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
-- the new name, and is renamed in the other sets of `lists.linked` too (one macro, wherever it is: the character's
-- and each specialization's), not the class's; a deleted one leaves its layer; a new one joins the character's.
-- `before` and `after`: name -> { body, icon }; `layer` as of before. Returns the renamed: old -> new.
function Sets.Follow(before, after, layer, lists)
    local renamed, deleted = ns.History.Gone(before, after)
    local function listOf(name) return lists[layer[name] or "character"] end
    for old, new in pairs(renamed) do
        local those = { listOf(old) }
        if layer[old] ~= "class" then
            for _, list in ipairs(lists.linked or {}) do those[#those + 1] = list end
        end
        for _, list in ipairs(those) do
            local m = Find(list, old)
            if m and not Find(list, new) then m.name = new end
        end
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
    local function add(name, from, to)
        if to == "character" or not Find(specs[to] or {}, name) then
            out[#out + 1] = { name = name, from = from, to = to }
        end
    end
    local held = {}
    for _, list in pairs(specs) do
        for _, m in ipairs(list) do held[m.name] = true end
    end
    for _, m in ipairs(character) do
        local works = not held[m.name] and Sets.WorksIn(m.body, spells, class, keys)
        if works and #works == 1 then add(m.name, "character", works[1]) end
    end
    for _, key in ipairs(keys) do
        for _, m in ipairs(specs[key] or {}) do
            local works = Sets.WorksIn(m.body, spells, class, keys)
            if works and #works == #keys then
                local twin = false
                for _, other in ipairs(keys) do
                    if other ~= key and Find(specs[other] or {}, m.name) then twin = true end
                end
                if not twin then add(m.name, key, "character") end
            elseif works and #works == 1 and works[1] ~= key then
                add(m.name, key, works[1])
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

function Sets.Busy() return busy end

-- What MacroSense did to the slots, until the game shows it (it may show it late): the names it deleted (when)
-- and those it made (their layer, when). A deleted one is no deletion of yours (no trash, it stays in its
-- layer); a made one comes in with its layer, not as a new macro of the character's.
local expect = { gone = {}, made = {} }
local EXPECT_FOR = 20 -- seconds

-- What the sets did, for a bug report (/ms sets log): the last of it.
local log = {}
local function Log(text, ...)
    log[#log + 1] = (date and date("%H:%M:%S ") or "") .. string.format(text, ...)
    while #log > 80 do table.remove(log, 1) end
end
function Sets.Log() return log end

-- Whether MacroSense deleted macro `name` and the game hasn't shown it gone yet.
function Sets.Ours(name) return expect.gone[name] ~= nil end

-- This character's sets, made on first use.
function Sets.Mine()
    local c = ns.Character()
    c.sets = c.sets or { enabled = false, character = {}, specs = {}, bars = {}, classParked = {} }
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

-- The character macros in the slots: { name, icon, body }, in the game's order.
local function InSlots()
    local out = {}
    local _, count = GetNumMacros()
    for index = ns.MAX_GENERAL + 1, ns.MAX_GENERAL + count do
        local name, _, body = GetMacroInfo(index)
        if name then out[#out + 1] = { name = name, icon = ns.MacroIcon(index), body = body or "" } end
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
    CreateMacro(m.name, m.icon or 134400, m.body, true)
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
        local linked = { sets.character }
        for _, list in pairs(sets.specs) do linked[#linked + 1] = list end
        local renamed = Sets.Follow(before, after, sets.layer, { class = ClassList(), character = sets.character,
            spec = SpecList(sets, sets.active), linked = linked })
        -- Its buttons kept for each specialization, under the new name.
        for old, new in pairs(renamed) do
            for _, record in pairs(sets.bars) do
                for slot, name in pairs(record) do
                    if name == old then record[slot] = new end
                end
            end
        end
    end
    seen = now
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
            Wrote(m.name, m.body)
            touched = true
            EditMacro(index, nil, m.icon, m.body)
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
    -- The one going keeps its macros as they are, and those it had parked.
    local kept = {}
    for _, m in ipairs(SpecList(sets, before)) do
        if m.parked then kept[#kept + 1] = m end
    end
    for _, m in ipairs(plan.leaving) do kept[#kept + 1] = m end
    sets.specs[before] = kept
    Log("specialization %s -> %s: out %d, in %d", tostring(before), key, #plan.drop, #plan.add)
    for _, name in ipairs(plan.drop) do
        if not edit[name] then
            Remove(name)
            sets.layer[name] = nil
        end
    end
    -- One of the same name in both: changed in place, its buttons stay.
    for _, m in ipairs(plan.add) do
        m.parked = nil
        local index = edit[m.name] and Index(m.name)
        if index then
            Wrote(m.name, m.body)
            touched = true
            EditMacro(index, nil, m.icon, m.body)
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
    for slot, name in pairs(sets.bars[key] or {}) do
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
-- The buttons of the specialization now, kept as you change them: the game swaps the bars with the
-- specialization, so once it changed they are those of the new one. Not while MacroSense puts them back; a
-- button whose macro is off the slots stays kept (deleting the macro took it off).
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
    for slot = 1, MAX_SLOT do
        local kind, name = At(slot)
        local was = record[slot]
        if kind == "character" then
            record[slot] = name
        elseif kind == "gone" then -- its macro off the slots: kept
        elseif kind or (was and have[was]) then
            record[slot] = nil
        end
        if record[slot] ~= was then Log("%s button %d: %s", sets.active, slot, tostring(record[slot] or "-")) end
    end
    sets.bars[sets.active] = record
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

-- Sets on for this character: the macros in the slots become its own layer (a backup of them first); the
-- specialization now is the active one, with nothing of its own yet. Then the class macros come in.
function Sets.Enable()
    local sets = Sets.Mine()
    if sets.enabled then return end
    if ns.Window.BackupNow then ns.Window.BackupNow() end
    sets.enabled = true
    sets.active = ns.ActionBars.Spec()
    sets.bars[sets.active] = BarsNow()
    sets.character, sets.layer = {}, {}
    for _, m in ipairs(InSlots()) do
        sets.character[#sets.character + 1] = m
        sets.layer[m.name] = "character"
    end
    seen = nil
    Sets.Update()
end

-- Sets off: the slots stay as they are; the specializations' macros not in them stay kept for later.
function Sets.Disable()
    Sets.Mine().enabled = false
    seen = nil
end

-- MacroSense changes the slots itself: what the game tells of meanwhile is not yours; then it is learned, and the
-- list and the rest are told.
local function Run(fn)
    busy, touched = true, false
    local ok, err = pcall(fn)
    busy = false
    Settle()
    if touched and ns.MacrosChanged then ns.MacrosChanged() end
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

-- Macro `name` of set `from` into set `to`, or a copy of it (`copy`: between specializations only, which are never
-- in the slots together). It stays in the slots, leaves them or comes in, as its new set is; with no free slot it
-- waits behind the scenes. Returns true (and "waits" then), or false and why: "name" (the set has a macro of that
-- name), "together", "combat". Out of a specialization into the character's is Sets.Release; out of the
-- character's into a specialization, the character's keeps it behind the scenes.
function Sets.MoveTo(from, name, to, copy)
    local sets = Sets.Mine()
    if not sets.enabled or from == to then return false end
    if InCombatLockdown() then return false, "combat" end
    if copy and (LayerOfSet(from) ~= "spec" or LayerOfSet(to) ~= "spec") then return false, "together" end
    if to == "character" and LayerOfSet(from) == "spec" then return Sets.Release(from, name) end
    -- Into a specialization from the character's: the character's keeps it, behind the scenes.
    local home = from == "character" and LayerOfSet(to) == "spec"
    Sets.Scan()
    local source, target = ListOf(sets, from), ListOf(sets, to)
    local m, i = Find(source, name)
    if not m then return false end
    if Find(target, name) then return false, "name" end
    local parked = Parked(sets, from, m)
    local wasIn = InGame(sets, from) and not parked and Index(name) ~= nil
    local waits
    Run(function()
        if home then
            m.parked = true
        elseif not copy then
            table.remove(source, i)
            if from == "class" then sets.classParked[name] = nil end
        end
        local entry = { name = m.name, icon = m.icon, body = m.body }
        target[#target + 1] = entry
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
            if Room() > 0 and not Index(name) then
                Make(entry, LayerOfSet(to))
                sets.layer[name] = LayerOfSet(to)
            else
                SetParked(sets, to, entry, true)
                waits = true
            end
        end
    end)
    Log("%s %s: %s -> %s", copy and "copied" or "moved", name, from, to)
    return true, waits and "waits" or nil
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

-- Whether a specialization's set has a macro of this name.
local function Held(sets, name)
    for _, list in pairs(sets.specs) do
        if Find(list, name) then return true end
    end
    return false
end
-- The specializations whose sets have a macro of this name: their keys, the one now last.
function Sets.HeldIn(name)
    local sets = Sets.Mine()
    local keys, now = {}, false
    for key, list in pairs(sets.specs) do
        if Find(list, name) then
            if key == sets.active then now = true else keys[#keys + 1] = key end
        end
    end
    table.sort(keys)
    if now then keys[#keys + 1] = sets.active end
    return keys
end

-- The character's macro `name` into the game, taken out of every specialization that has it ("Remove" from each,
-- the one now last: its macro in the game stays there, on its buttons). Returns as Sets.Release does.
function Sets.TakeHome(name)
    local sets = Sets.Mine()
    if not sets.enabled then return false end
    if InCombatLockdown() then return false, "combat" end
    local ok, why = true, nil
    for _, key in ipairs(Sets.HeldIn(name)) do ok, why = Sets.Release(key, name) end
    return ok, why
end

-- Macro `name` of set `id` back into this character's, the home of every macro: it leaves the set, and is kept
-- there (its own copy there stays as it is). While a specialization still has it, it stays behind the scenes
-- there; out of the last, it comes into the game, with the text it had in the game if it was. False and "combat"
-- in combat.
function Sets.Release(id, name)
    local sets = Sets.Mine()
    if not sets.enabled or id == "character" then return false end
    if InCombatLockdown() then return false, "combat" end
    Sets.Scan()
    local source = ListOf(sets, id)
    local m, i = Find(source, name)
    if not m then return false end
    local wasIn = InGame(sets, id) and not Parked(sets, id, m) and Index(name) ~= nil
    local waits
    Run(function()
        table.remove(source, i)
        if id == "class" then sets.classParked[name] = nil end
        local home = Find(sets.character, name)
        if not home then
            home = { name = m.name, icon = m.icon, body = m.body }
            sets.character[#sets.character + 1] = home
        end
        sets.layer = sets.layer or {}
        if Held(sets, name) then
            home.parked = true
            if wasIn then
                Remove(name)
                sets.layer[name] = nil
            end
        elseif wasIn then
            home.parked, home.icon, home.body = nil, m.icon, m.body
            sets.layer[name] = "character"
        elseif not Index(name) and Room() > 0 then
            home.parked = nil
            Make(home, "character")
            sets.layer[name] = "character"
        else
            home.parked, waits = true, true
        end
    end)
    Log("released %s from %s", name, id)
    return true, waits and "waits" or nil
end

-- Macro `name` of set `id` behind the scenes (`on`), or back. Back into the game it needs a free slot and its name
-- free there, else false and why: "room", "name" ("combat" in combat); the character's, one no specialization has
-- ("held"). A specialization not chosen now only remembers it: its macro comes in with it, or doesn't.
function Sets.Park(id, name, on)
    local sets = Sets.Mine()
    if not sets.enabled then return false end
    if InCombatLockdown() then return false, "combat" end
    Sets.Scan()
    local m = Find(ListOf(sets, id), name)
    if not m then return false end
    on = on and true or false
    if on == Parked(sets, id, m) then return true end
    if not on and id == "character" and Held(sets, name) then return false, "held" end
    if not on and InGame(sets, id) then
        if Index(name) then return false, "name" end
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

-- The specializations: { key, label, now } in the game's order (Classic: its talent groups), then any other one
-- with macros kept.
function Sets.Specs()
    local sets, out, seen = Sets.Mine(), {}, {}
    local now, nowLabel = ns.ActionBars.Spec()
    local function add(key, label)
        if seen[key] then return end
        seen[key] = true
        out[#out + 1] = { key = key, label = label, now = key == now }
    end
    local S = C_SpecializationInfo or {}
    if C_ClassTalents and S.GetSpecializationInfo and GetNumSpecializations then
        for i = 1, GetNumSpecializations() do
            local id, name = S.GetSpecializationInfo(i)
            if id and id ~= 0 then add("spec" .. id, name) end
        end
    else
        local groups = S.GetNumSpecGroups and S.GetNumSpecGroups() or GetNumTalentGroups and GetNumTalentGroups() or 1
        for group = 1, math.max(groups or 1, 1) do
            add("group" .. group, string.format(ns.L["Specialization %d"], group))
        end
    end
    add(now, nowLabel)
    local bars = ns.Character().bars or {}
    local keys = {}
    for key in pairs(sets.specs) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do add(key, bars[key] and bars[key].label or key) end
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
        if all and not Held(sets, m.name) then
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

return Sets
