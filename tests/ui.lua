-- Loads the whole addon against a tiny fake WoW API and drives the editor like a player would.
-- `lua tests/ui.lua` from the repo root. It catches load errors and logic bugs, not layout.
local now, timers = 0, {} -- timers: { at = time, fn = function }
local created = {} -- every frame, so tests can find anonymous ones (Core's event frame, the editor)
-- Shown, and so are the frames it is in: only then the game runs its OnUpdate.
local function Visible(o)
    while o do
        if not o.shown then return false end
        o = o.parentFrame
    end
    return true
end
local function NextFrame()
    now = now + 0.016
    local due, later = {}, {}
    for _, t in ipairs(timers) do table.insert(t.at <= now and due or later, t) end
    timers = later
    for _, t in ipairs(due) do t.fn() end
    for _, o in ipairs(created) do
        if o.scripts.OnUpdate and Visible(o) then o.scripts.OnUpdate(o, 0.016) end
    end
end

------------------------------------------------------------------------
-- Fake frames
------------------------------------------------------------------------
local Frame = {}
local focused

local function New(kind, name)
    local o = setmetatable({ kind = kind, scripts = {}, shown = true, text = "", cursor = 0, enabled = true }, Frame)
    if name then _G[name] = o end
    created[#created + 1] = o
    return o
end

local function Fire(o, script, ...)
    local fn = o.scripts[script]
    if fn then return fn(o, ...) end
end

function Frame:__index(k)
    local m = rawget(Frame, k)
    if m then return m end
    if k:find("^%u") then return function() end end -- every other widget method is a no-op
end
function Frame:SetScript(s, fn) self.scripts[s] = fn end
-- Like the game, an event this client doesn't have is refused: this one has no CHARACTER_POINTS_CHANGED.
local NO_SUCH_EVENTS = { CHARACTER_POINTS_CHANGED = true }
function Frame:RegisterEvent(e)
    if NO_SUCH_EVENTS[e] then error("Attempt to register unknown event \"" .. e .. "\"") end
    self.events = self.events or {}
    self.events[e] = true
end
function Frame:RegisterUnitEvent(e, unit)
    self.unitEvents = self.unitEvents or {}
    self.unitEvents[e] = unit
end
function Frame:GetScript(s) return self.scripts[s] end
function Frame:HookScript(s, fn)
    local old = self.scripts[s]
    self.scripts[s] = function(...)
        if old then old(...) end
        return fn(...)
    end
end
function Frame:Show() if not self.shown then self.shown = true; Fire(self, "OnShow") end end
function Frame:Hide() if self.shown then self.shown = false; Fire(self, "OnHide") end end
function Frame:SetShown(v) if v then self:Show() else self:Hide() end end
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown end
function Frame:CreateTexture()
    local t = New("Texture")
    t.parentFrame = self
    return t
end
function Frame:CreateFontString()
    local fs = New("FontString")
    fs.parentFrame = self
    return fs
end
function Frame:GetWidth() return 300 end
function Frame:GetHeight() return 200 end
function Frame:GetFrameLevel() return 1 end
function Frame:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function Frame:IsMouseOver() return false end
function Frame:GetParent() return self.parentFrame end
-- Fonts: a character is 0.6 of the size wide, a row is size + 1 high (size 13: 8 x 14 px).
function Frame:SetFont(path, size) self.fontPath, self.fontSize = path, size; return true end
function Frame:GetFont() return "font", self.fontSize or 13, "" end
local function charWidth(fs) return math.floor((fs.fontSize or 13) * 0.6 + 0.5) end
local function rowHeight(fs) return (fs.fontSize or 13) + 1 end
function Frame:GetMaxLetters() return self.maxLetters or 0 end
function Frame:SetMaxLetters(n) self.maxLetters = n end
function Frame:IsEnabled() return self.enabled end
function Frame:SetEnabled(v) self.enabled = v and true or false end
function Frame:SetText(t)
    self.text = t or ""
    if self.kind == "EditBox" then
        self.cursor = math.min(self.cursor, #self.text)
        Fire(self, "OnTextChanged", false)
    end
end
function Frame:GetText() return self.text end
function Frame:SetTexture(t) self.texture = t end
function Frame:GetValue() return self.value or 0 end
function Frame:GetVerticalScrollRange() return self.range or 0 end
function Frame:GetVerticalScroll() return self.vscroll or 0 end
function Frame:SetVerticalScroll(v) self.vscroll = v; Fire(self, "OnVerticalScroll", v) end
function Frame:SetValue(v) self.value = v; Fire(self, "OnValueChanged", v) end
function Frame:HasFocus() return focused == self end
function Frame:SetFocus() focused = self end
function Frame:ClearFocus() if focused == self then focused = nil; Fire(self, "OnEditFocusLost") end end
function Frame:GetCursorPosition() return self.cursor end
local cursorEventsLate = false -- like the real game seems to: OnCursorChanged comes a frame later
function Frame:SetCursorPosition(pos)
    self.cursor = pos
    local line = select(2, self.text:sub(1, pos):gsub("\n", ""))
    local h = rowHeight(self)
    if cursorEventsLate then
        timers[#timers + 1] = { at = now, fn = function() Fire(self, "OnCursorChanged", 0, -line * h, 2, h) end }
    else
        Fire(self, "OnCursorChanged", 0, -line * h, 2, h)
    end
end
-- FontString measuring: 8 px per character, 14 px high; one row unless wrapLines is on.
local wrapLines = false
function Frame:SetWidth(w) self.width = w end
function Frame:SetHeight(h) self.height = h end
function Frame:GetUnboundedStringWidth() return #tostring(self.text) * charWidth(self) end
function Frame:GetStringWidth() return #tostring(self.text) * charWidth(self) end
function Frame:GetNumLines()
    if wrapLines and self.width and self.width > 0 then
        return math.max(1, math.ceil(#self.text * charWidth(self) / self.width))
    end
    return 1
end
function Frame:GetStringHeight()
    return (select(2, tostring(self.text):gsub("\n", "")) + 1) * rowHeight(self)
end
function Frame:SetPoint(...) self.point = { ... } end
function Frame:GetLeft() return self.left end
function Frame:SetTextColor(r, g, b)
    self.textColor = string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end
function Frame:SetVertexColor(r, g, b)
    self.vertexColor = string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end
function Frame:SetColorTexture(r, g, b)
    self.color = string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end
function Frame:GetTop() return self.top end
function Frame:IsObjectType(kind) return self.kind == kind end
function Frame:GetRight() return self.right end

function CreateFrame(kind, name, parent)
    local o = New(kind, name)
    o.parentFrame = parent
    return o
end
UIParent = New("Frame")

------------------------------------------------------------------------
-- Fake game API
------------------------------------------------------------------------
function GetTime() return now end
-- Wall clock for saved versions: Oct 23 2026, 14:32 (local time); tests move it on.
local clock = os.time({ year = 2026, month = 10, day = 23, hour = 14, min = 32 })
function time() return clock end
function date(fmt, t) return os.date(fmt, t or clock) end
function IsMacClient() return true end
function GetLocale() return "enUS" end
local reloads = 0
function ReloadUI() reloads = reloads + 1 end
C_AddOns = { IsAddOnLoaded = function() return false end, GetAddOnMetadata = function() return "@project-version@" end }
function GetBuildInfo() return "12.1.5", "60000", "Oct 1 2026", 120105 end
C_Timer = { After = function(delay, fn) timers[#timers + 1] = { at = now + delay, fn = fn } end }
-- The player's buffs, and the values Retail hides from addons.
local auras, auraReads, secret = {}, 0, {}
C_UnitAuras = {
    GetAuraDataByIndex = function(unit, i, filter)
        auraReads = auraReads + 1
        if unit == "player" and filter == "HELPFUL" then return auras[i] end
    end,
}
function issecretvalue(v) return secret[v] == true end
local function Wait(seconds)
    local stop = now + seconds
    while now < stop do NextFrame() end
end
function IsControlKeyDown() return false end
function IsShiftKeyDown() return false end
function IsMouseButtonDown() return false end
function InCombatLockdown() return false end
local onScreen = {} -- UIErrorsFrame's messages: { text, r, g, b }
UIErrorsFrame = { AddMessage = function(_, text, r, g, b) onScreen[#onScreen + 1] = { text = text, r = r, g = g, b = b } end }
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local printed = {}
function print(s) printed[#printed + 1] = s end
local reported = {} -- errors the addon hands to the game's error handler
function geterrorhandler() return function(e) reported[#reported + 1] = e end end
UISpecialFrames, StaticPopupDialogs = {}, {}
function StaticPopup_Show(which, _, _, data) StaticPopupDialogs[which].OnAccept(nil, data) end
YES, NO, CANCEL, DELETE = "Yes", "No", "Cancel", "Delete"
-- Macro slots, where Retail keeps them (the Classic clients have them as globals).
Constants = { MacroConsts = { MAX_ACCOUNT_MACROS = 120, MAX_CHARACTER_MACROS = 30 } }
local SLOTS = Constants.MacroConsts

-- Like the game: the list of secure commands is hidden from addons, IsSecureCmd("/cast") tells.
SlashCmdList, ChatTypeInfo = {}, { SAY = true }
SLASH_CAST1, SLASH_USE1, SLASH_TARGET1, SLASH_SAY1 = "/cast", "/use", "/target", "/say"
SLASH_PET_MOVE_TO1, SLASH_TEAM_QUIT1 = "/petmoveto", "/teamquit" -- this client has no /teamquit
local secureKeys = { CAST = true, USE = true, TARGET = true, PET_MOVE_TO = true }
function IsSecureCmd(command)
    command = command:upper()
    for key in pairs(secureKeys) do
        local i = 1
        while _G["SLASH_" .. key .. i] do
            if _G["SLASH_" .. key .. i]:upper() == command then return true end
            i = i + 1
        end
    end
end
EMOTE1_TOKEN, EMOTE1_CMD1 = "DANCE", "/dance"

Enum = { SpellBookSpellBank = { Player = 0, Pet = 1 }, SpellBookItemType = { Spell = 1, FutureSpell = 2 } }
local petBook = {} -- names of the pet's spells; empty = no pet
local book = { -- name, rank: Classic lists every learned rank
    { "Fireball", "Rank 1" }, { "Fireball", "Rank 2" }, { "Fireball", "Rank 3" },
    { "Fire Blast", "" }, { "Frostbolt", "Rank 1" }, { "Polymorph", "" },
}
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 1 end,
    GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #book } end,
    HasPetSpells = function() return #petBook > 0 and #petBook or nil end,
    GetSpellBookItemName = function(i, bank) if bank == 1 then return petBook[i] end end,
    GetSpellBookItemInfo = function(slot)
        return { name = book[slot][1], subName = book[slot][2], itemType = 1, isPassive = false, iconID = slot }
    end,
}
local bag = { "|cffffffff|Hitem:5512::|h[Healthstone]|h|r", "|cff0070dd|Hitem:1234::|h[Fire Ring]|h|r" }
C_Container = {
    GetContainerNumSlots = function(b) return b == 0 and #bag or 0 end,
    GetContainerItemLink = function(b, s) return b == 0 and bag[s] or nil end,
}
C_Item = {
    GetItemSpell = function(link) return link:find("5512") and "Healthstone" or nil end,
    IsEquippableItem = function(link) return link:find("1234") ~= nil end,
    GetItemIconByID = function(id) return id end,
    GetItemCount = function() return 1 end,
    -- Item 2411 is a mount (Miscellaneous, Mount).
    GetItemInfoInstant = function(link)
        local id = tonumber(link:match("item:(%d+)"))
        return id, nil, nil, nil, id, id == 2411 and 15 or 0, id == 2411 and 5 or 0
    end,
    IsHelpfulItem = function(item) return item == "Healthstone" end,
    IsHarmfulItem = function() return false end,
}
-- Whether a spell is for friends or enemies; a name the game doesn't know it refuses.
-- The game's spells by ID, known or not (icon names): icon, name.
local gameSpells = { [5782] = { 1050, "Fear" }, [5484] = { 1050, "Howl of Terror" }, [6789] = { 1051, "Death Coil" },
    [9000] = { 1052, "Страх" } }
C_Spell = {
    IsSpellHarmful = function(name)
        if name == "Divine Hymn" then error("unknown spell") end
        return name == "Fireball" or name == "Fire Blast" or name == "Frostbolt" or name == "Holy Shock"
    end,
    IsSpellHelpful = function(name) return name == "Flash Heal" or name == "Holy Shock" end,
    -- Range "Self": it goes to nobody but you.
    SpellHasRange = function(name) return name ~= "Demon Armor" end,
    GetSpellTexture = function(id) return gameSpells[id] and gameSpells[id][1] end,
    GetSpellName = function(id) return gameSpells[id] and gameSpells[id][2] end,
    GetSpellLevelLearned = function(id) return id == 30283 and 40 or 0 end, -- Shadowfury, learned later
}
-- The talents of the Classic clients, one a query: tests set talentInfo (nil: no talents).
local talentInfo
C_SpecializationInfo = {
    GetTalentInfo = function(query) return talentInfo and talentInfo(query) end,
    GetActiveSpecGroup = function() return 1 end,
}
function debugprofilestop() return os.clock() * 1000 end
-- Gear: a trinket in slot 13 (no use effect, can't be equipped from the bags).
function GetInventoryItemLink(_, slot) if slot == 13 then return "|cffa335ee|Hitem:777::|h[Lucky Charm]|h|r" end end
-- Action slots: kind, ID, sub type and the text the button shows. Macro 1 shows Fireball: the game gives the
-- slot Fireball's ID, not the macro's.
local bindings, actions = { ACTIONBUTTON1 = "Q" }, { [1] = { "macro", 133, "spell" } }
function GetBindingKey(command) return bindings[command] end
local picked
function PickupMacro(index) picked = index end
-- The macro on the cursor goes onto the slot it is dropped on; what was there is left on the cursor.
function PlaceAction(slot)
    if picked then actions[slot] = { "macro", 0, nil, text = (GetMacroInfo(picked)) } end
end
-- What the mouse holds besides a macro: { "spell", index, book, id } or { "item", id }, set by a test.
local onCursor
function GetCursorInfo()
    if onCursor then return table.unpack(onCursor) end
end
function ClearCursor() picked, onCursor = nil, nil end
-- Shift-click on a link: the game passes it here (into the chat being typed).
function ChatEdit_InsertLink() return false end
-- This character, and the group it is in: none, unless a test fills `group` ({ raid = true in a raid, members =
-- { { name, realm, role = "TANK", mainTank = true } }, me = your role }). In a raid you are raid1, the members after
-- you.
local group = { members = {} }
local function Member(unit)
    local kind, i = unit:match("^(%a+)(%d+)$")
    i = tonumber(i)
    if kind == "party" and not group.raid then return group.members[i] end
    if kind == "raid" and group.raid then return i == 1 and "player" or group.members[i - 1] end
end
function UnitName(unit)
    if unit == "player" or Member(unit) == "player" then return "Tester" end
    local m = Member(unit)
    if m then return m.name, m.realm end
end
function IsInRaid() return group.raid == true end
function GetNumGroupMembers() return #group.members > 0 and #group.members + 1 or 0 end
function GetNumSubgroupMembers() return #group.members end
function UnitIsUnit(a, b) return a == b or (b == "player" and Member(a) == "player") end
function UnitGroupRolesAssigned(unit)
    local m = Member(unit)
    if unit == "player" or m == "player" then return group.me or "NONE" end
    return type(m) == "table" and m.role or "NONE"
end
function GetPartyAssignment(assignment, unit)
    local m = Member(unit)
    return assignment == "MAINTANK" and type(m) == "table" and m.mainTank == true
end
function GetRealmName() return "Realm" end
UNKNOWNOBJECT = "Unknown" -- a player's name before the game knows it
function UnitClass(unit) if unit == "player" then return "Warlock", "WARLOCK" end end
function GetActionInfo(slot) if actions[slot] then return actions[slot][1], actions[slot][2], actions[slot][3] end end
function GetMacroIcons(t) for i = 1, 300 do t[#t + 1] = 1000 + i end end
function GetMacroItemIcons(t) t[#t + 1] = "INV_Sword_01" end
-- Icons the player put in Interface\Icons: file names.
function GetLooseMacroIcons(t) t[#t + 1] = "My_Skull" end
function GetLooseMacroItemIcons(t) t[#t + 1] = "My_Potion" end
GameTooltip = New("GameTooltip")
function GameTooltip:SetOwner(owner) self.owner = owner end
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:SetAction(slot) return actions[slot] ~= nil end
function hooksecurefunc(t, name, hook)
    if type(t) == "string" then t, name, hook = _G, t, name end
    local original = t[name]
    t[name] = function(...)
        local r = table.pack(original(...))
        hook(...)
        return table.unpack(r, 1, r.n)
    end
end

-- Action buttons. The game's own register with ActionBarButtonEventsFrame, those of LibActionButton (Bartender,
-- ElvUI) are in its registry. `ran` counts the clicks that reach a button's own OnClick. A macro that shows a
-- spell gives that spell's ID as the game does: { "macro", spellID, "spell", text = macro name }.
C_ActionBar = { GetActionText = function(slot) return actions[slot] and actions[slot].text end }
local barPage = 1
local function ActionButton(id, attributes, parent)
    local b = New("CheckButton")
    b.id, b.attributes, b.parent, b.ran = id, attributes, parent, 0
    b.scripts.OnClick = function(self) self.ran = self.ran + 1 end
    b.icon = b:CreateTexture()
    function b:Update() end -- the game's: when the button's action changes
    return b
end
ActionBarButtonEventsFrame = { frames = {} }
function ActionBarButtonEventsFrame:RegisterFrame(b) table.insert(self.frames, b) end
local lab = { buttonRegistry = {} } -- LibActionButton-1.0; RegisterCallback keeps the function by event
function lab.RegisterCallback(_, event, fn) lab[event] = fn end
function LibStub(name) if name == "LibActionButton-1.0" then return lab end end
-- The game's click wrap (SecureHandlers.lua): the snippet runs before the button's own OnClick, with handles
-- of the button as `self` and of the header as `control`; false stops the click there.
local function Attribute(frame, name)
    local v = frame.attributes and frame.attributes[name]
    if v == nil and frame.attributes and frame.attributes["useparent-" .. name] and frame.parent then
        return Attribute(frame.parent, name)
    end
    return v
end
local function Handle(frame)
    return {
        GetID = function() return frame.id or 0 end,
        GetEffectiveAttribute = function(_, name) return Attribute(frame, name) end,
        -- Out of the secure code; the game hands its errors to the error handler.
        CallMethod = function(_, method, ...)
            local ok, err = pcall(frame[method], frame, ...)
            if not ok then geterrorhandler()(err) end
        end,
    }
end
function SecureHandlerWrapScript(frame, script, header, preBody)
    if frame.forbidden then error("Cannot use SecureHandlers API on forbidden frames") end
    local env = {
        IsShiftKeyDown = function() return IsShiftKeyDown() end,
        GetActionBarPage = function() return barPage end,
        GetActionInfo = function(slot) return GetActionInfo(slot) end,
    }
    local body = assert(load("local self, button, down = ...\n" .. preBody, "=PRE_CLICK", "t", env))
    local inner = frame.scripts[script]
    frame.scripts[script] = function(f, button, down, ...)
        env.control = Handle(header)
        if body(Handle(f), button, down) == false then return end
        return inner(f, button, down, ...)
    end
end
-- On the main bar from the start: its page is the game's, the button's ID is its slot on it.
local mainBar = New("Frame")
mainBar.attributes = {}
local startButton = ActionButton(2, { type = "action", ["useparent-actionpage"] = true }, mainBar)
ActionBarButtonEventsFrame:RegisterFrame(startButton)
local labButton = ActionButton(0, { type = "action", action = 100 })
lab.buttonRegistry[labButton] = true
-- A round minimap 140 px wide, its center at 1000, 600 on the screen; the mouse moves in tests.
Minimap = New("Frame", "Minimap")
function Minimap:GetWidth() return 140 end
function Minimap:GetHeight() return 140 end
function Minimap:GetCenter() return 1000, 600 end
function Minimap:GetEffectiveScale() return 1 end
local cursorX, cursorY = 0, 0
function GetCursorPosition() return cursorX, cursorY end
-- The game's condition check, for a state the tests change: modifiers held, units, pet, combat.
local game = { mods = {}, units = {} }
SecureCmdOptionParse = dofile("tests/fakeparse.lua")(game)

local macros = {} -- index -> { name, icon, body }
local function sorted(perChar)
    local out = {}
    for _, m in ipairs(macros) do if m.perChar == perChar then out[#out + 1] = m end end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end
local function byIndex(index)
    if index > SLOTS.MAX_ACCOUNT_MACROS then return sorted(true)[index - SLOTS.MAX_ACCOUNT_MACROS] end
    return sorted(false)[index]
end
local function indexOf(m)
    local list = sorted(m.perChar)
    for i, x in ipairs(list) do if x == m then return m.perChar and i + SLOTS.MAX_ACCOUNT_MACROS or i end end
end
function GetNumMacros() return #sorted(false), #sorted(true) end
-- The icon a macro shows now (m.shown: the question mark shows the #showtooltip spell's), the one chosen.
function GetMacroInfo(index)
    local m = byIndex(index)
    if m then return m.name, m.shown or m.icon, m.body end
end
C_Macro = { GetSelectedMacroIcon = function(index) return byIndex(index) and byIndex(index).icon end }
function CreateMacro(name, icon, body, perChar)
    local m = { name = name, icon = icon, body = body, perChar = perChar and true or false }
    macros[#macros + 1] = m
    return indexOf(m)
end
-- Like the game: nil keeps the name, the icon or the text as it is.
function EditMacro(index, name, icon, body)
    local m = byIndex(index)
    m.name, m.icon, m.body = name or m.name, icon or m.icon, body or m.body
    return indexOf(m)
end
function DeleteMacro(index)
    local m = byIndex(index)
    for i, x in ipairs(macros) do if x == m then table.remove(macros, i) end end
end
function GetMacroIndexByName(name)
    for _, m in ipairs(macros) do if m.name == name then return indexOf(m) end end
    return 0
end

------------------------------------------------------------------------
-- Tests
------------------------------------------------------------------------
local failed, passed = 0, 0
local function check(name, cond, detail)
    if cond then passed = passed + 1 else
        failed = failed + 1
        print = _G.print
        io.write("FAIL " .. name .. (detail and (": " .. tostring(detail)) or "") .. "\n")
    end
end

-- Load the addon in .toc order.
local ns = {}
for line in io.lines("MacroSense/MacroSense.toc") do
    if line:match("%.lua$") then assert(loadfile("MacroSense/" .. line))("MacroSense", ns) end
end
ns.IconNames.SPELLS, ns.IconNames.EMPTY = 10000, 1000 -- the test game's spells end at 9000
local function Send(name, ...)
    for _, o in ipairs(created) do Fire(o, "OnEvent", name, ...) end
end
Send("ADDON_LOADED", "MacroSense")
Send("PLAYER_LOGIN")
Send("PLAYER_ENTERING_WORLD")

-- The early-development note shows once per version.
local function printedWith(text)
    for _, p in ipairs(printed) do if p:find(text, 1, true) then return true end end
end
check("welcome note on first login", printedWith("early development"))
local count = #printed
Send("PLAYER_LOGIN")
check("welcome note only once per version", #printed == count, #printed - count)
SlashCmdList.MACROSENSE("bug")
check("/ms bug prints versions", printedWith("MacroSense dev, WoW 12.1.5 (120105), Mac"))

-- The MacroSense button sits in the title bar of the Blizzard macro window, left of its close button.
MacroFrame = New("Frame", "MacroFrame")
MacroFrame.CloseButton = New("Button")
Send("ADDON_LOADED", "Blizzard_MacroUI")
do
    local b = ns.macroFrameButton
    check("macro window button in its title bar", b and b.point[1] == "RIGHT" and b.point[2] == MacroFrame.CloseButton
        and b.point[3] == "LEFT", b and b.point and table.concat({ tostring(b.point[1]), tostring(b.point[3]) }, " "))
end

CreateMacro("Nuke", 1, "#showtooltip\n/cast Fireball", false)
-- Shift + right-click on it on an action bar opens the editor, also before it was ever opened.
actions[2] = { "macro", 133, "spell", text = "Nuke" }
IsShiftKeyDown = function() return true end
Fire(startButton, "OnClick", "RightButton", true)
Fire(startButton, "OnClick", "RightButton", false)
IsShiftKeyDown = function() return false end
check("action bars: the editor opens on it the first time", #reported == 0 and MacroSenseFrame ~= nil
    and MacroSenseFrame:IsShown(), reported[1])
reported, actions[2] = {}, nil
if MacroSenseFrame then MacroSenseFrame:Hide() end
ns.Window.Toggle()
-- Find the CodeBox edit: the multi-line EditBox with an OnTextChanged that strips colors.
local edit
for _, o in ipairs(created) do
    if o.kind == "EditBox" and o.scripts.OnArrowPressed then edit = o end
end
check("editor exists", edit ~= nil)
check("macro loaded", ns.Highlight.Strip(edit:GetText()) == "#showtooltip\n/cast Fireball", edit:GetText())
check("text is colored", edit:GetText():find("|cff") ~= nil)
do
    local label
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and tostring(o.label.text):find("^Character") then label = o.label.text end
    end
    check("the Character tab counts the client's slots", label == "Character  0/30", label)
end
do
    local visible = 0
    for _, o in ipairs(created) do if o.thumb and o.SetRange and o:IsShown() then visible = visible + 1 end end
    check("no scroll bars without overflow", visible == 0, visible)
end

local function raw() return ns.Highlight.Strip(edit:GetText()) end
-- Left text inset with the line number gutter: "00" is 16 px here, gutter = 16 + 2 * 6, text = gutter + 6.
local TEXT_INSET = 16 + 2 * 6 + 6
local function rawCursor() return ns.Highlight.ToRaw(edit:GetText(), edit:GetCursorPosition()) end

-- Type like the EditBox does: insert at the cursor, move it, then report the change.
local function Type(s)
    edit:SetFocus()
    for ch in s:gmatch(".") do
        local t, c = edit.text, edit.cursor
        edit.text = t:sub(1, c) .. ch .. t:sub(c + 1)
        edit:SetCursorPosition(c + 1)
        Fire(edit, "OnTextChanged", true)
        NextFrame()
    end
end
-- Arrow key: OnKeyDown, the EditBox moves the cursor a line, then OnArrowPressed.
local function Arrow(key)
    Fire(edit, "OnKeyDown", key)
    local t, c = edit.text, edit.cursor
    if key == "UP" then
        local prev = t:sub(1, c):match(".*()\n")
        if prev then edit:SetCursorPosition(prev - 1) end
    end
    Fire(edit, "OnArrowPressed", key)
    NextFrame()
end
local function Key(key, script)
    Fire(edit, "OnKeyDown", key)
    if script then Fire(edit, script) end
    NextFrame()
end
-- The "Live preview" checkbox in the header.
local function PreviewBox()
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Live preview" then return o end
    end
end

-- Put the cursor at the end and add a new line.
edit:SetFocus()
edit:SetCursorPosition(#edit.text)
Type("\n/ca")
check("popup opens for commands", ns.Popup:IsShown())
check("first suggestion is cast", ns.Popup.items[1] and ns.Popup.items[1].name == "cast",
    ns.Popup.items[1] and ns.Popup.items[1].name)
check("still colored after typing", edit:GetText():find("|cff") ~= nil)
check("raw text kept", raw() == "#showtooltip\n/cast Fireball\n/ca", raw())

-- Down / Up move the selection and keep the cursor.
local before = rawCursor()
Arrow("DOWN")
check("down selects second", ns.Popup.selected == 2, ns.Popup.selected)
check("cursor kept on down", rawCursor() == before, rawCursor())
Arrow("UP")
check("up selects first", ns.Popup.selected == 1, ns.Popup.selected)
check("cursor kept on up (EditBox moved it a line)", rawCursor() == before, rawCursor())
Arrow("UP")
check("up wraps to last", ns.Popup.selected == #ns.Popup.items, ns.Popup.selected)
Arrow("DOWN")

-- Other event order: the cursor moves first, only OnArrowPressed fires (no OnKeyDown).
do
    local prev = edit.text:sub(1, edit.cursor):match(".*()\n")
    edit:SetCursorPosition(prev - 1)
    Fire(edit, "OnArrowPressed", "UP")
    NextFrame()
    check("late arrow still moves selection", ns.Popup:IsShown() and ns.Popup.selected == #ns.Popup.items, ns.Popup.selected)
    check("late arrow restores cursor", rawCursor() == before, rawCursor())
    Arrow("DOWN")
    check("back to first", ns.Popup.selected == 1, ns.Popup.selected)
end

-- Enter accepts, without leaving a newline behind.
Fire(edit, "OnKeyDown", "ENTER")
Fire(edit, "OnEnterPressed")
-- The EditBox inserts its newline after the scripts ran.
do
    local t, c = edit.text, edit.cursor
    edit.text = t:sub(1, c) .. "\n" .. t:sub(c + 1)
    edit:SetCursorPosition(c + 1)
    Fire(edit, "OnTextChanged", true)
end
NextFrame()
check("enter accepts command", raw() == "#showtooltip\n/cast Fireball\n/cast ", raw())
check("spells offered after /cast", ns.Popup:IsShown() and ns.Popup.items[1].name == "Fire Blast",
    ns.Popup.items[1] and ns.Popup.items[1].name)

-- Conditions -> modifiers -> spells, accepted with Tab.
Type("[mo")
check("conditions offered", ns.Popup:IsShown() and ns.Popup.items[1].name == "mod", ns.Popup.items[1] and ns.Popup.items[1].name)
Key("TAB", "OnTabPressed")
check("mod: inserted", raw():find("%[mod:%]$") ~= nil, raw())
check("modifiers offered", ns.Popup:IsShown() and ns.Popup.items[1].name == "shift")
check("mac adds cmd", ns.Popup.items[4] and ns.Popup.items[4].name == "cmd", ns.Popup.items[4] and ns.Popup.items[4].name)
Key("TAB", "OnTabPressed")
Type("] Heal")
check("usable items for /cast", ns.Popup:IsShown() and ns.Popup.items[1].name == "Healthstone",
    ns.Popup.items[1] and ns.Popup.items[1].name)
Key("ESCAPE", "OnEscapePressed")
check("escape closes popup", not ns.Popup:IsShown())
check("escape keeps focus while popup was open", edit:HasFocus())

-- Undo goes back to before the last burst of typing.
local beforeUndo = raw()
now = now + 5
Type("x")
check("typed x", raw() == beforeUndo .. "x", raw())
Fire(edit, "OnKeyDown", "Z")
check("ctrl+z needs ctrl", raw() == beforeUndo .. "x")
IsControlKeyDown = function() return true end
Fire(edit, "OnKeyDown", "Z")
check("ctrl+z undoes", raw() == beforeUndo, raw())
Fire(edit, "OnKeyDown", "Y")
check("ctrl+y redoes", raw() == beforeUndo .. "x", raw())

-- Save writes the raw body, without color codes.
Fire(edit, "OnKeyDown", "S")
IsControlKeyDown = function() return false end
check("saved without colors", macros[1].body == raw() and not macros[1].body:find("|cff"), macros[1].body)

-- Equip suggests gear only.
edit:SetCursorPosition(#edit.text)
Type("\n/equip F")
check("equip suggests gear", ns.Popup:IsShown() and ns.Popup.items[1].name == "Fire Ring" and #ns.Popup.items == 1,
    ns.Popup.items[1] and ns.Popup.items[1].name)

-- Typing "[" adds "]" and opens conditions inside; "]" then steps over it.
edit:SetCursorPosition(#edit.text)
Type("\n/cast [")
check("bracket closed", raw():sub(-8) == "/cast []", raw():sub(-8))
check("cursor inside brackets", rawCursor() == #raw() - 1, rawCursor())
check("conditions offered inside", ns.Popup:IsShown() and ns.Popup.items[1].name == "combat",
    ns.Popup.items[1] and ns.Popup.items[1].name)
Type("harm")
Key("ESCAPE", "OnEscapePressed")
Type("]")
check("] steps over", raw():sub(-12) == "/cast [harm]" and rawCursor() == #raw(), raw():sub(-12))
Type(" ")
check("spells after ]", ns.Popup:IsShown())
Key("ESCAPE", "OnEscapePressed")

-- Syntax errors: underlined and named in the status bar, but not the word being typed.
do
    local function underlines()
        local n, tex = 0, nil
        for _, o in ipairs(created) do
            if o.isUnderline and o:IsShown() then n, tex = n + 1, o end
        end
        return n, tex
    end
    local function statusError()
        for _, o in ipairs(created) do
            if o.kind == "FontString" and tostring(o.text):find("Line %d+:") then return o.text end
        end
        return ""
    end
    edit:SetCursorPosition(#edit.text)
    -- A word that may still become valid is not marked while typing, only after a pause.
    Type("\n/cast [comb")
    NextFrame()
    check("no mark while typing an unfinished word", underlines() == 0 and statusError() == "", statusError())
    Wait(1)
    check("marked after a typing pause", underlines() == 1 and statusError():find("unknown condition") ~= nil,
        statusError())
    ns.Window.Revert()
    NextFrame()
    -- A typo that can't become a condition is marked at once.
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast [harmm")
    NextFrame()
    check("a hopeless word is marked at once", underlines() == 1, underlines())
    Key("ESCAPE", "OnEscapePressed")
    Type("] X")
    NextFrame()
    local n = underlines()
    check("error underlined", n == 1, n)
    check("short error in status", statusError():find('Line %d+: did you mean "harm"%?|r') ~= nil, statusError())
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    for _, o in ipairs(created) do
        if o.kind == "Frame" and o.scripts.OnEnter and o.scripts.OnLeave and not o.scripts.OnClick then
            Fire(o, "OnEnter")
        end
    end
    GameTooltip.AddLine = nil
    check("full error in tooltip", table.concat(tip, "\n"):find('unknown condition "harmm"') ~= nil, table.concat(tip, " / "))
    local function saveAlert()
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.label and o.label.text == "Save" then return o.alert:IsShown() end
        end
    end
    check("save shows the alert icon", saveAlert() == true)
    check("cursor kept after measuring", rawCursor() == #raw(), rawCursor())
    ns.Window.Revert()
    NextFrame()
    check("no errors after revert", underlines() == 0 and statusError() == "", statusError())
    check("no alert icon without errors", saveAlert() == false)

    -- The game reports cursor positions a frame late: underlines come from text widths instead.
    cursorEventsLate = true
    edit:SetCursorPosition(#edit.text)
    NextFrame()
    Type("\n/use [bogus] x")
    NextFrame()
    NextFrame()
    local count, tex = underlines()
    check("late events: underline drawn", count == 1, count)
    local line = select(2, raw():gsub("\n", ""))
    -- "bogus" starts after 6 characters of its line: x = text inset + 6 chars * 8; y = inset 4 + rows above * 14.
    check("late events: x from text width", tex and tex.point[4] == TEXT_INSET + 6 * 8, tex and tex.point[4])
    check("late events: y from rows above", tex and tex.point[5] == -4 - line * 14 - 14 + 1, tex and tex.point[5])
    check("late events: cursor stays", rawCursor() == #raw(), rawCursor())
    -- Two errors on two lines (like "/castiв" above "/cast [fsfs]"): both underlined, each on its line.
    Type("\n/cast [fsfs] Bane of Agony")
    NextFrame()
    NextFrame()
    local shown = {}
    for _, o in ipairs(created) do if o.isUnderline and o:IsShown() then shown[#shown + 1] = o end end
    table.sort(shown, function(p, q) return p.point[5] > q.point[5] end)
    check("two errors: two underlines", #shown == 2, #shown)
    check("second underline under fsfs", shown[2] and shown[2].point[4] == TEXT_INSET + 7 * 8,
        shown[2] and shown[2].point[4])
    check("second underline one row lower", shown[2] and shown[1].point[5] - shown[2].point[5] == 14,
        shown[2] and (shown[1].point[5] - shown[2].point[5]))
    cursorEventsLate = false
    ns.Window.Revert()
    NextFrame()
end

-- Backspace like the game does it: removes the unit before the cursor, a character or a whole color code.
local function Backspace()
    Fire(edit, "OnKeyDown", "BACKSPACE")
    local t, c = edit.text, edit.cursor
    local cut = 1
    if t:sub(c - 1, c) == "|r" then cut = 2
    elseif c >= 10 and t:sub(c - 9, c):find("^|c%x%x%x%x%x%x%x%x$") then cut = 10 end
    edit.text = t:sub(1, c - cut) .. t:sub(c + 1)
    edit:SetCursorPosition(c - cut)
    Fire(edit, "OnTextChanged", true)
    NextFrame()
end
edit:SetCursorPosition(#edit.text)
Type("\n/cast [")
check("pair typed", raw():sub(-8) == "/cast []", raw():sub(-8))
Backspace()
check("backspace in [] removes both", raw():sub(-7) == "\n/cast ", raw():sub(-8))
check("deleting does not open the list", not ns.Popup:IsShown())
-- If the cursor sits after a color code, Backspace takes the code: the character still goes.
Type("[")
edit:SetCursorPosition(edit.cursor + 12) -- after "[", its "|r" and the "|cffxxxxxx" of "]"
Backspace()
check("code-only backspace still removes the pair", raw():sub(-7) == "\n/cast ", raw():sub(-8))
Type("Fire")
check("typing after deleting works", raw():sub(-10) == "/cast Fire", raw():sub(-10))
check("list opens again when typing", ns.Popup:IsShown())
Backspace()
check("an open list follows deletes", ns.Popup:IsShown() and raw():sub(-3) == "Fir")
Key("ESCAPE", "OnEscapePressed")
ns.Window.Revert()
NextFrame()

-- Warnings (an unknown unit may be a player's name): yellow, short in the status bar, no alert on Save.
do
    local function statusText()
        for _, o in ipairs(created) do
            if o.kind == "FontString" and tostring(o.text):find("Line %d+:") then return o.text end
        end
        return ""
    end
    local function saveAlert()
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.label and o.label.text == "Save" then return o.alert:IsShown() end
        end
    end
    ns.Window.Revert()
    NextFrame()
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast [@mousover] X")
    NextFrame()
    local warn = ns.scheme.warning
    check("warning in status, short", statusText():find("|cff" .. warn .. 'Line %d+: did you mean "mouseover"%?|r') ~= nil,
        statusText())
    check("no Save alert for a warning", saveAlert() == false)
    local yellow = false
    for _, o in ipairs(created) do
        if o.isUnderline and o:IsShown() and o.color == warn then yellow = true end
    end
    check("warning underline is yellow", yellow)
    ns.Window.Revert()
    NextFrame()
end

-- Editing a unit and saving at once: the warning shows on Save, not only after the pause.
do
    local function warned()
        for _, o in ipairs(created) do
            local text = tostring(o.text)
            if o.kind == "FontString" and (text:find("unknown unit") or text:find('did you mean "mouseover"')) then
                return true
            end
        end
        return false
    end
    ns.Window.Revert()
    NextFrame()
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast [@mouse")
    NextFrame()
    check("unfinished unit: no warning yet", not warned())
    ns.Window.Save()
    check("Save checks the word being typed", warned())
    -- Typing on hides it again until the word is done or typing pauses.
    Type("o")
    NextFrame()
    check("typing on: unfinished again", not warned())
    Type("vr")
    NextFrame()
    check("mouseovr can't become a unit: marked at once", warned())
end

-- Long lists scroll: 10 rows on screen; arrows, PageUp / PageDown and the wheel reach every item.
do
    local P = ns.Popup
    ns.Window.Revert()
    NextFrame()
    edit:SetCursorPosition(#edit.text)
    Type("\n/")
    local n = #P.items
    local function shownRows()
        local c = 0
        for _, r in ipairs(P.rows) do if r:IsShown() then c = c + 1 end end
        return c
    end
    check("long list kept whole", n > 20, n)
    check("10 rows on screen", shownRows() == 10, shownRows())
    check("scroll bar for a long list", P.bar:IsShown())
    for _ = 1, 12 do Arrow("DOWN") end
    check("selection past the 10th row", P.selected == 13, P.selected)
    check("view follows the selection", P.offset == 3, P.offset)
    check("last row shows the selection", P.rows[10].text.text == P.items[13].name, P.rows[10].text.text)
    Key("PAGEDOWN")
    check("PageDown moves 10", P.selected == 23 and P.offset == 13, P.selected .. "/" .. P.offset)
    Fire(P, "OnMouseWheel", 1)
    check("wheel scrolls the view, selection stays", P.offset == 10 and P.selected == 23, P.offset)
    for _ = 1, 4 do Key("PAGEUP") end
    check("PageUp stops at the top", P.selected == 1 and P.offset == 0, P.selected .. "/" .. P.offset)
    Arrow("UP")
    check("Up wraps to the end and shows it", P.selected == n and P.offset == n - 10, P.selected .. "/" .. P.offset)
    check("cursor kept while scrolling", raw():sub(-2) == "\n/" and rawCursor() == #raw(), rawCursor())
    -- A click like in the game: pressing the mouse on the list takes the focus from the text first.
    local want = P.items[P.offset + 2].name
    P.IsMouseOver = function() return true end
    edit:ClearFocus()
    check("list stays open when the focus goes to it", P:IsShown())
    NextFrame()
    check("focus comes back to the text", edit:HasFocus())
    Fire(P.rows[2], "OnClick")
    P.IsMouseOver = nil
    NextFrame()
    check("click takes the item shown in that row", raw():sub(-(#want + 2)) == "/" .. want .. " ", raw():sub(-20))
    check("text keeps the focus after a click", edit:HasFocus())
    Key("ESCAPE", "OnEscapePressed")
    -- Clicking somewhere else closes the list.
    Type("\n/ca")
    check("list open again", P:IsShown())
    edit:ClearFocus()
    NextFrame()
    check("a click elsewhere closes the list", not P:IsShown() and not edit:HasFocus())
    edit:SetFocus()
    -- A short list: no scroll bar.
    ns.Window.Revert()
    NextFrame()
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast [group:")
    check("short list: no scroll bar", P:IsShown() and not P.bar:IsShown() and shownRows() == 2, shownRows())
    Key("ESCAPE", "OnEscapePressed")
    ns.Window.Revert()
    NextFrame()
end

-- A finished word does not reopen the list after Tab, even when longer words match ("mouseovertarget").
edit:SetCursorPosition(#edit.text)
Type("\n/cast [@mouse")
check("units offered", ns.Popup:IsShown() and ns.Popup.items[1].name == "mouseover")
Key("TAB", "OnTabPressed")
check("mouseover inserted", raw():find("%[@mouseover%]$") ~= nil, raw():sub(-20))
check("no list after a finished word", not ns.Popup:IsShown(), ns.Popup.items[1] and ns.Popup.items[1].name)
Type("t")
check("typing on shows longer words", ns.Popup:IsShown() and ns.Popup.items[1].name == "mouseovertarget")
Key("ESCAPE", "OnEscapePressed")

-- Ranks: "/" -> cast -> Fireball -> ranks. Tab takes a rank, Esc keeps the plain spell.
local function Pick(name)
    for i, item in ipairs(ns.Popup.items) do
        if item.name == name then
            for _ = 1, (i - ns.Popup.selected) % #ns.Popup.items do Arrow("DOWN") end
            return Key("TAB", "OnTabPressed")
        end
    end
    check("pick " .. name .. " offered", false)
end
edit:SetCursorPosition(#edit.text)
Type("\n/")
Pick("cast")
Pick("Fireball")
check("ranks offered after spell", ns.Popup:IsShown() and ns.Popup.items[1].name == "Rank 3" and #ns.Popup.items == 3,
    ns.Popup.items[1] and ns.Popup.items[1].name)
Arrow("DOWN")
Key("TAB", "OnTabPressed")
check("rank 2 inserted", raw():find("\n/cast Fireball%(Rank 2%)$") ~= nil, raw())
check("list closed after rank", not ns.Popup:IsShown())

Type("; ")
Pick("Fireball")
check("ranks offered again", ns.Popup:IsShown() and ns.Popup.items[1].name == "Rank 3")
Key("ESCAPE", "OnEscapePressed")
check("esc keeps plain spell", raw():find("/cast Fireball%(Rank 2%); Fireball$") ~= nil, raw())
check("esc closes ranks", not ns.Popup:IsShown())
Type(";")
check("typing on after esc", raw():find("; Fireball;$") ~= nil, raw())

-- Return / Enter without a list: exactly one newline, whatever the EditBox does by itself.
local function Newline(engine)
    edit:SetCursorPosition(#edit.text)
    NextFrame()
    if ns.Popup:IsShown() then Key("ESCAPE", "OnEscapePressed") end -- with a list open, Enter accepts
    local before = raw()
    local function insert()
        local t, c = edit.text, edit.cursor
        edit.text = t:sub(1, c) .. "\n" .. t:sub(c + 1)
        edit:SetCursorPosition(c + 1)
        Fire(edit, "OnTextChanged", true)
    end
    if engine == "before" then insert() end
    Fire(edit, "OnKeyDown", "ENTER")
    Fire(edit, "OnEnterPressed")
    if engine == "after" then insert() end
    NextFrame()
    NextFrame()
    check("one newline (" .. engine .. ")", raw() == before .. "\n", raw():sub(-20))
    check("cursor after newline (" .. engine .. ")", rawCursor() == #before + 1, rawCursor())
end
Newline("none")   -- the EditBox inserts nothing: we do
Newline("before") -- inserted before our scripts ran
Newline("after")  -- inserted after them, same frame
Fire(edit, "OnKeyDown", "NUMPADENTER")
NextFrame(); NextFrame()
check("numpad enter newline", raw():sub(-4) == "\n\n\n\n", #raw())

-- Icon picker: click the icon, pick one, save.
local function saveIsEnabled()
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Save" then return o.enabled end
    end
end
do
    local first, last = 1, select(1, GetNumMacros())
    ns.Window.Select(first)
    NextFrame()
    Fire(MacroSenseIconButton, "OnClick")
    check("icon picker opens", MacroSenseIconPicker:IsShown())
    local grid = {}
    for _, o in ipairs(created) do if o.kind == "Button" and o.entry then grid[#grid + 1] = o end end
    check("grid starts with question mark", grid[1] and grid[1].entry.icon == 134400)
    check("spell icons come next", grid[2] and grid[2].entry.name == "Fire Blast", grid[2] and grid[2].entry.name)
    -- Search by spell name.
    local target = grid[3]
    Fire(target, "OnClick")
    check("picked icon is unsaved change", saveIsEnabled())
    ns.Window.Save()
    check("icon saved", macros[1].icon == target.entry.icon, tostring(macros[1].icon))
    -- Resizing the picker shows more columns and rows, and remembers the size.
    local function gridShown()
        local n = 0
        for _, o in ipairs(created) do if o.kind == "Button" and o.entry and o:IsShown() then n = n + 1 end end
        return n
    end
    check("10 x 7 icons at the minimum size", gridShown() == 70, gridShown())
    MacroSenseIconPicker.GetWidth = function() return 600 end   -- room for 14 columns
    MacroSenseIconPicker.GetHeight = function() return 500 end  -- room for 11 rows
    Fire(MacroSenseIconPicker, "OnSizeChanged")
    check("bigger picker shows more icons", gridShown() == 14 * 11, gridShown())
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.scripts.OnMouseUp and o.scripts.OnMouseDown and not o.scripts.OnClick then
            Fire(o, "OnMouseUp")
        end
    end
    check("picker size remembered", ns.db.picker and ns.db.picker.w == 600 and ns.db.picker.h == 500)
    -- Docking: docked by default; dragged away it stays free (also when reopened); dragged back it docks.
    local picker, editor = MacroSenseIconPicker, MacroSenseFrame
    check("picker docked to the editor", picker.point[2] == editor)
    editor.right, editor.top = 800, 600
    picker.left, picker.top = 1200, 700
    Fire(picker, "OnDragStart")
    Fire(picker, "OnDragStop")
    check("dragged away: free", ns.db.picker.docked == false)
    picker:Hide()
    Fire(MacroSenseIconButton, "OnClick")
    check("reopened free, not on the editor", picker:IsShown() and picker.point[2] ~= editor)
    picker.left, picker.top = 815, 590
    Fire(picker, "OnDragStart")
    Fire(picker, "OnDragStop")
    check("dragged next to the editor: docked", ns.db.picker.docked == true and picker.point[2] == editor)
    picker.point = { "TOPLEFT", UIParent, "TOPLEFT", 1, 1 } -- what resizing does to the anchor
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.scripts.OnMouseUp and o.scripts.OnMouseDown and not o.scripts.OnClick then
            Fire(o, "OnMouseUp")
        end
    end
    check("docked picker stays docked after resizing", picker.point[2] == editor)
    MacroSenseIconPicker:Hide()
    check("picker closes", not MacroSenseIconPicker:IsShown())
end

-- Icon names: any spell of the game names the icons it uses, looked up while the grid is open.
do
    local box, footer
    for _, o in ipairs(created) do
        if o.kind == "EditBox" and o.parentFrame == MacroSenseIconPicker then box = o end
        if o.kind == "FontString" and tostring(o.text):find(" icons") then footer = o end
    end
    local function Shown()
        local icons = {}
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.entry and o:IsShown() then icons[#icons + 1] = o.entry.icon end
        end
        return icons
    end
    local function Found(q)
        box:SetText(q)
        return table.concat(Shown(), ",")
    end
    Wait(1) -- the grid is closed: nothing is looked up
    Fire(MacroSenseIconButton, "OnClick")
    check("icon names: not before the grid opens", Found("death") == "" and footer.text:find("looking up names: 0%%"),
        footer.text)
    Wait(1)
    check("icon names: a spell you don't know names its icon", Found("death") == "1051", Found("death"))
    check("icon names: the lookup is over", not footer.text:find("looking up"), footer.text)
    local scanner
    for _, o in ipairs(created) do
        if o.parentFrame == MacroSenseIconPicker and o.scripts.OnUpdate then scanner = o end
    end
    check("icon names: and stops looking", scanner and not scanner.shown)
    check("icon names: by any of the names", Found("howl") == "1050" and Found("fear") == "1050", Found("fear"))
    check("icon names: case doesn't count, in Cyrillic too", Found("страх") == "1052" and Found("СТРАХ") == "1052",
        Found("СТРАХ"))
    local tip = {}
    GameTooltip.SetText = function(_, text) tip = { text } end
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Found("fear")
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.entry and o.entry.icon == 1050 and o:IsShown() then Fire(o, "OnEnter") end
    end
    GameTooltip.SetText, GameTooltip.AddLine = nil, nil
    check("icon names: the tooltip has them all, by spell ID", table.concat(tip, ", ") == "Howl of Terror, Fear",
        table.concat(tip, ", "))
    MacroSenseIconPicker:Hide()
    Fire(MacroSenseIconButton, "OnClick")
    check("icon names: once a session", Found("death") == "1051", Found("death"))
    -- Your own icons from Interface\Icons: before the game's, by their file name, saved by their path.
    local order = {}
    Found("")
    for i, icon in ipairs(Shown()) do order[icon] = order[icon] or i end
    local mine, potion = "Interface\\Icons\\My_Skull", "Interface\\Icons\\My_Potion"
    check("your icons: before the game's", order[mine] and order[1001] and order[mine] < order[1001],
        tostring(order[mine]))
    Fire(MacroSenseIconPicker, "OnMouseWheel", -1000) -- to the end: the items
    local last = {}
    for i, icon in ipairs(Shown()) do last[icon] = last[icon] or i end
    check("your item icons: before the game's", last[1300] and last[potion] and last.INV_Sword_01
        and last[1300] < last[potion] and last[potion] < last.INV_Sword_01, tostring(last[potion]))
    check("your icons: by their file name", Found("my_skull") == mine, Found("my_skull"))
    local title
    GameTooltip.SetText = function(_, text) title = text end
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.entry and o.entry.icon == mine and o:IsShown() then Fire(o, "OnEnter") end
    end
    GameTooltip.SetText = nil
    check("your icons: the file name in the tooltip", title == "My_Skull", title)
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.entry and o.entry.icon == mine and o:IsShown() then Fire(o, "OnClick") end
    end
    ns.Window.Save()
    local saved
    for _, m in ipairs(macros) do saved = saved or m.icon == mine end
    check("your icons: saved by their path", saved)
    -- Your own spells: case doesn't count in Cyrillic either.
    book[#book + 1] = { "Чорна стріла", "" }
    Send("SPELLS_CHANGED")
    Fire(MacroSenseIconButton, "OnClick") -- closes it
    Fire(MacroSenseIconButton, "OnClick")
    check("icon names: your spells in Cyrillic", Found("чорна") == tostring(#book), Found("чорна"))
    book[#book] = nil
    Send("SPELLS_CHANGED")
    MacroSenseIconPicker:Hide()

    -- What the names match shows up while they are looked up, and more coming in don't move the view. A new
    -- session's lookup, a part of the spells a frame: 100 names early, 30 late.
    assert(loadfile("MacroSense/IconNames.lua"))("MacroSense", ns)
    ns.IconNames.SPELLS, ns.IconNames.EMPTY = 30000, 1000
    local late = { first = 20101, last = 20130 }
    for i = 1, 100 do gameSpells[3000 + i] = { 1100 + i, "Shadow " .. i } end
    for id = late.first, late.last do gameSpells[id] = { 1100 + id - 20000, "Shadow late" } end
    local clock, ms = debugprofilestop, 0
    debugprofilestop = function()
        ms = ms + 5
        return ms
    end
    MacroSenseIconPicker.GetWidth, MacroSenseIconPicker.GetHeight = nil, nil -- 10 x 7 again
    Fire(MacroSenseIconPicker, "OnSizeChanged")
    Fire(MacroSenseIconButton, "OnClick")
    box:SetText("shadow")
    Wait(0.55)
    local found = Shown()
    check("icon names: they show up while looked up", #found == 70 and footer.text:find("looking up"), #found)
    Fire(MacroSenseIconPicker, "OnMouseWheel", -1) -- two rows down: the 21st first
    check("icon names: scrolled", Shown()[1] == found[21], Shown()[1])
    Wait(1)
    check("icon names: the view stays as more come", Shown()[1] == found[21] and footer.text:find("^130 icons$"),
        footer.text)
    debugprofilestop = clock
    for i = 1, 100 do gameSpells[3000 + i] = nil end
    for id = late.first, late.last do gameSpells[id] = nil end
    Found("")
    MacroSenseIconPicker:Hide()
end

-- Our own scroll bar: hidden without overflow, wheel scrolls and clamps, dragging the thumb scrolls.
do
    local scroll = MacroSenseListScroll
    local function bar()
        for _, o in ipairs(created) do if o.thumb and o.SetRange and o.max == 100 then return o end end
    end
    scroll.range = 100
    Fire(scroll, "OnScrollRangeChanged")
    local b = bar()
    check("scroll bar shown with overflow", b and b:IsShown())
    Fire(scroll, "OnMouseWheel", -1)
    check("wheel scrolls 3 rows", scroll.vscroll == 72, scroll.vscroll)
    check("bar follows scroll", b and b.value == 72, b and b.value)
    Fire(scroll, "OnMouseWheel", -1)
    check("wheel clamps at end", scroll.vscroll == 100, scroll.vscroll)
    Fire(scroll, "OnMouseWheel", 5)
    check("wheel clamps at top", scroll.vscroll == 0, scroll.vscroll)
    -- The bar is 200 high with its top at 500, 200 of 300 shown: the thumb is 133.3 high and travels 66.7 for 100.
    local function near(v) return math.abs(scroll.vscroll - v) < 0.01 end
    b.top = 500
    cursorY = 500 - 190
    Fire(b, "OnMouseDown")
    check("a click low on the track scrolls down", scroll.vscroll == 100 and b.dragging, scroll.vscroll)
    Fire(b, "OnMouseUp")
    cursorY = 500 - 5
    Fire(b, "OnMouseDown")
    Fire(b, "OnMouseUp")
    check("a click high on the track scrolls up", scroll.vscroll == 0, scroll.vscroll)
    -- At the top the thumb covers 0 to 133.3: held 50 below its top and moved down 33.3, it scrolls half way.
    cursorY = 500 - 50
    Fire(b, "OnMouseDown")
    check("a click on the thumb doesn't move it", near(0), scroll.vscroll)
    cursorY = 500 - 50 - 100 / 3
    Fire(b, "OnUpdate")
    check("dragging the thumb scrolls", near(50), scroll.vscroll)
    Fire(b, "OnMouseUp")
    cursorY = 500 - 150
    Fire(b, "OnUpdate")
    check("let go: no more scrolling", near(50) and not b.dragging, scroll.vscroll)
    cursorY = 0
    scroll.range = 0.4
    Fire(scroll, "OnScrollRangeChanged")
    check("sub-pixel range hides the bar", not b:IsShown())
    scroll.range = 0
    Fire(scroll, "OnScrollRangeChanged")
    check("scroll bar hidden without overflow", not b:IsShown())
end

-- Mac: [mod:cmd] on Q (the macro is on action button 1, bound to Q) warns in the status bar.
do
    local function warningText()
        for _, o in ipairs(created) do
            if o.kind == "FontString" and tostring(o.text):find("macOS") then return o.text end
        end
        return ""
    end
    -- It shows Fireball: the game gives the slot Fireball's ID, and the button the macro's name.
    actions[1] = { "macro", 133, "spell", text = (GetMacroInfo(1)) }
    Send("ACTIONBAR_SLOT_CHANGED", 1)
    ns.Window.Select(1)
    NextFrame()
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast [mod:cmd] Fireball")
    Key("ESCAPE", "OnEscapePressed")
    check("cmd+Q warning shown", warningText():find("Cmd%+Q is a macOS shortcut") ~= nil, warningText())
    -- An equipment set named like the macro, on the W button: not the macro (Cmd+W closes the window).
    actions[2], bindings.ACTIONBUTTON2 = { "equipmentset", "Bar", text = (GetMacroInfo(1)) }, "W"
    Send("ACTIONBAR_SLOT_CHANGED", 2)
    check("only the macro's own buttons", not warningText():find("Cmd%+W"), warningText())
    actions[2], bindings.ACTIONBUTTON2 = nil, nil
    Send("ACTIONBAR_SLOT_CHANGED", 2)
    bindings.ACTIONBUTTON1 = "E"
    Send("UPDATE_BINDINGS")
    check("rebinding to E clears it", warningText() == "", warningText())
    bindings.ACTIONBUTTON1 = "Q"
    Send("UPDATE_BINDINGS")
    check("back on Q warns again", warningText() ~= "")
    IsMacClient = function() return false end
    Send("UPDATE_BINDINGS")
    check("no warning on Windows", warningText() == "", warningText())
    IsMacClient = function() return true end
    ns.Window.Revert()
end

-- Drag to an action bar: list rows and the header icon put the macro on the cursor.
do
    local row
    for _, o in ipairs(created) do if o.kind == "Button" and o.index == 1 and o.scripts.OnDragStart then row = o end end
    Fire(row, "OnDragStart")
    check("dragging a row picks up its macro", picked == 1, picked)
    picked = nil
    ns.Window.Select(1)
    Fire(MacroSenseIconButton, "OnDragStart")
    check("dragging the icon picks up the macro", picked == 1, picked)
    picked = nil
    InCombatLockdown = function() return true end
    Fire(MacroSenseIconButton, "OnDragStart")
    check("no pickup in combat", picked == nil)
    InCombatLockdown = function() return false end
    ns.Window.New()
    Fire(MacroSenseIconButton, "OnDragStart")
    check("a new macro must be saved first", picked == nil and printed[#printed]:find("save the macro first") ~= nil,
        printed[#printed])
    ns.Window.Select(1)
end

-- Line numbers: one per line, on its first row; the cursor's line is bright; the gutter grows past 99.
do
    local function numbers()
        local out = {}
        for _, o in ipairs(created) do
            if o.isLineNumber and o:IsShown() then out[tonumber(o.text)] = o end
        end
        return out
    end
    ns.Window.Revert()
    NextFrame()
    NextFrame()
    local lines = select(2, raw():gsub("\n", "")) + 1
    local n = numbers()
    local count = 0
    for _ in pairs(n) do count = count + 1 end
    check("a number per line", count == lines, count .. " numbers, " .. lines .. " lines")
    check("line 1 at the top", n[1] and n[1].point[5] == -4, n[1] and n[1].point[5])
    check("line 2 one row lower", n[2] and n[2].point[5] == -4 - 14, n[2] and n[2].point[5])
    -- The cursor's line is bright.
    edit:SetFocus()
    edit:SetCursorPosition(0)
    local bright, dim = ns.scheme.text, ns.scheme.dim
    local function color(fs) return fs.textColor end
    check("current line number uses the text color", color(n[1]) == bright, color(n[1]))
    check("other line numbers are dim", color(n[2]) == dim, color(n[2]))
    edit:SetCursorPosition(#edit.text)
    check("number follows the cursor", color(n[lines]) == bright and color(n[1]) == dim)
    -- A wrapped line takes two rows: the next number moves down two rows. The preview is off here: the
    -- text has the whole width, 260 of the 300 px.
    Fire(PreviewBox(), "OnClick")
    wrapLines = true
    Type("\n/cast " .. string.rep("Fireball ", 6) .. "\n/cast X")
    NextFrame()
    NextFrame()
    n = numbers()
    local long, nextLine = n[lines + 1], n[lines + 2]
    check("wrapped line: next number two rows lower", long and nextLine and long.point[5] - nextLine.point[5] == 28,
        long and nextLine and (long.point[5] - nextLine.point[5]))
    -- The preview column takes 140 px: 120 px of text are left, the line takes four rows.
    Fire(PreviewBox(), "OnClick")
    NextFrame()
    NextFrame()
    n = numbers()
    long, nextLine = n[lines + 1], n[lines + 2]
    check("preview column narrows the text", long and nextLine and long.point[5] - nextLine.point[5] == 56,
        long and nextLine and (long.point[5] - nextLine.point[5]))
    wrapLines = false
    -- 100 lines: three digits, wider gutter.
    Type(string.rep("\n", 100))
    NextFrame()
    NextFrame()
    n = numbers()
    check("line 100 numbered", n[100] ~= nil)
    check("gutter grows for three digits", n[1].width == 24 + 2 * 6 - 6, n[1].width)
    ns.Window.Revert()
    NextFrame()
    NextFrame()
    n = numbers()
    check("back to two digits after revert", n[1].width == 16 + 2 * 6 - 6, n[1].width)

    -- A bigger font: rows, gutter and underlines follow it (size 20: 12 px characters, 21 px rows).
    -- The text is not focused here, like after clicking "+" next to the size.
    edit:ClearFocus()
    ns.db.fontSize = 20
    ns.Window.ApplyLook()
    NextFrame()
    NextFrame()
    n = numbers()
    check("font size: row height follows", n[2] and n[2].point[5] == -4 - 21, n[2] and n[2].point[5])
    check("font size: gutter follows", n[1].width == 24 + 2 * 6 - 6, n[1].width)
    check("font size: numbers use the editor font", n[1].fontSize == 20, n[1].fontSize)
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast [harmm] X")
    NextFrame()
    NextFrame()
    local tex
    for _, o in ipairs(created) do if o.isUnderline and o:IsShown() then tex = o end end
    local lastLine = select(2, raw():gsub("\n", ""))
    check("font size: underline x follows", tex and tex.point[4] == (24 + 2 * 6 + 6) + 7 * 12, tex and tex.point[4])
    check("font size: underline y follows", tex and tex.point[5] == -4 - lastLine * 21 - 21 + 1, tex and tex.point[5])
    ns.Window.Revert()
    ns.db.fontSize = 13
    ns.Window.ApplyLook()
    NextFrame()
    NextFrame()
    n = numbers()
    check("font size back", n[2] and n[2].point[5] == -4 - 14, n[2] and n[2].point[5])

    -- The same when the game reports the cursor a frame late (as it does): rows come from the font first.
    cursorEventsLate = true
    edit:ClearFocus()
    ns.db.fontSize = 20
    ns.Window.ApplyLook()
    NextFrame()
    NextFrame()
    NextFrame()
    n = numbers()
    check("late events: row height follows the font", n[2] and n[2].point[5] == -4 - 21, n[2] and n[2].point[5])
    ns.db.fontSize = 13
    ns.Window.ApplyLook()
    NextFrame()
    NextFrame()
    NextFrame()
    n = numbers()
    check("late events: and back", n[2] and n[2].point[5] == -4 - 14, n[2] and n[2].point[5])
    cursorEventsLate = false
    edit:SetFocus()
end

-- Typos: "Firebal" is marked after the typing pause with a suggestion; a click on it fixes the text.
do
    local function hover()
        for _, o in ipairs(created) do
            if o.kind == "Frame" and not o.thumb and o.scripts.OnMouseUp and o.scripts.OnEnter and o.scripts.OnLeave then return o end
        end
    end
    local function statusText()
        for _, o in ipairs(created) do
            if o.kind == "FontString" and tostring(o.text):find("Line %d+:") then return o.text end
        end
        return ""
    end
    ns.Window.Revert()
    NextFrame()
    ns.Window.New() -- a clean macro: no issues left from the tests above
    NextFrame()
    edit:SetFocus()
    Type("/cast Firebal")
    Key("ESCAPE", "OnEscapePressed")
    Wait(1)
    check("typo suggestion in the status bar", statusText():find('did you mean "Fireball"%?') ~= nil, statusText())
    Fire(hover(), "OnMouseUp")
    NextFrame()
    check("click fixes the name", raw() == "/cast Fireball", raw())
    check("no issue after the fix", statusText() == "", statusText())
    Type("\n/cast [@] x")
    Wait(1)
    edit:ClearFocus()
    edit:SetCursorPosition(0)
    Fire(hover(), "OnMouseUp")
    local at = ns.Highlight.ToRaw(edit:GetText(), edit:GetCursorPosition())
    check("click on an issue with no fix goes to it", edit:HasFocus() and at == #"/cast Fireball\n/cast [", at)
    ns.Window.Revert()
    CreateMacro("Fix Me", 1, "/cast [harm Fireball", false)
    Send("UPDATE_MACROS")
    ns.Window.Select(GetMacroIndexByName("Fix Me"))
    Wait(1)
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(hover(), "OnEnter")
    GameTooltip.AddLine = function() end
    check("the fix in the tooltip", table.concat(tip, "|"):find('Click to add "]"', 1, true) ~= nil, table.concat(tip, "|"))
    Fire(hover(), "OnMouseUp")
    NextFrame()
    check("a click puts it in", raw() == "/cast [harm] Fireball", raw())
    ns.Window.Revert()
    DeleteMacro(GetMacroIndexByName("Fix Me"))
    Send("UPDATE_MACROS")

    -- A spell dropped on the text: on an empty line with /cast, else its name at the cursor.
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    onCursor = { "spell", 12, "spell", 5782 } -- Fear
    Fire(edit, "OnReceiveDrag")
    check("dropped: a spell on an empty line", raw() == "/cast Fear" and onCursor == nil, raw())
    Type("\n/cast [@focus] ")
    onCursor = { "item", 5512 }
    GetItemInfo = function(id) return id == 5512 and "Healthstone" or nil end
    Fire(edit, "OnMouseDown")
    check("dropped by a click: an item's name at the cursor", raw() == "/cast Fear\n/cast [@focus] Healthstone", raw())
    Type("\n")
    onCursor = { "item", 5512 }
    Fire(edit, "OnReceiveDrag")
    check("dropped: an item on an empty line with /use", raw():find("\n/use Healthstone$") ~= nil, raw())
    GetItemInfo = nil
    onCursor = { "macro", 3 }
    Fire(edit, "OnReceiveDrag")
    check("dropped: a macro is not text", raw():find("\n/use Healthstone$") ~= nil and onCursor ~= nil, raw())
    onCursor = nil
    -- Shift-click on a spell's link while the text has the focus.
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    ChatEdit_InsertLink("|cff71d5ff|Hspell:133:0|h[Fireball]|h|r")
    check("shift-click: a spell's name with /cast", raw() == "/cast Fireball", raw())
    edit:ClearFocus()
    ChatEdit_InsertLink("|cff71d5ff|Hspell:116:0|h[Frostbolt]|h|r")
    check("shift-click: not without the focus", raw() == "/cast Fireball", raw())
    edit:SetFocus()
    ChatEdit_InsertLink("|cffffff00|Hachievement:6:0|h[Level 10]|h|r")
    check("shift-click: not an achievement", raw() == "/cast Fireball", raw())
    Type("\n")
    ChatEdit_InsertLink("|cff71d5ff|Hspell:116:0|h[Frostbolt]|h|r")
    ChatEdit_InsertLink("|cff71d5ff|Hspell:116:0|h[Frostbolt]|h|r") -- the same link again at once: passed on
    check("shift-click: one link once", raw() == "/cast Fireball\n/cast Frostbolt", raw())
    -- Dropped below the last line, with no focus: at the end, wherever the cursor was.
    edit:SetCursorPosition(0)
    edit:ClearFocus()
    local catcher
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.parentFrame == MacroSenseCodeScroll and o.scripts.OnReceiveDrag then catcher = o end
    end
    onCursor = { "spell", 1, "spell", 5782 }
    Fire(catcher, "OnClick")
    check("dropped below the text: at its end", raw() == "/cast Fireball\n/cast FrostboltFear" and onCursor == nil,
        raw())
    ns.Window.Revert()
    NextFrame()
    -- Items: names seen in the bags are remembered for later.
    check("seen items remembered", ns.db.itemNames and ns.db.itemNames["Healthstone"] == true)
    -- Pet spells: remembered from every pet seen, so the other pet's spells stay known.
    petBook = { "Seduction", "Lash of Pain" }
    Send("UNIT_PET", "player")
    check("current pet's spells known", ns.KnownActions().set["seduction"] == true)
    petBook = { "Spell Lock" }
    Send("UNIT_PET", "player")
    local set = ns.KnownActions().set
    check("other pet's spells still known", set["seduction"] and set["spell lock"])
    check("pet spells saved per character", ns.char.petSpells["Lash of Pain"] == true)
    petBook = {}
    ns.Window.Select(1)
    NextFrame()
end

-- The Classic clients have C_SpellBook with HasPetSpells but not the rest: the pet's spells come from the old
-- functions. And a source that fails anyway (a game function a client lacks) costs the typo check, not the editor.
do
    local retail = C_SpellBook
    C_SpellBook = { HasPetSpells = retail.HasPetSpells }
    GetNumSpellTabs, HasPetSpells = function() return 0 end, retail.HasPetSpells
    GetSpellBookItemName = function(i, bookType) if bookType == "pet" then return petBook[i] end end
    petBook = { "Torment" }
    Send("UNIT_PET", "player")
    local ok, known = pcall(ns.KnownActions)
    check("classic: the pet's spells from the old functions", ok and known.set["torment"] == true,
        not ok and known or nil)
    C_SpellBook, GetNumSpellTabs, HasPetSpells, GetSpellBookItemName = retail, nil, nil, nil
    petBook = {}
    Send("UNIT_PET", "player")

    local journal = C_MountJournal
    C_MountJournal = { GetMountIDs = function() error("no such function") end }
    Send("BAG_UPDATE_DELAYED")
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    Type("/cast Fierball")
    Key("ESCAPE", "OnEscapePressed")
    Wait(1)
    check("a failing source: the text goes in, colored", raw() == "/cast Fierball" and edit:GetText():find("|cff") ~= nil,
        raw())
    check("a failing source: reported", #reported == 1 and reported[1]:find("no such function", 1, true) ~= nil,
        reported[1])
    Send("BAG_UPDATE_DELAYED")
    Type("\n/cast Frostblot")
    Wait(1)
    check("a failing source: reported once", #reported == 1, #reported)
    C_MountJournal = journal
    Send("BAG_UPDATE_DELAYED")
    ns.Window.Select(1)
    NextFrame()
end

-- Live preview: next to each line, what it would do now. It follows modifiers and combat by itself.
do
    local function notes()
        local shown = {}
        for _, o in ipairs(created) do
            if o.isNote and o:IsShown() then shown[#shown + 1] = o end
        end
        table.sort(shown, function(a, b) return a.point[5] > b.point[5] end)
        local texts = {}
        for i, o in ipairs(shown) do texts[i] = ns.Highlight.Strip(o.text) end
        return table.concat(texts, " | "), shown
    end
    local function lineNumber(i)
        for _, o in ipairs(created) do
            if o.isLineNumber and o:IsShown() and tonumber(o.text) == i then return o end
        end
    end
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    Type("#showtooltip\n/cast [mod:alt] Polymorph; Fireball\n/stopmacro [nocombat]\n/cast Frostbolt")
    Key("ESCAPE", "OnEscapePressed")
    NextFrame()
    NextFrame()
    check("preview: a note per line", notes() == "icon: Fireball | Fireball | stops here | not reached", notes())
    local _, shown = notes()
    check("preview: a note sits on its line", shown[2] and lineNumber(2) and shown[2].point[5] == lineNumber(2).point[5],
        shown[2] and shown[2].point[5])
    check("preview: notes in the column on the right", shown[1] and shown[1].point[1] == "TOPRIGHT"
        and shown[1].width == 140 - 12, shown[1] and shown[1].width)
    check("preview: a smaller font", shown[1] and shown[1].fontSize == 11, shown[1] and shown[1].fontSize)
    check("preview: the spell in its color", shown[2] and shown[2].text:find(
        "|cff" .. ns.TokenColors(ns.scheme).action .. "Fireball|r", 1, true) ~= nil, shown[2] and shown[2].text)
    game.mods.alt = true
    Wait(0.2)
    check("preview follows a held modifier", notes() == "icon: Polymorph | Polymorph | stops here | not reached", notes())
    game.mods.alt, game.combat = nil, true
    Wait(0.2)
    check("preview follows combat", notes() == "icon: Fireball | Fireball | conditions not met | Frostbolt",
        notes())
    game.combat = nil
    Type("\n/cast [harmm] Fear")
    Key("ESCAPE", "OnEscapePressed")
    NextFrame()
    NextFrame()
    check("preview: no note for a line with an error", notes() == "icon: Fireball | Fireball | stops here | not reached",
        notes())
    -- Off: the notes go, and the setting is kept.
    local box = PreviewBox()
    Fire(box, "OnClick")
    NextFrame()
    NextFrame()
    check("preview off: no notes", notes() == "" and ns.db.preview == false, notes())
    check("preview off: the box is empty", not box.fill:IsShown())
    Fire(box, "OnClick")
    NextFrame()
    NextFrame()
    check("preview on again", notes() ~= "" and ns.db.preview == true and box.fill:IsShown(), notes())
    -- The author's macro with the pet out: the pet's spell, on the mouseover enemy.
    ns.Window.New()
    NextFrame()
    local fixtures = dofile("tests/fixtures/macros.lua")
    Type(fixtures.petCC)
    Key("ESCAPE", "OnEscapePressed")
    game.pet, game.units.mouseover = "Succubus", { harm = true }
    Wait(0.2)
    check("preview: a pet macro", notes() == "icon: Seduction | Seduction @mouseover", notes())
    game.pet, game.units.mouseover = nil, nil
    Wait(0.2)
    check("preview: no pet, no match", notes() == "icon: ? | conditions not met", notes())
    -- A note on line 150 only (no line that far had one before); a shorter macro leaves it no trace.
    ns.Window.New()
    NextFrame()
    Type(string.rep("\n", 149) .. "/cast Fireball")
    Key("ESCAPE", "OnEscapePressed")
    NextFrame()
    check("preview: a note on line 150 only", notes() == "Fireball", notes())
    ns.Window.New()
    -- The preview may update before the text is laid out again: the game runs timers and OnUpdate in any order.
    Fire(MacroSenseFrame, "OnUpdate", 1)
    NextFrame()
    Type("/cast Frostbolt")
    Key("ESCAPE", "OnEscapePressed")
    NextFrame()
    check("preview: no notes left from a longer macro", notes() == "Frostbolt", notes())
    ns.Window.Revert()
    ns.Window.Select(1)
    NextFrame()
end

-- A command that runs is named in the live preview, in the color commands have in the text.
do
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    Type("/startattack")
    Key("ESCAPE", "OnEscapePressed")
    Wait(0.2)
    local note
    for _, o in ipairs(created) do
        if o.isNote and o:IsShown() then note = o.text end
    end
    check("preview: runs /startattack, the command in its color", note and ns.Highlight.Strip(note) == "runs /startattack"
        and note:find("|cff" .. ns.TokenColors(ns.scheme).command .. "/startattack|r", 1, true) ~= nil, note)
    ns.Window.Select(1)
    NextFrame()
end

-- Unknown commands and conditions are marked; known ones are not.
local function kindOf(text, word)
    for _, sp in ipairs(ns.Highlight.Spans(text)) do
        if text:sub(sp[1], sp[2]) == word then return sp[3] end
    end
end
check("emote is a command", kindOf("/dance", "/dance") == "command")
check("chat is a command", kindOf("/say hi", "/say") == "command")
check("unknown command is an error", kindOf("/bogus", "/bogus") == "error")
-- Secure commands: the game hides their list, IsSecureCmd knows them ("/petmoveto" was marked unknown).
check("secure command is a command", kindOf("/petmoveto [nomod]", "/petmoveto") == "command")
do
    local petControl = dofile("tests/fixtures/macros.lua").petControl
    local found = {}
    for _, e in ipairs(ns.Highlight.Errors(petControl)) do found[#found + 1] = petControl:sub(e.from, e.to) end
    check("no false alarms in the pet macro", #found == 0, table.concat(found, ", "))
    local offered = {}
    for _, c in ipairs(ns.sources.commands()) do offered[c.name] = true end
    check("secure commands offered after /", offered.petmoveto == true)
    check("only those this client has", offered.teamquit == nil)
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/petm")
    check("/petm suggests petmoveto", ns.Popup:IsShown() and ns.Popup.items[1] and ns.Popup.items[1].name == "petmoveto",
        ns.Popup.items[1] and ns.Popup.items[1].name)
    Key("ESCAPE", "OnEscapePressed")
    ns.Window.Revert()
    NextFrame()
end

-- The macro list marks macros with issues: a red name and the alert sign for errors, a yellow name for
-- warnings only. Hovering lists the issues.
do
    CreateMacro("Zap broken", 1, "/cast [harmm] Fireball", false)
    CreateMacro("Zap clean", 1, "#showtooltip\n/petmoveto [nomod]\n/cast Fireball", false)
    CreateMacro("Zap typo", 1, "/cast Firebal", false)
    Send("UPDATE_MACROS")
    local function row(name)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.alert and o.text and o.text.text == name and o:IsShown() then return o end
        end
    end
    local s = ns.scheme
    local broken, clean, typo = row("Zap broken"), row("Zap clean"), row("Zap typo")
    check("list: an error makes the name red", broken and broken.text.textColor == s.invalid, broken and broken.text.textColor)
    check("list: and shows the alert sign", broken and broken.alert:IsShown())
    check("list: the name makes room for the sign", broken and broken.text.point[2] == broken.alert, broken and broken.text.point[2])
    check("list: the sign before the copy button", broken and broken.alert.point[2] == broken.copy)
    check("list: a warning makes it yellow, no sign", typo and typo.text.textColor == s.warning and not typo.alert:IsShown(),
        typo and typo.text.textColor)
    check("list: a clean macro stays plain", clean and clean.text.textColor == s.text and not clean.alert:IsShown()
        and clean.text.point[2] == clean.copy, clean and clean.text.textColor)
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(broken, "OnEnter")
    Fire(clean, "OnEnter")
    GameTooltip.AddLine = nil
    check("list: hover lists the issues, and where it is on the bars", table.concat(tip, "\n")
        == 'Zap broken\nLine 1: unknown condition "harmm"\nNot on your action bars now\nZap clean\nNot on your action bars now',
        table.concat(tip, " / "))
    -- Fixed elsewhere (the Blizzard window): the mark goes.
    EditMacro(broken.index, "Zap broken", 1, "/cast [harm] Fireball")
    Send("UPDATE_MACROS")
    broken = row("Zap broken")
    check("list: fixed, the mark goes", broken and broken.text.textColor == s.text and not broken.alert:IsShown(),
        broken and broken.text.textColor)
    -- Another scheme keeps the marks.
    ns.db.scheme = "monokai"
    ns.Window.ApplyLook()
    local m = ns.FindByKey(ns.schemes, "monokai")
    check("list: marks follow the scheme", typo.text.textColor == m.warning and clean.text.textColor == m.text,
        typo.text.textColor)
    ns.db.scheme = ns.DEFAULT_SCHEME
    ns.Window.ApplyLook()
    for _, name in ipairs({ "Zap broken", "Zap clean", "Zap typo" }) do DeleteMacro(GetMacroIndexByName(name)) end
    Send("UPDATE_MACROS")
end

-- Shorten: the button says how many characters it saves, a click shortens, Ctrl+Z brings the text back.
do
    local btn
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and tostring(o.label.text):find("^Shorten") then btn = o end
    end
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    local long = "/cast [@mouseover,harm,nodead] Fireball; Fireball"
    local shorter = "/cast [@mouseover,harm,nodead][]Fireball"
    Type(long)
    Key("ESCAPE", "OnEscapePressed")
    NextFrame()
    check("shorten: the button says what it saves", btn and btn.label.text == "Shorten -" .. (#long - #shorter)
        and btn:IsEnabled(), btn and btn.label.text)
    -- A line with an error is left alone, so it adds nothing.
    Type("\n/cast [harmm] Fear; Fear")
    Key("ESCAPE", "OnEscapePressed")
    NextFrame()
    check("shorten: lines with errors don't count", btn.label.text == "Shorten -" .. (#long - #shorter), btn.label.text)
    Fire(btn, "OnClick")
    NextFrame()
    check("shorten: a click shortens", raw() == shorter .. "\n/cast [harmm] Fear; Fear", raw())
    check("shorten: then nothing is left to save", btn.label.text == "Shorten" and not btn:IsEnabled(), btn.label.text)
    IsControlKeyDown = function() return true end
    Fire(edit, "OnKeyDown", "Z")
    IsControlKeyDown = function() return false end
    NextFrame()
    check("shorten: undo brings the text back", raw() == long .. "\n/cast [harmm] Fear; Fear", raw())
    check("shorten: and the button again", btn.label.text == "Shorten -" .. (#long - #shorter), btn.label.text)
    ns.Window.Select(1)
    NextFrame()
end

-- History: a saved change keeps the text it replaced, wherever it was saved; a version goes back into the
-- editor as an unsaved change.
do
    local function button(label)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.label and o.label.text == label then return o end
        end
    end
    local function rows()
        local out = {}
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() then out[#out + 1] = ns.Highlight.Strip(r.text.text) end
        end
        return out
    end
    local function nameBox()
        for _, o in ipairs(created) do
            if o.kind == "EditBox" and o ~= edit and o.text == "Hist" then return o end
        end
    end
    local history = button("History")
    CreateMacro("Hist", 1, "/cast Fireball", false)
    Send("UPDATE_MACROS")
    ns.Window.Select(GetMacroIndexByName("Hist"))
    NextFrame()
    check("history: nothing before a change", history and not history:IsEnabled())
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast Frostbolt")
    Key("ESCAPE", "OnEscapePressed")
    ns.Window.Save()
    check("history: a save keeps the text it replaced", history:IsEnabled())
    Fire(history, "OnClick")
    local shown = rows()
    check("history: the version, when and how long", MacroSenseMenu:IsShown() and #shown == 1
        and shown[1] == "Today, 14:32  14 chars", table.concat(shown, " / "))
    Fire(MacroSenseMenu.rows[1], "OnClick")
    NextFrame()
    check("history: a version goes into the editor", raw() == "/cast Fireball" and not MacroSenseMenu:IsShown(), raw())
    check("history: as an unsaved change", saveIsEnabled())
    IsControlKeyDown = function() return true end
    Fire(edit, "OnKeyDown", "Z")
    IsControlKeyDown = function() return false end
    NextFrame()
    check("history: undo takes it back", raw() == "/cast Fireball\n/cast Frostbolt", raw())
    -- Saved in the game's macro window the next day: kept too, newest first.
    clock = clock + 86400
    EditMacro(GetMacroIndexByName("Hist"), "Hist", 1, "/cast Polymorph")
    Send("UPDATE_MACROS")
    ns.Window.Revert()
    NextFrame()
    Fire(history, "OnClick")
    shown = rows()
    check("history: changes saved elsewhere count", #shown == 2 and shown[1] == "Today, 14:32  30 chars"
        and shown[2] == "Yesterday, 14:32  14 chars", table.concat(shown, " / "))
    Fire(history, "OnClick")
    check("history: a second click closes the list", not MacroSenseMenu:IsShown())
    -- A new name: the versions follow it.
    local box = nameBox()
    box:SetText("Hist2")
    ns.Window.Save()
    local store = ns.History.Store("general")
    check("history: versions follow a new name", store.Hist == nil and store.Hist2 and #store.Hist2 == 2,
        store.Hist2 and #store.Hist2)
    Fire(history, "OnClick")
    check("history: still offered after renaming", #rows() == 2, #rows())
    Fire(history, "OnClick")
    -- Character macros keep theirs per character.
    local index = CreateMacro("Mine", 1, "/cast Fire Blast", true)
    Send("UPDATE_MACROS")
    EditMacro(index, "Mine", 1, "/cast Fire Blast\n/cast Fireball")
    Send("UPDATE_MACROS")
    check("history: a character macro's versions are the character's", ns.char.history and ns.char.history.Mine
        and #ns.char.history.Mine == 1 and ns.db.history.Mine == nil)
    DeleteMacro(GetMacroIndexByName("Mine"))
    DeleteMacro(GetMacroIndexByName("Hist2"))
    Send("UPDATE_MACROS")
    clock = clock - 86400
    ns.Window.Select(1)
    NextFrame()
end

-- The name, then Tab or Enter: on to the text. A new macro whose icon was not picked gets the icon of the spell
-- or item it is named after; one picked, a saved macro's, and the question mark of #showtooltip stay.
do
    local box
    for _, o in ipairs(created) do
        if o.kind == "EditBox" and o.maxLetters == 16 then box = o end
    end
    local function header()
        for _, o in ipairs(created) do
            if o.kind == "Texture" and o.parentFrame == MacroSenseIconButton and o.texture then return o.texture end
        end
    end
    local function named(name, key)
        box:SetFocus()
        box:SetText(name)
        Fire(box, key or "OnEnterPressed")
        return header()
    end
    ns.Window.New()
    NextFrame()
    check("name: Enter goes on to the text", named("Polymorph") == ns.IconTexture(6) and edit:HasFocus()
        and not box:HasFocus(), header())
    check("name: Tab too", named("frostbolt", "OnTabPressed") == ns.IconTexture(5) and edit:HasFocus())
    check("name: an item", named("Healthstone") == ns.IconTexture(5512))
    check("name: none found, the question mark again", named("Mount") == ns.IconTexture(134400))
    edit:SetFocus()
    Type("#showtooltip")
    check("name: #showtooltip keeps the question mark", named("Fire Blast") == ns.IconTexture(134400))
    ns.Window.Revert()
    ns.Window.New()
    NextFrame()
    named("Fire Blast")
    ns.Window.Save()
    check("name: the icon is saved", select(2, GetMacroInfo(GetMacroIndexByName("Fire Blast"))) == 4)
    check("name: a saved macro keeps its icon", named("Polymorph") == ns.IconTexture(4) and edit:HasFocus())
    ns.Window.Revert()
    DeleteMacro(GetMacroIndexByName("Fire Blast"))
    Send("UPDATE_MACROS")
    ns.Window.New()
    NextFrame()
    Fire(MacroSenseIconButton, "OnClick")
    local grid = {}
    for _, o in ipairs(created) do if o.kind == "Button" and o.entry and o:IsShown() then grid[#grid + 1] = o end end
    Fire(grid[1], "OnClick") -- the question mark, picked
    MacroSenseIconPicker:Hide()
    check("name: a picked icon stays", named("Polymorph") == ns.IconTexture(134400))
    ns.Window.New()
    NextFrame()
    check("name: picked for the macro before, not this one", named("Polymorph") == ns.IconTexture(6))
    box:SetText("")
    ns.Window.Select(1)
    NextFrame()
end

-- Copy: the copy button of each macro in the list, a duplicate in the same tab or a copy in the other one, under
-- a free name. The macro being edited with what the editor shows; another one as saved. There is no Copy button.
do
    local function row(name)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.alert and o.text and o.text.text == name and o:IsShown() then return o end
        end
    end
    local function menuItem(label)
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() and ns.Highlight.Strip(r.text.text):sub(1, #label) == label then return r end
        end
    end
    local function nameText()
        for _, o in ipairs(created) do
            if o.kind == "EditBox" and o.maxLetters == 16 then return o.text end
        end
    end
    local function itemTip(label)
        local tip = {}
        GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
        Fire(menuItem(label), "OnEnter")
        GameTooltip.AddLine = nil
        return tip[2]
    end
    local function body(name) return select(3, GetMacroInfo(GetMacroIndexByName(name))) end
    local copyButton
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Copy" then copyButton = o end
    end
    check("copy: no Copy button", copyButton == nil)
    CreateMacro("Zap", 1, "/cast Fireball", false)
    Send("UPDATE_MACROS")
    ns.Window.Select(GetMacroIndexByName("Zap"))
    NextFrame()
    local copy = row("Zap").copy
    check("copy: a button on each macro, before its x", copy:IsShown() and copy.mark.texture
        == "Interface\\AddOns\\MacroSense\\Media\\copy" and copy.point[2] == row("Zap").remove
        and row("Zap").text.point[2] == copy)
    check("copy: both dim", copy.mark.vertexColor == ns.scheme.dim and row("Zap").remove.mark.textColor == ns.scheme.dim)
    local wizard
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "New (Wizard)" then wizard = o end
    end
    check("copy: New and New (Wizard) in one row, the list down to it", wizard.point[1] == "BOTTOMRIGHT"
        and wizard.point[3] == 36 and MacroSenseListScroll.point[3] == 66)
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(copy, "OnEnter")
    GameTooltip.AddLine = nil
    check("copy: says what it does, lights up", tip[1] == "Copy this macro" and copy.mark.vertexColor == ns.scheme.text
        and row("Zap").bg:IsShown(), tip[1])
    Fire(copy, "OnLeave")
    check("copy: dim again", copy.mark.vertexColor == ns.scheme.dim, copy.mark.vertexColor)
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast Frostbolt")
    Key("ESCAPE", "OnEscapePressed")
    Fire(copy, "OnClick")
    check("copy: the menu opens under the button", MacroSenseMenu:IsShown() and MacroSenseMenu.point[1] == "TOPRIGHT"
        and MacroSenseMenu.point[2] == copy, MacroSenseMenu.point and MacroSenseMenu.point[1])
    check("copy: the one being edited, with what the editor shows", itemTip("Duplicate") == "A copy in this tab with "
        .. "what the editor shows now, under a free name like \"Fear 2\". The macro copied keeps its saved text.",
        itemTip("Duplicate"))
    Fire(menuItem("Duplicate"), "OnClick")
    NextFrame()
    check("copy: a duplicate under a free name, with the text shown", GetMacroIndexByName("Zap 2") > 0
        and body("Zap 2") == "/cast Fireball\n/cast Frostbolt", GetMacroIndexByName("Zap 2"))
    check("copy: the macro copied keeps its saved text", body("Zap") == "/cast Fireball", body("Zap"))
    check("copy: the copy is opened", nameText() == "Zap 2" and raw() == "/cast Fireball\n/cast Frostbolt"
        and not saveIsEnabled(), nameText())
    Fire(row("Zap 2").copy, "OnClick")
    Fire(menuItem("Copy to Character"), "OnClick")
    NextFrame()
    local index = GetMacroIndexByName("Zap 3")
    check("copy: to the other tab, the next free name", index > SLOTS.MAX_ACCOUNT_MACROS and ns.db.scope == "character"
        and nameText() == "Zap 3", index)
    Fire(row("Zap 3").copy, "OnClick")
    check("copy: from Character, the other tab is General", menuItem("Copy to General") ~= nil)
    MacroSenseMenu:Hide()

    -- Another macro: copied as saved, after asking about the unsaved changes here.
    ns.Window.SetScope("general")
    ns.Window.Select(GetMacroIndexByName("Zap"))
    NextFrame()
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    Fire(row("Zap 2").copy, "OnClick")
    check("copy: another one, as saved", itemTip("Duplicate") == "A copy in this tab, under a free name like "
        .. "\"Fear 2\".", itemTip("Duplicate"))
    local asked, show = 0, StaticPopup_Show
    StaticPopup_Show = function(...)
        asked = asked + 1
        return show(...)
    end
    Fire(menuItem("Duplicate"), "OnClick")
    StaticPopup_Show = show
    NextFrame()
    check("copy: another one, after asking", asked == 1 and body("Zap 4") == "/cast Fireball\n/cast Frostbolt"
        and nameText() == "Zap 4" and body("Zap") == "/cast Fireball", body("Zap 4"))
    check("copy: with its icon", select(2, GetMacroInfo(GetMacroIndexByName("Zap 4"))) == 1)

    -- A full tab can't take one.
    local fillers = SLOTS.MAX_CHARACTER_MACROS - select(2, GetNumMacros())
    for i = 1, fillers do CreateMacro("Filler " .. i, 1, "/sit", true) end
    Send("UPDATE_MACROS")
    ns.Window.Select(GetMacroIndexByName("Zap"))
    NextFrame()
    Fire(row("Zap").copy, "OnClick")
    local full = menuItem("Copy to Character")
    check("copy: a full tab is marked", full and full.item.disabled and full.text.text:find("(full)", 1, true) ~= nil)
    local count = select(2, GetNumMacros())
    Fire(full, "OnClick")
    check("copy: and takes nothing", select(2, GetNumMacros()) == count and MacroSenseMenu:IsShown())
    MacroSenseMenu:Hide()
    -- A long name is cut to make room for the number, a whole letter at a time.
    CreateMacro("Сімнадцять літер", 1, "/sit", false) -- 16 letters, Cyrillic: two bytes each
    Send("UPDATE_MACROS")
    ns.Window.Select(GetMacroIndexByName("Сімнадцять літер"))
    NextFrame()
    ns.Window.Copy("general")
    check("copy: a long name is cut", GetMacroIndexByName("Сімнадцять літ 2") > 0, nameText())
    -- Not for a macro that is not saved yet, and not in combat.
    InCombatLockdown = function() return true end
    count = select(1, GetNumMacros())
    ns.Window.Copy("general")
    check("copy: not in combat", select(1, GetNumMacros()) == count and printed[#printed]:find("in combat") ~= nil)
    InCombatLockdown = function() return false end
    ns.Window.New()
    NextFrame()
    ns.Window.Copy("general")
    check("copy: not before the macro is saved", select(1, GetNumMacros()) == count)
    for _, name in ipairs({ "Zap", "Zap 2", "Zap 3", "Zap 4", "Сімнадцять літер", "Сімнадцять літ 2" }) do
        DeleteMacro(GetMacroIndexByName(name))
    end
    for i = 1, fillers do DeleteMacro(GetMacroIndexByName("Filler " .. i)) end
    Send("UPDATE_MACROS")
    ns.Window.Select(1)
    NextFrame()
end

-- Search: the list keeps macros whose name or text has the words, in any case; the tabs count matches.
do
    local function shownNames()
        local out = {}
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.alert and o.text and o:IsShown() then out[#out + 1] = o.text.text end
        end
        table.sort(out)
        return table.concat(out, ", ")
    end
    local function tabLabel(prefix)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.label and tostring(o.label.text):sub(1, #prefix) == prefix and o.line then
                return o.label.text
            end
        end
    end
    local function noMatch()
        for _, o in ipairs(created) do
            if o.kind == "FontString" and o.text == "No macros match" then return o:IsShown() end
        end
    end
    CreateMacro("Fear Focus", 1, "/cast [@focus] Fear", false)
    CreateMacro("Heal", 1, "/cast [@mouseover,help] Flash Heal", false)
    CreateMacro("Sic", 1, "/petattack", true)
    Send("UPDATE_MACROS")
    local search = MacroSenseSearch
    search:SetText("FEAR")
    check("search: by name, in any case", shownNames() == "Fear Focus", shownNames())
    search:SetText("flash")
    check("search: by text", shownNames() == "Heal", shownNames())
    check("search: the tabs count matches", tabLabel("General") == "General  (1)"
        and tabLabel("Character") == "Character  (0)", tabLabel("General"))
    search:SetText("petattack")
    check("search: nothing here, the other tab has it", shownNames() == "" and noMatch()
        and tabLabel("Character") == "Character  (1)", tabLabel("Character"))
    -- Enter opens the first match, Esc brings every macro back.
    search:SetText("heal")
    search:SetFocus()
    Fire(search, "OnEnterPressed")
    NextFrame()
    check("search: Enter opens the first match", raw() == "/cast [@mouseover,help] Flash Heal" and not search:HasFocus(),
        raw())
    Fire(search, "OnEscapePressed")
    check("search: Esc shows every macro again", search.text == "" and shownNames():find("Fear Focus", 1, true)
        and shownNames():find("Nuke", 1, true) and tabLabel("General"):find("/120", 1, true), shownNames())
    check("search: no note without a search", not noMatch())
    -- Ctrl+F (Cmd+F) in the editor goes to the search; closing the window clears it.
    edit:SetFocus()
    IsControlKeyDown = function() return true end
    Fire(edit, "OnKeyDown", "F")
    IsControlKeyDown = function() return false end
    check("search: Ctrl+F goes to the search", search:HasFocus())
    search:SetText("fear")
    ns.Window.Toggle()
    ns.Window.Toggle()
    NextFrame()
    check("search: cleared when the window closes", search.text == "" and shownNames():find("Heal", 1, true) ~= nil,
        shownNames())
    for _, name in ipairs({ "Fear Focus", "Heal", "Sic" }) do DeleteMacro(GetMacroIndexByName(name)) end
    Send("UPDATE_MACROS")
    ns.Window.Select(1)
    NextFrame()
end

-- /castsequence reset=: values offered after "=" and each "/", a word on its way is not marked, a wrong one is.
do
    local function underlines()
        local n = 0
        for _, o in ipairs(created) do if o.isUnderline and o:IsShown() then n = n + 1 end end
        return n
    end
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    Type("/castsequence reset=")
    check("reset: values offered", ns.Popup:IsShown() and ns.Popup.items[1].name == "target",
        ns.Popup.items[1] and ns.Popup.items[1].name)
    Type("ta")
    NextFrame()
    check("reset: a value on its way is not marked", underlines() == 0, underlines())
    Key("TAB", "OnTabPressed")
    check("reset: Tab takes it", raw() == "/castsequence reset=target", raw())
    Type("/")
    check("reset: after / the others", ns.Popup:IsShown() and ns.Popup.items[1].name == "combat",
        ns.Popup.items[1] and ns.Popup.items[1].name)
    Type("tagret")
    Key("ESCAPE", "OnEscapePressed")
    Wait(1)
    check("reset: a wrong value is marked", underlines() == 1, underlines())
    ns.Window.Select(1)
    NextFrame()
end

-- Items by where they are: "/use 1" offers the equipment slots with what is in them, "/use 0 " the slots of
-- that bag that hold something; /equipslot takes the slot first, then gear. A slot that doesn't exist is marked.
do
    local function statusError()
        for _, o in ipairs(created) do
            if o.kind == "FontString" and tostring(o.text):find("Line %d+:") then return o.text end
        end
        return ""
    end
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    Type("/use 1")
    local items, trinket = ns.Popup.items, nil
    for _, it in ipairs(items) do if it.name == "13" then trinket = it end end
    check("slots: offered after a digit", ns.Popup:IsShown() and items[1].name == "1" and items[1].hint == "Head",
        items[1] and items[1].hint)
    check("slots: with what is in them", trinket and trinket.hint == "Trinket 1: Lucky Charm", trinket and trinket.hint)
    Key("ESCAPE", "OnEscapePressed")
    Type("\n/use 0 ")
    items = ns.Popup.items
    check("bag slots: what that bag holds", ns.Popup:IsShown() and #items == 2 and items[1].name == "1"
        and items[1].hint == "Healthstone" and items[2].hint == "Fire Ring", #items)
    Key("ESCAPE", "OnEscapePressed")
    Type("\n/equipslot ")
    check("equipslot: the slots first", ns.Popup:IsShown() and ns.Popup.items[1].name == "1",
        ns.Popup.items[1] and ns.Popup.items[1].name)
    Type("13 ")
    check("equipslot: then gear", ns.Popup:IsShown() and ns.Popup.items[1].name == "Fire Ring",
        ns.Popup.items[1] and ns.Popup.items[1].name)
    Key("ESCAPE", "OnEscapePressed")
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    Type("/use 23")
    Key("ESCAPE", "OnEscapePressed")
    Wait(1)
    check("slots: one that doesn't exist is marked", statusError():find("no equipment slot 23", 1, true) ~= nil,
        statusError())
    ns.Window.Select(1)
    NextFrame()
end

-- /click: the buttons there are now, with what is on them; a name no button has is a warning.
do
    local function statusText()
        for _, o in ipairs(created) do
            if o.kind == "FontString" and tostring(o.text):find("Line %d+:") then return o.text end
        end
        return ""
    end
    ActionButton1 = New("Button", "ActionButton1")
    ActionButton1.action = 1 -- the slot with macro 1 on it, which shows Fireball
    actions[1] = { "macro", 133, "spell", text = (GetMacroInfo(1)) }
    BT4Button3 = New("Frame", "BT4Button3") -- not a button: not offered
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    Type("/click Act")
    local items = ns.Popup.items
    check("click: the bar's buttons, with what is on them", ns.Popup:IsShown() and #items == 1
        and items[1].name == "ActionButton1" and items[1].hint == GetMacroInfo(1), items[1] and items[1].hint)
    Key("TAB", "OnTabPressed")
    Type(" ")
    check("click: then the mouse buttons", ns.Popup:IsShown() and ns.Popup.items[1].name == "LeftButton",
        ns.Popup.items[1] and ns.Popup.items[1].name)
    Key("ESCAPE", "OnEscapePressed")
    Type("\n/click BT4Button3")
    Key("ESCAPE", "OnEscapePressed")
    Wait(1)
    check("click: a frame that is not a button", statusText():find("not a button", 1, true) ~= nil, statusText())
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    Type("/click Nope")
    Key("ESCAPE", "OnEscapePressed")
    Wait(1)
    check("click: a name no button has", statusText():find("no such button now", 1, true) ~= nil, statusText())
    ns.Window.Select(1)
    NextFrame()
end

-- The minimap button: where it was left on the edge; a click opens and closes the editor, a drag moves it
-- along the edge (along the sides of a square minimap), /ms minimap hides it until it is asked back.
do
    local b, r = MacroSenseMinimapButton, 140 / 2 + 5
    local function at() return string.format("%.1f,%.1f", b.point[4], b.point[5]) end
    local function drag(x, y)
        Fire(b, "OnDragStart")
        cursorX, cursorY = x, y
        NextFrame()
        Fire(b, "OnDragStop")
    end
    check("minimap: the button is on the minimap", b and b:IsShown() and b.point[2] == Minimap)
    check("minimap: where it was left", at() == string.format("%.1f,%.1f", r * math.cos(math.rad(250)),
        r * math.sin(math.rad(250))), at())
    local open = MacroSenseFrame:IsShown()
    Fire(b, "OnClick", "LeftButton")
    check("minimap: a click closes the editor", MacroSenseFrame:IsShown() == not open)
    Fire(b, "OnClick", "LeftButton")
    check("minimap: and opens it", MacroSenseFrame:IsShown() == open)
    drag(1000 - 300, 600)
    check("minimap: a drag moves it along the edge", at() == "-75.0,0.0" and math.abs(ns.db.minimapAngle - 180) < 1e-6,
        at())
    cursorX = 1000 + 300
    NextFrame()
    check("minimap: it stays when let go", at() == "-75.0,0.0", at())
    GetMinimapShape = function() return "SQUARE" end
    drag(1000 + 100, 600 + 50)
    check("minimap: on the side of a square minimap", at() == "75.0,37.5", at())
    GetMinimapShape = nil
    -- An addon makes the minimap bigger: the button keeps to its edge.
    Minimap.GetWidth, Minimap.GetHeight = function() return 200 end, function() return 200 end
    Fire(Minimap, "OnSizeChanged", 200, 200)
    local a = math.rad(ns.db.minimapAngle)
    check("minimap: on the edge of a bigger minimap",
        at() == string.format("%.1f,%.1f", 105 * math.cos(a), 105 * math.sin(a)), at())
    Minimap.GetWidth, Minimap.GetHeight = function() return 140 end, function() return 140 end
    Fire(Minimap, "OnSizeChanged", 140, 140)
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(b, "OnEnter")
    GameTooltip.AddLine = nil
    check("minimap: the tooltip says what it does", table.concat(tip, "\n"):find("Drag: move the button", 1, true)
        and table.concat(tip, "\n"):find("/ms minimap hides it", 1, true), table.concat(tip, " / "))
    SlashCmdList.MACROSENSE("minimap")
    check("minimap: /ms minimap hides it", not b:IsShown() and ns.db.minimapButton == false
        and printedWith("minimap button |cffff0000off"))
    Send("PLAYER_LOGIN")
    check("minimap: still hidden after the next login", not b:IsShown())
    SlashCmdList.MACROSENSE("minimap")
    check("minimap: /ms minimap brings it back", b:IsShown() and ns.db.minimapButton == true)
    -- Retail: the addon menu by the minimap calls the function the TOC names.
    local fn
    for line in io.lines("MacroSense/MacroSense.toc") do fn = fn or line:match("^## AddonCompartmentFunc: (%S+)") end
    check("compartment: the TOC names a function", fn and type(_G[fn]) == "function", fn)
    _G[fn]("MacroSense", "LeftButton")
    check("compartment: it opens or closes the editor", MacroSenseFrame:IsShown() == not open)
    _G[fn]("MacroSense", "LeftButton")
end

-- Wizard: a window with a form; the macro shows under it as you choose, Create macro saves it and opens it.
do
    local function button(label)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.label and o.label.text == label then return o end
        end
    end
    local function menuItem(label)
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() and r.text.text == label then return r end
        end
    end
    local editorName
    for _, o in ipairs(created) do
        if o.kind == "EditBox" and o.maxLetters == 16 then editorName = o end
    end
    local C = ns.WizardWindow.Control
    -- A player types into a box of the form: it takes the focus, then the letters come.
    local function TypeIn(box, text)
        box:SetFocus()
        Fire(box, "OnEditFocusGained")
        box.text = text
        Fire(box, "OnTextChanged", true)
    end
    local function offered(box)
        local out = {}
        for _, r in ipairs(box.list.rows) do
            if r:IsShown() then out[#out + 1] = r.text.text end
        end
        return table.concat(out, ", ")
    end
    local function pick(dropdown, label)
        Fire(dropdown, "OnClick")
        Fire(menuItem(label), "OnClick")
    end
    local function shown() return ns.Highlight.Strip(C("preview").text) end
    local function body(name) return select(3, GetMacroInfo(GetMacroIndexByName(name))) end
    local wizardBtn = button("New (Wizard)")

    if not MacroSenseFrame:IsShown() then ns.Window.Toggle() end
    ns.Window.SetScope("general")
    ns.Window.Select(1)
    NextFrame()
    local count, before, first = GetNumMacros(), raw(), GetMacroInfo(1)
    Fire(wizardBtn, "OnClick")
    check("wizard: a window of its own", MacroSenseWizard and MacroSenseWizard:IsShown() and raw() == before)
    check("wizard: step by step the first time", C("mode").label.text == "All options"
        and C("question").text == "What should the macro do?" and MacroSenseWizard.height == 538, C("question").text)
    Fire(C("mode"), "OnClick")
    check("wizard: the whole form", C("mode").label.text == "Step by step" and ns.db.wizardForm == true
        and C("cancel").shown and not C("back").shown, C("mode").label.text)
    check("wizard: nothing to create yet", shown():find("Pick a spell", 1, true) ~= nil and not C("create"):IsEnabled(),
        shown())
    check("wizard: into the tab that is open", C("tab").label.text == "General", C("tab").label.text)

    local cast = C("cast")
    TypeIn(cast, "FB")
    check("wizard: a name by the first letters of its words", offered(cast) == "Fire Blast", offered(cast))
    TypeIn(cast, "fb")
    check("wizard: small letters in a word, in that order", offered(cast) == "Fireball, Frostbolt", offered(cast))
    TypeIn(cast, "fire")
    check("wizard: your spells and the items you can use", offered(cast) == "Fire Blast, Fireball", offered(cast))
    Fire(cast, "OnArrowPressed", "DOWN")
    Fire(cast, "OnEnterPressed")
    check("wizard: Enter takes the name the arrows picked, its ranks next", cast.text == "Fireball"
        and offered(cast) == "Fireball, Fireball(Rank 3), Fireball(Rank 2), Fireball(Rank 1)"
        and cast.list.rows[1].hint.text == "highest rank", offered(cast))
    Fire(cast, "OnArrowPressed", "DOWN")
    Fire(cast, "OnArrowPressed", "DOWN")
    Fire(cast, "OnEnterPressed")
    check("wizard: a rank picked", cast.text == "Fireball(Rank 2)" and not cast.list:IsShown()
        and shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Fireball(Rank 2)", shown())
    pick(C("command"), "/cast")
    check("wizard: and shown with it", cast.text == "Fireball(Rank 2)", cast.text)
    -- A click: the box loses the keys first (the game takes them away), and gets them back for the ranks.
    TypeIn(cast, "fireball")
    cast.list.IsMouseOver = function() return true end
    cast:ClearFocus()
    Fire(cast.list.rows[1], "OnClick")
    cast.list.IsMouseOver = nil
    check("wizard: a click on a spell with ranks: the keys stay for them", cast:HasFocus() and cast.list:IsShown()
        and cast.list.rows[2].text.text == "Fireball(Rank 3)", cast.list.rows[2].text.text)
    Fire(cast, "OnEscapePressed")
    Fire(cast, "OnEscapePressed")
    TypeIn(cast, "fireball")
    Fire(cast, "OnEnterPressed")
    Fire(cast, "OnEnterPressed")
    check("wizard: the spell itself: the highest rank", cast.text == "Fireball" and not cast.list:IsShown(), cast.text)
    check("wizard: the macro shows as you choose", shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Fireball",
        shown())
    check("wizard: enemies, as the spell is for them", C("only").label.text == "Enemies", C("only").label.text)
    check("wizard: named after it", C("name").text == "Fireball", C("name").text)
    check("wizard: how long it is", C("create"):IsEnabled()
        and ns.Highlight.Strip(C("counter").text) == #shown() .. " / 255", C("counter").text)

    TypeIn(cast, "stone")
    Fire(cast.list.rows[1], "OnClick")
    check("wizard: a click picks a name; an item for friends, with /use",
        shown() == "#showtooltip\n/use [@mouseover,help,nodead][] Healthstone", shown())
    check("wizard: the name follows", C("name").text == "Healthstone", C("name").text)
    pick(C("on2"), "Your target")
    pick(C("on3"), "Yourself")
    check("wizard: on whom, in order",
        shown() == "#showtooltip\n/use [@mouseover,help,nodead][help,nodead][@player] Healthstone", shown())
    Fire(C("alive"), "OnClick")
    check("wizard: dead ones too", shown() == "#showtooltip\n/use [@mouseover,help][help][@player] Healthstone", shown())
    Fire(C("alive"), "OnClick")

    TypeIn(cast, "frost")
    Fire(cast, "OnEnterPressed")
    pick(C("on2"), "As usual")
    check("wizard: nothing after As usual", shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Frostbolt", shown())
    Fire(C("shift"), "OnClick")
    TypeIn(C("shiftCast"), "poly")
    Fire(C("shiftCast"), "OnEnterPressed")
    pick(C("shiftOn"), "Focus")
    check("wizard: Shift casts another spell on another unit", shown()
        == "#showtooltip\n/cast [mod:shift,@focus,harm,nodead] Polymorph; [@mouseover,harm,nodead][] Frostbolt", shown())
    Fire(C("ctrl"), "OnClick")
    pick(C("ctrlOn"), "Yourself")
    check("wizard: Ctrl casts the same one on yourself", shown() == "#showtooltip\n/cast [mod:shift,@focus,harm,nodead] "
        .. "Polymorph; [mod:ctrl,@player][@mouseover,harm,nodead][] Frostbolt", shown())
    Fire(C("ctrl"), "OnClick")
    check("wizard: the list under a narrow box is wide enough for long names", C("shiftCast").list.width == 260
        and C("cast").list.width == 330, C("shiftCast").list.width)
    pick(C("shiftThen"), "Your target")
    check("wizard: a key falls back too", shown() == "#showtooltip\n/cast [mod:shift,@focus,harm,nodead]"
        .. "[mod:shift,harm,nodead] Polymorph; [@mouseover,harm,nodead][] Frostbolt", shown())
    check("wizard: Cmd too, on a Mac", C("cmd") ~= nil and C("cmd").label.text == "Cmd")
    Fire(C("cmd"), "OnClick")
    TypeIn(C("cmdCast"), "fire b")
    Fire(C("cmdCast"), "OnEnterPressed")
    check("wizard: Cmd casts another spell", shown() == "#showtooltip\n/cast [mod:shift,@focus,harm,nodead]"
        .. "[mod:shift,harm,nodead] Polymorph; [mod:cmd] Fire Blast; [@mouseover,harm,nodead][] Frostbolt", shown())
    Fire(C("cmd"), "OnClick")
    check("wizard: the trinkets by what is in the slot", C("trinket1").label.text == "Trinket 1: Lucky Charm"
        and C("trinket2").label.text == "Trinket 2: empty", C("trinket1").label.text)
    -- A long name is cut to stay in the window.
    local equipped = GetInventoryItemLink
    GetInventoryItemLink = function(unit, slot)
        if slot == 14 then return "|cffa335ee|Hitem:888::|h[Unbound Changeling of the Endless Night]|h|r" end
        return equipped(unit, slot)
    end
    Fire(wizardBtn, "OnClick")
    Fire(wizardBtn, "OnClick")
    check("wizard: a long trinket name cut", C("trinket2").label.text == "Trinket 2: Unbound Chang...",
        C("trinket2").label.text)
    GetInventoryItemLink = equipped
    TypeIn(cast, "frost")
    Fire(cast, "OnEnterPressed")
    pick(C("on2"), "As usual")
    Fire(C("shift"), "OnClick")
    TypeIn(C("shiftCast"), "poly")
    Fire(C("shiftCast"), "OnEnterPressed")
    pick(C("shiftOn"), "Focus")
    C("name"):SetText("Burst")
    Fire(C("stopcasting"), "OnClick")
    Fire(C("trinket1"), "OnClick")
    check("wizard: a name you typed stays", C("name").text == "Burst", C("name").text)
    local burst = "#showtooltip Frostbolt\n/stopcasting\n/use 13\n"
        .. "/cast [mod:shift,@focus,harm,nodead] Polymorph; [@mouseover,harm,nodead][] Frostbolt"
    check("wizard: and what else it does", shown() == burst, shown())

    -- Create macro: saved under the name in the box, opened in the editor (unsaved changes there asked about
    -- first: the fake dialog says yes).
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    Key("ESCAPE", "OnEscapePressed")
    Fire(C("create"), "OnClick")
    check("wizard: Create macro saves it", GetMacroIndexByName("Burst") > 0 and GetNumMacros() == count + 1
        and body("Burst") == burst, GetNumMacros())
    check("wizard: and opens it in the editor", not MacroSenseWizard:IsShown() and editorName.text == "Burst"
        and raw() == burst and not saveIsEnabled(), editorName.text)
    check("wizard: the macro edited before kept its saved text", body(first) == before, body(first))

    -- Fresh each time; a name that is taken gets a number; the tab chosen.
    Fire(wizardBtn, "OnClick")
    check("wizard: a fresh form", C("cast").text == "" and not C("shift").fill:IsShown()
        and C("on2").label.text == "As usual" and C("shiftThen").label.text == "-"
        and shown():find("Pick a spell", 1, true) ~= nil)
    TypeIn(C("cast"), "frost")
    Fire(C("cast"), "OnEnterPressed")
    C("name"):SetText("Burst")
    Fire(C("create"), "OnClick")
    check("wizard: a free name", GetMacroIndexByName("Burst 2") > 0, GetNumMacros())
    Fire(wizardBtn, "OnClick")
    TypeIn(C("cast"), "poly")
    Fire(C("cast"), "OnEnterPressed")
    pick(C("tab"), "Character")
    Fire(C("create"), "OnClick")
    local index = GetMacroIndexByName("Polymorph")
    check("wizard: into the tab chosen", index > SLOTS.MAX_ACCOUNT_MACROS and ns.db.scope == "character", index)
    Fire(wizardBtn, "OnClick")
    check("wizard: the tab open now first", C("tab").label.text == "Character", C("tab").label.text)

    -- Commands: /use offers the items first and the slots with a use effect; /castsequence and /castrandom take a
    -- list; the window is as tall as the command's form.
    local function last(label)
        local found
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.label and o.label.text == label then found = o end
        end
        return found
    end
    local gear = GetInventoryItemLink
    GetInventoryItemLink = function(unit, slot)
        if slot == 14 then return "|cffa335ee|Hitem:5512::|h[Burning Talisman]|h|r" end
        return gear(unit, slot)
    end
    local tall = MacroSenseWizard.height
    pick(C("command"), "/use")
    check("wizard: /use", C("castLabel").text == "Use" and MacroSenseWizard.height == tall, C("castLabel").text)
    TypeIn(C("cast"), "")
    check("wizard: /use offers the items first, then the slots", offered(C("cast")):find("^Healthstone, 14, Fire") ~= nil,
        offered(C("cast")))
    TypeIn(C("cast"), "1")
    check("wizard: /use offers the slots with a use effect", offered(C("cast")) == "14", offered(C("cast")))
    Fire(C("cast"), "OnEnterPressed")
    check("wizard: a slot, named after what is in it", shown() == "#showtooltip\n/use [@mouseover,exists,nodead][] 14"
        and C("name").text == "Burning Talisman", shown())
    GetInventoryItemLink = gear
    TypeIn(C("cast"), "fire")
    Fire(C("cast"), "OnArrowPressed", "DOWN")
    Fire(C("cast"), "OnEnterPressed")
    check("wizard: a spell picked: /cast again", C("command").label.text == "/cast" and C("castLabel").text == "Cast"
        and shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Fireball", C("command").label.text)
    pick(C("command"), "/castsequence")
    check("wizard: /castsequence takes a list, the spell first", C("list1").text == "Fireball"
        and C("listTitle").text == "In turn, one per press" and MacroSenseWizard.height == tall + 10,
        MacroSenseWizard.height)
    TypeIn(C("list2"), "frost")
    Fire(C("list2"), "OnEnterPressed")
    Fire(C("resetTarget"), "OnClick")
    Fire(C("resetTimed"), "OnClick")
    Fire(last("+"), "OnClick")
    check("wizard: in turn, and what starts it over", shown()
        == "#showtooltip\n/castsequence [@mouseover,harm,nodead][] reset=11/target Fireball, Frostbolt", shown())
    pick(C("command"), "/castrandom")
    check("wizard: /castrandom: one of them, nothing starts it over", shown()
        == "#showtooltip\n/castrandom [@mouseover,harm,nodead][] Fireball, Frostbolt"
        and C("listTitle").text == "One of these at random" and MacroSenseWizard.height == tall - 72, shown())
    pick(C("command"), "/cast")
    check("wizard: back to /cast, its spell kept", shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Fireball"
        and MacroSenseWizard.height == tall, shown())
    TypeIn(C("cast"), "")
    Fire(C("cast"), "OnEnterPressed")
    pick(C("command"), "/castsequence")
    TypeIn(C("list1"), "frost")
    Fire(C("list1"), "OnEnterPressed")
    pick(C("command"), "/cast")
    check("wizard: a /cast with no spell takes the list's first", C("cast").text == "Frostbolt"
        and shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Frostbolt", shown())
    pick(C("command"), "/castrandom")
    TypeIn(C("list3"), "")
    Fire(C("list3"), "OnEnterPressed")
    check("wizard: Enter in an empty box leaves it empty", C("list3").text == "", C("list3").text)
    TypeIn(C("list3"), "")
    Fire(C("list3"), "OnArrowPressed", "DOWN")
    Fire(C("list3"), "OnEnterPressed")
    check("wizard: or takes the name picked with the arrows", C("list3").text == "Fireball", C("list3").text)
    pick(C("command"), "/cast")
    Fire(C("nearest"), "OnClick")
    check("wizard: the nearest enemy first", shown()
        == "#showtooltip\n/targetenemy [noharm][dead]\n/cast [@mouseover,harm,nodead][] Frostbolt", shown())
    Fire(C("nearest"), "OnClick")

    -- /target, /focus, /assist: units only (As usual becomes your target); a key may clear; /target by name.
    pick(C("command"), "/focus")
    check("wizard: /focus on units, no icon line", shown() == "/focus [@mouseover,harm,nodead][@target,harm,nodead]"
        and C("on2").label.text == "Your target" and MacroSenseWizard.height == tall - 34, shown())
    check("wizard: a key's units where the spell was", not C("shiftCast"):IsShown() and C("shiftOn").point[2] == 84,
        C("shiftOn").point[2])
    Fire(C("shift"), "OnClick")
    pick(C("shiftOn"), "Clear focus")
    check("wizard: Shift clears the focus", shown() == "/clearfocus [mod:shift]\n/stopmacro [mod:shift]\n"
        .. "/focus [@mouseover,harm,nodead][@target,harm,nodead]" and C("name").text == "Focus", shown())
    pick(C("command"), "/target")
    check("wizard: /target, not on your target", shown() == "/cleartarget [mod:shift]\n/stopmacro [mod:shift]\n"
        .. "/target [@mouseover,harm,nodead]" and C("on2").label.text == "-" and MacroSenseWizard.height == tall, shown())
    TypeIn(C("byName"), "Hogger")
    check("wizard: /target by name", shown() == "/cleartarget [mod:shift]\n/stopmacro [mod:shift]\n"
        .. "/target [@mouseover,harm,nodead][] Hogger" and C("name").text == "Hogger", shown())
    TypeIn(C("byName"), "")
    pick(C("only"), "Friends")
    pick(C("on1"), "Party member 1")
    pick(C("shiftOn"), "Party member 2")
    check("wizard: party members by key", shown() == "/target [mod:shift,@party2,help,nodead][@party1,help,nodead]",
        shown())
    pick(C("command"), "/assist")
    check("wizard: /assist", shown() == "/assist [mod:shift,@party2,help,nodead][@party1,help,nodead]"
        and MacroSenseWizard.height == tall - 34, shown())
    pick(C("command"), "/cast")
    check("wizard: back to /cast: the spell, the keys in their places", shown()
        == "#showtooltip\n/cast [mod:shift,@party2,help,nodead][@party1,help,nodead] Frostbolt"
        and C("shiftCast"):IsShown() and C("shiftOn").point[2] == 242, shown())
    Fire(C("shift"), "OnClick")

    -- Pet commands: what it does without a key, a command per key; units only for Attack.
    pick(C("only"), "Enemies")
    pick(C("on1"), "Mouseover")
    pick(C("on2"), "As usual")
    pick(C("command"), "Pet commands")
    check("wizard: the pet attacks the mouseover, then your target", shown()
        == "/petattack [@mouseover,harm,nodead][]" and MacroSenseWizard.height == tall and C("name").text == "Pet",
        shown())
    Fire(C("shift"), "OnClick")
    check("wizard: Shift: the pet follows, no units for that", shown() == "/petattack [nomod:shift,@mouseover,"
        .. "harm,nodead][nomod:shift]\n/petfollow [mod:shift]" and not C("shiftOn"):IsShown()
        and C("shiftPet"):IsShown() and not C("shiftCast"):IsShown(), shown())
    pick(C("shiftPet"), "Attack")
    pick(C("shiftOn"), "Focus")
    check("wizard: Shift: the pet attacks the focus", C("shiftOn"):IsShown() and shown():find(
        "\n/petattack [mod:shift,@focus,harm,nodead]", 1, true) ~= nil, shown())
    pick(C("pet"), "Follow")
    Fire(C("ctrl"), "OnClick")
    pick(C("ctrlPet"), "Move to the cursor")
    check("wizard: no units without an attack", shown() == "/petfollow [nomod:shift/ctrl]\n"
        .. "/petattack [mod:shift,@focus,harm,nodead]\n/petmoveto [mod:ctrl,@cursor]"
        and MacroSenseWizard.height == tall - 68, shown())
    -- Classic Era and TBC have /petmoveto, but their game does nothing with it: not offered there.
    LE_EXPANSION_LEVEL_CURRENT = 1
    Fire(C("pet"), "OnClick")
    check("wizard: no Move To before Cataclysm", menuItem("Follow") ~= nil and menuItem("Move to the cursor") == nil)
    Fire(C("pet"), "OnClick")
    LE_EXPANSION_LEVEL_CURRENT = 4
    Fire(C("pet"), "OnClick")
    check("wizard: Move To from Cataclysm on", menuItem("Move to the cursor") ~= nil)
    Fire(C("pet"), "OnClick")
    LE_EXPANSION_LEVEL_CURRENT = nil
    Fire(C("shift"), "OnClick")
    Fire(C("ctrl"), "OnClick")
    pick(C("command"), "/cast")
    check("wizard: back to /cast", shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Frostbolt"
        and not C("shiftPet"):IsShown(), shown())

    -- When: in combat only, otherwise Fire Blast; /target has no otherwise; the forms of this character.
    pick(C("whenCombat"), "In combat")
    TypeIn(C("otherwise"), "Fire Blast")
    Fire(C("otherwise"), "OnEnterPressed")
    check("wizard: when, otherwise", shown() == "#showtooltip\n/cast [combat,@mouseover,harm,nodead][combat] Frostbolt; "
        .. "Fire Blast" and C("otherwise"):IsShown() and not C("whenForm"):IsShown(), shown())
    pick(C("command"), "/target")
    check("wizard: no otherwise for /target", not C("otherwise"):IsShown() and C("whenCombat"):IsShown(), shown())
    pick(C("command"), "/cast")
    pick(C("on2"), "As usual") -- /target has no As usual
    GetNumShapeshiftForms, GetShapeshiftFormInfo = function() return 1 end, function() return 1, "Bear Form" end
    C("whenForm"):Refresh()
    pick(C("whenForm"), "Bear Form")
    check("wizard: in a form of yours", C("whenForm"):IsShown() and shown():find("[combat,form:1,@mouseover", 1, true)
        ~= nil, shown())
    pick(C("whenForm"), "In any form or none")
    pick(C("whenCombat"), "In or out of combat")
    TypeIn(C("otherwise"), "")
    Fire(C("otherwise"), "OnEnterPressed")
    GetNumShapeshiftForms, GetShapeshiftFormInfo = nil, nil
    check("wizard: when taken back", shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Frostbolt", shown())

    -- A mount: your mounts offered first, one for each place; a key's own; no units; off it on a press.
    local journal = C_MountJournal
    C_MountJournal = { GetMountIDs = function() return { 1, 2, 3 } end, GetMountInfoByID = function(id)
        return ({ "Swift Red Gryphon", "Swift Brown Steed", "Hidden One" })[id], nil, nil, nil, nil, nil, nil, nil, nil,
            id == 3, true
    end }
    pick(C("command"), "Mount")
    check("wizard: a mount, no units", not C("on1").parentFrame:IsShown() and C("mountGround"):IsShown() and C("mountFly"):IsShown()
        and C("offMount"):IsShown() and not C("dismount"):IsShown() and C("shiftCast").placeholder.text == "a mount"
        and shown():find("Pick a spell", 1, true) ~= nil, shown())
    TypeIn(C("mountGround"), "swift")
    check("wizard: your mounts first", offered(C("mountGround")) == "Swift Brown Steed, Swift Red Gryphon",
        offered(C("mountGround")))
    Fire(C("mountGround"), "OnEnterPressed")
    TypeIn(C("mountFly"), "Swift Red Gryphon")
    Fire(C("mountFly"), "OnEnterPressed")
    Fire(C("shift"), "OnClick")
    TypeIn(C("shiftCast"), "Swift Brown Steed")
    Fire(C("shiftCast"), "OnEnterPressed")
    check("wizard: a mount for each place, Shift for the ground one", shown() == "#showtooltip [mod:shift] Swift "
        .. "Brown Steed; [flyable] Swift Red Gryphon; Swift Brown Steed\n/cast [nomounted,"
        .. "mod:shift] Swift Brown Steed; [nomounted,flyable] Swift Red Gryphon; [nomounted] Swift Brown Steed\n"
        .. "/dismount [mounted,noflying]" and not C("shiftOn"):IsShown(), C("name").text,
        shown())
    -- Without a mount collection (Classic): a class's mount spell and the mount items in the bags; no other spells.
    C_MountJournal = nil
    gameSpells[5784] = { 136103, "Summon Felsteed" }
    book[#book + 1] = { "Summon Felsteed", "" }
    bag[#bag + 1] = "|cff0070dd|Hitem:2411::|h[Black Stallion Bridle]|h|r"
    ns.InvalidateSources()
    TypeIn(C("mountFly"), "")
    Fire(C("mountFly"), "OnEditFocusGained")
    check("wizard: only mounts, without a collection", offered(C("mountFly")) == "Black Stallion Bridle, Summon Felsteed",
        offered(C("mountFly")))
    Fire(C("mountFly"), "OnEscapePressed")
    Fire(C("mountFly"), "OnEscapePressed")
    gameSpells[5784], book[#book], bag[#bag] = nil, nil, nil
    ns.InvalidateSources()
    TypeIn(C("mountFly"), "fire")
    check("wizard: no mounts at all: no spells either", not C("mountFly").list:IsShown(), offered(C("mountFly")))
    TypeIn(C("mountFly"), "Swift Red Gryphon")
    Fire(C("mountFly"), "OnEnterPressed")
    pick(C("offMount"), "Do nothing")
    check("wizard: nothing on a mount", shown() == "#showtooltip\n/cast [mod:shift] Swift Brown Steed; [flyable] "
        .. "Swift Red Gryphon; Swift Brown Steed", shown())
    Fire(C("shift"), "OnClick")
    C_MountJournal = journal
    pick(C("command"), "/cast")
    -- Gear: only gear in the list; a slot and a key per piece; a set when there are some.
    pick(C("command"), "Put on gear")
    check("wizard: gear, no units or keys", not C("on1").parentFrame:IsShown() and not C("shift").parentFrame:IsShown()
        and C("equip1"):IsShown() and not C("equipSet").parentFrame:IsShown() and not C("otherwise"):IsShown(), shown())
    TypeIn(C("equip1"), "")
    Fire(C("equip1"), "OnEditFocusGained")
    check("wizard: only gear offered", offered(C("equip1")) == "Fire Ring, Lucky Charm", offered(C("equip1")))
    TypeIn(C("equip1"), "Fire Ring")
    Fire(C("equip1"), "OnEnterPressed")
    pick(C("equipSlot1"), "Ring 2")
    pick(C("equipKey1"), "With Shift held")
    check("wizard: a ring in its slot with Shift", shown() == "#showtooltip Fire Ring\n/equipslot [mod:shift] 12 Fire Ring",
        shown())
    C_EquipmentSet = { GetEquipmentSetIDs = function() return { 1 } end, GetEquipmentSetInfo = function() return "PvP" end }
    pick(C("command"), "Put on gear")
    pick(C("equipSet"), "PvP")
    check("wizard: an equipment set", C("equipSet").parentFrame:IsShown() and shown() == "#showtooltip Fire Ring\n"
        .. "/equipset PvP\n/equipslot [mod:shift] 12 Fire Ring", shown())
    pick(C("equipSet"), "No set")
    C_EquipmentSet = nil
    TypeIn(C("equip1"), "")
    Fire(C("equip1"), "OnEnterPressed")
    pick(C("command"), "/cast")
    pick(C("on2"), "As usual")
    check("wizard: and back to /cast", shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Frostbolt"
        and C("on1").parentFrame:IsShown() and C("dismount"):IsShown() and C("shiftCast").placeholder.text == "same spell", shown())

    -- Also: out of a form, off the mount, a buff cancelled first; something said in chat last.
    Fire(C("cancelform"), "OnClick")
    Fire(C("dismount"), "OnClick")
    TypeIn(C("cancelaura"), "Ice Block")
    Fire(C("cancelaura"), "OnEnterPressed")
    TypeIn(C("say"), "Casting on %t")
    pick(C("channel"), "Raid")
    check("wizard: what goes first, what is said last", shown() == "#showtooltip\n/cancelform\n/dismount [mounted]\n"
        .. "/cancelaura Ice Block\n/cast [@mouseover,harm,nodead][] Frostbolt\n/raid Casting on %t", shown())
    Fire(C("cancelform"), "OnClick")
    Fire(C("dismount"), "OnClick")
    TypeIn(C("cancelaura"), "")
    Fire(C("cancelaura"), "OnEnterPressed")
    TypeIn(C("say"), "")
    check("wizard: and all of it taken back", shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Frostbolt",
        shown())

    -- Not in combat, not into a full tab: the form stays.
    TypeIn(C("cast"), "frost")
    Fire(C("cast"), "OnEnterPressed")
    InCombatLockdown = function() return true end
    count = GetNumMacros() + select(2, GetNumMacros())
    Fire(C("create"), "OnClick")
    check("wizard: not in combat", MacroSenseWizard:IsShown() and GetNumMacros() + select(2, GetNumMacros()) == count
        and printed[#printed]:find("in combat", 1, true) ~= nil)
    InCombatLockdown = function() return false end
    local fillers = SLOTS.MAX_CHARACTER_MACROS - select(2, GetNumMacros())
    for i = 1, fillers do CreateMacro("Filler " .. i, 1, "/sit", true) end
    Send("UPDATE_MACROS")
    Fire(C("create"), "OnClick")
    check("wizard: not into a full tab", MacroSenseWizard:IsShown()
        and printed[#printed]:find("no free character macro slots", 1, true) ~= nil, printed[#printed])
    for i = 1, fillers do DeleteMacro(GetMacroIndexByName("Filler " .. i)) end

    Fire(wizardBtn, "OnClick")
    check("wizard: the button closes it", not MacroSenseWizard:IsShown())
    Fire(wizardBtn, "OnClick")
    ns.Window.Toggle()
    check("wizard: closes with the editor", not MacroSenseWizard:IsShown())
    ns.Window.Toggle()

    for _, name in ipairs({ "Burst", "Burst 2", "Polymorph" }) do DeleteMacro(GetMacroIndexByName(name)) end
    Send("UPDATE_MACROS")
    ns.Window.SetScope("general")
    ns.Window.Select(1)
    NextFrame()
end

-- Step by step: the form's questions one at a time, in plain words. A click answers and goes on, a spell picked
-- too; Back goes back with the answers kept; the last question names the macro. The form and the questions share
-- the answers, and the window opens as it was left.
do
    local C = ns.WizardWindow.Control
    local wizardBtn
    local function pick(dropdown, label)
        Fire(dropdown, "OnClick")
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() and r.text.text == label then return Fire(r, "OnClick") end
        end
    end
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "New (Wizard)" then wizardBtn = o end
    end
    local function answers()
        local out = {}
        for i = 1, 18 do
            if C("answer" .. i).shown then out[#out + 1] = C("answer" .. i).label.text end
        end
        return table.concat(out, ", ")
    end
    local function answer(name)
        for i = 1, 18 do
            local b = C("answer" .. i)
            if b.shown and b.label.text == name then return b end
        end
    end
    local function chosen()
        for i = 1, 18 do
            local b = C("answer" .. i)
            if b.shown and b.chosen then return b.label.text end
        end
    end
    local function TypeIn(box, text)
        box:SetFocus()
        Fire(box, "OnEditFocusGained")
        box.text = text
        Fire(box, "OnTextChanged", true)
    end
    local function shown() return ns.Highlight.Strip(C("preview").text) end
    local function question() return C("question").text end
    local function body(name) return select(3, GetMacroInfo(GetMacroIndexByName(name))) end

    if not MacroSenseFrame:IsShown() then ns.Window.Toggle() end
    ns.Window.SetScope("general")
    ns.Window.Select(1)
    NextFrame()
    local count = GetNumMacros()
    Fire(wizardBtn, "OnClick")
    check("steps: the window opens as it was left",
        MacroSenseWizard:IsShown() and C("mode").label.text == "Step by step")
    Fire(C("mode"), "OnClick")
    check("steps: the questions from the first", ns.db.wizardForm == nil and MacroSenseWizard.height == 538
        and question() == "What should the macro do?" and not C("back"):IsEnabled() and C("back").shown
        and C("next").shown and not C("create").shown and not C("cancel").shown, question())
    check("steps: what the macro does", answers() == "Cast a spell, Use an item, Several spells in turn, One of "
        .. "several at random, Target someone, Set your focus, Take someone's target, Command your pet, Ride a mount, Put on gear"
        and chosen() == "Cast a spell" and C("answer1").hint.text == "/cast", answers())
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(answer("Several spells in turn"), "OnEnter")
    GameTooltip.AddLine = nil
    check("steps: an answer's tooltip says what it is", tip[1] == "Several spells in turn"
        and tip[2]:find("^Each press casts the next spell") ~= nil, tip[2])

    -- Gear: the first piece is a must, then where it goes and when; another one may stay empty.
    Fire(answer("Put on gear"), "OnClick")
    check("steps: gear first", question() == "Which item should the macro put on?" and not C("next"):IsEnabled()
        and C("stepSpell").placeholder.text == "type an item", question())
    TypeIn(C("stepSpell"), "Lucky Charm")
    Fire(C("next"), "OnClick")
    check("steps: where it goes", question() == "Where should Lucky Charm go?" and chosen() == "Default slot", question())
    Fire(answer("Trinket 2"), "OnClick")
    Fire(answer("Without a key"), "OnClick")
    check("steps: another piece may stay empty", question() == "And another one?" and C("next"):IsEnabled()
        and C("stepSpell").placeholder.text == "none" and shown() == "#showtooltip Lucky Charm\n"
        .. "/equipslot [nomod] 14 Lucky Charm", shown())
    Fire(C("next"), "OnClick")
    check("steps: then When", question() == "Should the macro work only at certain times?", question())
    for _ = 1, 5 do Fire(C("back"), "OnClick") end
    check("steps: back to the first again", question() == "What should the macro do?", question())

    -- A mount: the one for anywhere is a must, the others may stay empty; then what a press on a mount does.
    Fire(answer("Ride a mount"), "OnClick")
    check("steps: a mount first", question() == "Which mount should the macro summon?" and not C("next"):IsEnabled()
        and C("stepSpell").placeholder.text == "type a mount", question())
    TypeIn(C("stepSpell"), "Swift Brown Steed")
    Fire(C("next"), "OnClick")
    check("steps: a mount typed goes on", question() == "Which mount where you can fly?" and C("next"):IsEnabled()
        and C("stepSpell").text == "" and C("stepSpell").placeholder.text == "none", question())
    Fire(C("next"), "OnClick")
    Fire(C("next"), "OnClick")
    check("steps: on a mount", question() == "What should a press do while you're mounted?" and chosen()
        == "Dismount, but not while flying" and shown() == "#showtooltip Swift Brown Steed\n/cast [nomounted] Swift Brown Steed\n"
        .. "/dismount [mounted,noflying]", shown())
    Fire(C("next"), "OnClick")
    Fire(C("next"), "OnClick")
    check("steps: no dismount check for a mount", question() == "Would you like to add anything else?"
        and not C("stepDismount"):IsShown(), question())
    for _ = 1, 6 do Fire(C("back"), "OnClick") end
    check("steps: back to the first", question() == "What should the macro do?", question())

    Fire(answer("Cast a spell"), "OnClick")
    check("steps: a click answers and goes on", question() == "Which spell should the macro cast?"
        and C("stepSpell"):HasFocus() and not C("next"):IsEnabled() and C("back"):IsEnabled(), question())
    Fire(C("back"), "OnClick")
    check("steps: Back with nothing typed", question() == "What should the macro do?" and not C("stepSpell"):HasFocus(),
        question())
    Fire(answer("Cast a spell"), "OnClick")
    TypeIn(C("stepSpell"), "fire")
    check("steps: a name typed lets Next go on", C("next"):IsEnabled())
    Fire(C("stepSpell"), "OnArrowPressed", "DOWN")
    Fire(C("stepSpell"), "OnEnterPressed")
    check("steps: a spell with ranks: which one", question() == "Which rank of Fireball?"
        and answers() == "The highest you know, Rank 3, Rank 2, Rank 1" and chosen() == "The highest you know"
        and C("answer2").hint.text == "Fireball(Rank 3)", answers())
    Fire(answer("The highest you know"), "OnClick")
    check("steps: a spell picked goes on", question() == "Where should Fireball go?"
        and chosen() == "On whoever is under the mouse" and answer("On whoever is under the mouse").hint.text
        == "@mouseover" and answer("Do nothing") == nil, question())
    check("steps: a spell for enemies goes to no friend", answer("On arena enemy 1") ~= nil
        and answer("On party member 1") == nil and answer("On yourself") == nil and answer("On your pet") == nil,
        answers())
    check("steps: the macro as it is", shown() == "#showtooltip\n/cast [@mouseover,harm,nodead][] Fireball", shown())
    Fire(C("back"), "OnClick")
    Fire(C("back"), "OnClick")
    check("steps: back to the spell picked", question() == "Which spell should the macro cast?"
        and C("stepSpell").text == "Fireball" and not C("stepSpell"):HasFocus() and C("next"):IsEnabled(), question())
    Fire(C("next"), "OnClick")
    Fire(C("next"), "OnClick")
    Fire(answer("On whoever is under the mouse"), "OnClick")
    check("steps: and if nobody is under the mouse: no friends or enemies, the game says",
        question() == "And if nobody is under the mouse?"
        and C("hint").text == "Or the one there is not an enemy, or is dead." and chosen() == "On your target, as usual"
        and answer("On whoever is under the mouse") == nil and answers():find("Do nothing$") ~= nil, answers())
    Fire(answer("On your target, as usual"), "OnClick")
    check("steps: keys", question() == "Should the macro do something else while you hold Shift, Ctrl, Alt or Cmd?"
        and C("stepCmd") ~= nil and C("next"):IsEnabled(), question())
    Fire(C("stepShift"), "OnClick")
    Fire(C("next"), "OnClick")
    check("steps: what Shift casts", C("context").text == "With Shift held"
        and question() == "What should the macro cast instead?" and C("stepSpell").text == ""
        and C("stepSpell").placeholder.text == "same spell" and not C("stepSpell"):HasFocus()
        and C("next"):IsEnabled(), question())
    TypeIn(C("stepSpell"), "poly")
    Fire(C("stepSpell"), "OnEnterPressed")
    check("steps: where it goes with Shift", question() == "Where should Polymorph go?"
        and C("context").text == "With Shift held" and chosen() == "On your target, as usual", question())
    Fire(answer("On your focus"), "OnClick")
    check("steps: and if there is no focus", question() == "And if you have no focus?", question())
    Fire(answer("Do nothing"), "OnClick")
    -- When it works: in combat only, and what it casts the rest of the time.
    check("steps: when", question() == "Should the macro work only at certain times?" and C("next"):IsEnabled()
        and C("stepWhenCombat").label.text == "In or out of combat" and not C("stepWhenForm"):IsShown(), question())
    pick(C("stepWhenCombat"), "In combat")
    Fire(C("next"), "OnClick")
    check("steps: otherwise", question() == "And what should it cast the rest of the time?" and C("next"):IsEnabled()
        and C("stepSpell").placeholder.text == "nothing", question())
    TypeIn(C("stepSpell"), "Frostbolt")
    Fire(C("next"), "OnClick")
    check("steps: in combat, otherwise Frostbolt", shown() == "#showtooltip\n/cast [mod:shift,combat,@focus,harm,"
        .. "nodead] Polymorph; [combat,@mouseover,harm,nodead][combat] Fireball; Frostbolt", shown())
    Fire(C("back"), "OnClick")
    TypeIn(C("stepSpell"), "")
    Fire(C("back"), "OnClick")
    pick(C("stepWhenCombat"), "In or out of combat")
    Fire(C("next"), "OnClick")
    check("steps: anything else", question() == "Would you like to add anything else?" and C("context").text == ""
        and C("stepTrinket1").label.text == "Trinket 1: Lucky Charm", question())
    Fire(C("stepStopcasting"), "OnClick")
    local burst = "#showtooltip\n/stopcasting\n/cast [mod:shift,@focus,harm,nodead] Polymorph; "
        .. "[@mouseover,harm,nodead][] Fireball"
    check("steps: the macro so far", shown() == burst, shown())
    Fire(C("next"), "OnClick")
    check("steps: the last one names the macro", question() == "Almost done: name your macro"
        and C("stepName").text == "Fireball" and C("create").shown and C("create"):IsEnabled() and not C("next").shown
        and C("stepGeneral").chosen and not C("stepCharacter").chosen, question())

    -- Back, with the answers kept; the form with them, and the questions again from the first.
    Fire(C("back"), "OnClick")
    Fire(C("back"), "OnClick")
    Fire(C("back"), "OnClick")
    check("steps: Back keeps the answers", question() == "And if you have no focus?" and chosen() == "Do nothing"
        and C("context").text == "With Shift held", question())
    C("stepName"):SetText("Burst")
    Fire(C("mode"), "OnClick")
    check("steps: the form has the answers", ns.db.wizardForm == true and C("cast").text == "Fireball"
        and C("shift").fill.shown and C("shiftCast").text == "Polymorph" and C("shiftOn").label.text == "Focus"
        and C("stopcasting").fill.shown and C("only").label.text == "Enemies" and MacroSenseWizard.height ~= 510
        and C("cancel").shown and C("create").shown and not C("back").shown and not C("next").shown, C("cast").text)
    check("steps: and the name typed", C("name").text == "Burst", C("name").text)
    Fire(C("mode"), "OnClick")
    check("steps: the questions from the first again", question() == "What should the macro do?"
        and chosen() == "Cast a spell" and shown() == burst, question())
    for _ = 1, 11 do Fire(C("next"), "OnClick") end
    check("steps: Next through the answers given", question() == "Almost done: name your macro"
        and C("stepName").text == "Burst", question())
    Fire(C("stepCharacter"), "OnClick")
    check("steps: the tab in plain words", C("stepCharacter").chosen and not C("stepGeneral").chosen
        and C("stepCharacter").label.text == "Only for this character")
    Fire(C("stepName"), "OnEnterPressed")
    local index = GetMacroIndexByName("Burst")
    check("steps: Enter in the name creates the macro", index > SLOTS.MAX_ACCOUNT_MACROS and body("Burst") == burst
        and not MacroSenseWizard:IsShown(), index)

    -- /target by name; a list and what starts it over; the pet.
    Fire(wizardBtn, "OnClick")
    check("steps: opened again, from the first question", question() == "What should the macro do?"
        and chosen() == "Cast a spell" and shown():find("Pick a spell", 1, true) ~= nil, question())
    Fire(answer("Cast a spell"), "OnClick")
    TypeIn(C("stepSpell"), "Healthstone")
    Fire(C("next"), "OnClick")
    check("steps: Next takes the name typed; an item is used", question() == "Where should Healthstone go?"
        and shown() == "#showtooltip\n/use [@mouseover,help,nodead][] Healthstone" and MacroSenseWizard.height == 538,
        shown())
    Fire(C("back"), "OnClick")
    TypeIn(C("stepSpell"), "")
    Fire(C("back"), "OnClick")
    check("steps: Back takes the box emptied", question() == "What should the macro do?"
        and shown():find("Pick a spell", 1, true) ~= nil, shown())
    Fire(answer("Target someone"), "OnClick")
    check("steps: whom to target", question() == "Who should become your target?"
        and answer("Whoever is under the mouse") ~= nil and answer("Party member 2") ~= nil, answers())
    Fire(answer("Someone by name"), "OnClick")
    check("steps: by name", question() == "What name should it look for?" and not C("next"):IsEnabled(), question())
    TypeIn(C("stepByName"), "Hogger")
    check("steps: a name lets Next go on", C("next"):IsEnabled() and shown() == "/target Hogger", shown())
    Fire(C("stepByName"), "OnEnterPressed")
    check("steps: Enter goes on", question():find("^Should the macro do something else") ~= nil, question())
    Fire(C("back"), "OnClick")
    Fire(C("back"), "OnClick")
    Fire(C("back"), "OnClick")
    Fire(answer("Several spells in turn"), "OnClick")
    check("steps: a list", question() == "Pick the spells in the order the macro should cast them"
        and not C("next"):IsEnabled(), question())
    TypeIn(C("stepList1"), "fire")
    check("steps: a name being typed in the list lets Next go on", C("next"):IsEnabled())
    Fire(C("stepList1"), "OnArrowPressed", "DOWN")
    Fire(C("stepList1"), "OnEnterPressed")
    TypeIn(C("stepList2"), "frost")
    Fire(C("stepList2"), "OnEnterPressed")
    check("steps: a list is no single pick: it stays",
        question() == "Pick the spells in the order the macro should cast them" and C("next"):IsEnabled(), question())
    Fire(C("next"), "OnClick")
    check("steps: what starts it over", question() == "When should the sequence start again from the first spell?"
        and C("stepResetShift").label.text == "When you press it with Shift held", question())
    Fire(C("stepResetTarget"), "OnClick")
    Fire(C("next"), "OnClick")
    check("steps: where these spells go: as usual, after a name", question() == "Where should these spells go?"
        and chosen() == "On your target, as usual"
        and shown() == "#showtooltip\n/castsequence reset=target Fireball, Frostbolt", shown())
    Fire(C("back"), "OnClick")
    Fire(C("back"), "OnClick")
    Fire(C("back"), "OnClick")
    Fire(answer("Command your pet"), "OnClick")
    check("steps: the pet", question() == "What should your pet do?" and chosen() == "Attack", question())
    Fire(answer("Follow"), "OnClick")
    check("steps: no units to follow", question():find("^Should the macro do something else") ~= nil
        and shown() == "/petfollow", shown())
    Fire(C("mode"), "OnClick")
    TypeIn(C("cancelaura"), "Ice Block")
    Fire(C("mode"), "OnClick")
    check("steps: what was being typed in the form is taken", question() == "What should the macro do?"
        and shown() == "/cancelaura Ice Block\n/petfollow", shown())

    -- What the game says a spell is for: nothing when it says both; a key's own spell for itself; anyone there
    -- again when the spell picked next is one it says nothing about.
    check("steps: what a spell is for", ns.sources.reaction("Fireball") == "enemies"
        and ns.sources.reaction("Flash Heal") == "friends" and ns.sources.reaction("Holy Shock") == nil
        and ns.sources.reaction("Polymorph") == nil and ns.sources.reaction("Healthstone", true) == "friends")
    ns.WizardWindow.Close()
    Fire(wizardBtn, "OnClick")
    Fire(answer("Use an item"), "OnClick")
    TypeIn(C("stepSpell"), "Healthstone")
    Fire(C("next"), "OnClick")
    Fire(answer("On whoever is under the mouse"), "OnClick")
    Fire(answer("On your target, as usual"), "OnClick")
    Fire(C("stepShift"), "OnClick")
    Fire(C("next"), "OnClick")
    TypeIn(C("stepSpell"), "Fireball")
    Fire(C("next"), "OnClick")
    Fire(C("next"), "OnClick")
    check("steps: a key's own spell, for enemies", question() == "Where should Fireball go?"
        and answer("On party member 1") == nil and answer("On arena enemy 1") ~= nil, answers())
    Fire(answer("On your focus"), "OnClick")
    check("steps: and if not there, for that spell", C("hint").text == "Or the one there is not an enemy, or is dead.",
        C("hint").text)
    Fire(answer("Do nothing"), "OnClick")
    check("steps: each spell checked for what it is for", shown() == "#showtooltip\n"
        .. "/use [mod:shift,@focus,harm,nodead] Fireball; [@mouseover,help,nodead][] Healthstone", shown())
    Fire(C("mode"), "OnClick")
    TypeIn(C("cast"), "poly")
    Fire(C("cast"), "OnEnterPressed")
    check("steps: anyone there again for a spell the game says nothing about", C("only").label.text == "Anyone there"
        and shown():find("[@mouseover,exists,nodead][] Polymorph", 1, true) ~= nil, shown())
    TypeIn(C("shiftCast"), "Healthstone")
    Fire(C("shiftCast"), "OnEnterPressed")
    check("steps: in the form too, a key's own spell for what it is for",
        shown():find("[mod:shift,@focus,help,nodead] Healthstone", 1, true) ~= nil, shown())
    Fire(C("mode"), "OnClick")

    -- A spell that goes to nobody but you (Demon Armor: no range): no units, nor a key's that casts it.
    book[#book + 1] = { "Demon Armor", "" }
    ns.InvalidateSources("spells")
    check("steps: the game says it goes to nobody but you", ns.sources.selfOnly("Demon Armor") == true
        and ns.sources.selfOnly("Fireball") == false)
    check("steps: an item, on a client that doesn't say", ns.sources.selfOnly("Healthstone", true) == nil)
    ns.WizardWindow.Close()
    Fire(wizardBtn, "OnClick")
    Fire(answer("Cast a spell"), "OnClick")
    TypeIn(C("stepSpell"), "Demon Armor")
    Fire(C("next"), "OnClick")
    check("steps: for yourself only: no units", question():find("^Should the macro do something else") ~= nil
        and shown() == "#showtooltip\n/cast Demon Armor", shown())
    Fire(C("stepShift"), "OnClick")
    Fire(C("next"), "OnClick")
    Fire(C("next"), "OnClick")
    check("steps: a key casting it: no units either", question() == "Should the macro work only at certain times?",
        question())
    Fire(C("back"), "OnClick")
    Fire(C("back"), "OnClick")
    Fire(C("back"), "OnClick")
    TypeIn(C("stepSpell"), "Fireball")
    Fire(C("next"), "OnClick")
    Fire(answer("The highest you know"), "OnClick")
    Fire(answer("On whoever is under the mouse"), "OnClick")
    Fire(answer("On your target, as usual"), "OnClick")
    Fire(C("next"), "OnClick")
    TypeIn(C("stepSpell"), "Demon Armor")
    Fire(C("next"), "OnClick")
    check("steps: a key's own spell for yourself only", question() == "Should the macro work only at certain times?"
        and shown() == "#showtooltip\n/cast [mod:shift] Demon Armor; [@mouseover,harm,nodead][] Fireball", shown())
    Fire(C("mode"), "OnClick")
    TypeIn(C("cast"), "Demon Armor")
    Fire(C("cast"), "OnEnterPressed")
    check("steps: the form too: as usual, nobody after", C("on1").label.text == "As usual"
        and C("on2").label.text == "-" and shown() == "#showtooltip\n/cast [mod:shift][] Demon Armor", shown())
    TypeIn(C("shiftCast"), "fireball")
    Fire(C("shiftCast"), "OnEnterPressed")
    Fire(C("shiftCast"), "OnEnterPressed")
    Fire(C("shiftOn"), "OnClick")
    for _, r in ipairs(MacroSenseMenu.rows) do
        if r:IsShown() and r.text.text == "Focus" then Fire(r, "OnClick") end
    end
    local focused = C("shiftOn").label.text
    TypeIn(C("shiftCast"), "Demon Armor")
    Fire(C("shiftCast"), "OnEnterPressed")
    check("steps: a key's spell for yourself only: its units as usual", focused == "Focus"
        and C("shiftOn").label.text == "As usual", C("shiftOn").label.text)
    Fire(C("mode"), "OnClick")
    book[#book] = nil
    ns.InvalidateSources("spells")

    -- In Ukrainian.
    ns.WizardWindow.Close()
    ns.SetLanguage("uk")
    Fire(wizardBtn, "OnClick")
    check("steps: in Ukrainian", question() == "Що має робити макрос?"
        and C("answer1").label.text == "Застосувати заклинання", question())
    Fire(C("answer1"), "OnClick")
    check("steps: the next question in Ukrainian", question() == "Яке заклинання має застосовувати макрос?", question())
    ns.WizardWindow.Close()
    ns.SetLanguage("en")

    check("steps: one macro made", GetNumMacros() == count, GetNumMacros())
    DeleteMacro(GetMacroIndexByName("Burst"))
    Send("UPDATE_MACROS")
    ns.Window.SetScope("general")
    ns.Window.Select(1)
    NextFrame()
end

-- Shift + right-click on a macro on an action bar opens it in the editor instead of running it.
do
    -- Down and up, as the game sends a click; how many of them reached the button's own OnClick.
    local function Click(b, mouse, shift)
        IsShiftKeyDown = function() return shift end
        local ran = b.ran
        Fire(b, "OnClick", mouse, true)
        Fire(b, "OnClick", mouse, false)
        IsShiftKeyDown = function() return false end
        return b.ran - ran
    end
    local function Later(b)
        ActionBarButtonEventsFrame:RegisterFrame(b)
        NextFrame()
        return b
    end
    local errors = #reported -- the game shows them; the click itself goes on
    CreateMacro("Bar Fear", 1, "/cast Fear", false)
    CreateMacro("Bar Heal", 1, "/cast Heal", true)
    Send("UPDATE_MACROS")
    MacroSenseFrame:Hide()
    actions[2] = { "macro", 5782, "spell", text = "Bar Fear" }
    check("action bars: shift + right-click doesn't run the macro", Click(startButton, "RightButton", true) == 0)
    check("action bars: it opens the editor on it", MacroSenseFrame:IsShown() and raw() == "/cast Fear", raw())
    check("action bars: a right-click runs it", Click(startButton, "RightButton", false) == 2)
    check("action bars: shift + left-click runs it", Click(startButton, "LeftButton", true) == 2)
    -- A drag starts with the button down and never lets go on the button.
    ns.Window.Open(GetMacroIndexByName("Bar Heal"))
    IsShiftKeyDown = function() return true end
    Fire(startButton, "OnClick", "RightButton", true)
    IsShiftKeyDown = function() return false end
    check("action bars: dragging the macro doesn't open it", raw() == "/cast Heal", raw())
    -- Changed in the game's macro window while the editor was closed: it opens as it is now.
    EditMacro(GetMacroIndexByName("Bar Fear"), "Bar Fear", 1, "/cast Fear\n/say boo")
    Click(startButton, "RightButton", true)
    MacroSenseFrame:Hide()
    EditMacro(GetMacroIndexByName("Bar Fear"), "Bar Fear", 1, "/cast Fear")
    Click(startButton, "RightButton", true)
    check("action bars: the macro as it is now", raw() == "/cast Fear", raw())
    actions[7] = { "equipmentset", "Bar Fear", text = "Bar Fear" } -- its button shows the set's name
    check("action bars: only a macro's slot has a macro",
        ns.ActionBars.MacroAt(2) ~= nil and ns.ActionBars.MacroAt(7) == nil)
    local listens
    for _, o in ipairs(created) do listens = listens or (o.events and o.events.PLAYER_REGEN_ENABLED) end
    check("action bars: the end of combat is listened for", listens)

    -- The slot: the button's ID on its bar's page.
    local bottomBar = New("Frame")
    bottomBar.attributes = { actionpage = 6 }
    local bottom = Later(ActionButton(3, { type = "action", ["useparent-actionpage"] = true }, bottomBar))
    actions[63] = { "macro", 2061, "spell", text = "Bar Heal" }
    check("action bars: a button made later, on another page", Click(bottom, "RightButton", true) == 0
        and raw() == "/cast Heal", raw())
    check("action bars: a character macro opens in its tab", ns.db.scope == "character", ns.db.scope)
    barPage = 2
    actions[2], actions[14] = { "spell", 5782 }, { "macro", 5782, "spell", text = "Bar Fear" } -- 14: page 2's 2
    check("action bars: the main bar's page", Click(startButton, "RightButton", true) == 0 and raw() == "/cast Fear",
        raw())
    barPage = 1
    actions[2] = { "macro", 5782, "spell", text = "Bar Fear" }

    local other = Later(ActionButton(4, { type = "action", ["useparent-actionpage"] = true }, mainBar))
    actions[4] = { "spell", 5782 }
    check("action bars: a spell runs on shift + right-click", Click(other, "RightButton", true) == 2)
    actions[4] = { "macro", GetMacroIndexByName("Bar Heal"), "", text = "Bar Heal" }
    check("action bars: a macro that shows no spell", Click(other, "RightButton", true) == 0 and raw() == "/cast Heal",
        raw())
    actions[4] = { "macro", 5782, "spell", text = "Gone" }
    check("action bars: a macro not found runs nothing and opens nothing",
        Click(other, "RightButton", true) == 0 and raw() == "/cast Heal", raw())

    -- Bartender and ElvUI: the slot is the button's "action" attribute.
    actions[100] = { "macro", 5782, "spell", text = "Bar Fear" }
    check("action bars: LibActionButton's buttons", Click(labButton, "RightButton", true) == 0
        and raw() == "/cast Fear", raw())
    local petButton = ActionButton(0, { type = "action", action = 4 })
    lab.OnButtonCreated("OnButtonCreated", petButton)
    NextFrame()
    check("action bars: LibActionButton's buttons made later", Click(petButton, "RightButton", true) == 0)
    petButton.attributes.type = "pet" -- its action is a pet bar slot, not an action slot
    check("action bars: a pet button is left alone", Click(petButton, "RightButton", true) == 2)

    InCombatLockdown = function() return true end
    actions[5] = { "macro", 5782, "spell", text = "Bar Fear" }
    local late = Later(ActionButton(5, { type = "action", ["useparent-actionpage"] = true }, mainBar))
    check("action bars: buttons made in combat work as usual", Click(late, "RightButton", true) == 2)
    InCombatLockdown = function() return false end
    Send("PLAYER_REGEN_ENABLED")
    check("action bars: and are set up when it ends", Click(late, "RightButton", true) == 0)
    local refused = ActionButton(6, { type = "action", ["useparent-actionpage"] = true }, mainBar)
    refused.forbidden = true
    actions[6] = { "macro", 5782, "spell", text = "Bar Fear" }
    Later(refused)
    check("action bars: a button the game won't let us set up works as usual", Click(refused, "RightButton", true) == 2)
    -- Their slots are on bars of their own; slot 2 of the main bar has a macro.
    local extra = ActionButton(2, { type = "action", ["useparent-actionpage"] = true }, mainBar)
    extra.isExtra = true
    check("action bars: the extra action button is left alone", Click(Later(extra), "RightButton", true) == 2)
    local totem = ActionButton(2, { type = "action", ["useparent-actionpage"] = true }, mainBar)
    totem.buttonType = "MULTICASTACTIONBUTTON"
    check("action bars: so is the totem bar", Click(Later(totem), "RightButton", true) == 2)

    -- The tooltip of a macro says so.
    local tip, colors = {}, {}
    GameTooltip.AddLine = function(_, text, r, g, b)
        tip[#tip + 1] = text
        colors[text] = string.format("%.2f %.2f %.2f", r or 1, g or 1, b or 1)
    end
    local function Tip(owner, slot)
        tip = {}
        GameTooltip:SetOwner(owner)
        GameTooltip:SetAction(slot)
        return table.concat(tip, " / ")
    end
    -- After a blank line: apart from the game's own lines.
    check("action bars: a macro's tooltip tells", Tip(startButton, 2) == "  / " .. ns.ActionBars.TIP, Tip(startButton, 2))
    check("action bars: and on LibActionButton's", Tip(labButton, 100) == "  / " .. ns.ActionBars.TIP, Tip(labButton, 100))
    actions[4] = { "spell", 5782 }
    check("action bars: a spell's doesn't", Tip(other, 4) == "", Tip(other, 4))
    check("action bars: nor a button not set up", Tip(refused, 6) == "", Tip(refused, 6))
    -- On a Mac, Cmd with the macro's key may be a macOS shortcut: its tooltip warns, first, on any button.
    local fear = GetMacroIndexByName("Bar Fear")
    EditMacro(fear, "Bar Fear", 1, "/cast [mod:cmd] Fear")
    bindings.ACTIONBUTTON2 = "Q" -- the button of slot 2
    Send("UPDATE_BINDINGS")
    local warning = "Cmd+Q is a macOS shortcut (quits the game)"
    check("action bars: the macOS warning", Tip(startButton, 2) == "  / " .. warning .. " / " .. ns.ActionBars.TIP,
        Tip(startButton, 2))
    check("action bars: in red", colors[warning] == "1.00 0.35 0.35", colors[warning])
    local laidOut
    GameTooltip.Show = function() laidOut = #tip end
    check("action bars: the macOS warning where the click isn't ours", Tip(refused, 6) == "  / " .. warning
        and laidOut == 2, Tip(refused, 6))
    GameTooltip.Show = nil
    check("action bars: not on a spell", Tip(other, 4) == "", Tip(other, 4))
    IsMacClient = function() return false end
    check("action bars: no macOS warning on Windows", Tip(startButton, 2) == "  / " .. ns.ActionBars.TIP,
        Tip(startButton, 2))
    IsMacClient = function() return true end
    -- And the button whose own key that is turns red, on the game's bars.
    local function Tinted(b)
        for _, o in ipairs(created) do
            if o.kind == "Texture" and o.parentFrame == b and o.color == "ff0000" then return o:IsShown() end
        end
        return false
    end
    startButton.action, refused.action, labButton.action, petButton.action = 2, 6, 100, 2 -- the game keeps .action
    Send("UPDATE_BINDINGS")
    check("tint: the button of Cmd+Q", Tinted(startButton))
    check("tint: not where the macro has no such key", not Tinted(refused))
    check("tint: not on other addons' bars", not Tinted(labButton) and not Tinted(petButton))
    -- Set up again after each combat: still one look per change of the button.
    local looks, conflicts = 0, ns.Shortcuts.Conflicts
    ns.Shortcuts.Conflicts = function(...)
        looks = looks + 1
        return conflicts(...)
    end
    startButton:Update()
    ns.Shortcuts.Conflicts = conflicts
    check("tint: once per change", looks == 1, looks)
    bindings.ACTIONBUTTON2 = "E"
    Send("UPDATE_BINDINGS")
    check("tint: gone with another key", not Tinted(startButton))
    bindings.ACTIONBUTTON2 = "Q"
    Send("UPDATE_BINDINGS")
    EditMacro(fear, "Bar Fear", 1, "/cast Fear")
    Send("UPDATE_MACROS")
    check("tint: gone without Cmd in the macro", not Tinted(startButton))
    EditMacro(fear, "Bar Fear", 1, "/cast [mod:cmd] Fear")
    Send("UPDATE_MACROS")
    check("tint: back with it", Tinted(startButton))
    actions[2] = { "spell", 5782 }
    startButton:Update()
    check("tint: gone with a spell on the button", not Tinted(startButton))
    actions[2] = { "macro", 5782, "spell", text = "Bar Fear" }
    startButton:Update()
    check("tint: follows the button's action", Tinted(startButton))
    IsMacClient = function() return false end
    Send("UPDATE_BINDINGS")
    check("tint: not on Windows", not Tinted(startButton))
    IsMacClient = function() return true end
    startButton.action, refused.action, labButton.action, petButton.action = nil, nil, nil, nil
    EditMacro(fear, "Bar Fear", 1, "/cast Fear")
    bindings.ACTIONBUTTON2 = nil
    Send("UPDATE_BINDINGS")
    GameTooltip.AddLine = nil

    -- Unsaved changes: to another macro they are asked about, the macro's own stay.
    local asked, show = 0, StaticPopup_Show
    StaticPopup_Show = function(...)
        asked = asked + 1
        return show(...)
    end
    Click(startButton, "RightButton", true)
    edit:SetCursorPosition(#edit.text)
    Type("\n/say hi")
    Click(startButton, "RightButton", true)
    check("action bars: the same macro keeps its unsaved changes", asked == 0 and raw() == "/cast Fear\n/say hi", raw())
    Click(bottom, "RightButton", true)
    check("action bars: another macro asks first", asked == 1 and raw() == "/cast Heal", asked .. " " .. raw())
    StaticPopup_Show = show
    check("action bars: no Lua errors", #reported == errors, reported[errors + 1])

    for _, name in ipairs({ "Bar Fear", "Bar Heal" }) do DeleteMacro(GetMacroIndexByName(name)) end
    Send("UPDATE_MACROS")
    ns.Window.SetScope("general")
    ns.Window.Select(1)
    NextFrame()
end

-- Share: macros as a code to copy, and a code to import; nothing is replaced, a taken name gets a number.
do
    local function menuItem(label)
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() and ns.Highlight.Strip(r.text.text):sub(1, #label) == label then return r end
        end
    end
    local share
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Share" then share = o end
    end
    local function Pick(label)
        Fire(share, "OnClick")
        local item = menuItem(label)
        if item then Fire(item, "OnClick") end
        return item
    end
    local C = function(name) return ns.ShareWindow.Control(name) end
    CreateMacro("Share A", 134400, "/cast Fear", false)
    CreateMacro("Share B", 136183, "/cast Heal", true)
    Send("UPDATE_MACROS")
    ns.Window.Open(GetMacroIndexByName("Share A"))
    NextFrame()

    Pick("Export this macro")
    local code = C("box").text
    local macros = ns.Share.Decode(code)
    check("share: this macro's code, selected", MacroSenseShare:IsShown() and C("title").text == "Export a macro"
        and macros and #macros == 1 and macros[1].name == "Share A" and macros[1].body == "/cast Fear"
        and macros[1].icon == 134400 and macros[1].scope == "general", code)
    C("box"):SetText("typed over")
    Fire(C("box"), "OnTextChanged", true)
    check("share: the code can't be typed over", C("box").text == code)
    local general, character = GetNumMacros()
    Pick("Export the General tab")
    check("share: the tab", #ns.Share.Decode(C("box").text) == general)
    Pick("Export all macros")
    local all = C("box").text
    check("share: both tabs", #ns.Share.Decode(all) == general + character)
    ns.Window.New()
    NextFrame()
    Fire(share, "OnClick")
    check("share: no saved macro, nothing to export", menuItem("Export this macro").item.disabled)
    Fire(share, "OnClick")

    -- Import: what the code holds and where each macro goes.
    Pick("Import a code")
    check("share: an empty box to paste into", MacroSenseShare:IsShown() and C("title").text == "Import macros"
        and C("box").text == "" and C("info").text == "" and not C("import"):IsEnabled())
    C("box"):SetText("hello")
    check("share: not a code", C("info").text:find("neither a MacroSense code nor a macro") ~= nil
        and not C("import"):IsEnabled(),
        C("info").text)
    local two = ns.Share.Encode({
        { scope = "general", icon = 134400, name = "Share A", body = "/cast Fear\n/say boo" },
        { scope = "character", icon = 136183, name = "Share New", body = "/cast Heal" },
    })
    C("box"):SetText(two)
    local info = C("info").text
    check("share: what goes where", info:find("2 macros in the code", 1, true)
        and info:find("Share A: into General as \"Share A 2\" (the name is taken)", 1, true)
        and info:find("Share New: into Character", 1, true) and C("import"):IsEnabled(), info)
    local before = general + character
    Fire(C("import"), "OnClick")
    check("share: imported, nothing replaced", select(3, GetMacroInfo(GetMacroIndexByName("Share A"))) == "/cast Fear"
        and GetMacroIndexByName("Share A 2") > 0 and GetMacroIndexByName("Share New") > SLOTS.MAX_ACCOUNT_MACROS
        and GetNumMacros() + select(2, GetNumMacros()) == before + 2, GetMacroIndexByName("Share A 2"))
    check("share: the first one opens, the window closes", raw() == "/cast Fear\n/say boo"
        and not MacroSenseShare:IsShown(), raw())
    -- The text of a macro, to copy for a guide; and a guide's text, imported.
    Pick("Copy this macro's text")
    check("share: a macro's text to copy", MacroSenseShare:IsShown() and C("title").text == "The macro's text"
        and C("box").text == "/cast Fear\n/say boo" and C("box").highlighted ~= false, C("box").text)
    Pick("Import a code")
    C("box"):SetText("  #showtooltip\n  /cast [@mouseover,harm][] Fear\n\n/castsequence reset=10 Fire Blast(Rank 2), X\n")
    info = C("info").text
    check("share: a guide's text, two macros", info:find("2 macros in the text", 1, true)
        and info:find("Fear: into General", 1, true) and info:find("Fire Blast: into General", 1, true), info)
    Fire(C("import"), "OnClick")
    check("share: imported as written, lines trimmed", select(3, GetMacroInfo(GetMacroIndexByName("Fear")))
        == "#showtooltip\n/cast [@mouseover,harm][] Fear" and select(3, GetMacroInfo(GetMacroIndexByName("Fire Blast")))
        == "/castsequence reset=10 Fire Blast(Rank 2), X", raw())
    DeleteMacro(GetMacroIndexByName("Fear"))
    DeleteMacro(GetMacroIndexByName("Fire Blast"))
    Pick("Import a code")
    C("box"):SetText("/cast [@focus] Polymorph")
    Fire(C("import"), "OnClick")
    local icon = select(2, GetMacroInfo(GetMacroIndexByName("Polymorph")))
    check("share: no #showtooltip, the icon of its spell", icon ~= nil and icon == ns.Completion.IconFor("Polymorph")
        and icon ~= 134400, icon)
    DeleteMacro(GetMacroIndexByName("Polymorph"))
    Send("UPDATE_MACROS")

    -- One name twice in a code: each gets its own.
    Pick("Import a code")
    C("box"):SetText(ns.Share.Encode({ { scope = "general", icon = 1, name = "Share A", body = "/sit" },
        { scope = "general", icon = 1, name = "Share A", body = "/sit" } }))
    info = C("info").text
    check("share: a name twice, a number each", info:find("as \"Share A 3\"", 1, true)
        and info:find("as \"Share A 4\"", 1, true), info)
    -- One slot left for two: the second doesn't fit.
    local fillers = SLOTS.MAX_CHARACTER_MACROS - select(2, GetNumMacros()) - 1
    for i = 1, fillers do CreateMacro("Filler " .. i, 1, "/sit", true) end
    C("box"):SetText(ns.Share.Encode({ { scope = "character", icon = 1, name = "Last Slot", body = "/sit" },
        { scope = "character", icon = 1, name = "No Slot", body = "/sit" } }))
    info = C("info").text
    check("share: the free slots are counted", info:find("Last Slot: into Character", 1, true)
        and info:find("No Slot: no free slot in Character", 1, true), info)
    -- A full tab, a text too long: said, not imported.
    CreateMacro("Filler last", 1, "/sit", true)
    fillers = fillers + 1
    C("box"):SetText(ns.Share.Encode({ { scope = "character", icon = 1, name = "No Room", body = "/sit" },
        { scope = "general", icon = 1, name = "Too Long", body = ("/say " .. ("x"):rep(260)) } }))
    info = C("info").text
    check("share: no free slot, too long", info:find("No Room: no free slot in Character", 1, true)
        and info:find("Too Long: longer than the game allows", 1, true) and not C("import"):IsEnabled(), info)
    for i = 1, fillers - 1 do DeleteMacro(GetMacroIndexByName("Filler " .. i)) end
    DeleteMacro(GetMacroIndexByName("Filler last"))

    -- Not in combat; unsaved changes are asked about first.
    C("box"):SetText(two)
    InCombatLockdown = function() return true end
    local count = GetNumMacros()
    Fire(C("import"), "OnClick")
    InCombatLockdown = function() return false end
    check("share: not in combat", GetNumMacros() == count and MacroSenseShare:IsShown()
        and printed[#printed]:find("in combat") ~= nil)
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    local asked, show = 0, StaticPopup_Show
    StaticPopup_Show = function(...)
        asked = asked + 1
        return show(...)
    end
    Fire(C("import"), "OnClick")
    StaticPopup_Show = show
    check("share: unsaved changes asked about", asked == 1 and GetMacroIndexByName("Share A 3") > 0, asked)

    for _, name in ipairs({ "Share A", "Share A 2", "Share A 3", "Share B", "Share New", "Share New 2" }) do
        local index = GetMacroIndexByName(name)
        if index > 0 then DeleteMacro(index) end
    end
    Send("UPDATE_MACROS")
    ns.Window.SetScope("general")
    ns.Window.Select(1)
    NextFrame()
end

-- Trash: a macro deleted anywhere comes back with a click; a rename in the game's window is no delete.
do
    local trashBtn
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Trash" then trashBtn = o end
    end
    local function Rows()
        if MacroSenseMenu:IsShown() then MacroSenseMenu:Hide() end
        Fire(trashBtn, "OnClick")
        local rows = {}
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() then rows[#rows + 1] = r end
        end
        return rows
    end
    local function Labels()
        local out = {}
        for i, r in ipairs(Rows()) do out[i] = ns.Highlight.Strip(r.text.text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
        MacroSenseMenu:Hide()
        return table.concat(out, " / ")
    end
    local function Row(label)
        for _, r in ipairs(Rows()) do
            if r.text.text:sub(1, #label) == label then return r end
        end
    end
    local function wipe(t) for i = #t, 1, -1 do t[i] = nil end end
    local function body(name) return select(3, GetMacroInfo(GetMacroIndexByName(name))) end
    wipe(ns.History.Trash("general"))
    wipe(ns.History.Trash("character"))
    check("trash: empty", Labels() == "No deleted macros / Empty the trash", Labels())

    CreateMacro("Trash A", 135000, "/cast Fear", false)
    CreateMacro("Trash B", 135001, "/cast Heal", true)
    CreateMacro("Trash C", 135002, "/cast Fire", false)
    Send("UPDATE_MACROS")
    ns.Window.Delete(GetMacroIndexByName("Trash A")) -- here
    Send("UPDATE_MACROS")
    clock = clock + 60
    DeleteMacro(GetMacroIndexByName("Trash B")) -- in the game's window
    Send("UPDATE_MACROS")
    EditMacro(GetMacroIndexByName("Trash C"), "Trash C", 135002, "/cast Fire\n/sit")
    Send("UPDATE_MACROS")
    EditMacro(GetMacroIndexByName("Trash C"), "Trash D", 135002, "/cast Fire\n/sit") -- renamed there
    Send("UPDATE_MACROS")
    check("trash: deleted here and there, newest first", Labels() == "Trash B  Today, 14:33 / Trash A  Today, "
        .. "14:32 / Empty the trash", Labels())
    check("trash: a rename is no delete, its versions go along", ns.History.Store("general")["Trash C"] == nil
        and #ns.History.Store("general")["Trash D"] == 1)
    check("trash: each tab's own", #ns.History.Trash("general") == 1 and #ns.History.Trash("character") == 1
        and ns.db.trash[1].name == "Trash A" and ns.char.trash[1].name == "Trash B")
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(Row("Trash B"), "OnEnter")
    GameTooltip.AddLine = nil
    MacroSenseMenu:Hide()
    check("trash: where from, when, the text", table.concat(tip, " / ")
        == "Trash B / Deleted from Character: Today, 14:33. Click to bring it back. / /cast Heal", table.concat(tip, " / "))

    Fire(Row("Trash A"), "OnClick")
    check("trash: back as it was, opened", body("Trash A") == "/cast Fear"
        and select(2, GetMacroInfo(GetMacroIndexByName("Trash A"))) == 135000 and raw() == "/cast Fear"
        and ns.db.scope == "general", raw())
    check("trash: and out of the trash", Labels() == "Trash B  Today, 14:33 / Empty the trash", Labels())
    CreateMacro("Trash B", 135001, "/cast Other", true)
    Send("UPDATE_MACROS")
    Fire(Row("Trash B"), "OnClick")
    check("trash: a taken name gets a number", body("Trash B 2") == "/cast Heal" and body("Trash B") == "/cast Other"
        and ns.db.scope == "character", body("Trash B 2"))

    -- A full tab: the macro waits; not in combat; unsaved changes are asked about.
    DeleteMacro(GetMacroIndexByName("Trash A"))
    Send("UPDATE_MACROS")
    local fillers = SLOTS.MAX_ACCOUNT_MACROS - GetNumMacros()
    for i = 1, fillers do CreateMacro("Filler " .. i, 1, "/sit", false) end
    local full = Row("Trash A")
    local count = GetNumMacros()
    Fire(full, "OnClick")
    MacroSenseMenu:Hide()
    ns.Window.Undelete("general", ns.History.Trash("general")[#ns.History.Trash("general")])
    check("trash: not into a full tab", full.item.disabled and GetNumMacros() == count
        and printed[#printed]:find("no free general macro slots", 1, true) ~= nil, printed[#printed])
    for i = 1, fillers do DeleteMacro(GetMacroIndexByName("Filler " .. i)) end
    Send("UPDATE_MACROS")
    wipe(ns.History.Trash("general")) -- the fillers
    ns.History.Discard(ns.History.Trash("general"), "Trash A", { body = "/cast Fear", icon = 135000 }, clock)
    InCombatLockdown = function() return true end
    count = GetNumMacros()
    ns.Window.Undelete("general", ns.History.Trash("general")[1])
    InCombatLockdown = function() return false end
    check("trash: not in combat", GetNumMacros() == count and printed[#printed]:find("in combat") ~= nil)
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    local asked, show = 0, StaticPopup_Show
    StaticPopup_Show = function(...)
        asked = asked + 1
        return show(...)
    end
    Fire(Row("Trash A"), "OnClick")
    check("trash: unsaved changes asked about", asked == 1 and body("Trash A") == "/cast Fear", asked)
    DeleteMacro(GetMacroIndexByName("Trash A"))
    Send("UPDATE_MACROS")
    Fire(Row("Empty the trash"), "OnClick")
    StaticPopup_Show = show
    check("trash: emptied, after asking", asked == 2 and Labels() == "No deleted macros / Empty the trash", Labels())

    -- A long trash: the newest in the menu, the rest counted.
    for i = 1, 14 do ns.History.Discard(ns.History.Trash("general"), "Old " .. i, { body = "/sit", icon = 1 }, i) end
    local rows = Rows()
    MacroSenseMenu:Hide()
    check("trash: the newest twelve, the rest counted", #rows == 14 and rows[1].text.text:find("^Old 14")
        and ns.Highlight.Strip(rows[13].text.text) == "2 older" and rows[13].item.disabled, #rows)

    -- The x of a deleted macro deletes it for good, after asking; the rest stay.
    rows = Rows()
    check("trash: an x on each deleted macro", rows[1].remove:IsShown() and rows[12].remove:IsShown()
        and not rows[13].remove:IsShown() and not rows[14].remove:IsShown())
    tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(rows[1].remove, "OnEnter")
    GameTooltip.AddLine = nil
    Fire(rows[1].remove, "OnLeave")
    local which, said
    StaticPopup_Show = function(w, text, ...)
        which, said = w, text
        return show(w, text, ...)
    end
    Fire(rows[1].remove, "OnClick")
    StaticPopup_Show = show
    local trash = ns.History.Trash("general")
    check("trash: the x deletes it for good, after asking", tip[1] == "Delete for good"
        and which == "MACROSENSE_FORGET_DELETED" and said == "Old 14" and #trash == 13
        and trash[#trash].name == "Old 13", said)
    check("trash: one older less", Labels():find("1 older", 1, true) ~= nil, Labels())
    for _, name in ipairs({ "Trash B", "Trash B 2", "Trash D" }) do DeleteMacro(GetMacroIndexByName(name)) end
    Send("UPDATE_MACROS")
    wipe(ns.History.Trash("general"))
    wipe(ns.History.Trash("character"))
    ns.Window.SetScope("general")
    ns.Window.Select(1)
    NextFrame()
end

-- A menu row that is the chosen one and has an x stays lit when the mouse leaves the x.
do
    local b = ns.MenuButton(UIParent, "Test", 80, function()
        return { { name = "Chosen", current = true, onClick = function() end, onRemove = function() end,
            removeTip = "Remove" } }
    end)
    Fire(b, "OnClick")
    local r = MacroSenseMenu.rows[1]
    Fire(r.remove, "OnEnter")
    Fire(r.remove, "OnLeave")
    check("menu x: the chosen row stays lit", r.bg:IsShown())
    MacroSenseMenu:Hide()
end

-- The x of a macro in the list deletes it, after asking. The one being edited: the next one opens; another one:
-- the editor keeps what it shows. There is no Delete button.
do
    local deleteButton
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Delete" then deleteButton = o end
    end
    check("list x: no Delete button", deleteButton == nil)
    for _, name in ipairs({ "Del X", "Del A", "Del B", "Del C", "Del D", "Del F" }) do
        CreateMacro(name, 1, "/cast " .. name:sub(-1), false)
    end
    Send("UPDATE_MACROS")
    local function row(name)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.alert and o.text and o.text.text == name and o:IsShown() then return o end
        end
    end
    local function body(name)
        local index = GetMacroIndexByName(name)
        return index > 0 and select(3, GetMacroInfo(index)) or nil
    end
    ns.Window.Open(GetMacroIndexByName("Del B"))
    NextFrame()
    check("list x: on each macro", row("Del A").remove:IsShown() and row("Del B").remove:IsShown())
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(row("Del A").remove, "OnEnter")
    GameTooltip.AddLine = nil
    check("list x: says what it does, the row lit", tip[1] == "Delete this macro" and row("Del A").bg:IsShown()
        and row("Del A").remove.mark.textColor == ns.scheme.invalid, tip[1])
    Fire(row("Del A").remove, "OnLeave")
    check("list x: as it was", not row("Del A").bg:IsShown() and row("Del A").remove.mark.textColor == ns.scheme.dim)

    -- Another macro, above the one being edited: its unsaved text stays, and Save saves it to its own macro.
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    local which, said, show = nil, nil, StaticPopup_Show
    StaticPopup_Show = function(w, text, ...)
        which, said = w, text
        return show(w, text, ...)
    end
    Fire(row("Del A").remove, "OnClick")
    StaticPopup_Show = show
    check("list x: another macro, after asking", which == "MACROSENSE_DELETE" and said == "Del A"
        and GetMacroIndexByName("Del A") == 0 and row("Del A") == nil, said)
    check("list x: the editor keeps its text", raw() == "/cast B\n/sit" and row("Del B").selected, raw())
    ns.Window.Save()
    check("list x: and saves it to its macro", body("Del B") == "/cast B\n/sit" and body("Del C") == "/cast C",
        body("Del B"))

    -- The one being edited: the next one opens.
    Fire(row("Del B").remove, "OnClick")
    check("list x: the one being edited, then the next", GetMacroIndexByName("Del B") == 0 and raw() == "/cast C"
        and row("Del C").selected, raw())

    -- Another macro, below the one being edited: that one stays where it is.
    Fire(row("Del F").remove, "OnClick")
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    ns.Window.Save()
    check("list x: one below, the edited one stays itself", GetMacroIndexByName("Del F") == 0
        and row("Del C").selected and body("Del C") == "/cast C\n/sit" and body("Del X") == "/cast X", body("Del C"))

    -- The macros moved before the answer: the macro asked about is found by its name; one gone, nothing happens.
    local asked
    StaticPopup_Show = function(_, _, _, data) asked = data end -- the question stays open
    Fire(row("Del C").remove, "OnClick")
    DeleteMacro(GetMacroIndexByName("Del X"))
    StaticPopupDialogs.MACROSENSE_DELETE.OnAccept(nil, asked)
    check("list x: moved, found by its name", GetMacroIndexByName("Del C") == 0 and body("Del D") == "/cast D")
    Fire(row("Del D").remove, "OnClick")
    StaticPopup_Show = show
    DeleteMacro(GetMacroIndexByName("Del D"))
    local count = GetNumMacros()
    StaticPopupDialogs.MACROSENSE_DELETE.OnAccept(nil, asked)
    check("list x: gone already, nothing deleted", GetNumMacros() == count)

    -- Two macros of one name: the x deletes its own.
    CreateMacro("Twin", 1, "/cast 1", false)
    CreateMacro("Twin", 1, "/cast 2", false)
    Send("UPDATE_MACROS")
    local twins = {}
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.alert and o.text and o.text.text == "Twin" and o:IsShown() then twins[#twins + 1] = o end
    end
    table.sort(twins, function(a, b) return a.index < b.index end)
    Fire(twins[2].remove, "OnClick")
    local first = body("Twin")
    DeleteMacro(GetMacroIndexByName("Twin"))
    check("list x: of two of one name, its own", first == "/cast 1" and GetMacroIndexByName("Twin") == 0, first)

    -- Asked in one tab, answered in the other: the macro being edited there stays itself.
    CreateMacro("Del G", 1, "/cast G", false)
    CreateMacro("Del H", 1, "/cast H", true)
    Send("UPDATE_MACROS")
    StaticPopup_Show = function(_, _, _, data) asked = data end
    Fire(row("Del G").remove, "OnClick")
    StaticPopup_Show = show
    ns.Window.Open(GetMacroIndexByName("Del H"))
    NextFrame()
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    StaticPopupDialogs.MACROSENSE_DELETE.OnAccept(nil, asked)
    ns.Window.Save()
    check("list x: asked in one tab, the other's macro stays", GetMacroIndexByName("Del G") == 0
        and body("Del H") == "/cast H\n/sit", body("Del H"))
    DeleteMacro(GetMacroIndexByName("Del H"))
    Send("UPDATE_MACROS")
    ns.Window.SetScope("general")
    NextFrame()

    -- The game reports the change while it deletes (UPDATE_MACROS): the next one opens all the same, or the one
    -- before after the last; nothing is left to discard. Another one: the one being edited stays itself.
    local deleteMacro, ask = DeleteMacro, ns.Ask
    DeleteMacro = function(index)
        deleteMacro(index)
        Send("UPDATE_MACROS")
    end
    local discards = 0
    ns.Ask = function(which, ...)
        if which == "MACROSENSE_DISCARD" then discards = discards + 1 end
        return ask(which, ...)
    end
    ns.Window.SetScope("character")
    NextFrame()
    for _, name in ipairs({ "Last A", "Last B", "Last C" }) do CreateMacro(name, 1, "/cast " .. name:sub(-1), true) end
    Send("UPDATE_MACROS")
    ns.Window.Open(GetMacroIndexByName("Last B"))
    NextFrame()
    Fire(row("Last B").remove, "OnClick")
    check("list x: told at once, the next one opens", raw() == "/cast C" and row("Last C").selected
        and not saveIsEnabled(), raw())
    Fire(row("Last C").remove, "OnClick")
    check("list x: after the last, the one before", raw() == "/cast A" and row("Last A").selected
        and not saveIsEnabled(), raw())
    CreateMacro("Last M", 1, "/cast M", true)
    CreateMacro("Last Z", 1, "/cast Z", true)
    Send("UPDATE_MACROS")
    ns.Window.Select(GetMacroIndexByName("Last Z"))
    check("list x: nothing to discard after it", discards == 0 and raw() == "/cast Z", discards)
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    Fire(row("Last A").remove, "OnClick")
    ns.Window.Save()
    check("list x: told at once, another one: the edited one stays itself", body("Last Z") == "/cast Z\n/sit"
        and body("Last M") == "/cast M" and row("Last Z").selected and discards == 0, body("Last Z"))
    Fire(row("Last Z").remove, "OnClick")
    check("list x: told at once, the last one deleted: nothing to save", GetMacroIndexByName("Last Z") == 0
        and raw() ~= "/cast Z\n/sit" and not saveIsEnabled(), raw())
    ns.Ask, DeleteMacro = ask, deleteMacro
    DeleteMacro(GetMacroIndexByName("Last M"))
    Send("UPDATE_MACROS")
    ns.Window.SetScope("general")
    NextFrame()

    -- Not in combat.
    CreateMacro("Del E", 1, "/sit", false)
    Send("UPDATE_MACROS")
    InCombatLockdown = function() return true end
    Fire(row("Del E").remove, "OnClick")
    InCombatLockdown = function() return false end
    check("list x: not in combat", GetMacroIndexByName("Del E") > 0 and printed[#printed]:find("in combat") ~= nil)
    DeleteMacro(GetMacroIndexByName("Del E"))
    Send("UPDATE_MACROS")
    ns.Window.SetScope("general")
    ns.Window.Select(1)
    NextFrame()
end

-- The icon chosen for a macro is kept and saved, not the one it shows now: the question mark with
-- #showtooltip shows the spell's, and saving that would fix the macro's icon to it. The header shows what the
-- macro shows, as the list and the action bars do; an icon picked shows as picked until it is saved.
do
    local m = { name = "Shown", icon = 134400, body = "#showtooltip\n/cast Fireball", perChar = false, shown = 4242 }
    macros[#macros + 1] = m
    Send("UPDATE_MACROS")
    local index = GetMacroIndexByName("Shown")
    ns.Window.Open(index)
    NextFrame()
    local headerTex, row
    for _, o in ipairs(created) do
        if o.kind == "Texture" and o.parentFrame == MacroSenseIconButton and o.texture then headerTex = o end
        if o.kind == "Button" and o.index == index and o:IsShown() then row = o end
    end
    local function header() return headerTex and headerTex.texture end
    check("icon: the header shows what the macro shows", header() == 4242, header())
    check("icon: so does the list", row and row.icon.texture == 4242, row and row.icon.texture)
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(MacroSenseIconButton, "OnEnter")
    GameTooltip.AddLine = nil
    check("icon: the tooltip says what the question mark does", tip[3] and tip[3]:find("^Its icon is the question "
        .. "mark") ~= nil, tip[3])
    m.shown = 4343 -- Shift held: #showtooltip shows another spell
    Wait(0.12)
    check("icon: the header follows the game", header() == 4343, header())
    m.shown = 4242
    Fire(MacroSenseIconButton, "OnClick")
    local grid = {}
    for _, o in ipairs(created) do if o.kind == "Button" and o.entry and o:IsShown() then grid[#grid + 1] = o end end
    Fire(grid[2], "OnClick")
    Wait(0.12)
    check("icon: one picked shows as picked", header() == grid[2].entry.icon and grid[2].entry.icon ~= 4242, header())
    tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(MacroSenseIconButton, "OnEnter")
    GameTooltip.AddLine = nil
    check("icon: another icon needs no word about the question mark", #tip == 2, #tip)
    Fire(grid[1], "OnClick")
    MacroSenseIconPicker:Hide()
    check("icon: the question mark again shows the spell's", header() == 4242, header())
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    ns.Window.Save()
    Type("\n/sit")
    ns.Window.Save() -- after a save too
    check("icon: saved as chosen", m.icon == 134400 and m.body:find("/sit\n/sit", 1, true) ~= nil, m.icon)
    local share
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Share" then share = o end
    end
    Fire(share, "OnClick")
    for _, r in ipairs(MacroSenseMenu.rows) do
        if r:IsShown() and r.text.text:find("^Export the General tab") then Fire(r, "OnClick") end
    end
    local exported
    for _, x in ipairs(ns.Share.Decode(ns.ShareWindow.Control("box").text)) do
        if x.name == "Shown" then exported = x.icon end
    end
    ns.ShareWindow.Close()
    check("icon: exported as chosen", exported == 134400, exported)
    ns.Window.Delete(GetMacroIndexByName("Shown"))
    Send("UPDATE_MACROS")
    local trash = ns.History.Trash("general")
    check("icon: kept as chosen in the trash", trash[#trash].name == "Shown" and trash[#trash].icon == 134400,
        trash[#trash].icon)
    trash[#trash] = nil
    ns.Window.Select(1)
    NextFrame()
end

-- Backups: one a day by itself when the macros changed, one when asked; a restore brings their texts and the
-- deleted ones back, and leaves the macros made since.
do
    local button
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Backups" then button = o end
    end
    local function Rows()
        if MacroSenseMenu:IsShown() then MacroSenseMenu:Hide() end
        Fire(button, "OnClick")
        local rows = {}
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() then rows[#rows + 1] = r end
        end
        return rows
    end
    local function Labels()
        local out = {}
        for i, r in ipairs(Rows()) do out[i] = r.text.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
        MacroSenseMenu:Hide()
        return table.concat(out, " / ")
    end
    local function indexIn(scope, name)
        local first = scope == "character" and SLOTS.MAX_ACCOUNT_MACROS + 1 or 1
        local last = scope == "character" and SLOTS.MAX_ACCOUNT_MACROS + select(2, GetNumMacros()) or GetNumMacros()
        for index = first, last do
            if GetMacroInfo(index) == name then return index end
        end
    end
    local function body(scope, name)
        local index = indexIn(scope, name)
        return index and select(3, GetMacroInfo(index))
    end
    ns.char.backups = nil
    check("backups: none yet", Labels() == "Back up now / No backups yet", Labels())
    CreateMacro("Bk A", 135000, "/cast Fear", false)
    CreateMacro("Bk B", 135001, "/cast Heal", true)
    CreateMacro("Bk C", 1, "/cast G", false) -- one name in both tabs: two macros
    CreateMacro("Bk C", 1, "/cast C", true)
    Send("UPDATE_MACROS")
    Send("PLAYER_LOGIN")
    check("backups: one on login", ns.char.backups and #ns.char.backups == 1)
    EditMacro(GetMacroIndexByName("Bk A"), "Bk A", 135000, "/cast Fear\n/say same day")
    Send("UPDATE_MACROS")
    ns.Window.DailyBackup()
    check("backups: one a day", #ns.char.backups == 1)
    clock = clock + 86400
    EditMacro(GetMacroIndexByName("Bk A"), "Bk A", 135000, "/cast Fear\n/say a")
    Send("UPDATE_MACROS")
    ns.Window.DailyBackup()
    local count = #ns.char.backups
    check("backups: the next day, as they changed", count == 2)
    check("backups: newest first, with how many macros", Labels():find("^Back up now / Today, 14:3%d  %d+ macros / "
        .. "Yesterday, 14:3%d  %d+ macros$") ~= nil, Labels())
    Fire(Rows()[1], "OnClick")
    check("backups: nothing new to back up", #ns.char.backups == count
        and printed[#printed]:find("as in the last backup", 1, true) ~= nil, printed[#printed])
    local numMacros = GetNumMacros
    GetNumMacros = function() return 0, 0 end
    Fire(Rows()[1], "OnClick")
    GetNumMacros = numMacros
    check("backups: no macros, no backup", #ns.char.backups == count
        and printed[#printed]:find("no macros to back up", 1, true) ~= nil, printed[#printed])
    EditMacro(GetMacroIndexByName("Bk A"), "Bk A", 135000, "/cast Fear\n/say a\n/sit")
    Send("UPDATE_MACROS")
    Fire(Rows()[1], "OnClick")
    count = count + 1
    check("backups: backed up when asked", #ns.char.backups == count
        and printed[#printed]:find("backed up %d+ macros") ~= nil, printed[#printed])

    -- Changed, deleted, made since; a macro of the same name in the other tab is another macro.
    local backup = ns.char.backups[#ns.char.backups]
    EditMacro(GetMacroIndexByName("Bk A"), "Bk A", 135000, "/cast Changed")
    DeleteMacro(GetMacroIndexByName("Bk B"))
    CreateMacro("Bk New", 1, "/sit", false)
    CreateMacro("Bk A", 1, "/cast Other tab", true)
    EditMacro(indexIn("character", "Bk C"), "Bk C", 1, "/cast X")
    Send("UPDATE_MACROS")
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(Rows()[2], "OnEnter")
    GameTooltip.AddLine = nil
    MacroSenseMenu:Hide()
    check("backups: what one holds", tip[1]:find("^Backup of Today") and tip[2]:find("Click to restore it", 1, true)
        and tip[3]:find("Bk A", 1, true), table.concat(tip, " / "))
    Fire(Rows()[2], "OnClick")
    check("backups: texts back, the deleted made again", body("general", "Bk A") == "/cast Fear\n/say a\n/sit"
        and body("character", "Bk B") == "/cast Heal", body("general", "Bk A"))
    check("backups: each tab's macro of one name", body("character", "Bk C") == "/cast C"
        and body("general", "Bk C") == "/cast G", body("general", "Bk C"))
    check("backups: the macros made since stay", body("general", "Bk New") == "/sit"
        and body("character", "Bk A") == "/cast Other tab")
    check("backups: a backup of before, first", #ns.char.backups == count + 1
        and ns.Backups.Same(ns.char.backups[#ns.char.backups].macros, backup.macros) == false)
    check("backups: the replaced text is a version", ns.History.Versions(ns.History.Store("general"), "Bk A",
        "/cast Fear\n/say a\n/sit")[1].body == "/cast Changed")

    -- No room, combat, unsaved changes.
    DeleteMacro(GetMacroIndexByName("Bk B"))
    local fillers = SLOTS.MAX_CHARACTER_MACROS - select(2, GetNumMacros())
    for i = 1, fillers do CreateMacro("Filler " .. i, 1, "/sit", true) end
    ns.Window.RestoreBackup(backup)
    check("backups: no free slot, said", body("character", "Bk B") == nil
        and printed[#printed]:find("1 did not fit", 1, true) ~= nil, printed[#printed])
    for i = 1, fillers do DeleteMacro(GetMacroIndexByName("Filler " .. i)) end
    InCombatLockdown = function() return true end
    local before = #ns.char.backups
    ns.Window.RestoreBackup(backup)
    InCombatLockdown = function() return false end
    check("backups: not in combat", #ns.char.backups == before and printed[#printed]:find("in combat") ~= nil)
    ns.Window.Open(GetMacroIndexByName("Bk New"))
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    local asked, show = 0, StaticPopup_Show
    StaticPopup_Show = function(...)
        asked = asked + 1
        return show(...)
    end
    local list = ns.char.backups
    for k = 1, #list do
        if list[#list - k + 1] == backup then -- the menu: newest first
            Fire(Rows()[k + 1], "OnClick")
            break
        end
    end
    StaticPopup_Show = show
    check("backups: asked first, then unsaved changes", asked == 2 and body("character", "Bk B") == "/cast Heal", asked)

    -- An x on each backup deletes it, after asking; none on Back up now, nor in the other menus.
    local rows = Rows()
    check("backups: an x on each backup", not rows[1].remove:IsShown() and rows[2].remove:IsShown()
        and rows[#rows].remove:IsShown())
    check("backups: the name stops before the x", rows[1].text.point[2] == -8 and rows[2].text.point[2] == -24)
    tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(rows[2].remove, "OnEnter")
    GameTooltip.AddLine = nil
    check("backups: the x says what it does", tip[1] == "Delete this backup" and rows[2].bg:IsShown()
        and rows[2].remove.mark.textColor == ns.scheme.invalid, tip[1])
    Fire(rows[2].remove, "OnLeave")
    check("backups: the x as it was", not rows[2].bg:IsShown() and rows[2].remove.mark.textColor == ns.scheme.dim)
    local backups, asked = ns.char.backups, nil
    local newest, before = backups[#backups], #backups
    show = StaticPopup_Show
    StaticPopup_Show = function(which, ...)
        asked = which
        return show(which, ...)
    end
    Fire(rows[2].remove, "OnClick")
    StaticPopup_Show = show
    check("backups: the x deletes that one, after asking", asked == "MACROSENSE_DELETE_BACKUP"
        and #backups == before - 1 and backups[#backups] ~= newest and not MacroSenseMenu:IsShown(), asked)
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Share" then Fire(o, "OnClick") end
    end
    local xs = 0
    for _, r in ipairs(MacroSenseMenu.rows) do
        if r:IsShown() and r.remove:IsShown() then xs = xs + 1 end
    end
    MacroSenseMenu:Hide()
    check("backups: no x in the other menus", xs == 0, xs)

    for _, name in ipairs({ "Bk A", "Bk A", "Bk B", "Bk C", "Bk C", "Bk New" }) do
        local index = GetMacroIndexByName(name)
        if index > 0 then DeleteMacro(index) end
    end
    Send("UPDATE_MACROS")
    ns.char.backups = nil
    ns.Window.SetScope("general")
    ns.Window.Select(1)
    NextFrame()
end

-- In combat the game doesn't let macros change: Save and Delete say so and leave the macro as it is.
do
    CreateMacro("Fight", 1, "/cast Fear", false)
    Send("UPDATE_MACROS")
    ns.Window.Open(GetMacroIndexByName("Fight"))
    NextFrame()
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/sit")
    InCombatLockdown = function() return true end
    ns.Window.Save()
    local saved = select(3, GetMacroInfo(GetMacroIndexByName("Fight")))
    check("combat: no save", saved == "/cast Fear" and printed[#printed]:find("in combat") ~= nil, saved)
    printed[#printed] = nil
    ns.Window.Delete(GetMacroIndexByName("Fight"))
    check("combat: no delete", GetMacroIndexByName("Fight") > 0 and printed[#printed]:find("in combat") ~= nil)
    InCombatLockdown = function() return false end
    ns.Window.Revert()
    DeleteMacro(GetMacroIndexByName("Fight"))
    Send("UPDATE_MACROS")
    ns.Window.Select(1)
    NextFrame()
end

-- A command the client has but its game does nothing with: /petmoveto before Cataclysm is a warning.
do
    local function warned(raw)
        local e = ns.Highlight.Errors(raw)[1]
        return e and e.severity == "warning" and e.short or nil
    end
    LE_EXPANSION_LEVEL_CURRENT = 1
    check("petmoveto: a warning in TBC", warned("/petmoveto [@cursor]") == "not in this game version",
        warned("/petmoveto [@cursor]"))
    check("petmoveto: other commands are fine", #ns.Highlight.Errors("/target party1") == 0)
    LE_EXPANSION_LEVEL_CURRENT = 4
    check("petmoveto: fine from Cataclysm on", warned("/petmoveto [@cursor]") == nil)
    LE_EXPANSION_LEVEL_CURRENT = nil
    check("petmoveto: fine where the version is not known", warned("/petmoveto") == nil)
end

-- Cancel a buff and /cancelaura offer buffs, not spells: those on you now, then those you have had, kept for the
-- character (the last 200 seen), a second after they change. Data Retail hides from addons is left out.
do
    local watched
    for _, o in ipairs(created) do
        if o.unitEvents and o.unitEvents.UNIT_AURA then watched = o.unitEvents.UNIT_AURA end
    end
    check("buffs: the player's are watched", watched == "player", watched)
    ns.char.buffs = {}
    auras[1], auras[2], auras[3] = { name = "Ice Block", icon = 101 }, { name = "Arcane Intellect", icon = 102 },
        { name = "Hidden", icon = 103 }
    secret.Hidden = true
    local reads = auraReads
    Send("UNIT_AURA", "player")
    Send("UNIT_AURA", "player")
    check("buffs: not at once", ns.char.buffs["Ice Block"] == nil)
    Wait(1.1)
    check("buffs: kept a second later, read once", ns.char.buffs["Ice Block"] and ns.char.buffs["Ice Block"].icon == 101
        and ns.char.buffs["Arcane Intellect"] and auraReads - reads == 4, auraReads - reads)
    check("buffs: hidden ones left out", ns.char.buffs.Hidden == nil)
    check("buffs: known names for the typo check", ns.KnownActions().set["ice block"] == true)
    auras[1], auras[2], auras[3] = { name = "Arcane Intellect", icon = 102 }, nil, nil
    local names = {}
    for i, b in ipairs(ns.sources.buffs()) do names[i] = b.name .. ":" .. b.hint end
    check("buffs: on you now first, then those you had", table.concat(names, ",")
        == "Arcane Intellect:on you now,Ice Block:buff", table.concat(names, ","))
    ns.char.buffs["Arcane Intellect"].seen = 0 -- seen long ago, and on you again now
    for i = 1, ns.BUFFS_KEPT do ns.char.buffs["Old " .. i] = { icon = 1, seen = i } end
    ns.RememberBuffs()
    local n = 0
    for _ in pairs(ns.char.buffs) do n = n + 1 end
    check("buffs: the last ones seen", n == ns.BUFFS_KEPT and ns.char.buffs["Ice Block"] and ns.char.buffs["Old 1"] == nil
        and ns.char.buffs["Old 3"] ~= nil and ns.char.buffs["Arcane Intellect"] ~= nil, n)
    for i = 1, ns.BUFFS_KEPT do ns.char.buffs["Old " .. i] = nil end

    -- The wizard's box lists buffs only; so does /cancelaura in the editor.
    ns.WizardWindow.Open("general")
    local box = ns.WizardWindow.Control("cancelaura")
    Fire(box, "OnEditFocusGained")
    names = {}
    for i, item in ipairs(box.list.items) do names[i] = item.name end
    check("buffs: the wizard's box offers buffs only", table.concat(names, ",") == "Arcane Intellect,Ice Block",
        table.concat(names, ","))
    ns.SetLanguage("uk")
    Fire(box, "OnEditFocusGained")
    ns.SetLanguage("en")
    check("buffs: its hints in the chosen language", box.list.rows[1].hint.text == "зараз на вас"
        and box.list.rows[2].hint.text == "бафф", box.list.rows[1].hint.text)
    box:SetText("ice")
    Fire(box, "OnTextChanged", true)
    check("buffs: found as typed", box.list.items[1] and box.list.items[1].name == "Ice Block")
    Fire(box, "OnEscapePressed")
    ns.WizardWindow.Close()
    ns.Window.New()
    NextFrame()
    edit:SetFocus()
    Type("/cancelaura ")
    names = {}
    for i, item in ipairs(ns.Popup.items) do names[i] = item.name end
    check("buffs: /cancelaura offers them", ns.Popup:IsShown() and table.concat(names, ",") == "Arcane Intellect,Ice Block",
        table.concat(names, ","))
    Key("ESCAPE", "OnEscapePressed")
    ns.Window.Select(1)
    NextFrame()
    auras[1], secret.Hidden = nil, nil
    ns.char.buffs = {}
end

-- Every text MacroSense shows has a Ukrainian translation, and every translation is of a text it shows: the
-- texts in the code (L["..."], ns.Print("..."), ns.Plural(n, "...", "..."), the dialogs) and those of its lists.
do
    local uk = ns.locales.uk
    local shown, data = {}, {}
    -- A "..." at src[i], whole: its value and where it ends.
    local function literal(src, i)
        local j = i + 1
        while src:sub(j, j) ~= '"' do j = j + (src:sub(j, j) == "\\" and 2 or 1) end
        return assert(load("return " .. src:sub(i, j)))(), j + 1
    end
    -- "..." .. "..." from i on: its value, or nil when it is not literals only.
    local function literals(src, i)
        i = src:find("%S", i)
        if src:sub(i, i) ~= '"' then return nil end
        local value, j = literal(src, i)
        while true do
            local k = src:find("%S", j)
            if src:sub(k, k + 1) ~= ".." then return value, j end
            k = src:find("%S", k + 2)
            if src:sub(k, k) ~= '"' then return nil end
            local more
            more, j = literal(src, k)
            value = value .. more
        end
    end
    -- Past the first argument of a call: the comma after it.
    local function nextArg(src, i)
        local depth = 0
        while true do
            local c = src:sub(i, i)
            if c == '"' then
                i = select(2, literal(src, i))
            else
                if c == "(" then depth = depth + 1 elseif c == ")" then depth = depth - 1 end
                if c == "," and depth == 0 then return i + 1 end
                i = i + 1
            end
        end
    end
    local plural = {}
    for line in io.lines("MacroSense/MacroSense.toc") do
        if line:match("%.lua$") and line ~= "Locale.lua" and line ~= "Ukrainian.lua" then
            local lines = {}
            for l in io.lines("MacroSense/" .. line) do
                if not l:find("^%s*%-%-") then lines[#lines + 1] = l end
            end
            local src = table.concat(lines, "\n")
            for i in src:gmatch("()L%[") do
                if not src:sub(i - 1, i - 1):find("[%w_]") then
                    local text = literals(src, i + 2)
                    if text then shown[text] = true end
                end
            end
            for i in src:gmatch("()ns%.Print%(") do
                local text = literals(src, i + 9)
                if text then shown[text] = true end
            end
            for i in src:gmatch("()Plural%(") do
                local one, j = literals(src, nextArg(src, i + 7))
                local other = one and literals(src, src:find(",", j, true) + 1)
                if other then shown[other], plural[other] = true, true end
            end
        end
    end
    for which, d in pairs(StaticPopupDialogs) do
        if which:find("^MACROSENSE_") then
            for _, text in pairs(d.english or { d.text, d.button1, d.button2 }) do shown[text] = true end
        end
    end
    local function add(text) if text and text ~= "" then data[text] = true end end
    for _, list in pairs(ns.data) do
        for _, item in ipairs(list) do add(item.hint) end
    end
    for _, s in ipairs(ns.schemes) do add(s.name) end
    local W = ns.Wizard
    local whenItems = W.WhenForms({})
    for _, w in ipairs(W.whens) do
        for _, item in ipairs(w.items or {}) do whenItems[#whenItems + 1] = item end
    end
    for _, list in ipairs({ W.commands, W.PetActions(99), W.channels, W.units, W.mountPlaces, W.offMount, whenItems,
        W.equipSlots, W.equipKeys }) do
        for _, item in ipairs(list) do add(item.name) end
    end
    for _, command in ipairs(W.commands) do
        for _, place in ipairs({ "first", "then", "key" }) do
            for _, item in ipairs(W.Units(command.key, place)) do add(item.name) end
        end
    end
    for _, what in pairs(ns.Shortcuts.MAC) do add(what) end
    for _, text in ipairs(ns.Explain.Texts()) do add(text) end
    for _, text in ipairs(ns.Docs.Texts()) do add(text) end
    add(ns.ActionBars.TIP)
    -- Kept in their files' locals: month names, tab names, the preview's quiet notes and verbs, hints made in
    -- Sources and Completion, what a condition's value should be, and the wizard's names for a macro.
    for _, text in ipairs({ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
        "General", "Character", "does nothing", "conditions not met", "not reached", "chat", "equip", "cancel", "no form", "primary",
        "secondary", "your pet's name", "pet family", "equipped", "item", "extra action", "leave the vehicle",
        "popup: first button", "popup: second button", "highest", "on you now", "buff",
        "shift, ctrl, alt or a key action like SELFCAST",
        "1-5 or a button name", "party or raid", "a bar page 1-6", "a form number, 0 = no form",
        "a specialization number", "Target", "Focus", "Assist", "Pet" }) do add(text) end
    local SAME = { Mac = true, Retail = true, Monokai = true, ["-"] = true, ["1-5"] = true } -- the same in Ukrainian
    local missing, unused, notForms = {}, {}, {}
    for text in pairs(shown) do
        if not uk[text] then missing[#missing + 1] = text end
    end
    for text in pairs(data) do
        if not uk[text] and not SAME[text] and not text:find("^/") then missing[#missing + 1] = text end
    end
    for text, translation in pairs(uk) do
        if not shown[text] and not data[text] then unused[#unused + 1] = text end
        if (type(translation) == "table") ~= (plural[text] == true) then notForms[#notForms + 1] = text end
    end
    check("ukrainian: every text is translated", #missing == 0, table.concat(missing, " | "))
    check("ukrainian: every translation is of a text shown", #unused == 0, table.concat(unused, " | "))
    check("ukrainian: counts have their forms, and only they", #notForms == 0, table.concat(notForms, " | "))
end

-- In Ukrainian: a dialog, a chat line, a menu; the interface's font has Cyrillic letters on a client whose own
-- font has none. Choosing a language asks, in that language, to reload the interface.
do
    ns.SetLanguage("uk")
    check("ukrainian: a font with its letters", ns.Text(UIParent, 12).fontPath == "Fonts\\FRIZQT___CYR.TTF")
    GetLocale = function() return "ruRU" end
    check("ukrainian: a Russian client's own font", ns.Text(UIParent, 12).fontPath == "Fonts\\FRIZQT__.TTF")
    GetLocale = function() return "enUS" end
    local done
    ns.Ask("MACROSENSE_DISCARD", nil, nil, function() done = true end)
    local d = StaticPopupDialogs.MACROSENSE_DISCARD
    check("ukrainian: a dialog", done and d.text == "Відкинути незбережені зміни цього макросу?" and d.button1 == "Так"
        and d.button2 == "Ні", d.text)
    ns.Print("macros cannot be changed in combat")
    check("ukrainian: a chat line", printed[#printed]:find("у бою макроси змінювати не можна", 1, true) ~= nil,
        printed[#printed])
    local button
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Backups" then button = o end
    end
    ns.char.backups = { { time = clock, macros = { { scope = "general", name = "A", icon = 1, body = "" },
        { scope = "general", name = "B", icon = 1, body = "" } } } }
    Fire(button, "OnClick")
    local rows = {}
    for _, r in ipairs(MacroSenseMenu.rows) do
        if r:IsShown() then rows[#rows + 1] = r.text.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
    end
    MacroSenseMenu:Hide()
    check("ukrainian: a menu, with a count", rows[1] == "Зробити бекап зараз"
        and rows[2]:find("^Сьогодні, %d%d:%d%d  2 макроси$") ~= nil, table.concat(rows, " / "))
    ns.char.backups = nil
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(button, "OnEnter")
    GameTooltip.AddLine = nil
    check("ukrainian: the backups' tooltip, in plain words, with the limit", tip[1] == "Бекапи"
        and tip[2]:find("^Ваші макроси зберігаються самі щодня") ~= nil
        and tip[2]:find("останні 10 бекапів", 1, true) ~= nil, tip[2])
    local trash
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Trash" then trash = o end
    end
    tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(trash, "OnEnter")
    GameTooltip.AddLine = nil
    check("ukrainian: the trash's tooltip, with its limits", tip[2]:find("останні 30 видалених макросів", 1, true)
        and tip[2]:find("У меню видно 12 найновіших.", 1, true), tip[2])
    local preview
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Live preview" then preview = o end
    end
    tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(preview, "OnEnter")
    GameTooltip.AddLine = nil
    local wizard
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "New (Wizard)" then wizard = o end
    end
    local wizardTip = {}
    GameTooltip.AddLine = function(_, text) wizardTip[#wizardTip + 1] = text end
    Fire(wizard, "OnEnter")
    GameTooltip.AddLine = nil
    check("ukrainian: the wizard's tooltip", wizardTip[1] == "Майстер"
        and wizardTip[2]:find("^Створіть новий макрос за допомогою вбудованого майстра! Дайте відповідь") ~= nil,
        wizardTip[2])
    local shorten
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and tostring(o.label.text):find("^Shorten") then shorten = o end
    end
    local shortenTip = {}
    GameTooltip.AddLine = function(_, text) shortenTip[#shortenTip + 1] = text end
    Fire(shorten, "OnEnter")
    GameTooltip.AddLine = nil
    check("ukrainian: the shorten tooltip", shortenTip[1] == "Скоротити"
        and shortenTip[2]:find("^Спробує прибрати зайві пробіли") ~= nil, shortenTip[2])
    check("ukrainian: the live preview's tooltip", tip[1] == "Живий перегляд"
        and tip[3] == "Затискайте модифікатори (Shift, Ctrl, Alt чи Cmd), наводьте мишку, міняйте ціль — "
        .. "використовуйте все, що є в макросі, щоб побачити, яка саме здібність спрацює і в якій ситуації.", tip[3])
    ns.Popup:Style(ns.scheme, "Fonts\\Code.ttf", 13)
    ns.Popup:Open(edit, { { name = "cast", hint = "cast a spell" } }, 0, 0, 14)
    local row = ns.Popup.rows[1]
    check("ukrainian: a suggestion's hint, in the interface's font", row.hint.text == "застосувати заклинання"
        and row.hint.fontPath == "Fonts\\FRIZQT___CYR.TTF" and row.text.fontPath == "Fonts\\Code.ttf", row.hint.text)
    ns.Popup:Hide()
    ns.SetLanguage("en")
    ns.Window.ApplyLook()
    check("ukrainian: English again", ns.Text(UIParent, 12).fontPath == "Fonts\\FRIZQT__.TTF")
    MacroSenseDB.language = "uk"
    Send("ADDON_LOADED", "MacroSense")
    check("ukrainian: chosen when the addon loads", ns.language == "uk")
    MacroSenseDB.language = "en"
    Send("ADDON_LOADED", "MacroSense")

    local language
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "English" then language = o end
    end
    local function choose(name)
        Fire(language, "OnClick")
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() and r.text.text == name then return Fire(r, "OnClick") end
        end
    end
    choose("Ukrainian")
    local r = StaticPopupDialogs.MACROSENSE_RELOAD
    check("language: kept, and the interface reloads", ns.db.language == "uk" and reloads == 1 and ns.language == "en",
        reloads)
    check("language: asked in the language chosen", r.text == "Перезавантажити інтерфейс, щоб змінити мову?"
        and r.button1 == "Перезавантажити", r.text)
    choose("English")
    check("language: the one shown, no reload", ns.db.language == "en" and reloads == 1, reloads)
end

-- Spells you don't have now (Retail): a talent not chosen, another specialization's spell, one you learn later. A
-- warning in the editor and the list, a yellow tint and a tooltip line on the action bars; none where the macro
-- checks the specialization or the talent itself.
do
    local retail = C_SpellBook
    -- Another specialization's skill line first (Fireball is yours too), then yours with Shadowfury to learn later.
    -- Either says a spell is another specialization's: its line or the spell itself.
    local lines = {
        { itemIndexOffset = #book + 1, numSpellBookItems = 4, name = "Destruction", offSpecID = 267 },
        { itemIndexOffset = 0, numSpellBookItems = #book + 1 },
        { itemIndexOffset = #book + 5, numSpellBookItems = 1, name = "Affliction" },
        { itemIndexOffset = #book + 6, numSpellBookItems = 1 }, -- yours: Drain Soul in place of Shadow Bolt
        { itemIndexOffset = #book + 7, numSpellBookItems = 1, name = "Demonology", offSpecID = 266 },
    }
    local more = {
        [#book + 1] = { name = "Shadowfury", subName = "", itemType = 2, isPassive = false, iconID = 1, spellID = 30283 },
        [#book + 2] = { name = "Chaos Bolt", subName = "", itemType = 1, isPassive = false, iconID = 2, isOffSpec = true },
        [#book + 3] = { name = "Fireball", subName = "", itemType = 1, isPassive = false, iconID = 3, isOffSpec = true },
        [#book + 4] = { name = "Soul Fire", subName = "", itemType = 2, isPassive = false, iconID = 4, isOffSpec = true },
        [#book + 5] = { name = "Incinerate", subName = "", itemType = 1, isPassive = false, iconID = 5 },
        [#book + 6] = { name = "Haunt", subName = "", itemType = 1, isPassive = false, iconID = 6, isOffSpec = true },
        [#book + 7] = { name = "Drain Soul", subName = "", itemType = 1, isPassive = false, iconID = 7, actionID = 686,
            spellID = 198590 },
        [#book + 8] = { name = "Shadow Bolt", subName = "", itemType = 1, isPassive = false, iconID = 8, isOffSpec = true,
            actionID = 686, spellID = 686 },
    }
    gameSpells[686] = { 1, "Shadow Bolt" }
    C_SpellBook = setmetatable({
        GetNumSpellBookSkillLines = function() return #lines end,
        GetSpellBookSkillLineInfo = function(i) return lines[i] end,
        GetSpellBookItemInfo = function(slot, bank) return more[slot] or retail.GetSpellBookItemInfo(slot, bank) end,
    }, { __index = retail })
    -- The tree: Death Coil not chosen, Howl of Terror chosen, Fear another specialization's (not shown), Dark Pact
    -- chosen of a choice with Mortal Coil, Soul Leech in a hero tree not chosen.
    local nodes = {
        { isVisible = true, activeRank = 0, activeEntry = { entryID = 11 }, entryIDs = { 11 } },
        { isVisible = true, activeRank = 1, activeEntry = { entryID = 21 }, entryIDs = { 21 } },
        { isVisible = false, activeRank = 0, entryIDs = { 31 } },
        { isVisible = true, activeRank = 1, activeEntry = { entryID = 41 }, entryIDs = { 41, 42 } },
        { isVisible = true, activeRank = 1, activeEntry = { entryID = 51 }, entryIDs = { 51 }, subTreeID = 9,
            subTreeActive = false },
    }
    local spellOf = { [11] = 6789, [21] = 5484, [31] = 5782, [41] = 70001, [42] = 70002, [51] = 70003 }
    gameSpells[70001], gameSpells[70002], gameSpells[70003] = { 1, "Dark Pact" }, { 1, "Mortal Coil" }, { 1, "Soul Leech" }
    local configID = 7
    C_ClassTalents = { GetActiveConfigID = function() return configID end }
    C_Traits = {
        GetConfigInfo = function(id) return id == 7 and { treeIDs = { 1 } } or nil end,
        GetTreeNodes = function() return { 1, 2, 3, 4, 5 } end,
        GetNodeInfo = function(_, id) return nodes[id] end,
        GetEntryInfo = function(_, id) return { definitionID = id } end,
        GetDefinitionInfo = function(id) return { spellID = spellOf[id], overrideName = id == 11 and "Coil" or nil } end,
    }
    ns.InvalidateSources("spells")
    -- The first issue's short form, "(missing)" when it is a spell you don't have.
    local function issue(text)
        local e = ns.Highlight.Errors(text)[1]
        return e and (e.short .. (e.missing and " (missing)" or "")) or ""
    end
    check("missing: a talent not chosen", issue("/cast Death Coil") == "talent not chosen (missing)",
        issue("/cast Death Coil"))
    check("missing: in full", ns.Highlight.Errors("/cast Death Coil")[1].message
        == "\"Death Coil\": a talent you haven't chosen, the macro can't use it now")
    check("missing: by the talent's own name too", issue("/cast Coil") == "talent not chosen (missing)", issue("/cast Coil"))
    check("missing: not a chosen one", issue("/cast Dark Pact") == "", issue("/cast Dark Pact"))
    check("missing: the other one of a choice", issue("/cast Mortal Coil") == "talent not chosen (missing)",
        issue("/cast Mortal Coil"))
    check("missing: a hero tree not chosen", issue("/cast Soul Leech") == "talent not chosen (missing)",
        issue("/cast Soul Leech"))
    check("missing: not another specialization's talents", issue("/cast Fear") == "", issue("/cast Fear"))
    check("missing: another specialization's spell", issue("/cast Chaos Bolt") == "Destruction only (missing)",
        issue("/cast Chaos Bolt"))
    check("missing: by its skill line", issue("/cast Incinerate") == "Destruction only (missing)", issue("/cast Incinerate"))
    check("missing: by the spell", issue("/cast Haunt") == "Affliction only (missing)", issue("/cast Haunt"))
    check("missing: in full, with the specialization", ns.Highlight.Errors("/cast Chaos Bolt")[1].message
        == "\"Chaos Bolt\" belongs to Destruction: you are in another specialization now")
    check("missing: not a spell of yours too", issue("/cast Fireball") == "", issue("/cast Fireball"))
    check("missing: not the spell a talent replaces", issue("/cast Shadow Bolt") == "" and issue("/cast Drain Soul") == "",
        issue("/cast Shadow Bolt"))
    check("missing: a spell learned later", issue("/cast Shadowfury") == "not learned yet (missing)",
        issue("/cast Shadowfury"))
    check("missing: another specialization's, learned later", issue("/cast Soul Fire") == "Destruction only (missing)",
        issue("/cast Soul Fire"))
    check("missing: with its level", ns.Highlight.Errors("/cast Shadowfury")[1].message
        == "\"Shadowfury\": you learn it at level 40", ns.Highlight.Errors("/cast Shadowfury")[1].message)
    check("missing: /use casts it too", issue("/use Death Coil") == "talent not chosen (missing)")
    check("missing: in a sequence", issue("/castsequence Fireball, Death Coil") == "talent not chosen (missing)")
    check("missing: in #showtooltip", issue("#showtooltip Death Coil") == "talent not chosen (missing)")
    check("missing: at random", issue("/castrandom Fireball, Death Coil") == "talent not chosen (missing)"
        and issue("/userandom Fireball, Death Coil") == "talent not chosen (missing)")
    check("missing: not for /cancelaura", issue("/cancelaura Death Coil") == "", issue("/cancelaura Death Coil"))
    check("missing: the specialization checked first", issue("/cast [spec:2] Chaos Bolt; Fireball") == "")
    check("missing: also as nospec", issue("/cast [nospec:1] Chaos Bolt") == "")
    check("missing: the talent checked first", issue("/cast [talent:4/2] Death Coil") == "")
    check("missing: known checked first", issue("/cast [known:Death Coil] Death Coil; Fireball") == "")
    check("missing: in a group of its own", issue("/cast [@focus][spec:2] Chaos Bolt") == ""
        and issue("/cast [spec:2][@focus] Chaos Bolt") == "")
    check("missing: the next branch has its own", issue("/cast [spec:2] Fireball; Chaos Bolt")
        == "Destruction only (missing)", issue("/cast [spec:2] Fireball; Chaos Bolt"))
    check("missing: other conditions don't count", issue("/cast [mod:shift,nodead] Chaos Bolt")
        == "Destruction only (missing)")
    local typo = ns.Highlight.Errors("/cast Death Coyl")[1]
    check("missing: a typo of one gets its fix", typo and typo.fix == "Death Coil" and not typo.missing,
        typo and typo.fix)
    local hint
    for _, item in ipairs(ns.Completion.Get(ns.Parser.GetContext("/cast Chaos", 11))) do
        if item.name == "Chaos Bolt" then hint = item.hint end
    end
    check("missing: suggested with its specialization", hint == "Destruction", hint)
    -- Talents not loaded yet (just logged in): none, and no talents of the Classic kind either.
    configID = nil
    talentInfo = function() return { name = "Blazing Speed", selected = false, rank = 0, spellID = 0 } end
    ns.InvalidateSources("spells")
    check("missing: talents not loaded yet", issue("/cast Death Coil") == "" and issue("/cast Blazing Speed") == "",
        issue("/cast Blazing Speed"))
    configID, talentInfo = 7, nil
    ns.InvalidateSources("spells")
    -- A buff of that name (Power Infusion from a priest) is no spell of yours.
    ns.char.buffs["Mortal Coil"] = { icon = 1, seen = 1 }
    ns.InvalidateSources("buffs")
    check("missing: not hidden by a buff of its name", issue("/cast Mortal Coil") == "talent not chosen (missing)")
    ns.char.buffs["Mortal Coil"] = nil
    ns.InvalidateSources("buffs")

    -- The editor and its list.
    if not MacroSenseFrame:IsShown() then ns.Window.Toggle() end
    CreateMacro("Coil", 1, "/cast Death Coil", false)
    Send("UPDATE_MACROS")
    ns.Window.Select(GetMacroIndexByName("Coil"))
    NextFrame()
    NextFrame()
    local function statusText()
        for _, o in ipairs(created) do
            if o.kind == "FontString" and tostring(o.text):find("Line %d+:") then return o.text end
        end
        return ""
    end
    local function row(name)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.shown and o.name == name and o.index then return o end
        end
    end
    check("missing: in the status bar", statusText():find("Line 1: talent not chosen", 1, true) ~= nil, statusText())
    check("missing: a yellow name in the list", row("Coil") and row("Coil").severity == "warning")

    -- The action bars: the buttons turn yellow, the tooltip says why.
    local saved2, saved100 = actions[2], actions[100]
    actions[2] = { "macro", 6789, "spell", text = "Coil" }
    actions[100] = { "macro", 6789, "spell", text = "Coil" }
    startButton.action, labButton.action = 2, 100
    Send("UPDATE_MACROS")
    local function Tinted(b, color)
        for _, o in ipairs(created) do
            if o.kind == "Texture" and o.parentFrame == b and o.color == color then return o:IsShown() end
        end
        return false
    end
    check("missing: the button turns yellow", Tinted(startButton, "ffd100"))
    check("missing: on LibActionButton's too", Tinted(labButton, "ffd100"))
    local tip, colors = {}, {}
    GameTooltip.AddLine = function(_, text, r, g, b)
        tip[#tip + 1] = text
        colors[text] = string.format("%.2f %.2f %.2f", r or 1, g or 1, b or 1)
    end
    local function Tip(owner, slot)
        tip = {}
        GameTooltip:SetOwner(owner)
        GameTooltip:SetAction(slot)
        return table.concat(tip, " / ")
    end
    local line = "\"Death Coil\": a talent you haven't chosen, the macro can't use it now"
    check("missing: the tooltip says why", Tip(startButton, 2) == "  / " .. line .. " / " .. ns.ActionBars.TIP,
        Tip(startButton, 2))
    check("missing: in yellow", colors[line] == "1.00 0.82 0.00", colors[line])
    check("missing: on LibActionButton's tooltip too", Tip(labButton, 100) == "  / " .. line .. " / "
        .. ns.ActionBars.TIP, Tip(labButton, 100))
    local laidOut
    GameTooltip.Show = function() laidOut = true end
    check("missing: the tooltip line alone, laid out", Tip(New("Frame"), 2) == "  / " .. line and laidOut)
    GameTooltip.Show = nil
    -- Other issues don't tint: a typo shows in the editor.
    CreateMacro("Typo", 1, "/cast Fierball", false)
    actions[8] = { "macro", 133, "spell", text = "Typo" }
    startButton.action = 8
    Send("UPDATE_MACROS")
    check("missing: not for a typo", not Tinted(startButton, "ffd100") and Tip(startButton, 8) == "  / "
        .. ns.ActionBars.TIP, Tip(startButton, 8))
    startButton.action, actions[8] = 2, nil
    DeleteMacro(GetMacroIndexByName("Typo"))
    Send("UPDATE_MACROS")
    -- LibActionButton's buttons made later, and each change of their action.
    local made = ActionButton(0, { type = "action", action = 7 })
    made.action = 7
    actions[7] = { "macro", 6789, "spell", text = "Coil" }
    lab.OnButtonCreated("OnButtonCreated", made)
    NextFrame()
    check("missing: LibActionButton's buttons made later", Tinted(made, "ffd100"))
    actions[7] = { "spell", 6789 }
    lab.OnButtonUpdate("OnButtonUpdate", made)
    check("missing: they follow their action", not Tinted(made, "ffd100"))
    actions[7] = nil
    -- On a Mac, a macOS shortcut on the button's key is worse: red.
    local coil = GetMacroIndexByName("Coil")
    EditMacro(coil, "Coil", 1, "/cast [mod:cmd] Death Coil")
    bindings.ACTIONBUTTON2 = "Q"
    Send("UPDATE_BINDINGS")
    labButton.action = 2 -- its key is not that of the game's bar
    Send("UPDATE_BINDINGS")
    check("missing: red wins", Tinted(startButton, "ff0000") and not Tinted(startButton, "ffd100"))
    check("missing: LibActionButton's stays yellow", Tinted(labButton, "ffd100") and not Tinted(labButton, "ff0000"))
    labButton.action = 100
    bindings.ACTIONBUTTON2 = nil
    EditMacro(coil, "Coil", 1, "/cast Death Coil")
    Send("UPDATE_MACROS")
    check("missing: yellow again", Tinted(startButton, "ffd100") and not Tinted(startButton, "ff0000"))

    -- The talent chosen: the warnings go, a moment after the game says.
    nodes[1].activeRank, nodes[1].activeEntry = 1, { entryID = 11 }
    Send("TRAIT_CONFIG_UPDATED")
    check("missing: not before the game is done", Tinted(startButton, "ffd100"))
    Wait(0.6)
    check("missing: chosen, the tint goes", not Tinted(startButton, "ffd100") and not Tinted(labButton, "ffd100"))
    check("missing: and the tooltip line", Tip(startButton, 2) == "  / " .. ns.ActionBars.TIP, Tip(startButton, 2))
    check("missing: and the status bar", statusText() == "", statusText())
    check("missing: and the list", row("Coil") and row("Coil").severity == nil)
    local talentEvents, refused = false, false
    for _, o in ipairs(created) do
        talentEvents = talentEvents or (o.events and o.events.TRAIT_CONFIG_UPDATED and o.events.PLAYER_TALENT_UPDATE)
        refused = refused or (o.events and o.events.CHARACTER_POINTS_CHANGED)
    end
    check("missing: the talent events this client has", talentEvents and not refused)
    -- The talent dropped again: the macro on the bars it broke is told, once.
    local seen, said = #onScreen, #printed
    nodes[1].activeRank, nodes[1].activeEntry = 0, nil
    Send("TRAIT_CONFIG_UPDATED")
    Wait(0.6)
    check("broken: told on the screen, in yellow", #onScreen == seen + 1 and onScreen[#onScreen].text
        == "MacroSense: 1 macro on your bars uses a spell you don't have now" and onScreen[#onScreen].g == 0.82,
        onScreen[#onScreen] and onScreen[#onScreen].text)
    check("broken: and which, in chat", #printed == said + 1
        and printed[#printed]:find("on your bars, with spells you don't have now: Coil", 1, true) ~= nil,
        printed[#printed])
    Send("TRAIT_CONFIG_UPDATED")
    Wait(0.6)
    check("broken: once", #onScreen == seen + 1, #onScreen - seen)
    -- Chosen and dropped with no talent event (a spell learned, say): nothing told.
    nodes[1].activeRank, nodes[1].activeEntry = 1, { entryID = 11 }
    Send("TRAIT_CONFIG_UPDATED")
    Wait(0.6)
    nodes[1].activeRank, nodes[1].activeEntry = 0, nil
    Send("SPELLS_CHANGED")
    Wait(0.6)
    check("broken: not without a talent change", #onScreen == seen + 1, #onScreen - seen)
    -- A new session: its first look only learns, and so do its first seconds.
    local function fresh()
        local copy = setmetatable({}, { __index = ns })
        assert(loadfile("MacroSense/ActionBars.lua"))("MacroSense", copy)
        return copy.ActionBars
    end
    local session = fresh()
    Wait(11)
    session.TellBroken(true)
    check("broken: a session's first look tells nothing", #onScreen == seen + 1, #onScreen - seen)
    session = fresh()
    session.TellBroken(true)
    nodes[1].activeRank, nodes[1].activeEntry = 1, { entryID = 11 }
    ns.InvalidateSources("spells")
    session.Tint()
    session.TellBroken(true)
    nodes[1].activeRank, nodes[1].activeEntry = 0, nil
    ns.InvalidateSources("spells")
    session.Tint()
    session.TellBroken(true)
    check("broken: nor its first seconds", #onScreen == seen + 1, #onScreen - seen)
    Wait(11)
    nodes[1].activeRank, nodes[1].activeEntry = 1, { entryID = 11 }
    ns.InvalidateSources("spells")
    session.Tint()
    session.TellBroken(true)
    nodes[1].activeRank, nodes[1].activeEntry = 0, nil
    ns.InvalidateSources("spells")
    session.Tint()
    session.TellBroken(true)
    check("broken: then told", #onScreen == seen + 2, #onScreen - seen)

    GameTooltip.AddLine = nil
    actions[2], actions[100] = saved2, saved100
    startButton.action, labButton.action = nil, nil
    DeleteMacro(coil)
    Send("UPDATE_MACROS")
    C_SpellBook, C_ClassTalents, C_Traits = retail, nil, nil
    gameSpells[70001], gameSpells[70002], gameSpells[70003], gameSpells[686] = nil, nil, nil, nil
    ns.InvalidateSources("spells")
end

-- Spells you don't have now (Classic): Mists of Pandaria has a tab for each other specialization and the spells
-- learned later in the book; talents are points (Classic Era, TBC) or one talent of each row (Mists of Pandaria).
do
    local retail = C_SpellBook
    C_SpellBook = { HasPetSpells = function() return nil end }
    local tabs = { { "General", 0, 0, 1, false, 0 }, { "Frost", 0, 1, 2, false, 0 }, { "Fire", 0, 3, 1, false, 63 } }
    local slots = { { "SPELL", 1, "Frostbolt", "" }, { "SPELL", 2, "Frost Nova", "" }, { "FUTURESPELL", 30451, "Ice Lance" },
        { "SPELL", 3, "Pyroblast", "" } }
    GetNumSpellTabs = function() return #tabs end
    GetSpellTabInfo = function(i) return table.unpack(tabs[i]) end
    GetSpellBookItemInfo = function(slot) return slots[slot][1], slots[slot][2] end
    GetSpellBookItemName = function(slot) return slots[slot][3], slots[slot][4] end
    GetSpellBookItemTexture = function() return 1 end
    IsPassiveSpell = function() return false end
    local function issue(text)
        ns.InvalidateSources("spells")
        local e = ns.Highlight.Errors(text)[1]
        return e and (e.short .. (e.missing and " (missing)" or "")) or ""
    end
    check("classic missing: another specialization's tab", issue("/cast Pyroblast") == "Fire only (missing)",
        issue("/cast Pyroblast"))
    check("classic missing: learned later", issue("/cast Ice Lance") == "not learned yet (missing)",
        issue("/cast Ice Lance"))
    check("classic missing: with no level", ns.Highlight.Errors("/cast Ice Lance")[1].message
        == "\"Ice Lance\": you haven't learned it yet")
    check("classic missing: yours", issue("/cast Frost Nova") == "", issue("/cast Frost Nova"))
    -- Classic Era and TBC: a talent with no points is not chosen.
    LE_EXPANSION_LEVEL_CURRENT = 0
    GetNumTalentTabs, GetNumTalents = function() return 1 end, function() return 3 end
    local queries = {}
    talentInfo = function(q)
        queries[#queries + 1] = q
        if q.specializationIndex == 1 and q.talentIndex == 1 then return { name = "Ice Barrier", rank = 0, spellID = 0 } end
        if q.specializationIndex == 1 and q.talentIndex == 2 then return { name = "Cold Snap", rank = 1, spellID = 0 } end
        if q.specializationIndex == 1 and q.talentIndex == 3 then return { name = "Frost Coil", rank = 0, spellID = 6789 } end
    end
    check("classic missing: a talent with no points", issue("/cast Ice Barrier") == "talent not chosen (missing)",
        issue("/cast Ice Barrier"))
    check("classic missing: one with points", issue("/cast Cold Snap") == "", issue("/cast Cold Snap"))
    check("classic missing: by its spell's name", issue("/cast Death Coil") == "talent not chosen (missing)",
        issue("/cast Death Coil"))
    check("classic missing: the active talents", queries[1] and queries[1].groupIndex == 1)
    -- Mists of Pandaria: one talent of each row.
    LE_EXPANSION_LEVEL_CURRENT = 4
    talentInfo = function(q)
        if q.tier ~= 1 then return nil end
        return ({ { name = "Presence of Mind", selected = true, spellID = 0 },
            { name = "Blazing Speed", selected = false, spellID = 0 },
            { name = "Ice Floes", selected = false, spellID = 0 } })[q.column]
    end
    check("classic missing: a talent of a row not chosen", issue("/cast Blazing Speed") == "talent not chosen (missing)",
        issue("/cast Blazing Speed"))
    check("classic missing: the one chosen", issue("/cast Presence of Mind") == "", issue("/cast Presence of Mind"))
    -- Talents the client can't give cost only the talents, once reported.
    local errors = #reported
    talentInfo = function() error("no talents here") end
    check("classic missing: the rest without talents", issue("/cast Pyroblast") == "Fire only (missing)")
    issue("/cast Pyroblast")
    check("classic missing: reported once", #reported == errors + 1, #reported - errors)
    talentInfo, LE_EXPANSION_LEVEL_CURRENT, GetNumTalentTabs, GetNumTalents = nil, nil, nil, nil
    C_SpellBook, GetNumSpellTabs, GetSpellTabInfo, GetSpellBookItemInfo = retail, nil, nil, nil
    GetSpellBookItemName, GetSpellBookItemTexture, IsPassiveSpell = nil, nil, nil
    ns.InvalidateSources("spells")
end

-- Where macros are on the action bars: the bars now, those of your other specializations and, for general macros,
-- of your other characters, as last seen. The list can show only the macros on no bar; deleting one says where it
-- is; a macro moves into the other tab with its buttons, its history and no trip to the trash.
do
    if not MacroSenseFrame:IsShown() then ns.Window.Toggle() end
    local Spec = C_SpecializationInfo
    local talents, spec = C_ClassTalents, 1
    C_ClassTalents = { GetActiveConfigID = function() return nil end } -- Retail: bars for each specialization
    Spec.GetSpecialization = function() return spec end
    Spec.GetSpecializationInfo = function(i) return ({ 265, 266 })[i], ({ "Affliction", "Demonology" })[i] end
    ns.Character().bars = {}
    for _, name in ipairs({ "Bar A", "Bar B", "Loose", "Twin" }) do CreateMacro(name, 1, "/cast Fear", false) end
    CreateMacro("Char C", 1, "/cast Fear", true)
    CreateMacro("Twin", 1, "/cast Fireball", true)
    Send("UPDATE_MACROS")
    local function bars(list) -- slot -> macro name
        for slot = 30, 34 do actions[slot] = list[slot] and { "macro", 0, nil, text = list[slot] } or nil end
        Send("ACTIONBAR_SLOT_CHANGED", 0)
        Wait(1.1)
    end
    bars({ [30] = "Bar A", [31] = "Bar A", [32] = "Char C" })
    -- An equipment set on a bar shows its name too: no macro.
    actions[33] = { "equipmentset", 0, nil, text = "Loose" }
    Send("ACTIONBAR_SLOT_CHANGED", 33)
    Wait(1.1)
    local function uses(scope, name)
        local here, elsewhere = ns.ActionBars.Uses(scope, name)
        return here .. " " .. table.concat(elsewhere, ", ")
    end
    check("bars: the buttons now", uses("general", "Bar A") == "2 " and uses("character", "Char C") == "1 ",
        uses("general", "Bar A"))
    check("bars: only macros", uses("general", "Loose") == "0 ", uses("general", "Loose"))
    actions[33] = nil
    check("bars: kept for the specialization", ns.Character().bars.spec265.names["Bar A"] == 2
        and ns.Character().bars.spec265.label == "Affliction")
    spec = 2
    bars({ [30] = "Bar B" })
    check("bars: another specialization's, as last seen", uses("general", "Bar A") == "0 Affliction"
        and uses("character", "Char C") == "0 Affliction" and uses("general", "Bar B") == "1 ", uses("general", "Bar A"))
    ns.db.characters["Alt-Realm"] = { name = "Alt", realm = "Realm", class = "MAGE",
        bars = { spec62 = { label = "Arcane", names = { Loose = 1, ["Char C"] = 1 } },
            spec63 = { label = "Fire", names = { Loose = 1 } } } }
    ns.db.characters["Far-Other"] = { name = "Far", realm = "Other", bars = { group1 = { label = "Specialization 1",
        names = { Loose = 1 } } } }
    check("bars: a general macro on other characters' bars, each once", uses("general", "Loose") == "0 Alt, Far-Other",
        uses("general", "Loose"))
    for _, name in ipairs({ "Zed", "Mid", "Bob", "Kay" }) do
        ns.db.characters[name .. "-Realm"] = { name = name, realm = "Realm", bars = { x = { label = "", names = { Twin = 1 } } } }
    end
    check("bars: in order", uses("general", "Twin") == "0 Bob, Kay, Mid, Zed", uses("general", "Twin"))
    for _, name in ipairs({ "Zed", "Mid", "Bob", "Kay" }) do ns.db.characters[name .. "-Realm"] = nil end
    check("bars: a character macro is this character's only", uses("character", "Char C") == "0 Affliction",
        uses("character", "Char C"))
    -- Bars with nothing on them are not kept: the game may not have shown them yet.
    local saved = {}
    for slot, a in pairs(actions) do saved[slot] = a end
    for slot in pairs(saved) do actions[slot] = nil end
    Send("ACTIONBAR_SLOT_CHANGED", 0)
    Wait(1.1)
    check("bars: empty bars are not kept", ns.Character().bars.spec266.names["Bar B"] == 1)
    for slot, a in pairs(saved) do actions[slot] = a end
    Send("ACTIONBAR_SLOT_CHANGED", 0)
    Wait(1.1)

    -- The list: the tooltip says where, the filter keeps the macros on no bar.
    ns.Window.SetScope("general")
    NextFrame()
    local function row(name)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.alert and o.text and o.text.text == name and o:IsShown() then return o end
        end
    end
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    local function hover(name)
        tip = {}
        Fire(row(name), "OnEnter")
        return table.concat(tip, " / ")
    end
    check("bars: the tooltip, on the bars now", hover("Bar B") == "Bar B / On 1 button of your action bars", hover("Bar B"))
    check("bars: and elsewhere", hover("Bar A") == "Bar A / Not on your action bars now / On the bars of Affliction",
        hover("Bar A"))
    check("bars: a general one on other characters' bars", hover("Loose")
        == "Loose / Not on your action bars now / On the bars of Alt, Far-Other", hover("Loose"))
    GameTooltip.AddLine = nil
    local filter
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Not on action bars" then filter = o end
    end
    CreateMacro("Unused One", 1, "/cast Fear", false)
    Send("UPDATE_MACROS")
    Fire(filter, "OnClick")
    check("bars: the filter keeps the macros on no bar", row("Unused One") and not row("Bar A") and not row("Bar B")
        and not row("Loose"))
    local general = 0
    for index = 1, select(1, GetNumMacros()) do
        local name = GetMacroInfo(index)
        local here, elsewhere = ns.ActionBars.Uses("general", name)
        if here == 0 and #elsewhere == 0 then general = general + 1 end
    end
    local tabLabel
    for _, o in ipairs(created) do
        if o.kind == "FontString" and tostring(o.text):find("^General  %(") then tabLabel = o.text end
    end
    check("bars: the General tab says how many", tabLabel == string.format("General  (%d)", general), tabLabel)
    bars({ [30] = "Bar B", [33] = "Unused One" })
    check("bars: the list follows the bars", not row("Unused One"))
    -- A tab with every macro on some bar: the list says nothing matches.
    local noMatch
    for _, o in ipairs(created) do
        if o.kind == "FontString" and o.text == "No macros match" then noMatch = o end
    end
    local all = {}
    for index = SLOTS.MAX_ACCOUNT_MACROS + 1, SLOTS.MAX_ACCOUNT_MACROS + select(2, GetNumMacros()) do
        all[GetMacroInfo(index)] = 1
    end
    ns.Character().bars.spec999 = { label = "Other", names = all }
    ns.Window.SetScope("character")
    NextFrame()
    check("bars: nothing matches", noMatch:IsShown())
    ns.Character().bars.spec999 = nil
    ns.Window.SetScope("general")
    NextFrame()
    MacroSenseFrame:Hide()
    MacroSenseFrame:Show()
    check("bars: the filter is off when the editor opens again", row("Bar A") and row("Unused One")
        and not filter.fill:IsShown())
    bars({ [30] = "Bar B" })

    -- Deleting one says where it is.
    local asked, data, which
    local show = StaticPopup_Show
    StaticPopup_Show = function(w, a1, a2, d)
        which, data = w, d
        asked = string.format(StaticPopupDialogs[w].text, a1 or "", a2 or "")
    end
    Fire(row("Bar B").remove, "OnClick")
    check("bars: deleting one on the bars", asked == "Delete macro \"Bar B\"?\n\nIt is on 1 button of your action bars.",
        asked)
    Fire(row("Bar A").remove, "OnClick")
    check("bars: deleting one on other bars", asked == "Delete macro \"Bar A\"?\n\nIt is on the bars of Affliction.",
        asked)
    bars({ [30] = "Bar B", [31] = "Bar A" })
    Fire(row("Bar A").remove, "OnClick")
    check("bars: on both", asked == "Delete macro \"Bar A\"?\n\nIt is on 1 button of your action bars. It is on the "
        .. "bars of Affliction too.", asked)
    Fire(row("Unused One").remove, "OnClick")
    check("bars: on none", asked == "Delete macro \"Unused One\"?", asked)
    StaticPopup_Show = show

    -- Moving one: into the other tab, back on its buttons, with its history, not into the trash.
    local function menuItem(label)
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() and ns.Highlight.Strip(r.text.text):sub(1, #label) == label then return r end
        end
    end
    bars({ [30] = "Bar B", [31] = "Loose", [32] = "Bar B" })
    ns.History.Store("general")["Bar B"] = { { body = "/cast Fireball", time = 5 } }
    local trashed = #ns.History.Trash("general")
    local placed, place, dialogs = {}, PlaceAction, 0
    PlaceAction = function(slot)
        placed[#placed + 1] = slot
        place(slot)
    end
    StaticPopup_Show = function(w, ...)
        if w:find("^MACROSENSE_MOVE") then dialogs = dialogs + 1 end
        return show(w, ...)
    end
    Fire(row("Bar B").copy, "OnClick")
    Fire(menuItem("Move to Character"), "OnClick")
    NextFrame()
    PlaceAction, StaticPopup_Show = place, show
    check("move: not asked when no bars lose it", dialogs == 0, dialogs)
    check("move: put on its buttons, the others left alone", table.concat(placed, ",") == "30,32"
        and actions[31].text == "Loose", table.concat(placed, ","))
    local moved = GetMacroIndexByName("Bar B")
    check("move: into the other tab", moved > SLOTS.MAX_ACCOUNT_MACROS and ns.db.scope == "character", moved)
    check("move: gone from this one", select(1, GetNumMacros()) > 0 and not (function()
        for index = 1, select(1, GetNumMacros()) do if GetMacroInfo(index) == "Bar B" then return true end end
    end)())
    check("move: back on its buttons", actions[30] and actions[30].text == "Bar B" and actions[32].text == "Bar B"
        and picked == nil)
    check("move: its history along", ns.History.Store("character")["Bar B"] and ns.History.Store("general")["Bar B"] == nil)
    check("move: not into the trash", #ns.History.Trash("general") == trashed, #ns.History.Trash("general"))
    check("move: opened there", raw() == "/cast Fear")
    -- A name the other tab has: a free one.
    ns.Window.SetScope("general")
    NextFrame()
    Fire(row("Twin").copy, "OnClick")
    Fire(menuItem("Move to Character"), "OnClick")
    NextFrame()
    check("move: a free name when that tab has it", GetMacroIndexByName("Twin 2") > SLOTS.MAX_ACCOUNT_MACROS)
    -- On the bars of another specialization: asked first, those lose it.
    ns.Window.SetScope("general")
    NextFrame()
    StaticPopup_Show = function(w, a1, a2, d)
        which, data = w, d
        asked = string.format(StaticPopupDialogs[w].text, a1 or "", a2 or "")
    end
    Fire(row("Bar A").copy, "OnClick")
    Fire(menuItem("Move to Character"), "OnClick")
    check("move: asked when other bars lose it", which == "MACROSENSE_MOVE_CHARACTER" and asked == "Move \"Bar A\" to "
        .. "the Character tab?\n\nIt will be gone from the bars of Affliction.", asked)
    StaticPopup_Show = show
    -- The macros may have moved while it asked: found by its name.
    CreateMacro("AAA First", 1, "/cast Fear", false)
    Send("UPDATE_MACROS")
    StaticPopupDialogs[which].OnAccept(nil, data)
    NextFrame()
    check("move: then moved", GetMacroIndexByName("Bar A") > SLOTS.MAX_ACCOUNT_MACROS
        and GetMacroIndexByName("AAA First") <= SLOTS.MAX_ACCOUNT_MACROS)
    -- No free slot in the other tab: nothing moves.
    local fillers = {}
    while select(2, GetNumMacros()) < SLOTS.MAX_CHARACTER_MACROS do
        fillers[#fillers + 1] = "Filler " .. #fillers
        CreateMacro(fillers[#fillers], 1, "", true)
    end
    Send("UPDATE_MACROS")
    ns.Window.SetScope("general")
    NextFrame()
    Fire(row("Loose").copy, "OnClick")
    local full = menuItem("Move to Character")
    check("move: the full tab says so", full and full.text.text:find("(full)", 1, true) ~= nil)
    MacroSenseMenu:Hide()
    ns.Window.Move(GetMacroIndexByName("Loose"))
    check("move: not into a full tab", GetMacroIndexByName("Loose") <= SLOTS.MAX_ACCOUNT_MACROS
        and printed[#printed]:find("no free character macro slots", 1, true) ~= nil, printed[#printed])
    for _, name in ipairs(fillers) do DeleteMacro(GetMacroIndexByName(name)) end
    Send("UPDATE_MACROS")
    ns.Window.SetScope("character")
    NextFrame()
    Fire(row("Bar A").copy, "OnClick")
    check("move: back into General from Character", menuItem("Move to General") ~= nil)
    MacroSenseMenu:Hide()
    InCombatLockdown = function() return true end
    ns.Window.Move(GetMacroIndexByName("Bar A"))
    InCombatLockdown = function() return false end
    check("move: not in combat", GetMacroIndexByName("Bar A") > SLOTS.MAX_ACCOUNT_MACROS
        and printed[#printed]:find("cannot be changed in combat", 1, true) ~= nil)

    -- The Classic clients keep bars for each talent group, whatever specialization it has.
    C_ClassTalents = nil
    spec = 1
    bars({ [30] = "Loose" })
    spec = 2
    bars({ [30] = "Loose", [31] = "Twin" })
    local groups = {}
    for key in pairs(ns.Character().bars) do if key:find("^group") then groups[#groups + 1] = key end end
    check("bars: Classic, by talent group", #groups == 1 and ns.Character().bars.group1.names.Twin == 1
        and ns.Character().bars.group1.label == "Demonology", table.concat(groups, ","))
    for _, name in ipairs({ "Bar A", "Bar B", "Loose", "Twin", "Twin 2", "Char C", "Unused One", "AAA First" }) do
        while GetMacroIndexByName(name) > 0 do DeleteMacro(GetMacroIndexByName(name)) end
    end
    for slot = 30, 34 do actions[slot] = nil end
    Send("UPDATE_MACROS")
    ns.db.characters["Alt-Realm"], ns.db.characters["Far-Other"] = nil, nil
    C_ClassTalents, Spec.GetSpecialization, Spec.GetSpecializationInfo = talents, nil, nil
    ns.Window.SetScope("general")
    NextFrame()
end

-- Other characters' macros: kept as they were when you last played each one, shown in the Character tab under their
-- names (your realm first), to copy into this character or General. A search finds them too; a character can be
-- forgotten.
do
    if not MacroSenseFrame:IsShown() then ns.Window.Toggle() end
    ns.Window.SetScope("character")
    NextFrame()
    CreateMacro("Mine Here", 1, "/cast Fear", true)
    Send("UPDATE_MACROS")
    local kept = ns.Character().macros
    check("alts: this character's own macros kept", kept["Mine Here"] and kept["Mine Here"].body == "/cast Fear"
        and ns.Character().seen == clock)
    check("alts: not the general ones", kept[(GetMacroInfo(1))] == nil)
    -- The rows shown, top to bottom: "+ Name" for a character (- when open), "  name" for its macros.
    local function shown()
        local out = {}
        for _, o in ipairs(created) do
            if o.what and o.what ~= "macro" and o.shown then out[#out + 1] = o end
        end
        table.sort(out, function(a, b) return a.point[3] > b.point[3] end)
        local text = {}
        for i, r in ipairs(out) do
            text[i] = r.what == "alt" and ((r.icon.texture or ""):find("Minus") and "- " or "+ ") .. r.alt.label
                or "  " .. r.macro.name
        end
        return table.concat(text, " | "), out
    end
    local function find(label)
        local _, list = shown()
        for _, r in ipairs(list) do
            if (r.what == "alt" and r.alt.label == label) or (r.what == "altMacro" and r.macro.name == label) then return r end
        end
    end
    local hint
    for _, o in ipairs(created) do
        if o.kind == "FontString" and tostring(o.text):find("^Log in with your other characters") then hint = o end
    end
    check("alts: none known yet, a hint says how", hint and hint:IsShown() and shown() == "")
    ns.db.characters["Mage-Realm"] = { name = "Mage", realm = "Realm", class = "MAGE", seen = clock, macros = {
        ["Poly MO"] = { body = "/cast [@mouseover] Polymorph", icon = 6 }, ["Blink Out"] = { body = "/cast Blink", icon = 5 } } }
    ns.db.characters["Rogue-Other"] = { name = "Rogue", realm = "Other", class = "ROGUE", seen = clock,
        macros = { ["Kick F"] = { body = "/cast [@focus] Kick", icon = 7 } } }
    ns.db.characters["Ann-Zed"] = { name = "Ann", realm = "Zed", seen = clock, macros = { Hide = { body = "/cast Vanish" } } }
    ns.db.characters["Empty-Realm"] = { name = "Empty", realm = "Realm", macros = {} }
    RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
    ns.Window.RefreshList()
    check("alts: under their names, your realm first, closed", shown() == "+ Mage | + Ann-Zed | + Rogue-Other"
        and not hint:IsShown(), shown())
    check("alts: in their class color", find("Mage").text.textColor == "40c7eb", find("Mage").text.textColor)
    check("alts: how many each has", find("Mage").text.text:find("2|r", 1, true) ~= nil, find("Mage").text.text)
    Fire(find("Mage"), "OnClick")
    check("alts: a click shows its macros", shown() == "- Mage |   Blink Out |   Poly MO | + Ann-Zed | + Rogue-Other",
        shown())
    check("alts: its macros under its name, dim", find("Blink Out").icon.point[2] == 18
        and find("Blink Out").text.textColor == ns.scheme.dim, find("Blink Out").icon.point[2])
    check("alts: no x on another character's macro", not find("Blink Out").remove:IsShown()
        and find("Blink Out").copy:IsShown() and find("Mage").remove:IsShown() and not find("Mage").copy:IsShown())
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    local function hover(r)
        tip = {}
        Fire(r, "OnEnter")
        return table.concat(tip, " / ")
    end
    check("alts: its text on hover", hover(find("Poly MO")) == "Poly MO / A macro of Mage. Click to copy it. / "
        .. "/cast [@mouseover] Polymorph", hover(find("Poly MO")))
    check("alts: the character's", hover(find("Mage")) == "Mage / Its own macros, as they were when you last played "
        .. "it: Today, " .. date("%H:%M", clock) .. ". Click to show or hide them.", hover(find("Mage")))
    GameTooltip.AddLine = nil
    local function menuItem(label)
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() and ns.Highlight.Strip(r.text.text):sub(1, #label) == label then return r end
        end
    end
    Fire(find("Blink Out"), "OnClick")
    check("alts: a click offers to copy it", menuItem("Copy to Character") and menuItem("Copy to General"))
    Fire(menuItem("Copy to General"), "OnClick")
    NextFrame()
    local copied = GetMacroIndexByName("Blink Out")
    check("alts: copied into General, opened", copied > 0 and copied <= SLOTS.MAX_ACCOUNT_MACROS
        and ns.db.scope == "general" and raw() == "/cast Blink", copied)
    check("alts: the General tab has no other characters", shown() == "", shown())
    ns.Window.SetScope("character")
    NextFrame()
    check("alts: still open in the tab again", shown():find("^%- Mage") ~= nil, shown())
    Fire(find("Blink Out").copy, "OnClick")
    Fire(menuItem("Copy to Character"), "OnClick")
    NextFrame()
    check("alts: copied into this character, under a free name", GetMacroIndexByName("Blink Out 2")
        > SLOTS.MAX_ACCOUNT_MACROS and ns.db.scope == "character")
    -- A search finds them too, and shows those it finds.
    MacroSenseSearch:SetText("kick")
    check("alts: a search finds them", shown() == "- Rogue-Other |   Kick F", shown())
    Fire(MacroSenseSearch, "OnEnterPressed")
    check("alts: Enter opens no character", ns.db.scope == "character" and raw() == "/cast Blink", raw())
    MacroSenseSearch:SetText("")
    -- Only the macros on no bar: not other characters'.
    local filter
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Not on action bars" then filter = o end
    end
    Fire(filter, "OnClick")
    check("alts: not with the filter", shown() == "", shown())
    Fire(filter, "OnClick")
    -- Forgotten: gone, also from the bars counted.
    Fire(find("Rogue-Other").remove, "OnClick")
    check("alts: a character forgotten", ns.db.characters["Rogue-Other"] == nil and not shown():find("Rogue"), shown())
    for _, name in ipairs({ "Mine Here", "Blink Out", "Blink Out 2" }) do
        while GetMacroIndexByName(name) > 0 do DeleteMacro(GetMacroIndexByName(name)) end
    end
    Send("UPDATE_MACROS")
    for _, key in ipairs({ "Mage-Realm", "Ann-Zed", "Empty-Realm" }) do ns.db.characters[key] = nil end
    RAID_CLASS_COLORS = nil
    ns.Window.SetScope("general")
    NextFrame()
end

-- Explained: the mouse over a line's number or note, the tooltip says in plain words what the line does; over the
-- text, or off the editor, it goes.
do
    if not MacroSenseFrame:IsShown() then ns.Window.Toggle() end
    ns.Window.SetScope("general")
    ns.Window.Revert()
    ns.Window.New()
    NextFrame()
    SLASH_TARGET2, SLASH_DISMOUNT1, SLASH_DISMOUNT2 = "/ziel", "/dismount", "/absitzen" -- the client's: German
    ns.Window.Restore("/cast [mod:shift,@focus,harm,nodead] Polymorph; Frostbolt\n/startattack\n"
        .. "/cast [@mouseover,help][] Heal\n/cast [form:1] Maul; [spec:2] Wrath\n/ziel [@focus]\n/absitzen")
    edit:ClearFocus()
    NextFrame()
    NextFrame()
    local scroll = MacroSenseCodeScroll
    local over = true
    scroll.IsMouseOver = function() return over end
    scroll.left, scroll.right, edit.top = 100, 700, 500
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    local function at(x, line) -- the middle of a line's first row
        tip = {}
        cursorX, cursorY = x, 500 - 4 - 14 * (line - 1) - 7
        Wait(0.2)
        return table.concat(tip, " / ")
    end
    check("explained: over a line's number", at(102, 2) == "Line 2 / • starts auto attack", at(102, 2))
    check("explained: by the editor", GameTooltip:GetOwner() == scroll and GameTooltip:IsShown())
    check("explained: every branch", at(695, 1) == "Line 1 / • with Shift held: Polymorph on your focus, if it is an "
        .. "enemy and alive / • otherwise: Frostbolt", at(695, 1))
    check("explained: once while the mouse stays", at(696, 1) == "", at(696, 1))
    check("explained: the next unit tried, under the first", at(102, 3) == "Line 3 / • Heal on the unit under the "
        .. "mouse, if it is a friend /      if not, on your target", at(102, 3))
    -- The game's names of your forms and specializations, and the commands of the client's language.
    GetNumShapeshiftForms, GetShapeshiftFormInfo = function() return 1 end, function() return 1, "Bear Form" end
    GetNumSpecializations = function() return 2 end
    GetSpecializationInfo = function(i) return 100 + i, ({ "Balance", "Feral" })[i], "", 1 end
    check("explained: with the game's names", at(102, 4) == "Line 4 / • in Bear Form: Maul / • otherwise, in "
        .. "specialization Feral: Wrath", at(102, 4))
    check("explained: a command of the client's language", at(102, 5) == "Line 5 / • targets your focus"
        and at(102, 6) == "Line 6 / • gets off your mount", at(102, 6))
    GetNumShapeshiftForms, GetShapeshiftFormInfo, GetNumSpecializations, GetSpecializationInfo = nil, nil, nil, nil
    -- Over the text: the word under the mouse. Letter k of a line is at x = text start + 8 (k - 1).
    local w = math.floor((edit.fontSize or 13) * 0.6 + 0.5)
    local function letter(k) return 100 + 2 * w + 12 + 6 + (k - 1) * w + 2 end
    check("word: a command", at(letter(3), 1) == "/cast / Casts a spell or uses an item by its name. Branches split "
        .. "by \";\" are tried in order: the first whose conditions hold runs.", at(letter(3), 1))
    check("word: a condition", at(letter(9), 1):find("^mod / A modifier key is held") ~= nil, at(letter(9), 1))
    check("word: a value tells of its condition", at(letter(13), 1):find("^mod / ") ~= nil, at(letter(13), 1))
    check("word: @", at(letter(18), 1):find("^@ / On whom the branch acts") ~= nil, at(letter(18), 1))
    check("word: a unit", at(letter(21), 1) == "@focus / A unit you set with /focus: you act on it without "
        .. "targeting it.", at(letter(21), 1))
    check("word: a condition the other way round", at(letter(31), 1) == "nodead / The unit is not dead.",
        at(letter(31), 1))
    check("word: a command of the client's language", at(letter(2), 5):find("^/ziel / Targets a unit") ~= nil,
        at(letter(2), 5))
    local shownSpell
    C_Spell.GetSpellInfo = function(name) return name == "Polymorph" and { spellID = 118 } or nil end
    GameTooltip.SetSpellByID = function(_, id) shownSpell = id end
    at(letter(40), 1)
    check("word: a spell is the game's tooltip of it", shownSpell == 118 and GameTooltip:GetOwner() == scroll,
        shownSpell)
    C_Spell.GetSpellInfo, GameTooltip.SetSpellByID = nil, nil
    at(letter(20), 2)
    check("explained: not past a line's end", not GameTooltip:IsShown())
    -- A wrapped line: the letters of its second row.
    wrapLines = true
    ns.Window.Restore("/cast [@focus" .. string.rep("target", 15) .. "] X")
    NextFrame()
    NextFrame()
    check("word: on a wrapped line's second row", at(letter(3), 1):find("^/cast") ~= nil
        and at(letter(3), 2):find("^@focustarget") ~= nil, at(letter(3), 2))
    wrapLines = false
    ns.Window.Restore("/cast [mod:shift,@focus,harm,nodead] Polymorph; Frostbolt\n/startattack\n"
        .. "/cast [@mouseover,help][] Heal\n/cast [form:1] Maul; [spec:2] Wrath\n/ziel [@focus]\n/absitzen")
    NextFrame()
    NextFrame()
    -- A window above the editor (the wizard, the questions): its own frame is under the mouse, not the text.
    local above = CreateFrame("Frame", nil, UIParent)
    GetMouseFoci = function() return { above } end
    check("word: not through a window above", at(letter(3), 1) == "" and not GameTooltip:IsShown(), at(letter(3), 1))
    check("explained: not through a window above", at(102, 2) == "" and not GameTooltip:IsShown(), at(102, 2))
    GetMouseFoci = function() return { edit } end
    check("word: the text under the mouse", at(letter(3), 1):find("^/cast") ~= nil, at(letter(3), 1))
    GetMouseFoci = nil
    at(102, 2)
    over = false
    at(102, 2)
    check("explained: gone off the editor", not GameTooltip:IsShown())
    over = true
    check("explained: below the last line, nothing", at(102, 7) == "" and not GameTooltip:IsShown(), at(102, 7))
    -- Without the live preview there is no notes column: the line numbers still explain.
    local previewCheck
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Live preview" then previewCheck = o end
    end
    Fire(previewCheck, "OnClick")
    NextFrame()
    NextFrame()
    GameTooltip:Hide()
    check("explained: no notes column without the live preview", at(695, 1) == "" and at(700, 1) == ""
        and not GameTooltip:IsShown() and not ns.db.preview)
    check("explained: the line numbers still", at(102, 1):find("^Line 1 / ") ~= nil, at(102, 1))
    Fire(previewCheck, "OnClick")
    NextFrame()
    check("explained: the live preview's tooltip says how", (function()
        tip = {}
        Fire(previewCheck, "OnEnter")
        return table.concat(tip, " "):find("Point at a line's number or its note", 1, true) ~= nil
    end)())
    GameTooltip.AddLine = nil
    scroll.IsMouseOver = nil
    over = false
    SLASH_TARGET2, SLASH_DISMOUNT1, SLASH_DISMOUNT2 = nil, nil, nil
    ns.Window.Revert()
end

-- Links in chat: a macro linked from the Share menu or with Shift-click while typing; a link in a chat line clickable;
-- a click asks the one who wrote it (addon whispers) and opens the code in the import window; the macros linked
-- here are given to whoever asks, at most once every 2 seconds.
do
    local sent, filters, callbacks, opened, result = {}, {}, {}, nil, 0
    local prefix
    C_ChatInfo = {
        RegisterAddonMessagePrefix = function(p) prefix = p end,
        SendAddonMessage = function(p, text, chatType, target)
            sent[#sent + 1] = table.concat({ p, text, chatType, target }, " ")
            return result
        end,
    }
    local chatEdit = New("EditBox")
    function chatEdit:Insert(t) self.inserted = (self.inserted or "") .. t end
    local typing = false
    ChatFrameUtil = {
        AddMessageEventFilter = function(event, fn) filters[event] = fn end,
        GetActiveWindow = function() return typing and chatEdit or nil end,
        OpenChat = function(text) opened = text end,
    }
    local registered = 0
    EventRegistry = { RegisterCallback = function(_, event, fn, owner)
        registered = registered + 1
        callbacks[event] = function(...) return fn(owner, ...) end
    end }
    GetNormalizedRealmName = function() return "Realm" end
    Send("PLAYER_LOGIN")
    local onLogin = callbacks.SetItemRef ~= nil
    ns.Links.Setup() -- once
    local count = 0
    for _ in pairs(filters) do count = count + 1 end
    check("links: set up on login, once", onLogin and prefix == "MacroSense" and count == 14 and registered == 1, count)

    if not MacroSenseFrame:IsShown() then ns.Window.Toggle() end
    ns.Window.SetScope("general")
    CreateMacro("Link Me", 1, "/cast [@mouseover,harm] Fear", false)
    Send("UPDATE_MACROS")
    ns.Window.Select(GetMacroIndexByName("Link Me"))
    NextFrame()
    local share
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Share" then share = o end
    end
    local function menuItem(label)
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() and ns.Highlight.Strip(r.text.text):sub(1, #label) == label then return r end
        end
    end
    ns.Window.New()
    NextFrame()
    Fire(share, "OnClick")
    check("links: a new macro is saved first", menuItem("Link this macro in chat").item.disabled)
    MacroSenseMenu:Hide()
    ns.Window.Select(GetMacroIndexByName("Link Me"))
    NextFrame()
    Fire(share, "OnClick")
    Fire(menuItem("Link this macro in chat"), "OnClick")
    check("links: into the chat, opened", opened == "[MacroSense: Link Me]", opened)
    local kept = ns.db.links["Link Me"]
    local decoded = kept and ns.Share.Decode(kept.code)
    check("links: its code kept to give", decoded and decoded[1].body == "/cast [@mouseover,harm] Fear")
    -- Shift-click while typing: into the chat input, the editor stays.
    local function row(name)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.what == "macro" and o.name == name and o.shown then return o end
        end
    end
    CreateMacro("Also Me", 1, "/cast Fireball", false)
    Send("UPDATE_MACROS")
    typing = true
    IsShiftKeyDown = function() return true end
    Fire(row("Also Me"), "OnClick")
    IsShiftKeyDown = function() return false end
    check("links: Shift-click while typing", chatEdit.inserted == "[MacroSense: Also Me]" and raw() == "/cast [@mouseover,harm] "
        .. "Fear", chatEdit.inserted)
    typing = false
    opened = nil
    IsShiftKeyDown = function() return true end
    Fire(row("Also Me"), "OnClick")
    check("links: Shift-click with the chat closed opens it with the link, the editor stays",
        opened == "[MacroSense: Also Me]" and raw() == "/cast [@mouseover,harm] Fear", opened)
    ns.db.characters["Pal-Realm"] = { name = "Pal", realm = "Realm", seen = time(),
        macros = { Bubble = { body = "/cast Divine Shield", icon = 9 } } }
    ns.Window.SetScope("character")
    local function altRow(what, label)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.what == what and o.shown
                and (what == "alt" and o.alt.label == label or what == "altMacro" and o.macro.name == label) then
                return o
            end
        end
    end
    IsShiftKeyDown = function() return false end
    Fire(altRow("alt", "Pal"), "OnClick")
    IsShiftKeyDown = function() return true end
    Fire(altRow("altMacro", "Bubble"), "OnClick")
    IsShiftKeyDown = function() return false end
    local alt = ns.db.links.Bubble and ns.Share.Decode(ns.db.links.Bubble.code)
    check("links: an alt's macro too", opened == "[MacroSense: Bubble]" and alt and alt[1].body == "/cast Divine Shield"
        and not (MacroSenseMenu and MacroSenseMenu:IsShown()), opened)
    ns.db.characters["Pal-Realm"] = nil
    ns.Window.SetScope("general")

    -- A chat line: the link clickable, a whisper you sent asks you; hidden lines stay as they are.
    local frameArg = {}
    local function filtered(event, msg, author)
        local discard, text = filters[event](frameArg, event, msg, author, "x")
        return discard, text
    end
    local discard, line = filtered("CHAT_MSG_PARTY", "look [MacroSense: Fear MO]", "Bob-Realm")
    check("links: a line made clickable", discard == false and line:find("|Haddon:MacroSense:Bob-Realm:Fear MO|h", 1, true)
        ~= nil, line)
    _, line = filtered("CHAT_MSG_WHISPER_INFORM", "[MacroSense: Link Me]", "Bob-Realm")
    check("links: one you whispered is yours", line:find("|Haddon:MacroSense:Tester:Link Me|h", 1, true) ~= nil, line)
    check("links: other lines untouched", select(2, filtered("CHAT_MSG_SAY", "hello", "Bob")) == nil)
    local hidden = "[MacroSense: Fear MO] (hidden)"
    secret[hidden] = true
    check("links: a line hidden from addons", select(2, filtered("CHAT_MSG_RAID", hidden, "Bob")) == nil)
    secret[hidden] = nil

    -- A click asks; the parts open the import window.
    local function click(sender, name) callbacks.SetItemRef("addon:MacroSense:" .. sender .. ":" .. name, "", "LeftButton") end
    local function addon(text, sender) Send("CHAT_MSG_ADDON", "MacroSense", text, "WHISPER", sender) end
    click("Bob-Realm", "Fear MO")
    check("links: a click asks", sent[#sent] == "MacroSense Q:Fear MO WHISPER Bob-Realm", sent[#sent])
    check("links: and says so", printed[#printed]:find("asking Bob-Realm for \"Fear MO\"", 1, true) ~= nil)
    local code = ns.Share.Encode({ { scope = "general", name = "Fear MO", icon = 1,
        body = string.rep("/cast [@mouseover,harm,nodead] Fear\n", 6) } })
    local parts = ns.Links.Parts(code)
    check("links: a code in several parts", #parts > 1, #parts)
    for i = 1, #parts - 1 do addon(parts[i], "Bob-Realm") end
    check("links: not before the last part", not (MacroSenseShare and MacroSenseShare:IsShown()))
    addon(parts[#parts], "Bob-Realm")
    local box, info = ns.ShareWindow.Control("box"), ns.ShareWindow.Control("info")
    check("links: the import window with the code", MacroSenseShare:IsShown() and box:GetText() == code
        and info:GetText():find("Fear MO", 1, true) ~= nil, info:GetText())
    local lines = #printed
    Wait(6.1)
    check("links: answered, no word of no answer", #printed == lines, printed[#printed])
    MacroSenseShare:Hide()
    addon(parts[1], "Bob-Realm")
    check("links: an answer nobody asked for", not MacroSenseShare:IsShown())
    -- Your own realm's players come with or without it.
    click("Ann", "Kick")
    check("links: a name without its realm", sent[#sent] == "MacroSense Q:Kick WHISPER Ann", sent[#sent])
    addon(ns.Links.Parts(code)[1], "Ann-Realm")
    for i = 2, #parts do addon(parts[i], "Ann-Realm") end
    check("links: answered with the realm", MacroSenseShare:IsShown())
    MacroSenseShare:Hide()
    click("Bob-Realm", "Gone")
    addon("N:Gone", "Bob-Realm")
    check("links: no longer shared", printed[#printed]:find("Bob-Realm no longer shares \"Gone\"", 1, true) ~= nil,
        printed[#printed])
    click("Cat-Realm", "X")
    Wait(6.1)
    check("links: no answer", printed[#printed]:find("no answer from Cat-Realm", 1, true) ~= nil, printed[#printed])
    -- What the game says when it can't send.
    local before = #sent
    result = 11
    click("Bob-Realm", "Fear MO")
    check("links: blocked in combat in an instance", printed[#printed]:find("blocked now", 1, true) ~= nil)
    result = 12
    click("Bob-Realm", "Fear MO")
    check("links: offline", printed[#printed]:find("Bob-Realm is offline", 1, true) ~= nil)
    result = 3
    click("Bob-Realm", "Fear MO")
    check("links: too many messages", printed[#printed]:find("could not ask Bob-Realm", 1, true) ~= nil)
    result = 0
    addon("A:1/1:" .. code, "Bob-Realm")
    check("links: no answer taken after a failed question", not MacroSenseShare:IsShown() and #sent == before + 3)
    -- Your own link: opened at once, nothing sent.
    before = #sent
    click("Tester", "Link Me")
    check("links: your own", MacroSenseShare:IsShown() and box:GetText() == ns.db.links["Link Me"].code
        and #sent == before)
    MacroSenseShare:Hide()
    click("Tester-Realm", "Nothing")
    check("links: your own no longer shared", printed[#printed]:find("you no longer share \"Nothing\"", 1, true) ~= nil)

    -- Asked for one of yours: the parts, at most once every 2 seconds to one player; one not linked here: no.
    before = #sent
    addon("Q:Link Me", "Dan-Realm")
    check("links: given", sent[before + 1] == "MacroSense A:1/1:" .. ns.db.links["Link Me"].code .. " WHISPER Dan-Realm",
        sent[before + 1])
    addon("Q:Link Me", "Dan-Realm")
    check("links: not again at once", #sent == before + 1, #sent - before)
    Wait(2.1)
    addon("Q:Nope", "Dan-Realm")
    check("links: one not linked here", sent[#sent] == "MacroSense N:Nope WHISPER Dan-Realm", sent[#sent])
    Send("CHAT_MSG_ADDON", "OtherAddon", "Q:Link Me", "WHISPER", "Eve-Realm")
    check("links: other addons' messages", sent[#sent] == "MacroSense N:Nope WHISPER Dan-Realm")
    -- The last 20 linked are kept.
    for i = 1, 22 do
        clock = clock + 1
        ns.Links.Insert({ scope = "general", name = "M" .. i, icon = 1, body = "" })
    end
    local n = 0
    for _ in pairs(ns.db.links) do n = n + 1 end
    check("links: the last 20 kept", n == 20 and ns.db.links.M22 and ns.db.links.M3 and not ns.db.links.M2
        and not ns.db.links["Link Me"], n)

    for _, name in ipairs({ "Link Me", "Also Me" }) do DeleteMacro(GetMacroIndexByName(name)) end
    Send("UPDATE_MACROS")
    C_ChatInfo, ChatFrameUtil, EventRegistry, GetNormalizedRealmName = nil, nil, nil, nil
end

-- Your group's tank and healer: @tank and @heal in what MacroSense shows and saves, their names in the game's macro,
-- written again as the group changes, out of combat. The macro stays editable with its tags; one renamed is
-- followed, one changed outside MacroSense is let go. The history keeps no version of a name written in.
do
    local C = ns.WizardWindow.Control
    local function menuItem(label)
        for _, r in ipairs(MacroSenseMenu.rows) do
            if r:IsShown() and r.text.text == label then return r end
        end
    end
    local function pick(dropdown, label)
        Fire(dropdown, "OnClick")
        Fire(menuItem(label), "OnClick")
    end
    local function answer(label)
        for i = 1, 18 do
            local b = C("answer" .. i)
            if b.shown and b.label.text == label then return b end
        end
    end
    local function TypeIn(box, text)
        box:SetFocus()
        Fire(box, "OnEditFocusGained")
        box.text = text
        Fire(box, "OnTextChanged", true)
    end
    local function body(name) return select(3, GetMacroInfo(GetMacroIndexByName(name))) end
    local function preview() return ns.Highlight.Strip(C("preview").text) end
    -- The group changes: a second later the macros follow, and the game reports the macros changed.
    local function regroup(members, raid)
        group.members, group.raid = members, raid
        Send("GROUP_ROSTER_UPDATE")
        Wait(1.1)
        Send("UPDATE_MACROS")
    end
    local saveBtn, nameBox -- the editor's: its name box is the first one of 16 letters
    for _, o in ipairs(created) do
        if o.kind == "Button" and o.label and o.label.text == "Save" then saveBtn = o end
        if o.kind == "EditBox" and o.maxLetters == 16 and not nameBox then nameBox = o end
    end
    local BOB, CARL = { name = "Bob", realm = "", role = "TANK" }, { name = "Carl", role = "TANK" }
    local ANN, DEE = { name = "Ann", realm = "Other", role = "HEALER" }, { name = "Dee", role = "DAMAGER" }

    if not MacroSenseFrame:IsShown() then ns.Window.Toggle() end
    ns.Window.SetScope("general")
    group.members = { BOB, ANN, DEE }
    ns.db.wizardForm = true
    ns.WizardWindow.Open("general")
    TypeIn(C("cast"), "Flash Heal")
    C("cast"):ClearFocus()
    pick(C("on1"), "Group's tank")
    pick(C("on2"), "Your pet")
    C("name"):SetText("Tank Heal")
    local tagged = "#showtooltip\n/cast [@tank,help,nodead][@pet,help,nodead] Flash Heal"
    local function named(tank) return (tagged:gsub("@tank", "@" .. tank)) end
    check("roles: the wizard writes @tank", preview() == tagged, preview())
    Fire(C("create"), "OnClick")
    local kept = ns.db.roleMacros["Tank Heal"]
    check("roles: the game's macro has the name, the editor @tank", body("Tank Heal") == named("Bob") and kept
        and kept.text == tagged and kept.written == named("Bob") and raw() == tagged, body("Tank Heal"))

    -- The game tells UPDATE_MACROS while EditMacro runs: the editor still shows @tank, and no version is kept.
    local editMacro = EditMacro
    EditMacro = function(...)
        local index = editMacro(...)
        Send("UPDATE_MACROS")
        return index
    end
    regroup({ ANN, DEE })
    check("roles: told at once that the macro changed, the editor keeps @tank", body("Tank Heal") == named("none")
        and raw() == tagged and not saveBtn:IsEnabled()
        and #ns.History.Versions(ns.History.Store("general"), "Tank Heal", named("Bob")) == 0, raw())
    regroup({ BOB, ANN, DEE })
    EditMacro = editMacro

    local seen = #onScreen
    regroup({ CARL, ANN, DEE })
    local said = onScreen[seen + 1]
    check("roles: the new tank told on the screen, in red, once", #onScreen == seen + 1 and said
        and said.text == "MacroSense: your group's new tank is Carl" and said.r == 1 and said.g < 0.2, said and said.text)
    seen = #onScreen
    regroup({ CARL, ANN })
    check("roles: the same tank and healer: nothing told", #onScreen == seen)
    regroup({ CARL, { name = "Fay", role = "HEALER" } })
    check("roles: a new healer no macro has: nothing told", #onScreen == seen, onScreen[#onScreen].text)
    regroup({ CARL })
    regroup({ BOB })
    check("roles: no tank, then one: only the new one told", #onScreen == seen + 1
        and onScreen[#onScreen].text:find("is Bob$") ~= nil, onScreen[#onScreen].text)
    ns.SetLanguage("uk")
    regroup({ CARL })
    check("roles: told in the addon's language", onScreen[#onScreen].text == "MacroSense: новий танк групи — Carl",
        onScreen[#onScreen].text)
    ns.SetLanguage("en")
    -- A new session (a /reload) in a group: its tank isn't new.
    for _, o in ipairs(created) do
        if o.events and o.events.GROUP_ROSTER_UPDATE and o.events.PLAYER_ROLES_ASSIGNED then
            o:SetScript("OnEvent", nil)
        end
    end
    assert(loadfile("MacroSense/Roles.lua"))("MacroSense", ns)
    seen = #onScreen
    regroup({ CARL })
    check("roles: the first look of a session tells nothing", #onScreen == seen, onScreen[#onScreen].text)
    regroup({ BOB })
    check("roles: and after it a new one is told", #onScreen == seen + 1, #onScreen - seen)
    regroup({ CARL, ANN, DEE })
    check("roles: the new tank written in", body("Tank Heal") == named("Carl") and kept.written == named("Carl"),
        body("Tank Heal"))
    check("roles: the editor still shows @tank, nothing to save, no version kept", raw() == tagged
        and not saveBtn:IsEnabled() and #ns.History.Versions(ns.History.Store("general"), "Tank Heal", tagged) == 0
        and #ns.History.Versions(ns.History.Store("general"), "Tank Heal", named("Carl")) == 0, raw())
    edit:SetCursorPosition(#edit.text)
    Send("UPDATE_MACROS")
    check("roles: the editor loads it again only when it changed", edit:GetCursorPosition() == #edit.text)
    local events
    for _, o in ipairs(created) do
        if o.events and o.events.GROUP_ROSTER_UPDATE then events = o.events end
    end
    check("roles: told of the group, its roles, a new zone and the end of combat", events
        and events.PLAYER_ROLES_ASSIGNED and events.PLAYER_ENTERING_WORLD and events.PLAYER_REGEN_ENABLED)

    -- The live preview runs it as the game would: on the tank by name.
    game.units.carl = {}
    ns.Window.Restore("/cast [@tank,help] Flash Heal")
    Wait(0.2)
    local note
    for _, o in ipairs(created) do
        if o.isNote and o:IsShown() then note = ns.Highlight.Strip(o.text) end
    end
    check("roles: the preview casts on the tank", note ~= nil and note:find("Carl", 1, true) ~= nil, note)
    game.units.bob = {}
    group.members = { BOB, DEE }
    Send("GROUP_ROSTER_UPDATE")
    Wait(1.1)
    for _, o in ipairs(created) do
        if o.isNote and o:IsShown() then note = ns.Highlight.Strip(o.text) end
    end
    check("roles: and follows the group", note ~= nil and note:find("Bob", 1, true) ~= nil, note)
    group.members = { CARL, ANN, DEE }
    Send("GROUP_ROSTER_UPDATE")
    Wait(1.1)
    game.units.carl, game.units.bob = nil, nil

    -- With the names written in, too long to save: as it was.
    group.members = { { name = string.rep("B", 250), role = "TANK" } }
    ns.Window.Restore(tagged .. "\n/say x")
    local said = #printed
    ns.Window.Save()
    check("roles: too long with the names: not saved", body("Tank Heal") == named("Carl") and #printed == said + 1
        and printed[#printed]:find("macro is longer than 255 characters", 1, true) ~= nil, printed[#printed])
    group.members = { CARL, ANN, DEE }

    -- Edited with its tags and saved: it stays up to date.
    ns.Window.Restore(tagged .. "\n/say Healing %t")
    ns.Window.Save()
    check("roles: edited, the game's macro has the name", body("Tank Heal") == named("Carl") .. "\n/say Healing %t"
        and ns.db.roleMacros["Tank Heal"].text == tagged .. "\n/say Healing %t", body("Tank Heal"))
    regroup({ BOB, DEE })
    check("roles: and is still kept up to date", body("Tank Heal") == named("Bob") .. "\n/say Healing %t"
        and raw() == tagged .. "\n/say Healing %t", body("Tank Heal"))
    ns.Window.Restore(tagged)
    ns.Window.Save()

    -- What you are typing stays when the name is written in; then the macro gets what you save.
    ns.Window.Restore(tagged .. "\n/sit")
    regroup({ ANN, DEE })
    check("roles: no tank, nobody; what you are typing stays", body("Tank Heal") == named("none")
        and raw() == tagged .. "\n/sit", body("Tank Heal"))
    ns.Window.Revert()

    InCombatLockdown = function() return true end
    regroup({ BOB, DEE })
    local inCombat = body("Tank Heal")
    InCombatLockdown = function() return false end
    Send("PLAYER_REGEN_ENABLED")
    Wait(1.1)
    check("roles: in combat not, after it", inCombat == named("none") and body("Tank Heal") == named("Bob"), inCombat)

    -- Renamed in the editor, renamed elsewhere: followed.
    nameBox:SetText("Heal Tank")
    ns.Window.Save()
    check("roles: renamed in the editor", ns.db.roleMacros["Heal Tank"] ~= nil and ns.db.roleMacros["Tank Heal"] == nil)
    EditMacro(GetMacroIndexByName("Heal Tank"), "Tank Heal")
    Send("UPDATE_MACROS")
    regroup({ CARL, DEE })
    check("roles: renamed elsewhere, followed", body("Tank Heal") == named("Carl")
        and ns.db.roleMacros["Tank Heal"] ~= nil and ns.db.roleMacros["Heal Tank"] == nil, body("Tank Heal"))

    -- A copy keeps the tags.
    ns.Window.Copy("general", GetMacroIndexByName("Tank Heal"))
    check("roles: a copy keeps @tank", raw() == tagged and ns.db.roleMacros["Tank Heal 2"] ~= nil
        and body("Tank Heal 2") == named("Carl"), raw())
    DeleteMacro(GetMacroIndexByName("Tank Heal 2"))
    Send("UPDATE_MACROS")

    -- Changed outside MacroSense: the editor shows it as made there; it stays so, and is let go.
    ns.Window.Select(GetMacroIndexByName("Tank Heal"))
    EditMacro(GetMacroIndexByName("Tank Heal"), nil, nil, named("Carl") .. "\n/sit")
    Send("UPDATE_MACROS")
    check("roles: changed outside, shown as it is", raw() == named("Carl") .. "\n/sit", raw())
    regroup({ BOB, DEE })
    check("roles: changed outside, let go", body("Tank Heal") == named("Carl") .. "\n/sit"
        and ns.db.roleMacros["Tank Heal"] == nil, body("Tank Heal"))
    -- Saved without a tag: nothing to keep.
    ns.Roles.Saved("general", nil, "Plain", "/cast Flash Heal", "/cast Flash Heal")
    check("roles: no tag, nothing kept", ns.db.roleMacros.Plain == nil)

    -- Deleted: let go.
    ns.Roles.Saved("general", nil, "Gone", "/cast [@heal] Flash Heal", "/cast [@Ann-Other] Flash Heal")
    ns.Roles.Update()
    check("roles: deleted, let go", ns.db.roleMacros.Gone == nil)

    -- Two with the same text, one renamed: each followed.
    local twin = "/cast [@tank,exists] Flash Heal"
    for _, name in ipairs({ "Twin A", "Twin B" }) do
        CreateMacro(name, 1, "/cast [@Bob,exists] Flash Heal", false)
        ns.Roles.Saved("general", nil, name, twin, "/cast [@Bob,exists] Flash Heal")
    end
    EditMacro(GetMacroIndexByName("Twin A"), "Twin 0") -- before the other one in the list
    regroup({ CARL })
    check("roles: the same text twice, one renamed", ns.db.roleMacros["Twin B"] ~= nil
        and ns.db.roleMacros["Twin 0"] ~= nil and body("Twin 0") == "/cast [@Carl,exists] Flash Heal", body("Twin 0"))
    for _, name in ipairs({ "Twin B", "Twin 0" }) do DeleteMacro(GetMacroIndexByName(name)) end

    -- Names that would make it too long: it stays, and that is said once.
    local long = { name = string.rep("A", 250), role = "HEALER" }
    local ann = "#showtooltip\n/cast [@Ann-Other,exists,nodead][] Flash Heal"
    CreateMacro("Long", 1, ann, false)
    ns.Roles.Saved("general", nil, "Long", "#showtooltip\n/cast [@heal,exists,nodead][] Flash Heal", ann)
    said, seen = #printed, #onScreen
    regroup({ long })
    regroup({ long, DEE })
    check("roles: too long with the new names: as it was, said once", body("Long") == ann and #printed == said + 1
        and printed[#printed]:find("could not put your group's new names into \"Long\": it would be longer than "
        .. "255 characters", 1, true) ~= nil, printed[#printed])
    check("roles: a name too long to put in: told in red, once", #onScreen == seen + 1
        and onScreen[#onScreen].text == "MacroSense: could not set your group's new healer, " .. long.name
        .. ": the macro would be too long" and onScreen[#onScreen].r == 1, onScreen[#onScreen].text)

    -- Moved into the Character tab: kept up to date there.
    regroup({ ANN })
    ns.Window.Move(GetMacroIndexByName("Long"))
    regroup({ { name = "Eve", role = "HEALER" } })
    check("roles: moved, followed in the other tab", ns.char.roleMacros.Long ~= nil and ns.db.roleMacros.Long == nil
        and body("Long") == "#showtooltip\n/cast [@Eve,exists,nodead][] Flash Heal", body("Long"))
    DeleteMacro(GetMacroIndexByName("Long"))
    DeleteMacro(GetMacroIndexByName("Tank Heal"))
    Send("UPDATE_MACROS")

    -- In a raid: its main tank first; never you; what the game hides from addons is nobody.
    group.raid, group.me = true, "TANK"
    group.members = { { name = "Xan", role = "TANK" }, { name = "Yul", role = "DAMAGER", mainTank = true },
        { name = "Zia", role = "HEALER" } }
    table.insert(group.members, { name = "Wes", role = "TANK", mainTank = true })
    local names = ns.Roles.Names()
    check("roles: a raid's main tank first", names.tank == "Yul" and names.heal == "Zia", names.tank)
    group.members[2].mainTank, group.members[4].mainTank = nil, nil
    check("roles: else the first tank, not you", ns.Roles.Names().tank == "Xan", ns.Roles.Names().tank)
    group.members[1].name = "Unknown"
    check("roles: a name the game doesn't know yet: the next one", ns.Roles.Names().tank == "Wes",
        ns.Roles.Names().tank)
    secret.TANK, secret.Zia = true, true
    names = ns.Roles.Names()
    check("roles: a role or a name the game hides: nobody", names.tank == nil and names.heal == nil, names.tank)
    secret.TANK, secret.Zia, group.me = nil, nil, nil

    -- The editor takes the names in your group for units, as it is now, and knows @tank and @heal.
    regroup({ BOB, ANN })
    check("roles: a name in your group is no unknown unit", #ns.Highlight.Errors("/cast [@Bob][@Ann-Other][@ann] X")
        == 0 and #ns.Highlight.Errors("/cast [@Zed] X") == 1 and #ns.Highlight.Errors("/cast [@tank][@heal] X") == 0)
    regroup({ ANN })
    check("roles: one gone is", #ns.Highlight.Errors("/cast [@Bob] X") == 1)

    -- Step by step: the answers in plain words, the macro's words as their hint.
    ns.db.wizardForm = nil
    ns.WizardWindow.Open("general")
    Fire(answer("Cast a spell"), "OnClick")
    TypeIn(C("stepSpell"), "Flash Heal")
    Fire(C("stepSpell"), "OnEnterPressed")
    Fire(C("next"), "OnClick")
    check("roles: step by step", answer("On your group's tank").hint.text == "@tank"
        and answer("On your group's healer").hint.text == "@heal", C("question").text)
    Fire(answer("On your group's tank"), "OnClick")
    check("roles: and if there is no tank", C("question").text == "And if your group has no tank?"
        and preview() == "#showtooltip\n/cast [@tank,help,nodead][] Flash Heal", preview())
    ns.WizardWindow.Close()
    group.members = {}
    Send("GROUP_ROSTER_UPDATE")
end

-- Theme switch recolors without touching the text.
local body = raw()
ns.db.scheme = "darcula"
ns.Window.ApplyLook()
check("scheme keeps text", raw() == body)
check("darcula colors used", edit:GetText():find("|cffcc7832") ~= nil) -- Darcula keyword

io.write(string.format("%d passed, %d failed\n", passed, failed))
if failed > 0 then for _, p in ipairs(printed) do io.write("  printed: " .. p .. "\n") end end
os.exit(failed == 0 and 0 or 1)
