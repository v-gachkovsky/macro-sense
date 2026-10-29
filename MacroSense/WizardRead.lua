-- A macro back in the wizard's form: the answers that make it (Wizard.Read), and the lines of it the wizard writes
-- otherwise or not at all. Pure Lua (5.1); the text comes from Wizard.lua.
local _, ns = ...
ns = ns or {}
local W = ns.Wizard

local function Trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Other names of the same command, to the game.
local ALIASES = {
    s = "say", y = "yell", p = "party", ra = "raid", e = "emote", me = "emote", spell = "cast",
    userandom = "castrandom", script = "run",
}
local CHAT = { say = true, yell = true, party = true, raid = true, emote = true }
local PET_OF = {} -- "/petfollow" -> "follow"
for _, a in ipairs(W.petActions) do PET_OF[a.command:sub(2)] = a.key end
local KEY_OF = {} -- "mod:shift" -> "shift"
for _, key in ipairs(W.KEYS) do KEY_OF["mod:" .. key] = key end
local WHEN_OF = { ["group:party"] = { "group", "party" } } -- "nocombat" -> the When row's combat, "no"
for _, w in ipairs(W.whens) do
    for _, item in ipairs(w.items or {}) do
        if item.cond then WHEN_OF[item.cond] = { w.key, item.key } end
    end
end
local PLACE_OF = {} -- "swimming" -> "swim"
for _, p in ipairs(W.mountPlaces) do
    if p.cond then PLACE_OF[p.cond] = p.key end
end
local UNIT = {}
for _, u in ipairs(W.units) do UNIT[u.key] = true end

-- A condition as the wizard writes it: "target=focus" -> "@focus", "modifier:shift" -> "mod:shift".
local function Cond(c)
    c = Trim(c):lower():gsub("%s+", "")
    c = c:gsub("^target=", "@"):gsub("^modifier", "mod"):gsub("^nomodifier", "nomod")
    c = c:gsub("^stance", "form"):gsub("^nostance", "noform")
    return c
end

-- What a group of conditions says, in the form's words: the key held, the unit, its check, the When row; what the
-- mount and pet macros check (nomounted, the place, nomod); `other` for what the form has no place for.
local function Group(conds)
    local g = { unit = "default", when = {} }
    for _, raw in ipairs(conds) do
        local c = Cond(raw)
        local unit = c:match("^@(.+)$")
        if unit then
            g.unit = unit
        elseif KEY_OF[c] then
            g.key = KEY_OF[c]
        elseif c == "help" or c == "harm" or c == "exists" then
            g.check = c
        elseif c == "nodead" then
            g.alive = true
        elseif WHEN_OF[c] then
            g.when[WHEN_OF[c][1]] = WHEN_OF[c][2]
        elseif c == "noform" or c == "form:0" then
            g.when.form = "0"
        elseif c:match("^form:%d+$") then
            g.when.form = c:sub(6)
        elseif c == "nomounted" then
            g.nomounted = true
        elseif PLACE_OF[c] then
            g.place = PLACE_OF[c]
        elseif c == "nomod" or c:match("^nomod:") then
            g.nomod = c:match("^nomod:(.+)$") or ""
        else
            g.other = true
        end
    end
    if g.unit == "default" and g.check then g.unit = "target" end
    if not UNIT[g.unit] then g.other = true end
    return g
end

-- "Shadow Bolt(Rank 3)" -> { name = "Shadow Bolt", rank = "Rank 3" }.
local function Action(text, item)
    local name, rank = text:match("^(.-)%s*%((.+)%)$")
    if name and name ~= "" then return { name = name, rank = rank, item = item or nil } end
    return { name = text, item = item or nil }
end

local function Pad(units, n)
    for i = #units + 1, n do units[i] = "none" end
    for i = #units, n + 1, -1 do units[i] = nil end
    return units
end

local ONLY = { help = "friends", harm = "enemies", exists = "any" }

-- Friends, enemies or anyone, as the groups check them (the macro's own first: a key's own spell is checked for
-- what it is for); and whether the dead are left out.
local function Checks(spec, groups)
    for pass = 1, 2 do
        for _, g in ipairs(groups) do
            if g.check and (pass == 2 or not g.key) then
                spec.only = ONLY[g.check]
                break
            end
        end
        if spec.only ~= "any" then break end
    end
    spec.alive = false
    for _, g in ipairs(groups) do spec.alive = spec.alive or g.alive == true end
end

-- The groups of a line's branches, each with its branch's action and whether it is the last branch.
local function Groups(rest)
    local branches = ns.Explain.Branches(rest)
    if not branches then return nil end
    local out = {}
    for i, b in ipairs(branches) do
        for _, conds in ipairs(#b.groups > 0 and b.groups or { {} }) do
            local g = Group(conds)
            g.action, g.last, g.bare = b.action, i == #branches, #b.groups <= 1 and #conds == 0
            out[#out + 1] = g
        end
    end
    return out
end

local function HasWhen(when) return next(when) ~= nil end

-- "/cast [mod:shift,@player] Heal; [@mouseover,help,nodead][] Flash Heal": the keys' units and spells, the units
-- in order, the When row, and what it casts otherwise (a last clause that always holds).
local function ReadCast(spec, rest, item)
    local groups = Groups(rest)
    if not groups then return end
    local main, read, whenSet = {}, {}, false
    for _, g in ipairs(groups) do
        if g.action ~= "" and not g.other and not g.nomounted and not g.place and not g.nomod then
            if not whenSet then spec.when, whenSet = g.when, true end
            local action = Action(g.action, item)
            if g.key then
                local k = spec.keys[g.key]
                if not k.active then k.active, k.on, k.action = true, {}, action end
                k.on[#k.on + 1] = g.unit
                k.reaction = k.reaction or (g.check and g.check ~= "exists" and ONLY[g.check]) or nil
            elseif g.last and g.bare and HasWhen(spec.when) and #main > 0 then
                spec.otherwise = action
            else
                spec.action = spec.action or action
                main[#main + 1] = g.unit
            end
            read[#read + 1] = g
        end
    end
    spec.on = Pad(#main > 0 and main or { "default" }, 3)
    for _, key in ipairs(W.KEYS) do
        local k = spec.keys[key]
        if k.active then
            Pad(k.on, 2)
            -- The macro's own spell: a key "casts the same".
            if spec.action and k.action and W.Spelled(k.action) == W.Spelled(spec.action) then k.action = nil end
        end
    end
    Checks(spec, read)
end

-- "/castsequence [@focus,harm,nodead][] reset=10/target Corruption, Immolate".
local function ReadList(spec, rest)
    local groups = Groups(rest)
    if not groups then return end
    local units, read = {}, {}
    for _, g in ipairs(groups) do
        if not g.other and not g.key and not g.nomounted and not g.place and not g.nomod then
            if #read == 0 then spec.when = g.when end
            units[#units + 1], read[#read + 1] = g.unit, g
        end
    end
    spec.on = Pad(#units > 0 and units or { "default" }, 3)
    Checks(spec, read)
    local names = groups[#groups].action
    local reset, list = names:match("^reset=(%S+)%s+(.*)$")
    if reset then
        names = list
        spec.reset = { seconds = 10 }
        for v in reset:gmatch("[^/]+") do
            local value = v:lower()
            if tonumber(value) then
                spec.reset.timed, spec.reset.seconds = true, tonumber(value)
            else
                spec.reset[value] = true
            end
        end
    end
    local i = 0
    for n in (names .. ","):gmatch("([^,]*),") do
        local name = Trim(n)
        if name ~= "" and i < W.LIST then
            i = i + 1
            spec.list[i] = Action(name)
        end
    end
end

-- "/target [mod:alt,@focus,exists][@mouseover,harm,nodead][] Hogger": units for the keys and in order, a name to
-- look for last.
local function ReadTarget(spec, rest)
    local groups = Groups(rest)
    if not groups then return end
    local main, read = {}, {}
    for i, g in ipairs(groups) do
        if g.unit == "default" then g.unit = "target" end
        local named = g.action ~= "" and (i == #groups or groups[i + 1].action ~= g.action)
        if named and spec.command == "target" then
            -- The name's own group: only the When row, if anything.
            spec.byName = g.action
            if #read == 0 then spec.when = g.when end
        elseif not g.other and not g.nomounted and not g.place and not g.nomod then
            if #read == 0 then spec.when = g.when end
            if g.key then
                local k = spec.keys[g.key]
                if not k.active then k.active, k.on = true, {} end
                k.on[#k.on + 1] = g.unit
            else
                main[#main + 1] = g.unit
            end
            read[#read + 1] = g
        end
    end
    spec.on = Pad(main, 3)
    for _, key in ipairs(W.KEYS) do
        if spec.keys[key].active then Pad(spec.keys[key].on, 2) end
    end
    Checks(spec, read)
end

-- "/cleartarget [mod:shift/alt]": those keys clear the target (the /stopmacro after it comes with them).
local function ReadClear(spec, rest)
    local mods = rest:match("^%[%s*mod:([%a/]+)%s*%]$") or rest:match("^%[%s*modifier:([%a/]+)%s*%]$")
    for key in (mods or ""):lower():gmatch("[^/]+") do
        if spec.keys[key] then spec.keys[key].active, spec.keys[key].on = true, { "clear", "none" } end
    end
end

-- "/petattack [nomod:shift,@mouseover,harm,nodead][nomod:shift]", "/petfollow [mod:shift]": what the pet does
-- without a key held, and with each.
local function ReadPet(spec, command, rest)
    local groups = Groups(rest)
    if not groups then return end
    local key, units, read = nil, {}, {}
    for _, g in ipairs(groups) do
        key = key or g.key
        if #read == 0 then spec.when = g.when end
        if command == "attack" and not g.other then units[#units + 1] = g.unit end
        read[#read + 1] = g
    end
    if key then
        local k = spec.keys[key]
        k.active, k.pet = true, command
        if command == "attack" then k.on = Pad(units, 2) end
    else
        spec.pet = command
        if command == "attack" then spec.on = Pad(units, 3) end
    end
    if command == "attack" then Checks(spec, read) end
end

-- "/equipset [nocombat] PvP", "/equip [mod:shift] Shield", "/equipslot 14 Charm".
local function ReadEquip(spec, command, rest)
    local groups = Groups(rest)
    if not groups or #groups ~= 1 then return end
    local g = groups[1]
    spec.when = g.when
    if command == "equipset" then
        spec.equipSet = g.action ~= "" and g.action or nil
        return
    end
    local slot, name = "", g.action
    if command == "equipslot" then slot, name = g.action:match("^(%d+)%s+(.+)$") end
    if not slot then return end
    for _, piece in ipairs(spec.equip) do
        if not piece.item then
            piece.item, piece.slot = { name = name, item = true }, slot
            piece.key = g.key or (g.nomod == "" and "none") or "always"
            return
        end
    end
end

-- "/cast [nomounted,mod:shift] Ground; [nomounted,swimming] Water; [nomounted,flyable] Flying; [nomounted] Ground".
local function ReadMount(spec, rest)
    for _, g in ipairs(Groups(rest) or {}) do
        if g.action ~= "" and not g.other then
            local action = Action(g.action)
            if g.key then
                spec.keys[g.key].active, spec.keys[g.key].action = true, action
            else
                spec.mounts[g.place or "ground"] = spec.mounts[g.place or "ground"] or action
            end
        end
    end
end

-- Whether a /cast line calls a mount: it checks that you are not on one, or where you are (water, flying).
local function IsMount(rest)
    for _, g in ipairs(Groups(rest) or {}) do
        if g.nomounted or g.place then return true end
    end
    return false
end

local MAIN = { cast = "cast", use = "use", castsequence = "list", castrandom = "list", target = "target",
    focus = "target", assist = "target", equip = "equip", equipslot = "equip", equipset = "equip" }

-- A line as the wizard would write it, to tell whether the wizard's text has it: no spaces it doesn't need,
-- lower case, the conditions of a group in one order, "[]" alone left out, @target left out where it changes
-- nothing (a cast goes to the target anyway).
local function Norm(line)
    line = Trim(line)
    if line == "" then return nil end
    if line:lower():find("^#show") then return "#show" end
    local cmd, rest = line:match("^/(%S+)%s*(.-)$")
    if not cmd then return line:lower() end
    cmd = cmd:lower()
    cmd = ALIASES[cmd] or cmd
    if CHAT[cmd] then return "/" .. cmd .. " " .. rest end
    local branches = ns.Explain.Branches(rest)
    if not branches then return "/" .. cmd .. " " .. rest:lower() end
    local parts = {}
    for i, b in ipairs(branches) do
        local groups = {}
        for _, g in ipairs(b.groups) do
            local conds = {}
            for _, c in ipairs(g) do
                c = Cond(c)
                if c ~= "@target" or W.IsTarget(cmd) then conds[#conds + 1] = c end
            end
            table.sort(conds)
            groups[#groups + 1] = "[" .. table.concat(conds, ",") .. "]"
        end
        if #groups == 1 and groups[1] == "[]" then groups = {} end
        parts[i] = table.concat(groups) .. b.action:lower():gsub("%s*,%s*", ","):gsub("%s+", " ")
    end
    return "/" .. cmd .. " " .. table.concat(parts, ";")
end

-- The form's answers for the macro `text`, and its lines the wizard's text has not (written otherwise or left
-- out; the empty ones and #showtooltip don't count). nil when the wizard can't make it: nothing in it casts,
-- uses, targets, tells the pet, calls a mount or puts on gear.
function W.Read(text)
    local spec = W.Fresh()
    local lines = {}
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local trimmed = Trim(line)
        local cmd, rest = trimmed:match("^/(%S+)%s*(.-)$")
        cmd = cmd and cmd:lower()
        lines[#lines + 1] = { text = trimmed, cmd = cmd and (ALIASES[cmd] or cmd), rest = rest }
    end
    -- What the macro is: the first line with a command the form makes. A bare "/use 13" or "/petattack" is one
    -- only when nothing else is.
    local kind
    for _, l in ipairs(lines) do
        local main = MAIN[l.cmd]
        if main == "use" and (l.rest == "13" or l.rest == "14") then main = nil end
        if main == "cast" and IsMount(l.rest) then main = "mount" end
        if not main and PET_OF[l.cmd] and (l.cmd ~= "petattack" or l.rest ~= "") then main = "pet" end
        if main then
            kind = main
            break
        end
    end
    if not kind then
        for _, l in ipairs(lines) do
            if l.cmd == "petattack" then kind = "pet" end
        end
    end
    spec.command = kind == "list" and "castsequence" or kind == "target" and "target" or kind or "cast"
    local done = false -- the line of a /cast, a list or /target is read; more of them are not the form's
    for _, l in ipairs(lines) do
        local cmd, rest = l.cmd, l.rest
        local trinket = cmd == "use" and (rest == "13" or rest == "14")
        if not cmd then
            -- #showtooltip, empty lines, text: nothing of the form
        elseif (kind == "cast" or kind == "use") and cmd == kind and not done and not trinket then
            ReadCast(spec, rest, kind == "use")
            done = true
        elseif kind == "mount" and cmd == "cast" and not done then
            ReadMount(spec, rest)
            done = true
        elseif kind == "list" and MAIN[cmd] == "list" and not done then
            spec.command = cmd
            ReadList(spec, rest)
            done = true
        elseif kind == "target" and MAIN[cmd] == "target" and not done then
            spec.command = cmd
            ReadTarget(spec, rest)
            done = true
        elseif kind == "target" and (cmd == "cleartarget" or cmd == "clearfocus") then
            ReadClear(spec, rest)
        elseif kind == "pet" and PET_OF[cmd] then
            ReadPet(spec, PET_OF[cmd], rest)
        elseif kind == "equip" and MAIN[cmd] == "equip" then
            ReadEquip(spec, cmd, rest)
        elseif cmd == "stopcasting" and rest == "" then
            spec.stopcasting = true
        elseif cmd == "cancelform" and rest == "" then
            spec.cancelform = true
        elseif cmd == "dismount" and kind == "mount" then
            spec.dismount = Cond(rest:gsub("[%[%]]", "")) -- "mounted,noflying" or "mounted"
        elseif cmd == "dismount" and Cond(rest) == "[mounted]" then
            spec.dismount = true
        elseif cmd == "cancelaura" and rest ~= "" then
            spec.cancelaura = { name = rest }
        elseif cmd == "targetenemy" and Cond(rest) == "[noharm][dead]" then
            spec.nearest = true
        elseif trinket then
            spec[rest == "13" and "trinket1" or "trinket2"] = true
        elseif cmd == "startattack" and rest == "" then
            spec.startattack = true
        elseif cmd == "petattack" and rest == "" then
            spec.petattack = true
        elseif CHAT[cmd] and rest ~= "" then
            spec.channel, spec.say = cmd, rest
        end
    end
    if kind == "mount" then
        local off = spec.dismount
        spec.offMount = off == "mounted,noflying" and "safe" or off and "always" or "no"
        spec.dismount = nil
    end
    local made = W.Text(spec)
    if not made then return nil end
    local has, lost = {}, {}
    for line in (made .. "\n"):gmatch("([^\n]*)\n") do
        local n = Norm(line)
        if n then has[n] = true end
    end
    for _, l in ipairs(lines) do
        local n = Norm(l.text)
        if n and not has[n] and n ~= "#show" then lost[#lost + 1] = l.text end
    end
    return spec, lost
end

return W
