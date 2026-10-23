-- The MacroSense window: macro list on the left, editor on the right. Macros are the game's own
-- (CreateMacro / EditMacro), so everything stays in sync with the Blizzard macro UI.
local _, ns = ...

local MAX_GENERAL = MAX_ACCOUNT_MACROS or 120
local MAX_CHARACTER = MAX_CHARACTER_MACROS or 18
local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local NEW_ICON = 134400 -- question mark: #showtooltip picks the icon
local ROW_H = 24
local MIN_W, MIN_H = 780, 460 -- also the first size
local PREVIEW_EVERY = 0.1 -- seconds: modifiers, target, mouseover and pet change any time

local Window = {}
ns.Window = Window

-- What is being edited: scope "general" | "character", index (nil = new macro), name/body/savedIcon as saved,
-- icon = the icon picked now.
local state = { scope = "general", icon = NEW_ICON, savedIcon = NEW_ICON }
local frame, list, nameBox, iconTex, code, status, dirtyDot, warning, counter, saveBtn, revertBtn, deleteBtn, tabs
local shortenBtn, historyBtn

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
-- Shorten: the same macro in fewer characters
------------------------------------------------------------------------
local shortened -- { raw, text }: the last text shortened and what it became

local function Shortened(raw)
    if not shortened or shortened.raw ~= raw then
        -- Lines with syntax errors stay as they are.
        local skip = {}
        for _, e in ipairs(ns.Highlight.Errors(raw)) do
            if e.severity == "error" then skip[e.line] = true end
        end
        shortened = { raw = raw, text = ns.Shorten.Text(raw, { conditional = ns.IsConditionalCommand, skip = skip }) }
    end
    return shortened.text
end

-- The button says how many characters it saves.
local function UpdateShorten(raw)
    local saved = Letters(raw) - Letters(Shortened(raw))
    shortenBtn:SetEnabled(saved > 0)
    shortenBtn.label:SetText(saved > 0 and string.format("Shorten -%d", saved) or "Shorten")
end

-- Undo brings the old text back.
function Window.Shorten()
    local raw = code:GetRaw()
    local text = Shortened(raw)
    if text == raw then return end
    code:SetRaw(text, #text, true)
    code:SetFocus()
    code:CheckNow()
end

------------------------------------------------------------------------
-- History: earlier saved texts of the macro
------------------------------------------------------------------------
local function Versions()
    if not state.index then return {} end
    return ns.History.Versions(ns.History.Store(state.scope), state.name, state.body)
end

-- "Today, 14:32", "Yesterday, 09:10", "Oct 21, 18:05", "Oct 21, 2025".
local function When(t)
    local day, clock = date("%Y-%m-%d", t), date("%H:%M", t)
    if day == date("%Y-%m-%d") then return "Today, " .. clock end
    if day == date("%Y-%m-%d", time() - 86400) then return "Yesterday, " .. clock end
    local month = date("%b ", t) .. tonumber(date("%d", t))
    return month .. ", " .. (date("%Y", t) == date("%Y") and clock or date("%Y", t))
end

-- Like Shorten: the text goes into the editor, Save keeps it, undo takes it back.
function Window.Restore(body)
    code:SetRaw(body, #body, true)
    code:SetFocus()
    code:CheckNow()
end

local function HistoryItems()
    local items, dim = {}, ns.scheme.dim
    for _, v in ipairs(Versions()) do
        items[#items + 1] = {
            name = string.format("%s  |cff%s%d chars|r", When(v.time), dim, Letters(v.body)),
            current = v.body == code:GetRaw(),
            onClick = function() Window.Restore(v.body) end,
            onEnter = function(row)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(When(v.time), 1, 1, 1)
                for line in (v.body .. "\n"):gmatch("([^\n]*)\n") do
                    -- "|" would start a color code in the tooltip: shown as typed.
                    GameTooltip:AddLine(line ~= "" and line:gsub("|", "||") or " ", 0.8, 0.8, 0.8, true)
                end
                GameTooltip:Show()
            end,
        }
    end
    return items
end

------------------------------------------------------------------------
-- Status bar
------------------------------------------------------------------------
-- Tooltip lines for issues: errors red, warnings yellow.
local function AddIssueLines(issues)
    for _, e in ipairs(issues) do
        local r, g, b = 1, 0.35, 0.35
        if e.severity == "warning" then r, g, b = 1, 0.82, 0 end
        GameTooltip:AddLine(string.format("Line %d: %s", e.line, e.message), r, g, b)
    end
end

local function UpdateStatus()
    if not warning or not ns.scheme or code.measuring then return end
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
    UpdateShorten(raw)
    historyBtn:SetEnabled(#Versions() > 0)
    saveBtn:SetEnabled(dirty and letters <= MAX_BODY)
    revertBtn:SetEnabled(dirty and state.index ~= nil)
    deleteBtn:SetEnabled(state.index ~= nil)
    -- Mac: [mod:cmd] on a key macOS uses with Cmd (the macro's keys are the saved macro's).
    local message
    if ns.Shortcuts.Enabled() and state.index then
        local keys = ns.Shortcuts.KeysFor(state.index, state.name)
        message = ns.Shortcuts.Message(ns.Shortcuts.Conflicts(raw, keys))
    end
    -- Errors first, then the macOS shortcut (it can quit the game), then other warnings.
    -- Save shows an alert icon for errors (saving is still allowed).
    local issues, errors, warnings = code.errors or {}, {}, {}
    for _, e in ipairs(issues) do
        table.insert(e.severity == "warning" and warnings or errors, e)
    end
    saveBtn.alert:SetShown(#errors > 0)
    -- Short form here: the issue's own short text ("did you mean ...?") or the message without the
    -- quoted name and notes ("unknown unit"); the full list is in the tooltip.
    local function line(e, color, total)
        local short = e.short or e.message:gsub('%s*%b""', ""):gsub("%s*%b()", "")
        local more = total > 1 and string.format(" (+%d more)", total - 1) or ""
        return string.format("|cff%sLine %d: %s%s|r", color, e.line, short, more)
    end
    local total = #issues + (message and 1 or 0)
    local shown -- the issue in the status bar; a click applies its fix
    if #errors > 0 then
        shown = errors[1]
        warning:SetText(line(shown, s.invalid, total))
    elseif message then
        local more = total > 1 and string.format(" (+%d more)", total - 1) or ""
        warning:SetText("|cff" .. s.warning .. message .. more .. "|r")
    elseif #warnings > 0 then
        shown = warnings[1]
        warning:SetText(line(shown, s.warning, total))
    else
        warning:SetText("")
    end
    warning.errors, warning.message, warning.shown = issues, message, shown

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
-- Live preview: next to each line, what it would do right now
------------------------------------------------------------------------
local noteColors -- from the scheme, see ApplyLook

local function UpdatePreview()
    if not frame or not ns.db.preview or not noteColors then return end
    -- Lines with syntax errors get no note: they are underlined, and the game's reading of them is a guess.
    local skip = {}
    for _, e in ipairs(code.errors or {}) do
        if e.severity == "error" then skip[e.line] = true end
    end
    local results = ns.Preview.Evaluate(code:GetRaw(), ns.previewEnv, skip)
    local notes = {}
    for i = 1, results.n do notes[i] = ns.Preview.Note(results[i], noteColors) end
    code:SetLineNotes(notes)
end

------------------------------------------------------------------------
-- Macro list
------------------------------------------------------------------------
local rows = {}

-- Issues of a saved macro: the worst severity ("error", "warning" or nil) and the issues themselves.
local function MacroIssues(body)
    local issues, worst = ns.Highlight.Errors(body or ""), nil
    for _, e in ipairs(issues) do
        worst = "warning"
        if e.severity == "error" then
            worst = "error"
            break
        end
    end
    return worst, issues
end

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
    -- A macro with errors gets the alert sign, as on Save.
    r.alert = r:CreateTexture(nil, "OVERLAY")
    r.alert:SetSize(14, 14)
    r.alert:SetPoint("RIGHT", -6, 0)
    r.alert:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    r.alert:Hide()
    -- Hover: the issues, line by line.
    r:SetScript("OnEnter", function()
        if not r.selected then r.bg:SetAlpha(0.4); r.bg:Show() end
        if not r.severity then return end
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        GameTooltip:AddLine(r.text:GetText(), 1, 1, 1)
        AddIssueLines(r.issues)
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function()
        r.bg:SetShown(r.selected)
        r.bg:SetAlpha(1)
        GameTooltip:Hide()
    end)
    r:SetScript("OnClick", function() Window.Select(r.index) end)
    -- Drag a macro onto an action bar, like in the Blizzard macro window.
    r:RegisterForDrag("LeftButton")
    r:SetScript("OnDragStart", function() Window.Pickup(r.index) end)
    -- The name is red with errors, yellow with warnings only.
    function r:Paint()
        local s = ns.scheme
        if not s then return end
        self.bg:SetColorTexture(ns.RGB(s.selection))
        local color = self.severity == "error" and s.invalid or self.severity == "warning" and s.warning or s.text
        self.text:SetTextColor(ns.RGB(color))
    end
    ns.OnStyle(function() r:Paint() end)
    return r
end

function Window.RefreshList()
    if not frame then return end
    local first, last = MacroRange(state.scope)
    local n = 0
    for index = first, last do
        n = n + 1
        rows[n] = rows[n] or Row(n)
        local r, name, icon, body = rows[n], GetMacroInfo(index)
        r.index, r.selected = index, index == state.index
        r.icon:SetTexture(ns.IconTexture(icon))
        r.text:SetText(name)
        -- Marks follow the saved text: the one being edited shows its issues in the editor.
        r.severity, r.issues = MacroIssues(body)
        local alert = r.severity == "error"
        r.alert:SetShown(alert)
        r.text:SetPoint("RIGHT", alert and r.alert or r, alert and "LEFT" or "RIGHT", alert and -4 or -6, 0)
        r:Paint()
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
    -- A mistake in the word just typed shows now, not only after the typing pause.
    code:CheckNow()
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local name = strtrim(nameBox:GetText())
    local body = code:GetRaw()
    if name == "" then
        nameBox:SetFocus()
        return ns.Print("the macro needs a name")
    end
    if Letters(body) > MAX_BODY then return ns.Print("macro is longer than %d characters", MAX_BODY) end
    local index
    -- Earlier versions follow a new name.
    local renamed = state.index and name ~= state.name
    if renamed then ns.History.Renamed(state.scope, state.name, name) end
    if state.index then
        -- The game keeps macros sorted by name, so the index may change.
        index = EditMacro(state.index, name, state.icon, body)
    else
        index = CreateMacro(name, state.icon or NEW_ICON, body, state.scope == "character")
    end
    if not index or index == 0 then
        if renamed then ns.History.Renamed(state.scope, name, state.name) end
        return ns.Print("could not save the macro")
    end
    -- The text it replaced is kept now, not only when the game reports the change.
    ns.History.Scan()
    state.index, state.name, state.body = index, name, body
    state.icon = select(2, GetMacroInfo(index)) or state.icon
    state.savedIcon = state.icon
    iconTex:SetTexture(ns.IconTexture(state.icon))
    Window.RefreshList()
    UpdateStatus()
end

-- Put a macro on the cursor, to drop on an action bar. A new macro has to be saved first.
function Window.Pickup(index)
    if not index then return ns.Print("save the macro first, then drag it to an action bar") end
    if InCombatLockdown() then return ns.Print("action bars cannot be changed in combat") end
    PickupMacro(index)
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
    local tokens = ns.TokenColors(scheme)
    noteColors = { action = tokens.action, unit = tokens.unit, text = scheme.text, dim = scheme.dim,
        warning = scheme.warning }
    UpdatePreview()
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
    if frame.SetResizeBounds then frame:SetResizeBounds(MIN_W, MIN_H) else frame:SetMinResize(MIN_W, MIN_H) end
    local pos = ns.db.window
    frame:SetSize(math.max(pos and pos.w or 0, MIN_W), math.max(pos and pos.h or 0, MIN_H))
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

    -- Live preview on / off, with the other settings of the view.
    local previewCheck = ns.Check(title, "Live preview", function() return ns.db.preview end, function(on)
        ns.db.preview = on
        code:ShowNotes(on)
        UpdatePreview()
    end)
    previewCheck:SetPoint("RIGHT", fontDrop, "LEFT", -16, 0)
    previewCheck:HookScript("OnEnter", function(self)
        local keys = IsMacClient and IsMacClient() and "Shift, Ctrl, Alt or Cmd" or "Shift, Ctrl or Alt"
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine("Live preview", 1, 1, 1)
        GameTooltip:AddLine("Next to each line: what it would do if you pressed the macro now.", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("Hold " .. keys .. ", change your target or point at a unit to see the other branches.",
            0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    previewCheck:HookScript("OnLeave", function() GameTooltip:Hide() end)

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
    iconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Click: choose an icon", 1, 1, 1)
        GameTooltip:AddLine("Drag: put the macro on an action bar", 1, 1, 1)
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    iconFrame:RegisterForDrag("LeftButton")
    iconFrame:SetScript("OnDragStart", function() Window.Pickup(state.index) end)
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

    -- Shorten at the right end of the header.
    shortenBtn = ns.Button(main, "Shorten", 90, function() Window.Shorten() end)
    shortenBtn:SetPoint("RIGHT", main, "TOPRIGHT", -12, -29)
    shortenBtn:HookScript("OnEnter", function(self)
        local undo = IsMacClient and IsMacClient() and "Cmd+Z" or "Ctrl+Z"
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Shorten", 1, 1, 1)
        GameTooltip:AddLine("The same macro in fewer characters: target= becomes @, modifier becomes mod, "
            .. "[pet:Imp][pet:Felhunter] becomes [pet:Imp/Felhunter], [x] Fear; Fear becomes [x][]Fear, "
            .. "and spaces the game doesn't need go.", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(self:IsEnabled() and (undo .. " brings the old text back.") or "Nothing to shorten here.",
            0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    shortenBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- History, left of Shorten: its menu opens under it, lined up on the right.
    historyBtn = ns.MenuButton(main, "History", 80, HistoryItems, false, true)
    historyBtn:SetPoint("RIGHT", shortenBtn, "LEFT", -8, 0)
    historyBtn:HookScript("OnEnter", function(self)
        local undo = IsMacClient and IsMacClient() and "Cmd+Z" or "Ctrl+Z"
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("History", 1, 1, 1)
        if self:IsEnabled() then
            GameTooltip:AddLine("Earlier saved versions of this macro. Pick one to put it in the editor: Save keeps it, "
                .. undo .. " takes it back.", 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine("When you save a change to this macro, here or in the game's macro window, the text "
                .. "it had before is kept here.", 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    historyBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local nameHint = ns.Text(main, 11, "dim")
    nameHint:SetPoint("LEFT", nameBox, "RIGHT", 10, 0)
    nameHint:SetText("click or drag the icon")
    nameHint:SetPoint("RIGHT", historyBtn, "LEFT", -12, 0)
    nameHint:SetWordWrap(false)

    -- Status bar: position, length, Save / Revert.
    local bar = CreateFrame("Frame", nil, main, "BackdropTemplate")
    bar:SetPoint("BOTTOMLEFT")
    bar:SetPoint("BOTTOMRIGHT")
    bar:SetHeight(36)
    ns.Backdrop(bar, "panel", "panel")
    saveBtn = ns.Button(bar, "Save", 90, Window.Save, true)
    saveBtn.alert = saveBtn:CreateTexture(nil, "OVERLAY")
    saveBtn.alert:SetSize(16, 16)
    saveBtn.alert:SetPoint("RIGHT", saveBtn.label, "LEFT", -4, 0)
    saveBtn.alert:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew") -- triangle with "!"
    saveBtn.alert:Hide()
    saveBtn:HookScript("OnEnter", function(self)
        if not self.alert:IsShown() then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("The macro has syntax errors", 1, 0.3, 0.3)
        GameTooltip:AddLine("It can still be saved.", 1, 1, 1)
        GameTooltip:Show()
    end)
    saveBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    saveBtn:SetPoint("RIGHT", -24, 0) -- room for the resize grip in the corner
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
    -- Errors / warnings use the room between the status and Revert, cut short when too long.
    warning = ns.Text(bar, 11, "text")
    warning:SetPoint("LEFT", status, "RIGHT", 16, 0)
    warning:SetPoint("RIGHT", revertBtn, "LEFT", -12, 0)
    warning:SetJustifyH("RIGHT")
    warning:SetWordWrap(false)
    -- Hover: every error in full, and the macOS warning.
    local warningHover = CreateFrame("Frame", nil, bar)
    warningHover:SetAllPoints(warning)
    warningHover:EnableMouse(true)
    warningHover:SetScript("OnEnter", function(self)
        local errors, message = warning.errors or {}, warning.message
        if #errors == 0 and not message then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        AddIssueLines(errors)
        if message then GameTooltip:AddLine(message, 1, 0.82, 0) end
        if warning.shown and warning.shown.fix then
            GameTooltip:AddLine(string.format('Click to use "%s"', warning.shown.fix), 0.4, 1, 0.4)
        end
        GameTooltip:Show()
    end)
    warningHover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Click: replace the misspelled name with the suggestion.
    warningHover:SetScript("OnMouseUp", function()
        local e = warning.shown
        if not (e and e.fix) then return end
        local raw = code:GetRaw()
        code:SetRaw(raw:sub(1, e.from - 1) .. e.fix .. raw:sub(e.to + 1), e.from - 1 + #e.fix, true)
        code:CheckNow()
        GameTooltip:Hide()
    end)

    -- Editor.
    local editorBg = CreateFrame("Frame", nil, main, "BackdropTemplate")
    editorBg:SetPoint("TOPLEFT", 12, -58)
    editorBg:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -12, 10)
    ns.Backdrop(editorBg, "bg", "border")
    code = ns.CreateCodeBox(editorBg, "MacroSenseCodeScroll")
    code.scroll:SetPoint("TOPLEFT", 4, -4)
    code.scroll:SetPoint("BOTTOMRIGHT", -15, 4)
    ns.AttachAutocomplete(code)
    code:ShowNotes(ns.db.preview)
    -- Issues are found a frame after each change: the status bar and the preview follow them.
    code.onErrors = function()
        UpdateStatus()
        UpdatePreview()
    end
    -- Our own status bar follows text and cursor changes (Autocomplete owns onChange / onCaret).
    code.edit:HookScript("OnTextChanged", UpdateStatus)
    code.edit:HookScript("OnCursorChanged", UpdateStatus)
    code.edit:HookScript("OnKeyDown", function(_, key)
        if key == "S" and (IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())) then Window.Save() end
    end)

    -- Resize grip above the status bar (it used to hide the grip).
    ns.ResizeGrip(frame, SavePosition)

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
        ns.CloseMenu()
    end)
    -- The preview also follows the game: modifiers held, target, mouseover, pet, combat.
    local sincePreview = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        sincePreview = sincePreview + elapsed
        if sincePreview < PREVIEW_EVERY then return end
        sincePreview = 0
        UpdatePreview()
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
