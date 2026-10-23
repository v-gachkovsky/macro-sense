-- Loads the whole addon against a tiny fake WoW API and drives the editor like a player would.
-- `lua tests/ui.lua` from the repo root. It catches load errors and logic bugs, not layout.
local now, timers = 0, {}
local created = {} -- every frame, so tests can find anonymous ones (Core's event frame, the editor)
local function NextFrame()
    now = now + 0.016
    local run = timers
    timers = {}
    for _, fn in ipairs(run) do fn() end
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
function Frame:SetFont() return true end
function Frame:GetMaxLetters() return 0 end
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
    if cursorEventsLate then
        timers[#timers + 1] = function() Fire(self, "OnCursorChanged", 0, -line * 14, 2, 14) end
    else
        Fire(self, "OnCursorChanged", 0, -line * 14, 2, 14)
    end
end
-- FontString measuring: 8 px per character, one row, 14 px high.
function Frame:GetUnboundedStringWidth() return #self.text * 8 end
function Frame:GetStringWidth() return #self.text * 8 end
function Frame:GetNumLines() return 1 end
function Frame:GetStringHeight() return 14 end
function Frame:GetFont() return "font", 14, "" end
function Frame:SetPoint(...) self.point = { ... } end

function CreateFrame(kind, name) return New(kind, name) end
UIParent = New("Frame")

------------------------------------------------------------------------
-- Fake game API
------------------------------------------------------------------------
function GetTime() return now end
function IsMacClient() return true end
C_AddOns = { IsAddOnLoaded = function() return false end }
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
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

SlashCmdList, SecureCmdList, ChatTypeInfo = {}, { CAST = true, USE = true, TARGET = true }, { SAY = true }
SLASH_CAST1, SLASH_USE1, SLASH_TARGET1, SLASH_SAY1 = "/cast", "/use", "/target", "/say"
EMOTE1_TOKEN, EMOTE1_CMD1 = "DANCE", "/dance"

Enum = { SpellBookSpellBank = { Player = 0 }, SpellBookItemType = { Spell = 1 } }
local book = { -- name, rank: Classic lists every learned rank
    { "Fireball", "Rank 1" }, { "Fireball", "Rank 2" }, { "Fireball", "Rank 3" },
    { "Fire Blast", "" }, { "Frostbolt", "Rank 1" }, { "Polymorph", "" },
}
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 1 end,
    GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #book } end,
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
    Type("\n/cast [harmm")
    NextFrame()
    check("no error while typing the word", underlines() == 0 and statusError() == "", statusError())
    Key("ESCAPE", "OnEscapePressed")
    Type("] X")
    NextFrame()
    local n = underlines()
    check("error underlined", n == 1, n)
    check("error in status", statusError():find('unknown condition "harmm"') ~= nil, statusError())
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
    -- "bogus" starts after 6 characters of its line: x = inset 6 + 6 chars * 8; y = inset 4 + rows above * 14.
    check("late events: x from text width", tex and tex.point[4] == 6 + 6 * 8, tex and tex.point[4])
    check("late events: y from rows above", tex and tex.point[5] == -4 - line * 14 - 14 + 1, tex and tex.point[5])
    check("late events: cursor stays", rawCursor() == #raw(), rawCursor())
    cursorEventsLate = false
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

-- Unknown commands and conditions are marked; known ones are not.
local function kindOf(text, word)
    for _, sp in ipairs(ns.Highlight.Spans(text)) do
        if text:sub(sp[1], sp[2]) == word then return sp[3] end
    end
end
check("emote is a command", kindOf("/dance", "/dance") == "command")
check("chat is a command", kindOf("/say hi", "/say") == "command")
check("unknown command is an error", kindOf("/bogus", "/bogus") == "error")

-- Theme switch recolors without touching the text.
local body = raw()
ns.db.scheme = "darcula"
ns.Window.ApplyLook()
check("scheme keeps text", raw() == body)
check("darcula colors used", edit:GetText():find("|cffcc7832") ~= nil) -- Darcula keyword

io.write(string.format("%d passed, %d failed\n", passed, failed))
if failed > 0 then for _, p in ipairs(printed) do io.write("  printed: " .. p .. "\n") end end
os.exit(failed == 0 and 0 or 1)
