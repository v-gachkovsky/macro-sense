-- Flat, theme-aware widgets for the editor window. Every widget restyles itself when the scheme changes.
local _, ns = ...

local WHITE = "Interface\\Buttons\\WHITE8x8"
local UI_FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" -- localized: covers the client's alphabet
ns.UI_FONT = UI_FONT

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
    fs:SetFont(UI_FONT, size or 12, "")
    fs:SetJustifyH("LEFT")
    ns.OnStyle(function(s) fs:SetTextColor(ns.RGB(s[colorKey or "text"])) end)
    return fs
end

-- Flat button. `accent` = filled with the accent color (primary action).
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
    -- A disabled button still shows its tooltip (it says why it is disabled).
    if b.SetMotionScriptsWhileDisabled then b:SetMotionScriptsWhileDisabled(true) end
    ns.OnStyle(function() paint(false) end)
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
    b.label:SetText(label)
    b:SetWidth(14 + 6 + math.ceil(b.label:GetStringWidth()))
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
    b.fill = fill
    return b
end

-- Single-line input.
function ns.Input(parent, width, maxLetters, name)
    local e = CreateFrame("EditBox", name, parent, "BackdropTemplate")
    e:SetSize(width, 24)
    e:SetAutoFocus(false)
    e:SetTextInsets(6, 6, 0, 0)
    e:SetFont(UI_FONT, 13, "")
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

------------------------------------------------------------------------
-- Menus: one shared list frame for dropdowns and menu buttons
------------------------------------------------------------------------
local menu = CreateFrame("Frame", "MacroSenseMenu", UIParent, "BackdropTemplate")
menu:SetFrameStrata("FULLSCREEN_DIALOG")
menu:SetClampedToScreen(true)
menu:Hide()
menu.rows = {}
ns.Backdrop(menu, "panel", "border")

local function MenuRow(i)
    local r = CreateFrame("Button", nil, menu)
    r:SetHeight(20)
    r:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 20)
    r:SetPoint("TOPRIGHT", -2, -2 - (i - 1) * 20)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.text = ns.Text(r, 12)
    r.text:SetPoint("LEFT", 8, 0)
    r.text:SetPoint("RIGHT", -8, 0)
    r.text:SetWordWrap(false)
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

-- items: { { name, onClick = fn, current = the chosen one, disabled, onEnter = fn(row) for a tooltip } }.
-- Opens below `owner`, or above it with `up`; `right` lines it up with the owner's right edge.
local function OpenMenu(owner, items, width, up, right)
    if menu:IsShown() and menu.owner == owner then return menu:Hide() end
    GameTooltip:Hide() -- the owner's tooltip would cover the list
    for i = #menu.rows + 1, #items do menu.rows[i] = MenuRow(i) end
    for i, r in ipairs(menu.rows) do
        local item = items[i]
        r:SetShown(item ~= nil)
        if item then
            r.item, r.current = item, item.current
            r.bg:SetShown(r.current)
            r.text:SetText(item.name)
            r.text:SetAlpha(item.disabled and 0.45 or 1)
        end
    end
    menu.owner = owner
    menu:SetWidth(math.max(width, 180))
    menu:SetHeight(#items * 20 + 4)
    menu:ClearAllPoints()
    local side = right and "RIGHT" or "LEFT"
    if up then
        menu:SetPoint("BOTTOM" .. side, owner, "TOP" .. side, 0, 2)
    else
        menu:SetPoint("TOP" .. side, owner, "BOTTOM" .. side, 0, -2)
    end
    menu:Show()
end

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

-- onChange(value) runs when the player drags the thumb. `step` = snap to whole steps (rows).
function ns.ScrollBar(parent, onChange, step)
    local bar = CreateFrame("Slider", nil, parent)
    bar:SetOrientation("VERTICAL")
    bar:SetWidth(BAR_W)
    bar:SetMinMaxValues(0, 0)
    bar:SetValueStep(step or 1)
    if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(step ~= nil) end
    bar:EnableMouse(true)
    bar.max, bar.visible = 0, 1
    bar:Hide() -- until there is something to scroll

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(BAR_W, MIN_THUMB)
    bar:SetThumbTexture(thumb)

    local function paint()
        local s = ns.scheme
        if not s then return end
        track:SetColorTexture(ns.RGB(s.border))
        track:SetAlpha(0.35)
        thumb:SetColorTexture(ns.RGB((bar.hover or bar.dragging) and s.dim or s.border))
    end
    bar:SetScript("OnEnter", function() bar.hover = true; paint() end)
    bar:SetScript("OnLeave", function() bar.hover = false; paint() end)
    bar:SetScript("OnMouseDown", function() bar.dragging = true; paint() end)
    bar:SetScript("OnMouseUp", function() bar.dragging = false; paint() end)
    ns.OnStyle(paint)

    -- The thumb shows how much of the content is visible.
    local function sizeThumb()
        local h = bar:GetHeight() or 0
        thumb:SetHeight(math.max(MIN_THUMB, h * bar.visible / (bar.visible + bar.max)))
    end
    bar:SetScript("OnSizeChanged", sizeThumb)
    bar:SetScript("OnValueChanged", function(_, v)
        if not bar.setting then onChange(v) end
    end)

    -- max = how far it scrolls, visible = how much fits (same units).
    function bar:SetRange(max, visible)
        self.max, self.visible = math.max(0, max or 0), math.max(1, visible or 1)
        self:SetMinMaxValues(0, self.max)
        self:SetShown(self.max >= 1) -- text insets can leave a sub-pixel range: nothing to scroll
        sizeThumb()
    end
    function bar:SetPosition(v)
        self.setting = true
        self:SetValue(v)
        self.setting = false
    end
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
