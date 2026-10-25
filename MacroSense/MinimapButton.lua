-- The MacroSense button on the edge of the minimap: a click opens the editor, a drag moves it along the edge.
-- Where it sits is pure Lua; the button needs the game.
local _, ns = ...
ns = ns or {}

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local EDGE = 5 -- its center is this far outside the minimap's edge, so it sits on the border
local atan2 = math.atan2 or math.atan -- Lua 5.1 in the game, 5.3+ in tests
local button

-- Whether the quarter of the minimap toward (top, left) is round. Addons that reshape the minimap say how
-- through GetMinimapShape(): "CORNER-TOPLEFT" keeps that corner round, "SIDE-LEFT" the left half,
-- "TRICORNER-TOPLEFT" every corner but the opposite one, "SQUARE" none.
local function IsRound(shape, top, left)
    local kind, where = shape:match("^(%u+)%-(%u+)$")
    local v, h = top and "TOP" or "BOTTOM", left and "LEFT" or "RIGHT"
    if kind == "CORNER" then return where == v .. h end
    if kind == "SIDE" then return where == v or where == h end
    if kind == "TRICORNER" then return where ~= (top and "BOTTOM" or "TOP") .. (left and "RIGHT" or "LEFT") end
    return shape ~= "SQUARE"
end

-- The button's offset from the minimap's center at `angle` (degrees: 0 = right, 90 = up): on the round
-- edge, or on the side of a square corner.
function MinimapButton.Offset(angle, width, height, shape)
    local x, y = math.cos(math.rad(angle)), math.sin(math.rad(angle))
    if not IsRound(shape or "ROUND", y > 0, x < 0) then
        local k = 1 / math.max(math.abs(x), math.abs(y))
        x, y = x * k, y * k
    end
    return x * (width / 2 + EDGE), y * (height / 2 + EDGE)
end

------------------------------------------------------------------------
-- The button (game API)
------------------------------------------------------------------------
local function Place()
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local x, y = MinimapButton.Offset(ns.db.minimapAngle, Minimap:GetWidth(), Minimap:GetHeight(), shape)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- While it is dragged: the angle from the minimap's center to the cursor.
local function FollowCursor()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    ns.db.minimapAngle = math.deg(atan2(cy / scale - my, cx / scale - mx)) % 360
    Place()
end

local function Tooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("MacroSense", 1, 1, 1)
    GameTooltip:AddLine(ns.L["Click: open or close the editor"], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(ns.L["Drag: move the button"], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(ns.L["/ms minimap hides it"], 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

-- Laid out like the game's own mail button on the minimap: the icon at 7,-6 and the round border over it.
local function Create()
    button = CreateFrame("Button", "MacroSenseMinimapButton", Minimap)
    button:SetSize(33, 33)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local back = button:CreateTexture(nil, "BACKGROUND")
    back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    back:SetSize(20, 20)
    back:SetPoint("TOPLEFT", 7, -5)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\MacroSense\\Media\\logo")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- the logo's rounded corners go, the border covers the rest
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", 7, -6)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function() ns.Window.Toggle() end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:LockHighlight()
        self:SetScript("OnUpdate", FollowCursor)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)
    button:SetScript("OnEnter", Tooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Minimap:HookScript("OnSizeChanged", Place) -- addons that resize the minimap
end

-- On login (addons that reshape the minimap have done it by then) and after /ms minimap.
function MinimapButton.Update()
    if not Minimap then return end
    if not button then
        if not ns.db.minimapButton then return end -- hidden: not even made
        Create()
    end
    Place()
    button:SetShown(ns.db.minimapButton)
end

-- /ms minimap: hides it, or brings it back. True when it shows now.
function MinimapButton.Toggle()
    ns.db.minimapButton = not ns.db.minimapButton
    MinimapButton.Update()
    return ns.db.minimapButton
end

-- Retail also lists addons in a menu by the minimap (## AddonCompartmentFunc in the TOC).
function MacroSense_OnAddonCompartmentClick() ns.Window.Toggle() end

return MinimapButton
