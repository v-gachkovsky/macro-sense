-- Macro condition values and unit ids: what may follow "form:", "btn:", "@", ... Pure Lua (5.1).
-- Lists that depend on the character (forms, specs, item types, pet) come from ns.sources.
local _, ns = ...
ns = ns or {}
local L = ns.L

local Conditions = {}
ns.Conditions = Conditions

-- Different names for the same condition.
local ALIASES = {
    modifier = "mod", button = "btn", actionbar = "bar", stance = "form", worn = "equipped",
}

local argSet
local function takesArg()
    if not argSet then
        argSet = { modifier = true, button = true, actionbar = true, stance = true, worn = true }
        for _, c in ipairs(ns.data.conditions) do
            if c.arg then argSet[c.name] = true end
        end
    end
    return argSet
end

-- "nomodifier" -> "mod", "noform" -> "form", "stance" -> "form"; unknown names come back lowercased.
function Conditions.Base(name)
    name = name:lower()
    local args = takesArg()
    if not args[name] and name:sub(1, 2) == "no" and args[name:sub(3)] then name = name:sub(3) end
    return ALIASES[name] or name
end

function Conditions.TakesValue(name)
    local base = Conditions.Base(name)
    return takesArg()[base] or false
end

------------------------------------------------------------------------
-- Units
------------------------------------------------------------------------
local SINGLE = {
    player = true, target = true, focus = true, mouseover = true, pet = true, vehicle = true,
    cursor = true, none = true, npc = true, anyenemy = true, anyfriend = true, anyinteract = true,
    softenemy = true, softfriend = true, softinteract = true,
}
local NUMBERED = { party = 4, partypet = 4, raid = 40, raidpet = 40, arena = 5, arenapet = 5, boss = 8, nameplate = 40 }

-- The rest after a base unit: only "target" / "pet", any number of times.
local function suffixesOnly(rest)
    while rest ~= "" do
        local suffix = rest:match("^target") or rest:match("^pet")
        if not suffix then return false end
        rest = rest:sub(#suffix + 1)
    end
    return true
end

-- A unit id: a base ("focus", "party2") followed by any "target" / "pet" ("party2targettarget").
function Conditions.IsUnit(unit)
    unit = unit:lower()
    for base in pairs(SINGLE) do
        if unit:sub(1, #base) == base and suffixesOnly(unit:sub(#base + 1)) then return true end
    end
    local word, n, rest = unit:match("^(%a-)(%d+)(.*)$")
    local max = word and NUMBERED[word]
    return max ~= nil and n:sub(1, 1) ~= "0" and tonumber(n) <= max and suffixesOnly(rest)
end

------------------------------------------------------------------------
-- Values
------------------------------------------------------------------------
local function names(list)
    local set = {}
    for _, item in ipairs(list) do set[item.name:lower()] = true end
    return set
end

local function inRange(lo, hi)
    return function(v)
        local n = tonumber(v)
        return n ~= nil and n == math.floor(n) and n >= lo and n <= hi and not v:find("[^%d]")
    end
end

-- Base condition -> function(value) -> ok, plus what to say when it is not.
local RULES = {
    mod = {
        check = function(v) return names(ns.data.modifiers)[v:lower()] or v == "cmd" or v:find("^%u[%u_]+$") ~= nil end,
        expect = "shift, ctrl, alt or a key action like SELFCAST",
    },
    btn = { check = function(v) return names(ns.data.buttons)[v:lower()] end, expect = "1-5 or a button name" },
    group = { check = function(v) return names(ns.data.groups)[v:lower()] end, expect = "party or raid" },
    bar = { check = inRange(1, 6), expect = "a bar page 1-6" },
    bonusbar = { check = inRange(1, 5), expect = "1-5" },
    form = { check = inRange(0, 10), expect = "a form number, 0 = no form" },
    spec = { check = inRange(1, 5), expect = "a specialization number" },
}

-- nil when fine, or the error message for value `v` of condition `name`.
function Conditions.CheckValue(name, v)
    local rule = RULES[Conditions.Base(name)]
    if not rule or v == "" or rule.check(v) then return nil end
    return string.format(L["invalid %s value \"%s\" (expected %s)"], name:lower(), v, L[rule.expect])
end

local function source(name)
    return ns.sources and ns.sources[name] and ns.sources[name]() or {}
end

-- Suggestions after "name:" (and after each "/").
function Conditions.Values(name)
    local base = Conditions.Base(name)
    local d = ns.data
    if base == "mod" then return d.modifiers end
    if base == "btn" then return d.buttons end
    if base == "group" then return d.groups end
    if base == "bar" then return d.bars end
    if base == "bonusbar" then return d.bonusbars end
    if base == "form" then return source("forms") end
    if base == "spec" then return source("specs") end
    if base == "equipped" then return source("itemTypes") end
    if base == "pet" then return source("pets") end
    if base == "known" or base == "channeling" then return source("spells") end
    return {}
end

------------------------------------------------------------------------
-- reset= in /castsequence
------------------------------------------------------------------------
-- The game looks for these words after "reset=" and takes the first number as seconds without a press.
local RESETS = { target = true, combat = true, shift = true, ctrl = true, alt = true }

-- nil when fine, or the error message for reset value `v`.
function Conditions.CheckReset(v)
    if RESETS[v:lower()] or v:find("^%d+$") then return nil end
    return string.format(L["invalid reset value \"%s\" (expected seconds, target, combat, shift, ctrl or alt)"], v)
end

-- Suggestions after "reset=" and each "/": the ones not used yet (one number at most: only the first counts).
function Conditions.ResetItems(used)
    local number = false
    for v in pairs(used or {}) do
        if v:find("^%d+$") then number = true end
    end
    local out = {}
    for _, item in ipairs(ns.data.resets) do
        local isNumber = item.name:find("^%d") ~= nil
        if not (used and used[item.name]) and not (isNumber and number) then out[#out + 1] = item end
    end
    return out
end

-- Unit suggestions: the list, plus "...target" / "...pet" after a unit id ("party1" -> "party1target").
function Conditions.UnitItems(prefix)
    local out = {}
    for _, u in ipairs(ns.data.units) do out[#out + 1] = u end
    local p = prefix:lower()
    for k = #p, 1, -1 do
        local base = p:sub(1, k)
        if Conditions.IsUnit(base) then
            for _, suffix in ipairs({ "target", "pet" }) do
                local name = base .. suffix
                if name ~= p and name:sub(1, #p) == p then out[#out + 1] = { name = name } end
            end
            break
        end
    end
    return out
end

return Conditions
