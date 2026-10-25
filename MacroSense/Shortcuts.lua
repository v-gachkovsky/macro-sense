-- Warns when a macro with [mod:cmd] sits on a key that macOS itself uses with Cmd (Cmd+Q quits the game).
-- The analysis is pure Lua; finding the macro's keys needs the game (bindings, action bars).
local _, ns = ...
ns = ns or {}

local Shortcuts = {}
ns.Shortcuts = Shortcuts

-- macOS shortcuts with Cmd, as "CMD-[CTRL-][ALT-][SHIFT-]KEY" in WoW key names.
Shortcuts.MAC = {
    ["CMD-Q"] = "quits the game",
    ["CMD-W"] = "closes the window",
    ["CMD-H"] = "hides the game",
    ["CMD-M"] = "minimizes the window",
    ["CMD-TAB"] = "switches apps",
    ["CMD-SPACE"] = "opens Spotlight",
    ["CMD-`"] = "switches windows",
    ["CMD-ALT-H"] = "hides other apps",
    ["CMD-ALT-M"] = "minimizes all windows",
    ["CMD-ALT-D"] = "toggles the Dock",
    ["CMD-ALT-ESCAPE"] = "opens Force Quit",
    ["CMD-CTRL-Q"] = "locks the screen",
    ["CMD-CTRL-F"] = "toggles full screen",
    ["CMD-CTRL-SPACE"] = "opens emoji",
    ["CMD-SHIFT-Q"] = "logs you out",
    ["CMD-SHIFT-3"] = "takes a screenshot",
    ["CMD-SHIFT-4"] = "takes a screenshot",
    ["CMD-SHIFT-5"] = "opens screenshot tools",
}

local ORDER = { "CMD", "CTRL", "ALT", "SHIFT" }
local MOD_NAMES = { cmd = "CMD", ctrl = "CTRL", alt = "ALT", shift = "SHIFT" }
local LABELS = { CMD = "Cmd", CTRL = "Ctrl", ALT = "Option", SHIFT = "Shift",
    SPACE = "Space", TAB = "Tab", ESCAPE = "Esc" }

-- Modifier sets the macro needs Cmd for: one per bracket group with mod:cmd (other single
-- modifiers of that group are held too: [mod:cmd,mod:shift] -> Cmd+Shift).
function Shortcuts.CmdGroups(raw)
    local groups = {}
    -- Brackets never span lines, and an unclosed "[" must not swallow the next group.
    for inner in raw:gmatch("%[([^%[%]\n]*)%]") do
        local mods, cmd = {}, false
        for cond in inner:gmatch("[^,]+") do
            local name, values = cond:match("^%s*(%a+):([^%s]*)")
            name = name and name:lower()
            if name == "mod" or name == "modifier" then
                local list = {}
                for v in values:gmatch("[^/]+") do list[#list + 1] = v:lower() end
                for _, v in ipairs(list) do
                    if v == "cmd" then cmd = true end
                end
                -- "mod:shift/ctrl" means either one: only a single value is surely held.
                if #list == 1 and MOD_NAMES[list[1]] then mods[MOD_NAMES[list[1]]] = true end
            end
        end
        if cmd then
            mods.CMD = true
            groups[#groups + 1] = mods
        end
    end
    return groups
end

-- "SHIFT-Q" -> { SHIFT = true }, "Q". The Mac Command key shows up as META in bindings.
local function parseBinding(binding)
    local mods, key = {}, binding
    while true do
        local mod, rest = key:match("^(%u+)%-(.+)$")
        if not mod or not (mod == "ALT" or mod == "CTRL" or mod == "SHIFT" or mod == "META") then break end
        mods[mod == "META" and "CMD" or mod] = true
        key = rest
    end
    return mods, key
end

local function combo(mods, key)
    local parts = {}
    for _, m in ipairs(ORDER) do if mods[m] then parts[#parts + 1] = m end end
    parts[#parts + 1] = key
    return table.concat(parts, "-")
end

local function label(id)
    local parts = {}
    for part in id:gmatch("[^%-]+") do parts[#parts + 1] = LABELS[part] or part end
    return table.concat(parts, "+")
end

-- raw: macro text; keys: bindings the macro is on ("Q", "SHIFT-3"). Returns { { combo = "Cmd+Q", what = ... } }.
function Shortcuts.Conflicts(raw, keys)
    local out, seen = {}, {}
    for _, group in ipairs(Shortcuts.CmdGroups(raw)) do
        for _, binding in ipairs(keys) do
            local mods, key = parseBinding(binding:upper())
            for m in pairs(group) do mods[m] = true end
            local id = combo(mods, key)
            local what = Shortcuts.MAC[id]
            if what and not seen[id] then
                seen[id] = true
                out[#out + 1] = { combo = label(id), what = what }
            end
        end
    end
    return out
end

-- One line for the status bar, or nil.
function Shortcuts.Message(conflicts)
    if #conflicts == 0 then return nil end
    if #conflicts == 1 then
        return string.format("%s is a macOS shortcut (%s)", conflicts[1].combo, conflicts[1].what)
    end
    local combos = {}
    for i, c in ipairs(conflicts) do combos[i] = c.combo end
    return table.concat(combos, ", ") .. " are macOS shortcuts"
end

------------------------------------------------------------------------
-- Keys a macro is on (game API)
------------------------------------------------------------------------
-- Action slot -> binding command of the standard bars. Main bar pages and form bars use ACTIONBUTTON.
local function slotCommand(slot)
    local i = (slot - 1) % 12 + 1
    if slot <= 24 or (slot >= 73 and slot <= 120) then return "ACTIONBUTTON" .. i end
    if slot <= 36 then return "MULTIACTIONBAR3BUTTON" .. i end
    if slot <= 48 then return "MULTIACTIONBAR4BUTTON" .. i end
    if slot <= 60 then return "MULTIACTIONBAR2BUTTON" .. i end
    if slot <= 72 then return "MULTIACTIONBAR1BUTTON" .. i end
    if slot >= 145 and slot <= 156 then return "MULTIACTIONBAR5BUTTON" .. i end
    if slot >= 157 and slot <= 168 then return "MULTIACTIONBAR6BUTTON" .. i end
    if slot >= 169 and slot <= 180 then return "MULTIACTIONBAR7BUTTON" .. i end
end
Shortcuts.slotCommand = slotCommand

local keyCache = {}
local GetActionText = C_ActionBar and C_ActionBar.GetActionText or GetActionText

-- Keys that run macro `index` named `name`: a direct "MACRO name" binding and standard bar buttons.
-- Bars of addons (Bartender, ElvUI, ...) use their own bindings and are not found.
function Shortcuts.KeysFor(index, name)
    local cacheKey = index .. "\1" .. name
    if keyCache[cacheKey] then return keyCache[cacheKey] end
    local keys, seen = {}, {}
    local function add(...)
        for i = 1, select("#", ...) do
            local k = select(i, ...)
            if k and not seen[k] then
                seen[k] = true
                keys[#keys + 1] = k
            end
        end
    end
    add(GetBindingKey("MACRO " .. name))
    for slot = 1, 180 do
        -- By the name its button shows: for a macro that shows a spell, the game gives the spell's ID.
        if GetActionInfo(slot) == "macro" and GetActionText(slot) == name then
            local command = slotCommand(slot)
            if command then add(GetBindingKey(command)) end
        end
    end
    keyCache[cacheKey] = keys
    return keys
end

-- Bindings or bars changed.
function Shortcuts.Invalidate() keyCache = {} end

function Shortcuts.Enabled() return IsMacClient ~= nil and IsMacClient() and true or false end

return Shortcuts
