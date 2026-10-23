-- Loads the whole addon against a tiny fake WoW API and drives the editor like a player would.
-- `lua tests/ui.lua` from the repo root. It catches load errors and logic bugs, not layout.
local now, timers = 0, {} -- timers: { at = time, fn = function }
local created = {} -- every frame, so tests can find anonymous ones (Core's event frame, the editor)
local function NextFrame()
    now = now + 0.016
    local due, later = {}, {}
    for _, t in ipairs(timers) do table.insert(t.at <= now and due or later, t) end
    timers = later
    for _, t in ipairs(due) do t.fn() end
    for _, o in ipairs(created) do
        if o.scripts.OnUpdate and o.shown then o.scripts.OnUpdate(o, 0.016) end
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
function Frame:CreateTexture() return New("Texture") end
function Frame:CreateFontString() return New("FontString") end
function Frame:GetWidth() return 300 end
function Frame:GetHeight() return 200 end
function Frame:GetFrameLevel() return 1 end
function Frame:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function Frame:IsMouseOver() return false end
-- Fonts: a character is 0.6 of the size wide, a row is size + 1 high (size 13: 8 x 14 px).
function Frame:SetFont(_, size) self.fontSize = size; return true end
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
function Frame:SetColorTexture(r, g, b)
    self.color = string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end
function Frame:GetTop() return self.top end
function Frame:GetRight() return self.right end

function CreateFrame(kind, name) return New(kind, name) end
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
C_AddOns = { IsAddOnLoaded = function() return false end, GetAddOnMetadata = function() return "@project-version@" end }
function GetBuildInfo() return "12.1.5", "60000", "Oct 1 2026", 120105 end
C_Timer = { After = function(delay, fn) timers[#timers + 1] = { at = now + delay, fn = fn } end }
local function Wait(seconds)
    local stop = now + seconds
    while now < stop do NextFrame() end
end
function IsControlKeyDown() return false end
function IsShiftKeyDown() return false end
function IsMouseButtonDown() return false end
function InCombatLockdown() return false end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local printed = {}
function print(s) printed[#printed + 1] = s end
UISpecialFrames, StaticPopupDialogs = {}, {}
function StaticPopup_Show(which, _, _, data) StaticPopupDialogs[which].OnAccept(nil, data) end
YES, NO, CANCEL, DELETE = "Yes", "No", "Cancel", "Delete"
MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = 120, 18

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

Enum = { SpellBookSpellBank = { Player = 0, Pet = 1 }, SpellBookItemType = { Spell = 1 } }
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
}
function GetInventoryItemLink() return nil end
local bindings, actions = { ACTIONBUTTON1 = "Q" }, { [1] = { "macro", 1 } }
function GetBindingKey(command) return bindings[command] end
local picked
function PickupMacro(index) picked = index end
function GetActionInfo(slot) if actions[slot] then return actions[slot][1], actions[slot][2] end end
function GetMacroIcons(t) for i = 1, 300 do t[#t + 1] = 1000 + i end end
function GetMacroItemIcons(t) t[#t + 1] = "INV_Sword_01" end
GameTooltip = New("GameTooltip")
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
    if index > MAX_ACCOUNT_MACROS then return sorted(true)[index - MAX_ACCOUNT_MACROS] end
    return sorted(false)[index]
end
local function indexOf(m)
    local list = sorted(m.perChar)
    for i, x in ipairs(list) do if x == m then return m.perChar and i + MAX_ACCOUNT_MACROS or i end end
end
function GetNumMacros() return #sorted(false), #sorted(true) end
function GetMacroInfo(index)
    local m = byIndex(index)
    if m then return m.name, m.icon, m.body end
end
function CreateMacro(name, icon, body, perChar)
    local m = { name = name, icon = icon, body = body, perChar = perChar and true or false }
    macros[#macros + 1] = m
    return indexOf(m)
end
function EditMacro(index, name, icon, body)
    local m = byIndex(index)
    m.name, m.icon, m.body = name, icon, body
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
local function Send(name, ...)
    for _, o in ipairs(created) do Fire(o, "OnEvent", name, ...) end
end
Send("ADDON_LOADED", "MacroSense")
Send("PLAYER_LOGIN")

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
    local visible = 0
    for _, o in ipairs(created) do if o.kind == "Slider" and o.SetRange and o:IsShown() then visible = visible + 1 end end
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
    check("short error in status", statusError():find("Line %d+: unknown condition|r") ~= nil, statusError())
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
    check("warning in status, short", statusText():find("|cff" .. warn .. "Line %d+: unknown unit|r") ~= nil, statusText())
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
            if o.kind == "FontString" and tostring(o.text):find("unknown unit") then return true end
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

-- Our own scroll bar: hidden without overflow, wheel scrolls and clamps, dragging the thumb scrolls.
do
    local scroll = MacroSenseListScroll
    local function bar()
        for _, o in ipairs(created) do if o.kind == "Slider" and o.SetRange and o.max == 100 then return o end end
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
    Fire(b, "OnValueChanged", 30)
    check("dragging thumb scrolls", scroll.vscroll == 30, scroll.vscroll)
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
    ns.Window.Select(1)
    NextFrame()
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast [mod:cmd] Fireball")
    Key("ESCAPE", "OnEscapePressed")
    check("cmd+Q warning shown", warningText():find("Cmd%+Q is a macOS shortcut") ~= nil, warningText())
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
            if o.kind == "Frame" and o.scripts.OnMouseUp and o.scripts.OnEnter and o.scripts.OnLeave then return o end
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
    check("preview follows combat", notes() == "icon: Fireball | Fireball | no match | Frostbolt", notes())
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
    check("preview: no pet, no match", notes() == "icon: ? | no match", notes())
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
    check("list: a warning makes it yellow, no sign", typo and typo.text.textColor == s.warning and not typo.alert:IsShown(),
        typo and typo.text.textColor)
    check("list: a clean macro stays plain", clean and clean.text.textColor == s.text and not clean.alert:IsShown()
        and clean.text.point[2] == clean, clean and clean.text.textColor)
    local tip = {}
    GameTooltip.AddLine = function(_, text) tip[#tip + 1] = text end
    Fire(broken, "OnEnter")
    Fire(clean, "OnEnter")
    GameTooltip.AddLine = nil
    check("list: hover lists the issues", table.concat(tip, "\n") == 'Zap broken\nLine 1: unknown condition "harmm"',
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

-- Copy: a duplicate in the same tab or a copy in the other one, with what the editor shows, under a free name.
do
    local function button(label)
        for _, o in ipairs(created) do
            if o.kind == "Button" and o.label and o.label.text == label then return o end
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
    local function body(name) return select(3, GetMacroInfo(GetMacroIndexByName(name))) end
    local copy = button("Copy")
    CreateMacro("Zap", 1, "/cast Fireball", false)
    Send("UPDATE_MACROS")
    ns.Window.Select(GetMacroIndexByName("Zap"))
    NextFrame()
    check("copy: offered for a saved macro", copy and copy:IsEnabled())
    edit:SetFocus()
    edit:SetCursorPosition(#edit.text)
    Type("\n/cast Frostbolt")
    Key("ESCAPE", "OnEscapePressed")
    Fire(copy, "OnClick")
    check("copy: the menu opens above the button", MacroSenseMenu:IsShown() and MacroSenseMenu.point[1] == "BOTTOMLEFT"
        and MacroSenseMenu.point[2] == copy, MacroSenseMenu.point and MacroSenseMenu.point[1])
    Fire(menuItem("Duplicate"), "OnClick")
    NextFrame()
    check("copy: a duplicate under a free name, with the text shown", GetMacroIndexByName("Zap 2") > 0
        and body("Zap 2") == "/cast Fireball\n/cast Frostbolt", GetMacroIndexByName("Zap 2"))
    check("copy: the macro copied keeps its saved text", body("Zap") == "/cast Fireball", body("Zap"))
    check("copy: the copy is opened", nameText() == "Zap 2" and raw() == "/cast Fireball\n/cast Frostbolt"
        and not saveIsEnabled(), nameText())
    Fire(copy, "OnClick")
    Fire(menuItem("Copy to Character"), "OnClick")
    NextFrame()
    local index = GetMacroIndexByName("Zap 3")
    check("copy: to the other tab, the next free name", index > MAX_ACCOUNT_MACROS and ns.db.scope == "character"
        and nameText() == "Zap 3", index)
    Fire(copy, "OnClick")
    check("copy: from Character, the other tab is General", menuItem("Copy to General") ~= nil)
    Fire(copy, "OnClick")
    -- A full tab can't take one.
    local fillers = MAX_CHARACTER_MACROS - select(2, GetNumMacros())
    for i = 1, fillers do CreateMacro("Filler " .. i, 1, "/sit", true) end
    Send("UPDATE_MACROS")
    ns.Window.SetScope("general")
    ns.Window.Select(GetMacroIndexByName("Zap"))
    NextFrame()
    Fire(copy, "OnClick")
    local full = menuItem("Copy to Character")
    check("copy: a full tab is marked", full and full.item.disabled and full.text.text:find("(full)", 1, true) ~= nil)
    local count = select(2, GetNumMacros())
    Fire(full, "OnClick")
    check("copy: and takes nothing", select(2, GetNumMacros()) == count and MacroSenseMenu:IsShown())
    Fire(copy, "OnClick")
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
    check("copy: not before the macro is saved", not copy:IsEnabled())
    for _, name in ipairs({ "Zap", "Zap 2", "Zap 3", "Сімнадцять літер", "Сімнадцять літ 2" }) do
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

-- Theme switch recolors without touching the text.
local body = raw()
ns.db.scheme = "darcula"
ns.Window.ApplyLook()
check("scheme keeps text", raw() == body)
check("darcula colors used", edit:GetText():find("|cffcc7832") ~= nil) -- Darcula keyword

io.write(string.format("%d passed, %d failed\n", passed, failed))
if failed > 0 then for _, p in ipairs(printed) do io.write("  printed: " .. p .. "\n") end end
os.exit(failed == 0 and 0 or 1)
