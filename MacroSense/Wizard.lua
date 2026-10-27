-- The macro wizard's form as macro text: the command, what it casts or uses, on whom (in order), what Shift, Ctrl,
-- Alt or Cmd do instead, and what else the macro does. Pure Lua; the window with the form is WizardWindow.lua.
local _, ns = ...
ns = ns or {}

local Wizard = {}
ns.Wizard = Wizard

-- The commands the form makes. /cast and /use take one spell or item, with keys; /castsequence and /castrandom
-- a list of them (/userandom is the same command as /castrandom in the game); /target, /focus and /assist only
-- units, with keys too; the pet's commands one per key held.
Wizard.commands = {
    { key = "cast", name = "/cast" },
    { key = "use", name = "/use" },
    { key = "castsequence", name = "/castsequence" },
    { key = "castrandom", name = "/castrandom" },
    { key = "target", name = "/target" },
    { key = "focus", name = "/focus" },
    { key = "assist", name = "/assist" },
    { key = "pet", name = "Pet commands" },
}

-- What the pet can be told. Attack takes units, Move to goes to the cursor; `since`: the expansion it came with
-- (Move To with Cataclysm: Classic Era and TBC have the command, but their game does nothing with it).
Wizard.petActions = {
    { key = "attack", name = "Attack", command = "/petattack" },
    { key = "follow", name = "Follow", command = "/petfollow" },
    { key = "stay", name = "Stay", command = "/petstay" },
    { key = "moveto", name = "Move to the cursor", command = "/petmoveto", since = 3 },
    { key = "passive", name = "Passive", command = "/petpassive" },
    { key = "defensive", name = "Defensive", command = "/petdefensive" },
    { key = "aggressive", name = "Aggressive", command = "/petaggressive" },
    { key = "dismiss", name = "Dismiss", command = "/petdismiss" },
}
local PET_COMMANDS = {}
for _, a in ipairs(Wizard.petActions) do PET_COMMANDS[a.key] = a.command end

-- The pet's commands a game has: `expansion` is the client's (nil: all of them).
function Wizard.PetActions(expansion)
    local out = {}
    for _, a in ipairs(Wizard.petActions) do
        if not (expansion and a.since and expansion < a.since) then out[#out + 1] = a end
    end
    return out
end
-- A key held tells the pet this unless chosen otherwise.
local PET_KEYS = { shift = "follow", ctrl = "stay", alt = "passive", cmd = "defensive" }

-- What the macro may say in chat (%t in the text is your target's name).
Wizard.channels = {
    { key = "say", name = "Say" }, { key = "yell", name = "Yell" }, { key = "party", name = "Party" },
    { key = "raid", name = "Raid" }, { key = "emote", name = "Emote" },
}
Wizard.LIST = 6 -- names a list takes in the form
Wizard.RESETS = { "target", "combat", "shift", "ctrl", "alt" } -- what starts a sequence over, besides seconds

function Wizard.IsList(command) return command == "castsequence" or command == "castrandom" end
function Wizard.IsTarget(command) return command == "target" or command == "focus" or command == "assist" end

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

local function Trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- The name /target takes by name, "" for none.
local function ByName(spec)
    return spec.command == "target" and spec.byName and Trim(spec.byName) or ""
end
-- After these nothing is asked: they always hold.
local ALWAYS = { default = true, player = true, cursor = true }

-- Whether a unit always holds (nothing after it is tried), and whether it is checked (friends / enemies / alive).
function Wizard.Always(unit) return ALWAYS[unit] == true end
function Wizard.Checked(unit) return filtered[unit] == true end

-- Whether a command takes a unit: a cast any; /target, /focus and /assist neither As usual nor the cursor,
-- /target not your target (the game would target nothing) and /focus not the focus; the pet attacks neither
-- the cursor, you nor itself.
local function Takes(command, unit)
    if command == "pet" then return unit ~= "cursor" and unit ~= "player" and unit ~= "pet" end
    if not Wizard.IsTarget(command) then return true end
    if unit == "default" or unit == "cursor" then return false end
    return not (command == "target" and unit == "target" or command == "focus" and unit == "focus")
end

-- The units the form offers for a command. `place`: "first" of the On row (a cast goes somewhere; /target may
-- go by name only), "then" (or nobody), "key" (the first of a key's: it may clear the target or the focus).
function Wizard.Units(command, place)
    local out = {}
    local target = Wizard.IsTarget(command)
    if place == "then" or (target and place == "first") then out[#out + 1] = { key = "none", name = "-" } end
    if target and place == "key" then
        out[#out + 1] = { key = "clear", name = command == "focus" and "Clear focus" or "Clear target" }
    end
    for _, u in ipairs(Wizard.units) do
        if Takes(command, u.key) then out[#out + 1] = u end
    end
    return out
end

-- After another command, units it doesn't take become ones it does: As usual is your target for /focus and
-- /assist; a cast goes somewhere again; Clear is for /target, /focus and /assist only.
function Wizard.Fit(spec)
    local target = Wizard.IsTarget(spec.command)
    -- What goes in a slot nothing fits: a cast or an attack goes somewhere, /target may go by name.
    local function nobody(first) return (first and not target) and "default" or "none" end
    local function fit(unit, first, key)
        if unit == "clear" and not (target and key and first) then return nobody(first) end
        if unit == "none" then return nobody(first) end
        if unit == "clear" or Takes(spec.command, unit) then return unit end
        if unit == "default" and Takes(spec.command, "target") then return "target" end
        return nobody(first)
    end
    for i, unit in ipairs(spec.on) do spec.on[i] = fit(unit, i == 1) end
    for _, k in pairs(spec.keys) do
        for i, unit in ipairs(k.on) do k.on[i] = fit(unit, i == 1, true) end
    end
end

-- A fresh form: /cast on Mouseover, then as usual (the macro players make most); no keys held, nothing else. A
-- key held has its own units in order, two of them. A sequence starts over after 10 seconds once that is asked;
-- the pet attacks without a key; the chat is the party's. What the game says a spell is for comes with it:
-- `reaction` for the macro's, a key's own for its spell ("friends", "enemies" or nil).
function Wizard.Fresh()
    local spec = { command = "cast", on = { "mouseover", "default", "none" }, only = "any", alive = true, keys = {},
        list = {}, reset = { seconds = 10 }, pet = "attack", channel = "party" }
    for _, key in ipairs(Wizard.KEYS) do
        spec.keys[key] = { active = false, on = { "default", "none" }, pet = PET_KEYS[key] }
    end
    return spec
end

-- Friends, enemies or anyone: what the units of `key` (nil: the macro's own) are checked for. A key's own spell is
-- checked for what the game says it is for (its `reaction`), the rest for the form's choice.
function Wizard.Only(spec, key)
    local k = key and spec.keys[key]
    if k and k.action and k.reaction and not Wizard.IsTarget(spec.command) and spec.command ~= "pet" then
        return k.reaction
    end
    return spec.only
end

-- "[mod:shift,@mouseover,help,nodead]": the key (`mod`, "mod:shift" or "nomod:shift/ctrl"), the unit, then
-- what it must be (`only`: friends or enemies, the form's choice if nil). A unit that may not be there without a
-- check is asked for ([@focus,exists]), so the cast goes on to the next one. A cast needs no "@target" (it goes to
-- the target anyway); /focus and /assist do (`named`).
local function Group(spec, unit, mod, named, only)
    local conds = {}
    only = only or spec.only
    if mod then conds[#conds + 1] = mod end
    if unit ~= "default" and (named or unit ~= "target") then conds[#conds + 1] = "@" .. unit end
    if filtered[unit] then
        conds[#conds + 1] = only == "friends" and "help" or only == "enemies" and "harm" or "exists"
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
-- label = what is in it }. A spell may come with the ranks learned (`ranks`, "Rank 1" first) and one picked
-- (`rank`); one that goes to nobody but you has `selfOnly`. The game takes spells and items for /cast and /use
-- both: /cast looks for a spell first, /use for an item.

-- How the macro names an action: "Shadow Bolt(Rank 3)" with a rank picked, "Shadow Bolt" (the highest learned)
-- without.
function Wizard.Spelled(action)
    return action.rank and action.name .. "(" .. action.rank .. ")" or action.name
end

-- The clauses of a /cast or /use line: the keys held with their units, then the units in order, those casting the
-- same next to each other as one ("[mod:alt,@party4][@party1] Flash Heal").
local function Clauses(spec)
    local out = {}
    local function add(group, action)
        local last = out[#out]
        if last and Wizard.Spelled(last.action) == Wizard.Spelled(action) and last.action.item == action.item then
            last.groups = last.groups .. group
        else
            out[#out + 1] = { groups = group, action = action }
        end
    end
    for _, key in ipairs(Wizard.KEYS) do
        local k = spec.keys[key]
        local action = k.active and (k.action or spec.action)
        if action then
            local only = Wizard.Only(spec, key)
            for _, unit in ipairs(Chain(k.on)) do add(Group(spec, unit, "mod:" .. key, nil, only), action) end
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
        parts[i] = groups .. Wizard.Spelled(c.action)
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

-- Whether the units of `key` (nil: the macro's own) are no question: what they cast goes to nobody but you
-- (`selfOnly`: Demon Armor, a potion), for a list every spell of it. A key without a spell of its own casts the
-- macro's.
function Wizard.SelfOnly(spec, key)
    if Wizard.IsTarget(spec.command) or spec.command == "pet" then return false end
    local k = key and spec.keys[key]
    if k and k.action then return k.action.selfOnly == true end
    if Wizard.IsList(spec.command) then
        local names = Names(spec)
        for _, action in ipairs(names) do
            if not action.selfOnly then return false end
        end
        return #names > 0
    end
    return spec.action ~= nil and spec.action.selfOnly == true
end

-- Another command: what was picked comes along, the spell of /cast starting a list and the first of a list
-- becoming the spell; units it doesn't take become ones it does.
function Wizard.Switch(spec, command)
    local wasList = Wizard.IsList(spec.command)
    spec.command = command
    if Wizard.IsList(command) and not wasList and spec.action and not Names(spec)[1] then
        spec.list[1] = spec.action
    elseif not Wizard.IsList(command) and wasList and not spec.action then
        spec.action = Names(spec)[1]
    end
    Wizard.Fit(spec)
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
    for i, action in ipairs(Names(spec)) do names[i] = Wizard.Spelled(action) end
    if #names == 0 then return nil end
    local groups = ""
    for _, unit in ipairs(Chain(spec.on)) do groups = groups .. Group(spec, unit) end
    if groups == "[]" then groups = "" end -- as usual alone: no brackets
    local reset = spec.command == "castsequence" and Reset(spec.reset) or ""
    return "/" .. spec.command .. " " .. (groups ~= "" and groups .. " " or "") .. reset .. table.concat(names, ", ")
end

-- /target, /focus or /assist on the units in order, keys first; a key that clears goes before it all, with a
-- /stopmacro so the rest doesn't take a unit again. /target may end with a name: "[] Hogger" when nobody else is.
local CLEAR = { target = "/cleartarget", focus = "/clearfocus", assist = "/cleartarget" }
local function TargetLines(spec)
    local clears, groups = {}, ""
    for _, key in ipairs(Wizard.KEYS) do
        local k = spec.keys[key]
        if k.active and k.on[1] == "clear" then
            clears[#clears + 1] = key
        elseif k.active then
            for _, unit in ipairs(Chain(k.on)) do groups = groups .. Group(spec, unit, "mod:" .. key, true) end
        end
    end
    for _, unit in ipairs(Chain(spec.on)) do groups = groups .. Group(spec, unit, nil, true) end
    local before = {}
    if #clears > 0 then
        local mods = "[mod:" .. table.concat(clears, "/") .. "]"
        before = { CLEAR[spec.command] .. " " .. mods, "/stopmacro " .. mods }
    end
    local name = ByName(spec)
    if name ~= "" then return before, "/target " .. (groups ~= "" and groups .. "[] " or "") .. name end
    return before, groups ~= "" and ("/" .. spec.command .. " " .. groups) or nil
end

-- One line per thing the pet is told: without a key (none of those held), then each key's. Attack goes to the
-- units in order ([nomod:shift,@mouseover,harm,nodead][nomod:shift]), Move to to the cursor.
local function PetLine(spec, action, units, mod)
    local groups = ""
    if action == "attack" then
        for _, unit in ipairs(Chain(units)) do groups = groups .. Group(spec, unit, mod) end
    elseif action == "moveto" then
        groups = "[" .. (mod and mod .. "," or "") .. "@cursor]"
    elseif mod then
        groups = "[" .. mod .. "]"
    end
    return PET_COMMANDS[action] .. (groups ~= "" and groups ~= "[]" and " " .. groups or "")
end

local function PetLines(spec)
    local held = {}
    for _, key in ipairs(Wizard.KEYS) do
        if spec.keys[key].active then held[#held + 1] = key end
    end
    local lines = { PetLine(spec, spec.pet, spec.on, #held > 0 and ("nomod:" .. table.concat(held, "/")) or nil) }
    for _, key in ipairs(held) do
        local k = spec.keys[key]
        lines[#lines + 1] = PetLine(spec, k.pet, k.on, "mod:" .. key)
    end
    return lines
end

-- What the macro is named after and shows with trinkets first: the spell or item, a key's, the list's first.
local function First(spec)
    if Wizard.IsTarget(spec.command) or spec.command == "pet" then return nil end
    if Wizard.IsList(spec.command) then return Names(spec)[1] end
    if spec.action then return spec.action end
    for _, key in ipairs(Wizard.KEYS) do
        local k = spec.keys[key]
        if k.active and k.action then return k.action end
    end
end

-- The macro, or nil while there is nothing to cast, use or target.
function Wizard.Text(spec)
    local target = Wizard.IsTarget(spec.command) or spec.command == "pet" -- no spell, no icon of its own
    local before, line = {}, nil
    if spec.command == "pet" then
        before = PetLines(spec)
    elseif target then
        before, line = TargetLines(spec)
    elseif Wizard.IsList(spec.command) then
        line = ListLine(spec)
    else
        line = CastLine(spec)
    end
    local uses = {}
    if spec.trinket1 then uses[#uses + 1] = "/use 13" end
    if spec.trinket2 then uses[#uses + 1] = "/use 14" end
    if not line and #before == 0 and #uses == 0 then return nil end
    -- The icon and tooltip of the spell (a /target or pet macro has none to show, but trinkets have). With
    -- trinkets first, a bare #showtooltip would show the first trinket: it names the spell.
    local lines = {}
    if not target or #uses > 0 then
        local first = First(spec)
        lines[1] = #uses > 0 and first and ("#showtooltip " .. Wizard.Spelled(first)) or "#showtooltip"
    end
    local pet = spec.command == "pet"
    if not pet then
        for _, l in ipairs(before) do lines[#lines + 1] = l end
    end
    if spec.stopcasting then lines[#lines + 1] = "/stopcasting" end
    if spec.cancelform then lines[#lines + 1] = "/cancelform" end
    if spec.dismount then lines[#lines + 1] = "/dismount [mounted]" end
    if spec.cancelaura then lines[#lines + 1] = "/cancelaura " .. spec.cancelaura.name end
    if spec.nearest then lines[#lines + 1] = "/targetenemy [noharm][dead]" end
    -- Auto attack as guides have it, before trinkets and spells: once the nearest enemy is targeted.
    if spec.startattack then lines[#lines + 1] = "/startattack" end
    for _, use in ipairs(uses) do lines[#lines + 1] = use end
    if pet then
        for _, l in ipairs(before) do lines[#lines + 1] = l end
    end
    if line then lines[#lines + 1] = line end
    if spec.petattack then lines[#lines + 1] = "/petattack" end
    local say = spec.say and Trim(spec.say) or ""
    if say ~= "" then lines[#lines + 1] = "/" .. spec.channel .. " " .. say end
    return table.concat(lines, "\n")
end

-- A name for the macro: what it casts (the item in a slot, not the slot's number), or what it targets.
local TARGET_NAMES = { target = "Target", focus = "Focus", assist = "Assist", pet = "Pet" }
function Wizard.Name(spec)
    if Wizard.IsTarget(spec.command) or spec.command == "pet" then
        local name = ByName(spec)
        return name ~= "" and name or ns.L[TARGET_NAMES[spec.command]]
    end
    local first = First(spec)
    if first then return first.label or first.name end
    if spec.trinket1 or spec.trinket2 then return ns.L["Trinkets"] end
end

return Wizard
