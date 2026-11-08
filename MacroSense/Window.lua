-- The MacroSense window: macro list on the left, editor on the right. Macros are the game's own
-- (CreateMacro / EditMacro), so everything stays in sync with the Blizzard macro UI.
local _, ns = ...
local L = ns.L

local MAX_GENERAL, MAX_CHARACTER = ns.MAX_GENERAL, ns.MAX_CHARACTER
local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local MAX_NAME = 16 -- letters, as in the Blizzard macro window
local NEW_ICON = 134400 -- question mark: #showtooltip picks the icon
local NEW_BODY = "#showtooltip\n" -- a new macro starts with it, the cursor on the line below
local SORT_ICON = "Interface\\AddOns\\MacroSense\\Media\\sort"
local NO_ICON = "Interface\\AddOns\\MacroSense\\Media\\no" -- dragged where it can't go
local PLUS_ICON = "Interface\\AddOns\\MacroSense\\Media\\plus" -- dragged with Ctrl: a copy
local ROW_H = 24
-- Also the first size. The sidebar is 280 wide; the editor's header needs some 560 more.
local MIN_W, MIN_H = 840, 460
local PREVIEW_EVERY = 0.1 -- seconds: modifiers, target, mouseover and pet change any time

local Window = {}
ns.Window = Window

-- What is being edited: scope "general" | "character", index (nil = new macro), name/body/savedIcon as saved,
-- icon = the icon picked now. With macro sets on, `stored`: one behind the scenes, { id = its set, name } (no name:
-- a new one there). `waiting`: saved in combat, it goes into the game when combat ends (one of `waiting` below).
local state = { scope = "general", icon = NEW_ICON, savedIcon = NEW_ICON }
-- Saved in combat, in the order saved: the game doesn't let macros change then, so they go in when it ends.
-- { scope, index (nil: a new one), old = its name in the game, name, icon, body }.
local waiting = {}
local frame, list, nameBox, iconTex, code, status, dirtyDot, warning, counter, saveBtn, revertBtn, tabs
local side -- the sidebar: wider with macro sets on, for the Character tab's count of those behind the scenes
local sideRows -- its buttons at the bottom, by row: they share its width
local setsCheck, sortBtn -- macro sets on or off; "Sort by spells", with them on
local barInside -- the status bar's part not under the window's border: what it shows is centered in it
local NATIVE_EDGE_COVERS = 6 -- how much of the status bar the game's window border covers (the In-game scheme)
local shortenBtn, historyBtn, wizardEditBtn, search, noMatch, barsCheck, mistakesCheck, altHint
local expanded = {} -- the other characters whose macros the Character tab shows, by key
local groupOpen = {} -- the groups opened or closed: "in", "out", and those under them by "in:" or "out:" and the set
local PLUS, MINUS = "Interface\\Buttons\\UI-PlusButton-Up", "Interface\\Buttons\\UI-MinusButton-Up"
-- Shared with the window's other files (WindowList.lua, WindowShare.lua, WindowTrash.lua): its state, widgets and
-- helpers, put in below as they are made. Theirs come back the same way.
local shared = { state = state, expanded = expanded, groupOpen = groupOpen, notOnBars = false, mistakes = false }
ns.WindowShared = shared
local SCOPE_NAMES = { general = "General", character = "Character" }

local function MacroRange(scope)
    local general, character = GetNumMacros()
    if scope == "general" then return 1, general, MAX_GENERAL end
    return MAX_GENERAL + 1, MAX_GENERAL + character, MAX_CHARACTER
end

-- The index of macro `name` in tab `scope`, or nil: each tab may have a macro of that name.
local function IndexIn(scope, name)
    local first, last = MacroRange(scope)
    for index = first, last do
        if GetMacroInfo(index) == name then return index end
    end
end

local function Letters(s)
    return select(2, s:gsub("[^\128-\191]", ""))
end

-- A tab's name, in the chosen language.
local function TabName(scope) return L[SCOPE_NAMES[scope]] end

local function NoRoom(scope)
    if scope == "general" then return ns.Print("no free general macro slots") end
    ns.Print("no free character macro slots")
end

local function IsDirty()
    if not frame then return false end
    local body, name = code:GetRaw(), nameBox:GetText()
    -- A new macro without a name, an icon picked or a text (empty, or only #showtooltip) is nothing to keep.
    if not state.index and not (state.stored and state.stored.name) and not state.waiting then
        local blank = body:lower():match("^%s*$") or body:lower():match("^%s*#showtooltip%s*$")
        return not (blank and strtrim(name) == "" and state.icon == NEW_ICON)
    end
    return body ~= state.body or name ~= state.name or state.icon ~= state.savedIcon
end

------------------------------------------------------------------------
-- Shorten: the same macro in fewer characters
------------------------------------------------------------------------
local shortened -- { raw, text }: the last text shortened and what it became

local function Shortened(raw)
    if not shortened or shortened.raw ~= raw then
        -- Lines with syntax errors stay as they are.
        local skip = {}
        for _, e in ipairs(ns.Highlight.Errors(raw)) do
            if e.severity == "error" then skip[e.line] = true end
        end
        shortened = { raw = raw, text = ns.Shorten.Text(raw, { conditional = ns.IsConditionalCommand, skip = skip }) }
    end
    return shortened.text
end

-- The button says how many characters it saves.
local function UpdateShorten(raw)
    local saved = Letters(raw) - Letters(Shortened(raw))
    shortenBtn:SetEnabled(saved > 0)
    shortenBtn.label:SetText(saved > 0 and string.format(L["Shorten -%d"], saved) or L["Shorten"])
end

-- Undo brings the old text back.
function Window.Shorten()
    local raw = code:GetRaw()
    local text = Shortened(raw)
    if text == raw then return end
    code:SetRaw(text, #text, true)
    code:SetFocus()
    code:CheckNow()
end

------------------------------------------------------------------------
-- History: earlier saved texts of the macro
------------------------------------------------------------------------
local function Versions()
    if state.stored and state.stored.name then
        return ns.History.Versions(ns.History.Store("character"), state.stored.name, state.body)
    end
    if not state.index then return {} end
    return ns.History.Versions(ns.History.Store(state.scope), state.name, state.body)
end

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

-- "Today, 14:32", "Yesterday, 09:10", "Oct 21, 18:05", "Oct 21, 2025".
local function When(t)
    local day, clock = date("%Y-%m-%d", t), date("%H:%M", t)
    if day == date("%Y-%m-%d") then return string.format(L["Today, %s"], clock) end
    if day == date("%Y-%m-%d", time() - 86400) then return string.format(L["Yesterday, %s"], clock) end
    -- {month} and {day}: the order differs between languages.
    local month = L["{month} {day}"]:gsub("{month}", L[MONTHS[tonumber(date("%m", t))]])
        :gsub("{day}", tonumber(date("%d", t)))
    return month .. ", " .. (date("%Y", t) == date("%Y") and clock or date("%Y", t))
end

-- Like Shorten: the text goes into the editor, Save keeps it, undo takes it back.
-- Another window of MacroSense opened over the editor: the keys go there, not into the text behind it.
function Window.ClearFocus()
    if not frame then return end
    code.edit:ClearFocus()
    nameBox:ClearFocus()
    search:ClearFocus()
    ns.Popup:Hide()
end

-- The text in the editor now, saved or not (the guide's practice checks it).
function Window.Text() return code and code:GetRaw() or "" end

function Window.Restore(body)
    code:SetRaw(body, #body, true)
    code:SetFocus()
    code:CheckNow()
end

local function HistoryItems()
    local items, dim = {}, ns.scheme.dim
    for _, v in ipairs(Versions()) do
        items[#items + 1] = {
            name = string.format("%s  |cff%s%s|r", When(v.time), dim,
                ns.Plural(Letters(v.body), "%d char", "%d chars")),
            current = v.body == code:GetRaw(),
            onClick = function() Window.Restore(v.body) end,
            -- What it changes in the text now, as diff shows it: lines that go red, lines that come back green.
            onEnter = function(row)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(When(v.time), 1, 1, 1)
                local now = code:GetRaw()
                if v.body == now then
                    GameTooltip:AddLine(L["The same as the text now."], 0.6, 0.6, 0.6, true)
                else
                    GameTooltip:AddLine(L["If you pick it, the text changes like this:"], 0.6, 0.6, 0.6, true)
                end
                local signs = { same = "  ", gone = "- ", new = "+ " }
                local colors = { same = "cccccc", gone = "ff5959", new = "66ff66" }
                for _, d in ipairs(ns.History.Diff(now, v.body)) do
                    -- "|" would start a color code in the tooltip: shown as typed. The color is in the text, as
                    -- for TipLine.
                    local r, g, b = ns.RGB(colors[d.kind])
                    GameTooltip:AddLine("|cff" .. colors[d.kind] .. signs[d.kind] .. d.text:gsub("|", "||") .. "|r",
                        r, g, b, true)
                end
                GameTooltip:Show()
            end,
        }
    end
    return items
end

------------------------------------------------------------------------
-- Status bar
------------------------------------------------------------------------
-- Tooltip lines for issues: errors red, warnings yellow.
-- A tooltip line in color `hex`, written into its text too: the tooltip keeps it whatever set the line's color
-- before (the game's tooltips of spells, other addons).
local function TipLine(text, hex)
    local r, g, b = ns.RGB(hex)
    GameTooltip:AddLine("|cff" .. hex .. text .. "|r", r, g, b)
end

local function AddIssueLines(issues)
    for _, e in ipairs(issues) do
        TipLine(string.format(L["Line %d: %s"], e.line, e.message), e.severity == "warning" and "ffd100" or "ff5959")
    end
end

local function UpdateStatus()
    if not warning or not ns.scheme or code.measuring then return end
    local raw = code:GetRaw()
    local cursor = code.edit:HasFocus() and code:GetRawCursor() or 0
    local before = raw:sub(1, cursor)
    local line = select(2, before:gsub("\n", "")) + 1
    local col = Letters(before:match("[^\n]*$")) + 1
    local letters = Letters(raw)
    local s = ns.scheme
    local countColor = letters > MAX_BODY and s.invalid or s.dim
    counter:SetText(string.format(L["Ln %d, Col %d"], line, col)
        .. string.format("    |cff%s%d / %d|r", countColor, letters, MAX_BODY))
    local dirty = IsDirty()
    UpdateShorten(raw)
    historyBtn:SetEnabled(#Versions() > 0)
    wizardEditBtn:SetEnabled(ns.Wizard.Read(raw) ~= nil)
    saveBtn:SetEnabled(dirty and letters <= MAX_BODY)
    revertBtn:SetEnabled(dirty and (state.index ~= nil or state.stored and state.stored.name ~= nil))
    -- Mac: [mod:cmd] on a key macOS uses with Cmd (the macro's keys are the saved macro's).
    local message
    if ns.Shortcuts.Enabled() and state.index then
        local keys = ns.Shortcuts.KeysFor(state.index, state.name)
        message = ns.Shortcuts.Message(ns.Shortcuts.Conflicts(raw, keys))
    end
    -- Errors first, then the macOS shortcut (it can quit the game), then other warnings.
    -- Save shows an alert icon for errors (saving is still allowed).
    local issues, errors, warnings = code.errors or {}, {}, {}
    for _, e in ipairs(issues) do
        table.insert(e.severity == "warning" and warnings or errors, e)
    end
    saveBtn.alert:SetShown(#errors > 0)
    -- Short form here: the issue's own short text ("did you mean ...?") or the message without the
    -- quoted name and notes ("unknown unit"); the full list is in the tooltip.
    local function line(e, color, total)
        local short = e.short or e.message:gsub('%s*%b""', ""):gsub("%s*«.-»", ""):gsub("%s*%b()", "")
        local more = total > 1 and string.format(L[" (+%d more)"], total - 1) or ""
        return "|cff" .. color .. string.format(L["Line %d: %s"], e.line, short) .. more .. "|r"
    end
    local total = #issues + (message and 1 or 0)
    local shown -- the issue in the status bar; a click applies its fix
    if #errors > 0 then
        shown = errors[1]
        warning:SetText(line(shown, s.invalid, total))
    elseif message then
        local more = total > 1 and string.format(L[" (+%d more)"], total - 1) or ""
        warning:SetText("|cff" .. s.warning .. message .. more .. "|r")
    elseif #warnings > 0 then
        shown = warnings[1]
        warning:SetText(line(shown, s.warning, total))
    else
        warning:SetText("")
    end
    warning.errors, warning.message, warning.shown = issues, message, shown

    -- The dot is a texture: not every font has a "●" glyph.
    dirtyDot:SetShown((dirty or state.waiting) and letters <= MAX_BODY)
    dirtyDot:SetVertexColor(ns.RGB(s.accent))
    if letters > MAX_BODY then
        status:SetText("|cff" .. s.invalid .. string.format(L["Macro is longer than %d characters"], MAX_BODY) .. "|r")
    elseif dirty then
        status:SetText(L["Unsaved changes"])
    elseif state.waiting then
        status:SetText(L["Saves when combat ends"])
    else
        status:SetText("")
    end
end

local function IsQuestionMark(icon)
    return icon == NEW_ICON or type(icon) == "string" and icon:lower():find("inv_misc_questionmark", 1, true) ~= nil
end

-- A macro whose icon is the question mark shows in the game the icon of what it casts, and #showtooltip can
-- change it (a key held). Here too: the game's icon for a saved macro; when the game shows the question mark (a
-- new macro, or just saved), the one found for its text, else its name (Completion.MacroIcon). Returns the icon,
-- and true when a saved macro shows the question mark on the action bars now: the one found is only a hint then.
local function FoundIcon(body, index, name)
    local shown = index and select(2, GetMacroInfo(index))
    if shown and not IsQuestionMark(shown) then return shown, false end
    local found = ns.Completion.MacroIcon(ns.Roles.Fill(body or ""), ns.previewEnv, name)
    return found or NEW_ICON, index ~= nil and found ~= nil
end

-- An icon found while the action bars show the question mark: greyed, and its tooltip says why (HintNote).
local function ShowFound(texture, icon, hint)
    texture:SetTexture(ns.IconTexture(icon))
    texture:SetDesaturated(hint)
    texture.hint = hint
end

local function AddHintNote()
    GameTooltip:AddLine(L["On your action bars the game shows the question mark for now: as things are right now "
        .. "(keys held, your target, items in your bags), the macro wouldn't use anything. The grey icon only "
        .. "shows what the macro is for."], 0.8, 0.8, 0.8, true)
end

-- The game's padlock (the pet battle one where the client has pet battles; older clients have the button one).
local LOCK = C_PetBattles and "Interface\\PetBattles\\PetBattle-LockIcon" or "Interface\\Buttons\\LockButton-Locked-Up"

-- A padlock in the corner of an icon the player chose, in a macro with #showtooltip (or #show): there the game
-- would change the icon, and the one chosen stays instead.
local function LockMark(parent, icon, size)
    local mark = parent:CreateTexture(nil, "OVERLAY")
    mark:SetTexture(LOCK)
    mark:SetSize(size, size)
    mark:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    mark:Hide()
    return mark
end

-- An icon chosen (not the question mark) with #showtooltip or #show in the text: the padlock.
local function Locked(icon, body)
    return icon ~= nil and not IsQuestionMark(icon) and ("\n" .. (body or ""):lower()):find("\n%s*#show") ~= nil
end

-- What the padlock means, in the header's and the list's tooltips.
local function AddLockNote()
    GameTooltip:AddLine(L["Icon chosen by you: it stays the same, even when #showtooltip would change it. To let "
        .. "the game pick it, choose the question mark."], 0.8, 0.8, 0.8, true)
end

-- The header's icon: the one chosen, as the list and the action bars show it. The question mark: as FoundIcon.
-- An icon picked and not saved yet shows as picked; with #showtooltip in the text, with the padlock.
local function ShowIcon()
    if state.icon == NEW_ICON then
        ShowFound(iconTex, FoundIcon(code:GetRaw(), state.index, nameBox:GetText()))
    else
        local shown = state.index and state.icon == state.savedIcon and select(2, GetMacroInfo(state.index))
        ShowFound(iconTex, shown or state.icon, false)
    end
    iconTex.mark:SetShown(Locked(state.icon, code:GetRaw()))
end

------------------------------------------------------------------------
------------------------------------------------------------------------
-- Live preview: next to each line, what it would do right now
------------------------------------------------------------------------
local noteColors -- from the scheme, see ApplyLook

local function UpdatePreview()
    if not frame or not ns.db.preview or not noteColors then return end
    -- Lines with syntax errors get no note: they are underlined, and the game's reading of them is a guess.
    local skip = {}
    for _, e in ipairs(code.errors or {}) do
        if e.severity == "error" then skip[e.line] = true end
    end
    -- As the game would run it: with the names of your group's tank and healer.
    -- "What if" on: the moment set up by hand instead of the game's now (WindowWhatIf.lua).
    local env = Window.PreviewEnv and Window.PreviewEnv() or ns.previewEnv
    local results = ns.Preview.Evaluate(ns.Roles.Fill(code:GetRaw()), env, skip)
    local notes = {}
    for i = 1, results.n do notes[i] = ns.Preview.Note(results[i], noteColors) end
    code:SetLineNotes(notes)
end
function Window.RefreshPreview() UpdatePreview() end

------------------------------------------------------------------------
-- Explained: over a line's number or note, the tooltip says in plain words what the line does, every branch
------------------------------------------------------------------------
local explained -- what the tooltip explains now: the line's number and the text

-- Line `n` of `raw`, or nil. One by one: a pattern takes 32 lines at most.
local function LineOf(raw, n)
    local i = 0
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        i = i + 1
        if i == n then return line end
    end
end

-- The names of forms and specializations and the commands of this client, for Explain.
local explainEnv = {
    formName = function(n)
        for _, f in ipairs(ns.sources.forms()) do if f.name == n then return f.hint and L[f.hint] end end
    end,
    specName = function(n)
        for _, spec in ipairs(ns.sources.specs()) do if spec.name == n then return spec.hint and L[spec.hint] end end
    end,
    commandKey = function(name) return ns.CommandKey(name) end,
}

-- The game's tooltip of a spell or item named in a macro; false when the game knows no such name.
local function ActionTip(name)
    name = name:gsub("%(.-%)$", "") -- "Fireball(Rank 4)"
    local id = ns.SpellID(name)
    if id and GameTooltip.SetSpellByID then
        GameTooltip:SetOwner(code.scroll, "ANCHOR_CURSOR")
        GameTooltip:SetSpellByID(id)
        return true
    end
    local itemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local link = itemInfo and select(2, itemInfo(name))
    if link then
        GameTooltip:SetOwner(code.scroll, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        return true
    end
    return false
end

-- The name of what is on the cursor (a spell, mount or item) and the command that takes it; nil for anything else.
local function OnCursor()
    local kind, a, b, c = GetCursorInfo()
    if kind == "spell" then
        local id = c or a
        local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
            or (GetSpellInfo and GetSpellInfo(id))
        return name, "/cast"
    elseif kind == "mount" then
        return C_MountJournal and C_MountJournal.GetMountInfoByID and C_MountJournal.GetMountInfoByID(a), "/cast"
    elseif kind == "companion" then -- the Classic clients' mounts and pets
        local spell = GetCompanionInfo and select(3, GetCompanionInfo(b, a))
        return spell and (GetSpellInfo and GetSpellInfo(spell)), "/cast"
    elseif kind == "item" then
        local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(a) or (GetItemInfo and GetItemInfo(a))
        return name, "/use"
    end
end

-- `name` goes in at the cursor; on an empty line after the command that takes it ("/cast Fireball").
local function PutName(name, command)
    local raw = code:GetRaw()
    local at = code.edit:HasFocus() and code:GetRawCursor() or #raw
    local line = raw:sub(1, at):match("[^\n]*$") .. raw:sub(at + 1):match("^[^\n]*")
    code:InsertText(line:find("%S") and name or (command .. " " .. name))
end

-- Issue `e` fixed: its fix put in place of its text.
local function ApplyFix(e)
    local raw, from, to = code:GetRaw(), e.fixFrom or e.from, e.fixTo or e.to
    code:SetRaw(raw:sub(1, from - 1) .. e.fix .. raw:sub(to + 1), from - 1 + #e.fix, true)
    code:CheckNow()
end

-- The issue with a fix at raw position `pos` of the text, if any.
local function FixAt(pos)
    for _, e in ipairs(pos and code.errors or {}) do
        if e.fix and pos >= e.from and pos <= e.to then return e end
    end
end

-- The word under the mouse: what it means, or the game's tooltip of the spell or item.
local function WordTip(raw, pos)
    local doc = pos and ns.Docs.At(raw, pos, explainEnv)
    if not doc then return false end
    if doc.action then return ActionTip(doc.action) end
    GameTooltip:SetOwner(code.scroll, "ANCHOR_CURSOR")
    GameTooltip:AddLine(doc.title, 1, 1, 1)
    for _, line in ipairs(doc.lines) do GameTooltip:AddLine(line, 0.85, 0.85, 0.85, true) end
    GameTooltip:Show()
    return true
end

local function UpdateExplain()
    local n = code:HoveredLine()
    local raw = code:GetRaw()
    local pos = not n and code:HoveredPos()
    local key = (n and n .. "\1" .. raw) or (pos and "@" .. pos .. "\1" .. raw)
    if key == explained then return end
    explained = key
    local text = n and LineOf(raw, n)
    local lines = text and ns.Explain.Line(text, explainEnv)
    if not lines then
        local shown, e = WordTip(raw, pos), FixAt(pos)
        if e then -- an issue Ctrl+click fixes: said under what the word means
            if not shown then GameTooltip:SetOwner(code.scroll, "ANCHOR_CURSOR") end
            TipLine(L["Ctrl+click to fix it"], "66ff66")
            GameTooltip:Show()
        elseif not shown and GameTooltip:GetOwner() == code.scroll then
            GameTooltip:Hide()
        end
        return
    end
    GameTooltip:SetOwner(code.scroll, "ANCHOR_CURSOR")
    GameTooltip:AddLine(string.format(L["Line %d"], n), 1, 1, 1)
    for _, line in ipairs(lines) do
        local more = line:match("^%s+(.*)$") -- a unit tried after the one before it
        GameTooltip:AddLine(more and "     " .. more or "• " .. line, 0.85, 0.85, 0.85, true)
    end
    GameTooltip:Show()
end

------------------------------------------------------------------------
-- Editing
------------------------------------------------------------------------
-- `stored`: one behind the scenes instead, { id = its set, name } (no name: a new one there).
local function Load(index, stored)
    -- The wizard had the macro shown before: what it makes is not for this one.
    if ns.WizardWindow.IsEditing() then ns.WizardWindow.Close() end
    state.stored = stored and { id = stored.id, name = stored.name }
    state.waiting = nil
    local m
    for _, x in ipairs(stored and stored.name and ns.Sets.List(stored.id) or {}) do
        if x.name == stored.name then m = x end
    end
    if stored and stored.name and not m then state.stored, stored = nil, nil end
    if m then
        state.index, state.name, state.icon, state.body = nil, m.name, m.icon or NEW_ICON, m.body or ""
    elseif index then
        local name, _, body = GetMacroInfo(index)
        local text = ns.Roles.Text(index > MAX_GENERAL and "character" or "general", name, body or "")
        state.index, state.name, state.icon, state.body = index, name, ns.MacroIcon(index) or NEW_ICON, text
        -- Saved in combat: as saved, until it goes in.
        for _, w in ipairs(waiting) do
            if w.index == index then
                state.waiting, state.name, state.icon, state.body = w, w.name, w.icon, w.body
            end
        end
    else
        state.index, state.name, state.icon, state.body = nil, "", NEW_ICON, NEW_BODY
    end
    state.savedIcon = state.icon
    nameBox:SetText(state.name)
    ShowIcon()
    ns.IconPicker.SetCurrent(state.icon)
    code:SetRaw(state.body, (index or m) and 0 or #state.body)
    Window.RefreshList()
    UpdateStatus()
end

-- Ask before throwing away unsaved changes.
-- Asked in the language chosen, before the interface reloads to show it.
StaticPopupDialogs.MACROSENSE_RELOAD = {
    text = "Reload the interface to switch the language?",
    button1 = "Reload", button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs.MACROSENSE_DISCARD = {
    text = "Discard unsaved changes to this macro?",
    button1 = "Yes", button2 = "No",
    OnAccept = function(_, fn) fn() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs.MACROSENSE_DELETE = {
    text = "Delete macro \"%s\"?%s",
    button1 = "Delete", button2 = "Cancel",
    -- The macros may have moved since the x was clicked: then it is found by its name in its tab.
    OnAccept = function(_, m)
        if m.stored then return Window.Forget(m.stored.id, m.stored.name) end
        local index = GetMacroInfo(m.index) == m.name and m.index or IndexIn(m.scope, m.name)
        if index then Window.Delete(index) end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function Guard(fn)
    if IsDirty() then
        ns.Ask("MACROSENSE_DISCARD", nil, nil, fn)
    else
        fn()
    end
end

function Window.Select(index)
    if index == state.index and not state.stored then return end
    Guard(function() Load(index) end)
end

-- Macro sets turned on or off: the list as it is then; off, one behind the scenes being edited is left (its
-- changes too: there is nowhere to keep them).
function Window.SetsChanged()
    if not frame then return end
    setsCheck:Refresh()
    if state.stored and not ns.Sets.Mine().enabled then
        local first, last = MacroRange(state.scope)
        return Load(last >= first and first or nil)
    end
    Window.RefreshList()
end

-- Macro `name` of set `id`, behind the scenes, in the editor.
-- The set that keeps macro `name` behind the scenes (the specialization now first, then the class's, this
-- character's, the others), nil when none or the sets are off.
function Window.StoredSetOf(name)
    if not ns.Sets.Mine().enabled then return end
    local ids = { ns.Sets.Mine().active, "class", "character" }
    for _, spec in ipairs(ns.Sets.Specs()) do ids[#ids + 1] = spec.key end
    for _, id in ipairs(ids) do
        for _, m in ipairs(ns.Sets.List(id)) do
            if m.name == name and ns.Sets.Behind(id, m) then return id end
        end
    end
end

function Window.SelectStored(id, name)
    if state.stored and state.stored.id == id and state.stored.name == name then return end
    Guard(function() Load(nil, { id = id, name = name }) end)
end

-- Macro `name` of set `id`, behind the scenes, deleted: into the trash. The one being edited: the first one of the
-- tab opens.
function Window.Forget(id, name)
    if not ns.Sets.Forget(id, name) then return end
    if state.stored and state.stored.id == id and state.stored.name == name then
        local first, last = MacroRange(state.scope)
        return Load(last >= first and first or nil)
    end
    Window.RefreshList()
end

function Window.SetScope(scope)
    if scope == state.scope then return end
    Guard(function()
        state.scope = scope
        ns.db.scope = scope
        local first, last = MacroRange(scope)
        Load(last >= first and first or nil)
    end)
end

-- An empty new macro in the tab that is open, if the tab has a free slot. With macro sets on and no free slot, one
-- for the character's, behind the scenes.
local function Fresh()
    local first, last, max = MacroRange(state.scope)
    if last - first + 1 >= max then
        if shared.SetsShown() then
            Load(nil, { id = "character" })
            return true
        end
        NoRoom(state.scope)
        return false
    end
    Load(nil)
    return true
end

function Window.New()
    Guard(function()
        local first, last, max = MacroRange(state.scope)
        -- No free slot, macro sets on: asked first, then a new one behind the scenes.
        if last - first + 1 >= max and shared.SetsShown() then
            return ns.SetsWindow.AskBehind(1, function()
                Load(nil, { id = "character" })
                nameBox:SetFocus()
            end)
        end
        if Fresh() then nameBox:SetFocus() end
    end)
end

-- Macro `w` (as in `waiting`) into the game, with its earlier versions and the names for @tank and @heal: its
-- index, or nil.
local function Write(w)
    local renamed = w.old and w.name ~= w.old
    -- Earlier versions follow a new name.
    if renamed then ns.History.Renamed(w.scope, w.old, w.name) end
    -- The game's macro has the names of your group's tank and healer for @tank and @heal.
    local written = ns.Roles.Fill(w.body)
    local index
    if w.index then
        -- The game keeps macros sorted by name, so the index may change.
        index = EditMacro(w.index, w.name, w.icon, written)
    else
        index = CreateMacro(w.name, w.icon or NEW_ICON, written, w.scope == "character")
    end
    if not index or index == 0 then
        if renamed then ns.History.Renamed(w.scope, w.name, w.old) end
        return
    end
    ns.Roles.Saved(w.scope, w.old, w.name, w.body, select(3, GetMacroInfo(index)))
    -- The text it replaced is kept now, not only when the game reports the change.
    ns.History.Scan()
    return index
end

-- Saved in combat: kept as saved, it goes in when combat ends. Saved again, it replaces what waits.
local function Wait(w)
    local was = state.waiting
    if was then
        w.old = was.old
        for i, x in ipairs(waiting) do if x == was then waiting[i] = w end end
    else
        waiting[#waiting + 1] = w
    end
    state.waiting, state.name, state.body, state.savedIcon = w, w.name, w.body, w.icon
    ns.Print("\"%s\" will be saved when combat ends: the game doesn't let you change macros in combat", w.name)
    UpdateStatus()
end

-- Combat is over: what was saved in it goes into the game, in the order saved.
function Window.CombatEnded()
    if #waiting == 0 then return end
    local list = waiting
    waiting = {}
    for _, w in ipairs(list) do
        -- Its place in the list moves when one saved before it got another name.
        if w.index and GetMacroInfo(w.index) ~= w.old then w.index = IndexIn(w.scope, w.old) end
        local index = (w.index or not w.old) and Write(w)
        if index then
            ns.Print("\"%s\" saved after combat", w.name)
            if state.waiting == w then state.index = index end
        else
            ns.Print("could not save \"%s\" after combat", w.name)
        end
        if state.waiting == w then state.waiting = nil end
    end
    if not frame then return end
    Window.RefreshList()
    UpdateStatus()
end

function Window.Save()
    -- A mistake in the word just typed shows now, not only after the typing pause.
    code:CheckNow()
    local name = strtrim(nameBox:GetText())
    local body = code:GetRaw()
    if name == "" then
        nameBox:SetFocus()
        return ns.Print("the macro needs a name")
    end
    -- The game's macro has the names of your group's tank and healer for @tank and @heal.
    local written = ns.Roles.Fill(body)
    if Letters(written) > MAX_BODY then return ns.Print("macro is longer than %d characters", MAX_BODY) end
    -- One behind the scenes: kept in its set.
    if state.stored then
        local ok, why = ns.Sets.Write(state.stored.id, state.stored.name, name, state.icon, body)
        if not ok then
            if why == "name" then
                return ns.Print("\"%s\" has a macro named \"%s\" already: a set holds only one macro of a name. "
                    .. "Choose another name.", ns.SetsWindow.Label(state.stored.id), name)
            end
            return ns.Print("could not save the macro")
        end
        ns.History.MoveNote("character", state.stored.name or name, "character", name)
        state.stored.name, state.name, state.body, state.savedIcon = name, name, body, state.icon
        Window.RefreshList()
        return UpdateStatus()
    end
    local scope = state.index and (state.index > MAX_GENERAL and "character" or "general") or state.scope
    local w = { scope = scope, index = state.index, old = state.index and state.name, name = name, icon = state.icon,
        body = body }
    if InCombatLockdown() then
        -- A new one needs a free slot then too, with those waiting.
        if not w.index and not state.waiting then
            local first, last, max = MacroRange(scope)
            local count = last - first + 1
            for _, x in ipairs(waiting) do if not x.index and x.scope == scope then count = count + 1 end end
            if count >= max then return NoRoom(scope) end
        end
        return Wait(w)
    end
    local index = Write(w)
    if not index then return ns.Print("could not save the macro") end
    state.index, state.name, state.body = index, name, body
    state.icon = ns.MacroIcon(index) or state.icon
    state.savedIcon = state.icon
    ShowIcon()
    Window.RefreshList()
    UpdateStatus()
    ns.Easter.Saved(body)
end

-- Put a macro on the cursor, to drop on an action bar. A new macro has to be saved first.
function Window.Pickup(index)
    if not index then return ns.Print("save the macro first, then drag it to an action bar") end
    if InCombatLockdown() then return ns.Print("action bars cannot be changed in combat") end
    PickupMacro(index)
end

-- Bindings or action bars changed.
function Window.RefreshStatus()
    if frame and frame:IsShown() then UpdateStatus() end
end

-- What is on the action bars changed: the list follows when it shows only the macros on no bar.
function Window.BarsChanged()
    if frame and frame:IsShown() and shared.notOnBars then Window.RefreshList() end
end

-- Spells, pets or talents changed: the marks in the list and the editor's warnings follow.
function Window.SpellsChanged()
    if not frame or not frame:IsShown() then return end
    Window.RefreshList()
    code:ScheduleUnderlines()
end

function Window.Revert()
    if state.stored and state.stored.name then return Load(nil, state.stored) end
    if state.index then Load(state.index) end
end

-- Before macro `index` is deleted: one made in "From Spellbook" that still casts its spell gives its buttons back
-- to that spell, as they were before it. (Deleted, a macro leaves its buttons empty.)
local function SpellBack(index)
    local name, _, body = GetMacroInfo(index)
    if not name or index <= ns.MAX_GENERAL or InCombatLockdown() then return end
    -- Two spells in it, one joined on a key: the one it was made for; remembered before that was, the one it casts
    -- with no key held.
    local casts, main, spell, best = ns.Spellbook.Casts(body), ns.Spellbook.Main(body), nil, 0
    for s, m in pairs(ns.Spellbook.Journal(ns.char).made) do
        if m.name == name and casts[s:lower()] then
            local rank = m.main and 3 or s:lower() == main and 2 or 1
            if rank > best then spell, best = s, rank end
        end
    end
    local id = spell and ns.SpellID(spell)
    local pickup = C_Spell and C_Spell.PickupSpell or PickupSpell
    if not id or not pickup then return end
    for _, slot in ipairs(ns.ActionBars.SlotsOf(name)) do
        if ns.ActionBars.MacroAt(slot) == index then
            pickup(id)
            if GetCursorInfo() == "spell" then PlaceAction(slot) end -- a spell you don't have now: nothing
            ClearCursor()
        end
    end
end

-- Deletes macro `index`. The one being edited: the next one opens, or the one before when it was the last. Another
-- one: the editor keeps what it shows. Which one it was is known before: the game may report the change while it
-- deletes (UPDATE_MACROS), and the one being edited, looked up by its name, is gone then.
function Window.Delete(index)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local editing = state.index
    SpellBack(index)
    DeleteMacro(index)
    local first, last = MacroRange(state.scope)
    if index == editing then return Load(last >= first and math.min(index, last) or nil) end
    -- The macros after it in its tab move up one, the one being edited too.
    if editing and index >= first and index < editing then state.index = editing - 1 end
    Window.RefreshList()
    UpdateStatus()
end

-- `s` cut to its first `n` letters, whole ones.
local function FirstLetters(s, n)
    while Letters(s) > n and s ~= "" do
        s = s:gsub("[\1-\127\192-\255][\128-\191]*$", "") -- the last letter, whole
    end
    return s
end

-- A name no macro has: "Fear" -> "Fear 2", "Fear 2" -> "Fear 3", cut to fit the name limit. Two macros with
-- one name would share a key binding ("MACRO Fear" runs the first one). `also`: names given out already;
-- `onlyAlso`: those only (a set's names, the game's not counted).
local function FreeName(name, also, onlyAlso)
    local function taken(n)
        local index = not onlyAlso and GetMacroIndexByName(n)
        return (index and index > 0) or (also ~= nil and also[n] ~= nil)
    end
    if not taken(name) then return name end
    local base, n = name:match("^(.-) (%d+)$")
    base, n = base or name, tonumber(n) or 1
    while true do
        n = n + 1
        local suffix = " " .. n
        local candidate = FirstLetters(base, MAX_NAME - Letters(suffix)):match("^(.-)%s*$") .. suffix
        if not taken(candidate) then return candidate end
    end
end

-- Macro `name` made in tab `scope` from `body` as MacroSense keeps it, with @tank and @heal: the game's has the names
-- of your group's tank and healer (too long with them, nobody's: @none, as long as the tags), and gets the new ones
-- from then on (Roles.lua). Its index, or nil when the game made none.
local function MakeMacro(scope, name, icon, body)
    local written = ns.Roles.Fill(body)
    if Letters(written) > MAX_BODY then written = ns.Conditions.Fill(body, {}) end
    local index = CreateMacro(name, icon or NEW_ICON, written, scope == "character")
    if not index or index == 0 then return nil end
    local made, _, text = GetMacroInfo(index)
    ns.Roles.Saved(scope, nil, made, body, text)
    return index
end

-- With macro sets on and no free slot, a new character macro is kept behind the scenes, in this character's: under a
-- name free in the game and there. Opened, and told in the chat (`quiet`: neither). Returns its name.
function Window.MakeBehind(name, icon, body, quiet)
    local taken = {}
    for _, m in ipairs(ns.Sets.List("character")) do taken[m.name] = true end
    local free = FreeName(FirstLetters(name, MAX_NAME), taken)
    ns.Sets.Write("character", nil, free, icon or NEW_ICON, body)
    if quiet then return free end -- one of many: they say it together
    state.scope, ns.db.scope = "character", "character"
    Load(nil, { id = "character", name = free })
    Window.RefreshList()
    ns.Print("\"%s\" is made behind the scenes, in \"This character's\": there is no free slot. Put another macro "
        .. "behind the scenes, then take this one in.", free)
    return free
end

-- No free slot in tab `scope`: with macro sets on, a character macro can be made behind the scenes instead (asked
-- first, unless you said not to; `count` of them), by `make()`; else there is no room.
local function Full(scope, make, count, moving)
    if scope ~= "character" or not ns.Sets.Mine().enabled then return NoRoom(scope) end
    ns.SetsWindow.AskBehind(count or 1, make, moving)
end

-- A copy of macro `index` (the one being edited when nil) in `scope`, opened then. The one being edited is copied
-- with what the editor shows (name, icon, text) and keeps its saved text; another one as saved, after asking
-- about unsaved changes.
function Window.Copy(scope, index)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    index = index or state.index
    if not index then return end
    local first, last, max = MacroRange(scope)
    local full = last - first + 1 >= max
    if full and (scope ~= "character" or not ns.Sets.Mine().enabled) then return NoRoom(scope) end
    -- `body` as MacroSense shows it: @tank and @heal stay in the copy.
    local function make(name, icon, body)
        if full then
            return Full(scope, function() Guard(function() Window.MakeBehind(name, icon, body) end) end)
        end
        local copy = MakeMacro(scope, FreeName(name), icon, body)
        if not copy then return ns.Print("could not copy the macro") end
        ns.History.Scan()
        state.scope, ns.db.scope = scope, scope
        Load(copy)
    end
    if index ~= state.index then
        return Guard(function()
            local name, _, body = GetMacroInfo(index)
            make(name, ns.MacroIcon(index), ns.Roles.Text(index > MAX_GENERAL and "character" or "general", name,
                body or ""))
        end)
    end
    local body = code:GetRaw()
    if Letters(ns.Roles.Fill(body)) > MAX_BODY then return ns.Print("macro is longer than %d characters", MAX_BODY) end
    local name = strtrim(nameBox:GetText())
    make(name ~= "" and name or state.name, state.icon, body)
end

-- Macro `name` of tab `scope`: of two with that name, the one with text `body`, else the first; nil when none.
local function IndexOf(scope, name, body)
    local first, last = MacroRange(scope)
    local found
    for index = first, last do
        local n, _, text = GetMacroInfo(index)
        if n == name then
            if text == body then return index end
            found = found or index
        end
    end
    return found
end

-- Macro `index` into the other tab, opened there: made under its name (a free one when that tab has it) with its
-- icon and text, put back on its buttons of the action bars now, its versions taken along, then deleted here. The
-- bars of your other specializations and, for a general macro, of other characters lose it. Unsaved changes are
-- asked about first.
-- General macro `name` (with text `text` as it was asked about) into the character's, with no free slot there:
-- behind the scenes, off its buttons (one of a macro gone would show the next general macro made in its place).
-- All or nothing, as the moves below.
local function MoveBehind(from, name, text) return ns.Sets.Atomic(function()
    local index = IndexOf(from, name, text)
    if not index then return end
    -- As MacroSense shows it: behind the scenes @tank and @heal stay, the names come in with it again.
    local body = ns.Roles.Text(from, name, select(3, GetMacroInfo(index)) or "")
    local icon = ns.MacroIcon(index)
    for _, slot in ipairs(ns.ActionBars.SlotsOf(name)) do
        if ns.ActionBars.MacroAt(slot) == index then
            PickupAction(slot)
            ClearCursor()
        end
    end
    DeleteMacro(index) -- first: its name is free for the one behind the scenes
    local moved = Window.MakeBehind(name, icon, body, true)
    ns.History.Moved(from, "character", name, moved)
    ns.Roles.Moved(from, "character", name, moved)
    ns.History.Scan()
    state.scope, ns.db.scope = "character", "character"
    Load(nil, { id = "character", name = moved })
    Window.RefreshList()
    ns.Print("\"%s\" is moved behind the scenes, in \"This character's\": there is no free slot. Put another macro "
        .. "behind the scenes, then take this one in.", moved)
end) end

-- Macro `index` made in tab `to` and deleted where it was, as Window.Move does it, inside ns.Sets.Atomic: its name
-- there, or nil.
local function MoveOne(index, to)
    local from = index > MAX_GENERAL and "character" or "general"
    local name, _, body = GetMacroInfo(index)
    local icon, slots = ns.MacroIcon(index), ns.ActionBars.SlotsOf(name)
    local moved = IndexIn(to, name) and FreeName(name) or name
    local made = CreateMacro(moved, icon or NEW_ICON, body or "", to == "character")
    if not made or made == 0 then return nil end
    ns.History.Moved(from, to, name, moved)
    ns.Roles.Moved(from, to, name, moved)
    -- This one, not another of its name: a macro made in the other tab leaves the numbers of this one as they were.
    DeleteMacro(index)
    ns.ActionBars.Place(IndexIn(to, moved), slots)
    return moved
end
shared.MoveOne = MoveOne

function Window.Move(index)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local from = index > MAX_GENERAL and "character" or "general"
    local to = from == "general" and "character" or "general"
    local first, last, max = MacroRange(to)
    if last - first + 1 >= max then
        local name, _, body = GetMacroInfo(index)
        return Full(to, function() Guard(function() MoveBehind(from, name, body) end) end, 1, true)
    end
    Guard(function() ns.Sets.Atomic(function()
        local moved = MoveOne(index, to)
        if not moved then return ns.Print("could not move the macro") end
        ns.History.Scan()
        state.scope, ns.db.scope = to, to
        Load(IndexIn(to, moved))
    end) end)
end

local function AskMove(_, m)
    local index = GetMacroInfo(m.index) == m.name and m.index or IndexIn(m.scope, m.name)
    if index then Window.Move(index) end
end
-- Asked when the bars of another specialization or character lose the macro.
StaticPopupDialogs.MACROSENSE_MOVE_GENERAL = {
    text = "Move \"%s\" to the General tab?%s",
    button1 = "Move", button2 = "Cancel", OnAccept = AskMove,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs.MACROSENSE_MOVE_CHARACTER = {
    text = "Move \"%s\" to the Character tab?%s",
    button1 = "Move", button2 = "Cancel", OnAccept = AskMove,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- Moves macro `index` into the other tab; asks first when it is on the bars of your other specializations or, for a
-- general macro, of your other characters: those lose it.
local function MoveAsked(index)
    local name = GetMacroInfo(index)
    local from = index > MAX_GENERAL and "character" or "general"
    local _, elsewhere = ns.ActionBars.Uses(from, name)
    if #elsewhere == 0 then return Window.Move(index) end
    local note = "\n\n" .. string.format(L["It will be gone from the bars of %s."], table.concat(elsewhere, ", "))
    ns.Ask(from == "general" and "MACROSENSE_MOVE_CHARACTER" or "MACROSENSE_MOVE_GENERAL", name, note,
        { index = index, name = name, scope = from })
end

-- What macro `index` in the game can be: duplicated, copied or moved to the other tab: { dup, copy, move }. `sets`:
-- among the sets' items, named as they are ("Move to: General").
local function CopyItems(index, sets)
    local other = state.scope == "general" and "character" or "general"
    local function item(scope, label, tip, move)
        return shared.TabItem(scope, label, tip, function()
            if move then MoveAsked(index) else Window.Copy(scope, index) end
        end)
    end
    -- The macro being edited is copied with what the editor shows.
    local tips = index == state.index and {
        same = L["Makes a copy in this tab with the text from the editor, named like \"Fear 2\". The macro you copy "
            .. "keeps its saved text."],
        character = L["Makes a copy for this character only, with the text from the editor, named like \"Fear 2\". "
            .. "The macro you copy keeps its saved text."],
        general = L["Makes a copy for all your characters, with the text from the editor, named like \"Fear 2\". The "
            .. "macro you copy keeps its saved text."],
    } or {
        same = L["Makes a copy in this tab, named like \"Fear 2\"."],
        character = L["Makes a copy for this character only, named like \"Fear 2\"."],
        general = L["Makes a copy for all your characters, named like \"Fear 2\"."],
    }
    local moves = {
        character = L["Into the Character tab, for this character only. Its buttons on your action bars stay, and its "
            .. "history goes with it."],
        general = L["Into the General tab, for all your characters. Its buttons on your action bars stay, and its "
            .. "history goes with it."],
    }
    return {
        item(state.scope, L["Duplicate"], tips.same),
        item(other, sets and string.format(L["Copy to: %s"], TabName(other))
            or other == "character" and L["Copy to Character"] or L["Copy to General"], tips[other]),
        item(other, sets and string.format(L["Move to: %s"], TabName(other))
            or other == "character" and L["Move to Character"] or L["Move to General"], moves[other], true),
    }
end

-- Another character's macro `m` ({ name, icon, body }) in tab `scope`, under a free name, opened. Unsaved changes are
-- asked about first.
function Window.CopyIn(scope, m)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local first, last, max = MacroRange(scope)
    if last - first + 1 >= max then
        return Full(scope, function() Guard(function() Window.MakeBehind(m.name, m.icon, m.body) end) end)
    end
    Guard(function()
        local name = FreeName(FirstLetters(m.name, MAX_NAME))
        local made = CreateMacro(name, m.icon or NEW_ICON, m.body, scope == "character")
        if not made or made == 0 then return ns.Print("could not copy the macro") end
        ns.History.Scan()
        state.scope, ns.db.scope = scope, scope
        Load(IndexIn(scope, name))
    end)
end

-- The copy menu of macro `index`.
function Window.OpenCopyMenu(owner, index) ns.OpenMenu(owner, CopyItems(index), 180, false, true) end

-- The "..." menu of list row `r`: another character's macro copied here; a macro copied or moved to the other tab;
-- in a set, with what can be done with it in the sets too.
function Window.OpenRowMenu(owner, r)
    if r.what == "altMacro" then return shared.OpenAltCopyMenu(owner, r.macro) end
    local items
    if r.set then
        local copy = r.what == "macro" and CopyItems(r.index, true)
        items = shared.SetsItems(r, copy and { dup = copy[1], copy = copy[2], move = copy[3] })
    else
        items = CopyItems(r.index)
    end
    -- A General one: favorite, folder (WindowFolders.lua). Its note, last (one behind the scenes is the
    -- character's).
    if r.what == "macro" and r.scope == "general" then
        for _, item in ipairs(shared.FolderItems({ r.name })) do items[#items + 1] = item end
    end
    items[#items + 1] = shared.NoteItem(r.what == "stored" and "character" or r.scope, r.name)
    ns.OpenMenu(owner, items, 200, false, true)
end

-- Macro row `source` dropped on tab `scope`, `copy` or moved: true (and "behind": with no free slot, behind the
-- scenes), or false and why: "combat", "same" (its own tab), "full", "stored" (behind the scenes, onto Character).
function Window.TabPlan(source, scope, copy)
    if InCombatLockdown() then return false, "combat" end
    if source.what == "stored" then
        if scope ~= "general" then return false, "stored" end
    elseif source.scope == scope then
        return false, "same"
    end
    local first, last, max = MacroRange(scope)
    if last - first + 1 < max then return true end
    if scope == "character" and ns.Sets.Mine().enabled then return true, "behind" end
    return false, "full"
end

-- Why a macro can't go onto tab `scope`, in words.
function Window.TabWhy(why, scope)
    if why == "combat" then return L["macros cannot be changed in combat"] end
    if why == "same" then return L["It is in this tab already."] end
    if why == "full" then return string.format(L["The %s tab is full."], TabName(scope)) end
    return L["It is this character's already. To bring it into the game, drag it onto \"In the game\" or use "
        .. "\"Take in\"."]
end

-- Macro row `source` dropped on tab `scope`: moved there, or copied with `copy`.
function Window.DropOnTab(source, scope, copy)
    ClearCursor() -- a macro picked up for the action bars
    local ok, why = Window.TabPlan(source, scope, copy)
    if not ok then return ns.Say(Window.TabWhy(why, scope)) end
    if source.what == "stored" then return Window.StoredToGeneral(source.set, source.name, not copy) end
    if copy then return Window.Copy(scope, source.index) end
    MoveAsked(source.index)
end

-- Macro `name` of set `id`, behind the scenes: { name, icon, body } as kept, the one being edited as saved.
local function StoredOf(id, name)
    for _, m in ipairs(ns.Sets.List(id)) do if m.name == name then return m end end
end

-- A copy of macro `name` of set `id` in the same set, behind the scenes, under a free name, opened. In a
-- specialization not chosen now it comes into the game with it, as the one copied does.
function Window.Duplicate(id, name)
    local m = StoredOf(id, name)
    if not m then return end
    Guard(function() ns.Sets.Atomic(function()
        local taken = {}
        for _, x in ipairs(ns.Sets.List(id)) do taken[x.name] = true end
        local copy = FreeName(FirstLetters(m.name, MAX_NAME), taken)
        if not ns.Sets.Write(id, nil, copy, m.icon or NEW_ICON, m.body or "") then
            return ns.Print("could not copy the macro")
        end
        if not ns.Sets.InGame(id) and not ns.Sets.IsParked(id, m) then ns.Sets.Park(id, copy, false) end
        Load(nil, { id = id, name = copy })
        Window.RefreshList()
    end) end)
end

-- Macro `name` of set `id`, behind the scenes, into the General tab under a free name, opened; `move`: it leaves
-- its set, with its history.
function Window.StoredToGeneral(id, name, move)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local first, last, max = MacroRange("general")
    if last - first + 1 >= max then return NoRoom("general") end
    local m = StoredOf(id, name)
    if not m then return end
    Guard(function() ns.Sets.Atomic(function()
        local general = FreeName(FirstLetters(m.name, MAX_NAME))
        local made = MakeMacro("general", general, m.icon, m.body or "")
        if not made then return ns.Print(move and "could not move the macro" or "could not copy the macro") end
        if move then
            ns.History.Moved("character", "general", name, general)
            ns.Sets.Forget(id, name, true)
        end
        ns.History.Scan()
        state.scope, ns.db.scope = "general", "general"
        Load(IndexIn("general", general))
    end) end)
end

------------------------------------------------------------------------
-- Shared with the window's other files: the helpers above (ns.WindowShared).
------------------------------------------------------------------------
-- The saved macros of `scope`, or of both tabs, as Share.Encode takes them: with the game's text, or as MacroSense
-- shows it (`shown`: @tank and @heal, for a code to share).
local function Macros(scope, shown)
    local out = {}
    for _, s in ipairs(scope and { scope } or { "general", "character" }) do
        local first, last = MacroRange(s)
        for index = first, last do
            local name, _, body = GetMacroInfo(index)
            if name then
                body = shown and ns.Roles.Text(s, name, body or "") or body or ""
                out[#out + 1] = { scope = s, name = name, icon = ns.MacroIcon(index), body = body }
            end
        end
    end
    return out
end

for key, value in pairs({
    MAX_BODY = MAX_BODY, MAX_NAME = MAX_NAME, NEW_ICON = NEW_ICON, MAX_GENERAL = MAX_GENERAL,
    MAX_CHARACTER = MAX_CHARACTER, NO_ICON = NO_ICON, PLUS_ICON = PLUS_ICON, PLUS = PLUS, MINUS = MINUS, ROW_H = ROW_H,
    AddIssueLines = AddIssueLines, AddHintNote = AddHintNote, AddLockNote = AddLockNote, FoundIcon = FoundIcon,
    ShowFound = ShowFound, LockMark = LockMark, Locked = Locked,
    MacroRange = MacroRange, IndexIn = IndexIn, Letters = Letters, TabName = TabName, When = When, Load = Load,
    Guard = Guard, Full = Full, FreeName = FreeName, FirstLetters = FirstLetters, Macros = Macros,
    MakeMacro = MakeMacro,
}) do shared[key] = value end

------------------------------------------------------------------------
-- Wizard: a new macro from a form, in a window of its own
------------------------------------------------------------------------
-- The macro shown, in the wizard's form: what the form makes of it comes back into the editor as a change, under
-- the name chosen there (Save keeps it, undo takes it back, as with History).
function Window.OpenInWizard()
    ns.WizardWindow.Edit(code:GetRaw(), nameBox:GetText(), function(text, name)
        if name ~= "" then nameBox:SetText(name) end
        Window.Restore(text)
    end)
end

-- A name no macro has, cut to fit (see FreeName).
function Window.FreeName(name) return FreeName(FirstLetters(name, MAX_NAME)) end

-- The wizard's macro: saved in the tab `scope` under a free name, then opened in the editor. @tank and @heal in it
-- are the names of your group's tank and healer in the game's macro, kept up to date (Roles.lua).
function Window.CreateFromWizard(name, body, scope)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local first, last, max = MacroRange(scope)
    local filled = ns.Roles.Fill(body)
    if Letters(filled) > MAX_BODY then return ns.Print("macro is longer than %d characters", MAX_BODY) end
    if last - first + 1 >= max then
        return Full(scope, function()
            Guard(function()
                ns.WizardWindow.Close()
                Window.MakeBehind(name, NEW_ICON, body) -- with @tank and @heal: the names come in with it
            end)
        end)
    end
    Guard(function()
        local index = MakeMacro(scope, Window.FreeName(name), NEW_ICON, body)
        if not index then return ns.Print("could not save the macro") end
        ns.History.Scan()
        state.scope, ns.db.scope = scope, scope
        ns.WizardWindow.Close()
        Load(index)
    end)
end

-- The macro list changed elsewhere (Blizzard UI, another addon): keep our selection by name. The macro shown,
-- changed there and not here, shows as it is saved now (the names MacroSense writes in for @tank and @heal are no
-- change to it).
function Window.OnMacrosChanged()
    if not frame or not frame:IsShown() then return end
    -- The one behind the scenes came into the game (its specialization chosen, or taken in): edited there.
    local stored = state.stored
    if stored and stored.name and not IsDirty() then
        local m
        for _, x in ipairs(ns.Sets.List(stored.id)) do if x.name == stored.name then m = x end end
        local index = GetMacroIndexByName(stored.name)
        if (not m or not ns.Sets.Behind(stored.id, m)) and index and index > 0 then return Load(index) end
        if not m then return Load(nil) end
    end
    if state.index then
        local name = GetMacroInfo(state.index)
        if name ~= state.name then
            local dirty = IsDirty() -- as it was: without its index it would be a new one
            local index = GetMacroIndexByName(state.name)
            state.index = index and index > 0 and index or nil
            -- Gone from the game into a set behind the scenes (moved to a specialization not chosen, put away):
            -- edited there, not left as a new one.
            local id = not state.index and not dirty and Window.StoredSetOf(state.name)
            if id then return Load(nil, { id = id, name = state.name }) end
        end
    end
    local saved = state.index and ns.Roles.Text(state.scope, state.name, select(3, GetMacroInfo(state.index)) or "")
    if saved and not IsDirty() and saved ~= state.body then
        return Load(state.index)
    end
    Window.RefreshList()
    UpdateStatus()
end

------------------------------------------------------------------------
-- Look: font, size, scheme
------------------------------------------------------------------------
local function FontList()
    local out = {}
    for _, f in ipairs(ns.fonts) do out[#out + 1] = { key = f.key, name = f.name, path = f.path } end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        for _, name in ipairs(LSM:List("font")) do
            out[#out + 1] = { key = "lsm:" .. name, name = name, path = LSM:Fetch("font", name) }
        end
    end
    return out
end

function Window.ApplyLook()
    local scheme = ns.FindByKey(ns.schemes, ns.db.scheme) or ns.FindByKey(ns.schemes, ns.DEFAULT_SCHEME)
    local font = ns.FindByKey(FontList(), ns.db.font)
    if not font or not code:SetFont(font.path, ns.db.fontSize) then
        font = ns.FindByKey(ns.fonts, ns.DEFAULT_FONT)
        ns.db.font = font.key
        code:SetFont(font.path, ns.db.fontSize)
    end
    ns.ApplyScheme(scheme)
    barInside:SetPoint("BOTTOMRIGHT", 0, scheme.native and NATIVE_EDGE_COVERS or 0)
    code:SetScheme(scheme)
    ns.Popup:Style(scheme, font.path, ns.db.fontSize)
    local tokens = ns.TokenColors(scheme)
    noteColors = { action = tokens.action, unit = tokens.unit, command = tokens.command, text = scheme.text,
        dim = scheme.dim, warning = scheme.warning }
    UpdatePreview()
    if frame:IsShown() then UpdateStatus() end
end

------------------------------------------------------------------------
-- Build
------------------------------------------------------------------------
local function Tab(parent, scope)
    local t = CreateFrame("Button", nil, parent)
    t:SetHeight(26)
    t.label = ns.Text(t, 12)
    t.label:SetPoint("CENTER")
    t.line = t:CreateTexture(nil, "OVERLAY")
    t.line:SetHeight(2)
    t.line:SetPoint("BOTTOMLEFT")
    t.line:SetPoint("BOTTOMRIGHT")
    function t:Paint()
        local s = ns.scheme
        if not s then return end
        self.line:SetColorTexture(ns.RGB(s.accent))
        self.line:SetShown(self.active)
        self.label:SetTextColor(ns.RGB(self.active and s.text or s.dim))
    end
    t:SetScript("OnClick", function() Window.SetScope(scope) end)
    ns.OnStyle(function() t:Paint() end)
    return t
end

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    ns.db.window = { point = point, relPoint = relPoint, x = x, y = y, w = frame:GetWidth(), h = frame:GetHeight() }
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseFrame", UIParent, "BackdropTemplate")
    shared.frame = frame
    table.insert(UISpecialFrames, "MacroSenseFrame") -- Esc closes it
    -- With the game's own windows (bags, the spellbook...): the one clicked last is on top. Below StaticPopup dialogs.
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(MIN_W, MIN_H) else frame:SetMinResize(MIN_W, MIN_H) end
    local pos = ns.db.window
    frame:SetSize(math.max(pos and pos.w or 0, MIN_W), math.max(pos and pos.h or 0, MIN_H))
    frame:SetPoint(pos and pos.point or "CENTER", UIParent, pos and pos.relPoint or "CENTER", pos and pos.x or 0, pos and pos.y or 40)
    frame:EnableMouse(true)
    ns.Backdrop(frame, "bg", "border", true)
    frame:Hide()

    -- Title bar: drag to move.
    local title = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    title:SetPoint("TOPLEFT", 1, -1)
    title:SetPoint("TOPRIGHT", -1, -1)
    title:SetHeight(34)
    ns.Backdrop(title, "panel", "panel")
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() frame:StartMoving() end)
    title:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); SavePosition() end)
    local titleText = ns.Text(title, 14)
    titleText:SetPoint("LEFT", 12, 0)
    titleText:SetText("MacroSense")

    local close = ns.Button(title, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    -- The macro guide (HelpWindow).
    local help = ns.Button(title, "?", 24, function() ns.HelpWindow.Toggle() end)
    help:SetPoint("RIGHT", close, "LEFT", -6, 0)
    help:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(L["Macro guide"], 1, 1, 1)
        GameTooltip:AddLine(L["What macros are, what they can do and how to make them, with ready-made macros."],
            0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    help:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- The language: the texts are made in it, so switching it reloads the interface (asked in the new language).
    local languageDrop = ns.Dropdown(title, 104, function()
        return { { key = "en", name = L["English"] }, { key = "uk", name = L["Ukrainian"] } }
    end, function() return ns.db.language end, function(key)
        ns.db.language = key
        if key ~= ns.language then ns.Ask("MACROSENSE_RELOAD", nil, nil, nil, key) end
    end)
    languageDrop:SetPoint("RIGHT", help, "LEFT", -10, 0)
    languageDrop:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(L["Language"], 1, 1, 1)
        GameTooltip:AddLine(L["The language of MacroSense. The interface reloads to switch it."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    languageDrop:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local schemeDrop = ns.Dropdown(title, 140, function()
        local items = {}
        for i, s in ipairs(ns.schemes) do items[i] = { key = s.key, name = L[s.name] } end
        return items
    end, function() return ns.db.scheme end, function(key) ns.db.scheme = key; Window.ApplyLook() end)
    schemeDrop:SetPoint("RIGHT", languageDrop, "LEFT", -10, 0)

    local size = ns.Stepper(title, 8, 28, function() return ns.db.fontSize end,
        function(v) ns.db.fontSize = v; Window.ApplyLook() end)
    size:SetPoint("RIGHT", schemeDrop, "LEFT", -10, 0)

    local fontDrop = ns.Dropdown(title, 140, FontList, function() return ns.db.font end,
        function(key) ns.db.font = key; Window.ApplyLook() end)
    fontDrop:SetPoint("RIGHT", size, "LEFT", -10, 0)

    -- Live preview on / off, with the other settings of the view.
    local previewCheck = ns.Check(title, L["Live preview"], function() return ns.db.preview end, function(on)
        ns.db.preview = on
        code:ShowNotes(on)
        Window.RefreshWhatIf()
        UpdatePreview()
    end)
    previewCheck:SetPoint("RIGHT", fontDrop, "LEFT", -16, 0)
    previewCheck:HookScript("OnEnter", function(self)
        local keys = IsMacClient and IsMacClient() and L["Shift, Ctrl, Alt or Cmd"] or L["Shift, Ctrl or Alt"]
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(L["Live preview"], 1, 1, 1)
        GameTooltip:AddLine(L["See exactly how the macro will act. Next to each line is what it would do if you "
            .. "pressed the macro now."], 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(string.format(L["Hold %s, point the mouse at someone, change your target. Try everything "
            .. "the macro checks, and you see which ability it uses and when."], keys), 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(L["Point at a line's number or its note to read what the whole line does, in plain "
            .. "words."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    previewCheck:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- Sidebar: tabs, list, buttons.
    side = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    shared.side = side
    side:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
    side:SetPoint("BOTTOMLEFT", 1, 1)
    side:SetWidth(280)
    ns.Backdrop(side, "panel", "panel")

    tabs = { general = Tab(side, "general"), character = Tab(side, "character") }
    shared.tabs = tabs
    tabs.general:SetPoint("TOPLEFT", 0, 0)
    tabs.general:SetPoint("TOPRIGHT", side, "TOP", 0, 0)
    tabs.character:SetPoint("TOPLEFT", side, "TOP", 0, 0)
    tabs.character:SetPoint("TOPRIGHT", 0, 0)

    -- At the bottom: Share / Trash / Backups; New / New (Wizard) over them. Their menus open above them, the list
    -- is in the way below. Each macro in the list has its copy and x buttons.
    local shareBtn = ns.MenuButton(side, L["Share"], 64, shared.ShareItems, true)
    shareBtn:SetPoint("BOTTOMLEFT", 8, 8)
    shareBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Share"], 1, 1, 1)
        GameTooltip:AddLine(L["Share your macros with other players: just pass them the code made for them. Or add "
            .. "someone else's macros to yours, if you have their code."], 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(L["Or link a macro in chat. Whoever has MacroSense gets it with one "
            .. "click."], 0.8, 0.8, 0.8,
            true)
        GameTooltip:Show()
    end)
    shareBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    local trashBtn = ns.MenuButton(side, L["Trash"], 64, shared.TrashItems, true)
    trashBtn:SetPoint("BOTTOM", 0, 8)
    trashBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Trash"], 1, 1, 1)
        GameTooltip:AddLine(string.format(L["Deleted macros land here, and you can bring them back. It doesn't "
            .. "matter where you deleted them: here, in another addon or in the game's macro window. The trash keeps "
            .. "the last %d deleted macros of each tab and deletes older ones by itself."], ns.History.TRASH), 0.8,
            0.8, 0.8, true)
        GameTooltip:Show()
    end)
    trashBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    local backupsBtn = ns.MenuButton(side, L["Backups"], 64, shared.BackupItems, true, true)
    backupsBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    backupsBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Backups"], 1, 1, 1)
        GameTooltip:AddLine(string.format(L["Your macros are saved by themselves the first time you log in each day, "
            .. "if they changed since. You can also make a backup yourself, any time. To get your macros back as "
            .. "they were, just pick a backup. Each character keeps its last %d backups; older ones are deleted by "
            .. "themselves."], ns.Backups.LIMIT), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    backupsBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    local newBtn = ns.Button(side, L["New"], 99, Window.New)
    newBtn:SetPoint("BOTTOMLEFT", 8, 36)

    -- The wizard next to it: a new macro from questions or a form, in a window of its own.
    local wizardBtn = ns.Button(side, L["New (Wizard)"], 99, function() ns.WizardWindow.Toggle(state.scope) end)
    wizardBtn:SetPoint("BOTTOMRIGHT", -8, 36)
    sideRows = { { shareBtn, trashBtn, backupsBtn }, { newBtn, wizardBtn } }
    shared.sideRows = sideRows
    wizardBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["New (Wizard)"], 1, 1, 1)
        GameTooltip:AddLine(L["Create a new macro with the built-in wizard! Answer a few simple questions, or fill "
            .. "in the whole form at once: what to cast and on whom (mouseover, focus, party members, yourself, the "
            .. "cursor...), other spells on Shift, Ctrl or Alt, trinkets and more."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    wizardBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- Over them: macros for the spells of the book, many at once, in a window of their own.
    local bookBtn = ns.Button(side, L["From Spellbook"], 99, function() ns.SpellbookWindow.Toggle() end)
    bookBtn:SetPoint("BOTTOMLEFT", 8, 64)
    bookBtn:SetPoint("BOTTOMRIGHT", -8, 64)
    bookBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Macros from the Spellbook"], 1, 1, 1)
        GameTooltip:AddLine(L["Make macros for the spells in your spellbook, many at once. Pick the spells, where "
            .. "they go and what Shift, Ctrl or Alt do. Spells that have a macro already are left out. Next time, the "
            .. "spells you learned since and those whose macro you deleted are offered."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    bookBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- Over it: macro sets on or off (turning them on asks, and tells what they are), and "Sort by spells".
    setsCheck = ns.Check(side, L["Macro sets"], function() return ns.Sets.Mine().enabled end, function(on)
        if on then return ns.SetsWindow.Open() end
        ns.SetsWindow.AskOff()
    end)
    setsCheck:SetPoint("BOTTOMLEFT", 8, 94)
    -- Over it, while macros are picked: how many, and what to do with them all.
    Window.BuildPicks(side)
    setsCheck:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Macro sets"], 1, 1, 1)
        GameTooltip:AddLine(L["More macros than 30 slots: each specialization gets macros of its own, and they come "
            .. "into the game with it, onto their buttons. Class macros are shared by all your characters of one "
            .. "class."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    setsCheck:HookScript("OnLeave", function() GameTooltip:Hide() end)
    sortBtn = ns.RowButton(side, SORT_ICON, "text", function() end, function() return L["Sort by spells"] end,
        function() ns.SetsWindow.Sort() end)
    shared.sortBtn = sortBtn
    sortBtn:SetPoint("BOTTOMRIGHT", -8, 95)
    sortBtn:SetMotionScriptsWhileDisabled(true)
    sortBtn:HookScript("OnEnter", function(self)
        GameTooltip:AddLine(L["MacroSense looks at the spells each macro casts, and offers to move it: one that works "
            .. "in one specialization only, into that one's set; a specialization's that works in all, to this "
            .. "character's. You see the moves before they are made."], 0.8, 0.8, 0.8, true)
        local unvisited = ns.Sets.Unvisited()
        if #unvisited > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["It can sort once it knows the spells of every specialization: choose each of them "
                .. "at least once."], 1, 0.4, 0.4, true)
            GameTooltip:AddLine(string.format(L["MacroSense learns the spells of each specialization while you play "
                .. "it. Not yet: %s."], table.concat(unvisited, ", ")), 0.6, 0.6, 0.6, true)
        end
        GameTooltip:Show()
    end)

    -- Search under the tabs: Enter opens the first match, Esc clears it.
    search = ns.Input(side, 204, 40, "MacroSenseSearch")
    shared.search = search
    search:SetPoint("TOPLEFT", 8, -32)
    search:SetPoint("TOPRIGHT", -78, -32)
    -- Next to it: find and replace in many macros at once (WindowReplace.lua).
    local replaceBtn = ns.Button(side, L["Replace"], 64, function() Window.OpenReplace() end)
    replaceBtn:SetHeight(24)
    replaceBtn:SetPoint("TOPRIGHT", -8, -32)
    replaceBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Find and replace"], 1, 1, 1)
        GameTooltip:AddLine(L["Changes a word or a spell in many macros at once, in the groups you choose. Each "
            .. "macro's History keeps the text it had."], 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(IsMacClient and IsMacClient() and "Cmd+H" or "Ctrl+H", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    replaceBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    search:SetTextInsets(6, 24, 0, 0)
    local placeholder = ns.Text(search, 12, "dim")
    placeholder:SetPoint("LEFT", 6, 0)
    placeholder:SetText(L["Search name or text"])
    local clear = ns.Button(search, "x", 18, function() search:SetText("") end)
    clear:SetHeight(18)
    clear:SetPoint("RIGHT", -3, 0)
    clear:Hide()
    search:SetScript("OnTextChanged", function(self)
        local empty = self:GetText() == ""
        placeholder:SetShown(empty)
        clear:SetShown(not empty)
        list:SetVerticalScroll(0) -- what it finds from the top: scrolled down, it could be out of sight
        Window.RefreshList()
    end)
    search:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    search:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        -- The first macro found opens (with macro sets on, under the names of the parts).
        for _, r in ipairs(shared.rows) do
            if not r:IsShown() then break end
            if r.what == "macro" then return Window.Select(r.index) end
            if r.what == "stored" then return Window.SelectStored(r.set, r.name) end
        end
    end)

    -- Under it: only the macros on no action bar, to free slots.
    barsCheck = ns.Check(side, L["Not on action bars"], function() return shared.notOnBars end, function(on)
        shared.notOnBars = on
        Window.RefreshList()
    end)
    barsCheck:SetPoint("TOPLEFT", 10, -60)
    barsCheck:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Not on action bars"], 1, 1, 1)
        GameTooltip:AddLine(L["Only the macros you have put on no action bar: handy to free slots. MacroSense "
            .. "remembers the bars of each of your specializations and characters as it last saw them, so a general "
            .. "macro an alt uses counts as used."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    barsCheck:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- And only the macros with a mistake or a warning: all of them checked at once.
    mistakesCheck = ns.Check(side, L["With mistakes"], function() return shared.mistakes end, function(on)
        shared.mistakes = on
        Window.RefreshList()
    end)
    mistakesCheck:SetPoint("TOPLEFT", 10, -84)
    mistakesCheck:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["With mistakes"], 1, 1, 1)
        GameTooltip:AddLine(L["Only the macros with a mistake (red) or a warning (yellow): every macro is checked. "
            .. "The tabs say how many each has. Point at a macro to read what is wrong, click it to fix it."],
            0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    mistakesCheck:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- At its right: checks before the macros and the groups, to pick many at once (WindowPick.lua).
    local pickCheck = ns.Check(side, L["Pick"], function() return Window.IsPicking() end, function(on)
        Window.SetPicking(on)
    end)
    pickCheck:SetPoint("TOPRIGHT", -10, -84)
    shared.pickCheck = pickCheck
    pickCheck:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Pick"], 1, 1, 1)
        GameTooltip:AddLine(L["A check before each macro and each group: one click picks a macro or a whole group, "
            .. "another click takes it back. Then share, move, put into a set or delete them all at once."],
            0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    pickCheck:HookScript("OnLeave", function() GameTooltip:Hide() end)

    list = CreateFrame("ScrollFrame", "MacroSenseListScroll", side)
    shared.list = list
    list:SetPoint("TOPLEFT", 0, -108)
    list:SetPoint("BOTTOMRIGHT", -13, 122)
    ns.AttachScrollBar(list, ROW_H * 3)
    list.child = CreateFrame("Frame", nil, list)
    list.child:SetSize(196, 1)
    list:SetScrollChild(list.child)
    list:SetScript("OnSizeChanged", function(_, w) list.child:SetWidth(w) end)
    altHint = ns.Text(list.child, 11, "dim")
    shared.altHint = altHint
    altHint:SetWordWrap(true)
    altHint:SetText(L["Log in with your other characters once, and their own macros show up here to copy."])
    altHint:Hide()
    noMatch = ns.Text(side, 12, "dim")
    shared.noMatch = noMatch
    noMatch:SetPoint("TOP", list, "TOP", 0, -12)
    noMatch:SetText(L["No macros match"])
    noMatch:Hide()

    -- Header: icon + name.
    local main = CreateFrame("Frame", nil, frame)
    main:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, 0)
    main:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Click the icon to pick another one.
    local iconFrame = CreateFrame("Button", "MacroSenseIconButton", main, "BackdropTemplate")
    iconFrame:SetSize(38, 38)
    iconFrame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    iconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Click: choose an icon"], 1, 1, 1)
        GameTooltip:AddLine(L["Drag: put the macro on an action bar"], 1, 1, 1)
        if iconTex.mark:IsShown() then AddLockNote() end
        if iconTex.hint then AddHintNote() end
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    iconFrame:RegisterForDrag("LeftButton")
    iconFrame:SetScript("OnDragStart", function() Window.Pickup(state.index) end)
    iconFrame:SetScript("OnClick", function()
        if ns.IconPicker.IsShown() then return ns.IconPicker.Close() end
        ns.IconPicker.Open(frame, state.icon, function(icon)
            state.icon = icon
            ShowIcon()
            UpdateStatus()
        end)
    end)
    iconFrame:SetPoint("TOPLEFT", 12, -10)
    ns.Backdrop(iconFrame, "bg", "border")
    iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", 1, -1)
    iconTex:SetPoint("BOTTOMRIGHT", -1, 1)
    iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    iconTex.mark = LockMark(iconFrame, iconTex, 18)

    nameBox = ns.Input(main, 220, 16)
    nameBox:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
    nameBox:SetScript("OnTextChanged", function() UpdateStatus() end)
    -- Tab or Enter: on to the text. The question mark's icon may follow the name (ShowIcon).
    local function NameDone()
        ShowIcon()
        code:SetFocus()
    end
    nameBox:SetScript("OnEnterPressed", NameDone)
    nameBox:SetScript("OnTabPressed", NameDone)

    -- Shorten at the right end of the header.
    shortenBtn = ns.Button(main, L["Shorten"], 90, function() Window.Shorten() end)
    shortenBtn:SetPoint("RIGHT", main, "TOPRIGHT", -12, -29)
    shortenBtn:HookScript("OnEnter", function(self)
        local undo = IsMacClient and IsMacClient() and "Cmd+Z" or "Ctrl+Z"
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(L["Shorten"], 1, 1, 1)
        GameTooltip:AddLine(L["Makes the macro shorter without changing what it does. It removes spaces the game "
            .. "doesn't need and uses shorter ways to write the same thing. For example, target= becomes @, modifier "
            .. "becomes mod, [pet:Imp][pet:Felhunter] becomes [pet:Imp/Felhunter], and [x] Fear; Fear becomes "
            .. "[x][]Fear."], 0.8, 0.8,
            0.8, true)
        GameTooltip:AddLine(self:IsEnabled() and string.format(L["%s brings the old text back."], undo)
            or L["Nothing to shorten here."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    shortenBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- History, left of Shorten: its menu opens under it, lined up on the right.
    historyBtn = ns.MenuButton(main, L["History"], 80, HistoryItems, false, true)
    historyBtn:SetPoint("RIGHT", shortenBtn, "LEFT", -8, 0)
    historyBtn:HookScript("OnEnter", function(self)
        local undo = IsMacClient and IsMacClient() and "Cmd+Z" or "Ctrl+Z"
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(L["History"], 1, 1, 1)
        if self:IsEnabled() then
            GameTooltip:AddLine(string.format(L["Earlier saved versions of this macro. Pick one, and it goes into "
                .. "the editor. Save keeps it, and %s takes it back."], undo), 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine(L["Each time you save a change to this macro, here or in the game's macro window, "
                .. "the text it had before is kept here."], 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    historyBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- Open in Wizard, left of History: one word, as its neighbours, so the row fits the narrowest window.
    wizardEditBtn = ns.Button(main, L["Wizard"], 80, function() Window.OpenInWizard() end)
    wizardEditBtn:SetPoint("RIGHT", historyBtn, "LEFT", -8, 0)
    wizardEditBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(L["Open in Wizard"], 1, 1, 1)
        local read, lost = ns.Wizard.Read(code:GetRaw())
        if not read then
            GameTooltip:AddLine(L["The wizard can't read this macro. It makes macros that cast a spell, use an item, "
                .. "target someone, command your pet, summon a mount or put on gear."], 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine(L["Opens this macro in the wizard, so you can change it with a few clicks. The new "
                .. "text comes back here, and Save keeps it."], 0.8, 0.8, 0.8, true)
            if #lost > 0 then
                GameTooltip:AddLine(ns.Plural(#lost, "%d line will come out different or be left out.",
                    "%d lines will come out different or be left out."), 1, 0.82, 0, true)
            end
        end
        GameTooltip:Show()
    end)
    wizardEditBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local nameHint = ns.Text(main, 11, "dim")
    nameHint:SetPoint("LEFT", nameBox, "RIGHT", 10, 0)
    nameHint:SetText(L["click or drag the icon"])
    nameHint:SetPoint("RIGHT", wizardEditBtn, "LEFT", -12, 0)
    nameHint:SetWordWrap(false)
    -- No room for it in a narrow window.
    main:HookScript("OnSizeChanged", function(_, w) nameHint:SetShown(w >= 680) end)

    -- Status bar: position, length, Save / Revert.
    local bar = CreateFrame("Frame", nil, main, "BackdropTemplate")
    bar:SetPoint("BOTTOMLEFT")
    bar:SetPoint("BOTTOMRIGHT")
    bar:SetHeight(36)
    ns.Backdrop(bar, "panel", "panel")
    barInside = CreateFrame("Frame", nil, bar)
    barInside:SetPoint("TOPLEFT")
    barInside:SetPoint("BOTTOMRIGHT")
    saveBtn = ns.Button(bar, L["Save"], 90, Window.Save, true)
    saveBtn.alert = saveBtn:CreateTexture(nil, "OVERLAY")
    saveBtn.alert:SetSize(16, 16)
    saveBtn.alert:SetPoint("RIGHT", saveBtn.label, "LEFT", -4, 0)
    saveBtn.alert:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew") -- triangle with "!"
    saveBtn.alert:Hide()
    saveBtn:HookScript("OnEnter", function(self)
        if not self.alert:IsShown() then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["The macro has syntax errors"], 1, 0.3, 0.3)
        GameTooltip:AddLine(L["It can still be saved."], 1, 1, 1)
        GameTooltip:Show()
    end)
    saveBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    saveBtn:SetPoint("RIGHT", barInside, "RIGHT", -12, 0) -- under Shorten
    revertBtn = ns.Button(bar, L["Revert"], 90, Window.Revert)
    revertBtn:SetPoint("RIGHT", saveBtn, "LEFT", -6, 0)
    counter = ns.Text(bar, 11, "dim")
    counter:SetPoint("LEFT", barInside, "LEFT", 12, 0)
    dirtyDot = bar:CreateTexture(nil, "OVERLAY")
    dirtyDot:SetSize(8, 8)
    dirtyDot:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask") -- white circle
    dirtyDot:SetPoint("LEFT", counter, "RIGHT", 24, 0)
    status = ns.Text(bar, 11, "text")
    status:SetPoint("LEFT", dirtyDot, "RIGHT", 6, 0)
    -- Errors / warnings use the room between the status and Revert, cut short when too long.
    warning = ns.Text(bar, 11, "text")
    shared.warning = warning
    warning:SetPoint("LEFT", status, "RIGHT", 16, 0)
    warning:SetPoint("RIGHT", revertBtn, "LEFT", -12, 0)
    warning:SetJustifyH("RIGHT")
    warning:SetWordWrap(false)
    -- Hover: every error in full, and the macOS warning.
    local warningHover = CreateFrame("Frame", nil, bar)
    warningHover:SetAllPoints(warning)
    warningHover:EnableMouse(true)
    warningHover:SetScript("OnEnter", function(self)
        local errors, message = warning.errors or {}, warning.message
        if #errors == 0 and not message then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        AddIssueLines(errors)
        if message then GameTooltip:AddLine(message, 1, 0.82, 0) end
        if warning.shown then
            TipLine(string.format(L["Click to go to line %d"], warning.shown.line), "66ff66")
        end
        if warning.shown and warning.shown.fix then
            TipLine(warning.shown.fixTip or string.format(L["Ctrl+click to use \"%s\""], warning.shown.fix), "66ff66")
        end
        GameTooltip:Show()
    end)
    warningHover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Click: go to the issue; with Ctrl (Cmd on a Mac too), its fix (a suggestion for a misspelled name, ...).
    warningHover:SetScript("OnMouseUp", function()
        local e = warning.shown
        if not e then return end
        GameTooltip:Hide()
        if e.fix and ns.CtrlDown() then return ApplyFix(e) end
        code:SetRawCursor(e.from - 1)
    end)

    -- Editor.
    local editorBg = CreateFrame("Frame", nil, main, "BackdropTemplate")
    editorBg:SetPoint("TOPLEFT", 12, -58)
    editorBg:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -12, 10)
    ns.Backdrop(editorBg, "bg", "border")
    -- Over the status bar with Live preview on: "What if" (WindowWhatIf.lua). The editor ends over it.
    Window.BuildWhatIf(main, editorBg, bar)
    code = ns.CreateCodeBox(editorBg, "MacroSenseCodeScroll")
    code.scroll:SetPoint("TOPLEFT", 4, -4)
    code.scroll:SetPoint("BOTTOMRIGHT", -15, 4)
    ns.AttachAutocomplete(code)
    code:ShowNotes(ns.db.preview)
    -- Ctrl+click (Cmd+click on a Mac) on an issue that has a fix: fixed, as from the status bar.
    code.onFixClick = function(pos)
        local e = FixAt(pos)
        if not e then return false end
        GameTooltip:Hide()
        ApplyFix(e)
        return true
    end
    -- A spell, mount or item dropped on the text: its name, as the game's macro window takes it.
    code.onDrop = function()
        local name, command = OnCursor()
        if not name then return end
        ClearCursor()
        PutName(name, command)
    end
    -- Shift-click on a spell or item while the text has the focus: its name, as the game's macro window does.
    local lastLink
    local function linked(link)
        if not (code.edit:HasFocus() and type(link) == "string") or lastLink == link .. GetTime() then return end
        lastLink = link .. GetTime() -- the game may pass one link through both functions
        local name = link:match("|h%[(.-)%]|h")
        local kind = link:match("|H(%a+):")
        if name and (kind == "spell" or kind == "item" or kind == "mount") then
            PutName(name, kind == "item" and "/use" or "/cast")
        end
    end
    if ChatEdit_InsertLink then hooksecurefunc("ChatEdit_InsertLink", linked) end
    if ChatFrameUtil and ChatFrameUtil.InsertLink then hooksecurefunc(ChatFrameUtil, "InsertLink", linked) end
    -- Issues are found a frame after each change: the status bar, the preview and a new macro's icon follow them.
    code.onErrors = function()
        ShowIcon()
        UpdateStatus()
        UpdatePreview()
    end
    -- Our own status bar follows text and cursor changes (Autocomplete owns onChange / onCaret).
    code.edit:HookScript("OnTextChanged", UpdateStatus)
    code.edit:HookScript("OnCursorChanged", UpdateStatus)
    code.edit:HookScript("OnKeyDown", function(_, key)
        if not ns.CtrlDown() then return end
        if key == "S" then
            Window.Save()
        elseif key == "F" then
            search:SetFocus()
            search:HighlightText()
        elseif key == "H" then
            Window.OpenReplace()
        end
    end)

    -- Resize grip above the status bar (it used to hide the grip).
    ns.ResizeGrip(frame, SavePosition)

    frame:SetScript("OnShow", function()
        languageDrop:Refresh()
        fontDrop:Refresh()
        size:Refresh()
        schemeDrop:Refresh()
        Window.RefreshList()
        UpdateStatus()
    end)
    frame:SetScript("OnHide", function()
        ns.Popup:Hide()
        ns.IconPicker.Close()
        ns.WizardWindow.Close()
        ns.ShareWindow.Close()
        if MacroSenseReplace then MacroSenseReplace:Hide() end
        ns.CloseMenu()
        search:SetText("") -- opened again, the list shows every macro
        shared.notOnBars, shared.mistakes = false, false
        Window.ForgetPicks()
        shared.pickCheck:Refresh()
        barsCheck:Refresh()
        mistakesCheck:Refresh()
    end)
    -- The preview also follows the game: modifiers held, target, mouseover, pet, combat.
    local sincePreview = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        sincePreview = sincePreview + elapsed
        if sincePreview < PREVIEW_EVERY then return end
        sincePreview = 0
        UpdatePreview()
        ShowIcon()
        shared.FollowRowIcons()
        UpdateExplain()
    end)
    -- After OnShow and OnHide are set: it hooks them.
    ns.Easter.Attach(frame, shortenBtn)

    Window.ApplyLook()
end

-- The look (the color scheme, the font) comes with the editor's window: a window opened before it (/ms book,
-- /ms help) has it built first, hidden.
function Window.Ready()
    if not frame then Build() end
end

function Window.Toggle()
    if not frame then Build() end
    if frame:IsShown() then return frame:Hide() end
    state.scope = ns.db.scope or "general"
    frame:Show()
    if IsDirty() then return end
    if state.stored and state.stored.name then return Load(nil, state.stored) end
    -- Reload: the macro may have changed in the Blizzard UI while we were closed.
    local index = state.name and state.name ~= "" and GetMacroIndexByName(state.name)
    if index and index > 0 then return Load(index) end
    local first, last = MacroRange(state.scope)
    Load(last >= first and first or nil)
end

-- The editor on macro `index`, opened if it is closed (Shift + right-click on an action bar). Unsaved changes
-- to another macro are asked about first; the macro's own stay. Below Build, like Toggle: it may build the
-- window, and a local function is only seen after it.
-- The guide's buttons (HelpWindow): the editor shown, then a new macro, or one made from `body` in the tab that
-- is open, under a free name.
function Window.Make(name, body)
    if not frame then Build() end
    frame:Show()
    if not body then return Window.New() end
    Window.Import({ { scope = state.scope, name = name, icon = "", body = body } })
end

function Window.Open(index)
    if not frame then Build() end
    frame:Show()
    frame:Raise()
    if index == state.index and IsDirty() then return end
    Guard(function()
        state.scope = index > MAX_GENERAL and "character" or "general"
        ns.db.scope = state.scope
        Load(index)
    end)
end
