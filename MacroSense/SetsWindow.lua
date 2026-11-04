-- Macro sets, the window: the sets on the left (the class's, the character's, each specialization's), the macros
-- of the one picked on the right, each in the game or behind the scenes, to move or copy to another set. Free
-- slots, "Sort by spells" and turning the sets off at the bottom left. The logic is Sets.lua.
local _, ns = ...
local L = ns.L

local SetsWindow = {}
ns.SetsWindow = SetsWindow

local WIDTH, HEIGHT, PAD, ROW_H = 960, 520, 14, 40
local SIDE_W = 210
local MAX_LISTED = 12 -- moves listed in the question of "Sort by spells"; the rest are counted

local frame, offView, onView, setButtons, title, about, list, empty, message, slotsText, visitText, sortBtn, onCheck
local rowFrames = {}
local picked -- the set shown: "class", "character" or a specialization's key

local function Label(id)
    if id == "class" then return L["Class macros"] end
    if id == "character" then return L["This character's"] end
    for _, spec in ipairs(ns.Sets.Specs()) do
        if spec.key == id then return spec.label end
    end
    return id
end

-- All the sets: { id, label, now }.
local function AllSets()
    local out = { { id = "class", label = L["Class macros"] }, { id = "character", label = L["This character's"] } }
    for _, spec in ipairs(ns.Sets.Specs()) do
        out[#out + 1] = { id = spec.key, label = spec.label, now = spec.now }
    end
    return out
end

local function Tell(text) message:SetText(text or "") end

-- What a move or a change behind the scenes said, for the line under the list; `label`: the set moved to.
local function Said(ok, why, label)
    if ok then return why == "waits" and L["Moved. It waits behind the scenes: there is no free slot."] or "" end
    if why == "room" then return L["No free slot: put another macro behind the scenes first."] end
    if why == "name" and label then return string.format(L["\"%s\" has a macro of this name already."], label) end
    if why == "name" then return L["A macro of this name is in the game already."] end
    if why == "combat" then return L["Macros cannot be changed in combat."] end
    if why == "held" then return L["A specialization has this macro: it comes into the game from there."] end
    return ""
end

local Refresh

-- The macro's state in its set: in the game, behind the scenes, waiting for a slot. In a specialization not
-- chosen, only one that stays behind the scenes: the text over the list says the rest come in with it.
local function State(id, m)
    local parked = ns.Sets.IsParked(id, m)
    if not ns.Sets.InGame(id) then
        return parked and L["Stays behind the scenes"] or ""
    end
    if parked then return L["Behind the scenes"] end
    return GetMacroIndexByName(m.name) > 0 and L["In the game"] or L["Waiting for a free slot"]
end

local function IsSpec(id) return id ~= "class" and id ~= "character" end

-- Where a macro can go: moved to any other set; copied, a specialization's, to another specialization.
local function Items(id, m, copy)
    local items = {}
    for _, set in ipairs(AllSets()) do
        if set.id ~= id and (not copy or IsSpec(set.id)) then
            local text = copy and L["Copy to: %s"] or L["Move to: %s"]
            items[#items + 1] = { name = string.format(text, set.label), onClick = function()
                Tell(Said(ns.Sets.MoveTo(id, m.name, set.id, copy), set.label))
                Refresh()
            end }
        end
    end
    return items
end

local function Tip(owner, head, text)
    owner:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(head, 1, 1, 1)
        GameTooltip:AddLine(text(), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    owner:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Row(i)
    local r = CreateFrame("Frame", nil, list.child)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetPoint("RIGHT")
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(28, 28)
    r.icon:SetPoint("LEFT", 4, 0)
    r.name = ns.Text(r, 13)
    r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, 0)
    r.note = ns.Text(r, 11, "dim")
    r.note:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, 0)
    r.note:SetWordWrap(false)
    r.move = ns.MenuButton(r, L["Move"], 90, function() return Items(picked, r.m) end, false, true)
    r.move:SetPoint("RIGHT", -4, 0)
    Tip(r.move, L["Move"], function()
        return L["The macro leaves this set for the one you pick."]
    end)
    r.copy = ns.MenuButton(r, L["Copy"], 90, function() return Items(picked, r.m, true) end, false, true)
    r.copy:SetPoint("RIGHT", r.move, "LEFT", -6, 0)
    r.release = ns.Button(r, L["Remove"], 90, function()
        Tell(Said(ns.Sets.Release(picked, r.m.name)))
        Refresh()
    end)
    Tip(r.release, L["Remove"], function()
        return L["The macro leaves this set and stays in \"This character's\", the home of all macros: behind the "
            .. "scenes while a specialization still has it, in the game when none does."]
    end)
    Tip(r.copy, L["Copy"], function()
        if picked == "character" then
            return L["A copy goes into a specialization, and this one stays here, behind the scenes while a "
                .. "specialization has it."]
        end
        return L["A copy goes into another specialization, and this one stays here."]
    end)
    r.park = ns.Button(r, "", 110, function()
        local on = not ns.Sets.IsParked(picked, r.m)
        -- The character's one a specialization has: asked, then taken out of them.
        local held = picked == "character" and not on and ns.Sets.HeldIn(r.m.name)
        if held and #held > 0 then
            local labels = {}
            for _, key in ipairs(held) do labels[#labels + 1] = Label(key) end
            return ns.Ask("MACROSENSE_SETS_TAKE_HOME", r.m.name, table.concat(labels, ", "), r.m.name)
        end
        Tell(Said(ns.Sets.Park(picked, r.m.name, on)))
        Refresh()
    end)
    r.park:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local parked = ns.Sets.IsParked(picked, r.m)
        GameTooltip:AddLine(parked and L["Take in"] or L["Put away"], 1, 1, 1)
        local text = parked and L["The macro comes into the game and takes a free slot."]
            or L["The macro leaves the game and frees its slot, but stays here, in its set. Its buttons come "
                .. "back with it."]
        if picked == "character" and parked and #ns.Sets.HeldIn(r.m.name) > 0 then
            text = L["A specialization has this macro: it comes into the game from there. Taken in here, it leaves "
                .. "every specialization."]
        end
        GameTooltip:AddLine(text, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    r.park:HookScript("OnLeave", function() GameTooltip:Hide() end)
    r.state = ns.Text(r, 11, "dim")
    r.state:SetPoint("RIGHT", r.park, "LEFT", -10, 0)
    r.note:SetPoint("RIGHT", r.state, "LEFT", -10, 0)
    -- The macro's text under the mouse.
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(r.m.name, 1, 1, 1)
        for line in (r.m.body or ""):gmatch("[^\n]+") do GameTooltip:AddLine(line, 0.6, 0.9, 1) end
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return r
end

local function ShowRow(r, m)
    r.m = m
    r.icon:SetTexture(m.icon or 134400)
    r.name:SetText(m.name)
    local note, kind = ns.Sets.Note(picked, m)
    r.note:SetText(note or "")
    if kind == "warn" then r.note:SetTextColor(1, 0.4, 0.4) else r.note:SetTextColor(ns.RGB(ns.scheme.dim)) end
    r.state:SetText(State(picked, m))
    r.park.label:SetText(ns.Sets.IsParked(picked, m) and L["Take in"] or L["Put away"])
    -- Copied only between specializations.
    local copies = picked ~= "class" and #Items(picked, m, true) > 0
    r.copy:SetShown(copies)
    -- Back to the character's from any other set.
    r.release:SetShown(picked ~= "character")
    r.release:ClearAllPoints()
    r.release:SetPoint("RIGHT", copies and r.copy or r.move, "LEFT", -6, 0)
    r.park:ClearAllPoints()
    r.park:SetPoint("RIGHT", picked ~= "character" and r.release or copies and r.copy or r.move, "LEFT", -6, 0)
    r:Show()
end

-- What the set shown is.
local function About(id, isNow)
    if id == "class" then
        return L["The same on all your characters of this class: what you change here reaches the others when they "
            .. "log in."]
    end
    if id == "character" then return L["In the game in every specialization of this character."] end
    if isNow then
        return L["In the game while this specialization is chosen. Choose another, and they go behind the scenes, "
            .. "and that one's come in."]
    end
    return L["They come into the game when you choose this specialization, onto their buttons."]
end

function Refresh()
    if not frame or not frame:IsShown() then return end
    local sets = ns.Sets.Mine()
    offView:SetShown(not sets.enabled)
    onView:SetShown(sets.enabled)
    if not sets.enabled then return end
    onCheck:Refresh() -- turned on from the other view
    local all = AllSets()
    local found = false
    for _, set in ipairs(all) do found = found or set.id == picked end
    if not found then picked = sets.active or "character" end
    -- The sets on the left: the one shown lit, the specialization now marked.
    for i, set in ipairs(all) do
        local b = setButtons[i]
        if not b then
            b = ns.Button(onView, "", SIDE_W, nil)
            b:SetPoint("TOPLEFT", PAD, -34 - PAD - (i - 1) * 28)
            setButtons[i] = b
        end
        b:SetScript("OnClick", function()
            if picked ~= set.id then list:SetVerticalScroll(0) end
            picked = set.id
            Tell("")
            Refresh()
        end)
        b.label:SetText(set.now and string.format(L["%s (now)"], set.label) or set.label)
        b:SetAccent(set.id == picked)
        b:Show()
    end
    for i = #all + 1, #setButtons do setButtons[i]:Hide() end
    slotsText:ClearAllPoints()
    slotsText:SetPoint("TOPLEFT", PAD, -34 - PAD - #all * 28 - 10)
    slotsText:SetText(string.format(L["Free slots: %d of %d"], ns.Sets.Room(), ns.MAX_CHARACTER))
    local unvisited = ns.Sets.Unvisited()
    sortBtn:SetEnabled(#unvisited == 0)
    visitText:SetText(#unvisited > 0 and string.format(L["MacroSense learns the spells of each specialization "
        .. "while you play it. Not yet: %s."], table.concat(unvisited, ", ")) or "")
    -- The set shown.
    title:SetText(Label(picked))
    about:SetText(About(picked, picked == sets.active))
    local macros = ns.Sets.List(picked)
    for i, m in ipairs(macros) do
        rowFrames[i] = rowFrames[i] or Row(i)
        ShowRow(rowFrames[i], m)
    end
    for i = #macros + 1, #rowFrames do rowFrames[i]:Hide() end
    list.child:SetHeight(math.max(1, #macros * ROW_H))
    -- Fewer rows than before: not scrolled past the last.
    local bottom = math.max(0, #macros * ROW_H - list:GetHeight())
    if list:GetVerticalScroll() > bottom then list:SetVerticalScroll(bottom) end
    empty:SetShown(#macros == 0)
end
SetsWindow.Refresh = Refresh

StaticPopupDialogs.MACROSENSE_SETS_SORT = {
    text = "Move these macros to where their spells are?\n\n%s",
    button1 = "Move", button2 = "Cancel",
    OnAccept = function(_, moves)
        local done = ns.Sets.ApplySort(moves)
        Tell(string.format(L["Moved: %d."], done))
        Refresh()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs.MACROSENSE_SETS_TAKE_HOME = {
    text = "\"%s\" is in these specializations: %s.\n\nTake it into the game here? It leaves them, and is in the "
        .. "game in every specialization.",
    button1 = "Take in", button2 = "Cancel",
    OnAccept = function(_, name)
        Tell(Said(ns.Sets.TakeHome(name)))
        Refresh()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

function SetsWindow.Sort()
    local moves = ns.Sets.SortPlan()
    if #moves == 0 then return Tell(L["Nothing to move: each macro is where its spells are."]) end
    local lines = {}
    for i, move in ipairs(moves) do
        if i > MAX_LISTED then
            lines[#lines + 1] = string.format(L["and %d more"], #moves - MAX_LISTED)
            break
        end
        lines[#lines + 1] = string.format("%s: %s > %s", move.name, Label(move.from), Label(move.to))
    end
    ns.Ask("MACROSENSE_SETS_SORT", table.concat(lines, "\n"), nil, moves)
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseSets", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseSets") -- Esc closes it
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 40)
    ns.Backdrop(frame, "bg", "border", true)
    frame:Hide()
    frame:SetScript("OnShow", function() Refresh() end)

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

    -- Sets off: what they are, and turning them on.
    offView = CreateFrame("Frame", nil, frame)
    offView:SetAllPoints()
    local intro = ns.Text(offView, 13)
    intro:SetPoint("TOPLEFT", PAD * 2, -34 - PAD * 2)
    intro:SetPoint("RIGHT", -PAD * 2, 0)
    intro:SetSpacing(4)
    intro:SetText(L["A character has only 30 macro slots. Macro sets make room: each specialization gets macros "
        .. "of its own. Choose a specialization, and its macros come into the game, onto their buttons, while the "
        .. "others' wait behind the scenes.\n\nClass macros are the same on all your characters of one class: "
        .. "change one, and the others get it too. This character's macros stay in every specialization.\n\nOnce "
        .. "turned on, all your character macros go into \"This character's\". Move them to a specialization or to "
        .. "the class here, or let \"Sort by spells\" do it. A backup of your macros is made first."])
    local on = ns.Button(offView, L["Turn on macro sets"], 200, function()
        ns.Sets.Enable()
        Refresh()
    end, true)
    on:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -20)

    -- Sets on.
    onView = CreateFrame("Frame", nil, frame)
    onView:SetAllPoints()
    setButtons = {}
    slotsText = ns.Text(onView, 12)
    visitText = ns.Text(onView, 11, "dim")
    visitText:SetPoint("TOPLEFT", slotsText, "BOTTOMLEFT", 0, -8)
    visitText:SetWidth(SIDE_W)
    sortBtn = ns.Button(onView, L["Sort by spells"], SIDE_W, function() SetsWindow.Sort() end)
    sortBtn:SetPoint("BOTTOMLEFT", PAD, PAD + 30)
    Tip(sortBtn, L["Sort by spells"], function()
        return L["MacroSense looks at the spells each macro casts, and offers to move it: one that works in one "
            .. "specialization only, into that one's set; a specialization's that works in all, to this "
            .. "character's. You see the moves before they are made."]
            .. (sortBtn:IsEnabled() and "" or "\n\n" .. L["It can sort once it knows the spells of every "
                .. "specialization: choose each of them at least once."])
    end)
    local off = ns.Check(onView, L["Macro sets on"], function() return ns.Sets.Mine().enabled end, function(v)
        if not v then ns.Sets.Disable() end
        Refresh()
    end)
    off:SetPoint("BOTTOMLEFT", PAD, PAD)
    onCheck = off
    Tip(off, L["Macro sets on"], function()
        return L["Turned off, the macros in the game stay as they are, and the sets are kept for later."]
    end)

    local right = CreateFrame("Frame", nil, onView)
    right:SetPoint("TOPLEFT", PAD + SIDE_W + 20, -34 - PAD)
    right:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    title = ns.Text(right, 15)
    title:SetPoint("TOPLEFT", 0, 0)
    about = ns.Text(right, 11, "dim")
    about:SetPoint("TOPLEFT", 0, -22)
    about:SetPoint("RIGHT")
    list = CreateFrame("ScrollFrame", nil, right)
    list:SetPoint("TOPLEFT", 0, -58)
    list:SetPoint("BOTTOMRIGHT", -13, 24)
    ns.AttachScrollBar(list, ROW_H * 3)
    list.child = CreateFrame("Frame", nil, list)
    list.child:SetSize(WIDTH - SIDE_W - PAD * 2 - 40, 1)
    list:SetScrollChild(list.child)
    empty = ns.Text(right, 12, "dim")
    empty:SetPoint("TOPLEFT", 4, -66)
    empty:SetPoint("RIGHT")
    empty:SetText(L["No macros here yet. Move some here from another set: \"Move\" in its row."])
    message = ns.Text(right, 12)
    message:SetPoint("BOTTOMLEFT", 0, 0)
    message:SetPoint("RIGHT")
    message:SetTextColor(1, 0.4, 0.4)
end

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

-- For the tests: the set shown, picking one, the row frames, the message.
function SetsWindow.Picked() return picked end
function SetsWindow.Pick(id)
    if picked ~= id and list then list:SetVerticalScroll(0) end
    picked = id
    Refresh()
end
function SetsWindow.RowFrame(i) return rowFrames[i] end
function SetsWindow.Message() return message and message:GetText() end
function SetsWindow.OnCheck() return onCheck end
function SetsWindow.Showing() return offView:IsShown() and "off" or onView:IsShown() and "on" or nil end

return SetsWindow
