-- Macros from the spellbook, the window: the spells on the left, each checked to get a macro, of its own or joined
-- to another one's on a key held, a lower rank on a key too; where the spells go, what else the macros do and the
-- pet's macro on the right; the count against the free slots and Create at the bottom. The macros go into the
-- character's tab and, if asked, onto the action bars in place of their spells. The logic is Spellbook.lua.
local _, ns = ...
local L = ns.L

local SpellbookWindow = {}
ns.SpellbookWindow = SpellbookWindow

local WIDTH, HEIGHT, PAD, ROW_H = 940, 560, 14, 28
local LIST_W = 590
local NEW_ICON = 134400 -- question mark: #showtooltip picks the icon
local KEY_NAMES = { shift = "Shift", ctrl = "Ctrl", alt = "Alt", cmd = "Cmd" }
local SpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo

local frame, list, countText, problemText, createBtn
local kit, journal, rows, choices, macros, problems
local rowFrames, keys = {}, {}
local controls = {} -- by name, for the tests

local function Rows() return rows end

-- The macro a spell is in now, as planned.
local function MacroOf(spell)
    for _, m in ipairs(macros or {}) do
        for _, name in ipairs(m.spells) do
            if name == spell then return m end
        end
    end
end

-- Why a spell isn't checked.
local function State(row)
    if row.state == "has" then return string.format(L["Already in the macro \"%s\""], row.macro) end
    if row.state == "deleted" then return L["You deleted its macro"] end
    if row.state == "skipped" then return L["Left out last time"] end
    return ""
end

local Refresh

-- One row of the list: the check with the spell's name, then, while checked, how it gets a macro: its own or
-- with another spell on a key, and a lower rank on a key; while not, why it isn't checked.
local function Row(i)
    local r = CreateFrame("Frame", nil, list.child)
    r.row = rows[i] -- the controls read it as they are made
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetPoint("RIGHT")
    r:EnableMouse(true)
    r.check = ns.Check(r, "", function() return r.row and choices.picked[r.row.spell.name] end, function(on)
        choices.picked[r.row.spell.name] = on or nil
        Refresh()
    end)
    r.check:SetPoint("LEFT", 4, 0)
    r.state = ns.Text(r, 11, "dim")
    r.state:SetPoint("RIGHT", -6, 0)
    -- Its own macro, or with another spell's on a key.
    r.join = ns.Dropdown(r, 132, function()
        local items = { { key = "", name = L["Own macro"] } }
        for _, other in ipairs(rows) do
            local name = other.spell.name
            if name ~= r.row.spell.name and choices.picked[name] and not choices.join[name] then
                items[#items + 1] = { key = name, name = string.format(L["With %s"], name) }
            end
        end
        return items
    end, function() return choices.join[r.row.spell.name] and choices.join[r.row.spell.name].into or "" end,
    function(into)
        local name = r.row.spell.name
        choices.join[name] = into ~= "" and { into = into, key = (choices.join[name] or {}).key or keys[1] } or nil
        Refresh()
    end)
    -- A lower rank too, where the spell has more than one: "—" for none.
    r.rank = ns.Dropdown(r, 96, function()
        local items = { { key = "", name = "—" } }
        local ranks = r.row.spell.ranks
        for n = 1, #ranks - 1 do items[#items + 1] = { key = ranks[n], name = string.format(L["+ %s"], ranks[n]) } end
        return items
    end, function() return choices.lower[r.row.spell.name] and choices.lower[r.row.spell.name].rank or "" end,
    function(rank)
        local name = r.row.spell.name
        choices.lower[name] = rank ~= "" and { rank = rank, key = (choices.lower[name] or {}).key or keys[1] } or nil
        Refresh()
    end)
    -- The key of the join or of the lower rank.
    r.key = ns.Dropdown(r, 62, function()
        local items = {}
        for _, key in ipairs(keys) do items[#items + 1] = { key = key, name = KEY_NAMES[key] } end
        return items
    end, function()
        local name = r.row.spell.name
        local held = choices.join[name] or choices.lower[name]
        return held and held.key
    end, function(key)
        local name = r.row.spell.name
        local held = choices.join[name] or choices.lower[name]
        if held then held.key = key end
        Refresh()
    end)
    r.key:SetPoint("RIGHT", -4, 0)
    r.rank:SetPoint("RIGHT", r.key, "LEFT", -4, 0)
    r.rank:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Lower rank"], 1, 1, 1)
        GameTooltip:AddLine(#r.row.spell.ranks > 1 and L["A lower rank of the spell, cast while you hold the key. It "
            .. "costs less mana: to heal a little, to put a cheap spell on an enemy for them to dispel, or to waste "
            .. "a warrior's Spell Reflection on it."]
            or L["You know only one rank of this spell."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    r.rank:HookScript("OnLeave", function() GameTooltip:Hide() end)
    r.join:SetPoint("RIGHT", kit.ranks and r.rank or r.key, "LEFT", -4, 0) -- Retail: no lower rank, no gap for it
    -- Where this spell goes, over the choice for all: "—" keeps that one.
    r.unit = ns.Dropdown(r, 96, function()
        return { { key = "", name = "—" }, { key = "mouseover", name = L["Mouseover"] },
            { key = "target", name = L["Your target"] }, { key = "focus", name = L["Focus"] } }
    end, function() return choices.unitOf[r.row.spell.name] or "" end, function(unit)
        choices.unitOf[r.row.spell.name] = unit ~= "" and unit or nil
        Refresh()
    end)
    r.unit:SetPoint("RIGHT", r.join, "LEFT", -4, 0)
    r.unit:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Where this spell goes"], 1, 1, 1)
        GameTooltip:AddLine(L["\"—\" goes where the choice for all attacks or helpful spells says. Pick another to "
            .. "send only this spell elsewhere."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    r.unit:HookScript("OnLeave", function() GameTooltip:Hide() end)
    -- The macro the spell gets, just over the mouse, where the cursor doesn't cover it: over the row and over the
    -- spell's name, which is a button of its own; a click on the check shows the macro as it is now.
    local function Tip(owner)
        local spell = r.row.spell.name
        GameTooltip:SetOwner(owner, "ANCHOR_NONE")
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", x / scale, y / scale + 12)
        GameTooltip:AddLine(spell, 1, 1, 1)
        local m = choices.picked[spell] and MacroOf(spell)
        if m then
            GameTooltip:AddLine(string.format(L["Macro \"%s\":"], m.name), 0.8, 0.8, 0.8)
            for line in m.body:gmatch("[^\n]+") do GameTooltip:AddLine(line, 0.6, 0.9, 1) end
        end
        if problems[spell] then GameTooltip:AddLine(problems[spell], 1, 0.3, 0.3, true) end
        GameTooltip:Show()
    end
    r:SetScript("OnEnter", Tip)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    r.check:HookScript("OnEnter", Tip)
    r.check:HookScript("OnLeave", function() GameTooltip:Hide() end)
    r.check:HookScript("OnClick", Tip)
    return r
end

local function ShowRow(r, row)
    r.row = row
    local spell = row.spell
    local picked = choices.picked[spell.name]
    local label = spell.name
    if row.state == "new" then label = label .. " |cff66ccff" .. L["new"] .. "|r" end
    if problems[spell.name] then label = "|cffff5555" .. label .. "|r" end
    r.check:SetLabel(label)
    r.check:Refresh()
    r.state:SetText(not picked and State(row) or "")
    local joined, lower = choices.join[spell.name], choices.lower[spell.name]
    r.join:SetShown(picked and true or false)
    r.unit:SetShown(picked and spell.kind ~= "self" or false)
    r.unit:Refresh()
    -- In the clients with ranks; dim with one rank known, its tooltip says why.
    r.rank:SetShown(picked and not joined and kit.ranks or false)
    r.rank:SetEnabled(#spell.ranks > 1)
    r.key:SetShown(picked and (joined or lower) and true or false)
    r.join:Refresh()
    r.rank:Refresh()
    r.key:Refresh()
    r:Show()
end

function Refresh()
    -- A join to a spell no longer of its own goes.
    for name, join in pairs(choices.join) do
        if not choices.picked[join.into] or choices.join[join.into] then choices.join[name] = nil end
    end
    macros, problems = ns.Spellbook.Plan(kit, choices)
    for i, row in ipairs(rows) do
        rowFrames[i] = rowFrames[i] or Row(i)
        ShowRow(rowFrames[i], row)
    end
    for i = #rows + 1, #rowFrames do rowFrames[i]:Hide() end
    list.child:SetHeight(math.max(1, #rows * ROW_H))
    local over = #macros > kit.free
    countText:SetText(string.format(L["Macros: %d. Free slots: %d."], #macros, kit.free))
    countText:SetTextColor(over and 1 or 0.8, over and 0.3 or 0.8, over and 0.3 or 0.8)
    local _, problem = next(problems)
    problemText:SetText(over and L["Not enough room: leave some spells out, or join them to others on a key."]
        or problem or "")
    createBtn.label:SetText(string.format(L["Create macros (%d)"], #macros))
    createBtn:SetEnabled(#macros > 0 and not over and problem == nil)
    for _, control in pairs(controls) do
        if control.Refresh and control ~= createBtn then control:Refresh() end
    end
    -- Without a macro for the pet, its choices are dim and say nothing.
    local pet = choices.pet ~= nil
    for name, control in pairs(controls) do
        if name:find("^pet.") and name ~= "petBlock" then
            control:SetEnabled(pet)
            control:SetAlpha(pet and 1 or 0.45)
            if not pet and control.arrow then control.label:SetText("—") end
        end
    end
end

-- The action slots with `spell` on them.
local function SlotsWith(spell)
    local out = {}
    for slot = 1, 180 do
        local kind, id = GetActionInfo(slot)
        if kind == "spell" and id then
            local ok, name = pcall(SpellName, id)
            if ok and name == spell then out[#out + 1] = slot end
        end
    end
    return out
end

-- The planned macros into the character's tab, one at a time: the game makes only a few at once and drops the rest
-- without a word. One it hasn't made is tried again a second later, then told in chat. Then each spell's action
-- buttons get its macro, if asked, and what was made is remembered for the next time.
local STEP, RETRY = 0.3, 1
function SpellbookWindow.Create()
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    Refresh()
    if #macros == 0 or #macros > kit.free or next(problems) then return end
    local queue, offered, book, bars = macros, rows, journal, choices.bars
    local made, names, failed = {}, {}, {}
    SpellbookWindow.Close()
    ns.Print("making %d macros...", #queue)

    local function finish()
        -- After all are made: the game sorts the macros by name, their numbers change with each new one.
        local placed = 0
        if bars and not InCombatLockdown() then
            for _, n in ipairs(names) do
                local spell = n.macro.spells[1]
                if spell then
                    local slots = SlotsWith(spell)
                    ns.ActionBars.Place(GetMacroIndexByName(n.name), slots)
                    placed = placed + #slots
                end
            end
        end
        ns.Spellbook.Remember(book, offered, made, failed)
        ns.Print("macros made: %d; put on the action bars: %d", #names, placed)
        if ns.Window.RefreshList then ns.Window.RefreshList() end
    end

    local function step(i, again)
        local m = queue[i]
        if not m then return finish() end
        if InCombatLockdown() then
            ns.Print("macros cannot be changed in combat")
            for j = i, #queue do
                for _, spell in ipairs(queue[j].spells) do failed[spell] = true end
            end
            return finish()
        end
        local name = again or ns.Window.FreeName(m.name)
        local _, answer = pcall(CreateMacro, name, NEW_ICON, m.body, true)
        -- Made is what the game has now, whatever it answered: the answer differs between its clients.
        local index = GetMacroIndexByName(name)
        if index and index > 0 then
            names[#names + 1] = { name = name, macro = m }
            for _, spell in ipairs(m.spells) do made[spell] = { name = name, body = m.body } end
        elseif not again then
            return C_Timer.After(RETRY, function() step(i, name) end)
        else
            ns.Print("could not make the macro \"%s\" (the game said: %s)", name, tostring(answer))
            if ns.db.debug then ns.Print("its text: %s", (m.body:gsub("\n", " | "))) end
            for _, spell in ipairs(m.spells) do failed[spell] = true end
        end
        C_Timer.After(STEP, function() step(i + 1) end)
    end
    step(1)
end

-- A dropdown on the right with its label before it; with `above`, the label over it and the dropdown as wide as
-- the column, for long choices.
local function Labeled(parent, label, y, width, getItems, getValue, onSelect, name, above)
    local text = ns.Text(parent, 12)
    text:SetPoint("TOPLEFT", 0, y - 4)
    text:SetText(label)
    local d = ns.Dropdown(parent, width, getItems, getValue, onSelect)
    if above then
        d:SetPoint("TOPLEFT", 0, y - 22)
        d:SetPoint("RIGHT")
    else
        d:SetPoint("TOPRIGHT", 0, y)
    end
    controls[name] = d
    return d
end

local function Check(parent, label, y, get, set, name)
    local c = ns.Check(parent, label, get, function(on)
        set(on)
        Refresh()
    end)
    c:SetPoint("TOPLEFT", 0, y)
    controls[name] = c
    return c
end

local function Build()
    keys = {}
    for _, key in ipairs(ns.Wizard.KEYS) do
        if key ~= "cmd" or (IsMacClient and IsMacClient()) then keys[#keys + 1] = key end
    end

    frame = CreateFrame("Frame", "MacroSenseSpellbook", UIParent, "BackdropTemplate")
    frame:HookScript("OnShow", function() ns.Window.ClearFocus() end) -- the keys come here, not to the editor
    table.insert(UISpecialFrames, "MacroSenseSpellbook") -- Esc closes it
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 40)
    ns.Backdrop(frame, "bg", "border", true)
    frame:Hide()

    -- Title bar: drag to move.
    local title = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    title:SetPoint("TOPLEFT", 1, -1)
    title:SetPoint("TOPRIGHT", -1, -1)
    title:SetHeight(34)
    ns.Backdrop(title, "panel", "panel")
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() frame:StartMoving() end)
    title:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local titleText = ns.Text(title, 14)
    titleText:SetPoint("LEFT", 12, 0)
    titleText:SetText(L["Macros from the Spellbook"])
    local close = ns.Button(title, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    local intro = ns.Text(frame, 12, "dim")
    intro:SetPoint("TOPLEFT", PAD, -34 - PAD)
    intro:SetWidth(LIST_W)
    intro:SetText(L["Check the spells to make macros for. A macro names the spell with no rank, so it always casts "
        .. "the highest rank you know. Point at a spell to see its macro."])

    -- The columns' names over the rows, each with what it is for under the mouse; as wide as the row's
    -- dropdowns, from the right.
    local head = CreateFrame("Frame", nil, frame)
    head:SetPoint("TOPLEFT", PAD, -34 - PAD - 40)
    head:SetSize(LIST_W, 20)
    local function Column(label, width, tipTitle, tip)
        local c = CreateFrame("Button", nil, head)
        c:SetSize(width, 20)
        c.label = ns.Text(c, 11, "dim")
        c.label:SetPoint("LEFT", 8, 0)
        c.label:SetText(label)
        c:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(tipTitle, 1, 1, 1)
            GameTooltip:AddLine(tip, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        c:SetScript("OnLeave", function() GameTooltip:Hide() end)
        controls["column" .. #head.columns + 1] = c
        head.columns[#head.columns + 1] = c
        return c
    end
    head.columns = {}
    local spellCol = Column(L["Spell"], 160, L["Spell"], L["Check a spell to make a macro for it. A spell with no "
        .. "check box ticked has a macro already, or you left it out before: you can still tick it."])
    spellCol:SetPoint("LEFT", 16, 0)
    local key = Column(L["Key"], 62, L["Key"], L["The key to hold for a spell joined to another macro, or for a "
        .. "lower rank."])
    key:SetPoint("RIGHT", -4, 0)
    local rank = Column(L["Lower rank"], 96, L["Lower rank"], L["A lower rank of the spell, cast while you hold the "
        .. "key. It costs less mana: to heal a little, to put a cheap spell on an enemy for them to dispel, or to "
        .. "waste a warrior's Spell Reflection on it."])
    rank:SetPoint("RIGHT", key, "LEFT", -4, 0)
    local macro = Column(L["Macro"], 132, L["Macro"], L["\"Own macro\": the spell gets a macro of its own. \"With\" "
        .. "another spell: it goes into that spell's macro and is cast while you hold the key. This saves macro "
        .. "slots."])
    macro:SetPoint("RIGHT", kit.ranks and rank or key, "LEFT", -4, 0)
    local target = Column(L["Target"], 96, L["Where this spell goes"], L["\"—\" goes where the choice for all "
        .. "attacks or helpful spells says. Pick another to send only this spell elsewhere."])
    target:SetPoint("RIGHT", macro, "LEFT", -4, 0)

    -- The spells, scrolling.
    list = CreateFrame("ScrollFrame", nil, frame)
    list:SetPoint("TOPLEFT", PAD, -34 - PAD - 62)
    list:SetPoint("BOTTOMLEFT", PAD, PAD)
    list:SetWidth(LIST_W)
    ns.AttachScrollBar(list, ROW_H * 3)
    list.child = CreateFrame("Frame", nil, list)
    list.child:SetSize(LIST_W, 1)
    list:SetScrollChild(list.child)

    -- The choices, on the right.
    local side = CreateFrame("Frame", nil, frame)
    side:SetPoint("TOPLEFT", PAD + LIST_W + 30, -34 - PAD)
    side:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    local function targets(kind)
        local some = kind == "harm" and L["The enemy under the mouse, else your target"]
            or L["The friend under the mouse, else your target"]
        return function()
            return { { key = "mouseover", name = some }, { key = "target", name = L["Your target"] },
                { key = "focus", name = L["Your focus, else your target"] } }
        end
    end
    local y = 0
    Labeled(side, L["Attacks go to"], y, 150, targets("harm"), function() return choices.units.harm end,
        function(key)
            choices.units.harm = key
            Refresh()
        end, "harm", true)
    y = y - 54
    Labeled(side, L["Helpful spells go to"], y, 150, targets("help"), function() return choices.units.help end,
        function(key)
            choices.units.help = key
            Refresh()
        end, "help", true)
    y = y - 60
    Check(side, L["Start auto attack with each attack"], y, function() return choices.startattack end,
        function(on) choices.startattack = on end, "startattack")
    y = y - 26
    Check(side, L["Stop your cast before an interrupt"], y, function() return choices.stopcasting end,
        function(on) choices.stopcasting = on end, "stopcasting")
    y = y - 26
    Check(side, L["Put them on the bars in place of the spells"], y, function() return choices.bars end,
        function(on) choices.bars = on end, "bars")

    -- The pet's macro: what it does with no key held and with each key.
    y = y - 40
    local pet = CreateFrame("Frame", nil, side)
    pet:SetPoint("TOPLEFT", 0, y)
    pet:SetPoint("RIGHT")
    pet:SetHeight(200)
    controls.petBlock = pet
    Check(pet, L["A macro for your pet"], 0, function() return choices.pet ~= nil end, function(on)
        choices.pet = on and { none = "attack", shift = "follow" } or nil
    end, "pet")
    local function actions(none)
        return function()
            local items = none and {} or { { key = "", name = L["Nothing"] } }
            for _, a in ipairs(ns.Wizard.PetActions(LE_EXPANSION_LEVEL_CURRENT)) do
                items[#items + 1] = { key = a.key, name = L[a.name] }
            end
            return items
        end
    end
    local py = -28
    Labeled(pet, L["No key"], py, 150, actions(true), function() return choices.pet and choices.pet.none end,
        function(key)
            if choices.pet then choices.pet.none = key end
            Refresh()
        end, "petNone")
    for _, key in ipairs(keys) do
        py = py - 28
        Labeled(pet, KEY_NAMES[key], py, 150, actions(false), function() return choices.pet and choices.pet[key] or "" end,
            function(action)
                if choices.pet then choices.pet[key] = action ~= "" and action or nil end
                Refresh()
            end, "pet" .. KEY_NAMES[key])
    end
    py = py - 32
    Check(pet, L["Attack the enemy under the mouse first"], py, function() return choices.petMouseover end,
        function(on) choices.petMouseover = on end, "petMouseover")

    -- The count and Create, at the bottom.
    createBtn = ns.Button(side, L["Create macros (%d)"], 160, function() SpellbookWindow.Create() end, true)
    createBtn:SetPoint("BOTTOMRIGHT", 0, 0)
    controls.create = createBtn
    countText = ns.Text(side, 12)
    countText:SetPoint("BOTTOMLEFT", 0, 34)
    problemText = ns.Text(side, 11)
    problemText:SetPoint("BOTTOMLEFT", 0, 50)
    problemText:SetPoint("RIGHT")
    problemText:SetTextColor(1, 0.4, 0.4)
end

function SpellbookWindow.Open()
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    kit = ns.Spellbook.Kit()
    journal = ns.Spellbook.Journal(ns.char)
    rows = ns.Spellbook.Rows(kit, journal)
    -- The first tab's spells (Attack, racials) after the class's.
    local order = {}
    for i, row in ipairs(rows) do order[row] = i end
    table.sort(rows, function(a, b)
        if (a.spell.general or false) ~= (b.spell.general or false) then return not a.spell.general end
        return order[a] < order[b]
    end)
    choices = ns.Spellbook.Fresh(kit)
    ns.Window.Ready() -- its colors
    for _, row in ipairs(rows) do
        if row.checked then choices.picked[row.spell.name] = true end
    end
    if not frame then Build() end -- its controls read the choices as they are made
    controls.petBlock:SetShown(kit.pet and true or false)
    controls.column3:SetShown(kit.ranks) -- Lower rank: Retail has no ranks
    frame:Show()
    frame:Raise()
    Refresh()
end

function SpellbookWindow.Close() if frame then frame:Hide() end end
function SpellbookWindow.IsShown() return frame ~= nil and frame:IsShown() end
function SpellbookWindow.Toggle()
    if SpellbookWindow.IsShown() then return SpellbookWindow.Close() end
    SpellbookWindow.Open()
end

-- For the tests: a control by name ("harm", "help", "startattack", "stopcasting", "bars", "pet", "petNone",
-- "petShift", "petMouseover", "create"), the rows, the row frames and the macros planned.
function SpellbookWindow.Control(name) return controls[name] end
SpellbookWindow.Rows = Rows
function SpellbookWindow.RowFrame(i) return rowFrames[i] end
function SpellbookWindow.Planned() return macros end

return SpellbookWindow
