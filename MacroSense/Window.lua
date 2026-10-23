-- The MacroSense window: macro list on the left, editor on the right. Macros are the game's own
-- (CreateMacro / EditMacro), so everything stays in sync with the Blizzard macro UI.
local _, ns = ...

local MAX_GENERAL = MAX_ACCOUNT_MACROS or 120
local MAX_CHARACTER = MAX_CHARACTER_MACROS or 18
local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local NEW_ICON = 134400 -- question mark: #showtooltip picks the icon
local ROW_H = 24

local Window = {}
ns.Window = Window

-- What is being edited: scope "general" | "character", index (nil = new macro), name/body/savedIcon as saved,
-- icon = the icon picked now.
local state = { scope = "general", icon = NEW_ICON, savedIcon = NEW_ICON }
local frame, list, nameBox, iconTex, code, status, dirtyDot, warning, counter, saveBtn, revertBtn, deleteBtn, tabs

local function MacroRange(scope)
    local general, character = GetNumMacros()
    if scope == "general" then return 1, general, MAX_GENERAL end
    return MAX_GENERAL + 1, MAX_GENERAL + character, MAX_CHARACTER
end

local function Letters(s)
    return select(2, s:gsub("[^\128-\191]", ""))
end

local function IsDirty()
    if not frame then return false end
    local body, name = code:GetRaw(), nameBox:GetText()
    if not state.index then return body ~= "" or name ~= "" or state.icon ~= NEW_ICON end
    return body ~= state.body or name ~= state.name or state.icon ~= state.savedIcon
end

------------------------------------------------------------------------
-- Status bar
------------------------------------------------------------------------
local function UpdateStatus()
    if not warning or not ns.scheme then return end
    local raw = code:GetRaw()
    local cursor = code.edit:HasFocus() and code:GetRawCursor() or 0
    local before = raw:sub(1, cursor)
    local line = select(2, before:gsub("\n", "")) + 1
    local col = Letters(before:match("[^\n]*$")) + 1
    local letters = Letters(raw)
    local s = ns.scheme
    local countColor = letters > MAX_BODY and s.invalid or s.dim
    counter:SetText(string.format("Ln %d, Col %d    |cff%s%d / %d|r", line, col, countColor, letters, MAX_BODY))
    local dirty = IsDirty()
    saveBtn:SetEnabled(dirty and letters <= MAX_BODY)
    revertBtn:SetEnabled(dirty and state.index ~= nil)
    deleteBtn:SetEnabled(state.index ~= nil)
    -- Mac: [mod:cmd] on a key macOS uses with Cmd (the macro's keys are the saved macro's).
    local message
    if ns.Shortcuts.Enabled() and state.index then
        local keys = ns.Shortcuts.KeysFor(state.index, state.name)
        message = ns.Shortcuts.Message(ns.Shortcuts.Conflicts(raw, keys))
    end
    warning:SetText(message and ("|cff" .. s.warning .. message .. "|r") or "")

    -- The dot is a texture: not every font has a "●" glyph.
    dirtyDot:SetShown(dirty and letters <= MAX_BODY)
    dirtyDot:SetVertexColor(ns.RGB(s.accent))
    if letters > MAX_BODY then
        status:SetText("|cff" .. s.invalid .. "Macro is longer than " .. MAX_BODY .. " characters|r")
    elseif dirty then
        status:SetText("Unsaved changes")
    else
        status:SetText("")
    end
end

------------------------------------------------------------------------
-- Macro list
------------------------------------------------------------------------
local rows = {}

local function Row(i)
    local r = CreateFrame("Button", nil, list.child)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(ROW_H - 4, ROW_H - 4)
    r.icon:SetPoint("LEFT", 6, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.text = ns.Text(r, 12)
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
    r.text:SetPoint("RIGHT", -6, 0)
    r.text:SetWordWrap(false)
    r:SetScript("OnEnter", function() if not r.selected then r.bg:SetAlpha(0.4); r.bg:Show() end end)
    r:SetScript("OnLeave", function() r.bg:SetShown(r.selected); r.bg:SetAlpha(1) end)
    r:SetScript("OnClick", function() Window.Select(r.index) end)
    ns.OnStyle(function(s) r.bg:SetColorTexture(ns.RGB(s.selection)) end)
    return r
end

function Window.RefreshList()
    if not frame then return end
    local first, last = MacroRange(state.scope)
    local n = 0
    for index = first, last do
        n = n + 1
        rows[n] = rows[n] or Row(n)
        local r, name, icon = rows[n], GetMacroInfo(index)
        r.index, r.selected = index, index == state.index
        r.icon:SetTexture(ns.IconTexture(icon))
        r.text:SetText(name)
        r.bg:SetShown(r.selected)
        r.bg:SetAlpha(1)
        r:Show()
    end
    for i = n + 1, #rows do rows[i]:Hide() end
    list.child:SetHeight(math.max(n * ROW_H, 1))

    local general, character = GetNumMacros()
    tabs.general.label:SetText(string.format("General  %d/%d", general, MAX_GENERAL))
    tabs.character.label:SetText(string.format("Character  %d/%d", character, MAX_CHARACTER))
    for scope, tab in pairs(tabs) do tab.active = scope == state.scope; tab:Paint() end
end

------------------------------------------------------------------------
-- Editing
------------------------------------------------------------------------
local function Load(index)
    if index then
        local name, icon, body = GetMacroInfo(index)
        state.index, state.name, state.icon, state.body = index, name, icon, body or ""
    else
        state.index, state.name, state.icon, state.body = nil, "", NEW_ICON, ""
    end
    state.savedIcon = state.icon
    nameBox:SetText(state.name)
    iconTex:SetTexture(ns.IconTexture(state.icon))
    ns.IconPicker.SetCurrent(state.icon)
    code:SetRaw(state.body, 0)
    Window.RefreshList()
    UpdateStatus()
end

-- Ask before throwing away unsaved changes.
StaticPopupDialogs.MACROSENSE_DISCARD = {
    text = "Discard unsaved changes to this macro?",
    button1 = YES, button2 = NO,
    OnAccept = function(_, fn) fn() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs.MACROSENSE_DELETE = {
    text = "Delete macro \"%s\"?",
    button1 = DELETE or "Delete", button2 = CANCEL,
    OnAccept = function(_, index) Window.Delete(index) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function Guard(fn)
    if IsDirty() then
        StaticPopup_Show("MACROSENSE_DISCARD", nil, nil, fn)
    else
        fn()
    end
end

function Window.Select(index)
    if index == state.index then return end
    Guard(function() Load(index) end)
end

function Window.SetScope(scope)
    if scope == state.scope then return end
    Guard(function()
        state.scope = scope
        ns.db.scope = scope
        local first, last = MacroRange(scope)
        Load(last >= first and first or nil)
    end)
end

function Window.New()
    Guard(function()
        local first, last, max = MacroRange(state.scope)
        if last - first + 1 >= max then
            return ns.Print("no free %s macro slots", state.scope)
        end
        Load(nil)
        nameBox:SetFocus()
    end)
end

function Window.Save()
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local name = strtrim(nameBox:GetText())
    local body = code:GetRaw()
    if name == "" then
        nameBox:SetFocus()
        return ns.Print("the macro needs a name")
    end
    if Letters(body) > MAX_BODY then return ns.Print("macro is longer than %d characters", MAX_BODY) end
    local index
    if state.index then
        -- The game keeps macros sorted by name, so the index may change.
        index = EditMacro(state.index, name, state.icon, body)
    else
        index = CreateMacro(name, state.icon or NEW_ICON, body, state.scope == "character")
    end
    if not index or index == 0 then return ns.Print("could not save the macro") end
    state.index, state.name, state.body = index, name, body
    state.icon = select(2, GetMacroInfo(index)) or state.icon
    state.savedIcon = state.icon
    iconTex:SetTexture(ns.IconTexture(state.icon))
    Window.RefreshList()
    UpdateStatus()
end

-- Bindings or action bars changed.
function Window.RefreshStatus()
    if frame and frame:IsShown() then UpdateStatus() end
end

function Window.Revert()
    if state.index then Load(state.index) end
end

function Window.Delete(index)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    DeleteMacro(index)
    local first, last = MacroRange(state.scope)
    Load(last >= first and math.min(index, last) or nil)
end

-- The macro list changed elsewhere (Blizzard UI, another addon): keep our selection by name.
function Window.OnMacrosChanged()
    if not frame or not frame:IsShown() then return end
    if state.index then
        local name = GetMacroInfo(state.index)
        if name ~= state.name then
            local index = GetMacroIndexByName(state.name)
            state.index = index and index > 0 and index or nil
        end
    end
    Window.RefreshList()
    UpdateStatus()
end

------------------------------------------------------------------------
-- Look: font, size, scheme
------------------------------------------------------------------------
local function FontList()
    local out = {}
    for _, f in ipairs(ns.fonts) do out[#out + 1] = { key = f.key, name = f.name, path = f.path } end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        for _, name in ipairs(LSM:List("font")) do
            out[#out + 1] = { key = "lsm:" .. name, name = name, path = LSM:Fetch("font", name) }
        end
    end
    return out
end

function Window.ApplyLook()
    local scheme = ns.FindByKey(ns.schemes, ns.db.scheme) or ns.FindByKey(ns.schemes, ns.DEFAULT_SCHEME)
    local font = ns.FindByKey(FontList(), ns.db.font)
    if not font or not code:SetFont(font.path, ns.db.fontSize) then
        font = ns.FindByKey(ns.fonts, ns.DEFAULT_FONT)
        ns.db.font = font.key
        code:SetFont(font.path, ns.db.fontSize)
    end
    ns.ApplyScheme(scheme)
    code:SetScheme(scheme)
    ns.Popup:Style(scheme, font.path, ns.db.fontSize)
    if frame:IsShown() then UpdateStatus() end
end

------------------------------------------------------------------------
-- Build
------------------------------------------------------------------------
local function Tab(parent, scope)
    local t = CreateFrame("Button", nil, parent)
    t:SetHeight(26)
    t.label = ns.Text(t, 12)
    t.label:SetPoint("CENTER")
    t.line = t:CreateTexture(nil, "OVERLAY")
    t.line:SetHeight(2)
    t.line:SetPoint("BOTTOMLEFT")
    t.line:SetPoint("BOTTOMRIGHT")
    function t:Paint()
        local s = ns.scheme
        if not s then return end
        self.line:SetColorTexture(ns.RGB(s.accent))
        self.line:SetShown(self.active)
        self.label:SetTextColor(ns.RGB(self.active and s.text or s.dim))
    end
    t:SetScript("OnClick", function() Window.SetScope(scope) end)
    ns.OnStyle(function() t:Paint() end)
    return t
end

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    ns.db.window = { point = point, relPoint = relPoint, x = x, y = y, w = frame:GetWidth(), h = frame:GetHeight() }
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseFrame", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseFrame") -- Esc closes it
    frame:SetFrameStrata("HIGH") -- below StaticPopup dialogs
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(660, 320) else frame:SetMinResize(660, 320) end
    local pos = ns.db.window
    frame:SetSize(pos and pos.w or 780, pos and pos.h or 460)
    frame:SetPoint(pos and pos.point or "CENTER", UIParent, pos and pos.relPoint or "CENTER", pos and pos.x or 0, pos and pos.y or 40)
    frame:EnableMouse(true)
    ns.Backdrop(frame, "bg", "border")
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
    title:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); SavePosition() end)
    local titleText = ns.Text(title, 14)
    titleText:SetPoint("LEFT", 12, 0)
    titleText:SetText("MacroSense")

    local close = ns.Button(title, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    local schemeItems = {}
    for _, s in ipairs(ns.schemes) do schemeItems[#schemeItems + 1] = { key = s.key, name = s.name } end
    local schemeDrop = ns.Dropdown(title, 190, function() return schemeItems end,
        function() return ns.db.scheme end,
        function(key) ns.db.scheme = key; Window.ApplyLook() end)
    schemeDrop:SetPoint("RIGHT", close, "LEFT", -10, 0)

    local size = ns.Stepper(title, 8, 28, function() return ns.db.fontSize end,
        function(v) ns.db.fontSize = v; Window.ApplyLook() end)
    size:SetPoint("RIGHT", schemeDrop, "LEFT", -10, 0)

    local fontDrop = ns.Dropdown(title, 160, FontList, function() return ns.db.font end,
        function(key) ns.db.font = key; Window.ApplyLook() end)
    fontDrop:SetPoint("RIGHT", size, "LEFT", -10, 0)

    -- Sidebar: tabs, list, New / Delete.
    local side = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    side:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
    side:SetPoint("BOTTOMLEFT", 1, 1)
    side:SetWidth(220)
    ns.Backdrop(side, "panel", "panel")

    tabs = { general = Tab(side, "general"), character = Tab(side, "character") }
    tabs.general:SetPoint("TOPLEFT", 0, 0)
    tabs.general:SetPoint("TOPRIGHT", side, "TOP", 0, 0)
    tabs.character:SetPoint("TOPLEFT", side, "TOP", 0, 0)
    tabs.character:SetPoint("TOPRIGHT", 0, 0)

    local newBtn = ns.Button(side, "New", 100, Window.New)
    newBtn:SetPoint("BOTTOMLEFT", 8, 8)
    deleteBtn = ns.Button(side, "Delete", 100, function()
        StaticPopup_Show("MACROSENSE_DELETE", state.name, nil, state.index)
    end)
    deleteBtn:SetPoint("BOTTOMRIGHT", -8, 8)

    list = CreateFrame("ScrollFrame", "MacroSenseListScroll", side)
    list:SetPoint("TOPLEFT", 0, -30)
    list:SetPoint("BOTTOMRIGHT", -13, 38)
    ns.AttachScrollBar(list, ROW_H * 3)
    list.child = CreateFrame("Frame", nil, list)
    list.child:SetSize(196, 1)
    list:SetScrollChild(list.child)
    list:SetScript("OnSizeChanged", function(_, w) list.child:SetWidth(w) end)

    -- Header: icon + name.
    local main = CreateFrame("Frame", nil, frame)
    main:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, 0)
    main:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Click the icon to pick another one.
    local iconFrame = CreateFrame("Button", "MacroSenseIconButton", main, "BackdropTemplate")
    iconFrame:SetSize(38, 38)
    iconFrame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    iconFrame:SetScript("OnClick", function()
        if ns.IconPicker.IsShown() then return ns.IconPicker.Close() end
        ns.IconPicker.Open(frame, state.icon, function(icon)
            state.icon = icon
            iconTex:SetTexture(ns.IconTexture(icon))
            UpdateStatus()
        end)
    end)
    iconFrame:SetPoint("TOPLEFT", 12, -10)
    ns.Backdrop(iconFrame, "bg", "border")
    iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", 1, -1)
    iconTex:SetPoint("BOTTOMRIGHT", -1, 1)
    iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    nameBox = ns.Input(main, 220, 16)
    nameBox:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
    nameBox:SetScript("OnTextChanged", function() UpdateStatus() end)
    local nameHint = ns.Text(main, 11, "dim")
    nameHint:SetPoint("LEFT", nameBox, "RIGHT", 10, 0)
    nameHint:SetText("click the icon to change it")

    -- Status bar: position, length, Save / Revert.
    local bar = CreateFrame("Frame", nil, main, "BackdropTemplate")
    bar:SetPoint("BOTTOMLEFT")
    bar:SetPoint("BOTTOMRIGHT")
    bar:SetHeight(36)
    ns.Backdrop(bar, "panel", "panel")
    saveBtn = ns.Button(bar, "Save", 90, Window.Save, true)
    saveBtn:SetPoint("RIGHT", -8, 0)
    revertBtn = ns.Button(bar, "Revert", 90, Window.Revert)
    revertBtn:SetPoint("RIGHT", saveBtn, "LEFT", -6, 0)
    counter = ns.Text(bar, 11, "dim")
    counter:SetPoint("LEFT", 12, 0)
    dirtyDot = bar:CreateTexture(nil, "OVERLAY")
    dirtyDot:SetSize(8, 8)
    dirtyDot:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask") -- white circle
    dirtyDot:SetPoint("LEFT", counter, "RIGHT", 24, 0)
    status = ns.Text(bar, 11, "text")
    status:SetPoint("LEFT", dirtyDot, "RIGHT", 6, 0)
    warning = ns.Text(bar, 11, "text")
    warning:SetPoint("RIGHT", revertBtn, "LEFT", -12, 0)
    warning:SetJustifyH("RIGHT")

    -- Editor.
    local editorBg = CreateFrame("Frame", nil, main, "BackdropTemplate")
    editorBg:SetPoint("TOPLEFT", 12, -58)
    editorBg:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -12, 10)
    ns.Backdrop(editorBg, "bg", "border")
    code = ns.CreateCodeBox(editorBg, "MacroSenseCodeScroll")
    code.scroll:SetPoint("TOPLEFT", 4, -4)
    code.scroll:SetPoint("BOTTOMRIGHT", -15, 4)
    ns.AttachAutocomplete(code)
    -- Our own status bar follows text and cursor changes (Autocomplete owns onChange / onCaret).
    code.edit:HookScript("OnTextChanged", UpdateStatus)
    code.edit:HookScript("OnCursorChanged", UpdateStatus)
    code.edit:HookScript("OnKeyDown", function(_, key)
        if key == "S" and (IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())) then Window.Save() end
    end)

    -- Resize grip.
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); SavePosition() end)

    frame:SetScript("OnShow", function()
        fontDrop:Refresh()
        size:Refresh()
        schemeDrop:Refresh()
        Window.RefreshList()
        UpdateStatus()
    end)
    frame:SetScript("OnHide", function()
        ns.Popup:Hide()
        ns.IconPicker.Close()
    end)

    Window.ApplyLook()
end

function Window.Toggle()
    if not frame then Build() end
    if frame:IsShown() then return frame:Hide() end
    state.scope = ns.db.scope or "general"
    frame:Show()
    if IsDirty() then return end
    -- Reload: the macro may have changed in the Blizzard UI while we were closed.
    local index = state.name and state.name ~= "" and GetMacroIndexByName(state.name)
    if index and index > 0 then return Load(index) end
    local first, last = MacroRange(state.scope)
    Load(last >= first and first or nil)
end
