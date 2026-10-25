-- Suggestion list shown under the cursor. Shows up to VISIBLE rows and scrolls through the rest.
local _, ns = ...

local PAD, ICON_GAP = 3, 4
local VISIBLE = 10    -- rows on screen
local WHEEL_ROWS = 3  -- rows per mouse wheel notch
local BAR_ROOM = 12   -- right margin for the scroll bar

local Popup = CreateFrame("Frame", "MacroSensePopup", UIParent, "BackdropTemplate")
ns.Popup = Popup
Popup:SetFrameStrata("TOOLTIP")
Popup:SetWidth(280)
Popup:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
})
Popup:Hide()

-- items: the whole list; selected: index in it; offset: items above the first row.
Popup.rows, Popup.items, Popup.selected, Popup.offset = {}, {}, 1, 0
Popup.rowHeight = 18
Popup.onAccept = nil -- function(item), set by Autocomplete

local font, fontSize = "Fonts\\FRIZQT__.TTF", 12
local colors

local function MaxOffset() return math.max(0, #Popup.items - VISIBLE) end

local function Row(i)
    local row = CreateFrame("Button", nil, Popup)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("LEFT", 2, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.text = row:CreateFontString(nil, "ARTWORK")
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row.hint = row:CreateFontString(nil, "ARTWORK")
    row.hint:SetPoint("RIGHT", -4, 0)
    row.hint:SetJustifyH("RIGHT")
    row:SetScript("OnClick", function()
        Popup.selected = Popup.offset + i
        Popup:Accept()
    end)
    row:SetScript("OnEnter", function()
        Popup.selected = Popup.offset + i
        Popup:Refresh()
    end)
    return row
end

local function Layout(row, i, scrolls)
    local h = Popup.rowHeight
    row:SetHeight(h)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", PAD, -PAD - (i - 1) * h)
    row:SetPoint("TOPRIGHT", -PAD - (scrolls and BAR_ROOM or 0), -PAD - (i - 1) * h)
    row.icon:SetSize(h - 4, h - 4)
    row.text:SetFont(font, fontSize, "")
    -- Hints are words, not code: in Ukrainian in the interface's font, which has its letters.
    row.hint:SetFont(ns.language == "uk" and ns.UIFont() or font, math.max(fontSize - 2, 8), "")
end

-- Scroll bar on the right, only when the list is longer than the rows.
Popup.bar = ns.ScrollBar(Popup, function(v) Popup:Scroll(v) end, 1)
Popup.bar:SetPoint("TOPRIGHT", -PAD - 1, -PAD)
Popup.bar:SetPoint("BOTTOMRIGHT", -PAD - 1, PAD)

function Popup:Refresh()
    local scrolls = #self.items > VISIBLE
    for i, row in ipairs(self.rows) do
        local index = self.offset + i
        local item = i <= VISIBLE and self.items[index] or nil
        row:SetShown(item ~= nil)
        if item then
            Layout(row, i, scrolls)
            row.icon:SetShown(item.icon ~= nil)
            if item.icon then row.icon:SetTexture(item.icon) end
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", item.icon and (self.rowHeight + ICON_GAP) or 6, 0)
            row.text:SetPoint("RIGHT", row.hint, "LEFT", -8, 0)
            row.text:SetText(item.name)
            row.hint:SetText(item.hint and ns.L[item.hint] or "")
            if colors then
                row.bg:SetColorTexture(ns.RGB(colors.selection))
                row.bg:SetShown(index == self.selected)
                row.text:SetTextColor(ns.RGB(colors.text))
                row.hint:SetTextColor(ns.RGB(colors.dim))
            end
        end
    end
    self.bar:SetRange(MaxOffset(), VISIBLE)
    self.bar:SetPosition(self.offset)
end

-- First visible item (0-based), kept within the list.
function Popup:Scroll(offset)
    self.offset = math.max(0, math.min(MaxOffset(), math.floor(offset + 0.5)))
    self:Refresh()
end

-- Scroll just enough to show the selected item.
local function ShowSelected(self)
    if self.selected <= self.offset then
        self.offset = self.selected - 1
    elseif self.selected > self.offset + VISIBLE then
        self.offset = self.selected - VISIBLE
    end
    self:Scroll(self.offset)
end

-- Fonts and colors follow the editor.
function Popup:Style(scheme, fontPath, size)
    colors, font, fontSize = scheme, fontPath, size
    self.rowHeight = math.floor(size * 1.6 + 0.5)
    self:SetBackdropColor(ns.RGB(scheme.panel))
    self:SetBackdropBorderColor(ns.RGB(scheme.border))
    if self:IsShown() then self:Refresh() end
end

local function signature(items)
    local names = {}
    for i, item in ipairs(items) do names[i] = item.name end
    return table.concat(names, "\1")
end

-- owner = EditBox; x, y = cursor offset from its top left (from OnCursorChanged), h = line height.
-- The selection and scroll stay when the list did not change (the same word re-checked after a cursor event).
function Popup:Open(owner, items, x, y, h)
    if #items == 0 then return self:Hide() end
    local sig = signature(items)
    if sig ~= self.signature or not self:IsShown() then self.selected, self.offset = 1, 0 end
    self.items, self.signature = items, sig
    local rows = math.min(#items, VISIBLE)
    for i = #self.rows + 1, rows do self.rows[i] = Row(i) end
    self:SetHeight(rows * self.rowHeight + PAD * 2)
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", owner, "TOPLEFT", x, y - h - 2)
    self:Refresh()
    self:Show()
end

-- Up / Down (delta 1) wrap around the list; PageUp / PageDown (delta VISIBLE) stop at its ends.
function Popup:Move(delta)
    local n = #self.items
    if n == 0 then return end
    if math.abs(delta) == 1 then
        self.selected = (self.selected - 1 + delta) % n + 1
    else
        self.selected = math.max(1, math.min(n, self.selected + delta))
    end
    ShowSelected(self)
end

function Popup:Accept()
    local item = self.items[self.selected]
    self:Hide()
    if item and self.onAccept then self.onAccept(item) end
end

-- The mouse wheel scrolls the list; the selection stays where it is.
Popup:EnableMouseWheel(true)
Popup:SetScript("OnMouseWheel", function(self, delta) self:Scroll(self.offset - delta * WHEEL_ROWS) end)
