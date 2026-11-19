-- "What if": the preview for a moment you set up yourself, not the one in the game now. The keys held, who your
-- target, mouseover and focus are, your group's tank and healer (@tank, @heal), and combat come from `state`; any
-- other condition (a form, your pet, a specialization...) is the game's own, as `real(cond, unit)` tells. The same
-- reading of the options as the game's SecureCmdOptionParse, for Preview.Evaluate. Pure Lua (5.1).
local _, ns = ...
ns = ns or {}

local WhatIf = {}
ns.WhatIf = WhatIf

-- The units set up: "none", "enemy", "friend" or "dead" (an enemy, dead).
WhatIf.UNITS = { "target", "mouseover", "focus" }
WhatIf.KINDS = { "none", "enemy", "friend", "dead" }
-- Your group's tank and healer, for @tank and @heal: "friend", "deadfriend" or "none" (nobody has the role).
WhatIf.ROLES = { "tank", "heal" }
WhatIf.ROLE_KINDS = { "friend", "deadfriend", "none" }

-- A fresh moment: no key held, out of combat, an enemy targeted, nobody under the mouse, no focus; a tank and a
-- healer in your group.
function WhatIf.Fresh()
    return { mods = {}, combat = false,
        units = { target = "enemy", mouseover = "none", focus = "none", tank = "friend", heal = "friend" } }
end

local function trim(s) return s:match("^%s*(.-)%s*$") end
local ALIASES = { modifier = "mod" }

-- The key of `unit` among the units set up: "target" for "Target"; @tank and @heal only as MacroSense writes them,
-- in lowercase ("Tank" is someone's name). Nil for one not set up.
local ROLE = { tank = true, heal = true }
local function Key(unit)
    if ROLE[unit] then return unit end
    local lower = unit:lower()
    if ROLE[lower] then return nil end
    return lower
end

-- What a unit set up is now: nil for one not set up (the game's then), else its kind.
local function Kind(state, unit)
    local key = Key(unit)
    return key and state.units[key]
end

-- The conditions this moment answers itself: true / false, or nil for the game's.
local function Own(state, name, value, unit)
    if name == "mod" then
        local m = state.mods
        if not value or value == "" then return m.shift or m.ctrl or m.alt or m.cmd or false end
        for key in value:gmatch("[^/]+") do
            if m[key:lower()] then return true end
            -- Keys joined ("ctrlshift"): those held, and no other. The game takes it so: with Alt held too,
            -- [mod:ctrlshift] doesn't hold.
            local joined, exact = ns.Conditions.Keys(key), true
            local want = {}
            for _, k in ipairs(joined or {}) do want[k] = true end
            for _, k in ipairs({ "shift", "ctrl", "alt", "cmd" }) do
                if (m[k] == true) ~= (want[k] == true) then exact = false end
            end
            if joined and exact then return true end
        end
        return false
    end
    if name == "combat" then return state.combat == true end
    local kind = Kind(state, unit)
    if kind == nil then return nil end
    if name == "exists" then return kind ~= "none" end
    if name == "harm" then return kind == "enemy" or kind == "dead" end
    if name == "help" then return kind == "friend" or kind == "deadfriend" end
    if name == "dead" then return kind == "dead" or kind == "deadfriend" end
    return nil
end

-- Where a spell goes when it is cast, for the moment set up: `reaction(name, item)` says what it is for ("friends",
-- "enemies" or nil, as Sources does). One for enemies won't cast on a friend, a dead one or nobody; one for friends
-- won't on an enemy named in the macro, and goes to you when the game picks (Auto Self Cast). Nil: as it is.
local NOBODY = { target = "won't cast: you have no target", mouseover = "won't cast: nobody is under the mouse",
    focus = "won't cast: you have no focus", tank = "won't cast: your group has no tank",
    heal = "won't cast: your group has no healer" }
local WORDS = { target = "the target", mouseover = "the mouseover", focus = "the focus", tank = "the tank",
    heal = "the healer" }
-- Its texts kept in these tables, for the check that each has its translation.
function WhatIf.Texts()
    local out = {}
    for _, t in ipairs({ NOBODY, WORDS }) do for _, text in pairs(t) do out[#out + 1] = text end end
    return out
end

function WhatIf.Verdict(state, reaction, name, unit, item)
    local u = Key(unit or "target")
    local kind = u and state.units[u]
    local what = kind and reaction and reaction(name, item)
    if not what then return nil end
    local L = ns.L or setmetatable({}, { __index = function(_, k) return k end })
    local who = L[WORDS[u]]
    local friend = kind == "friend" or kind == "deadfriend"
    if what == "enemies" then
        if kind == "none" then return { fails = L[NOBODY[u]] } end
        if friend then return { fails = string.format(L["won't cast: %s is a friend"], who) } end
        if kind == "dead" then return { fails = string.format(L["won't cast: %s is a dead enemy"], who) } end
        return nil
    end
    -- A friend, dead too: as it is (a dead one may be raised, and [nodead] in the macro tells it apart).
    if friend then return nil end
    -- For friends, on an enemy or nobody: named in the macro, it won't; else the game casts it on you.
    if unit then
        if kind == "none" then return { fails = L[NOBODY[u]] } end
        return { fails = string.format(L["won't cast: %s is an enemy"], who) }
    end
    return { unit = "player" }
end

-- The env for Preview.Evaluate: parse(options) -> what it casts and on whom, as the game would in this moment.
-- `real(cond, unit)`: whether one condition holds in the game now (nil: it doesn't); `reaction`: see Verdict.
function WhatIf.Env(state, real, icon, reaction)
    -- "nocombat" is "combat" turned round; "modifier" is "mod".
    local function holds(cond, unit)
        local negate = cond:sub(1, 2):lower() == "no"
        local positive = negate and cond:sub(3) or cond
        local name, value = positive:match("^(%a+):(.*)$")
        name = (name or positive):lower()
        name = ns.Conditions and ns.Conditions.Base(name) or ALIASES[name] or name
        local own = Own(state, name, value, unit)
        -- Else the game's own answer, for the same unit.
        if own == nil then own = real and real(positive, unit) or false end
        return (own and true or false) ~= negate
    end
    local function parse(options)
        for clause in (options .. ";"):gmatch("([^;]*);") do
            local rest, groups = trim(clause), {}
            while rest:sub(1, 1) == "[" and rest:find("]", 1, true) do
                local close = rest:find("]", 1, true)
                groups[#groups + 1] = rest:sub(2, close - 1)
                rest = trim(rest:sub(close + 1))
            end
            if #groups == 0 then return rest end
            for _, group in ipairs(groups) do
                local conds, target = {}, nil
                for part in (group .. ","):gmatch("([^,]*),") do
                    local cond = trim(part)
                    local unit = cond:match("^@(.+)$") or cond:match("^[Tt][Aa][Rr][Gg][Ee][Tt]=(.+)$")
                    if unit then
                        target = trim(unit)
                    elseif cond ~= "" then
                        conds[#conds + 1] = cond
                    end
                end
                local ok = true
                for _, cond in ipairs(conds) do
                    if not holds(cond, target or "target") then
                        ok = false
                        break
                    end
                end
                if ok then return rest, target end
            end
        end
        return nil
    end
    local function verdict(name, unit, item) return WhatIf.Verdict(state, reaction, name, unit, item) end
    return { parse = parse, icon = icon, verdict = reaction and verdict or nil }
end

return WhatIf
