-- The MacroSense window: macro list on the left, editor on the right. Macros are the game's own
-- (CreateMacro / EditMacro), so everything stays in sync with the Blizzard macro UI.
local _, ns = ...
local L = ns.L

local MAX_GENERAL, MAX_CHARACTER = ns.MAX_GENERAL, ns.MAX_CHARACTER
local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local MAX_NAME = 16 -- letters, as in the Blizzard macro window
local NEW_ICON = 134400 -- question mark: #showtooltip picks the icon
local NEW_BODY = "#showtooltip\n" -- a new macro starts with it, the cursor on the line below
local COPY_ICON = "Interface\\AddOns\\MacroSense\\Media\\copy"
local SORT_ICON = "Interface\\AddOns\\MacroSense\\Media\\sort"
local NO_ICON = "Interface\\AddOns\\MacroSense\\Media\\no" -- dragged where it can't go
local PLUS_ICON = "Interface\\AddOns\\MacroSense\\Media\\plus" -- dragged with Ctrl: a copy
local ROW_H = 24
local MIN_W, MIN_H = 780, 460 -- also the first size
local PREVIEW_EVERY = 0.1 -- seconds: modifiers, target, mouseover and pet change any time

local Window = {}
ns.Window = Window

-- What is being edited: scope "general" | "character", index (nil = new macro), name/body/savedIcon as saved,
-- icon = the icon picked now. With macro sets on, `stored`: one behind the scenes, { id = its set, name } (no name:
-- a new one there).
local state = { scope = "general", icon = NEW_ICON, savedIcon = NEW_ICON }
local frame, list, nameBox, iconTex, code, status, dirtyDot, warning, counter, saveBtn, revertBtn, tabs
local side -- the sidebar: wider with macro sets on, for the Character tab's count of those behind the scenes
local sideRows -- its buttons at the bottom, by row: they share its width
local setsCheck, sortBtn -- macro sets on or off; "Sort by spells", with them on
local barInside -- the status bar's part not under the window's border: what it shows is centered in it
local NATIVE_EDGE_COVERS = 6 -- how much of the status bar the game's window border covers (the In-game scheme)
local shortenBtn, historyBtn, wizardEditBtn, search, noMatch, barsCheck, altHint
local notOnBars = false -- the list shows only the macros on no action bar
local expanded = {} -- the other characters whose macros the Character tab shows, by key
local groupOpen = {} -- the groups opened or closed: "in", "out", and those under them by "in:" or "out:" and the set
local PLUS, MINUS = "Interface\\Buttons\\UI-PlusButton-Up", "Interface\\Buttons\\UI-MinusButton-Up"
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
    if not state.index and not (state.stored and state.stored.name) then
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
            onEnter = function(row)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(When(v.time), 1, 1, 1)
                for line in (v.body .. "\n"):gmatch("([^\n]*)\n") do
                    -- "|" would start a color code in the tooltip: shown as typed.
                    GameTooltip:AddLine(line ~= "" and line:gsub("|", "||") or " ", 0.8, 0.8, 0.8, true)
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
local function AddIssueLines(issues)
    for _, e in ipairs(issues) do
        local r, g, b = 1, 0.35, 0.35
        if e.severity == "warning" then r, g, b = 1, 0.82, 0 end
        GameTooltip:AddLine(string.format(L["Line %d: %s"], e.line, e.message), r, g, b)
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
    dirtyDot:SetShown(dirty and letters <= MAX_BODY)
    dirtyDot:SetVertexColor(ns.RGB(s.accent))
    if letters > MAX_BODY then
        status:SetText("|cff" .. s.invalid .. string.format(L["Macro is longer than %d characters"], MAX_BODY) .. "|r")
    elseif dirty then
        status:SetText(L["Unsaved changes"])
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
    local results = ns.Preview.Evaluate(ns.Roles.Fill(code:GetRaw()), ns.previewEnv, skip)
    local notes = {}
    for i = 1, results.n do notes[i] = ns.Preview.Note(results[i], noteColors) end
    code:SetLineNotes(notes)
end

------------------------------------------------------------------------
-- Explained: over a line's number or note, the tooltip says in plain words what the line does, every branch
------------------------------------------------------------------------
local explained -- what the tooltip explains now: the line's number and the text

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
    local spell = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(name)
    local id = spell and spell.spellID or (GetSpellInfo and select(7, GetSpellInfo(name)))
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
    local text = n and select(n, (raw .. "\n"):match(string.rep("([^\n]*)\n", n)))
    local lines = text and ns.Explain.Line(text, explainEnv)
    if not lines then
        if not WordTip(raw, pos) and GameTooltip:GetOwner() == code.scroll then GameTooltip:Hide() end
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
-- Macro list
------------------------------------------------------------------------
local rows = {}

-- Issues of a saved macro: the worst severity ("error", "warning" or nil) and the issues themselves.
local function MacroIssues(body)
    local issues, worst = ns.Highlight.Errors(body or ""), nil
    for _, e in ipairs(issues) do
        worst = "warning"
        if e.severity == "error" then
            worst = "error"
            break
        end
    end
    return worst, issues
end

-- Where macro `name` of tab `scope` is on the action bars, for its tooltip.
local function AddBarsLines(scope, name)
    local here, elsewhere = ns.ActionBars.Uses(scope, name)
    local now = here > 0 and ns.Plural(here, "On %d button of your action bars", "On %d buttons of your action bars")
    GameTooltip:AddLine(now or L["Not on your action bars now"], 0.6, 0.6, 0.6)
    if #elsewhere > 0 then
        GameTooltip:AddLine(string.format(L["On the bars of %s"], table.concat(elsewhere, ", ")), 0.6, 0.6, 0.6, true)
    end
end

-- What deleting or moving macro `name` of tab `scope` takes from the action bars, for its question: "" or sentences.
local function BarsNote(scope, name)
    local here, elsewhere = ns.ActionBars.Uses(scope, name)
    local out = {}
    if here > 0 then
        out[#out + 1] = ns.Plural(here, "It is on %d button of your action bars.",
            "It is on %d buttons of your action bars.")
    end
    if #elsewhere > 0 then
        local places = table.concat(elsewhere, ", ")
        out[#out + 1] = string.format(here > 0 and L["It is on the bars of %s too."] or L["It is on the bars of %s."],
            places)
    end
    return #out > 0 and "\n\n" .. table.concat(out, " ") or ""
end

------------------------------------------------------------------------
-- Other characters' macros: kept as they were when you last played each one (History.Scan), shown in the
-- Character tab under their names, to copy
------------------------------------------------------------------------
-- { key, c, label = name (with its realm when not yours), same = your realm, color = its class's, macros = sorted
-- { name, icon, body } }, your realm's first.
local function Alts()
    local out, mine = {}, ns.Character()
    for key, c in pairs(ns.db.characters or {}) do
        if c ~= mine and c.macros and next(c.macros) then
            local macros = {}
            for name, m in pairs(c.macros) do macros[#macros + 1] = { name = name, icon = m.icon, body = m.body or "" } end
            table.sort(macros, function(a, b) return a.name < b.name end)
            local same = c.realm == mine.realm
            out[#out + 1] = { key = key, c = c, macros = macros, same = same,
                label = same and c.name or (c.name .. "-" .. c.realm),
                color = RAID_CLASS_COLORS and c.class and RAID_CLASS_COLORS[c.class] }
        end
    end
    table.sort(out, function(a, b)
        if a.same ~= b.same then return a.same end
        return a.label < b.label
    end)
    return out
end

-- A menu item that makes a macro in tab `scope`, unless it is full.
local function TabItem(scope, label, tip, onClick)
    local first, last, max = MacroRange(scope)
    local full = last - first + 1 >= max
    return {
        name = full and string.format("%s  |cff%s%s|r", label, ns.scheme.dim, L["(full)"]) or label,
        disabled = full,
        onClick = onClick,
        onEnter = function(row)
            GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
            GameTooltip:AddLine(label, 1, 1, 1)
            GameTooltip:AddLine(full and string.format(L["The %s tab is full."], TabName(scope)) or tip, 0.8, 0.8, 0.8,
                true)
            GameTooltip:Show()
        end,
    }
end

-- The copy menu of another character's macro `m`: into this character's tab or General.
local function OpenAltCopyMenu(owner, m)
    ns.OpenMenu(owner, {
        TabItem("character", L["Copy to Character"], L["Makes a copy for this character only, named like \"Fear "
            .. "2\"."], function() Window.CopyIn("character", m) end),
        TabItem("general", L["Copy to General"], L["Makes a copy for all your characters, named like \"Fear "
            .. "2\"."], function() Window.CopyIn("general", m) end),
    }, 180, false, true)
end

local function AddAltLines(alt)
    local color = alt.color
    GameTooltip:AddLine(alt.label, color and color.r or 1, color and color.g or 1, color and color.b or 1)
    GameTooltip:AddLine(string.format(L["Its own macros, as they were when you last played it: %s. Click to show or "
        .. "hide them."], When(alt.c.seen or 0)), 0.8, 0.8, 0.8, true)
end

local function AddAltMacroLines(alt, m)
    GameTooltip:AddLine(m.name, 1, 1, 1)
    GameTooltip:AddLine(string.format(L["A macro of %s. Click to copy it."], alt.label), 0.8, 0.8, 0.8, true)
    for line in (m.body .. "\n"):gmatch("([^\n]*)\n") do
        GameTooltip:AddLine(line ~= "" and line:gsub("|", "||") or " ", 0.6, 0.6, 0.6, true)
    end
end

StaticPopupDialogs.MACROSENSE_FORGET_CHARACTER = {
    text = "Forget %s? MacroSense no longer shows its macros or counts its action bars, until you log in with it "
        .. "again.",
    button1 = "Forget", button2 = "Cancel",
    OnAccept = function(_, key)
        ns.db.characters[key] = nil
        Window.RefreshList()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- A row of the list is one of this tab's macros ("macro"), another character ("alt", its macros under it) or one
-- of that character's macros ("altMacro").
local function Row(i)
    local r = CreateFrame("Button", nil, list.child)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.band = r:CreateTexture(nil, "BACKGROUND", nil, -1) -- a specialization's group not chosen now: red
    r.band:SetAllPoints()
    r.band:Hide()
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(ROW_H - 4, ROW_H - 4)
    r.icon:SetPoint("LEFT", 6, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.mark = LockMark(r, r.icon, 14)
    -- What opens and closes (a part, a group, another character): + or -, the game's button in its look, else a
    -- box drawn in the scheme's colors.
    r.sign = {}
    for _, part in ipairs({ "edge", "inside", "across", "down" }) do
        r.sign[part] = r:CreateTexture(nil, "OVERLAY", nil, part == "edge" and 0 or part == "inside" and 1 or 2)
        r.sign[part]:SetPoint("CENTER", r.icon, "CENTER")
        r.sign[part]:Hide()
    end
    r.sign.edge:SetSize(12, 12)
    r.sign.inside:SetSize(10, 10)
    r.sign.across:SetSize(6, 2)
    r.sign.down:SetSize(2, 6)
    function r:Toggle(open)
        self.toggle, self.open = true, open
        self:Paint()
    end
    r.text = ns.Text(r, 12)
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
    r.text:SetPoint("RIGHT", -6, 0)
    r.text:SetWordWrap(false)
    -- Lit under the mouse, faintly: the selected row is lit already.
    local function lit(on)
        if on and not r.selected then r.bg:SetAlpha(0.4); r.bg:Show() end
        if not on then r.bg:SetShown(r.selected); r.bg:SetAlpha(1) end
    end
    -- At the end: copy (a menu: this tab or the other one) and x (delete, after asking). Another character has an x
    -- (forget it), its macros a copy button.
    r.remove = ns.RowButton(r, "x", "invalid", lit, function()
        return r.what == "alt" and L["Forget this character"] or L["Delete this macro"]
    end, function()
        if r.what == "alt" then return ns.Ask("MACROSENSE_FORGET_CHARACTER", r.alt.label, nil, r.alt.key) end
        if r.what == "stored" then
            return ns.Ask("MACROSENSE_DELETE", r.name, "", { stored = { id = r.set, name = r.name } })
        end
        local m = { index = r.index, name = r.name, scope = r.scope }
        ns.Ask("MACROSENSE_DELETE", r.name, BarsNote(r.scope, r.name), m)
    end)
    r.remove:SetPoint("RIGHT", -2, 0)
    r.copy = ns.RowButton(r, COPY_ICON, "text", lit, function() return L["Copy this macro"] end, function()
        if r.what == "altMacro" then return OpenAltCopyMenu(r.copy, r.macro) end
        Window.OpenCopyMenu(r.copy, r.index)
    end)
    r.copy:SetPoint("RIGHT", r.remove, "LEFT")
    -- With macro sets on: "...", what can be done with it in the sets (a right click too).
    r.more = ns.RowButton(r, "...", "text", lit, function() return L["Macro sets"] end, function()
        Window.OpenSetsMenu(r.more, r)
    end)
    -- A macro with errors gets the alert sign, as on Save.
    r.alert = r:CreateTexture(nil, "OVERLAY")
    r.alert:SetSize(14, 14)
    r.alert:SetPoint("RIGHT", r.copy, "LEFT", -2, 0)
    r.alert:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    r.alert:Hide()
    -- Hover: the issues, line by line, and where it is on the action bars; another character's macro: its text.
    r:SetScript("OnEnter", function()
        lit(true)
        if Window.dragging then return end -- a macro dragged over it: its own tooltip says what letting go does
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        if r.what == "alt" then
            AddAltLines(r.alt)
        elseif r.what == "altMacro" then
            AddAltMacroLines(r.alt, r.macro)
        elseif r.what == "head" or r.what == "group" then
            GameTooltip:AddLine(r.name, 1, 1, 1)
            GameTooltip:AddLine(r.tip, 0.8, 0.8, 0.8, true)
        elseif r.what == "stored" then
            GameTooltip:AddLine(r.name, 1, 1, 1)
            AddIssueLines(r.issues or {})
            GameTooltip:AddLine(L["Behind the scenes: not in the game now, and on no slot."], 0.6, 0.6, 0.6, true)
            Window.AddSetsNote(r)
        else
            GameTooltip:AddLine(r.text:GetText(), 1, 1, 1)
            AddIssueLines(r.issues or {})
            AddBarsLines(r.scope, r.name)
            Window.AddSetsNote(r)
        end
        if r.mark:IsShown() then AddLockNote() end
        if r.icon.hint then AddHintNote() end
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function()
        lit(false)
        if not Window.dragging then GameTooltip:Hide() end
    end)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            if r.more:IsShown() then Window.OpenSetsMenu(r, r) end
            return
        end
        if r.what == "alt" then
            expanded[r.alt.key] = not expanded[r.alt.key]
            return Window.RefreshList()
        end
        if r.what == "group" or r.what == "head" then
            groupOpen[r.group] = not r.open
            return Window.RefreshList()
        end
        if r.what == "stored" then return Window.SelectStored(r.set, r.name) end
        -- Shift-click links the macro in chat, as an item is linked: into the message being typed, or a new one,
        -- wherever the cursor is.
        if IsShiftKeyDown() and ChatFrameUtil then
            if r.what == "altMacro" then
                return ns.Links.Insert({ scope = "character", name = r.macro.name, icon = r.macro.icon,
                    body = r.macro.body or "" })
            end
            local name, _, body = GetMacroInfo(r.index)
            return ns.Links.Insert({ scope = r.scope, name = name, icon = ns.MacroIcon(r.index), body = body or "" })
        end
        if r.what == "altMacro" then return OpenAltCopyMenu(r, r.macro) end
        Window.Select(r.index)
    end)
    -- Drag a macro onto an action bar, like in the Blizzard macro window.
    r:RegisterForDrag("LeftButton")
    -- With macro sets on, also anywhere in the list: into another set, in the game or behind the scenes.
    r:SetScript("OnDragStart", function()
        if r.what == "macro" then Window.Pickup(r.index) end
        if r.set then Window.dragging, Window.copying = r, IsControlKeyDown() end
        -- Behind the scenes, the game puts nothing on the cursor: its icon and name follow the mouse instead.
        if r.what == "stored" then Window.ShowGhost(r) end
        if r.set then Window.Watch() end
    end)
    r:SetScript("OnDragStop", function()
        Window.HideGhost()
        Window.DragOver(nil)
        if Window.dragging ~= r then return end
        Window.dragging = nil
        for _, target in ipairs(rows) do
            if target:IsShown() and target:IsMouseOver() then
                return Window.Drop(r, target, Window.copying or IsControlKeyDown())
            end
        end
    end)
    -- The name is red with errors, yellow with warnings only; another character's in its class color, its macros dim.
    function r:Paint()
        local s = ns.scheme
        if not s then return end
        self.bg:SetColorTexture(ns.RGB(s.selection))
        local color = self.severity == "error" and s.invalid or self.severity == "warning" and s.warning or s.text
        self.text:SetTextColor(ns.RGB((self.what == "altMacro" or self.what == "head") and s.dim or color))
        -- A set's group, its name and its macros: the class's yellow, the specialization now's green, another red.
        local tone = self.tone == "class" and { ns.RGB(s.warning) } or self.tone == "now" and { 0.3, 0.75, 0.3 }
            or self.tone == "other" and { ns.RGB(s.invalid) }
        local strong = self.what == "group" or self.what == "head"
        if tone then self.band:SetColorTexture(tone[1], tone[2], tone[3], strong and 0.3 or 0.14) end
        self.band:SetShown(tone and true or false)
        -- + or -.
        local sign = self.toggle and not s.native
        if self.toggle and s.native then
            self.icon:SetTexture(self.open and MINUS or PLUS)
        elseif sign then
            self.icon:SetTexture(nil)
            self.sign.edge:SetColorTexture(ns.RGB(s.dim))
            self.sign.inside:SetColorTexture(ns.RGB(s.panel))
            self.sign.across:SetColorTexture(ns.RGB(s.text))
            self.sign.down:SetColorTexture(ns.RGB(s.text))
        end
        for part, t in pairs(self.sign) do t:SetShown(sign and (part ~= "down" or not self.open) or false) end
        local class = self.what == "alt" and self.alt.color
        if class then self.text:SetTextColor(class.r, class.g, class.b) end
    end
    ns.OnStyle(function() r:Paint() end)
    return r
end

-- Search: a macro matches by its name or its text, in any case.
local function Query() return strtrim(search:GetText() or ""):lower() end

local function Matches(q, name, body)
    return q == "" or name:lower():find(q, 1, true) ~= nil or (body or ""):lower():find(q, 1, true) ~= nil
end

-- What the list shows: the macros the search matches, and with "Not on action bars" only those on no bar, of
-- this character's specializations and, for a general macro, of your other characters as last seen.
local function Shown(q, scope, name, body)
    if not Matches(q, name, body) then return false end
    if not notOnBars then return true end
    local here, elsewhere = ns.ActionBars.Uses(scope, name)
    return here == 0 and #elsewhere == 0
end

local function CountMatches(scope, q)
    local first, last = MacroRange(scope)
    local n = 0
    for index = first, last do
        local name, _, body = GetMacroInfo(index)
        if name and Shown(q, scope, name, body) then n = n + 1 end
    end
    return n
end

-- Row `n` of the list as a row of `what` (see Row), not selected, without marks; `tone`: in a set's group, its color
-- (see Paint); `depth`: how deep under the names of what it is in, each step further right (a character's macros
-- under its name: one).
local function UseRow(n, what, tone, depth)
    rows[n] = rows[n] or Row(n)
    local r = rows[n]
    r.what, r.index, r.selected, r.severity, r.issues = what, nil, false, nil, nil
    r.tone, r.toggle, r.set, r.dropId, r.dropIn = tone, false, nil, nil, nil
    r.icon:SetPoint("LEFT", 6 + 12 * (depth or (what == "altMacro" and 1 or 0)), 0)
    local plain = what == "alt" or what == "group" or what == "head"
    if plain then r.icon:SetTexCoord(0, 1, 0, 1) else r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    r.band:Hide()
    r.copy:SetShown(what == "macro" or what == "altMacro")
    r.remove:SetShown(what == "macro" or what == "alt" or what == "stored")
    r.more:Hide() -- shown for a set's macro (see Belongs)
    r.alert:ClearAllPoints()
    r.alert:SetPoint("RIGHT", r.copy, "LEFT", -2, 0)
    r.alert:Hide()
    r.mark:Hide()
    r.auto = false
    r.icon:SetDesaturated(false)
    r.icon.hint = false
    r.text:ClearAllPoints()
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
    if what == "group" or what == "head" then
        r.text:SetPoint("RIGHT", -6, 0)
    else
        r.text:SetPoint("RIGHT", (what == "alt" or what == "stored") and r.remove or r.copy, "LEFT", -2, 0)
    end
    r.bg:Hide()
    r.bg:SetAlpha(1)
    r:Show()
    return r
end

-- The Character tab also has your other characters' macros, under their names: a click shows them, a search shows
-- those it finds. Returns the number of rows used then.
local function AltRows(n, q)
    local alts = Alts()
    for _, alt in ipairs(alts) do
        local found = {}
        for _, m in ipairs(alt.macros) do
            if Matches(q, m.name, m.body) then found[#found + 1] = m end
        end
        if q == "" or #found > 0 then
            local open = q ~= "" or expanded[alt.key]
            n = n + 1
            local r = UseRow(n, "alt")
            r.alt, r.name = alt, alt.label
            r:Toggle(open)
            r.text:SetText(string.format("%s  |cff%s%d|r", alt.label, ns.scheme.dim, #alt.macros))
            r:Paint()
            for _, m in ipairs(open and found or {}) do
                n = n + 1
                r = UseRow(n, "altMacro")
                r.alt, r.macro, r.name = alt, m, m.name
                local auto = m.icon == NEW_ICON
                ShowFound(r.icon, auto and FoundIcon(m.body, nil, m.name) or m.icon, false)
                r.mark:SetShown(Locked(m.icon, m.body))
                r.text:SetText(m.name)
                r:Paint()
            end
        end
    end
    -- None known yet: they show once you play them with MacroSense.
    altHint:ClearAllPoints()
    altHint:SetPoint("TOPLEFT", 8, -n * ROW_H - 6)
    altHint:SetPoint("TOPRIGHT", -8, -n * ROW_H - 6)
    altHint:SetShown(#alts == 0 and q == "")
    return n
end

-- The list's macros with the question mark follow the game's icon too (a key held), as the header does.
local function FollowRowIcons()
    for _, r in ipairs(rows) do
        if r:IsShown() and r.what == "macro" and r.auto then
            local name, _, body = GetMacroInfo(r.index)
            if name then ShowFound(r.icon, FoundIcon(body, r.index, name)) end
        end
    end
end

-- Row `n` as macro `index` of the tab open; `tone`, `depth`: see UseRow.
local function MacroRow(n, index, tone, depth)
    local name, icon, body = GetMacroInfo(index)
    local r = UseRow(n, "macro", tone, depth)
    r.index, r.name, r.scope, r.selected = index, name, state.scope, index == state.index
    local chosen = ns.MacroIcon(index)
    r.auto = chosen == NEW_ICON
    if r.auto then ShowFound(r.icon, FoundIcon(body, index, name)) else ShowFound(r.icon, icon, false) end
    r.mark:SetShown(Locked(chosen, body))
    r.text:SetText(name)
    -- Marks follow the saved text: the one being edited shows its issues in the editor.
    r.severity, r.issues = MacroIssues(body)
    local alert = r.severity == "error"
    r.alert:SetShown(alert)
    r.text:SetPoint("RIGHT", alert and r.alert or r.copy, "LEFT", alert and -4 or -2, 0)
    r:Paint()
    r.bg:SetShown(r.selected)
end

------------------------------------------------------------------------
-- Macro sets on: the Character tab has all the macros, those in the game and those behind the scenes, each part
-- with the character's first, then the class's in a group, then each specialization's. In the game the class's
-- group is yellow, the specialization now's green; behind the scenes all is red, another specialization's group
-- closed till you open it. Each part and group opens and closes with a click.
------------------------------------------------------------------------
local function SetsShown()
    return state.scope == "character" and ns.Sets.Mine().enabled
end

-- Opened or closed: as you left it; searching, open; else as `default`.
local function IsOpen(key, default, q)
    if q ~= "" then return true end
    if groupOpen[key] ~= nil then return groupOpen[key] end
    return default
end

local function HeadRow(n, key, label, tip, open, tone)
    local r = UseRow(n, "head", tone)
    r.group, r.open, r.name, r.tip = key, open, label, tip
    r:Toggle(open)
    r.text:SetText(label)
    r:Paint()
end

-- `tone`: "class", "now" or "other" (see Paint); `kind`: the same, what the group is (its tooltip).
local function GroupRow(n, key, label, count, tone, open, kind)
    local r = UseRow(n, "group", tone, 1)
    r.group, r.open, r.name = key, open, label
    r.tip = kind == "class" and L["The same on all your characters of this class: what you change here reaches the "
        .. "others when they log in."] or kind == "now" and L["The macros of the specialization chosen now."]
        or L["This specialization is not chosen now: its macros come into the game when you choose it."]
    r:Toggle(open)
    r.text:SetText(string.format("%s  |cff%s%d|r", label, ns.scheme.dim, count))
    r:Paint()
end

local function StoredRow(n, id, m, tone, depth)
    local r = UseRow(n, "stored", tone, depth)
    r.set, r.name = id, m.name
    r.selected = state.stored ~= nil and state.stored.id == id and state.stored.name == m.name
    local auto = (m.icon or NEW_ICON) == NEW_ICON
    ShowFound(r.icon, auto and FoundIcon(m.body or "", nil, m.name) or m.icon, false)
    r.mark:SetShown(Locked(m.icon, m.body))
    r.text:SetText(m.name)
    r.severity, r.issues = MacroIssues(m.body)
    r:Paint()
    r.bg:SetShown(r.selected)
end

-- The macros behind the scenes of set `id` that the search finds.
local function Behind(id, q)
    local out = {}
    for _, m in ipairs(ns.Sets.List(id)) do
        if ns.Sets.Behind(id, m) and Matches(q, m.name, m.body) then out[#out + 1] = m end
    end
    return out
end

-- Row `r` of set `id`, in the game or behind the scenes (`inGame`): a macro there gets "..." (what can be done with
-- it in the sets), and a macro dropped on the row goes there.
local function Belongs(r, id, inGame)
    r.dropId, r.dropIn = id, inGame
    if r.what ~= "macro" and r.what ~= "stored" then return end
    r.set = id
    r.more:ClearAllPoints()
    r.more:SetPoint("RIGHT", r.what == "stored" and r.remove or r.copy, "LEFT")
    r.more:Show()
    local alert = r.alert:IsShown()
    r.alert:ClearAllPoints()
    r.alert:SetPoint("RIGHT", r.more, "LEFT", -2, 0)
    r.text:SetPoint("RIGHT", alert and r.alert or r.more, "LEFT", alert and -4 or -2, 0)
end

-- A group of set `id`, in the game or behind the scenes (`inGame`): its name, then, open, its rows (`add(n, x,
-- tone, depth)` for each of `items`). Shown empty too, to drop a macro in; not while searching. `kind`: see
-- GroupRow; else `tone`.
local function Group(n, key, label, tone, default, items, q, add, kind, id, inGame)
    if #items == 0 and q ~= "" then return n end
    local open = IsOpen(key, default, q)
    n = n + 1
    GroupRow(n, key, label, #items, tone, open, kind or tone)
    Belongs(rows[n], id, inGame)
    for _, x in ipairs(open and items or {}) do
        n = n + 1
        add(n, x, tone, 2)
        Belongs(rows[n], id, inGame)
    end
    return n
end

local function SetsRows(n, q)
    local specs = ns.Sets.Specs()
    local now
    for _, spec in ipairs(specs) do if spec.now then now = spec end end
    -- In the game.
    local root, class, mine = {}, {}, {}
    local first, last = MacroRange("character")
    for index = first, last do
        local name, _, body = GetMacroInfo(index)
        if name and Shown(q, "character", name, body) then
            local layer = ns.Sets.LayerIn(name)
            table.insert(layer == "spec" and mine or layer == "class" and class or root, index)
        end
    end
    local open = IsOpen("in", true, q)
    n = n + 1
    HeadRow(n, "in", L["In the game"], string.format(L["These take the character's macro slots: %d of %d."],
        last - first + 1, MAX_CHARACTER), open)
    Belongs(rows[n], "character", true)
    if open then
        for _, index in ipairs(root) do
            n = n + 1
            MacroRow(n, index, nil, 1)
            Belongs(rows[n], "character", true)
        end
        n = Group(n, "in:class", L["Class macros"], "class", true, class, q, MacroRow, nil, "class", true)
        if now then n = Group(n, "in:" .. now.key, now.label, "now", true, mine, q, MacroRow, nil, now.key, true) end
    end
    -- Behind the scenes: not with "Not on action bars", they are on none.
    if notOnBars then return n end
    open = IsOpen("out", true, q)
    n = n + 1
    HeadRow(n, "out", L["Behind the scenes"], L["Kept by MacroSense, on no slot. Change any of them here. They come "
        .. "into the game with their specialization, with \"Take in\" in \"...\", or dragged into \"In the "
        .. "game\"."], open, "other")
    Belongs(rows[n], "character", false)
    if not open then return n end
    for _, m in ipairs(Behind("character", q)) do
        n = n + 1
        StoredRow(n, "character", m, "other", 1)
        Belongs(rows[n], "character", false)
    end
    n = Group(n, "out:class", L["Class macros"], "other", true, Behind("class", q), q,
        function(i, m, _, depth) StoredRow(i, "class", m, "other", depth) end, "class", "class", false)
    for _, spec in ipairs(specs) do
        n = Group(n, "out:" .. spec.key, spec.label, "other", spec.now, Behind(spec.key, q), q,
            function(i, m, _, depth) StoredRow(i, spec.key, m, "other", depth) end, spec.now and "now" or "other",
            spec.key, false)
    end
    return n
end

-- What can be done with macro `r.name` of set `r.set` in the sets: in the game or behind the scenes, moved to
-- another set, copied to a specialization, sent back to the character's.
local function SetsItems(r)
    local Sets, id, name = ns.Sets, r.set, r.name
    local items, m = {}, nil
    for _, x in ipairs(Sets.List(id)) do if x.name == name then m = x end end
    if not m then return items end
    local parked = Sets.IsParked(id, m) or (Sets.InGame(id) and Sets.Behind(id, m))
    items[#items + 1] = { name = parked and L["Take in"] or L["Put away"], onClick = function()
        local ok, why = Sets.Park(id, name, not parked)
        Window.Told(ok, why, { name = name, to = id, park = parked and "in" or "out" })
    end }
    local sets = { { id = "class" }, { id = "character" } }
    for _, spec in ipairs(Sets.Specs()) do sets[#sets + 1] = { id = spec.key, spec = true } end
    for _, set in ipairs(sets) do
        local label = ns.SetsWindow.Label(set.id)
        if set.id ~= id then
            items[#items + 1] = { name = string.format(L["Move to: %s"], label), onClick = function()
                local ok, why = Sets.MoveTo(id, name, set.id)
                Window.Told(ok, why, { name = name, to = set.id })
            end }
        end
    end
    for _, set in ipairs(sets) do
        local label = ns.SetsWindow.Label(set.id)
        if set.id ~= id then
            items[#items + 1] = { name = string.format(L["Copy to: %s"], label), onClick = function()
                local ok, why = Sets.MoveTo(id, name, set.id, true)
                Window.Told(ok, why, { name = name, to = set.id, copy = true })
            end }
        end
    end
    if id ~= "character" then
        items[#items + 1] = { name = L["Remove"], onClick = function()
            local ok, why = Sets.Release(id, name)
            Window.Told(ok, why, { name = name, to = "character" })
        end }
    end
    return items
end

function Window.OpenSetsMenu(owner, r) ns.OpenMenu(owner, SetsItems(r), 200, false, true) end

-- What a change of the sets says (`ok`, `why` as Sets returns them): each time the rule it met, so the sets can be
-- learned from it; nil when there is nothing to tell. `t`: the macro's `name`, the set it goes `to`, `copy`, `park`
-- ("in" taken in, "out" put away).
function Window.Explain(ok, why, t)
    t = t or {}
    local name, label = t.name or "", t.to and ns.SetsWindow.Label(t.to) or ""
    if why == "combat" then return L["macros cannot be changed in combat"] end
    if why == "waits" then
        return string.format(L["\"%s\" waits behind the scenes: there is no free slot, a character has only 30. Put "
            .. "another macro behind the scenes, then take this one in."], name)
    end
    if why == "twin" then
        return string.format(L["\"%s\" waits behind the scenes: a macro of this name is in the game already, and "
            .. "the game tells macros apart by name. Rename one of them, or put the other one behind the scenes."],
            name)
    end
    if why == "room" then
        return string.format(L["no free slot for \"%s\": a character has only 30. Put another macro behind the "
            .. "scenes first."], name)
    end
    if why == "ingame" then
        return string.format(L["\"%s\" can't come into the game: a macro of this name is there already, and only "
            .. "one of a name can be. Put that one behind the scenes, or rename one of them."], name)
    end
    if why == "name" then
        return string.format(L["\"%s\" has a macro named \"%s\" already: a set holds only one macro of a name. "
            .. "Rename one of them first."], label, name)
    end
    if why == "differs" then
        return string.format(L["\"%s\" can't go back to \"This character's\": it has another macro of this name. If "
            .. "they had the same text, the two would be one. Rename one of them, or make them the same."], name)
    end
    if why == "merged" then
        return string.format(L["\"%s\" in \"%s\" was the very same macro: the two are one now."], name, label)
    end
    if why == "same" then
        return string.format(L["a copy goes into another set: drag \"%s\" with Ctrl onto another group."], name)
    end
    if not ok then return end
    local inGame = t.to and ns.Sets.InGame(t.to)
    if t.copy then
        return string.format(L["\"%s\" is copied to \"%s\": now they are two macros of their own. Change or rename "
            .. "one, and the other stays as it is."], name, label)
    end
    if t.park == "in" and not inGame then
        return string.format(L["\"%s\" will come into the game with its specialization: it isn't the one chosen now."],
            name)
    end
    if t.park == "out" and not inGame then
        return string.format(L["\"%s\" stays behind the scenes, also when you choose its specialization. \"Take in\" "
            .. "brings it back."], name)
    end
    if t.to and not t.park and not inGame then
        return string.format(L["\"%s\" is in \"%s\" now: it comes into the game when you choose that specialization."],
            name, label)
    end
end

-- The same, in the chat.
function Window.Told(ok, why, t)
    local text = Window.Explain(ok, why, t)
    if text then ns.Say(text) end
end

-- A macro behind the scenes being dragged: its icon and name by the mouse.
local ghost
function Window.ShowGhost(r)
    if not ghost then
        ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetFrameStrata("TOOLTIP")
        ghost:SetSize(200, 24)
        ghost.icon = ghost:CreateTexture(nil, "ARTWORK")
        ghost.icon:SetSize(24, 24)
        ghost.icon:SetPoint("LEFT")
        ghost.text = ns.Text(ghost, 12)
        ghost.text:SetPoint("LEFT", ghost.icon, "RIGHT", 6, 0)
        ghost:SetScript("OnUpdate", function(self)
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 12, y / scale - 4)
        end)
    end
    ghost.icon:SetTexture(r.icon:GetTexture())
    ghost.text:SetText(r.name)
    ghost:SetAlpha(0.8)
    ghost:Show()
end
function Window.HideGhost() if ghost then ghost:Hide() end end

-- While a macro is dragged in the list: over a group, by the macro on the mouse a sign of what letting go does
-- there (a copy: a plus; nothing can be done: a crossed circle), and a tooltip that says it, with why not.
local mark, over
local function MarkAt()
    mark:ClearAllPoints()
    if ghost and ghost:IsShown() then return mark:SetPoint("CENTER", ghost.icon, "BOTTOMRIGHT", -2, 2) end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    mark:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale + 22, y / scale - 22)
end
function Window.Watch()
    if not mark then
        mark = CreateFrame("Frame", nil, UIParent)
        mark:SetFrameStrata("TOOLTIP")
        mark:SetFrameLevel(100)
        mark:SetSize(18, 18)
        mark.icon = mark:CreateTexture(nil, "OVERLAY")
        mark.icon:SetAllPoints()
        mark:Hide()
        -- Follows the mouse while the drag lasts: the row under it, Ctrl held or let go.
        mark.watch = CreateFrame("Frame", nil, UIParent)
        mark.watch:SetScript("OnUpdate", function()
            if not Window.dragging then return mark.watch:Hide() end
            local at
            for _, target in ipairs(rows) do
                if target:IsShown() and target.dropId and target:IsMouseOver() then at = target end
            end
            Window.DragOver(at)
            if mark:IsShown() then MarkAt() end
        end)
    end
    mark.watch:Show()
end

-- The sign by the dragged macro, if one is shown (the tests).
function Window.DragSign() return mark ~= nil and mark:IsShown() and mark.sign or nil end

-- The dragged macro over row `target` (nil: over none, or let go): the sign and the tooltip, as Ctrl is now.
function Window.DragOver(target)
    local source = Window.dragging
    if not (source and target and target.dropId) or target == source then
        if over then GameTooltip:Hide() end
        over = nil
        if mark then mark:Hide() end
        return
    end
    local copy = (Window.copying or IsControlKeyDown()) and true or false
    local ok, why = ns.Sets.CanPlace(source.set, source.name, target.dropId, target.dropIn, copy)
    local key = table.concat({ tostring(target), tostring(copy), tostring(ok), tostring(why) }, " ")
    if key == over then return end
    over = key
    local label = ns.SetsWindow.Label(target.dropId)
    if mark then
        mark.sign = not ok and NO_ICON or PLUS_ICON
        mark.icon:SetTexture(mark.sign)
        mark:SetShown(not ok or copy)
        if mark:IsShown() then MarkAt() end
    end
    GameTooltip:SetOwner(target, "ANCHOR_RIGHT")
    if ok then
        GameTooltip:SetText(string.format(copy and L["Copy to \"%s\""] or L["Move to \"%s\""], label), 0.3, 0.75,
            0.3)
        GameTooltip:AddLine(copy and L["A macro of its own goes there; this one stays as it is. Let go of Ctrl to "
            .. "move it instead."] or L["It leaves its set and goes there. Hold Ctrl to copy it instead."],
            1, 1, 1, true)
    else
        GameTooltip:SetText(string.format(copy and L["Can't copy to \"%s\""] or L["Can't move to \"%s\""], label),
            1, 0.3, 0.3)
        local text = Window.Explain(ok, why, { name = source.name, to = target.dropId, copy = copy })
        if text then GameTooltip:AddLine(text, 1, 1, 1, true) end
    end
    GameTooltip:Show()
end

-- Macro row `source` dropped on row `target`: into the target's set, in the game or behind the scenes. With Ctrl
-- held (`copy`: when the drag began or at the drop), a copy of it.
function Window.Drop(source, target, copy)
    if not target.dropId or not source.set or target == source then return end
    ClearCursor() -- a macro picked up for the action bars
    copy = copy or IsControlKeyDown()
    local from, name, to = source.set, source.name, target.dropId
    local ok, why = ns.Sets.Place(from, name, to, target.dropIn, copy)
    -- Dropped in its own set: in the game or behind the scenes (one not chosen now: to come in with it).
    local park = from == to and ((target.dropIn or not ns.Sets.InGame(to)) and "in" or "out") or nil
    Window.Told(ok, why, { name = name, to = to, copy = copy, park = park })
end

-- What the spells say of macro row `r` in its set, in its tooltip: one that can't be cast there in red.
function Window.AddSetsNote(r)
    if not r.set then return end
    local body = r.what == "macro" and select(3, GetMacroInfo(r.index)) or nil
    if r.what == "stored" then
        for _, x in ipairs(ns.Sets.List(r.set)) do if x.name == r.name then body = x.body end end
    end
    local note, kind = ns.Sets.Note(r.set, { name = r.name, body = body or "" })
    if not note then return end
    local red = kind == "warn"
    GameTooltip:AddLine(note, red and 1 or 0.6, red and 0.4 or 0.6, red and 0.4 or 0.6, true)
end

-- How many macros are behind the scenes.
local function BehindCount()
    local count = 0
    for _, id in ipairs({ "class", "character" }) do count = count + #Behind(id, "") end
    for _, spec in ipairs(ns.Sets.Specs()) do count = count + #Behind(spec.key, "") end
    return count
end

-- The sidebar `width` wide, its buttons at the bottom sharing it (6 px apart, 8 from its edges).
function Window.SideWidth(width)
    side:SetWidth(width)
    for _, row in ipairs(sideRows or {}) do
        for _, b in ipairs(row) do b:SetWidth((width - 16 - 6 * (#row - 1)) / #row) end
    end
end

function Window.RefreshList()
    if not frame then return end
    local setsOn = ns.Sets.Mine().enabled
    Window.SideWidth(setsOn and 280 or 220)
    sortBtn:SetShown(setsOn)
    sortBtn:SetEnabled(#ns.Sets.Unvisited() == 0)
    sortBtn:SetAlpha(sortBtn:IsEnabled() and 1 or 0.4)
    local q = Query()
    local first, last = MacroRange(state.scope)
    local n = 0
    if SetsShown() then
        n = SetsRows(n, q)
    else
        for index = first, last do
            local name, _, body = GetMacroInfo(index)
            if name and Shown(q, state.scope, name, body) then
                n = n + 1
                MacroRow(n, index)
            end
        end
    end
    altHint:Hide()
    if state.scope == "character" and not notOnBars then n = AltRows(n, q) end
    for i = n + 1, #rows do rows[i]:Hide() end
    local height = math.max(n * ROW_H + (altHint:IsShown() and 40 or 0), 1)
    list.child:SetHeight(height)
    -- Fewer rows than before: not scrolled past the last.
    local bottom = math.max(0, height - list:GetHeight())
    if list:GetVerticalScroll() > bottom then list:SetVerticalScroll(bottom) end
    noMatch:SetShown(n == 0 and (q ~= "" or notOnBars))

    -- While searching or filtering, the tabs say how many match.
    if q == "" and not notOnBars then
        local general, character = GetNumMacros()
        tabs.general.label:SetText(string.format(L["General  %d/%d"], general, MAX_GENERAL))
        local behind = ns.Sets.Mine().enabled and BehindCount() or 0
        tabs.character.label:SetText(behind > 0
            and string.format(L["Character  %d/%d  +%d"], character, MAX_CHARACTER, behind)
            or string.format(L["Character  %d/%d"], character, MAX_CHARACTER))
    else
        tabs.general.label:SetText(string.format(L["General  (%d)"], CountMatches("general", q)))
        tabs.character.label:SetText(string.format(L["Character  (%d)"], CountMatches("character", q)))
    end
    for scope, tab in pairs(tabs) do tab.active = scope == state.scope; tab:Paint() end
end

------------------------------------------------------------------------
-- Editing
------------------------------------------------------------------------
-- `stored`: one behind the scenes instead, { id = its set, name } (no name: a new one there).
local function Load(index, stored)
    -- The wizard had the macro shown before: what it makes is not for this one.
    if ns.WizardWindow.IsEditing() then ns.WizardWindow.Close() end
    state.stored = stored and { id = stored.id, name = stored.name }
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
        if SetsShown() then
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
        if last - first + 1 >= max and SetsShown() then
            return ns.SetsWindow.AskBehind(1, function()
                Load(nil, { id = "character" })
                nameBox:SetFocus()
            end)
        end
        if Fresh() then nameBox:SetFocus() end
    end)
end

function Window.Save()
    -- A mistake in the word just typed shows now, not only after the typing pause.
    code:CheckNow()
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
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
        local ok, why = ns.Sets.Write(state.stored.id, state.stored.name, name, state.icon, written)
        if not ok then
            if why == "name" then
                return ns.Print("\"%s\" has a macro named \"%s\" already: a set holds only one macro of a name. "
                    .. "Choose another name.", ns.SetsWindow.Label(state.stored.id), name)
            end
            return ns.Print("could not save the macro")
        end
        state.stored.name, state.name, state.body, state.savedIcon = name, name, body, state.icon
        Window.RefreshList()
        return UpdateStatus()
    end
    local index
    -- Earlier versions follow a new name.
    local renamed = state.index and name ~= state.name
    if renamed then ns.History.Renamed(state.scope, state.name, name) end
    if state.index then
        -- The game keeps macros sorted by name, so the index may change.
        index = EditMacro(state.index, name, state.icon, written)
    else
        index = CreateMacro(name, state.icon or NEW_ICON, written, state.scope == "character")
    end
    if not index or index == 0 then
        if renamed then ns.History.Renamed(state.scope, name, state.name) end
        return ns.Print("could not save the macro")
    end
    ns.Roles.Saved(state.scope, state.index and state.name, name, body, select(3, GetMacroInfo(index)))
    -- The text it replaced is kept now, not only when the game reports the change.
    ns.History.Scan()
    state.index, state.name, state.body = index, name, body
    state.icon = ns.MacroIcon(index) or state.icon
    state.savedIcon = state.icon
    ShowIcon()
    Window.RefreshList()
    UpdateStatus()
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
    if frame and frame:IsShown() and notOnBars then Window.RefreshList() end
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

-- Deletes macro `index`. The one being edited: the next one opens, or the one before when it was the last. Another
-- one: the editor keeps what it shows. Which one it was is known before: the game may report the change while it
-- deletes (UPDATE_MACROS), and the one being edited, looked up by its name, is gone then.
function Window.Delete(index)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local editing = state.index
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
-- one name would share a key binding ("MACRO Fear" runs the first one). `also`: names given out already.
local function FreeName(name, also)
    local function taken(n)
        local index = GetMacroIndexByName(n)
        return (index ~= nil and index > 0) or (also ~= nil and also[n] == true)
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
local function Full(scope, make, count)
    if scope ~= "character" or not ns.Sets.Mine().enabled then return NoRoom(scope) end
    ns.SetsWindow.AskBehind(count or 1, make)
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
            return Full(scope, function() Guard(function() Window.MakeBehind(name, icon, ns.Roles.Fill(body)) end) end)
        end
        local copy = CreateMacro(FreeName(name), icon or NEW_ICON, ns.Roles.Fill(body), scope == "character")
        if not copy or copy == 0 then return ns.Print("could not copy the macro") end
        local made, _, written = GetMacroInfo(copy)
        ns.Roles.Saved(scope, nil, made, body, written)
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

-- Macro `index` into the other tab, opened there: made under its name (a free one when that tab has it) with its
-- icon and text, put back on its buttons of the action bars now, its versions taken along, then deleted here. The
-- bars of your other specializations and, for a general macro, of other characters lose it. Unsaved changes are
-- asked about first.
function Window.Move(index)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local from = index > MAX_GENERAL and "character" or "general"
    local to = from == "general" and "character" or "general"
    local first, last, max = MacroRange(to)
    if last - first + 1 >= max then return NoRoom(to) end
    Guard(function()
        local name, _, body = GetMacroInfo(index)
        local icon, slots = ns.MacroIcon(index), ns.ActionBars.SlotsOf(name)
        local moved = IndexIn(to, name) and FreeName(name) or name
        local made = CreateMacro(moved, icon or NEW_ICON, body or "", to == "character")
        if not made or made == 0 then return ns.Print("could not move the macro") end
        ns.History.Moved(from, to, name, moved)
        ns.Roles.Moved(from, to, name, moved)
        DeleteMacro(IndexIn(from, name))
        ns.ActionBars.Place(IndexIn(to, moved), slots)
        ns.History.Scan()
        state.scope, ns.db.scope = to, to
        Load(IndexIn(to, moved))
    end)
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

local function CopyItems(index)
    local other = state.scope == "general" and "character" or "general"
    local function item(scope, label, tip, move)
        return TabItem(scope, label, tip, function()
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
        item(other, other == "character" and L["Copy to Character"] or L["Copy to General"], tips[other]),
        item(other, other == "character" and L["Move to Character"] or L["Move to General"], moves[other], true),
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

-- The copy menu of macro `index`, under its copy button in the list.
function Window.OpenCopyMenu(owner, index) ns.OpenMenu(owner, CopyItems(index), 180, false, true) end

------------------------------------------------------------------------
-- Share: macros as a code to copy, and back (Share.lua, ShareWindow.lua)
------------------------------------------------------------------------
-- The saved macros of `scope`, or of both tabs, as Share.Encode takes them.
local function Macros(scope)
    local out = {}
    for _, s in ipairs(scope and { scope } or { "general", "character" }) do
        local first, last = MacroRange(s)
        for index = first, last do
            local name, _, body = GetMacroInfo(index)
            if name then out[#out + 1] = { scope = s, name = name, icon = ns.MacroIcon(index), body = body or "" } end
        end
    end
    return out
end

-- Where each macro of a code goes, in order: { macro, name = a free one } into its own tab, or { macro, full =
-- true } with no free slot there, or { macro, long = true } for a text longer than the game allows.
function Window.ImportPlan(macros)
    local room, given, plan = {}, {}, {}
    for _, s in ipairs({ "general", "character" }) do
        local first, last, max = MacroRange(s)
        room[s] = max - (last - first + 1)
    end
    for i, m in ipairs(macros) do
        if Letters(m.body) > MAX_BODY then
            plan[i] = { macro = m, long = true }
        elseif room[m.scope] > 0 then
            room[m.scope] = room[m.scope] - 1
            local name = FreeName(FirstLetters(m.name, MAX_NAME), given)
            given[name] = true
            plan[i] = { macro = m, name = name }
        else
            plan[i] = { macro = m, full = true }
        end
    end
    return plan
end

-- Creates the macros of a code where ImportPlan puts them and opens the first, then done(). Unsaved changes
-- are asked about first.
function Window.Import(macros, done)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    Guard(function()
        local made, first, behind = 0, nil, {}
        for _, p in ipairs(Window.ImportPlan(macros)) do
            local m = p.macro
            -- A text from a guide has no icon: the question mark, so the game shows the spell's.
            local icon = m.icon ~= "" and m.icon or NEW_ICON
            if p.name then
                CreateMacro(p.name, icon, m.body, m.scope == "character")
                made, first = made + 1, first or p
            elseif p.full and m.scope == "character" and ns.Sets.Mine().enabled then
                behind[#behind + 1] = { name = m.name, icon = icon, body = m.body }
            end
        end
        -- Those with no free slot, macro sets on: behind the scenes (asked first).
        if #behind > 0 then
            Full("character", function()
                for _, m in ipairs(behind) do Window.MakeBehind(m.name, m.icon, m.body) end
                if done and not first then done() end
            end, #behind)
        end
        if not first then return end
        ns.History.Scan()
        ns.Print("imported %d of %d macros", made, #macros)
        state.scope, ns.db.scope = first.macro.scope, first.macro.scope
        Load(GetMacroIndexByName(first.name))
        if done then done() end
    end)
end

local function ShareItems()
    local tab = TabName(state.scope)
    local general, character = GetNumMacros()
    local here = state.scope == "general" and general or character
    local function item(name, tip, onClick, disabled)
        return {
            name = name,
            disabled = disabled,
            onClick = onClick,
            onEnter = function(row)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(name, 1, 1, 1)
                GameTooltip:AddLine(tip, 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end,
        }
    end
    return {
        item(L["Link this macro in chat"], state.index and L["Puts a link to it in the chat. Players with MacroSense "
            .. "can click it to get the macro as it is saved now. Others see only its name. Shift-click on a macro "
            .. "in the list does the same."] or L["Save the macro first, then link it."], function()
            ns.Links.Insert({ scope = state.scope, name = state.name, icon = state.savedIcon, body = state.body })
        end, not state.index),
        item(L["Export this macro"], state.index and L["The code of the saved macro, to copy and share."]
            or L["Save the macro first, then export it."], function()
            ns.ShareWindow.Export({ { scope = state.scope, name = state.name, icon = state.savedIcon,
                body = state.body } })
        end, not state.index),
        item(L["Copy this macro's text"], state.index and L["The text of the saved macro, to paste into a guide, a "
            .. "forum or Discord. MacroSense can import it too."] or L["Save the macro first, then copy its text."],
            function() ns.ShareWindow.ExportText({ name = state.name, body = state.body }) end, not state.index),
        item(string.format(L["Export the %s tab (%d)"], tab, here), L["The code of every macro in this tab."],
            function() ns.ShareWindow.Export(Macros(state.scope)) end, here == 0),
        item(string.format(L["Export all macros (%d)"], general + character),
            L["The code of every macro in both tabs. On import, each one goes into its own tab."],
            function() ns.ShareWindow.Export(Macros()) end, general + character == 0),
        item(L["Import a code or text..."], L["Paste a code, or a macro's text from a guide, to add its macros. "
            .. "Nothing gets replaced: if a name is taken, a number is added to it, like \"Fear 2\"."],
            function() ns.ShareWindow.Import() end),
    }
end

------------------------------------------------------------------------
-- Trash: macros deleted anywhere, to bring back (History.lua keeps them)
------------------------------------------------------------------------
StaticPopupDialogs.MACROSENSE_EMPTY_TRASH = {
    text = "Empty the trash? Its %s deleted macros will be gone for good.",
    button1 = "Yes", button2 = "No",
    OnAccept = function()
        for _, scope in ipairs({ "general", "character" }) do
            local trash = ns.History.Trash(scope)
            for i = #trash, 1, -1 do trash[i] = nil end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs.MACROSENSE_FORGET_DELETED = {
    text = "Delete \"%s\" from the trash? It will be gone for good.",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function(_, d) ns.History.TakeOut(ns.History.Trash(d.scope), d.entry) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- The deleted macros of both tabs, newest first: { scope, entry }.
local function Deleted()
    local out = {}
    for _, scope in ipairs({ "general", "character" }) do
        for _, entry in ipairs(ns.History.Trash(scope)) do out[#out + 1] = { scope = scope, entry = entry } end
    end
    table.sort(out, function(a, b) return a.entry.time > b.entry.time end)
    return out
end

-- A deleted macro back in its tab, under a free name, and opened. Unsaved changes are asked about first.
function Window.Undelete(scope, entry)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local first, last, max = MacroRange(scope)
    if last - first + 1 >= max then
        return Full(scope, function()
            Guard(function()
                ns.History.TakeOut(ns.History.Trash(scope), entry)
                Window.MakeBehind(entry.name, entry.icon, entry.body)
            end)
        end)
    end
    Guard(function()
        local name = FreeName(entry.name)
        local index = CreateMacro(name, entry.icon or NEW_ICON, entry.body, scope == "character")
        if not index or index == 0 then return ns.Print("could not restore the macro") end
        ns.History.TakeOut(ns.History.Trash(scope), entry)
        ns.History.Scan()
        state.scope, ns.db.scope = scope, scope
        Load(GetMacroIndexByName(name))
    end)
end

local function TrashItems()
    local items, dim, deleted = {}, ns.scheme.dim, Deleted()
    for n = 1, #deleted do
        local d = deleted[n]
        local first, last, max = MacroRange(d.scope)
        local full = last - first + 1 >= max
        items[n] = {
            name = string.format("%s  |cff%s%s|r", d.entry.name, dim, When(d.entry.time)),
            disabled = full,
            onClick = function() Window.Undelete(d.scope, d.entry) end,
            onRemove = function() ns.Ask("MACROSENSE_FORGET_DELETED", d.entry.name, nil, d) end,
            removeTip = L["Delete for good"],
            onEnter = function(row)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(d.entry.name, 1, 1, 1)
                GameTooltip:AddLine(full and string.format(L["The %s tab is full."], TabName(d.scope))
                    or string.format(L["Deleted from %s: %s. Click to bring it back."], TabName(d.scope),
                        When(d.entry.time)), 0.8, 0.8, 0.8, true)
                for line in ((d.entry.body or "") .. "\n"):gmatch("([^\n]*)\n") do
                    GameTooltip:AddLine(line ~= "" and line:gsub("|", "||") or " ", 0.6, 0.6, 0.6, true)
                end
                GameTooltip:Show()
            end,
        }
    end
    local noop = function() end
    if #deleted == 0 then items[1] = { name = L["No deleted macros"], disabled = true, onClick = noop } end
    items[#items + 1] = { name = L["Empty the trash"], disabled = #deleted == 0,
        onClick = function() ns.Ask("MACROSENSE_EMPTY_TRASH", #deleted) end }
    return items
end

------------------------------------------------------------------------
-- Backups: all the macros, to go back to (Backups.lua); kept per character
------------------------------------------------------------------------
local NAMES_SHOWN = 15 -- macro names in a backup's tooltip

local function BackupList()
    ns.char.backups = ns.char.backups or {}
    return ns.char.backups
end

-- A backup now, unless the macros are as in the last one.
function Window.BackupNow() ns.Backups.Add(BackupList(), Macros(), time()) end

-- On login: the day's backup, if the macros changed since the last one.
function Window.DailyBackup()
    local list = BackupList()
    if ns.Backups.Due(list, time()) then ns.Backups.Add(list, Macros(), time()) end
end

-- The macros of `backup` as they were, after a backup of them now; macros made since stay. Unsaved changes are
-- asked about first.
function Window.RestoreBackup(backup)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    Guard(function()
        ns.Backups.Add(BackupList(), Macros(), time())
        local room = {}
        for _, s in ipairs({ "general", "character" }) do
            local first, last, max = MacroRange(s)
            room[s] = max - (last - first + 1)
        end
        local plan = ns.Backups.Plan(backup.macros, Macros(), room)
        for _, m in ipairs(plan.back) do EditMacro(IndexIn(m.scope, m.name), m.name, m.icon, m.body) end
        for _, m in ipairs(plan.again) do CreateMacro(m.name, m.icon or NEW_ICON, m.body, m.scope == "character") end
        ns.History.Scan()
        ns.Print("backup restored: %d changed back, %d made again", #plan.back, #plan.again)
        if #plan.full > 0 then
            ns.Print(ns.Plural(#plan.full, "%d did not fit: no free slot in its tab",
                "%d did not fit: no free slot in their tab"))
        end
        local first, last = MacroRange(state.scope)
        Load(state.index and IndexIn(state.scope, state.name) or (last >= first and first or nil))
    end)
end

StaticPopupDialogs.MACROSENSE_RESTORE_BACKUP = {
    text = "Restore the backup of %s?\n\nYour macros get back the text and icons they had then, and the missing ones "
        .. "are made again. Macros you made after it stay. First, MacroSense backs up your macros as they are now.",
    button1 = "Yes", button2 = "No",
    OnAccept = function(_, backup) Window.RestoreBackup(backup) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs.MACROSENSE_DELETE_BACKUP = {
    text = "Delete the backup of %s? It will be gone for good.",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function(_, backup) ns.Backups.Remove(BackupList(), backup) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function BackupItems()
    local dim, list = ns.scheme.dim, BackupList()
    local function tip(row, title, text)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title, 1, 1, 1)
        GameTooltip:AddLine(text, 0.8, 0.8, 0.8, true)
    end
    local items = { {
        name = L["Back up now"],
        onClick = function()
            local macros = Macros()
            if #macros == 0 then return ns.Print("no macros to back up") end
            if ns.Backups.Add(list, macros, time()) then
                return ns.Print(ns.Plural(#macros, "backed up %d macro", "backed up %d macros"))
            end
            ns.Print("your macros are as in the last backup")
        end,
        onEnter = function(row)
            tip(row, L["Back up now"], string.format(L["Saves all your macros now, General and this character's. "
                .. "Each character keeps its last %d backups; older ones are deleted by themselves."],
                ns.Backups.LIMIT))
            GameTooltip:Show()
        end,
    } }
    for i = #list, 1, -1 do
        local b = list[i]
        items[#items + 1] = {
            name = string.format("%s  |cff%s%s|r", When(b.time), dim, ns.Plural(#b.macros, "%d macro", "%d macros")),
            onClick = function() ns.Ask("MACROSENSE_RESTORE_BACKUP", When(b.time), nil, b) end,
            onRemove = function() ns.Ask("MACROSENSE_DELETE_BACKUP", When(b.time), nil, b) end,
            removeTip = L["Delete this backup"],
            onEnter = function(row)
                local count = { general = 0, character = 0 }
                local names = {}
                for n, m in ipairs(b.macros) do
                    count[m.scope] = count[m.scope] + 1
                    if n <= NAMES_SHOWN then names[n] = m.name end
                end
                tip(row, string.format(L["Backup of %s"], When(b.time)), string.format(L["General %d, Character %d. "
                    .. "Click to restore it."], count.general, count.character))
                local more = #b.macros > NAMES_SHOWN and string.format(L[" and %d more"], #b.macros - NAMES_SHOWN)
                    or ""
                GameTooltip:AddLine(table.concat(names, ", ") .. more, 0.6, 0.6, 0.6, true)
                GameTooltip:Show()
            end,
        }
    end
    if #list == 0 then items[2] = { name = L["No backups yet"], disabled = true, onClick = function() end } end
    return items
end

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
                Window.MakeBehind(name, NEW_ICON, filled)
            end)
        end)
    end
    Guard(function()
        local index = CreateMacro(Window.FreeName(name), NEW_ICON, filled, scope == "character")
        if not index or index == 0 then return ns.Print("could not save the macro") end
        local saved, _, written = GetMacroInfo(index)
        ns.Roles.Saved(scope, nil, saved, body, written)
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
    side:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
    side:SetPoint("BOTTOMLEFT", 1, 1)
    side:SetWidth(220)
    ns.Backdrop(side, "panel", "panel")

    tabs = { general = Tab(side, "general"), character = Tab(side, "character") }
    tabs.general:SetPoint("TOPLEFT", 0, 0)
    tabs.general:SetPoint("TOPRIGHT", side, "TOP", 0, 0)
    tabs.character:SetPoint("TOPLEFT", side, "TOP", 0, 0)
    tabs.character:SetPoint("TOPRIGHT", 0, 0)

    -- At the bottom: Share / Trash / Backups; New / New (Wizard) over them. Their menus open above them, the list
    -- is in the way below. Each macro in the list has its copy and x buttons.
    local shareBtn = ns.MenuButton(side, L["Share"], 64, ShareItems, true)
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
    local trashBtn = ns.MenuButton(side, L["Trash"], 64, TrashItems, true)
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
    local backupsBtn = ns.MenuButton(side, L["Backups"], 64, BackupItems, true, true)
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
        ns.Sets.Disable()
    end)
    setsCheck:SetPoint("BOTTOMLEFT", 8, 94)
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
    search:SetPoint("TOPLEFT", 8, -32)
    search:SetPoint("TOPRIGHT", -8, -32)
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
        for _, r in ipairs(rows) do
            if not r:IsShown() then break end
            if r.what == "macro" then return Window.Select(r.index) end
            if r.what == "stored" then return Window.SelectStored(r.set, r.name) end
        end
    end)

    -- Under it: only the macros on no action bar, to free slots.
    barsCheck = ns.Check(side, L["Not on action bars"], function() return notOnBars end, function(on)
        notOnBars = on
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

    list = CreateFrame("ScrollFrame", "MacroSenseListScroll", side)
    list:SetPoint("TOPLEFT", 0, -84)
    list:SetPoint("BOTTOMRIGHT", -13, 122)
    ns.AttachScrollBar(list, ROW_H * 3)
    list.child = CreateFrame("Frame", nil, list)
    list.child:SetSize(196, 1)
    list:SetScrollChild(list.child)
    list:SetScript("OnSizeChanged", function(_, w) list.child:SetWidth(w) end)
    altHint = ns.Text(list.child, 11, "dim")
    altHint:SetWordWrap(true)
    altHint:SetText(L["Log in with your other characters once, and their own macros show up here to copy."])
    altHint:Hide()
    noMatch = ns.Text(side, 12, "dim")
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
        if warning.shown and warning.shown.fix then
            GameTooltip:AddLine(warning.shown.fixTip or string.format(L["Click to use \"%s\""], warning.shown.fix),
                0.4, 1, 0.4)
        elseif warning.shown then
            GameTooltip:AddLine(string.format(L["Click to go to line %d"], warning.shown.line), 0.4, 1, 0.4)
        end
        GameTooltip:Show()
    end)
    warningHover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Click: replace the misspelled name with the suggestion, or go to the issue.
    warningHover:SetScript("OnMouseUp", function()
        local e = warning.shown
        if not e then return end
        GameTooltip:Hide()
        if not e.fix then return code:SetRawCursor(e.from - 1) end
        local raw, from, to = code:GetRaw(), e.fixFrom or e.from, e.fixTo or e.to
        code:SetRaw(raw:sub(1, from - 1) .. e.fix .. raw:sub(to + 1), from - 1 + #e.fix, true)
        code:CheckNow()
    end)

    -- Editor.
    local editorBg = CreateFrame("Frame", nil, main, "BackdropTemplate")
    editorBg:SetPoint("TOPLEFT", 12, -58)
    editorBg:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -12, 10)
    ns.Backdrop(editorBg, "bg", "border")
    code = ns.CreateCodeBox(editorBg, "MacroSenseCodeScroll")
    code.scroll:SetPoint("TOPLEFT", 4, -4)
    code.scroll:SetPoint("BOTTOMRIGHT", -15, 4)
    ns.AttachAutocomplete(code)
    code:ShowNotes(ns.db.preview)
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
        if not (IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())) then return end
        if key == "S" then
            Window.Save()
        elseif key == "F" then
            search:SetFocus()
            search:HighlightText()
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
        ns.CloseMenu()
        search:SetText("") -- opened again, the list shows every macro
        notOnBars = false
        barsCheck:Refresh()
    end)
    -- The preview also follows the game: modifiers held, target, mouseover, pet, combat.
    local sincePreview = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        sincePreview = sincePreview + elapsed
        if sincePreview < PREVIEW_EVERY then return end
        sincePreview = 0
        UpdatePreview()
        ShowIcon()
        FollowRowIcons()
        UpdateExplain()
    end)

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
