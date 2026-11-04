-- Macro sets, what they are: a window that tells it, and turns them on (the check box "Macro sets" in the editor
-- asks with it). Also "Sort by spells", asked first. The sets themselves are in the editor's list (Window.lua);
-- the logic is Sets.lua.
local _, ns = ...
local L = ns.L

local SetsWindow = {}
ns.SetsWindow = SetsWindow

local WIDTH, HEIGHT, PAD = 560, 360, 14
local MAX_LISTED = 12 -- moves listed in the question of "Sort by spells"; the rest are counted

local frame, onBtn, onNote

-- A set's name: "class", "character" or a specialization's key.
function SetsWindow.Label(id)
    if id == "class" then return L["Class macros"] end
    if id == "character" then return L["This character's"] end
    for _, spec in ipairs(ns.Sets.Specs()) do
        if spec.key == id then return spec.label end
    end
    return id
end

-- Turned on already: no button, it says so.
local function Refresh()
    if not frame then return end
    local on = ns.Sets.Mine().enabled
    onBtn:SetShown(not on)
    onNote:SetShown(on)
end
SetsWindow.Refresh = Refresh

StaticPopupDialogs.MACROSENSE_SETS_SORT = {
    text = "Move these macros to where their spells are?\n\n%s",
    button1 = "Move", button2 = "Cancel",
    OnAccept = function(_, moves)
        ns.Print("moved: %d", ns.Sets.ApplySort(moves))
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs.MACROSENSE_SETS_OFF = {
    text = "Turn off macro sets?\n\n%s",
    button1 = "Turn off", button2 = "Cancel",
    OnAccept = function() ns.Window.Told(ns.Sets.Disable()) end,
    OnHide = function() ns.Window.SetsChanged() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- Not all of them fit: you choose which macros come into the game, those MacroSense would pick checked first. One
-- whose name is in the game, or chosen already, can't be.
local choose, chooseRows = nil, {}
local CHOOSE_ROW = 24
local function ChooseOff()
    ns.Window.Ready()
    local all, room = ns.Sets.OffChoice()
    local picked = {}
    local first = ns.Sets.OffPlan()
    for _, b in ipairs(first) do picked[b.m] = true end
    if not choose then
        choose = CreateFrame("Frame", "MacroSenseSetsOff", UIParent, "BackdropTemplate")
        table.insert(UISpecialFrames, "MacroSenseSetsOff") -- Esc closes it
        choose:SetFrameStrata("DIALOG")
        choose:SetToplevel(true)
        choose:SetClampedToScreen(true)
        choose:EnableMouse(true)
        choose:SetSize(460, 500)
        choose:SetPoint("CENTER", 0, 40)
        ns.Backdrop(choose, "bg", "border", true)
        local title = ns.Text(choose, 14)
        title:SetPoint("TOPLEFT", PAD * 2, -PAD * 2)
        title:SetText(L["Turn off macro sets"])
        choose.intro = ns.Text(choose, 13)
        choose.intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
        choose.intro:SetPoint("RIGHT", -PAD * 2, 0)
        choose.intro:SetSpacing(3)
        choose.scroll = CreateFrame("ScrollFrame", nil, choose)
        choose.scroll:SetPoint("TOPLEFT", choose.intro, "BOTTOMLEFT", 0, -12)
        choose.scroll:SetPoint("BOTTOMRIGHT", -PAD * 2 - 14, PAD * 2 + 60)
        choose.list = CreateFrame("Frame", nil, choose.scroll)
        choose.list:SetSize(1, 1)
        choose.scroll:SetScrollChild(choose.list)
        ns.AttachScrollBar(choose.scroll, CHOOSE_ROW * 3)
        -- The game hides a row scrolled out of the list but it still takes the mouse: one over "Turn off" took its
        -- click. Rows out of sight are hidden.
        choose.scroll:HookScript("OnVerticalScroll", function() choose.clip() end)
        choose.count = ns.Text(choose, 12)
        choose.count:SetPoint("BOTTOMLEFT", PAD * 2, PAD * 2 + 34)
        choose.off = ns.Button(choose, L["Turn off"], 160, function()
            local bring = {}
            for _, c in ipairs(choose.all) do
                if choose.picked[c.m] then bring[#bring + 1] = { m = c.m, id = c.id } end
            end
            choose:Hide()
            ns.Window.Told(ns.Sets.Disable(bring))
        end, true)
        choose.off:SetPoint("BOTTOMLEFT", PAD * 2, PAD * 2)
        local cancel = ns.Button(choose, L["Cancel"], 120, function() choose:Hide() end)
        cancel:SetPoint("LEFT", choose.off, "RIGHT", 10, 0)
        -- Over the list, whatever is in it.
        for _, b in ipairs({ choose.off, cancel }) do b:SetFrameLevel(choose.scroll:GetFrameLevel() + 10) end
        choose:SetScript("OnHide", function() ns.Window.SetsChanged() end)
    end
    choose.all, choose.picked, choose.room = all, picked, room
    choose.intro:SetText(string.format(L["Not all the macros behind the scenes fit into the game: there are %d free "
        .. "slots. Choose which come in. The rest stay kept for later, and all go back where they were when you turn "
        .. "the sets on again."], room))
    local function refresh()
        local count, names = 0, {}
        for m in pairs(choose.picked) do
            count = count + 1
            names[m.name] = m
        end
        for i, c in ipairs(choose.all) do
            local row = chooseRows[i]
            local blocked = c.taken or (names[c.m.name] and names[c.m.name] ~= c.m)
                or (not choose.picked[c.m] and count >= choose.room)
            row:SetEnabled(not blocked)
            row:SetAlpha(blocked and 0.45 or 1)
            row.Refresh(row)
        end
        choose.count:SetText(string.format(L["Chosen: %d of %d free slots"], count, choose.room))
    end
    choose.refresh = refresh
    -- The rows in sight shown, the others hidden (all while the list has no height yet).
    function choose.clip()
        local top, height = choose.scroll:GetVerticalScroll() or 0, choose.scroll:GetHeight() or 0
        for i, row in ipairs(chooseRows) do
            local y = (i - 1) * CHOOSE_ROW
            row:SetShown(i <= #choose.all and (height <= 0 or (y + CHOOSE_ROW > top and y < top + height)))
        end
    end
    for i, c in ipairs(all) do
        local row = chooseRows[i]
        if not row then
            row = ns.Check(choose.list, "", function()
                    local r = chooseRows[i] -- nil while it is made
                    return r ~= nil and r.c ~= nil and choose.picked[r.c.m] ~= nil
                end,
                function(on)
                    choose.picked[chooseRows[i].c.m] = on or nil
                    choose.refresh()
                end)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * CHOOSE_ROW)
            chooseRows[i] = row
        end
        row.c = c
        row:SetLabel(c.taken and string.format(L["%s  (%s; a macro of this name is in the game)"], c.m.name,
            SetsWindow.Label(c.id)) or string.format("%s  (%s)", c.m.name, SetsWindow.Label(c.id)))
        row:Show()
    end
    for i = #all + 1, #chooseRows do chooseRows[i]:Hide() end
    choose.list:SetSize(400, math.max(1, #all * CHOOSE_ROW))
    choose.scroll:SetVerticalScroll(0)
    refresh()
    choose.clip()
    choose:Show()
    choose:Raise()
end
-- For the tests: the choice, if shown.
function SetsWindow.Choosing() return choose ~= nil and choose:IsShown() and choose or nil end
function SetsWindow.ChooseRows() return chooseRows end

-- "Macro sets" cleared: what comes into the game told first, then turned off (at once when nothing is behind the
-- scenes). Not all fit: you choose.
function SetsWindow.AskOff()
    local bring, left = ns.Sets.OffPlan()
    if #bring == 0 and #left == 0 then return ns.Window.Told(ns.Sets.Disable()) end
    for _, x in ipairs(left) do
        if x.why == "room" then return ChooseOff() end
    end
    local lines = {}
    if #bring > 0 then
        lines[#lines + 1] = string.format(L["%d macros behind the scenes come into the game, so you have them all "
            .. "here. When you turn the sets on again, they go back where they were."], #bring)
    end
    if #left > 0 then
        local names = {}
        for i, x in ipairs(left) do
            if i > MAX_LISTED then
                names[#names + 1] = string.format(L["and %d more"], #left - MAX_LISTED)
                break
            end
            names[#names + 1] = x.name
        end
        lines[#lines + 1] = string.format(L["%d don't fit (no free slot, or a macro of the same name is in the game "
            .. "already) and stay kept for later: %s."], #left, table.concat(names, ", "))
    end
    ns.Ask("MACROSENSE_SETS_OFF", table.concat(lines, "\n\n"))
end

function SetsWindow.Sort()
    local moves = ns.Sets.SortPlan()
    if #moves == 0 then return ns.Print("nothing to move: each macro is where its spells are") end
    local lines = {}
    for i, move in ipairs(moves) do
        if i > MAX_LISTED then
            lines[#lines + 1] = string.format(L["and %d more"], #moves - MAX_LISTED)
            break
        end
        lines[#lines + 1] = string.format("%s: %s > %s", move.name, SetsWindow.Label(move.from),
            SetsWindow.Label(move.to))
    end
    ns.Ask("MACROSENSE_SETS_SORT", table.concat(lines, "\n"), nil, moves)
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseSets", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseSets") -- Esc closes it
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 40)
    ns.Backdrop(frame, "bg", "border", true)
    frame:Hide()
    frame:SetScript("OnShow", Refresh)
    -- Closed without turning them on: the check box in the editor stays clear.
    frame:SetScript("OnHide", function() ns.Window.SetsChanged() end)

    -- Title bar: drag to move.
    local bar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(34)
    ns.Backdrop(bar, "panel", "panel")
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() frame:StartMoving() end)
    bar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local barText = ns.Text(bar, 14)
    barText:SetPoint("LEFT", 12, 0)
    barText:SetText(L["Macro sets"])
    local close = ns.Button(bar, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    local intro = ns.Text(frame, 13)
    intro:SetPoint("TOPLEFT", PAD * 2, -34 - PAD * 2)
    intro:SetPoint("RIGHT", -PAD * 2, 0)
    intro:SetSpacing(4)
    intro:SetText(L["A character has only 30 macro slots. Macro sets make room: each specialization gets macros "
        .. "of its own. Choose a specialization, and its macros come into the game, onto their buttons, while the "
        .. "others' wait behind the scenes.\n\nClass macros are the same on all your characters of one class: "
        .. "change one, and the others get it too. This character's macros stay in every specialization.\n\nOnce "
        .. "turned on, all your character macros go into \"This character's\". Move them to a specialization or to "
        .. "the class in the list of macros: drag one there (hold Ctrl to copy it), or use \"...\" by its name. Or "
        .. "let \"Sort by spells\" do it. A backup of your macros is made first."])
    onBtn = ns.Button(frame, L["Turn on macro sets"], 200, function()
        ns.Sets.Enable()
        frame:Hide()
    end, true)
    onBtn:SetPoint("BOTTOMLEFT", PAD * 2, PAD * 2)
    local cancel = ns.Button(frame, L["Cancel"], 120, function() frame:Hide() end)
    cancel:SetPoint("LEFT", onBtn, "RIGHT", 10, 0)
    onNote = ns.Text(frame, 12, "dim")
    onNote:SetPoint("BOTTOMLEFT", PAD * 2, PAD * 2 + 4)
    onNote:SetText(L["Macro sets are on. Clear \"Macro sets\" to turn them off: the macros behind the scenes "
        .. "come into the game, and go back when you turn the sets on again."])
    -- All of it, in detail: the guide's section (in a lower layer: this one closes first).
    local how = ns.Button(frame, L["How it works"], 140, function()
        frame:Hide()
        ns.HelpWindow.OpenOn(L["Macro sets"])
    end)
    how:SetPoint("BOTTOMRIGHT", -PAD * 2, PAD * 2)
    SetsWindow.how = how
    onNote:SetPoint("RIGHT", how, "LEFT", -10, 0)
    onBtn:HookScript("OnShow", function() cancel:Show() end)
    onBtn:HookScript("OnHide", function() cancel:Hide() end)
end

-- No free slot, macro sets on: asked before a macro is made behind the scenes, with "Don't remind me again"; after
-- that, made at once. `count` macros; `go()` makes them. `moving`: a general macro moved into the character's.
local ask
function SetsWindow.AskBehind(count, go, moving)
    if ns.db.noBehindAsk then return go() end
    ns.Window.Ready()
    if not ask then
        ask = CreateFrame("Frame", "MacroSenseBehind", UIParent, "BackdropTemplate")
        table.insert(UISpecialFrames, "MacroSenseBehind") -- Esc closes it
        ask:SetFrameStrata("DIALOG")
        ask:SetToplevel(true)
        ask:SetClampedToScreen(true)
        ask:EnableMouse(true)
        ask:SetSize(440, 200)
        ask:SetPoint("CENTER", 0, 80)
        ns.Backdrop(ask, "bg", "border", true)
        ask.text = ns.Text(ask, 13)
        ask.text:SetPoint("TOPLEFT", PAD * 2, -PAD * 2)
        ask.text:SetPoint("RIGHT", -PAD * 2, 0)
        ask.text:SetSpacing(4)
        ask.check = ns.Check(ask, L["Don't remind me again"], function() return ask.quiet end, function(on)
            ask.quiet = on
        end)
        ask.check:SetPoint("BOTTOMLEFT", PAD * 2, PAD * 2 + 34)
        ask.yes = ns.Button(ask, L["Make it behind the scenes"], 220, function()
            ask:Hide()
            if ask.quiet then ns.db.noBehindAsk = true end
            ask.go()
        end, true)
        ask.yes:SetPoint("BOTTOMLEFT", PAD * 2, PAD * 2)
        local cancel = ns.Button(ask, L["Cancel"], 120, function() ask:Hide() end)
        cancel:SetPoint("LEFT", ask.yes, "RIGHT", 10, 0)
    end
    ask.go, ask.quiet = go, false
    ask.yes.label:SetText(moving and L["Move it behind the scenes"] or L["Make it behind the scenes"])
    ask.text:SetText(moving and L["All 30 slots are taken. MacroSense moves the macro behind the scenes, in \"This "
        .. "character's\", where it takes no slot, and off the action bars. To use it, put another macro behind the "
        .. "scenes and take it in."]
        or count > 1 and string.format(L["%d of the macros don't fit: all 30 slots are taken. MacroSense "
        .. "keeps them behind the scenes, in \"This character's\", where they take no slot. To use one, put another "
        .. "macro behind the scenes and take it in."], count)
        or L["All 30 slots are taken. MacroSense keeps the new macro behind the scenes, in \"This character's\", "
        .. "where it takes no slot. To use it, put another macro behind the scenes and take it in."])
    ask.check:Refresh()
    ask:Show()
    ask:Raise()
end
-- For the tests: the question, if shown.
function SetsWindow.Asking() return ask ~= nil and ask:IsShown() and ask or nil end

function SetsWindow.Open()
    ns.Window.Ready() -- its colors
    if not frame then Build() end
    frame:Show()
    frame:Raise()
    Refresh()
end
function SetsWindow.Close() if frame then frame:Hide() end end
function SetsWindow.IsShown() return frame ~= nil and frame:IsShown() end
function SetsWindow.Toggle()
    if SetsWindow.IsShown() then return SetsWindow.Close() end
    SetsWindow.Open()
end

-- For the tests: whether it offers to turn them on.
function SetsWindow.Offers() return onBtn ~= nil and onBtn:IsShown() end

return SetsWindow
