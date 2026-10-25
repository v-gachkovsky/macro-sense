-- Icon grid for macros: the question mark first (#showtooltip picks the icon), then icons of your spells
-- and items, then every macro icon the game offers, with icons you put in Interface\Icons yourself. Search
-- matches the names of your spells and items, of any spell or achievement that uses an icon (IconNames.lua),
-- and icon file names where the game gives them.
local _, ns = ...

local MIN_COLS, MIN_ROWS, SIZE, GAP, PAD = 10, 7, 34, 4, 10
local TOP, BOTTOM, SIDE = PAD * 2 + 26, PAD + 20, PAD + 18 -- around the grid: search, footer, scroll bar
local cols, rows = MIN_COLS, MIN_ROWS -- follow the window size
local QUESTION_MARK = 134400

local Picker = {}
ns.IconPicker = Picker

local frame, search, slider, buttons, info, scanner
local all, shown = nil, {}
local offset, current, onPick = 0, nil, nil
local anchor -- the editor window the picker docks to
local SNAP = 24 -- px: this close to the editor's right edge, the picker docks back

-- Saved: size, and whether it is docked to the editor or free (with its position).
local function Saved()
    ns.db.picker = ns.db.picker or { docked = true }
    return ns.db.picker
end

local function Dock()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 4, 0)
    Saved().docked = true
end

-- Left edge near the editor's right edge, tops roughly level.
local function NearEditor()
    local l, t, r, top = frame:GetLeft(), frame:GetTop(), anchor and anchor:GetRight(), anchor and anchor:GetTop()
    return l and t and r and top and math.abs(l - (r + 4)) <= SNAP and math.abs(t - top) <= SNAP * 3
end

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
        local entry = { icon = icon, name = name or (type(icon) == "string" and icon:match("[^\\/]+$")) or nil }
        seen[key] = entry
        out[#out + 1] = entry
    end
    add(QUESTION_MARK, "#showtooltip")
    for _, spell in ipairs(ns.sources.spells()) do add(spell.icon, spell.name) end
    for _, item in ipairs(ns.sources.items()) do add(item.icon, item.name) end
    if not gameIcons then
        -- As in the game's macro window: for spells, then for items, the icons you put in Interface\Icons
        -- yourself first. They come as file names; the game saves them by their path.
        gameIcons = {}
        local function from(fill, yours)
            for _, icon in ipairs(GameIcons(fill)) do gameIcons[#gameIcons + 1] = yours and Texture(icon) or icon end
        end
        from(GetLooseMacroIcons, true)
        from(GetMacroIcons)
        from(GetLooseMacroItemIcons, true)
        from(GetMacroItemIcons)
    end
    ns.IconNames.Want(gameIcons)
    for _, icon in ipairs(gameIcons) do add(icon) end
    return out
end

local function MaxOffset() return math.max(0, math.ceil(#shown / cols) - rows) end

local function SizeFor(c, r)
    return PAD + c * (SIZE + GAP) - GAP + SIDE, TOP + r * (SIZE + GAP) - GAP + BOTTOM
end

local function Refresh()
    for i, b in ipairs(buttons) do
        local entry = i <= cols * rows and shown[offset * cols + i] or nil
        b.entry = entry
        b:SetShown(entry ~= nil)
        if entry then
            b.tex:SetTexture(Texture(entry.icon))
            b.selected:SetShown(entry.icon == current)
        end
    end
    local text = #shown == 0 and ns.L["No icons"] or ns.Plural(#shown, "%d icon", "%d icons")
    local progress = ns.IconNames.Progress()
    if progress < 1 then text = string.format(ns.L["%s (looking up names: %d%%)"], text, math.floor(progress * 100)) end
    info:SetText(text)
end

local function SetOffset(v)
    offset = math.max(0, math.min(MaxOffset(), math.floor(v + 0.5)))
    slider:SetPosition(offset)
    Refresh()
end

local function Matches(entry, q)
    if entry.name and ns.Completion.Lower(entry.name):find(q, 1, true) then return true end
    local names = ns.IconNames.For(entry.icon)
    return names ~= nil and names.text:find(q, 1, true) ~= nil
end

-- keep: the view stays where it is (names found since the search came in), else it goes to the top.
local function Filter(keep)
    local q = ns.Completion.Lower(strtrim(search:GetText() or ""))
    if q == "" then
        shown = all
    else
        shown = {}
        for _, entry in ipairs(all) do
            if Matches(entry, q) then shown[#shown + 1] = entry end
        end
    end
    slider:SetRange(MaxOffset(), rows)
    SetOffset(keep and offset or 0)
end

local function Create()
    frame = CreateFrame("Frame", "MacroSenseIconPicker", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseIconPicker")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetResizable(true)
    ns.SetMinSize(frame, SizeFor(MIN_COLS, MIN_ROWS))
    local minW, minH = SizeFor(MIN_COLS, MIN_ROWS)
    local saved = ns.db.picker
    frame:SetSize(math.max(saved and saved.w or 0, minW), math.max(saved and saved.h or 0, minH))
    ns.Backdrop(frame, "panel", "border")
    frame:Hide()

    search = ns.Input(frame, 200, 40)
    search:SetPoint("TOPLEFT", PAD, -PAD)
    search:SetScript("OnTextChanged", function() Filter() end)
    local hint = ns.Text(frame, 11, "dim")
    hint:SetPoint("LEFT", search, "RIGHT", 8, 0)
    hint:SetText(ns.L["Search by name"])

    local close = ns.Button(frame, "x", 24, function() frame:Hide() end)
    close:SetPoint("TOPRIGHT", -PAD, -PAD)

    buttons = {}
    local function Button(i)
        local b = CreateFrame("Button", nil, frame)
        b:SetSize(SIZE, SIZE)
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
        -- Its name, then the names of other spells and achievements that use it.
        b:SetScript("OnEnter", function()
            local names = b.entry and ns.IconNames.For(b.entry.icon)
            local name = b.entry and b.entry.name or names and names[1]
            if not name then return end
            GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
            GameTooltip:SetText(name)
            for _, other in ipairs(names or {}) do
                if other ~= name then GameTooltip:AddLine(other, 0.8, 0.8, 0.8) end
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return b
    end

    -- As many columns and rows as fit; the first visible icon stays in view.
    local function Layout()
        local first = offset * cols
        local w, h = frame:GetWidth(), frame:GetHeight()
        cols = math.max(MIN_COLS, math.floor((w - PAD - SIDE + GAP) / (SIZE + GAP)))
        rows = math.max(MIN_ROWS, math.floor((h - TOP - BOTTOM + GAP) / (SIZE + GAP)))
        for i = 1, cols * rows do
            buttons[i] = buttons[i] or Button(i)
            local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
            buttons[i]:ClearAllPoints()
            buttons[i]:SetPoint("TOPLEFT", PAD + col * (SIZE + GAP), -TOP - row * (SIZE + GAP))
        end
        if slider then
            slider:SetRange(MaxOffset(), rows)
            SetOffset(math.floor(first / cols))
        end
    end
    Layout()
    frame:SetScript("OnSizeChanged", Layout)
    -- Resizing frees a frame from its anchor: a docked picker docks again.
    ns.ResizeGrip(frame, function()
        local saved = Saved()
        saved.w, saved.h = frame:GetWidth(), frame:GetHeight()
        if saved.docked then Dock() end
    end)

    -- Drag by any empty spot to move it; let go next to the editor to dock it again.
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    local function border(snap)
        local s = ns.scheme
        if s then frame:SetBackdropBorderColor(ns.RGB(snap and s.accent or s.border)) end
    end
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
        frame:SetScript("OnUpdate", function() border(NearEditor()) end)
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        frame:SetScript("OnUpdate", nil)
        border(false)
        if NearEditor() then return Dock() end
        local saved = Saved()
        local point, _, relPoint, x, y = frame:GetPoint()
        saved.docked, saved.point, saved.relPoint, saved.x, saved.y = false, point, relPoint, x, y
    end)

    slider = ns.ScrollBar(frame, SetOffset, 1)
    slider:SetPoint("TOPRIGHT", -PAD, -TOP)
    slider:SetPoint("BOTTOMRIGHT", -PAD, BOTTOM)

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta) SetOffset(offset - delta * 2) end)

    info = ns.Text(frame, 11, "dim")
    info:SetPoint("BOTTOMLEFT", PAD, PAD)

    -- Names for the game's icons: looked up a little each frame while the grid is open. What they match
    -- shows up every half second and at the end.
    local since = 0
    scanner = CreateFrame("Frame", nil, frame)
    scanner:SetScript("OnUpdate", function(_, elapsed)
        local done = ns.IconNames.Step(4)
        since = since + elapsed
        if not done and since < 0.5 then return end
        since = 0
        if strtrim(search:GetText() or "") ~= "" then Filter(true) else Refresh() end
        if done then scanner:Hide() end
    end)
end

-- anchor: frame to sit next to; icon: the macro's icon now; pick(icon) runs on every click.
function Picker.Open(editor, icon, pick)
    anchor = editor
    if not frame then Create() end
    current, onPick = icon, pick
    all = Build()
    search:SetText("")
    Filter()
    scanner:Show() -- names left to look up; it hides when there are none
    local saved = Saved()
    if saved.docked or not saved.point then
        Dock()
    else
        frame:ClearAllPoints()
        frame:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
    end
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
