-- Macro sets: the character's macro slots hold three layers. Class macros are the same on all your characters of
-- one class (ns.db.classMacros[class]); the character's own stay in all its specializations; a specialization's
-- come in when it is chosen and go when another one is (ns.Character().sets). A macro of any layer may wait off
-- the slots (parked) and come in later. The layers are kept with the account, so your other characters can copy
-- them. The planning is pure; the game part follows it.
--
-- A macro of a layer: { name, icon, body, parked = true when off the slots }. The class layer's are parked per
-- character (sets.classParked[name]): one class macro may be in the slots of one warlock and not of another.
local _, ns = ...
ns = ns or {}

local Sets = {}
ns.Sets = Sets

Sets.LAYERS = { "class", "character", "spec" }

local function Find(list, name)
    for i, m in ipairs(list) do
        if m.name == name then return m, i end
    end
end

------------------------------------------------------------------------
-- Planning (pure)
------------------------------------------------------------------------

-- The layer of each macro in the slots (`now`: { name, ... }): as known before (`known`: name -> layer), else the
-- specialization's when it has one of the name in the slots, else the character's. A macro is the class's only
-- when MacroSense made it so (from the class, or moved there): one of yours with a class macro's name stays yours.
function Sets.LayerOf(now, known, spec)
    local out = {}
    for _, m in ipairs(now) do
        local s = Find(spec, m.name)
        out[m.name] = known[m.name] or (s and not s.parked and "spec") or "character"
    end
    return out
end

-- Changing specialization: `now` the macros in the slots, each with its layer; `entering` the macros of the
-- specialization coming in; `limit` the slots; `works(m)`, if given, false for a macro whose spells the one coming in
-- doesn't have: with too little room, those wait first. Returns what the one going keeps (its macros in the slots,
-- as they are now), the names that leave the slots, the macros that come in, those of `entering` that wait (parked
-- before, or no room, or the name taken by a macro that stays), and the names that both leave and come in: those
-- are changed in place, so their buttons stay.
function Sets.Swap(now, layer, entering, limit, works)
    local leaving, drop, taken = {}, {}, {}
    for _, m in ipairs(now) do
        if layer[m.name] == "spec" then
            leaving[#leaving + 1] = { name = m.name, icon = m.icon, body = m.body }
            drop[#drop + 1] = m.name
        else
            taken[m.name] = true
        end
    end
    local room = limit - (#now - #drop)
    local order = {}
    for _, m in ipairs(entering) do
        if not (works and works(m) == false) then order[#order + 1] = m end
    end
    for _, m in ipairs(entering) do
        if works and works(m) == false then order[#order + 1] = m end
    end
    local add, wait = {}, {}
    for _, m in ipairs(order) do
        if not m.parked and room > 0 and not taken[m.name] then
            add[#add + 1] = m
            taken[m.name], room = true, room - 1
        else
            wait[#wait + 1] = m
        end
    end
    local dropped, edit = {}, {}
    for _, name in ipairs(drop) do dropped[name] = true end
    for _, m in ipairs(add) do
        if dropped[m.name] then edit[#edit + 1] = m.name end
    end
    return { leaving = leaving, drop = drop, add = add, wait = wait, edit = edit }
end

-- The class macros as this character should have them: those to make, those to change (their text or icon
-- changed on another character), those to remove (gone from the class), those it has already as its own (the same
-- name and text: they become the class's), and those that wait: no room, or the name taken by another macro
-- (`clash`). `now` the macros in the slots, with their layers.
function Sets.ClassPlan(now, layer, class, classParked, limit)
    local here, used = {}, 0
    for _, m in ipairs(now) do
        here[m.name] = m
        used = used + 1
    end
    local make, change, remove, wait, adopt, clash = {}, {}, {}, {}, {}, {}
    for _, m in ipairs(now) do
        if layer[m.name] == "class" and not Find(class, m.name) then
            remove[#remove + 1] = m.name
            used = used - 1
        end
    end
    for _, m in ipairs(class) do
        local there = here[m.name]
        if not classParked[m.name] then
            if there and layer[m.name] == "class" then
                if there.body ~= m.body or there.icon ~= m.icon then change[#change + 1] = m end
            elseif there and there.body == m.body then
                adopt[#adopt + 1] = m.name
            elseif there then
                wait[#wait + 1] = m
                clash[#clash + 1] = m.name
            elseif used >= limit then
                wait[#wait + 1] = m
            else
                make[#make + 1] = m
                used = used + 1
            end
        end
    end
    return { make = make, change = change, remove = remove, wait = wait, adopt = adopt, clash = clash }
end

-- The macros in the slots changed (by you, or on this character): each layer follows. A text or icon changed here
-- is kept in its layer (one not changed here leaves the layer's as it is); a renamed macro keeps its layer under
-- the new name; another set's of the same name is a macro of its own, and stays as it is. A deleted one leaves its
-- layer; a new one joins the character's. `before` and `after`: name -> { body, icon };
-- `layer` as of before. Returns the renamed: old -> new.
function Sets.Follow(before, after, layer, lists)
    local renamed, deleted = ns.History.Gone(before, after)
    local function listOf(name) return lists[layer[name] or "character"] end
    for old, new in pairs(renamed) do
        local m = Find(listOf(old), old)
        if m then m.name = new end
        layer[new], layer[old] = layer[old], nil
    end
    for _, name in ipairs(deleted) do
        local list = listOf(name)
        local _, i = Find(list, name)
        if i then table.remove(list, i) end
        layer[name] = nil
    end
    for name, m in pairs(after) do
        local list = listOf(name)
        local kept = Find(list, name)
        local was = before[name]
        -- Not changed here, the layer's stays: it may be newer (a class macro changed on another character).
        local changed = not was or was.body ~= m.body or was.icon ~= m.icon
        if kept then
            if changed then kept.body, kept.icon = m.body, m.icon end
        elseif not was then -- new here (one gone from its layer elsewhere is not brought back)
            list[#list + 1] = { name = name, icon = m.icon, body = m.body }
            layer[name] = layer[name] or "character"
        end
    end
    return renamed
end

-- Conditions that check what you can cast ([spec:2], [talent:...], [known:...]): a macro with them is meant for
-- more than one specialization.
local GUARDS = { spec = true, talent = true, pvptalent = true, known = true }
local function Guarded(body)
    for inner in (body or ""):gmatch("%[([^%]]*)%]") do
        for part in (inner .. ","):gmatch("([^,]*),") do
            local word = (part:match("^%s*(%a+)") or ""):lower()
            if GUARDS[word] or GUARDS[word:match("^no(.+)$") or ""] then return true end
        end
    end
    return false
end

-- Whether a macro works with the spells `known` (lowercase name -> true): true; or false and the class's spells it
-- casts that are not known; nil when it casts none of the class's spells (`class`: lowercase name -> the name), or
-- checks what you can cast itself.
function Sets.Works(body, known, class)
    if Guarded(body) then return nil end
    local missing, told = {}, false
    for name in pairs(ns.Spellbook.Casts(body)) do
        if class[name] then
            told = true
            if not known[name] then missing[#missing + 1] = class[name] end
        end
    end
    if not told then return nil end
    table.sort(missing)
    return #missing == 0, missing
end

-- The specializations of `keys` (each with its spells in `spells`) a macro works in; nil when that can't be told.
function Sets.WorksIn(body, spells, class, keys)
    local out = {}
    for _, key in ipairs(keys) do
        local works = Sets.Works(body, spells[key], class)
        if works == nil then return nil end
        if works then out[#out + 1] = key end
    end
    return out
end

-- Where the macros would go by the spells they cast, once the spells of two specializations or more are known
-- (`keys`, in order): one of the character's that works in one specialization only goes to it (not one a
-- specialization has already: the character's keeps that behind the scenes); one of a specialization's that works
-- in all goes back to the character's (unless another specialization has one of its name: a macro for each, on
-- purpose), one that works not there but in one other goes to that one. A move to a specialization with a macro of
-- that name is left out. Returns { name, from, to }.
function Sets.Sort(character, specs, spells, class, keys)
    if #keys < 2 then return {} end
    local out = {}
    local function add(m, from, to)
        local there = Find(to == "character" and character or specs[to] or {}, m.name)
        if not there or (to == "character" and there.body == m.body) then
            out[#out + 1] = { name = m.name, from = from, to = to }
        end
    end
    for _, m in ipairs(character) do
        local works = Sets.WorksIn(m.body, spells, class, keys)
        if works and #works == 1 then add(m, "character", works[1]) end
    end
    for _, key in ipairs(keys) do
        for _, m in ipairs(specs[key] or {}) do
            local works = Sets.WorksIn(m.body, spells, class, keys)
            if works and #works == #keys then
                local twin = false
                for _, other in ipairs(keys) do
                    if other ~= key and Find(specs[other] or {}, m.name) then twin = true end
                end
                if not twin then add(m, key, "character") end
            elseif works and #works == 1 and works[1] ~= key then
                add(m, key, works[1])
            end
        end
    end
    return out
end

-- The macro buttons to put back for a specialization: { slot, name } of `record` (slot -> name) where the slot is
-- empty, has a macro the game has no more, or another of the character's macros (its place may have moved), and
-- the macro is in the slots. `at(slot)` says what is there: nil, "gone", "character" with the name, or anything
-- else (a spell, an item, a general macro), which stays.
function Sets.BarsBack(record, at, have)
    local out = {}
    for slot, name in pairs(record) do
        local kind, there = at(slot)
        if have[name] and (kind == nil or kind == "gone" or (kind == "character" and there ~= name)) then
            out[#out + 1] = { slot = slot, name = name }
        end
    end
    table.sort(out, function(a, b) return a.slot < b.slot end)
    return out
end

------------------------------------------------------------------------
-- The game
------------------------------------------------------------------------
local MAX_SLOT = 180
local pending -- a change waits for the end of combat
-- MacroSense changes the slots now: the game tells of each macro made or deleted while it is done, not after.
-- Those are not your changes: not followed, no versions, no trash (Core skips them); learned once it is over.
local busy
local touched -- MacroSense made, changed or deleted a macro while busy
local placing = 0 -- until when MacroSense puts the buttons of the specialization back
local fresh = { names = {} } -- the macros made for specialization `key` when it was chosen last

function Sets.Busy() return busy end

-- What MacroSense did to the slots, until the game shows it (it may show it late): the names it deleted (when)
-- and those it made (their layer, when). A deleted one is no deletion of yours (no trash, it stays in its
-- layer); a made one comes in with its layer, not as a new macro of the character's.
local expect = { gone = {}, made = {} }
local EXPECT_FOR = 20 -- seconds

-- What the sets did, for a bug report (/ms sets log): the last of it, kept with the character's sets (it outlasts
-- a reload).
local LOG_LINES = 300
local log = {}
local function Log(text, ...)
    local sets = ns.db and Sets.Mine and Sets.Mine()
    if sets then
        sets.log = sets.log or {}
        log = sets.log
    end
    -- The game's format errors on nil for %s (a macro made with no layer): each as text.
    local args, n = { ... }, select("#", ...)
    for i = 1, n do
        if type(args[i]) ~= "number" then args[i] = tostring(args[i]) end
    end
    local line = string.format(text, (unpack or table.unpack)(args, 1, n))
    log[#log + 1] = (date and date("%m-%d %H:%M:%S ") or "") .. line
    while #log > LOG_LINES do table.remove(log, 1) end
end
function Sets.Log()
    local sets = ns.db and Sets.Mine()
    return sets and sets.log or log
end

-- Whether MacroSense deleted macro `name` and the game hasn't shown it gone yet.
function Sets.Ours(name) return expect.gone[name] ~= nil end

-- This character's sets, made on first use.
-- Where the specializations are talent groups (ns.SpecsByGroup), what was kept under a specialization goes to the
-- talent group chosen now: WoW Forever kept it so before ("spec1485", its one specialization). Once the game
-- tells the group, after login. Into a group that has something already it doesn't go: it stays as it was, and
-- the list still shows its macros.
local function Regroup(c)
    local sets = c.sets
    if sets.grouped or not ns.SpecsByGroup() or not (IsLoggedIn and IsLoggedIn()) then return end
    sets.grouped = true
    local group = "group" .. ns.ActionBars.Group()
    for _, t in ipairs({ sets.specs, sets.bars, sets.spells or {}, c.bars or {} }) do
        local old = {}
        for key in pairs(t) do if key:find("^spec") then old[#old + 1] = key end end
        table.sort(old)
        for _, key in ipairs(old) do
            local here = t[group]
            if here == nil or (type(here) == "table" and next(here) == nil) then t[group], t[key] = t[key], nil end
        end
    end
    if sets.active and sets.active:find("^spec") then sets.active = group end
end

function Sets.Mine()
    local c = ns.Character()
    c.sets = c.sets or { enabled = false, character = {}, specs = {}, bars = {}, classParked = {} }
    Regroup(c)
    return c.sets
end

local function ClassList()
    local class = ns.Character().class or "?"
    ns.db.classMacros = ns.db.classMacros or {}
    ns.db.classMacros[class] = ns.db.classMacros[class] or {}
    return ns.db.classMacros[class]
end

local function SpecList(sets, key)
    sets.specs[key] = sets.specs[key] or {}
    return sets.specs[key]
end

-- Whether macro `name` is in a set of specialization `key` still: in the slots or behind the scenes.
local function Kept(sets, key, name)
    return (Find(ClassList(), name) or Find(sets.character, name) or Find(SpecList(sets, key), name)) ~= nil
end

-- The character macros in the slots: { name, icon, body }, in the game's order. The body as MacroSense shows it:
-- with @tank and @heal while the game's macro is as MacroSense wrote it (Roles.lua), so the sets keep the tags.
local function InSlots()
    local out = {}
    local _, count = GetNumMacros()
    for index = ns.MAX_GENERAL + 1, ns.MAX_GENERAL + count do
        local name, _, body = GetMacroInfo(index)
        body = body or ""
        if name and ns.Roles then body = ns.Roles.Text("character", name, body) end
        if name then out[#out + 1] = { name = name, icon = ns.MacroIcon(index), body = body } end
    end
    return out
end

local function ByName(list)
    local out = {}
    for _, m in ipairs(list) do out[m.name] = { body = m.body, icon = m.icon } end
    return out
end

local function Layers(sets)
    return Sets.LayerOf(InSlots(), sets.layer or {}, SpecList(sets, sets.active))
end

local function Index(name)
    local _, count = GetNumMacros()
    for index = ns.MAX_GENERAL + 1, ns.MAX_GENERAL + count do
        if GetMacroInfo(index) == name then return index end
    end
end

-- The game lets two macros have one name, the sets tell them apart by it: one of them would be taken for the other.
local function Count(name)
    local n = 0
    for _, m in ipairs(InSlots()) do
        if m.name == name then n = n + 1 end
    end
    return n
end
-- A name two macros in the slots have, one of them the class's or a specialization's; nil when there is none.
-- Then the sets wait: changing specialization, they would keep one text of the two, and delete both.
local function Twins(sets)
    local seen, layer = {}, sets.layer or {}
    for _, m in ipairs(InSlots()) do
        if seen[m.name] and (layer[m.name] == "spec" or layer[m.name] == "class") then return m.name end
        seen[m.name] = true
    end
end
local stalled, told -- the sets wait for twins renamed; the name told of

-- What is on action slot `slot`: nil, "character" and the macro's name, "gone" (a macro the game has no more:
-- Retail keeps one deleted on the bars of the other specializations) or "other".
local function At(slot)
    local kind = GetActionInfo(slot)
    if not kind then return nil end
    if kind ~= "macro" then return "other" end
    local index = ns.ActionBars.MacroAt(slot)
    if not index then return "gone" end
    if index and index > ns.MAX_GENERAL then return "character", (GetMacroInfo(index)) end
    return "other"
end

-- Where the character's macros are on the bars now: slot -> name.
local function BarsNow()
    local out = {}
    for slot = 1, MAX_SLOT do
        local kind, name = At(slot)
        if kind == "character" then out[slot] = name end
    end
    return out
end

local function Wrote(name, body) ns.History.Rewritten("character", name, body) end

-- The game's macro of `m`: the names of your group now for @tank and @heal, and kept up to date from then on
-- (Roles.lua). Too long with them, it has nobody's (@none), and still fits.
local function Written(m)
    if not ns.Roles then return m.body end
    local text = ns.Roles.Fill(m.body)
    if select(2, text:gsub("[^\128-\191]", "")) > (MAX_MACRO_CHARACTERS or 255) then
        text = ns.Conditions.Fill(m.body, {})
    end
    ns.Roles.Saved("character", nil, m.name, m.body, text)
    return text
end

-- A macro out of the slots, or into them with its layer: expected until the game shows it.
local function Remove(name)
    local index = Index(name)
    if not index then return end
    expect.gone[name] = GetTime()
    touched = true
    DeleteMacro(index)
    Log("deleted %s", name)
end
local function Make(m, layer)
    expect.made[m.name] = { layer = layer, at = GetTime() }
    touched = true
    CreateMacro(m.name, m.icon or 134400, Written(m), true)
    Log("made %s (%s)", m.name, layer)
end

-- The layers as the macros in the slots are now: done before anything is changed, so what you changed is kept.
local seen -- name -> { body, icon } as of the last look

-- What MacroSense did, as the game shows it now: a macro it deleted is gone, one it made is there, each as it
-- should be; what it hasn't shown yet is left out of both. Old expectations end.
local function Expected(before, now, layer)
    local t = GetTime()
    for name, at in pairs(expect.gone) do
        if not now[name] then
            Log("seen gone: %s", name)
            expect.gone[name] = nil
        elseif t - at > EXPECT_FOR then
            Log("still there: %s", name)
            expect.gone[name] = nil
        end
        before[name], now[name] = nil, nil
    end
    for name, made in pairs(expect.made) do
        if now[name] then
            Log("seen made: %s (%s)", name, made.layer)
            before[name], layer[name] = now[name], made.layer
            expect.made[name] = nil
        elseif t - made.at > EXPECT_FOR then
            Log("never made: %s", name)
            expect.made[name] = nil
        end
    end
end

-- Changes in the slots go into the layers (UPDATE_MACROS).
function Sets.Scan()
    local sets = Sets.Mine()
    if not sets.enabled or busy then return end
    local now = ByName(InSlots())
    if seen then
        sets.layer = sets.layer or Layers(sets)
        local before, after = {}, {}
        for name, m in pairs(seen) do before[name] = m end
        for name, m in pairs(now) do after[name] = m end
        Expected(before, after, sets.layer)
        local renamed = Sets.Follow(before, after, sets.layer, { class = ClassList(), character = sets.character,
            spec = SpecList(sets, sets.active) })
        -- Its buttons kept under the new name: for each specialization; a specialization's, for this one only.
        for old, new in pairs(renamed) do
            for key, record in pairs(sets.bars) do
                if sets.layer[new] ~= "spec" or key == sets.active then
                    for slot, name in pairs(record) do
                        if name == old then record[slot] = new end
                    end
                end
            end
        end
        -- One deleted, in no set any more: its buttons forgotten at once. Kept, a macro made later with its name
        -- would go onto them.
        for name in pairs(before) do
            if not after[name] and not renamed[name] then
                for key, record in pairs(sets.bars) do
                    if not Kept(sets, key, name) then
                        for slot, was in pairs(record) do
                            if was == name then
                                record[slot] = nil
                                Log("forgot button %d: %s, deleted", slot, name)
                            end
                        end
                    end
                end
            end
        end
    end
    seen = now
    -- One of the twins renamed: the sets go on.
    if stalled and not Twins(sets) then
        stalled = false
        C_Timer.After(0, Sets.Update)
    end
end

-- The macros in the slots changed by MacroSense itself: learned, not followed, and no versions or trash for them.
local function Settle()
    local sets = Sets.Mine()
    seen = ByName(InSlots())
    sets.layer = Layers(sets)
    ns.History.Settle()
end

-- The class macros brought up to date: made, changed, removed. Those that don't fit wait.
local function SyncClass(sets)
    sets.layer = Layers(sets)
    local plan = Sets.ClassPlan(InSlots(), sets.layer, ClassList(), sets.classParked, ns.MAX_CHARACTER)
    for _, name in ipairs(plan.remove) do Remove(name) end
    for _, m in ipairs(plan.change) do
        local index = Index(m.name)
        if index then
            local text = Written(m)
            Wrote(m.name, text)
            touched = true
            EditMacro(index, nil, m.icon, text)
        end
    end
    for _, m in ipairs(plan.make) do
        Make(m, "class")
        sets.layer[m.name] = "class"
    end
    for _, name in ipairs(plan.remove) do sets.layer[name] = nil end
    for _, name in ipairs(plan.adopt) do
        local _, i = Find(sets.character, name)
        if i then table.remove(sets.character, i) end
        sets.layer[name] = "class"
    end
    for _, m in ipairs(plan.wait) do sets.classParked[m.name] = true end
    for _, name in ipairs(plan.clash) do
        ns.Print("the class macro \"%s\" waits off the slots: a macro of yours has this name", name)
    end
    return #plan.wait - #plan.clash
end

-- The specialization now: the slots get its macros, those of the one before go back into its layer; the macro
-- buttons of the one coming in go back where they were. Not in combat: after it.
local function Change(sets, key)
    local before = sets.active
    sets.layer = Layers(sets)
    local known, class = (sets.spells or {})[key], sets.classSpells or {}
    local plan = Sets.Swap(InSlots(), sets.layer, SpecList(sets, key), ns.MAX_CHARACTER,
        known and function(m) return Sets.Works(m.body, known, class) end)
    local edit = {}
    for _, name in ipairs(plan.edit) do edit[name] = true end
    -- The one going keeps its set: each of its macros as it is in the slots now, those not there as they were
    -- (nothing of it is lost when the slots don't show one); one of its layer new in the slots joins it.
    local inSlots, kept = {}, {}
    for _, m in ipairs(plan.leaving) do inSlots[m.name] = m end
    for _, m in ipairs(SpecList(sets, before)) do
        local now = inSlots[m.name]
        if now then
            m.body, m.icon, m.parked = now.body, now.icon, nil
            inSlots[m.name] = nil
        elseif not m.parked then
            Log("kept, not in the slots: %s", m.name)
        end
        kept[#kept + 1] = m
    end
    for _, m in ipairs(plan.leaving) do
        if inSlots[m.name] then kept[#kept + 1] = m end
    end
    sets.specs[before] = kept
    Log("specialization %s -> %s: out %d, in %d", tostring(before), key, #plan.drop, #plan.add)
    for _, name in ipairs(plan.drop) do
        if not edit[name] then
            Remove(name)
            sets.layer[name] = nil
        end
    end
    -- One of the same name in both: changed in place, its buttons stay.
    fresh = { key = key, names = {} }
    for _, m in ipairs(plan.add) do
        m.parked = nil
        fresh.names[m.name] = true
        local index = edit[m.name] and Index(m.name)
        if index then
            local text = Written(m)
            Wrote(m.name, text)
            touched = true
            EditMacro(index, nil, m.icon, text)
            Log("changed in place: %s", m.name)
        else
            Make(m, "spec")
        end
        sets.layer[m.name] = "spec"
    end
    local newly = 0 -- off the slots now, not by your choice before
    for _, m in ipairs(plan.wait) do
        if not m.parked then newly = newly + 1 end
        m.parked = true
    end
    sets.active = key
    Settle()
    placing = math.max(placing, GetTime() + 5)
    Sets.PlaceBars(key)
    -- The game may show the macros made a little later: their buttons then.
    for _, delay in ipairs({ 0.5, 1.5, 4 }) do
        C_Timer.After(delay, function() Sets.PlaceBars(key, delay == 4) end)
    end
    return #plan.add, newly
end

-- The macro buttons of specialization `key` back where they were, for the macros in the slots now. Not when
-- another specialization came since, nor in combat. `last`: those not placed go into the log, with why.
function Sets.PlaceBars(key, last)
    local sets = Sets.Mine()
    if sets.active ~= key or InCombatLockdown() then return end
    local have = {}
    for _, m in ipairs(InSlots()) do have[m.name] = true end
    for _, b in ipairs(Sets.BarsBack(sets.bars[key] or {}, At, have)) do
        local index = Index(b.name)
        if index then
            ns.ActionBars.Place(index, { b.slot })
            Log("button %d: %s", b.slot, b.name)
        end
    end
    if not last then return end
    local record = sets.bars[key] or {}
    -- A button keeps a macro's place in the list, not its name: one of a macro deleted before shows the one made
    -- now in that place. A macro made now on a button you never gave it: taken off.
    if fresh.key == key then
        for slot = 1, MAX_SLOT do
            local kind, there = At(slot)
            if kind == "character" and fresh.names[there] and record[slot] ~= there then
                PickupAction(slot)
                ClearCursor()
                Log("took off button %d: %s was never put there", slot, there)
            end
        end
    end
    -- The buttons of macros there are no more (deleted): forgotten.
    for slot, name in pairs(record) do
        if not have[name] and not Kept(sets, key, name) then
            record[slot] = nil
            Log("forgot button %d: %s, deleted", slot, name)
        end
    end
    for slot, name in pairs(record) do
        local kind, there = At(slot)
        if not have[name] then
            Log("no button %d: %s is not in the slots", slot, name)
        elseif there ~= name then
            local a, id = GetActionInfo(slot)
            Log("no button %d: %s, the slot has %s (%s %s \"%s\")", slot, name, tostring(there or kind), tostring(a),
                tostring(id), tostring(ns.ActionBars.Text(slot)))
        end
    end
end

local rememberDue
-- As of the last look: the buttons whose macro was off the slots, and the macros in the slots.
local lastLook = { slots = {} }
-- The buttons of the specialization now, kept as you change them: the game swaps the bars with the
-- specialization, so once it changed they are those of the new one. Not while MacroSense puts them back; a
-- button whose macro is off the slots stays kept (deleting the macro took it off). A button keeps a macro's place
-- in the list, not its name: one whose macro was off the slots shows the next macro made in that place. Such a
-- macro, made since the last look, never put there: taken off (by any way it was made, MacroSense's or the game's).
function Sets.RememberBars()
    local sets = Sets.Mine()
    if not sets.enabled then return end
    if GetTime() < placing then -- a look once that is over
        if not rememberDue then
            rememberDue = true
            C_Timer.After(placing - GetTime() + 0.1, function()
                rememberDue = false
                Sets.RememberBars()
            end)
        end
        return
    end
    if busy or sets.active ~= ns.ActionBars.Spec() then return end
    local have = {}
    for _, m in ipairs(InSlots()) do have[m.name] = true end
    local record = sets.bars[sets.active] or {}
    local last = lastLook.key == sets.active and lastLook or nil
    local gone = {}
    for slot = 1, MAX_SLOT do
        local kind, name = At(slot)
        local was = record[slot]
        if kind == "character" and last and last.slots[slot] and not last.have[name] and name ~= was
            and not InCombatLockdown() then
            PickupAction(slot)
            ClearCursor()
            Log("took off button %d: %s was never put there", slot, name)
            kind = "gone"
        end
        if kind == "character" then
            record[slot] = name
        elseif kind == "gone" then -- its macro off the slots: kept
            gone[slot] = true
        elseif kind or (was and have[was]) then
            record[slot] = nil
        end
        if record[slot] ~= was then Log("%s button %d: %s", sets.active, slot, tostring(record[slot] or "-")) end
    end
    sets.bars[sets.active] = record
    lastLook = { key = sets.active, slots = gone, have = have }
end

-- Brings the slots in line with the specialization and the class: at login, after a change of specialization,
-- after combat.
function Sets.Update()
    local sets = Sets.Mine()
    if not sets.enabled then return end
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false
    ns.History.Scan()
    Sets.Scan()
    local twin = Twins(sets)
    if twin then
        stalled = true
        if told ~= twin then
            told = twin
            ns.Print("two macros in the game are named \"%s\": MacroSense tells macros apart by name, so it won't "
                .. "change the sets' macros until you rename one of them", twin)
        end
        return
    end
    stalled, told = false, nil
    local key = ns.ActionBars.Spec()
    local waiting = 0
    busy, touched = true, false
    local ok, err = pcall(function()
        if sets.active ~= key then
            local _, wait = Change(sets, key)
            waiting = waiting + wait
        end
        waiting = waiting + SyncClass(sets)
    end)
    busy = false
    Settle()
    -- What the game told of while busy was let go: the list and the rest now.
    if touched and ns.MacrosChanged then ns.MacrosChanged() end
    -- The editor's list shows the sets: one moved behind the scenes changes it too.
    if ns.Window and ns.Window.RefreshList then ns.Window.RefreshList() end
    if not ok then error(err, 0) end
    if waiting > 0 then
        ns.Print("%d macros wait behind the scenes: there is no free slot for them. Pick which to take in under "
            .. "\"Macro sets\"", waiting)
    end
end

function Sets.Pending() return pending end

-- The game tells of a new specialization in several events, some before it gives the new one: a look at once and
-- again a little later. A look when nothing changed changes nothing.
function Sets.Soon()
    placing = math.max(placing, GetTime() + 7) -- the bars may be the new one's before the game says it is
    for _, delay in ipairs({ 0.5, 2, 5 }) do C_Timer.After(delay, Sets.Update) end
end
if CreateFrame then -- the game (not the tests of the planning)
    local watch, events = CreateFrame("Frame"), {}
    for _, event in ipairs({ "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
        "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_ENTERING_WORLD" }) do
        events[event] = pcall(watch.RegisterEvent, watch, event)
    end
    watch:SetScript("OnEvent", function(_, event)
        if events[event] and ns.db and Sets.Mine().enabled then Sets.Soon() end
    end)
end

-- What the sets know, for a bug report: the specialization they are of and the one now, each layer.
function Sets.Debug()
    local sets = Sets.Mine()
    local out = { string.format("enabled %s, active %s, now %s", tostring(sets.enabled), tostring(sets.active),
        tostring(ns.ActionBars.Spec())) }
    local layers = {}
    for name, layer in pairs(sets.layer or {}) do layers[#layers + 1] = name .. "=" .. layer end
    table.sort(layers)
    out[#out + 1] = "slots: " .. table.concat(layers, ", ")
    local function names(list)
        local t = {}
        for _, m in ipairs(list) do t[#t + 1] = m.parked and ("(" .. m.name .. ")") or m.name end
        return table.concat(t, ", ")
    end
    out[#out + 1] = "class " .. tostring(ns.Character().class) .. ": " .. names(ClassList())
    local parked = {}
    for name in pairs(sets.classParked) do parked[#parked + 1] = name end
    out[#out + 1] = "class parked here: " .. table.concat(parked, ", ")
    out[#out + 1] = "character: " .. names(sets.character)
    for key, list in pairs(sets.specs) do
        local bars = 0
        for _ in pairs(sets.bars[key] or {}) do bars = bars + 1 end
        out[#out + 1] = string.format("%s: %s; buttons %d", key, names(list), bars)
    end
    return out
end

-- What turning the sets on again once took apart (the character's took in all the macros in the slots) put back:
-- one in the slots that the specialization's set has is that set's, the character's of its name behind the scenes;
-- one with the text of the class's is the class's.
local function Mend(sets)
    local class = ClassList()
    for _, m in ipairs(InSlots()) do
        if (sets.layer[m.name] or "character") == "character" then
            local _, i = Find(sets.character, m.name)
            local theirs = Find(class, m.name)
            if theirs and theirs.body == m.body and i then
                table.remove(sets.character, i)
                sets.layer[m.name] = "class"
                sets.classParked[m.name] = nil
            end
        end
    end
end

-- Sets on for this character. The first time: the macros in the slots become its own layer (a backup of them
-- first); the specialization now is the active one, with nothing of its own yet. Again: the sets as they were left,
-- the macros in the slots as they are now (changed, deleted, a new one the character's). Then the class macros come
-- in.
function Sets.Enable()
    local sets = Sets.Mine()
    if sets.enabled then return end
    if ns.Window.BackupNow then ns.Window.BackupNow() end
    sets.enabled = true
    if sets.active then
        sets.layer = sets.layer or {}
        -- Those that came into the game when the sets were turned off go back where they were, as you left them:
        -- changed, with the change; deleted, out of their set too.
        local back = {}
        local slots = ByName(InSlots())
        for _, o in ipairs(sets.out or {}) do
            local list = o.id == "class" and ClassList() or o.id == "character" and sets.character
                or SpecList(sets, o.id)
            local m, i = Find(list, o.name)
            local there = slots[o.name]
            if m and there then
                m.body, m.icon = there.body, there.icon
                Remove(o.name)
                back[o.name] = true
            elseif m and o.id ~= "class" then
                table.remove(list, i)
            end
        end
        if sets.out then Log("on again: %d back behind the scenes", #sets.out) end
        sets.out = nil
        local now = ByName(InSlots())
        for name in pairs(back) do now[name], sets.layer[name] = nil, nil end -- shown gone maybe a little later
        local function listOf(layer)
            return layer == "spec" and SpecList(sets, sets.active) or layer == "class" and ClassList() or sets.character
        end
        for name, layer in pairs(sets.layer) do
            if not now[name] then
                local _, i = Find(listOf(layer), name)
                if i and layer ~= "class" then table.remove(listOf(layer), i) end
                sets.layer[name] = nil
            end
        end
        for name, m in pairs(now) do
            local kept = sets.layer[name] and Find(listOf(sets.layer[name]), name)
            if kept then
                kept.body, kept.icon = m.body, m.icon
            elseif not sets.layer[name] then
                if not Find(sets.character, name) then
                    sets.character[#sets.character + 1] = { name = name, icon = m.icon, body = m.body }
                end
                sets.layer[name] = "character"
            end
        end
        Mend(sets)
    else
        sets.active = ns.ActionBars.Spec()
        sets.bars[sets.active] = BarsNow()
        sets.character, sets.layer = {}, {}
        for _, m in ipairs(InSlots()) do
            sets.character[#sets.character + 1] = m
            sets.layer[m.name] = "character"
        end
    end
    seen = nil
    Sets.Update()
    ns.Window.SetsChanged()
end


-- MacroSense changes the slots itself: what the game tells of meanwhile is not yours; then it is learned, and the
-- list and the rest are told.
local function Run(fn)
    busy, touched = true, false
    local ok, err = pcall(fn)
    busy = false
    Settle()
    if touched and ns.MacrosChanged then ns.MacrosChanged() end
    -- The editor's list shows the sets: one moved behind the scenes changes it too.
    if ns.Window and ns.Window.RefreshList then ns.Window.RefreshList() end
    if not ok then error(err, 0) end
end

-- A set: "class", "character" or a specialization's key. Its macros, whether it is in the game now, its layer.
local function ListOf(sets, id)
    if id == "class" then return ClassList() end
    if id == "character" then return sets.character end
    return SpecList(sets, id)
end
local function InGame(sets, id) return id == "class" or id == "character" or id == sets.active end
local function LayerOfSet(id) return (id == "class" or id == "character") and id or "spec" end
local function Parked(sets, id, m)
    if id == "class" then return sets.classParked[m.name] == true end
    return m.parked == true
end
local function SetParked(sets, id, m, on)
    if id == "class" then sets.classParked[m.name] = on or nil else m.parked = on or nil end
end
local function Room() return ns.MAX_CHARACTER - #InSlots() end

-- The macros behind the scenes that could come into the game when the sets are turned off, in this order: the
-- class's, this character's, the specialization now's, the others'. Each { m, id, taken = its name is in the game
-- already }; and the free slots.
function Sets.OffChoice()
    local sets = Sets.Mine()
    local inGame = {}
    for _, m in ipairs(InSlots()) do inGame[m.name] = true end
    local ids = { "class", "character" }
    if sets.active then ids[#ids + 1] = sets.active end
    local others = {}
    for key in pairs(sets.specs) do
        if key ~= sets.active then others[#others + 1] = key end
    end
    table.sort(others)
    for _, key in ipairs(others) do ids[#ids + 1] = key end
    local out = {}
    for _, id in ipairs(ids) do
        for _, m in ipairs(ListOf(sets, id)) do
            if Sets.Behind(id, m) then out[#out + 1] = { m = m, id = id, taken = inGame[m.name] or nil } end
        end
    end
    return out, Room()
end

-- What comes into the game when the sets are turned off, unless you choose: every macro behind the scenes, as many
-- as there are free slots, one of a name (the first, in the order of Sets.OffChoice). Returns those that come in
-- ({ m, id }) and those that don't ({ name, why = "room" or "name" }).
function Sets.OffPlan()
    local all, room = Sets.OffChoice()
    local taken, bring, left = {}, {}, {}
    for _, c in ipairs(all) do
        if c.taken or taken[c.m.name] then
            left[#left + 1] = { name = c.m.name, why = "name" }
        elseif room <= 0 then
            left[#left + 1] = { name = c.m.name, why = "room" }
        else
            bring[#bring + 1] = { m = c.m, id = c.id }
            taken[c.m.name], room = true, room - 1
        end
    end
    return bring, left
end

-- Sets off: the macros behind the scenes come into the game, `bring` ({ m, id }, as you chose) or as many as fit
-- (Sets.OffPlan), so you have them; the sets are kept as they were, and those come back to them when the sets are
-- on again. False and "combat" in combat.
function Sets.Disable(bring)
    local sets = Sets.Mine()
    if not sets.enabled then return true end
    if InCombatLockdown() then return false, "combat" end
    Sets.Scan()
    bring = bring or Sets.OffPlan()
    sets.out = {}
    Run(function()
        for _, b in ipairs(bring) do
            Make(b.m)
            sets.out[#sets.out + 1] = { name = b.m.name, id = b.id }
        end
    end)
    -- Out of the layers: they are their sets', behind the scenes, to go back there.
    for _, o in ipairs(sets.out) do sets.layer[o.name] = nil end
    sets.enabled = false
    seen = nil
    Log("off: %d into the game", #bring)
    ns.Window.SetsChanged()
    return true
end

-- Macro `name` of set `from` into set `to`, or a copy of it (`copy`): a macro of its own there, and the one in
-- `from` stays as it is. It stays in the slots, leaves them or comes in, as its new set is; with no free slot, or
-- with its name in the game already (a copy), it waits behind the scenes. Moved onto the very same macro there (the
-- same text), the two are one. Returns true (and "waits", "twin" or "merged" then), or false and why: "name" (the
-- set has another macro of that name), "combat". Moved into the character's, it is Sets.Release.
function Sets.MoveTo(from, name, to, copy)
    local sets = Sets.Mine()
    if not sets.enabled or from == to then return false end
    if InCombatLockdown() then return false, "combat" end
    if to == "character" and not copy then return Sets.Release(from, name) end
    Sets.Scan()
    if Count(name) > 1 then return false, "twins" end
    local source, target = ListOf(sets, from), ListOf(sets, to)
    local m, i = Find(source, name)
    if not m then return false end
    local there = Find(target, name)
    if there and (copy or there.body ~= m.body) then return false, "name" end
    local parked = Parked(sets, from, m)
    local wasIn = InGame(sets, from) and not parked and Index(name) ~= nil
    local waits = there and "merged" or nil
    Run(function()
        if not copy then
            table.remove(source, i)
            if from == "class" then sets.classParked[name] = nil end
        end
        local entry = there or { name = m.name, body = m.body }
        entry.icon = m.icon
        if not there then target[#target + 1] = entry end
        SetParked(sets, to, entry, parked)
        local willBe = InGame(sets, to) and not parked
        sets.layer = sets.layer or {}
        if wasIn and not copy then
            if willBe then
                sets.layer[name] = LayerOfSet(to)
            else
                Remove(name)
                sets.layer[name] = nil
            end
        elseif willBe then
            if Index(name) then
                SetParked(sets, to, entry, true)
                waits = "twin"
            elseif Room() > 0 then
                Make(entry, LayerOfSet(to))
                sets.layer[name] = LayerOfSet(to)
            else
                SetParked(sets, to, entry, true)
                waits = "waits"
            end
        end
    end)
    Log("%s %s: %s -> %s%s", copy and "copied" or "moved", name, from, to, there and ", merged" or "")
    return true, waits
end

-- A macro in the slots into another layer (`to`: "class", "character", "spec"). Its place in the slots stays.
function Sets.Move(name, to)
    local sets = Sets.Mine()
    if not sets.enabled then return false end
    Sets.Scan()
    sets.layer = Layers(sets)
    local from = sets.layer[name]
    if not from then return false end
    if from == to then return true end
    local function id(layer) return layer == "spec" and sets.active or layer end
    return (Sets.MoveTo(id(from), name, id(to)))
end

-- Macro `name` of set `id` back into this character's ("Remove"): it leaves the set, and is the character's, in the
-- game if it was there (or comes in, with a free slot and its name free there). The character's has one of that name
-- already: the same text, and the two are one; another, false and "differs". False and "combat" in combat.
function Sets.Release(id, name)
    local sets = Sets.Mine()
    if not sets.enabled or id == "character" then return false end
    if InCombatLockdown() then return false, "combat" end
    Sets.Scan()
    if Count(name) > 1 then return false, "twins" end
    local source = ListOf(sets, id)
    local m, i = Find(source, name)
    if not m then return false end
    local same = Find(sets.character, name)
    if same and same.body ~= m.body then return false, "differs" end
    local wasIn = InGame(sets, id) and not Parked(sets, id, m) and Index(name) ~= nil
    local waits
    Run(function()
        table.remove(source, i)
        if id == "class" then sets.classParked[name] = nil end
        local entry = same
        if not entry then
            entry = { name = m.name, body = m.body }
            sets.character[#sets.character + 1] = entry
        end
        entry.icon = m.icon
        sets.layer = sets.layer or {}
        if wasIn then
            entry.parked = nil
            sets.layer[name] = "character"
        elseif same and not same.parked then
            return -- in the game already
        elseif Index(name) then
            entry.parked, waits = true, "twin"
        elseif Room() > 0 then
            entry.parked = nil
            Make(entry, "character")
            sets.layer[name] = "character"
        else
            entry.parked, waits = true, "waits"
        end
    end)
    Log("released %s from %s", name, id)
    return true, waits
end

-- Macro `name` of set `id` behind the scenes (`on`), or back. Back into the game it needs a free slot and its name
-- free there, else false and why: "room", "ingame" ("combat" in combat). A specialization not chosen now only
-- remembers it: its macro comes in with it, or doesn't.
function Sets.Park(id, name, on)
    local sets = Sets.Mine()
    if not sets.enabled then return false end
    if InCombatLockdown() then return false, "combat" end
    Sets.Scan()
    local m = Find(ListOf(sets, id), name)
    if not m then return false end
    if Count(name) > 1 then return false, "twins" end
    on = on and true or false
    -- Not put away, yet not in the slots as this set's: taken in, it comes in.
    if on == Parked(sets, id, m) and (on or not Sets.Behind(id, m)) then return true end
    if not on and InGame(sets, id) then
        if Index(name) then return false, "ingame" end
        if Room() <= 0 then return false, "room" end
    end
    Run(function()
        SetParked(sets, id, m, on)
        if not InGame(sets, id) then return end
        sets.layer = sets.layer or {}
        if on then
            if Index(name) and sets.layer[name] == LayerOfSet(id) then
                Remove(name)
                sets.layer[name] = nil
            end
        else
            Make(m, LayerOfSet(id))
            sets.layer[name] = LayerOfSet(id)
        end
    end)
    Log("%s %s (%s)", on and "parked" or "taken in", name, id)
    return true
end

-- For the window: the macros of set `id` (the list itself), whether one is behind the scenes, whether the set is in
-- the game now, and the free slots.
function Sets.List(id) return ListOf(Sets.Mine(), id) end
function Sets.IsParked(id, m) return Parked(Sets.Mine(), id, m) end
function Sets.InGame(id) return InGame(Sets.Mine(), id) end
function Sets.Room() return Room() end

------------------------------------------------------------------------
-- The editor: it shows every macro of the sets, and changes, makes and deletes those behind the scenes where
-- they are kept
------------------------------------------------------------------------
-- The set of macro `name` in the slots: "class", "character" or "spec".
function Sets.LayerIn(name)
    local sets = Sets.Mine()
    sets.layer = sets.layer or Layers(sets)
    return sets.layer[name]
end

-- Whether macro `m` of set `id` is behind the scenes: put away, of a specialization not chosen, or not in the
-- slots as this set's (none of its name there, or one of another set): shown there, never nowhere.
function Sets.Behind(id, m)
    local sets = Sets.Mine()
    if not InGame(sets, id) or Parked(sets, id, m) then return true end
    sets.layer = sets.layer or Layers(sets)
    return sets.layer[m.name] ~= LayerOfSet(id) or Index(m.name) == nil
end

-- Macro `old` of set `id`, behind the scenes, written as `name`, `icon`, `body`; `old` nil: a new one there,
-- behind the scenes. Its buttons kept follow a new name. False and "name" when the set has another of that name.
function Sets.Write(id, old, name, icon, body)
    local sets = Sets.Mine()
    if not sets.enabled then return false end
    local list = ListOf(sets, id)
    local m = old and Find(list, old)
    if old and not m then return false end
    local other = Find(list, name)
    if other and other ~= m then return false, "name" end
    if not m then
        m = { name = name }
        list[#list + 1] = m
        SetParked(sets, id, m, true)
    elseif old ~= name then
        if id == "class" then sets.classParked[old], sets.classParked[name] = nil, sets.classParked[old] end
        for key, record in pairs(sets.bars) do
            if LayerOfSet(id) ~= "spec" or key == id then
                for slot, at in pairs(record) do
                    if at == old then record[slot] = name end
                end
            end
        end
    end
    m.name, m.icon, m.body = name, icon, body
    Log("wrote %s behind the scenes: %s", name, id)
    return true
end

-- Macro `name` of set `from` dropped on set `to`, in the game (`inGame`) or behind the scenes: moved there if that is
-- another set, then in the game or not, as dropped. Into a specialization not chosen now: in its set, to come in
-- with it. `copy`: a copy of it there, as Sets.MoveTo makes (false and "same" into its own set). Returns as
-- Sets.MoveTo and Sets.Park do.
function Sets.Place(from, name, to, inGame, copy)
    local sets = Sets.Mine()
    if not sets.enabled then return false end
    if copy and from == to then return false, "same" end
    local ok, why = true, nil
    if from ~= to then
        ok, why = Sets.MoveTo(from, name, to, copy)
        if not ok or why then return ok, why end
    end
    if not InGame(sets, to) then inGame = true end
    return Sets.Park(to, name, not inGame)
end

-- Whether Sets.Place would do it, as it says why not; nothing changes. For the drag: what is under the mouse.
function Sets.CanPlace(from, name, to, inGame, copy)
    local sets = Sets.Mine()
    if not sets.enabled then return false end
    if InCombatLockdown() then return false, "combat" end
    if copy and from == to then return false, "same" end
    local m = Find(ListOf(sets, from), name)
    if not m then return false end
    if Count(name) > 1 then return false, "twins" end
    if from ~= to then
        if to == "character" and not copy then
            local same = Find(sets.character, name)
            if same and same.body ~= m.body then return false, "differs" end
            return true
        end
        local there = Find(ListOf(sets, to), name)
        if there and (copy or there.body ~= m.body) then return false, "name" end
        return true
    end
    if InGame(sets, to) and inGame and Parked(sets, to, m) then
        if Index(name) then return false, "ingame" end
        if Room() <= 0 then return false, "room" end
    end
    return true
end

-- Macro `name` of set `id` deleted, behind the scenes: into the trash, as one deleted in the game.
function Sets.Forget(id, name, moved)
    local sets = Sets.Mine()
    local list = ListOf(sets, id)
    local m, i = Find(list, name)
    if not m then return false end
    table.remove(list, i)
    if id == "class" then sets.classParked[name] = nil end
    if moved then -- into the General tab: not deleted
        Log("moved %s from behind the scenes into General: %s", name, id)
        return true
    end
    ns.History.Discard(ns.History.Trash("character"), name, m, time())
    Log("deleted %s behind the scenes: %s", name, id)
    return true
end

-- The specializations: { key, label, now } in the game's order (Classic: its talent groups), then any other one
-- with macros kept: the one before level 10, with no name, too.
function Sets.Specs()
    local sets, out, seen = Sets.Mine(), {}, {}
    local now, nowLabel = ns.ActionBars.Spec()
    local function add(key, label)
        if seen[key] then return end
        seen[key] = true
        out[#out + 1] = { key = key, label = label, now = key == now }
    end
    local S = C_SpecializationInfo or {}
    if not ns.SpecsByGroup() and S.GetSpecializationInfo and GetNumSpecializations then
        for i = 1, GetNumSpecializations() do
            local id, name = S.GetSpecializationInfo(i)
            if id and id ~= 0 then add("spec" .. id, name) end
        end
    else
        local groups = S.GetNumSpecGroups and S.GetNumSpecGroups() or GetNumTalentGroups and GetNumTalentGroups() or 1
        for group = 1, math.max(groups or 1, 1) do
            add("group" .. group, ns.ActionBars.GroupLabel(group))
        end
    end
    add(now, nowLabel)
    local bars = ns.Character().bars or {}
    local keys = {}
    for key, list in pairs(sets.specs) do
        if #list > 0 then keys[#keys + 1] = key end
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local label, group = bars[key] and bars[key].label, key:match("^group(%d+)$")
        if group then label = ns.ActionBars.GroupLabel(tonumber(group)) end
        add(key, label and label ~= "" and label or key:find("^spec") and ns.L["No specialization yet"] or key)
    end
    return out
end

-- The spells of the specialization now, as the spellbook has them once it changed (SPELLS_CHANGED), kept for each
-- specialization; and every spell of the class seen, in any of them: to tell which macros work where.
function Sets.LearnSpells()
    local ok, spells = pcall(ns.sources.spells)
    if not ok or #spells == 0 then return end
    local sets = Sets.Mine()
    sets.classSpells = sets.classSpells or {}
    local class, known = sets.classSpells, {}
    local function seen(name) if name and name ~= "" then class[name:lower()] = name end end
    for _, spell in ipairs(spells) do
        seen(spell.name)
        seen(spell.base)
        if not spell.offSpec then
            known[spell.name:lower()] = true
            if spell.base then known[spell.base:lower()] = true end
        end
    end
    local okLater, later = pcall(ns.sources.laterSpells)
    for _, spell in ipairs(okLater and later or {}) do seen(spell.name) end
    local okTalents, talents = pcall(ns.sources.talents)
    for _, name in ipairs(okTalents and talents or {}) do seen(name) end
    sets.spells = sets.spells or {}
    sets.spells[ns.ActionBars.Spec()] = known
end

-- The specializations whose spells are known (in order), and those not yet: visited once, they are.
local function Visited(sets)
    local keys, missing = {}, {}
    for _, spec in ipairs(Sets.Specs()) do
        if (sets.spells or {})[spec.key] then keys[#keys + 1] = spec.key else missing[#missing + 1] = spec.label end
    end
    return keys, missing
end
function Sets.Unvisited() return select(2, Visited(Sets.Mine())) end

-- What a macro of set `id` is told with in the window: a specialization's that it can't cast there, what it
-- lacks ("warn"); the character's that works in one specialization only, that one; the character's that works in
-- all of them (all known), that it could be the class's ("hint").
function Sets.Note(id, m)
    local sets = Sets.Mine()
    local spells, class = sets.spells or {}, sets.classSpells or {}
    if LayerOfSet(id) == "spec" and spells[id] then
        local works, missing = Sets.Works(m.body, spells[id], class)
        if works == false then
            return string.format(ns.L["Not in this specialization: %s"], table.concat(missing, ", ")), "warn"
        end
    elseif id == "character" then
        local keys = Visited(sets)
        local works = #keys >= 2 and Sets.WorksIn(m.body, spells, class, keys)
        local all = works and #works == #keys and #select(2, Visited(sets)) == 0
        if all then
            return ns.L["Works in every specialization: it could go to \"Class macros\""], "hint"
        end
        if works and #works == 1 then
            for _, spec in ipairs(Sets.Specs()) do
                if spec.key == works[1] then return string.format(ns.L["Works only in %s"], spec.label), "hint" end
            end
        end
    end
end

-- The moves "Sort by spells" offers, and doing them. None till the spells of every specialization are known: one
-- that works where they are known may work in another too.
function Sets.SortPlan()
    local sets = Sets.Mine()
    if #Sets.Unvisited() > 0 then return {} end
    return Sets.Sort(sets.character, sets.specs, sets.spells or {}, sets.classSpells or {}, (Visited(sets)))
end
function Sets.ApplySort(moves)
    local done = 0
    for _, move in ipairs(moves) do
        if Sets.MoveTo(move.from, move.name, move.to) then done = done + 1 end
    end
    return done
end

-- The layers for the chat: each with its macros, those off the slots marked.
function Sets.Describe()
    local sets = Sets.Mine()
    local lists = { class = ClassList(), character = sets.character, spec = SpecList(sets, sets.active or "") }
    local out = {}
    for _, layer in ipairs(Sets.LAYERS) do
        local names = {}
        for _, m in ipairs(lists[layer]) do
            local off = (layer == "class" and sets.classParked[m.name]) or (layer ~= "class" and m.parked)
            names[#names + 1] = off and ("(" .. m.name .. ")") or m.name
        end
        out[#out + 1] = { layer = layer, names = names }
    end
    return out
end

------------------------------------------------------------------------
-- All or nothing: a change that breaks halfway (an error) is undone. The sets, the class macros, the macros in
-- both tabs and their buttons go back as they were before it; the error is raised then, to be reported.
------------------------------------------------------------------------
local function Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Copy(v) end
    return out
end

-- Every macro of the game, in its tab: { general = { { name, icon, body } }, character = { ... } }.
local function AllMacros()
    local general, character = GetNumMacros()
    local out = { general = {}, character = {} }
    for index = 1, general do
        local name, _, body = GetMacroInfo(index)
        if name then out.general[#out.general + 1] = { name = name, icon = ns.MacroIcon(index), body = body or "" } end
    end
    for index = ns.MAX_GENERAL + 1, ns.MAX_GENERAL + character do
        local name, _, body = GetMacroInfo(index)
        if name then
            out.character[#out.character + 1] = { name = name, icon = ns.MacroIcon(index), body = body or "" }
        end
    end
    return out
end

-- The macro buttons: slot -> { name, general }; a slot with no action: false.
local function Buttons()
    local out = {}
    for slot = 1, MAX_SLOT do
        local kind = GetActionInfo(slot)
        local index = kind == "macro" and ns.ActionBars.MacroAt(slot)
        if index then
            out[slot] = { name = (GetMacroInfo(index)), general = index <= ns.MAX_GENERAL }
        elseif not kind then
            out[slot] = false
        end
    end
    return out
end

local function IndexIn(general, name)
    local first, last
    if general then
        first, last = 1, (GetNumMacros())
    else
        first, last = ns.MAX_GENERAL + 1, ns.MAX_GENERAL + select(2, GetNumMacros())
    end
    for index = first, last do
        if GetMacroInfo(index) == name then return index end
    end
end

-- The macros of a tab as `was`: those made since deleted, those deleted made again, those changed written back.
-- Matched by name, in order (two of one name are two).
local function TabBack(was, general)
    local function pair()
        local now, wanted, extra = general and AllMacros().general or AllMacros().character, {}, {}
        for _, m in ipairs(was) do
            wanted[m.name] = wanted[m.name] or {}
            table.insert(wanted[m.name], m)
        end
        local changed = {}
        for i, m in ipairs(now) do
            local w = wanted[m.name] and table.remove(wanted[m.name], 1)
            if not w then
                extra[#extra + 1] = i
            elseif w.body ~= m.body or w.icon ~= m.icon then
                changed[#changed + 1] = w
            end
        end
        return extra, changed, wanted
    end
    local extra = pair()
    local base = general and 0 or ns.MAX_GENERAL
    for k = #extra, 1, -1 do DeleteMacro(base + extra[k]) end
    local _, changed, missing = pair()
    for _, w in ipairs(changed) do
        local index = IndexIn(general, w.name)
        if index then EditMacro(index, nil, w.icon, w.body) end
    end
    for _, list in pairs(missing) do
        for _, w in ipairs(list) do CreateMacro(w.name, w.icon or 134400, w.body, not general) end
    end
end

local function ButtonsBack(was)
    local now = Buttons()
    for slot = 1, MAX_SLOT do
        local before, after = was[slot], now[slot]
        if before and not (after and after.name == before.name and after.general == before.general) then
            local index = IndexIn(before.general, before.name)
            if index then ns.ActionBars.Place(index, { slot }) end
        elseif before == false and after then
            PickupAction(slot)
            ClearCursor()
        end
    end
end

local depth = 0
local function Snapshot()
    local c = ns.Character()
    return { sets = Copy(c.sets), class = Copy(ClassList()), macros = AllMacros(), buttons = Buttons(),
        seen = Copy(seen), expect = Copy(expect), fresh = Copy(fresh) }
end

local function Restore(snap)
    local c = ns.Character()
    local lines = c.sets and c.sets.log -- what happened stays, for a report
    c.sets = snap.sets
    if c.sets and lines then c.sets.log = lines end
    ns.db.classMacros[ns.Character().class or "?"] = snap.class
    seen, expect, fresh = snap.seen, snap.expect, snap.fresh
    if InCombatLockdown() then return Log("undone in the sets only: in combat, the macros can't be changed") end
    busy = true
    local ok, err = pcall(function()
        TabBack(snap.macros.general, true)
        TabBack(snap.macros.character, false)
        ButtonsBack(snap.buttons)
    end)
    busy = false
    if not ok then Log("undoing: %s", err) end
    pcall(Settle)
end

-- `fn` all or nothing; one inside another is a part of it.
function Sets.Atomic(fn, ...)
    if depth > 0 or not ns.db then return fn(...) end
    local snap = Snapshot()
    depth = depth + 1
    local result = { n = 0 }
    local function keep(ok, ...) result = { n = select("#", ...), ok = ok, ... } end
    keep(pcall(fn, ...))
    depth = depth - 1
    if result.ok then return (unpack or table.unpack)(result, 1, result.n) end
    Log("broke: %s", result[1])
    Restore(snap)
    pcall(function()
        if ns.MacrosChanged then ns.MacrosChanged() end
        if ns.Window and ns.Window.SetsChanged then ns.Window.SetsChanged() end
    end)
    ns.Print("something went wrong, so MacroSense undid this change: your macros and sets are as they were. "
        .. "Please report the error")
    error(result[1], 0)
end

for _, name in ipairs({ "Enable", "Disable", "Update", "MoveTo", "Move", "Release", "Park", "Write", "Place",
    "Forget", "ApplySort" }) do
    local fn = Sets[name]
    Sets[name] = function(...) return Sets.Atomic(fn, ...) end
end

return Sets
