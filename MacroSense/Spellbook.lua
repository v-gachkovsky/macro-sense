-- Macros from the spellbook: a macro for each spell you pick, /cast with no rank (in the older flavors it casts the
-- highest one learned), at the unit you choose, with /startattack or /stopcasting where they help. A spell that
-- doesn't fit in your macros joins another one on a key held; a lower rank can go on a key too; the pet gets one
-- macro for its commands. A spell some macro casts already (with macro sets on, one behind the scenes too) and one
-- you left out before are not offered again; one whose macro you deleted is, and those you learn later. The wizard writes the macros (Wizard.Text). Pure Lua (5.1): the
-- spellbook comes in a kit, Spellbook.Kit makes it in game.
local _, ns = ...
ns = ns or {}

local Spellbook = {}
ns.Spellbook = Spellbook

-- Interrupts, by spell ID: their macros stop what you are casting first. The names come from the game, in its
-- language. Earth Shock interrupts in the older flavors only.
local INTERRUPTS = { 6552, 72, 1766, 2139, 57994, 47528, 147362, 187707, 34490, 183752, 116705, 96231, 106839, 78675,
    15487, 351338, 119910, 19244, 16979 }
local OLD_INTERRUPTS = { 8042 }
-- Spells that keep an enemy out of the fight, or need you unseen: /startattack would break them at once.
local CONTROL = { 6770, 1776, 2094, 921, 1725, 118, 20066, 2637, 33786, 339, 51514, 5246, 115078, 217832, 19503,
    19386, 1499, 5782, 6358, 9484, 605, 8122, 5484, 710, 10326, 2878 }
-- Classes that fight in melee: /startattack is on for them at first.
local MELEE = { WARRIOR = true, ROGUE = true, PALADIN = true, DEATHKNIGHT = true, MONK = true, DEMONHUNTER = true }

local MAX_NAME = 16 -- letters, as in the Blizzard macro window
local MAX_BODY = MAX_MACRO_CHARACTERS or 255

local function Letters(s) return select(2, s:gsub("[^\128-\191]", "")) end

-- The commands that cast or use what they name.
local CASTS = { cast = true, use = true, spell = true, castsequence = true, castrandom = true, userandom = true }

-- The spells and items a macro casts or uses, lowercase, with no rank: "/cast [mod] !Frost Nova; Frostbolt(Rank 2)"
-- casts frost nova and frostbolt.
function Spellbook.Casts(body)
    local out = {}
    for line in (body or ""):gmatch("[^\n]+") do
        local command, rest = line:match("^%s*/(%a+)%s*(.*)$")
        if command and CASTS[command:lower()] then
            for option in (rest .. ";"):gmatch("([^;]*);") do
                local part = option:gsub("%b[]", "")
                part = part:gsub("reset=%S*", "")
                for item in (part .. ","):gmatch("([^,]*),") do
                    local name = item:gsub("%b()", "")
                    name = name:gsub("^[%s!]+", ""):gsub("%s+$", "")
                    if name ~= "" then out[name:lower()] = true end
                end
            end
        end
    end
    return out
end

-- A name of up to 16 letters: the spell's, or shorter as players write it: "SW: Pain" for Shadow Word: Pain, "BoK"
-- for Blessing of Kings.
function Spellbook.Name(spell)
    if Letters(spell) <= MAX_NAME then return spell end
    local function initials(words)
        local out = ""
        for word in words:gmatch("%S+") do out = out .. word:match("^[%z\1-\127\194-\244][\128-\191]*") end
        return out
    end
    local before, after = spell:match("^(.-):%s*(.+)$")
    if before then
        local short = initials(before) .. ": " .. after
        if Letters(short) <= MAX_NAME then return short end
    end
    return initials((spell:gsub(":", " ")))
end

-- Who a spell goes to, as the form asks it: "harm" (enemies), "help" (friends, others too), "self" (nobody to choose:
-- Ice Block, Blink, Bear Form, and a spell whose tooltip says no range: Howl of Terror, Demonic Circle).
local function Kind(S, spell)
    local name = spell.name
    if S.targeted and S.targeted(spell.id) == false then return "self" end
    local reaction = S.reaction and S.reaction(name)
    if reaction == "enemies" then return "harm" end
    if reaction == "friends" and S.selfOnly and S.selfOnly(name) == false then return "help" end
    return "self"
end

-- The spellbook and the macros, from the game: { class, mac, spells = { name, ranks, general, kind, interrupt,
-- control } in book order (another specialization's left out), macros = { name, body, scope }, free = the
-- character's empty macro slots, pet = whether you have a pet to command }.
function Spellbook.Kit()
    local S = ns.sources
    local spellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
    local class = UnitClass and select(2, UnitClass("player"))
    local function names(list)
        local out = {}
        for _, id in ipairs(list) do
            local ok, name = pcall(spellName, id)
            if ok and name then out[name:lower()] = true end
        end
        return out
    end
    local interrupts, control = names(INTERRUPTS), names(CONTROL)
    local kit = { class = class, mac = IsMacClient and IsMacClient() or false, spells = {}, macros = {} }
    local spells = S.spells and S.spells() or {}
    -- The older flavors (their spells have ranks) take Earth Shock for an interrupt too.
    for _, s in ipairs(spells) do
        if #s.ranks > 0 then
            for name in pairs(names(OLD_INTERRUPTS)) do interrupts[name] = true end
            break
        end
    end
    for _, s in ipairs(spells) do
        if not s.offSpec then
            local key = s.name:lower()
            kit.spells[#kit.spells + 1] = { name = s.name, ranks = s.ranks, general = s.general,
                kind = Kind(S, s), interrupt = interrupts[key] or nil, control = control[key] or nil }
        end
    end
    local general, character = GetNumMacros()
    local function add(scope, index)
        local name, _, body = GetMacroInfo(index)
        if name then kit.macros[#kit.macros + 1] = { name = name, body = body or "", scope = scope } end
    end
    for index = 1, general do add("general", index) end
    for index = ns.MAX_GENERAL + 1, ns.MAX_GENERAL + character do add("character", index) end
    -- With macro sets on, the macros behind the scenes are yours too: each set's, every specialization's.
    local sets = ns.Sets and ns.Sets.Mine()
    if sets and sets.enabled then
        local seen = {}
        for _, m in ipairs(kit.macros) do seen[m.name] = true end
        local ids = { "class", "character" }
        for _, spec in ipairs(ns.Sets.Specs()) do ids[#ids + 1] = spec.key end
        for key in pairs(sets.specs) do ids[#ids + 1] = key end
        for _, id in ipairs(ids) do
            for _, m in ipairs(ns.Sets.List(id)) do
                if not seen[m.name .. "\0" .. (m.body or "")] then
                    seen[m.name .. "\0" .. (m.body or "")] = true
                    kit.macros[#kit.macros + 1] = { name = m.name, body = m.body or "", scope = "character" }
                end
            end
        end
    end
    kit.free = ns.MAX_CHARACTER - character
    kit.pet = (HasPetSpells and HasPetSpells() ~= nil) or class == "HUNTER" or class == "WARLOCK"
    kit.petMacro = Spellbook.PetMacro(kit.macros)
    -- Whether the spells have ranks here (the older flavors).
    kit.ranks = false
    for _, s in ipairs(kit.spells) do
        if #s.ranks > 0 then kit.ranks = true end
    end
    return kit
end

-- The name of a macro that commands the pet (/petattack, /petfollow...), or nil.
function Spellbook.PetMacro(macros)
    for _, m in ipairs(macros) do
        for line in m.body:gmatch("[^\n]+") do
            if line:match("^%s*/pet%a") then return m.name end
        end
    end
end

-- What MacroSense remembers of the spellbook, per character: { seen = spell -> true (offered once), made = spell ->
-- { name, body } (the macro made for it, as written) }.
function Spellbook.Journal(char)
    char.spellbook = char.spellbook or {}
    local j = char.spellbook
    j.seen, j.made = j.seen or {}, j.made or {}
    return j
end

-- The spells to offer, in book order: { spell, state, macro, checked }. State: "has" (a macro casts it: `macro`),
-- "deleted" (the one made for it is gone), "skipped" (left out before), "new" (learned since the last time) or
-- "offer" (the first time). Checked at first: the new ones, those whose macro was deleted, and the first time those
-- not in the first tab.
function Spellbook.Rows(kit, journal)
    local casts = {}
    for _, m in ipairs(kit.macros) do
        for name in pairs(Spellbook.Casts(m.body)) do casts[name] = casts[name] or m.name end
    end
    local before = next(journal.seen) ~= nil
    local rows = {}
    for _, spell in ipairs(kit.spells) do
        local has = casts[spell.name:lower()]
        local state = has and "has" or journal.made[spell.name] and "deleted" or journal.seen[spell.name] and "skipped"
            or before and "new" or "offer"
        rows[#rows + 1] = { spell = spell, state = state, macro = has,
            checked = state == "new" or state == "deleted" or (state == "offer" and not spell.general) }
    end
    return rows
end

-- The choices of a fresh form: spells at your target, as on the action bars; /startattack for the classes that
-- fight in melee; /stopcasting for interrupts; the pet, unless some macro commands it already, attacks the enemy
-- under the mouse, or the target, and follows with Shift.
function Spellbook.Fresh(kit)
    return { picked = {}, units = { harm = "target", help = "target" }, unitOf = {}, join = {}, lower = {},
        startattack = MELEE[kit.class or ""] == true, stopcasting = true, bars = true,
        pet = kit.pet and not kit.petMacro and { none = "attack", shift = "follow" } or nil, petMouseover = true }
end

-- Where a spell of `kind` goes: { units in order }, and what they must be.
local function Units(kind, choice)
    if kind == "self" or choice == "target" then return { "default" }, "any" end
    return { choice, "default" }, kind == "harm" and "enemies" or "friends"
end

-- The macros the choices make: { name, body, spells = names in it, pet = true for the pet's }, in book order, and
-- what is wrong: spell -> why (a key taken twice, joining a spell not made, a macro too long).
function Spellbook.Plan(kit, choices)
    local W = ns.Wizard
    local byName, problems, macros = {}, {}, {}
    for _, s in ipairs(kit.spells) do byName[s.name] = s end
    local function unitsOf(spell) return Units(spell.kind, choices.unitOf[spell.name] or choices.units[spell.kind]) end
    -- What goes on the keys of each macro: { key, spell, rank }, from joins and lower ranks.
    local keys = {}
    local function put(into, key, spell, rank, who)
        keys[into] = keys[into] or {}
        for _, k in ipairs(keys[into]) do
            if k.key == key then
                problems[who] = string.format(ns.L["%s already has a spell on this key."], into)
                return
            end
        end
        table.insert(keys[into], { key = key, spell = spell, rank = rank })
    end
    for _, s in ipairs(kit.spells) do
        local join = choices.picked[s.name] and choices.join[s.name]
        if join then
            local into = byName[join.into]
            if not into or not choices.picked[into.name] or choices.join[into.name] or into == s then
                problems[s.name] = ns.L["Join it to a spell that gets a macro of its own."]
            else
                put(into.name, join.key, s, nil, s.name)
            end
        end
        local lower = choices.picked[s.name] and choices.lower[s.name]
        if lower and not choices.join[s.name] then put(s.name, lower.key, s, lower.rank, s.name) end
    end
    for _, s in ipairs(kit.spells) do
        if choices.picked[s.name] and not choices.join[s.name] then
            local spec = W.Fresh()
            spec.action = { name = s.name, selfOnly = s.kind == "self" or nil }
            spec.on, spec.only = unitsOf(s)
            local all, attack, stop = { s.name }, s.kind == "harm" and not s.control, s.interrupt
            for _, k in ipairs(keys[s.name] or {}) do
                local held = spec.keys[k.key]
                held.active, held.action = true, { name = k.spell.name, rank = k.rank }
                held.on = unitsOf(k.spell)
                held.reaction = k.spell.kind == "harm" and "enemies" or k.spell.kind == "help" and "friends" or nil
                if k.spell ~= s then all[#all + 1] = k.spell.name end
                attack = attack and k.spell.kind == "harm" and not k.spell.control
                stop = stop and k.spell.interrupt
            end
            spec.startattack = choices.startattack and attack or nil
            spec.stopcasting = choices.stopcasting and stop or nil
            local body = W.Text(spec)
            if Letters(body) > MAX_BODY then
                problems[s.name] = string.format(ns.L["The macro would be longer than %d characters."], MAX_BODY)
            end
            macros[#macros + 1] = { name = Spellbook.Name(s.name), body = body, spells = all }
        end
    end
    if choices.pet then
        local spec = W.Fresh()
        spec.command, spec.pet = "pet", choices.pet.none or "attack"
        spec.on = choices.petMouseover and { "mouseover", "default" } or { "default" }
        spec.only = "enemies"
        for _, key in ipairs(W.KEYS) do
            local held = spec.keys[key]
            held.active, held.pet, held.on = choices.pet[key] ~= nil, choices.pet[key], spec.on
        end
        macros[#macros + 1] = { name = ns.L["Pet"], body = W.Text(spec), spells = {}, pet = true }
    end
    return macros, problems
end

-- After the macros are made: every spell offered is seen, and those made remembered with their macro as written
-- (`made`: spell -> { name, body }, the names the game took). A spell whose macro the game didn't make (`failed`)
-- is offered again as before.
function Spellbook.Remember(journal, rows, made, failed)
    for _, row in ipairs(rows) do
        if not (failed and failed[row.spell.name]) then journal.seen[row.spell.name] = true end
    end
    for spell, m in pairs(made) do journal.made[spell] = { name = m.name, body = m.body } end
end

return Spellbook
