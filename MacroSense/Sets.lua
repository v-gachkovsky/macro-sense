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
-- specialization coming in; `limit` the slots. Returns what the one going keeps (its macros in the slots, as
-- they are now), the names that leave the slots, the macros that come in, and those of `entering` that wait:
-- parked before, or no room, or the name taken by a macro that stays.
function Sets.Swap(now, layer, entering, limit)
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
    local add, wait = {}, {}
    for _, m in ipairs(entering) do
        if not m.parked and room > 0 and not taken[m.name] then
            add[#add + 1] = m
            taken[m.name], room = true, room - 1
        else
            wait[#wait + 1] = m
        end
    end
    return { leaving = leaving, drop = drop, add = add, wait = wait }
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
-- is kept in its layer (one not changed here leaves the layer's as it is); a renamed macro keeps its layer under the new name; a deleted one leaves its layer; a new one
-- joins the character's. `before` and `after`: name -> { body, icon }; `layer` as of before.
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
end

-- The macro buttons to put back for a specialization: { slot, name } of `record` (slot -> name) where the slot is
-- empty or has another of the character's macros (its place may have moved), and the macro is in the slots.
-- `at(slot)` says what is there: nil, "character" with the name, or anything else (a spell, an item, a general
-- macro), which stays.
function Sets.BarsBack(record, at, have)
    local out = {}
    for slot, name in pairs(record) do
        local kind, there = at(slot)
        if have[name] and (kind == nil or (kind == "character" and there ~= name)) then
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

-- What is on action slot `slot`: nil, "character" and the macro's name, or "other".
local function At(slot)
    local kind = GetActionInfo(slot)
    if not kind then return nil end
    if kind ~= "macro" then return "other" end
    local index = ns.ActionBars.MacroAt(slot)
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
    DeleteMacro(index)
    Log("deleted %s", name)
end
local function Make(m, layer)
    expect.made[m.name] = { layer = layer, at = GetTime() }
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
        Sets.Follow(before, after, sets.layer, { class = ClassList(), character = sets.character,
            spec = SpecList(sets, sets.active) })
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
    sets.bars[before] = BarsNow()
    sets.layer = Layers(sets)
    local plan = Sets.Swap(InSlots(), sets.layer, SpecList(sets, key), ns.MAX_CHARACTER)
    -- The one going keeps its macros as they are, and those it had parked.
    local kept = {}
    for _, m in ipairs(SpecList(sets, before)) do
        if m.parked then kept[#kept + 1] = m end
    end
    for _, m in ipairs(plan.leaving) do kept[#kept + 1] = m end
    sets.specs[before] = kept
    Log("specialization %s -> %s: out %d, in %d", tostring(before), key, #plan.drop, #plan.add)
    for _, name in ipairs(plan.drop) do
        Remove(name)
        sets.layer[name] = nil
    end
    for _, m in ipairs(plan.add) do
        m.parked = nil
        Make(m, "spec")
        sets.layer[m.name] = "spec"
    end
    local newly = 0 -- off the slots now, not by your choice before
    for _, m in ipairs(plan.wait) do
        if not m.parked then newly = newly + 1 end
        m.parked = true
    end
    sets.active = key
    Settle()
    Sets.PlaceBars(key)
    -- The game may show the macros made a little later: their buttons then.
    for _, delay in ipairs({ 0.5, 1.5, 4 }) do C_Timer.After(delay, function() Sets.PlaceBars(key) end) end
    return #plan.add, newly
end

-- The macro buttons of specialization `key` back where they were, for the macros in the slots now. Not when
-- another specialization came since, nor in combat.
function Sets.PlaceBars(key)
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
    busy = true
    local ok, err = pcall(function()
        if sets.active ~= key then
            local _, wait = Change(sets, key)
            waiting = waiting + wait
        end
        waiting = waiting + SyncClass(sets)
    end)
    busy = false
    Settle()
    if not ok then error(err, 0) end
    if waiting > 0 then ns.Print("%d macros wait off the slots: there is no room for them", waiting) end
end

function Sets.Pending() return pending end

-- The game tells of a new specialization in several events, some before it gives the new one: a look at once and
-- again a little later. A look when nothing changed changes nothing.
function Sets.Soon()
    for _, delay in ipairs({ 0.5, 2, 5 }) do C_Timer.After(delay, Sets.Update) end
end
if CreateFrame then -- the game (not the tests of the planning)
    local watch = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
        "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_ENTERING_WORLD" }) do
        pcall(watch.RegisterEvent, watch, event)
    end
    watch:SetScript("OnEvent", function() if ns.db and Sets.Mine().enabled then Sets.Soon() end end)
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

-- A macro in the slots into another layer (`to`: "class", "character", "spec"). Its place in the slots stays.
function Sets.Move(name, to)
    local sets = Sets.Mine()
    if not sets.enabled then return false end
    Sets.Scan()
    sets.layer = Layers(sets)
    local from = sets.layer[name]
    if not from then return false end
    if from == to then return true end
    local lists = { class = ClassList(), character = sets.character, spec = SpecList(sets, sets.active) }
    local m, i = Find(lists[from], name)
    if not m then return false end
    table.remove(lists[from], i)
    if to == "class" then sets.classParked[name] = nil end
    lists[to][#lists[to] + 1] = { name = m.name, icon = m.icon, body = m.body }
    sets.layer[name] = to
    return true
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
