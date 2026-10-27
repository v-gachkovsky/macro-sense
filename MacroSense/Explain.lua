-- What a macro line does, in plain words: every branch of it, not only the one that would run now (the live
-- preview says that). For the line's tooltip in the editor. Pure Lua (5.1): the names of forms and specializations
-- and the commands of the client's language come in through `env`.
local _, ns = ...
ns = ns or {}
local L = ns.L

local Explain = {}
ns.Explain = Explain

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- "[a,b][c] X; [d] Y; Z" -> { { groups = { { "a", "b" }, { "c" } }, action = "X" }, { groups = { { "d" } },
-- action = "Y" }, { groups = {}, action = "Z" } }; nil when a bracket is not closed (the editor marks that).
function Explain.Branches(s)
    local out, branch, text, i = {}, { groups = {} }, {}, 1
    while i <= #s do
        local c = s:sub(i, i)
        if c == "[" then
            local close = s:find("]", i + 1, true)
            if not close then return nil end
            local group = {}
            for part in (s:sub(i + 1, close - 1) .. ","):gmatch("([^,]*),") do
                if part:find("%S") then group[#group + 1] = trim(part) end
            end
            branch.groups[#branch.groups + 1] = group
            i = close + 1
        else
            if c == ";" then
                branch.action = trim(table.concat(text))
                out[#out + 1] = branch
                branch, text = { groups = {} }, {}
            else
                text[#text + 1] = c
            end
            i = i + 1
        end
    end
    branch.action = trim(table.concat(text))
    out[#out + 1] = branch
    return out
end

------------------------------------------------------------------------
-- Units: how "@focus" reads after "on" (in Ukrainian, the case that takes)
------------------------------------------------------------------------
local UNITS = {
    target = "your target", focus = "your focus", mouseover = "the unit under the mouse", player = "yourself",
    pet = "your pet", vehicle = "your vehicle", targettarget = "your target's target", none = "whoever you click",
    npc = "the one you are talking to", tank = "your group's tank", heal = "your group's healer",
}
local NUMBERED = {
    party = "party member %d", partypet = "the pet of party member %d", raid = "raid member %d",
    raidpet = "the pet of raid member %d", arena = "arena enemy %d", arenapet = "the pet of arena enemy %d",
    boss = "boss %d",
}

-- A unit id in words; anything else is a player's name, as it is.
function Explain.Unit(unit)
    local u = unit:lower()
    if UNITS[u] then return L[UNITS[u]] end
    local base, n = u:match("^(%a+)(%d+)$")
    if base and NUMBERED[base] then return string.format(L[NUMBERED[base]], tonumber(n)) end
    local of = u:match("^(.+)target$")
    if of and (UNITS[of] or (of:match("^(%a+)%d+$") and NUMBERED[of:match("^(%a+)%d+$")])) then
        return string.format(L["the target of %s"], Explain.Unit(of))
    end
    return unit
end

------------------------------------------------------------------------
-- Conditions
------------------------------------------------------------------------
-- About the unit a group goes to: "if it is a friend and alive". { yes, no }
local CHECKS = {
    help = { "a friend", "not a friend" }, harm = { "an enemy", "not an enemy" }, dead = { "dead", "alive" },
    party = { "in your party", "not in your party" }, raid = { "in your raid", "not in your raid" },
    unithasvehicleui = { "in a vehicle", "not in a vehicle" },
}
-- About you and the game: "in combat". { yes, no, value = { "with %s", "without %s" } }
local STATES = {
    combat = { "in combat", "out of combat" },
    stealth = { "in stealth", "out of stealth" },
    mounted = { "mounted", "not mounted" },
    flying = { "flying", "not flying" },
    flyable = { "where you can fly", "where you can't fly" },
    advflyable = { "where you can skyride", "where you can't skyride" },
    swimming = { "swimming", "not swimming" },
    indoors = { "indoors", "not indoors" },
    outdoors = { "outdoors", "not outdoors" },
    resting = { "resting, in a city or an inn", "not resting" },
    cursor = { "with something on the cursor", "with nothing on the cursor" },
    petbattle = { "in a pet battle", "not in a pet battle" },
    vehicleui = { "in a vehicle", "not in a vehicle" },
    canexitvehicle = { "when you can leave the vehicle", "when you can't leave the vehicle" },
    possessbar = { "while you control another creature", "while you control no other creature" },
    overridebar = { "with a special action bar", "without a special action bar" },
    extrabar = { "with the extra action button", "without the extra action button" },
    shapeshift = { "shapeshifted", "not shapeshifted" },
    bonusbar = { "with a bonus action bar", "without a bonus action bar",
        value = { "with bonus action bar %s", "without bonus action bar %s" } },
    channeling = { "while channeling", "not channeling", value = { "while channeling %s", "not channeling %s" } },
    pet = { "with your pet out", "with no pet out", value = { "with %s out", "without %s out" } },
    equipped = { value = { "with %s equipped", "without %s equipped" } },
    known = { value = { "if you know %s", "if you don't know %s" } },
    pvptalent = { value = { "with the PvP talent %s", "without the PvP talent %s" } },
    bar = { value = { "on action bar page %s", "not on action bar page %s" } },
    spec = { value = { "in specialization %s", "not in specialization %s" } },
    form = { "in a form", "in no form", value = { "in %s", "not in %s" } },
    talent = { value = { "with the talent of %s", "without the talent of %s" } },
    btn = { value = { "clicked with %s", "not clicked with %s" } },
}
local ALIASES = { modifier = "mod", stance = "form", worn = "equipped", button = "btn", actionbar = "bar" }
local KEYS = { shift = "Shift", ctrl = "Ctrl", alt = "Alt", cmd = "Cmd" }
local SIDES = { l = "left %s", r = "right %s" }
local BUTTONS = { ["1"] = "the left mouse button", ["2"] = "the right mouse button", ["3"] = "the middle mouse button",
    LeftButton = "the left mouse button", RightButton = "the right mouse button", MiddleButton = "the middle mouse button" }

-- "a/b" in words, "or" between: each through `word`.
local function Alternatives(value, word)
    local out = {}
    for part in (value .. "/"):gmatch("([^/]*)/") do
        if part:find("%S") then out[#out + 1] = word(trim(part)) end
    end
    return table.concat(out, L[" or "])
end

local function Key(k)
    local lower = k:lower()
    if KEYS[lower] then return KEYS[lower] end
    local side, key = lower:match("^([lr])(%a+)$")
    if side and KEYS[key] then return string.format(L[SIDES[side]], KEYS[key]) end
    return k
end

-- How one value reads, for condition `name`.
local function Value(name, v, env)
    if name == "form" then
        if v == "0" then return L["no form"] end
        return env.formName and env.formName(v) or string.format(L["form %s"], v)
    elseif name == "spec" then
        return env.specName and env.specName(v) or v
    elseif name == "talent" then
        local row, column = v:match("^(%d+)/(%d+)$")
        if row then return string.format(L["row %s, column %s"], row, column) end
    elseif name == "btn" then
        if BUTTONS[v] then return L[BUTTONS[v]] end
        if v:find("^%d$") then return string.format(L["mouse button %s"], v) end
    end
    return v
end

-- A condition that is not about the unit, in words.
local function State(name, no, value, env)
    if name == "mod" then
        if not value then return no and L["with no key held"] or L["with Shift, Ctrl or Alt held"] end
        return string.format(no and L["without %s held"] or L["with %s held"], Alternatives(value, Key))
    elseif name == "group" then
        if value == "raid" then return no and L["not in a raid"] or L["in a raid"] end
        return no and L["not in a group"] or L["in a group"]
    elseif name == "form" and value == "0" then
        return no and L["in a form"] or L["in no form"]
    end
    local s = STATES[name]
    if value and s.value then
        -- Talent: "row 2, column 1"; the others: "or" between alternatives.
        local words = name == "talent" and Value(name, value, env)
            or Alternatives(value, function(v) return Value(name, v, env) end)
        return string.format(L[s.value[no and 2 or 1]], words)
    end
    return s[1] and L[s[no and 2 or 1]] or nil
end

-- What one group of conditions says: { unit = the unit it goes to, checks = about it, exists = true / false,
-- states = the rest, conditional = it checks something (a unit alone always holds) }, all in words.
local function Group(conds, env)
    local g = { checks = {}, states = {} }
    for _, c in ipairs(conds) do
        local unit = c:match("^@(.*)$") or c:match("^[Tt][Aa][Rr][Gg][Ee][Tt]%s*=%s*(.*)$")
        if unit then
            g.unit = trim(unit)
        else
            g.conditional = true
            local name, value = c:match("^([^:]+):(.*)$")
            name = trim(name or c):lower()
            value = value and trim(value) ~= "" and trim(value) or nil
            name = ALIASES[name] or name
            local no = false
            local function known(n) return CHECKS[n] or STATES[n] or n == "mod" or n == "group" or n == "exists" end
            if not known(name) and name:sub(1, 2) == "no" then
                local base = ALIASES[name:sub(3)] or name:sub(3)
                if known(base) then no, name = true, base end
            end
            if name == "exists" then
                g.exists = not no
            elseif CHECKS[name] then
                g.checks[#g.checks + 1] = L[CHECKS[name][no and 2 or 1]]
            elseif known(name) then
                g.states[#g.states + 1] = State(name, no, value, env)
            end
        end
    end
    return g
end

-- "if it is an enemy and alive", "if there is one", or nil.
local function Checks(g)
    if #g.checks > 0 then return string.format(L["if it is %s"], table.concat(g.checks, L[" and "])) end
    if g.exists == true then return L["if there is one"] end
    if g.exists == false then return L["if there is none"] end
end

------------------------------------------------------------------------
-- Commands
------------------------------------------------------------------------
-- An equipment slot by its number: "13" -> Trinket 1.
local function SlotName(n)
    local slot = ns.data and ns.data.slots[tonumber(n)]
    return slot and L[slot.hint] or string.format(L["slot %s"], n)
end

-- A spell or item as the line names it: "13" -> the item in Trinket 1, "0 1" -> bag 0, slot 1, "Fireball(Rank 3)"
-- -> "Fireball (Rank 3)", "!Prowl" -> Prowl.
function Explain.Name(s)
    s = trim(s):gsub("^!", "")
    if s:find("^%d+$") then return string.format(L["the item in %s"], SlotName(s)) end
    local bag, slot = s:match("^(%d+)%s+(%d+)$")
    if bag then return string.format(L["bag %s, slot %s"], bag, slot) end
    return (s:gsub("%s*(%b())$", " %1"))
end

local function List(s)
    local out = {}
    for item in (s .. ","):gmatch("([^,]*),") do
        if item:find("%S") then out[#out + 1] = Explain.Name(item) end
    end
    return table.concat(out, ", ")
end

-- "reset=target/10" in words: what starts the sequence over.
local function Reset(value)
    return Alternatives(value, function(v)
        local lower = v:lower()
        if lower == "target" then return L["on a new target"] end
        if lower == "combat" then return L["when combat ends"] end
        if KEYS[lower] then return string.format(L["with %s held"], KEYS[lower]) end
        if v:find("^%d+%.?%d*$") then return string.format(L["after %s seconds without a press"], v) end
        return v
    end)
end

-- Secure commands other than the action ones, by their key (SLASH_<KEY>n): what they do, `unit` the unit or name
-- in words (nil: none given). English names stand in when `env` can't tell the key.
local ENGLISH = {
    target = "TARGET", tar = "TARGET", focus = "FOCUS", assist = "ASSIST", a = "ASSIST", clearfocus = "CLEARFOCUS",
    cleartarget = "CLEARTARGET", startattack = "STARTATTACK", stopattack = "STOPATTACK",
    stopcasting = "STOPCASTING", cancelform = "CANCELFORM", dismount = "DISMOUNT", petattack = "PET_ATTACK",
    petfollow = "PET_FOLLOW", petstay = "PET_STAY", petmoveto = "PET_MOVE_TO", petpassive = "PET_PASSIVE",
    petdefensive = "PET_DEFENSIVE", petaggressive = "PET_AGGRESSIVE", petassist = "PET_ASSIST",
    petdismiss = "PET_DISMISS", petautocaston = "PET_AUTOCASTON", petautocastoff = "PET_AUTOCASTOFF",
    petautocasttoggle = "PET_AUTOCASTTOGGLE", equipset = "EQUIP_SET", targetenemy = "TARGET_NEAREST_ENEMY",
    targetfriend = "TARGET_NEAREST_FRIEND", targetlasttarget = "TARGET_LAST_TARGET",
    targetparty = "TARGET_NEAREST_PARTY", targetraid = "TARGET_NEAREST_RAID", stopspelltarget = "STOPSPELLTARGET",
    changeactionbar = "CHANGEACTIONBAR",
}
local SECURE = {
    TARGET = function(unit) return unit and string.format(L["targets %s"], unit) or L["does nothing"] end,
    FOCUS = function(unit) return string.format(L["sets %s as your focus"], unit or L["your target"]) end,
    ASSIST = function(unit) return string.format(L["takes the target of %s"], unit or L["your target"]) end,
    CLEARFOCUS = function() return L["clears your focus"] end,
    CLEARTARGET = function() return L["clears your target"] end,
    STARTATTACK = function(unit)
        return unit and string.format(L["starts auto attack on %s"], unit) or L["starts auto attack"]
    end,
    STOPATTACK = function() return L["stops auto attack"] end,
    STOPCASTING = function() return L["stops your cast"] end,
    STOPSPELLTARGET = function() return L["cancels the spell waiting for its target"] end,
    CANCELFORM = function() return L["leaves your form"] end,
    DISMOUNT = function() return L["gets off your mount"] end,
    PET_ATTACK = function(unit) return string.format(L["your pet attacks %s"], unit or L["your target"]) end,
    PET_FOLLOW = function() return L["your pet follows you"] end,
    PET_STAY = function() return L["your pet stays where it is"] end,
    PET_MOVE_TO = function(_, cursor)
        return cursor and L["your pet goes to the cursor"] or L["your pet goes where you click"]
    end,
    PET_PASSIVE = function() return L["your pet turns passive"] end,
    PET_DEFENSIVE = function() return L["your pet turns defensive"] end,
    PET_AGGRESSIVE = function() return L["your pet turns aggressive"] end,
    PET_ASSIST = function() return L["your pet turns to assist"] end,
    PET_DISMISS = function() return L["dismisses your pet"] end,
    PET_AUTOCASTON = function(unit) return string.format(L["turns autocast of %s on"], unit or "") end,
    PET_AUTOCASTOFF = function(unit) return string.format(L["turns autocast of %s off"], unit or "") end,
    PET_AUTOCASTTOGGLE = function(unit) return string.format(L["turns autocast of %s on or off"], unit or "") end,
    EQUIP_SET = function(unit) return string.format(L["puts on the equipment set %s"], unit or "") end,
    TARGET_NEAREST_ENEMY = function() return L["targets the nearest enemy"] end,
    TARGET_NEAREST_FRIEND = function() return L["targets the nearest friend"] end,
    TARGET_LAST_TARGET = function() return L["targets your last target"] end,
    TARGET_NEAREST_PARTY = function() return L["targets the nearest party member"] end,
    TARGET_NEAREST_RAID = function() return L["targets the nearest raid member"] end,
    CHANGEACTIONBAR = function(unit) return string.format(L["switches to action bar page %s"], unit or "") end,
}
-- What branch `action` of command `cmd` does for group `g`: the whole phrase, and the one after "if not," (for a
-- spell, only where it goes now).
local function Does(cmd, action, g)
    local P = ns.Parser
    local base = P.actionCommands[cmd]
    local unit = g.unit and g.unit:lower() ~= "cursor" and Explain.Unit(g.unit)
    local cursor = g.unit and g.unit:lower() == "cursor"
    if base == "cast" or base == "use" or base == "castsequence" or base == "castrandom" or base == "userandom" then
        local what
        if action == "" then return L["does nothing"], L["does nothing"] end
        if base == "castsequence" then
            local reset, list = action:match("^reset=(%S+)%s*(.*)$")
            what = string.format(L["%s in turn, one each press"], List(list or action))
            if reset then what = what .. ", " .. string.format(L["starting over %s"], Reset(reset)) end
        elseif base == "castrandom" or base == "userandom" then
            what = string.format(L["one of %s at random"], List(action))
        else
            what = Explain.Name(action)
        end
        unit = unit or ((#g.checks > 0 or g.exists ~= nil) and L["your target"]) or nil
        if cursor then return string.format(L["%s at the cursor"], what), L["at the cursor"] end
        if unit then return string.format(L["%s on %s"], what, unit), string.format(L["on %s"], unit) end
        return what, string.format(L["on %s"], L["your target"])
    elseif base == "equip" then
        local s = action == "" and L["does nothing"] or string.format(L["equips %s"], Explain.Name(action))
        return s, s
    elseif base == "equipslot" then
        local slot, item = action:match("^(%d+)%s+(.+)$")
        local s = slot and string.format(L["equips %s in %s"], Explain.Name(item), SlotName(slot))
            or L["does nothing"]
        return s, s
    elseif base == "cancelaura" then
        local s = action == "" and L["does nothing"] or string.format(L["cancels %s"], Explain.Name(action))
        return s, s
    elseif P.stopCommands[cmd] then
        return L["the macro stops here"], L["the macro stops here"]
    elseif P.clickCommands[cmd] then
        local s = string.format(L["clicks %s"], action:match("^(%S+)") or "")
        return s, s
    end
    return nil
end

-- One "/command options" line: { phrases }, or nil when the line can't be read (a bracket not closed).
local function CommandLine(cmd, rest, env)
    local P = ns.Parser
    if P.luaCommands[cmd] then return { L["runs Lua code"] } end
    if P.chatCommands[cmd] then return { string.format(L["writes in chat: %s"], rest) } end
    local key = (env.commandKey and env.commandKey(cmd)) or ENGLISH[cmd]
    local secure = key and SECURE[key]
    if not (secure or P.actionCommands[cmd] or P.stopCommands[cmd] or P.clickCommands[cmd]) then
        return { string.format(L["runs /%s"], cmd) }
    end
    local branches = Explain.Branches(rest)
    if not branches then return nil end
    local out = {}
    for i, b in ipairs(branches) do
        local groups = #b.groups > 0 and b.groups or { {} }
        local always = false -- a group that always holds: the game goes no further
        for j, conds in ipairs(groups) do
            local g = Group(conds, env)
            local full, short
            if secure then
                -- The unit, else what the line names (a player, an equipment set, a pet's spell, a bar page).
                local unit = (g.unit and g.unit:lower() ~= "cursor" and Explain.Unit(g.unit))
                    or (b.action ~= "" and b.action) or nil
                full = secure(unit, g.unit and g.unit:lower() == "cursor")
                short = full
            else
                full, short = Does(cmd, b.action, g)
            end
            local parts = { j == 1 and full or short }
            parts[#parts + 1] = Checks(g)
            -- One group: its other conditions say when; with several, each has its own.
            local when = table.concat(g.states, ", ")
            if #groups > 1 and when ~= "" then parts[#parts + 1] = when end
            local text = table.concat(parts, ", ")
            if #groups > 1 then
                if j > 1 then
                    text = "  " .. string.format(L["if not, %s"], text)
                elseif i > 1 then
                    text = string.format(L["otherwise: %s"], text)
                end
            elseif i == 1 then
                text = when ~= "" and string.format(L["%s: %s"], when, text) or text
            else
                text = when ~= "" and string.format(L["otherwise, %s: %s"], when, text)
                    or string.format(L["otherwise: %s"], text)
            end
            out[#out + 1] = text
            if not g.conditional then
                always = true
                break
            end
        end
        if always then break end
    end
    return out
end

-- What line `line` of a macro does, in phrases (each a line of the tooltip), or nil for an empty line or one
-- that can't be read. env: { formName(n), specName(n), commandKey(name) -> "TARGET" ... }, each optional.
function Explain.Line(line, env)
    env = env or {}
    if not line:find("%S") then return nil end
    local meta, options = line:match("^%s*#(%a+)(.*)$")
    meta = meta and meta:lower()
    if meta == "showtooltip" or meta == "show" then
        local shows = meta == "show" and L["shows the icon of %s"] or L["shows the icon and tooltip of %s"]
        if not options:find("%S") then
            return { string.format(shows, L["the spell or item the macro uses"]) }
        end
        local branches = Explain.Branches(options)
        if not branches then return nil end
        local out = {}
        for i, b in ipairs(branches) do
            local g = Group(b.groups[1] or {}, env)
            local when = table.concat(g.states, ", ")
            local text = string.format(shows, Explain.Name(b.action))
            if i == 1 then
                out[#out + 1] = when ~= "" and string.format(L["%s: %s"], when, text) or text
            else
                out[#out + 1] = when ~= "" and string.format(L["otherwise, %s: %s"], when, text)
                    or string.format(L["otherwise: %s"], text)
            end
        end
        return out
    end
    if meta then return nil end
    local cmd, rest = line:match("^%s*/(%S+)%s*(.*)$")
    if not cmd then return { L["says it in chat"] } end
    return CommandLine(cmd:lower(), rest, env)
end

-- Every text this file shows, for the translation check: the tables' words.
function Explain.Texts()
    local out = {}
    for _, t in ipairs({ UNITS, NUMBERED, BUTTONS, SIDES }) do
        for _, s in pairs(t) do out[#out + 1] = s end
    end
    for _, t in ipairs({ CHECKS, STATES }) do
        for _, s in pairs(t) do
            for _, text in ipairs(s) do out[#out + 1] = text end
            for _, text in ipairs(s.value or {}) do out[#out + 1] = text end
        end
    end
    return out
end

return Explain
