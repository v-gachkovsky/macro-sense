local ADDON, ns = ...
_G.MacroSense = ns

local L = ns.L
local PREFIX = "|cff569cd6MacroSense|r: "
-- A chat line; `text` is translated, then filled in like string.format.
function ns.Print(text, ...) print(PREFIX .. string.format(L[text], ...)) end
-- A chat line already translated and filled in.
function ns.Say(text) print(PREFIX .. text) end

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
    -- The click on a macro on an action bar that opens it in the editor (ActionBars.lua; the settings, Options.lua).
    barEdit = true,
    barEditKeys = "shift", -- ActionBars.KEYS
    barEditButton = "RightButton",
    tagKeys = "ctrl-alt", -- held with a click on a creature or player: its name into the tag macro (Tag.lua)
    -- MacroSense instead of the game's macro window: from "Macros" in the game menu, with /macro (the settings).
    gameMenu = true,
    macroCommand = false,
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

-- The macro chosen in the Blizzard macro window, or nil.
local function ChosenInMacroFrame()
    local ok, index = pcall(function() return MacroFrame:GetMacroDataIndex(MacroFrame:GetSelectedIndex()) end)
    return ok and type(index) == "number" and GetMacroInfo(index) and index or nil
end

-- "MacroSense" button in the title bar of the Blizzard macro window, left of its close button: MacroSense opens on
-- the macro chosen there, in front, whether it was open or not. The game's window closes, saving what was typed in
-- it: its macros and buttons are drawn above other windows, so left open they would cover MacroSense.
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
    b:SetScript("OnClick", function()
        local index = ChosenInMacroFrame()
        HideUIPanel(MacroFrame)
        if index then ns.Window.Open(index) else ns.Window.Show() end
    end)
    ns.macroFrameButton = b
end

-- "Macros" in the game menu and /macro open MacroSense instead of the game's macro window, each as chosen in the
-- settings. Both call the game's ShowMacroFrame: /macro is told apart while it runs. The chat runs a command from
-- its own table once it was used: /macro there is changed too.
local function OpenInstead()
    local show, macro = ShowMacroFrame, SlashCmdList.MACRO
    if not show then return end
    local typed = false
    ShowMacroFrame = function(...)
        if typed and ns.db.macroCommand or not typed and ns.db.gameMenu then return ns.Window.Show() end
        return show(...)
    end
    if not macro then return end
    SlashCmdList.MACRO = function(...)
        typed = true
        local ok, err = pcall(macro, ...)
        typed = false
        if not ok then error(err, 0) end
    end
    for command, fn in pairs(hash_SlashCmdList or {}) do
        if fn == macro then hash_SlashCmdList[command] = SlashCmdList.MACRO end
    end
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
        ns.RememberPet() -- for [pet:] later, when it is no longer out
        ns.Window.SpellsChanged()
        ns.ActionBars.Tint()
        ns.ActionBars.TellBroken(talentsChanged)
        ns.Ranks.Update()
        ns.Sets.LearnSpells() -- which macros work in this specialization
        ns.Sets.Update() -- another specialization: its macros
        talentsChanged = false
    end)
end

-- The talent events differ between the clients, and the game refuses those it doesn't have.
local TALENT_EVENTS = { PLAYER_TALENT_UPDATE = true, TRAIT_CONFIG_UPDATED = true, TRAIT_CONFIG_LIST_UPDATED = true,
    CHARACTER_POINTS_CHANGED = true, ACTIVE_TALENT_GROUP_CHANGED = true, ACTIVE_PLAYER_SPECIALIZATION_CHANGED = true }

-- The macros changed: what depends on them, again.
function ns.MacrosChanged()
    ns.History.Scan()
    ns.Sets.Scan()
    ns.Shortcuts.Invalidate()
    ns.Window.OnMacrosChanged()
    ns.ActionBars.Tint()
    ns.SetsWindow.Refresh()
end

-- Bindings or what is on the action bars changed: the keys, the status bar and the buttons' tints follow.
local function BarsChanged()
    ns.Shortcuts.Invalidate()
    ns.Window.RefreshStatus()
    ns.ActionBars.Tint()
end
-- The game changes many slots at once (all of them with a specialization, at login): once, the next frame.
local barsDue
local function BarsChangedSoon()
    if barsDue then return end
    barsDue = true
    C_Timer.After(0, function()
        barsDue = false
        BarsChanged()
    end)
end

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
            MacroSenseCharDB.pets = MacroSenseCharDB.pets or {}
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
        ns.Ranks.Update()
        ns.Window.DailyBackup()
        ns.Sets.Update()
        ns.RememberBuffs()
        ns.MinimapButton.Update()
        ns.ActionBars.Setup()
        ns.Options.Setup()
        ns.Links.Setup()
        OpenInstead()
        Welcome()
    elseif event == "UNIT_AURA" then
        RememberBuffsSoon()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Action buttons and macros can't be changed in combat: what waited for it is done now. Macros saved in
        -- combat go in first, so the macro sets see them as they are now.
        ns.Window.CombatEnded()
        ns.ActionBars.Setup()
        ns.Ranks.Update()
        if ns.Sets.Pending() then ns.Sets.Update() end
    elseif event == "SPELLS_CHANGED" or event == "PET_BAR_UPDATE" or (event == "UNIT_PET" and name == "player")
        or TALENT_EVENTS[event] then
        SpellsChangedSoon(TALENT_EVENTS[event])
    elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        ns.InvalidateSources("items")
    elseif event == "UPDATE_MACROS" then
        if ns.Sets.Busy() then return end -- MacroSense changes the slots now: learned when it is done
        ns.MacrosChanged()
    elseif event == "UPDATE_BINDINGS" then
        BarsChanged()
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        BarsChangedSoon()
    end
end)

local function OnOff(v) return v and L["|cff00ff00on|r"] or L["|cffff0000off|r"] end

-- /ms sets: macro sets on or off, a macro into a layer, the layers. Until the sets have a window of their own.
local SETS_LAYERS = { class = "class", char = "character", character = "character", spec = "spec" }
local function LayerName(layer)
    return layer == "class" and L["Class macros"] or layer == "character" and L["This character's"]
        or L["This specialization's"]
end
local function SetsCommand(args)
    local word, rest = args:match("^(%S*)%s*(.-)$")
    word = word:lower()
    if word == "debug" then
        for _, line in ipairs(ns.Sets.Debug()) do print("  " .. line) end
    elseif word == "log" then
        for _, line in ipairs(ns.Sets.Log()) do print("  " .. line) end
    elseif word == "on" or word == "off" then
        local ok, why = (word == "on" and ns.Sets.Enable or ns.Sets.Disable)()
        if not ok then return ns.Window.Told(ok, why) end -- in combat
        ns.Print("macro sets %s", OnOff(word == "on"))
    elseif SETS_LAYERS[word] and rest ~= "" then
        if ns.Sets.Move(rest, SETS_LAYERS[word]) then
            ns.Print("\"%s\" is in this layer now: %s", rest, LayerName(SETS_LAYERS[word]))
        else
            ns.Print("no macro \"%s\" in this character's slots (macro sets on?)", rest)
        end
    elseif word == "" then
        ns.SetsWindow.Toggle()
    else
        ns.Print("macro sets %s", OnOff(ns.Sets.Mine().enabled))
        for _, l in ipairs(ns.Sets.Describe()) do
            print(string.format("  %s: %s", LayerName(l.layer), #l.names > 0 and table.concat(l.names, ", ") or "-"))
        end
    end
end

-- /ms conditions: which conditions this game client doesn't know, by its own check: for a bug report, or a new client.
-- Asked about each one (Conditions.Ask), the game names in the chat those it doesn't know: as system lines, kept out
-- of the chat while it's asked, or right into a chat window. They're told in one line a moment later: the game may
-- say them a frame late.
local heard -- the game's lines in the chat while it's asked; nil: not asked now
local function Hear(line)
    if heard and type(line) == "string" then heard[#heard + 1] = line end
end
local listen = CreateFrame("Frame")
listen:SetScript("OnEvent", function(_, _, line) Hear(line) end)
local filtered, hooked = false, {}
local function Listen()
    heard = {}
    listen:RegisterEvent("CHAT_MSG_SYSTEM")
    local AddFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
    if AddFilter and not filtered then
        filtered = true
        AddFilter("CHAT_MSG_SYSTEM", function(_, _, line)
            Hear(line) -- the chat may have it before MacroSense does
            return heard ~= nil and type(line) == "string" and ns.Conditions.Answer(heard, line)
        end)
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local chat = _G["ChatFrame" .. i]
        if chat and not hooked[chat] then
            hooked[chat] = true
            hooksecurefunc(chat, "AddMessage", function(_, line) Hear(line) end)
        end
    end
end
local function ConditionsCommand()
    if heard then return end -- asked already: the answer comes in a moment
    if not SecureCmdOptionParse then return ns.Print("this game doesn't tell which conditions it knows") end
    Listen()
    ns.Conditions.Ask(SecureCmdOptionParse)
    C_Timer.After(0.5, function()
        local unknown = ns.Conditions.Unknown(heard)
        heard = nil
        listen:UnregisterEvent("CHAT_MSG_SYSTEM")
        if not unknown then
            ns.Print("this game doesn't tell which conditions it knows")
        elseif #unknown == 0 then
            ns.Print("this game knows every condition MacroSense offers")
        else
            ns.Print("conditions this game doesn't know: %s", "[" .. table.concat(unknown, "], [") .. "]")
        end
    end)
end

SLASH_MACROSENSE1 = "/macrosense"
SLASH_MACROSENSE2 = "/ms"
SLASH_MACROSENSE3 = "/msense" -- in case another addon took /ms
SlashCmdList.MACROSENSE = function(msg)
    local raw = (msg or ""):match("^%s*(.-)%s*$")
    msg = raw:lower()
    if msg == "" then
        ns.Window.Toggle()
    elseif msg == "autocomplete" then
        ns.db.enabled = not ns.db.enabled
        ns.Print("autocomplete %s", OnOff(ns.db.enabled))
        if not ns.db.enabled then ns.Popup:Hide() end
    elseif msg == "help" then
        ns.HelpWindow.Open()
    elseif msg == "book" then
        ns.SpellbookWindow.Open()
    elseif msg == "settings" then
        ns.Options.Open()
    elseif msg == "conditions" then
        ConditionsCommand()
    elseif msg == "sets" or msg:find("^sets ") then
        SetsCommand(raw:match("^%S+%s*(.*)$"))
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
        ns.Print("/ms - open the editor; /ms help - the macro guide; /ms book - macros from the spellbook; /ms sets - macro sets; "
            .. "/ms settings - settings; /ms minimap - hide or show the minimap button; /ms bug - details for a bug report; "
            .. "/ms autocomplete | debug - toggle")
    end
end
