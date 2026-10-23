local ADDON, ns = ...
_G.MacroSense = ns

local L_PREFIX = "|cff569cd6MacroSense|r: "
function ns.Print(...) print(L_PREFIX .. string.format(...)) end

ns.defaults = {
    enabled = true, -- autocomplete
    debug = false,  -- print key events of the editor
    font = ns.DEFAULT_FONT,
    fontSize = 13,
    scheme = ns.DEFAULT_SCHEME,
    scope = "general",
}

local IsLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

-- "MacroSense" button next to the Blizzard macro window.
local function AddMacroFrameButton()
    if not MacroFrame or ns.macroFrameButton then return end
    local b = CreateFrame("Button", nil, MacroFrame, "UIPanelButtonTemplate")
    b:SetSize(100, 22)
    b:SetText("MacroSense")
    b:SetPoint("TOPLEFT", MacroFrame, "TOPRIGHT", 2, -30)
    b:SetScript("OnClick", function() ns.Window.Toggle() end)
    ns.macroFrameButton = b
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "SPELLS_CHANGED", "BAG_UPDATE_DELAYED",
    "PLAYER_EQUIPMENT_CHANGED", "UPDATE_MACROS" }) do
    f:RegisterEvent(e)
end
f:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == ADDON then
            MacroSenseDB = MacroSenseDB or {}
            for k, v in pairs(ns.defaults) do
                if MacroSenseDB[k] == nil then MacroSenseDB[k] = v end
            end
            ns.db = MacroSenseDB
            if IsLoaded("Blizzard_MacroUI") then AddMacroFrameButton() end
        elseif name == "Blizzard_MacroUI" then
            AddMacroFrameButton()
        end
        -- New addons may register new slash commands.
        ns.InvalidateSources("commands")
    elseif event == "PLAYER_LOGIN" then
        ns.RegisterActionCommands()
    elseif event == "SPELLS_CHANGED" then
        ns.InvalidateSources("spells")
    elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        ns.InvalidateSources("items")
    elseif event == "UPDATE_MACROS" then
        ns.Window.OnMacrosChanged()
    end
end)

local function OnOff(v) return v and "|cff00ff00on|r" or "|cffff0000off|r" end

SLASH_MACROSENSE1 = "/macrosense"
SLASH_MACROSENSE2 = "/ms"
SLASH_MACROSENSE3 = "/msense" -- in case another addon took /ms
SlashCmdList.MACROSENSE = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "" then
        ns.Window.Toggle()
    elseif msg == "autocomplete" then
        ns.db.enabled = not ns.db.enabled
        ns.Print("autocomplete %s", OnOff(ns.db.enabled))
        if not ns.db.enabled then ns.Popup:Hide() end
    elseif msg == "debug" then
        ns.db.debug = not ns.db.debug
        ns.Print("debug %s", OnOff(ns.db.debug))
    else
        ns.Print("/ms - open the editor; /ms autocomplete | debug - toggle")
    end
end
