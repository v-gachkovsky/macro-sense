-- Flat, theme-aware widgets for the editor window. Every widget restyles itself when the scheme changes.
local _, ns = ...

local L = ns.L
local WHITE = "Interface\\Buttons\\WHITE8x8"
local UI_FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" -- localized: covers the client's alphabet
-- Clients whose own font has letters beyond Latin. The others write Ukrainian with the game's Friz Quadrata with
-- Cyrillic letters: the game's own fonts use that file for Russian on every client.
local OWN_LETTERS = { ruRU = true, koKR = true, zhCN = true, zhTW = true }

-- The font of the interface's texts in the chosen language.
function ns.UIFont()
    if ns.language == "uk" and not OWN_LETTERS[GetLocale()] then return "Fonts\\FRIZQT___CYR.TTF" end
    return UI_FONT
end

local stylers = {}

-- fn(scheme) runs now (if a scheme is active) and on every scheme change.
function ns.OnStyle(fn)
    stylers[#stylers + 1] = fn
    if ns.scheme then fn(ns.scheme) end
end

function ns.ApplyScheme(scheme)
    ns.scheme = scheme
    for _, fn in ipairs(stylers) do fn(scheme) end
end

-- StaticPopup_Show in the chosen language, or in `language`: a dialog's text and buttons are written in English
-- and translated when it is shown.
function ns.Ask(which, arg1, arg2, data, language)
    local d = StaticPopupDialogs[which]
    local function T(text) return text and (language and ns.Translate(language, text) or L[text]) end
    d.english = d.english or { d.text, d.button1, d.button2 }
    d.text, d.button1, d.button2 = T(d.english[1]), T(d.english[2]), T(d.english[3])
    return StaticPopup_Show(which, arg1, arg2, data)
end

-- `frame` must be created with "BackdropTemplate".
-- The game's own look (a scheme with `native`): a window gets the game's dialog background and border, the border
-- in a layer of its own over the window's parts, which are laid out for a 1 px line; the panels inside a window let
-- the background show through (not the menus, which stand over the world).
local FLAT = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }
local NATIVE_BG = { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", tile = true, tileSize = 32 }
local NATIVE_EDGE = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16 }
local PANEL_ALPHA = 0.6

-- The game's art for widgets in its look, in three pieces of one texture as its own templates draw them: a left and
-- a right end `edge` px wide that keep their shape, and a middle that stretches. x0..x3: where the pieces meet in
-- the texture, y0..y1: its rows.
local ART = {
    button = { file = "Interface\\Buttons\\UI-Panel-Button-Up", edge = 12,
        x = { 0, 0.09375, 0.53125, 0.625 }, y = { 0, 0.6875 } },
    field = { file = "Interface\\Common\\Common-Input-Border", edge = 8, x = { 0, 0.0625, 0.9375, 1 }, y = { 0, 0.625 } },
}
local BUTTON_DISABLED = "Interface\\Buttons\\UI-Panel-Button-Disabled"
local BUTTON_LIT = "Interface\\Buttons\\UI-Panel-Button-Highlight"
local GOLD = "ffd100" -- the game's labels (GameFontNormal)

-- The three pieces of `art` on `frame`, in `layer` (HIGHLIGHT: shown under the mouse only); hidden at first.
local function Slices(frame, art, layer, blend)
    local pieces = {}
    for i = 1, 3 do
        local t = frame:CreateTexture(nil, layer or "BACKGROUND")
        t:SetTexture(art.file)
        t:SetTexCoord(art.x[i], art.x[i + 1], art.y[1], art.y[2])
        if blend then t:SetBlendMode(blend) end
        t:Hide()
        pieces[i] = t
    end
    local l, m, r = pieces[1], pieces[2], pieces[3]
    l:SetPoint("TOPLEFT")
    l:SetPoint("BOTTOMLEFT")
    l:SetWidth(art.edge)
    r:SetPoint("TOPRIGHT")
    r:SetPoint("BOTTOMRIGHT")
    r:SetWidth(art.edge)
    m:SetPoint("TOPLEFT", l, "TOPRIGHT")
    m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
    local s = {}
    function s:SetShown(on) for _, t in ipairs(pieces) do t:SetShown(on) end end
    function s:SetFile(file) for _, t in ipairs(pieces) do t:SetTexture(file) end end
    function s:IsShown() return l:IsShown() end
    return s
end

-- `window`: a window of its own, which gets the game's background and border in the game's look.
function ns.Backdrop(frame, bgKey, borderKey, window)
    frame:SetBackdrop(FLAT)
    ns.OnStyle(function(s)
        local native = s.native and window
        frame:SetBackdrop(native and NATIVE_BG or FLAT)
        if native then
            if not frame.nativeEdge then
                frame.nativeEdge = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                frame.nativeEdge:SetAllPoints()
                frame.nativeEdge:SetFrameLevel(frame:GetFrameLevel() + 30)
                frame.nativeEdge:SetBackdrop(NATIVE_EDGE)
            end
            frame.nativeEdge:Show()
            frame:SetBackdropColor(1, 1, 1, 1)
            return
        end
        if frame.nativeEdge then frame.nativeEdge:Hide() end
        local r, g, b = ns.RGB(s[bgKey or "panel"])
        local inside = frame:GetParent() ~= UIParent
        frame:SetBackdropColor(r, g, b, s.native and bgKey == "panel" and inside and PANEL_ALPHA or 1)
        frame:SetBackdropBorderColor(ns.RGB(s[borderKey or "border"]))
    end)
end

function ns.Text(parent, size, colorKey)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ns.UIFont(), size or 12, "")
    fs:SetJustifyH("LEFT")
    ns.OnStyle(function(s) fs:SetTextColor(ns.RGB(s[colorKey or "text"])) end)
    return fs
end

-- Flat button. `accent` = filled with the accent color (primary action); b:SetAccent(on) changes it (the one
-- chosen of a few).
-- In the game's look it is the game's red button with gold letters (white for the primary or chosen one); with
-- b.field (a dropdown) the game's input frame instead.
function ns.Button(parent, label, width, onClick, accent)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width or 80, 22)
    b:SetBackdrop(FLAT)
    b.label = ns.Text(b, 12)
    b.label:SetPoint("CENTER")
    b.label:SetText(label)
    local art, lit, field
    local function paint(hover)
        local s = ns.scheme
        if not s then return end
        if s.native then
            if not art then
                art, lit, field = Slices(b, ART.button), Slices(b, ART.button, "HIGHLIGHT", "ADD"), Slices(b, ART.field)
                lit:SetFile(BUTTON_LIT)
            end
            b:SetBackdrop(nil)
            art:SetShown(not b.field)
            lit:SetShown(not b.field)
            field:SetShown(b.field and true or false)
            art:SetFile(b:IsEnabled() and ART.button.file or BUTTON_DISABLED)
            local color = not b:IsEnabled() and "808080" or b.field and s.text or accent and "ffffff" or GOLD
            b.label:SetTextColor(ns.RGB(color))
            b:SetAlpha(b.field and not b:IsEnabled() and 0.45 or 1)
            return
        end
        if art then
            art:SetShown(false)
            lit:SetShown(false)
            field:SetShown(false)
        end
        b:SetBackdrop(FLAT)
        local bg = accent and s.accent or (hover and s.selection or s.panel)
        b:SetBackdropColor(ns.RGB(bg))
        b:SetBackdropBorderColor(ns.RGB(accent and s.accent or s.border))
        b.label:SetTextColor(ns.RGB(accent and (s.accentText or "ffffff") or s.text))
        b:SetAlpha(b:IsEnabled() and (hover and accent and 0.85 or 1) or 0.45)
    end
    b:SetScript("OnEnter", function() paint(true) end)
    b:SetScript("OnLeave", function() paint(false) end)
    b:SetScript("OnEnable", function() paint(false) end)
    b:SetScript("OnDisable", function() paint(false) end)
    b:SetScript("OnClick", onClick)
    function b:SetAccent(on)
        accent = on
        paint(false)
    end
    function b:Restyle() paint(false) end
    -- A disabled button still shows its tooltip (it says why it is disabled).
    if b.SetMotionScriptsWhileDisabled then b:SetMotionScriptsWhileDisabled(true) end
    ns.OnStyle(function() paint(false) end)
    return b
end

-- One answer of a few to pick from: a wide flat button with its name and, dim at its right end, a hint; framed in
-- the accent color under the mouse and while it is the one chosen (SetChosen).
function ns.Answer(parent, width, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, 24)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b.hint = ns.Text(b, 10, "dim")
    b.hint:SetPoint("RIGHT", -8, 0)
    b.label = ns.Text(b, 12)
    b.label:SetPoint("LEFT", 10, 0)
    b.label:SetPoint("RIGHT", b.hint, "LEFT", -6, 0)
    b.label:SetWordWrap(false)
    local hover = false
    local function paint()
        local s = ns.scheme
        if not s then return end
        local lit = hover or b.chosen
        b:SetBackdropColor(ns.RGB(lit and s.selection or s.panel))
        b:SetBackdropBorderColor(ns.RGB(lit and s.accent or s.border))
    end
    b:SetScript("OnEnter", function()
        hover = true
        paint()
    end)
    b:SetScript("OnLeave", function()
        hover = false
        paint()
    end)
    b:SetScript("OnClick", onClick)
    function b:SetChosen(on)
        self.chosen = on
        paint()
    end
    ns.OnStyle(paint)
    return b
end

-- Checkbox with a label: a small square, filled with the accent color when on.
-- getValue() -> boolean; onChange(value).
function ns.Check(parent, label, getValue, onChange)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(22)
    local box = CreateFrame("Frame", nil, b, "BackdropTemplate")
    box:SetSize(14, 14)
    box:SetPoint("LEFT")
    box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    local fill = box:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    -- The game's check box and its check, a little bigger than the box: the art has a margin.
    local gameBox, gameCheck
    local function GameArt(file, layer)
        local t = b:CreateTexture(nil, layer)
        t:SetTexture(file)
        t:SetSize(24, 24)
        t:SetPoint("CENTER", box, "CENTER")
        t:Hide()
        return t
    end
    b.label = ns.Text(b, 12)
    b.label:SetPoint("LEFT", box, "RIGHT", 6, 0)
    function b:SetLabel(text)
        self.label:SetText(text)
        self:SetWidth(14 + 6 + math.ceil(self.label:GetStringWidth()))
    end
    b:SetLabel(label)
    local function paint(hover)
        local s = ns.scheme
        if not s then return end
        local on = getValue() and true or false
        if s.native and not gameBox then
            gameBox = GameArt("Interface\\Buttons\\UI-CheckBox-Up", "BACKGROUND")
            gameCheck = GameArt("Interface\\Buttons\\UI-CheckBox-Check", "ARTWORK")
            b.gameLit = GameArt("Interface\\Buttons\\UI-CheckBox-Highlight", "HIGHLIGHT")
            b.gameLit:SetBlendMode("ADD")
        end
        if gameBox then
            gameBox:SetShown(s.native and true or false)
            gameCheck:SetShown(s.native and on)
            b.gameLit:SetShown(s.native and true or false)
        end
        box:SetShown(not s.native)
        box:SetBackdropColor(ns.RGB(s.bg))
        box:SetBackdropBorderColor(ns.RGB(hover and s.accent or s.border))
        fill:SetColorTexture(ns.RGB(s.check or s.accent))
        fill:SetShown(on)
    end
    b:SetScript("OnEnter", function() paint(true) end)
    b:SetScript("OnLeave", function() paint(false) end)
    b:SetScript("OnClick", function()
        onChange(not getValue())
        paint(true)
    end)
    ns.OnStyle(function() paint(false) end)
    function b:Refresh() paint(false) end -- the value changed elsewhere
    b.fill = fill
    return b
end

-- Single-line input.
function ns.Input(parent, width, maxLetters, name)
    local e = CreateFrame("EditBox", name, parent, "BackdropTemplate")
    e:SetSize(width, 24)
    e:SetAutoFocus(false)
    e:SetTextInsets(6, 6, 0, 0)
    e:SetFont(ns.UIFont(), 13, "")
    if maxLetters then e:SetMaxLetters(maxLetters) end
    e:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    e:SetScript("OnEscapePressed", e.ClearFocus)
    e:SetScript("OnEnterPressed", e.ClearFocus)
    local field
    local function paint()
        local s = ns.scheme
        if not s then return end
        e:SetTextColor(ns.RGB(s.text))
        -- The game's input frame in its look.
        if s.native and not field then field = Slices(e, ART.field) end
        if field then field:SetShown(s.native and true or false) end
        e:SetBackdrop(not s.native and FLAT or nil)
        if s.native then return end
        e:SetBackdropColor(ns.RGB(s.bg))
        e:SetBackdropBorderColor(ns.RGB(e:HasFocus() and s.accent or s.border))
    end
    e:SetScript("OnEditFocusGained", paint)
    e:SetScript("OnEditFocusLost", paint)
    ns.OnStyle(paint)
    return e
end

-- A small button at the end of a row: a letter ("x") or a texture (a path), dim, in the scheme's `hover` color
-- under the mouse, with a tooltip line (tip()). lit(on): the row stays lit while the mouse is over it.
function ns.RowButton(row, glyph, hover, lit, tip, onClick)
    local b = CreateFrame("Button", nil, row)
    b:SetSize(20, 20)
    local texture = glyph:find("\\", 1, true) ~= nil
    if texture then
        b.mark = b:CreateTexture(nil, "ARTWORK")
        b.mark:SetSize(13, 13)
        b.mark:SetTexture(glyph, nil, nil, "TRILINEAR") -- smooth at any size
    else
        b.mark = ns.Text(b, 12)
        b.mark:SetText(glyph)
    end
    b.mark:SetPoint("CENTER")
    local function paint(key)
        local r, g, bl = ns.RGB(ns.scheme[key])
        if texture then b.mark:SetVertexColor(r, g, bl) else b.mark:SetTextColor(r, g, bl) end
    end
    ns.OnStyle(function() paint("dim") end)
    b:SetScript("OnEnter", function()
        lit(true)
        paint(hover)
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
        GameTooltip:AddLine(tip(), 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function()
        lit(false)
        paint("dim")
        GameTooltip:Hide()
    end)
    b:SetScript("OnClick", onClick)
    return b
end

------------------------------------------------------------------------
-- Menus: one shared list frame for dropdowns and menu buttons
------------------------------------------------------------------------
local MENU_ROWS = 20 -- rows a menu shows at a time; the wheel and its scroll bar go through the rest
local MENU_MAX_W = 340 -- a longer item goes on to a second line
local menu = CreateFrame("Frame", "MacroSenseMenu", UIParent, "BackdropTemplate")
menu:SetFrameStrata("FULLSCREEN_DIALOG")
menu:SetClampedToScreen(true)
menu:Hide()
menu.rows, menu.items, menu.offset = {}, {}, 0
ns.Backdrop(menu, "panel", "border")

local function MenuRow(i)
    local r = CreateFrame("Button", nil, menu)
    r:SetHeight(20)
    r:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 20)
    r:SetPoint("RIGHT", menu, "RIGHT", -2, 0)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.text = ns.Text(r, 12)
    r.text:SetPoint("LEFT", 8, 0)
    r.text:SetWordWrap(true)
    -- An x at the end of a row whose item can be removed (item.onRemove).
    r.remove = ns.RowButton(r, "x", "invalid", function(on) r.bg:SetShown(on or r.current) end,
        function() return r.item.removeTip end, function()
            menu:Hide()
            r.item.onRemove()
        end)
    r.remove:SetPoint("RIGHT")
    r:SetScript("OnEnter", function()
        r.bg:SetShown(r.current or not r.item.disabled)
        if r.item.onEnter then r.item.onEnter(r) end
    end)
    r:SetScript("OnLeave", function()
        r.bg:SetShown(r.current)
        GameTooltip:Hide()
    end)
    r:SetScript("OnClick", function()
        if r.item.disabled then return end
        menu:Hide()
        r.item.onClick()
    end)
    ns.OnStyle(function(s) r.bg:SetColorTexture(ns.RGB(s.selection)) end)
    return r
end

-- Close the list on any click outside it.
menu:SetScript("OnShow", function(self) self.opened = GetTime() end)
menu:SetScript("OnUpdate", function(self)
    if GetTime() - self.opened > 0.1 and IsMouseButtonDown("LeftButton") and not self:IsMouseOver()
        and not (self.owner and self.owner:IsMouseOver()) then
        self:Hide()
    end
end)

-- The rows show the items from `menu.offset` on, each as high as its text: a long one on two lines.
local function FillMenu()
    local y = 2
    for i, r in ipairs(menu.rows) do
        local item = menu.items[menu.offset + i]
        r:SetShown(i <= MENU_ROWS and item ~= nil)
        if item and i <= MENU_ROWS then
            r.item, r.current = item, item.current
            r.bg:SetShown(r.current)
            r.text:SetWidth(menu.textWidth - (item.onRemove and 16 or 0))
            r.text:SetText(item.name)
            r.text:SetAlpha(item.disabled and 0.45 or 1)
            r.remove:SetShown(item.onRemove ~= nil)
            local h = math.max(20, math.ceil(r.text:GetStringHeight()) + 6)
            r:SetHeight(h)
            r:SetPoint("TOPLEFT", 2, -y)
            y = y + h
        end
    end
    menu:SetHeight(y + 2)
    if menu.bar then menu.bar:SetPosition(menu.offset) end
end

local function ScrollMenu(offset)
    menu.offset = math.max(0, math.min(#menu.items - MENU_ROWS, math.floor(offset + 0.5)))
    GameTooltip:Hide()
    FillMenu()
end
menu:EnableMouseWheel(true)
menu:SetScript("OnMouseWheel", function(_, delta) ScrollMenu(menu.offset - delta * 3) end)

-- items: { { name, onClick = fn, current = the chosen one, disabled, onEnter = fn(row) for a tooltip,
-- onRemove = fn for an x at the row's end, removeTip = its tooltip } }.
-- Opens below `owner`, or above it with `up`; `right` lines it up with the owner's right edge. A long one shows
-- MENU_ROWS at a time, with a scroll bar.
local function OpenMenu(owner, items, width, up, right)
    if menu:IsShown() and menu.owner == owner then return menu:Hide() end
    GameTooltip:Hide() -- the owner's tooltip would cover the list
    local shown = math.min(#items, MENU_ROWS)
    for i = #menu.rows + 1, shown do menu.rows[i] = MenuRow(i) end
    menu.items, menu.offset, menu.owner = items, 0, owner
    if not menu.bar then
        menu.bar = ns.ScrollBar(menu, ScrollMenu, 1)
        menu.bar:SetPoint("TOPRIGHT", -2, -2)
        menu.bar:SetPoint("BOTTOMRIGHT", -2, 2)
    end
    local scrolls = #items > MENU_ROWS
    menu.bar:SetRange(#items - shown, shown)
    -- As wide as the longest row, in any language, up to MENU_MAX_W: the longer ones wrap.
    local w, text = math.max(width, 180), menu.rows[1].text
    local measure = text.GetUnboundedStringWidth or text.GetStringWidth
    for _, item in ipairs(items) do
        text:SetText(item.name)
        w = math.max(w, measure(text) + (item.onRemove and 32 or 16))
    end
    w = math.min(w, math.max(width, MENU_MAX_W))
    for _, r in ipairs(menu.rows) do r:SetPoint("RIGHT", menu, "RIGHT", scrolls and -12 or -2, 0) end
    menu:SetWidth(w + (scrolls and 10 or 0))
    menu.textWidth = w - 16
    FillMenu()
    menu:ClearAllPoints()
    local side = right and "RIGHT" or "LEFT"
    if up then
        menu:SetPoint("BOTTOM" .. side, owner, "TOP" .. side, 0, 2)
    else
        menu:SetPoint("TOP" .. side, owner, "BOTTOM" .. side, 0, -2)
    end
    menu:Show()
end
ns.OpenMenu = OpenMenu

-- getItems() -> { { key, name }, ... }; getValue() -> key; onSelect(key).
function ns.Dropdown(parent, width, getItems, getValue, onSelect)
    local d = ns.Button(parent, "", width, nil)
    d.label:ClearAllPoints()
    d.label:SetPoint("LEFT", 8, 0)
    d.label:SetPoint("RIGHT", -18, 0)
    d.label:SetWordWrap(false)
    d.arrow = ns.Text(d, 10, "dim")
    d.arrow:SetPoint("RIGHT", -6, 0)
    d.arrow:SetText("v")
    -- In the game's look: the game's input frame and its down arrow.
    d.field = true
    local gameArrow = d:CreateTexture(nil, "ARTWORK")
    gameArrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    gameArrow:SetSize(20, 20)
    gameArrow:SetPoint("RIGHT", -1, 0)
    gameArrow:Hide()
    ns.OnStyle(function(s)
        gameArrow:SetShown(s.native and true or false)
        d.arrow:SetShown(not s.native)
        d:Restyle()
    end)

    function d:Refresh()
        for _, item in ipairs(getItems()) do
            if item.key == getValue() then self.label:SetText(item.name) end
        end
    end

    d:SetScript("OnClick", function(self)
        local items = {}
        for i, item in ipairs(getItems()) do
            items[i] = { name = item.name, current = item.key == getValue(), onClick = function()
                onSelect(item.key)
                self:Refresh()
            end }
        end
        OpenMenu(self, items, width)
    end)
    d:Refresh()
    return d
end

-- A button with a menu of actions: getItems() -> items as for OpenMenu, built on each click.
function ns.MenuButton(parent, label, width, getItems, up, right)
    local b = ns.Button(parent, label, width, nil)
    b:SetScript("OnClick", function(self) OpenMenu(self, getItems(), width, up, right) end)
    return b
end

function ns.CloseMenu() menu:Hide() end

-- "-  13  +" stepper.
function ns.Stepper(parent, min, max, getValue, onChange)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(76, 22)
    local value = ns.Text(f, 12)
    value:SetPoint("CENTER")
    value:SetJustifyH("CENTER")
    local function set(v)
        v = math.min(max, math.max(min, v))
        onChange(v)
        value:SetText(v)
    end
    local minus = ns.Button(f, "-", 22, function() set(getValue() - 1) end)
    minus:SetPoint("LEFT")
    local plus = ns.Button(f, "+", 22, function() set(getValue() + 1) end)
    plus:SetPoint("RIGHT")
    function f:Refresh() value:SetText(getValue()) end
    f:Refresh()
    return f
end

------------------------------------------------------------------------
-- Scroll bar: thin track + thumb in the scheme's colors, instead of the game's scroll bar
------------------------------------------------------------------------
local BAR_W, MIN_THUMB = 8, 24

-- onChange(value) runs when the player moves the thumb: drags it, or clicks the track (the thumb jumps there, its
-- middle under the mouse). `step` = snap to whole steps (rows). Our own, not the game's Slider: its clicks on the
-- track went the other way.
function ns.ScrollBar(parent, onChange, step)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetWidth(BAR_W)
    bar:EnableMouse(true)
    bar.max, bar.visible, bar.value = 0, 1, 0
    bar:Hide() -- until there is something to scroll

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(BAR_W, MIN_THUMB)
    bar.thumb = thumb

    local function paint()
        local s = ns.scheme
        if not s then return end
        track:SetColorTexture(ns.RGB(s.border))
        track:SetAlpha(0.35)
        thumb:SetColorTexture(ns.RGB((bar.hover or bar.dragging) and s.dim or s.border))
    end
    ns.OnStyle(paint)

    -- How far the thumb can travel, and where it is for the value: from the top.
    local thumbH = MIN_THUMB
    local function travel() return math.max(0, (bar:GetHeight() or 0) - thumbH) end
    local function place()
        local y = bar.max > 0 and travel() * bar.value / bar.max or 0
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", bar, "TOP", 0, -y)
    end
    -- The thumb shows how much of the content is visible.
    local function sizeThumb()
        local h = bar:GetHeight() or 0
        thumbH = math.max(MIN_THUMB, h * bar.visible / (bar.visible + bar.max))
        thumb:SetHeight(thumbH)
        place()
    end
    bar:SetScript("OnSizeChanged", sizeThumb)

    local function set(v)
        v = math.max(0, math.min(bar.max, v))
        if step then v = math.floor(v / step + 0.5) * step end
        if v == bar.value then return end
        bar.value = v
        place()
        onChange(v)
    end
    -- The mouse, from the bar's top.
    local function down()
        local _, y = GetCursorPosition()
        return (bar:GetTop() or 0) - y / (bar:GetEffectiveScale() or 1)
    end
    local grab -- where on the thumb it is held, from the thumb's top
    local function follow()
        local t = travel()
        if t > 0 then set((down() - grab) / t * bar.max) end
    end
    bar:SetScript("OnMouseDown", function()
        local top = bar.max > 0 and travel() * bar.value / bar.max or 0
        local y = down()
        local onThumb = y >= top and y <= top + thumbH
        grab = onThumb and (y - top) or thumbH / 2
        bar.dragging = true
        paint()
        follow()
        bar:SetScript("OnUpdate", follow)
    end)
    bar:SetScript("OnMouseUp", function()
        bar.dragging = false
        bar:SetScript("OnUpdate", nil)
        paint()
    end)
    bar:SetScript("OnEnter", function() bar.hover = true; paint() end)
    bar:SetScript("OnLeave", function() bar.hover = false; paint() end)

    -- max = how far it scrolls, visible = how much fits (same units).
    function bar:SetRange(max, visible)
        self.max, self.visible = math.max(0, max or 0), math.max(1, visible or 1)
        self.value = math.min(self.value, self.max)
        self:SetShown(self.max >= 1) -- text insets can leave a sub-pixel range: nothing to scroll
        sizeThumb()
    end
    -- Where the content is now, scrolled some other way (the wheel, the keys): the thumb follows, nothing is told.
    function bar:SetPosition(v)
        self.value = math.max(0, math.min(self.max, v or 0))
        place()
    end
    function bar:GetValue() return self.value end
    return bar
end

-- A ScrollBar for a ScrollFrame, to its right, plus mouse wheel scrolling (`wheelStep` pixels per notch).
function ns.AttachScrollBar(scroll, wheelStep)
    local bar = ns.ScrollBar(scroll:GetParent(), function(v) scroll:SetVerticalScroll(v) end)
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 3, 0)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 3, 0)
    local function update()
        bar:SetRange(scroll:GetVerticalScrollRange(), scroll:GetHeight())
        bar:SetPosition(scroll:GetVerticalScroll())
    end
    scroll:HookScript("OnScrollRangeChanged", update)
    scroll:HookScript("OnVerticalScroll", update)
    scroll:HookScript("OnSizeChanged", update)
    scroll:HookScript("OnShow", update)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        local range = scroll:GetVerticalScrollRange()
        local v = math.max(0, math.min(range, scroll:GetVerticalScroll() - delta * (wheelStep or 40)))
        scroll:SetVerticalScroll(v)
    end)
    return bar
end

-- Dotted corner to resize `frame` (made resizable by the caller); onDone() runs when the mouse is released.
function ns.ResizeGrip(frame, onDone)
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetFrameLevel(frame:GetFrameLevel() + 20)
    local dots = {}
    for row = 0, 2 do
        for col = 0, 2 - row do
            local d = grip:CreateTexture(nil, "OVERLAY")
            d:SetSize(2, 2)
            d:SetPoint("BOTTOMRIGHT", -2 - col * 4, 2 + row * 4)
            dots[#dots + 1] = d
        end
    end
    local function paint(hover)
        local s = ns.scheme
        if not s then return end
        for _, d in ipairs(dots) do d:SetColorTexture(ns.RGB(hover and s.accent or s.dim)) end
    end
    ns.OnStyle(function() paint(false) end)
    grip:SetScript("OnEnter", function() paint(true) end)
    grip:SetScript("OnLeave", function() paint(false) end)
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        if onDone then onDone() end
    end)
    return grip
end

function ns.SetMinSize(frame, w, h)
    if frame.SetResizeBounds then frame:SetResizeBounds(w, h) else frame:SetMinResize(w, h) end
end
