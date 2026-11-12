-- MacroSense's page of the game's settings (AddOns; /ms settings): the click on a macro on an action bar that
-- opens it in the editor (ActionBars.lua), its keys and mouse button, or none; the keys of the tag macro (Tag.lua).
local _, ns = ...
ns = ns or {}
local L = ns.L

local Options = {}
ns.Options = Options

local PAD = 16

-- The keys and the mouse buttons the click may take, as the menus list them.
local function KeyItems()
    local out = {}
    for i, keys in ipairs(ns.ActionBars.KEYS) do out[i] = { key = keys, name = ns.ActionBars.KeysText(keys) } end
    return out
end
local function ButtonItems()
    local out = {}
    for i, button in ipairs(ns.ActionBars.BUTTONS) do
        out[i] = { key = button, name = ns.ActionBars.ButtonText(button) }
    end
    return out
end

-- A choice made: kept, and the buttons follow (after combat, if in it).
local function Chosen(field, value)
    ns.db[field] = value
    ns.ActionBars.ApplyClick()
    Options.Refresh()
end

-- The page, made once the saved settings are known (PLAYER_LOGIN), among the addons' pages of the game's settings.
function Options.Setup()
    if Options.page then return end
    local page = CreateFrame("Frame", nil, nil, "BackdropTemplate")
    page:Hide()
    page:SetScript("OnShow", function() ns.Window.Ready() end) -- its colors: the settings may open before the editor
    ns.Backdrop(page, "bg", "border")
    Options.page = page

    local title = ns.Text(page, 16)
    title:SetPoint("TOPLEFT", PAD, -PAD)
    title:SetText("MacroSense")
    local bars = ns.Text(page, 13, "accent")
    bars:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -18)
    bars:SetText(L["Action bars"])

    Options.on = ns.Check(page, L["Open a macro in MacroSense with a click on its button"],
        function() return ns.db.barEdit end, function(on) Chosen("barEdit", on) end)
    Options.on:SetPoint("TOPLEFT", bars, "BOTTOMLEFT", 0, -8)
    local combination = ns.Text(page, 12)
    combination:SetPoint("TOPLEFT", Options.on, "BOTTOMLEFT", 20, -12)
    combination:SetText(L["Combination:"])
    Options.keys = ns.Dropdown(page, 150, KeyItems, function() return ns.db.barEditKeys end,
        function(keys) Chosen("barEditKeys", keys) end)
    Options.keys:SetPoint("LEFT", combination, "RIGHT", 10, 0)
    local plus = ns.Text(page, 12)
    plus:SetPoint("LEFT", Options.keys, "RIGHT", 8, 0)
    plus:SetText("+")
    Options.click = ns.Dropdown(page, 150, ButtonItems, function() return ns.db.barEditButton end,
        function(button) Chosen("barEditButton", button) end)
    Options.click:SetPoint("LEFT", plus, "RIGHT", 8, 0)
    local note = ns.Text(page, 12, "dim")
    note:SetPoint("TOPLEFT", combination, "BOTTOMLEFT", 0, -14)
    note:SetWidth(520)
    note:SetWordWrap(true)
    note:SetText(L["This click opens the macro instead of running it. Pick one your macros don't use, or turn it off."])

    -- The tag macro (Tag.lua): the keys held with a click on a creature or player.
    local tag = ns.Text(page, 13, "accent")
    tag:SetPoint("TOPLEFT", note, "BOTTOMLEFT", -20, -24)
    tag:SetText(L["Tag macro"])
    local keys = ns.Text(page, 12)
    keys:SetPoint("TOPLEFT", tag, "BOTTOMLEFT", 20, -14)
    keys:SetText(L["Keys:"])
    Options.tagKeys = ns.Dropdown(page, 150, KeyItems, function() return ns.db.tagKeys end,
        function(picked) ns.db.tagKeys = picked end)
    Options.tagKeys:SetPoint("LEFT", keys, "RIGHT", 10, 0)
    local tagNote = ns.Text(page, 12, "dim")
    tagNote:SetPoint("TOPLEFT", keys, "BOTTOMLEFT", 0, -14)
    tagNote:SetWidth(520)
    tagNote:SetWordWrap(true)
    tagNote:SetText(L["Hold them and click a creature or player: its name goes into your tag macro, which then targets "
        .. "it. A click on yourself takes the name out. A macro becomes the tag macro in its \"...\" menu."])
    Options.Refresh()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        Options.category = Settings.RegisterCanvasLayoutCategory(page, "MacroSense")
        Settings.RegisterAddOnCategory(Options.category)
    elseif InterfaceOptions_AddCategory then -- the older clients' settings
        page.name = "MacroSense"
        InterfaceOptions_AddCategory(page)
    end
end

-- The page as the settings are now: the combination only while the click is on.
function Options.Refresh()
    if not Options.page then return end
    Options.on:Refresh()
    Options.keys:Refresh()
    Options.click:Refresh()
    Options.tagKeys:Refresh()
    Options.keys:SetEnabled(ns.db.barEdit and true or false)
    Options.click:SetEnabled(ns.db.barEdit and true or false)
end

-- /ms settings: the game's settings on MacroSense's page.
function Options.Open()
    if Options.category and Settings.OpenToCategory then
        Settings.OpenToCategory(Options.category:GetID())
    elseif Options.page and InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(Options.page)
    end
end

return Options
