local ADDON, ns = ...
_G.MacroSense = ns

local L_PREFIX = "|cff569cd6MacroSense|r: "
function ns.Print(...) print(L_PREFIX .. string.format(...)) end

-- Where players report bugs.
ns.ISSUES_URL = "https://github.com/v-gachkovsky/macro-sense/issues"

local Metadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local function Version()
    local v = Metadata(ADDON, "Version")
    return (not v or v:find("@")) and "dev" or v
end

ns.defaults = {
    enabled = true, -- autocomplete
    debug = false,  -- print key events of the editor
    font = ns.DEFAULT_FONT,
    fontSize = 13,
    scheme = ns.DEFAULT_SCHEME,
    scope = "general",
    preview = true, -- the live preview column
    welcomeSeen = nil, -- version the early-development note was shown for
}

-- Once per installed version: the addon is young, bug reports are welcome.
local function Welcome()
    local version = Version()
    if ns.db.welcomeSeen == version then return end
    ns.db.welcomeSeen = version
    ns.Print("%s - thanks for trying it! The addon is in early development.", version)
    print("  Found a bug or have an idea? Please don't hesitate to tell me: I read every report")
    print("  and try to fix things as fast as I can. Type /ms bug for the details to include.")
    if ns.ISSUES_URL then print("  Report here: " .. ns.ISSUES_URL) end
end

local IsLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

-- "MacroSense" button in the title bar of the Blizzard macro window, left of its close button.
local function AddMacroFrameButton()
    if not MacroFrame or ns.macroFrameButton then return end
    local b = CreateFrame("Button", nil, MacroFrame, "UIPanelButtonTemplate")
    b:SetSize(80, 18) -- the title bar is about 18 px high
    b:SetText("MacroSense")
    b:SetNormalFontObject(GameFontNormalSmall)
    b:SetHighlightFontObject(GameFontHighlightSmall)
    local close = MacroFrame.CloseButton or MacroFrameCloseButton
    if close then
        b:SetPoint("RIGHT", close, "LEFT", 2, 0)
        b:SetFrameLevel(close:GetFrameLevel())
    else
        b:SetPoint("TOPRIGHT", MacroFrame, "TOPRIGHT", -26, -3)
    end
    b:SetScript("OnClick", function() ns.Window.Toggle() end)
    ns.macroFrameButton = b
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "SPELLS_CHANGED", "BAG_UPDATE_DELAYED",
    "PLAYER_EQUIPMENT_CHANGED", "UPDATE_MACROS", "UPDATE_BINDINGS", "ACTIONBAR_SLOT_CHANGED", "UNIT_PET",
    "PET_BAR_UPDATE" }) do
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
            MacroSenseCharDB = MacroSenseCharDB or {}
            MacroSenseCharDB.petSpells = MacroSenseCharDB.petSpells or {}
            ns.char = MacroSenseCharDB
            if IsLoaded("Blizzard_MacroUI") then AddMacroFrameButton() end
        elseif name == "Blizzard_MacroUI" then
            AddMacroFrameButton()
        end
        -- New addons may register new slash commands.
        ns.InvalidateSources("commands")
    elseif event == "PLAYER_LOGIN" then
        ns.RegisterActionCommands()
        ns.History.Scan()
        Welcome()
    elseif event == "SPELLS_CHANGED" or event == "PET_BAR_UPDATE" or (event == "UNIT_PET" and name == "player") then
        ns.InvalidateSources("spells")
    elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        ns.InvalidateSources("items")
    elseif event == "UPDATE_MACROS" then
        ns.History.Scan()
        ns.Shortcuts.Invalidate()
        ns.Window.OnMacrosChanged()
    elseif event == "UPDATE_BINDINGS" or event == "ACTIONBAR_SLOT_CHANGED" then
        ns.Shortcuts.Invalidate()
        ns.Window.RefreshStatus()
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
    elseif msg == "bug" then
        -- Everything a bug report needs, ready to copy.
        local build, _, _, toc = GetBuildInfo()
        ns.Print("bug report details:")
        print(string.format("  MacroSense %s, WoW %s (%s), %s", Version(), build, toc,
            IsMacClient and IsMacClient() and "Mac" or "Windows"))
        print("  Please describe what you did, what you expected and what happened; a screenshot helps.")
        if ns.ISSUES_URL then print("  Report here: " .. ns.ISSUES_URL) end
    elseif msg == "debug" then
        ns.db.debug = not ns.db.debug
        ns.Print("debug %s", OnOff(ns.db.debug))
    else
        ns.Print("/ms - open the editor; /ms bug - details for a bug report; /ms autocomplete | debug - toggle")
    end
end
