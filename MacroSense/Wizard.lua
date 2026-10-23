-- The macro wizard's form as macro text: the command, what it casts or uses, on whom (in order), what Shift, Ctrl,
-- Alt or Cmd do instead, and what else the macro does. Pure Lua; the window with the form is WizardWindow.lua.
local _, ns = ...
ns = ns or {}

local Wizard = {}
ns.Wizard = Wizard

-- The commands the form makes. /cast and /use take one spell or item, with keys; the others a list of them.
-- (/userandom is the same command as /castrandom in the game.)
Wizard.commands = {
    { key = "cast", name = "/cast" },
    { key = "use", name = "/use" },
    { key = "castsequence", name = "/castsequence" },
    { key = "castrandom", name = "/castrandom" },
}
Wizard.LIST = 6 -- names a list takes in the form
Wizard.RESETS = { "target", "combat", "shift", "ctrl", "alt" } -- what starts a sequence over, besides seconds

function Wizard.IsList(command) return command == "castsequence" or command == "castrandom" end

-- Where a cast can go, as the form lists them. "default" is the game's own choice: your target, or you when
-- the game casts on you by itself (Auto Self Cast). `filters`: friends / enemies / alive only apply to it.
Wizard.units = {
    { key = "default", name = "As usual" },
    { key = "target", name = "Your target", filters = true },
    { key = "mouseover", name = "Mouseover", filters = true },
    { key = "focus", name = "Focus", filters = true },
    { key = "player", name = "Yourself" },
    { key = "pet", name = "Your pet", filters = true },
    { key = "party1", name = "Party member 1", filters = true },
    { key = "party2", name = "Party member 2", filters = true },
    { key = "party3", name = "Party member 3", filters = true },
    { key = "party4", name = "Party member 4", filters = true },
    { key = "targettarget", name = "Target's target", filters = true },
    { key = "arena1", name = "Arena enemy 1", filters = true },
    { key = "arena2", name = "Arena enemy 2", filters = true },
    { key = "arena3", name = "Arena enemy 3", filters = true },
    { key = "cursor", name = "At the cursor" },
}
Wizard.KEYS = { "shift", "ctrl", "alt", "cmd" } -- the form shows Cmd on a Mac only

local filtered = {}
for _, u in ipairs(Wizard.units) do filtered[u.key] = u.filters end
-- After these nothing is asked: they always hold.
local ALWAYS = { default = true, player = true, cursor = true }

-- A fresh form: /cast on Mouseover, then as usual (the macro players make most); no keys held, nothing else. A
-- key held has its own units in order, two of them. A sequence starts over after 10 seconds once that is asked.
function Wizard.Fresh()
    local spec = { command = "cast", on = { "mouseover", "default", "none" }, only = "any", alive = true, keys = {},
        list = {}, reset = { seconds = 10 } }
    for _, key in ipairs(Wizard.KEYS) do spec.keys[key] = { active = false, on = { "default", "none" } } end
    return spec
end

-- "[mod:shift,@mouseover,help,nodead]": the unit, then what it must be. A unit that may not be there
-- without a check is asked for ([@focus,exists]), so the cast goes on to the next one.
local function Group(spec, unit, key)
    local conds = {}
    if key then conds[#conds + 1] = "mod:" .. key end
    if unit ~= "default" and unit ~= "target" then conds[#conds + 1] = "@" .. unit end
    if filtered[unit] then
        conds[#conds + 1] = spec.only == "friends" and "help" or spec.only == "enemies" and "harm" or "exists"
        if spec.alive then conds[#conds + 1] = "nodead" end
    end
    return "[" .. table.concat(conds, ",") .. "]"
end

-- Units in order, "none" left out, up to the first one that always holds: nothing after it is ever tried.
local function Chain(units)
    local out = {}
    for _, unit in ipairs(units) do
        if unit ~= "none" then
            out[#out + 1] = unit
            if ALWAYS[unit] then break end
        end
    end
    return out
end

-- An action is { name = "Flash Heal" }, { name = "Healthstone", item = true } or a slot { name = "13", item = true,
-- label = what is in it }. The game takes spells and items for /cast and /use both: /cast looks for a spell
-- first, /use for an item.

-- The clauses of a /cast or /use line: the keys held with their units, then the units in order, those casting the
-- same next to each other as one ("[mod:alt,@party4][@party1] Flash Heal").
local function Clauses(spec)
    local out = {}
    local function add(group, action)
        local last = out[#out]
        if last and last.action.name == action.name and last.action.item == action.item then
            last.groups = last.groups .. group
        else
            out[#out + 1] = { groups = group, action = action }
        end
    end
    for _, key in ipairs(Wizard.KEYS) do
        local k = spec.keys[key]
        local action = k.active and (k.action or spec.action)
        if action then
            for _, unit in ipairs(Chain(k.on)) do add(Group(spec, unit, key), action) end
        end
    end
    if spec.action then
        for _, unit in ipairs(Chain(spec.on)) do add(Group(spec, unit), spec.action) end
    end
    return out
end

local function CastLine(spec)
    local clauses = Clauses(spec)
    if #clauses == 0 then return nil end
    local parts = {}
    for i, c in ipairs(clauses) do
        -- A last clause that always holds needs no brackets: "; Frostbolt".
        local groups = (i == #clauses and c.groups == "[]") and "" or (c.groups .. " ")
        parts[i] = groups .. c.action.name
    end
    return "/" .. spec.command .. " " .. table.concat(parts, "; ")
end

-- The names of a list in order, the rows left empty skipped.
local function Names(spec)
    local out = {}
    for i = 1, Wizard.LIST do
        if spec.list[i] then out[#out + 1] = spec.list[i] end
    end
    return out
end

-- "reset=10/target/combat " for what starts a sequence over, "" for nothing.
local function Reset(reset)
    local parts = {}
    if reset.timed then parts[#parts + 1] = tostring(reset.seconds) end
    for _, what in ipairs(Wizard.RESETS) do
        if reset[what] then parts[#parts + 1] = what end
    end
    return #parts > 0 and ("reset=" .. table.concat(parts, "/") .. " ") or ""
end

-- "/castsequence [@mouseover,harm,nodead][] reset=target Corruption, Immolate": the units hold for the whole list.
local function ListLine(spec)
    local names = {}
    for i, action in ipairs(Names(spec)) do names[i] = action.name end
    if #names == 0 then return nil end
    local groups = ""
    for _, unit in ipairs(Chain(spec.on)) do groups = groups .. Group(spec, unit) end
    if groups == "[]" then groups = "" end -- as usual alone: no brackets
    local reset = spec.command == "castsequence" and Reset(spec.reset) or ""
    return "/" .. spec.command .. " " .. (groups ~= "" and groups .. " " or "") .. reset .. table.concat(names, ", ")
end

-- What the macro is named after and shows with trinkets first: the spell or item, a key's, the list's first.
local function First(spec)
    if Wizard.IsList(spec.command) then return Names(spec)[1] end
    if spec.action then return spec.action end
    for _, key in ipairs(Wizard.KEYS) do
        local k = spec.keys[key]
        if k.active and k.action then return k.action end
    end
end

-- The macro, or nil while there is nothing to cast or use.
function Wizard.Text(spec)
    local line
    if Wizard.IsList(spec.command) then line = ListLine(spec) else line = CastLine(spec) end
    local uses = {}
    if spec.trinket1 then uses[#uses + 1] = "/use 13" end
    if spec.trinket2 then uses[#uses + 1] = "/use 14" end
    if not line and #uses == 0 then return nil end
    -- With trinkets first, a bare #showtooltip would show the first trinket: it names the spell.
    local first = First(spec)
    local lines = { #uses > 0 and first and ("#showtooltip " .. first.name) or "#showtooltip" }
    if spec.stopcasting then lines[#lines + 1] = "/stopcasting" end
    for _, use in ipairs(uses) do lines[#lines + 1] = use end
    if line then lines[#lines + 1] = line end
    if spec.startattack then lines[#lines + 1] = "/startattack" end
    if spec.petattack then lines[#lines + 1] = "/petattack" end
    return table.concat(lines, "\n")
end

-- A name for the macro: what it casts (the item in a slot, not the slot's number).
function Wizard.Name(spec)
    local first = First(spec)
    if first then return first.label or first.name end
    if spec.trinket1 or spec.trinket2 then return "Trinkets" end
end

return Wizard
