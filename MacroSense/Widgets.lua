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
function ns.Backdrop(frame, bgKey, borderKey)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    ns.OnStyle(function(s)
        frame:SetBackdropColor(ns.RGB(s[bgKey or "panel"]))
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
function ns.Button(parent, label, width, onClick, accent)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width or 80, 22)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b.label = ns.Text(b, 12)
    b.label:SetPoint("CENTER")
    b.label:SetText(label)
    local function paint(hover)
        local s = ns.scheme
        if not s then return end
        local bg = accent and s.accent or (hover and s.selection or s.panel)
        b:SetBackdropColor(ns.RGB(bg))
        b:SetBackdropBorderColor(ns.RGB(accent and s.accent or s.border))
        b.label:SetTextColor(ns.RGB(accent and "ffffff" or s.text))
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
        box:SetBackdropColor(ns.RGB(s.bg))
        box:SetBackdropBorderColor(ns.RGB(hover and s.accent or s.border))
        fill:SetColorTexture(ns.RGB(s.accent))
        fill:SetShown(getValue() and true or false)
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
    local function paint()
        local s = ns.scheme
        if not s then return end
        e:SetBackdropColor(ns.RGB(s.bg))
        e:SetBackdropBorderColor(ns.RGB(e:HasFocus() and s.accent or s.border))
        e:SetTextColor(ns.RGB(s.text))
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
    r.text:SetPoint("RIGHT", -8, 0)
    r.text:SetWordWrap(false)
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

-- The rows show the items from `menu.offset` on.
local function FillMenu()
    for i, r in ipairs(menu.rows) do
        local item = menu.items[menu.offset + i]
        r:SetShown(i <= MENU_ROWS and item ~= nil)
        if item then
            r.item, r.current = item, item.current
            r.bg:SetShown(r.current)
            r.text:SetText(item.name)
            r.text:SetAlpha(item.disabled and 0.45 or 1)
            r.remove:SetShown(item.onRemove ~= nil)
            r.text:SetPoint("RIGHT", item.onRemove and -24 or -8, 0)
        end
    end
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
    -- As wide as the longest row, in any language.
    local w = math.max(width, 180)
    for i, item in ipairs(items) do
        menu.rows[1].text:SetText(item.name)
        w = math.max(w, menu.rows[1].text:GetStringWidth() + (item.onRemove and 32 or 16))
    end
    FillMenu()
    for _, r in ipairs(menu.rows) do r:SetPoint("RIGHT", menu, "RIGHT", scrolls and -12 or -2, 0) end
    menu:SetWidth(w + (scrolls and 10 or 0))
    menu:SetHeight(shown * 20 + 4)
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
