-- Suggestion list shown under the cursor.
local _, ns = ...

local PAD, ICON_GAP = 3, 4

local Popup = CreateFrame("Frame", "MacroSensePopup", UIParent, "BackdropTemplate")
ns.Popup = Popup
Popup:SetFrameStrata("TOOLTIP")
Popup:SetWidth(280)
Popup:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
})
Popup:Hide()

Popup.rows, Popup.items, Popup.selected = {}, {}, 1
Popup.rowHeight = 18
Popup.onAccept = nil -- function(item), set by Autocomplete

local font, fontSize = "Fonts\\FRIZQT__.TTF", 12
local colors

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
        Popup.selected = i
        Popup:Accept()
    end)
    row:SetScript("OnEnter", function()
        Popup.selected = i
        Popup:Refresh()
    end)
    return row
end

local function Layout(row, i)
    local h = Popup.rowHeight
    row:SetHeight(h)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", PAD, -PAD - (i - 1) * h)
    row:SetPoint("TOPRIGHT", -PAD, -PAD - (i - 1) * h)
    row.icon:SetSize(h - 4, h - 4)
    row.text:SetFont(font, fontSize, "")
    row.hint:SetFont(font, math.max(fontSize - 2, 8), "")
end

function Popup:Refresh()
    for i, row in ipairs(self.rows) do
        local item = self.items[i]
        row:SetShown(item ~= nil)
        if item then
            Layout(row, i)
            row.icon:SetShown(item.icon ~= nil)
            if item.icon then row.icon:SetTexture(item.icon) end
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", item.icon and (self.rowHeight + ICON_GAP) or 6, 0)
            row.text:SetPoint("RIGHT", row.hint, "LEFT", -8, 0)
            row.text:SetText(item.name)
            row.hint:SetText(item.hint or "")
            if colors then
                local selected = i == self.selected
                row.bg:SetColorTexture(ns.RGB(colors.selection))
                row.bg:SetShown(selected)
                row.text:SetTextColor(ns.RGB(colors.text))
                row.hint:SetTextColor(ns.RGB(colors.dim))
            end
        end
    end
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
-- The selection stays when the list did not change (e.g. the same word re-checked after a cursor event).
function Popup:Open(owner, items, x, y, h)
    if #items == 0 then return self:Hide() end
    local sig = signature(items)
    if sig ~= self.signature or not self:IsShown() then self.selected = 1 end
    self.items, self.signature = items, sig
    for i = #self.rows + 1, #items do self.rows[i] = Row(i) end
    self:SetHeight(#items * self.rowHeight + PAD * 2)
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", owner, "TOPLEFT", x, y - h - 2)
    self:Refresh()
    self:Show()
end

function Popup:Move(delta)
    local n = #self.items
    if n == 0 then return end
    self.selected = (self.selected - 1 + delta) % n + 1
    self:Refresh()
end

function Popup:Accept()
    local item = self.items[self.selected]
    self:Hide()
    if item and self.onAccept then self.onAccept(item) end
end
