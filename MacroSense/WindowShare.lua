-- The editor's Share menu: macros as a code to copy, and back (Share.lua, ShareWindow.lua); macro sets too. The
-- menu's button is made in Window.lua.
local _, ns = ...
local L = ns.L

local Window, shared = ns.Window, ns.WindowShared
local state = shared.state
local MAX_BODY, MAX_NAME, NEW_ICON = shared.MAX_BODY, shared.MAX_NAME, shared.NEW_ICON
local MacroRange, Letters, TabName = shared.MacroRange, shared.Letters, shared.TabName
local Load, Guard, Full, FreeName, FirstLetters = shared.Load, shared.Guard, shared.Full, shared.FreeName,
    shared.FirstLetters
local Macros = shared.Macros

-- Where each macro of a code goes, in order: { macro, name = a free one } into its own tab, or { macro, full =
-- true } with no free slot there, or { macro, long = true } for a text longer than the game allows.
function Window.ImportPlan(macros)
    local room, given, plan = {}, {}, {}
    for _, s in ipairs({ "general", "character" }) do
        local first, last, max = MacroRange(s)
        room[s] = max - (last - first + 1)
    end
    for i, m in ipairs(macros) do
        if Letters(m.body) > MAX_BODY then
            plan[i] = { macro = m, long = true }
        elseif room[m.scope] > 0 then
            room[m.scope] = room[m.scope] - 1
            local name = FreeName(FirstLetters(m.name, MAX_NAME), given)
            given[name] = true
            plan[i] = { macro = m, name = name }
        else
            plan[i] = { macro = m, full = true }
        end
    end
    return plan
end

-- Creates the macros of a code where ImportPlan puts them and opens the first, then done(). Unsaved changes
-- are asked about first.
function Window.Import(macros, done)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    Guard(function()
        local made, first, behind = 0, nil, {}
        for _, p in ipairs(Window.ImportPlan(macros)) do
            local m = p.macro
            -- A text from a guide has no icon: the question mark, so the game shows the spell's.
            local icon = m.icon ~= "" and m.icon or NEW_ICON
            if p.name then
                CreateMacro(p.name, icon, m.body, m.scope == "character")
                made, first = made + 1, first or p
            elseif p.full and m.scope == "character" and ns.Sets.Mine().enabled then
                behind[#behind + 1] = { name = m.name, icon = icon, body = m.body }
            end
        end
        -- Those with no free slot, macro sets on: behind the scenes (asked first).
        if #behind > 0 then
            Full("character", function()
                for _, m in ipairs(behind) do Window.MakeBehind(m.name, m.icon, m.body) end
                if done and not first then done() end
            end, #behind)
        end
        if not first then return end
        ns.History.Scan()
        ns.Print("imported %d of %d macros", made, #macros)
        state.scope, ns.db.scope = first.macro.scope, first.macro.scope
        Load(GetMacroIndexByName(first.name))
        if done then done() end
    end)
end

-- Macro sets as a code holds them (Share.EncodeSets): this character's (`key` nil), or another one's of yours,
-- with its macros in the game that are in no set as its own. Each set with its name and macros.
function Window.SetsData(key)
    local mine = ns.Character()
    local c = key and ns.db.characters[key] or mine
    local sets = c.sets or {}
    local class, specs = (ns.db.classMacros or {})[c.class or "?"] or {}, sets.specs or {}
    local keys = {}
    for id in pairs(specs) do keys[#keys + 1] = id end
    table.sort(keys)
    -- Its macros in the game in no set are its own (its sets off, or never on).
    local own, listed = {}, {}
    for _, list in ipairs({ class, sets.character or {} }) do
        for _, m in ipairs(list) do listed[m.name] = true end
    end
    for _, id in ipairs(keys) do
        for _, m in ipairs(specs[id]) do listed[m.name] = true end
    end
    for _, m in ipairs(sets.character or {}) do own[#own + 1] = m end
    local loose = {}
    for name, m in pairs(c ~= mine and c.macros or {}) do
        if not listed[name] then loose[#loose + 1] = { name = name, icon = m.icon, body = m.body } end
    end
    table.sort(loose, function(a, b) return a.name < b.name end)
    for _, m in ipairs(loose) do own[#own + 1] = m end

    local data = { class = c.class, sets = {} }
    local function add(id, label, list, parked)
        local set = { id = id, label = label, macros = {} }
        for _, m in ipairs(list) do
            set.macros[#set.macros + 1] = { name = m.name, icon = m.icon, body = m.body or "", parked = parked(m) }
        end
        if #set.macros > 0 then data.sets[#data.sets + 1] = set end
    end
    local function label(id)
        if c == mine then return ns.SetsWindow.Label(id) end
        local bars, group = (c.bars or {})[id], id:match("^group(%d+)$")
        if group then return ns.ActionBars.GroupLabel(tonumber(group)) end
        return bars and bars.label ~= "" and bars.label or L["No specialization yet"]
    end
    local function parked(m) return m.parked or nil end
    add("class", L["Class macros"], class, function(m) return (sets.classParked or {})[m.name] or nil end)
    add("character", L["This character's"], own, parked)
    for _, id in ipairs(keys) do add(id, label(id), specs[id], parked) end
    return data
end

-- Where each macro of sets `data` goes here: { other = another class's, sets = { { from = the set, to = the set
-- here, items = { { macro, name } or { macro, skip = "same" | "long" } }, new, same, long } } }. Its own set; of
-- another class, this character's. A name its set here has: the same text, skipped; another, a number added.
function Window.SetsImportPlan(data)
    local other = data.class ~= nil and data.class ~= ns.Character().class
    local plan, names = { other = other, sets = {}, new = 0 }, {}
    for _, set in ipairs(data.sets) do
        local to = other and "character" or set.id
        if not names[to] then
            names[to] = {}
            for _, m in ipairs(ns.Sets.List(to)) do names[to][m.name] = m.body or "" end
        end
        local here = names[to]
        local p = { from = set, to = to, items = {}, new = 0, same = 0, long = 0 }
        for _, m in ipairs(set.macros) do
            local body = m.body or ""
            if Letters(body) > MAX_BODY then
                p.items[#p.items + 1], p.long = { macro = m, skip = "long" }, p.long + 1
            elseif here[m.name] == body then
                p.items[#p.items + 1], p.same = { macro = m, skip = "same" }, p.same + 1
            else
                local name = FreeName(FirstLetters(m.name, MAX_NAME), here, true)
                here[name] = body
                p.items[#p.items + 1], p.new = { macro = m, name = name }, p.new + 1
            end
        end
        plan.new = plan.new + p.new
        plan.sets[#plan.sets + 1] = p
    end
    return plan
end

-- The macros of sets `data` into the sets here, as Window.SetsImportPlan puts them: behind the scenes; one of a
-- specialization not chosen now comes in with it, unless it was kept behind the scenes there. All or nothing.
function Window.ImportSets(data, done)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    if not ns.Sets.Mine().enabled then return ns.Print("turn on \"Macro sets\" first: the macros go into them") end
    Guard(function()
        local plan = Window.SetsImportPlan(data)
        ns.Sets.Atomic(function()
            for _, p in ipairs(plan.sets) do
                for _, item in ipairs(p.items) do
                    local m = item.macro
                    if item.name then
                        ns.Sets.Write(p.to, nil, item.name, m.icon ~= "" and m.icon or NEW_ICON, m.body or "")
                        if not ns.Sets.InGame(p.to) and not m.parked then ns.Sets.Park(p.to, item.name, false) end
                    end
                end
            end
        end)
        Window.RefreshList()
        ns.Print("imported %d macros into the sets, behind the scenes: take in those you need", plan.new)
        if done then done() end
    end)
end

local function ShareItems()
    local tab = TabName(state.scope)
    local general, character = GetNumMacros()
    local here = state.scope == "general" and general or character
    local function item(name, tip, onClick, disabled)
        return {
            name = name,
            disabled = disabled,
            onClick = onClick,
            onEnter = function(row)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(name, 1, 1, 1)
                GameTooltip:AddLine(tip, 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end,
        }
    end
    return {
        item(L["Link this macro in chat"], state.index and L["Puts a link to it in the chat. Players with MacroSense "
            .. "can click it to get the macro as it is saved now. Others see only its name. Shift-click on a macro "
            .. "in the list does the same."] or L["Save the macro first, then link it."], function()
            ns.Links.Insert({ scope = state.scope, name = state.name, icon = state.savedIcon, body = state.body })
        end, not state.index),
        item(L["Export this macro"], state.index and L["The code of the saved macro, to copy and share."]
            or L["Save the macro first, then export it."], function()
            ns.ShareWindow.Export({ { scope = state.scope, name = state.name, icon = state.savedIcon,
                body = state.body } })
        end, not state.index),
        item(L["Copy this macro's text"], state.index and L["The text of the saved macro, to paste into a guide, a "
            .. "forum or Discord. MacroSense can import it too."] or L["Save the macro first, then copy its text."],
            function() ns.ShareWindow.ExportText({ name = state.name, body = state.body }) end, not state.index),
        item(string.format(L["Export the %s tab (%d)"], tab, here), L["The code of every macro in this tab."],
            function() ns.ShareWindow.Export(Macros(state.scope)) end, here == 0),
        item(string.format(L["Export all macros (%d)"], general + character),
            L["The code of every macro in both tabs. On import, each one goes into its own tab."],
            function() ns.ShareWindow.Export(Macros()) end, general + character == 0),
        item(L["Export macro sets..."], L["The code of your macro sets: you choose which. Import it on another "
            .. "character, or share it."], function() ns.ShareWindow.ExportSets(Window.SetsData()) end,
            #Window.SetsData().sets == 0),
        item(L["Import a code or text..."], L["Paste a code, or a macro's text from a guide, to add its macros. "
            .. "Nothing gets replaced: if a name is taken, a number is added to it, like \"Fear 2\". Macro sets "
            .. "come from a code too, or from another character of yours."],
            function() ns.ShareWindow.Import() end),
    }
end
shared.ShareItems = ShareItems
