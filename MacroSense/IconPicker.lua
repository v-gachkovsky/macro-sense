-- Icon grid for macros: the question mark first (#showtooltip picks the icon), then icons of your spells
-- and items, then every macro icon the game offers. Search matches spell / item names and icon file names.
local _, ns = ...

local COLS, ROWS, SIZE, GAP, PAD = 10, 7, 34, 4, 10
local QUESTION_MARK = 134400

local Picker = {}
ns.IconPicker = Picker

local frame, search, slider, buttons, info
local all, shown = nil, {}
local offset, current, onPick = 0, nil, nil

-- Older flavors return texture names instead of file IDs.
local function Texture(icon)
    if type(icon) == "string" and not icon:find("[\\/]") then return "Interface\\Icons\\" .. icon end
    return icon
end

local function GameIcons(fill)
    local t = {}
    local r = fill and fill(t)
    return type(r) == "table" and r or t
end

-- Built once per open: spells and items change, the game's icon list does not.
local gameIcons
local function Build()
    local out, seen = {}, {}
    local function add(icon, name)
        if not icon then return end
        local key = type(icon) == "string" and icon:lower() or icon
        if seen[key] then
            -- The same icon found again by name (a spell, an item): make it searchable by that name too.
            if name then seen[key].name = (seen[key].name and seen[key].name .. " " or "") .. name end
            return
        end
        local entry = { icon = icon, name = name or (type(icon) == "string" and icon) or nil }
        seen[key] = entry
        out[#out + 1] = entry
    end
    add(QUESTION_MARK, "#showtooltip")
    for _, spell in ipairs(ns.sources.spells()) do add(spell.icon, spell.name) end
    for _, item in ipairs(ns.sources.items()) do add(item.icon, item.name) end
    if not gameIcons then
        gameIcons = {}
        for _, icon in ipairs(GameIcons(GetMacroIcons)) do gameIcons[#gameIcons + 1] = icon end
        for _, icon in ipairs(GameIcons(GetMacroItemIcons)) do gameIcons[#gameIcons + 1] = icon end
    end
    for _, icon in ipairs(gameIcons) do add(icon) end
    return out
end

local function MaxOffset() return math.max(0, math.ceil(#shown / COLS) - ROWS) end

local function Refresh()
    for i, b in ipairs(buttons) do
        local entry = shown[offset * COLS + i]
        b.entry = entry
        b:SetShown(entry ~= nil)
        if entry then
            b.tex:SetTexture(Texture(entry.icon))
            b.selected:SetShown(entry.icon == current)
        end
    end
    info:SetText(#shown == 0 and "No icons" or string.format("%d icons", #shown))
end

local function SetOffset(v)
    offset = math.max(0, math.min(MaxOffset(), math.floor(v + 0.5)))
    slider:SetPosition(offset)
    Refresh()
end

local function Filter()
    local q = strtrim(search:GetText() or ""):lower()
    if q == "" then
        shown = all
    else
        shown = {}
        for _, entry in ipairs(all) do
            if entry.name and entry.name:lower():find(q, 1, true) then shown[#shown + 1] = entry end
        end
    end
    slider:SetRange(MaxOffset(), ROWS)
    SetOffset(0)
end

local function Create()
    frame = CreateFrame("Frame", "MacroSenseIconPicker", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseIconPicker")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetSize(PAD * 2 + COLS * (SIZE + GAP) - GAP + 18, PAD * 3 + 26 + ROWS * (SIZE + GAP) - GAP + 20)
    ns.Backdrop(frame, "panel", "border")
    frame:Hide()

    search = ns.Input(frame, 200, 40)
    search:SetPoint("TOPLEFT", PAD, -PAD)
    search:SetScript("OnTextChanged", Filter)
    local hint = ns.Text(frame, 11, "dim")
    hint:SetPoint("LEFT", search, "RIGHT", 8, 0)
    hint:SetText("Search spell or item")

    local close = ns.Button(frame, "x", 24, function() frame:Hide() end)
    close:SetPoint("TOPRIGHT", -PAD, -PAD)

    buttons = {}
    for i = 1, COLS * ROWS do
        local b = CreateFrame("Button", nil, frame)
        b:SetSize(SIZE, SIZE)
        local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
        b:SetPoint("TOPLEFT", PAD + col * (SIZE + GAP), -(PAD * 2 + 26) - row * (SIZE + GAP))
        b.tex = b:CreateTexture(nil, "ARTWORK")
        b.tex:SetAllPoints()
        b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.selected = b:CreateTexture(nil, "BACKGROUND") -- accent frame around the current icon
        b.selected:SetPoint("TOPLEFT", -2, 2)
        b.selected:SetPoint("BOTTOMRIGHT", 2, -2)
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        ns.OnStyle(function(s) b.selected:SetColorTexture(ns.RGB(s.accent)) end)
        b:SetScript("OnClick", function()
            current = b.entry.icon
            Refresh()
            if onPick then onPick(current) end
        end)
        b:SetScript("OnEnter", function()
            if not (b.entry and b.entry.name) then return end
            GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
            GameTooltip:SetText(b.entry.name)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        buttons[i] = b
    end

    slider = ns.ScrollBar(frame, SetOffset, 1)
    slider:SetPoint("TOPRIGHT", -PAD, -(PAD * 2 + 26))
    slider:SetPoint("BOTTOMRIGHT", -PAD, PAD + 20)

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta) SetOffset(offset - delta * 2) end)

    info = ns.Text(frame, 11, "dim")
    info:SetPoint("BOTTOMLEFT", PAD, PAD)
end

-- anchor: frame to sit next to; icon: the macro's icon now; pick(icon) runs on every click.
function Picker.Open(anchor, icon, pick)
    if not frame then Create() end
    current, onPick = icon, pick
    all = Build()
    search:SetText("")
    Filter()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 4, 0)
    frame:Show()
end

function Picker.Close()
    if frame then frame:Hide() end
end

function Picker.IsShown() return frame ~= nil and frame:IsShown() end

-- Show `icon` as selected (the macro was reverted or switched while the grid is open).
function Picker.SetCurrent(icon)
    current = icon
    if Picker.IsShown() then Refresh() end
end

ns.IconTexture = Texture
