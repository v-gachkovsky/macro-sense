-- The macro wizard's form as macro text: what to cast, on whom (in order), what Shift, Ctrl or Alt cast
-- instead, and what else the macro does. Pure Lua; the window with the form is WizardWindow.lua.
local _, ns = ...
ns = ns or {}

local Wizard = {}
ns.Wizard = Wizard

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
Wizard.KEYS = { "shift", "ctrl", "alt" }

local filtered = {}
for _, u in ipairs(Wizard.units) do filtered[u.key] = u.filters end
-- After these nothing is asked: they always hold.
local ALWAYS = { default = true, player = true, cursor = true }

-- A fresh form: Mouseover, then as usual (the macro players make most); no keys, nothing else.
function Wizard.Fresh()
    local spec = { on = { "mouseover", "default", "none" }, only = "any", alive = true, keys = {} }
    for _, key in ipairs(Wizard.KEYS) do spec.keys[key] = { on = false, unit = "default" } end
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

-- An action is { name = "Flash Heal" } or { name = "Healthstone", item = true }. A line of items says /use,
-- one with a spell /cast: the game takes either for both, /cast looks for a spell first and /use for an item.
local function Command(clauses)
    for _, c in ipairs(clauses) do
        if not c.action.item then return "/cast" end
    end
    return "/use"
end

-- The cast line's clauses: one per key held, then the units in order, those casting the same next to each other
-- as one ("[mod:alt,@party4][@party1] Flash Heal").
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
        local action = k.on and (k.action or spec.action)
        if action then add(Group(spec, k.unit, key), action) end
    end
    if spec.action then
        for _, unit in ipairs(spec.on) do
            if unit ~= "none" then
                add(Group(spec, unit), spec.action)
                if ALWAYS[unit] then break end
            end
        end
    end
    return out
end

-- The macro, or nil while there is nothing to cast or use.
function Wizard.Text(spec)
    local clauses = Clauses(spec)
    local uses = {}
    if spec.trinket1 then uses[#uses + 1] = "/use 13" end
    if spec.trinket2 then uses[#uses + 1] = "/use 14" end
    if #clauses == 0 and #uses == 0 then return nil end
    -- With trinkets first, a bare #showtooltip would show the first trinket: it names the spell.
    local lines = { #uses > 0 and spec.action and ("#showtooltip " .. spec.action.name) or "#showtooltip" }
    if spec.stopcasting then lines[#lines + 1] = "/stopcasting" end
    for _, line in ipairs(uses) do lines[#lines + 1] = line end
    if #clauses > 0 then
        local parts = {}
        for i, c in ipairs(clauses) do
            -- A last clause that always holds needs no brackets: "; Frostbolt".
            local groups = (i == #clauses and c.groups == "[]") and "" or (c.groups .. " ")
            parts[i] = groups .. c.action.name
        end
        lines[#lines + 1] = Command(clauses) .. " " .. table.concat(parts, "; ")
    end
    if spec.startattack then lines[#lines + 1] = "/startattack" end
    if spec.petattack then lines[#lines + 1] = "/petattack" end
    return table.concat(lines, "\n")
end

-- A name for the macro: what it casts.
function Wizard.Name(spec)
    if spec.action then return spec.action.name end
    for _, key in ipairs(Wizard.KEYS) do
        local k = spec.keys[key]
        if k.on and k.action then return k.action.name end
    end
    if spec.trinket1 or spec.trinket2 then return "Trinkets" end
end

return Wizard
