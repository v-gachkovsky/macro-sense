local ADDON, ns = ...
_G.MacroSense = ns

local L = ns.L
local PREFIX = "|cff569cd6MacroSense|r: "
-- A chat line; `text` is translated, then filled in like string.format.
function ns.Print(text, ...) print(PREFIX .. string.format(L[text], ...)) end

-- Where players report bugs.
ns.ISSUES_URL = "https://github.com/v-gachkovsky/macro-sense/issues"
ns.EMAIL = "volodymyr.hachkovsky@icloud.com"

-- This character among the account's characters (ns.db.characters, by "Name-Realm"): its name, realm and class,
-- and what is kept for it there (the action bars of each specialization, see ActionBars.lua).
local me
function ns.Character()
    if me then return me end
    local name, realm = UnitName("player"), GetRealmName()
    ns.db.characters = ns.db.characters or {}
    me = ns.db.characters[name .. "-" .. realm] or {}
    me.name, me.realm, me.class = name, realm, select(2, UnitClass("player"))
    ns.db.characters[name .. "-" .. realm] = me
    return me
end

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
    minimapButton = true,
    minimapAngle = 250, -- where on the minimap's edge, in degrees (0 = right, 90 = up)
    language = "en", -- "uk": Ukrainian (Locale.lua)
    wizardForm = nil, -- the wizard opens on its whole form, not its questions one at a time
    welcomeSeen = nil, -- version the early-development note was shown for
}

-- Once per installed version: the addon is young, bug reports are welcome.
local function Welcome()
    local version = Version()
    if ns.db.welcomeSeen == version then return end
    ns.db.welcomeSeen = version
    ns.Print("%s - thanks for trying it! The addon is in early development.", version)
    print(L["  Found a bug or have an idea? Please don't hesitate to tell me: I read every report"])
    print(L["  and try to fix things as fast as I can. Type /ms bug for the details to include."])
    if ns.ISSUES_URL then print(string.format(L["  Report here: %s"], ns.ISSUES_URL)) end
    print(string.format(L["  Or in the comments on CurseForge, or by email: %s"], ns.EMAIL))
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

-- The buffs on you are kept for /cancelaura a second after they change, at most once a second.
local buffsDue
local function RememberBuffsSoon()
    if buffsDue then return end
    buffsDue = true
    C_Timer.After(1, function()
        buffsDue = false
        ns.RememberBuffs()
    end)
end

-- Spells, pets or talents changed: the warnings about spells you don't have follow, in the editor, its list and on
-- the action bars. The game sends several such events at once: at most twice a second.
-- A talent or specialization change also tells of the macros on the bars it broke.
local spellsDue, talentsChanged
local function SpellsChangedSoon(talents)
    ns.InvalidateSources("spells")
    talentsChanged = talentsChanged or talents
    if spellsDue then return end
    spellsDue = true
    C_Timer.After(0.5, function()
        spellsDue = false
        ns.Window.SpellsChanged()
        ns.ActionBars.Tint()
        ns.ActionBars.TellBroken(talentsChanged)
        talentsChanged = false
    end)
end

-- The talent events differ between the clients, and the game refuses those it doesn't have.
local TALENT_EVENTS = { PLAYER_TALENT_UPDATE = true, TRAIT_CONFIG_UPDATED = true, TRAIT_CONFIG_LIST_UPDATED = true,
    CHARACTER_POINTS_CHANGED = true, ACTIVE_TALENT_GROUP_CHANGED = true, ACTIVE_PLAYER_SPECIALIZATION_CHANGED = true }

local f = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "SPELLS_CHANGED", "BAG_UPDATE_DELAYED",
    "PLAYER_EQUIPMENT_CHANGED", "UPDATE_MACROS", "UPDATE_BINDINGS", "ACTIONBAR_SLOT_CHANGED", "UNIT_PET",
    "PET_BAR_UPDATE", "PLAYER_REGEN_ENABLED" }) do
    f:RegisterEvent(e)
end
for e in pairs(TALENT_EVENTS) do pcall(f.RegisterEvent, f, e) end
f:RegisterUnitEvent("UNIT_AURA", "player")
f:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == ADDON then
            MacroSenseDB = MacroSenseDB or {}
            for k, v in pairs(ns.defaults) do
                if MacroSenseDB[k] == nil then MacroSenseDB[k] = v end
            end
            ns.db = MacroSenseDB
            ns.SetLanguage(ns.db.language)
            MacroSenseCharDB = MacroSenseCharDB or {}
            MacroSenseCharDB.petSpells = MacroSenseCharDB.petSpells or {}
            MacroSenseCharDB.buffs = MacroSenseCharDB.buffs or {}
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
        ns.Window.DailyBackup()
        ns.RememberBuffs()
        ns.MinimapButton.Update()
        ns.ActionBars.Setup()
        ns.Links.Setup()
        Welcome()
    elseif event == "UNIT_AURA" then
        RememberBuffsSoon()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Action buttons can't be set up in combat: those made during it are set up now.
        ns.ActionBars.Setup()
    elseif event == "SPELLS_CHANGED" or event == "PET_BAR_UPDATE" or (event == "UNIT_PET" and name == "player")
        or TALENT_EVENTS[event] then
        SpellsChangedSoon(TALENT_EVENTS[event])
    elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        ns.InvalidateSources("items")
    elseif event == "UPDATE_MACROS" then
        ns.History.Scan()
        ns.Shortcuts.Invalidate()
        ns.Window.OnMacrosChanged()
        ns.ActionBars.Tint()
    elseif event == "UPDATE_BINDINGS" or event == "ACTIONBAR_SLOT_CHANGED" then
        ns.Shortcuts.Invalidate()
        ns.Window.RefreshStatus()
        ns.ActionBars.Tint()
    end
end)

local function OnOff(v) return v and L["|cff00ff00on|r"] or L["|cffff0000off|r"] end

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
    elseif msg == "help" then
        ns.HelpWindow.Open()
    elseif msg == "minimap" then
        ns.Print("minimap button %s", OnOff(ns.MinimapButton.Toggle()))
    elseif msg == "bug" then
        -- Everything a bug report needs, ready to copy.
        local build, _, _, toc = GetBuildInfo()
        ns.Print("bug report details:")
        print(string.format("  MacroSense %s, WoW %s (%s), %s", Version(), build, toc,
            IsMacClient and IsMacClient() and "Mac" or "Windows"))
        print(L["  Please describe what you did, what you expected and what happened; a screenshot helps."])
        if ns.ISSUES_URL then print(string.format(L["  Report here: %s"], ns.ISSUES_URL)) end
        print(string.format(L["  Or in the comments on CurseForge, or by email: %s"], ns.EMAIL))
    elseif msg == "debug" then
        ns.db.debug = not ns.db.debug
        ns.Print("debug %s", OnOff(ns.db.debug))
    else
        ns.Print("/ms - open the editor; /ms help - macros in short; /ms minimap - hide or show the minimap button; "
            .. "/ms bug - details for a bug report; /ms autocomplete | debug - toggle")
    end
end
