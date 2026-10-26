-- The MacroSense window: macro list on the left, editor on the right. Macros are the game's own
-- (CreateMacro / EditMacro), so everything stays in sync with the Blizzard macro UI.
local _, ns = ...
local L = ns.L

local MAX_GENERAL, MAX_CHARACTER = ns.MAX_GENERAL, ns.MAX_CHARACTER
local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local MAX_NAME = 16 -- letters, as in the Blizzard macro window
local NEW_ICON = 134400 -- question mark: #showtooltip picks the icon
local COPY_ICON = "Interface\\AddOns\\MacroSense\\Media\\copy"
local ROW_H = 24
local MIN_W, MIN_H = 780, 460 -- also the first size
local PREVIEW_EVERY = 0.1 -- seconds: modifiers, target, mouseover and pet change any time

local Window = {}
ns.Window = Window

-- What is being edited: scope "general" | "character", index (nil = new macro), name/body/savedIcon as saved,
-- icon = the icon picked now.
local state = { scope = "general", icon = NEW_ICON, savedIcon = NEW_ICON }
local frame, list, nameBox, iconTex, code, status, dirtyDot, warning, counter, saveBtn, revertBtn, tabs
local shortenBtn, historyBtn, search, noMatch, barsCheck, altHint
local notOnBars = false -- the list shows only the macros on no action bar
local expanded = {} -- the other characters whose macros the Character tab shows, by key
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
    if not state.index then return body ~= "" or name ~= "" or state.icon ~= NEW_ICON end
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
    saveBtn:SetEnabled(dirty and letters <= MAX_BODY)
    revertBtn:SetEnabled(dirty and state.index ~= nil)
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

-- The header's icon: the one the macro shows in the game, as the list and the action bars do (the question mark
-- shows the icon of the spell #showtooltip names, and can change with a key held). An icon picked and not saved
-- yet shows as picked; the one saved stays the one chosen.
local function ShowIcon()
    local shown = state.index and state.icon == state.savedIcon and select(2, GetMacroInfo(state.index))
    iconTex:SetTexture(ns.IconTexture(shown or state.icon))
end

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
    local results = ns.Preview.Evaluate(code:GetRaw(), ns.previewEnv, skip)
    local notes = {}
    for i = 1, results.n do notes[i] = ns.Preview.Note(results[i], noteColors) end
    code:SetLineNotes(notes)
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
        TabItem("character", L["Copy to Character"], L["A copy for this character only, under a free name like "
            .. "\"Fear 2\"."], function() Window.CopyIn("character", m) end),
        TabItem("general", L["Copy to General"], L["A copy for all your characters, under a free name like "
            .. "\"Fear 2\"."], function() Window.CopyIn("general", m) end),
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
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(ROW_H - 4, ROW_H - 4)
    r.icon:SetPoint("LEFT", 6, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
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
        local m = { index = r.index, name = r.name, scope = r.scope }
        ns.Ask("MACROSENSE_DELETE", r.name, BarsNote(r.scope, r.name), m)
    end)
    r.remove:SetPoint("RIGHT", -2, 0)
    r.copy = ns.RowButton(r, COPY_ICON, "text", lit, function() return L["Copy this macro"] end, function()
        if r.what == "altMacro" then return OpenAltCopyMenu(r.copy, r.macro) end
        Window.OpenCopyMenu(r.copy, r.index)
    end)
    r.copy:SetPoint("RIGHT", r.remove, "LEFT")
    -- A macro with errors gets the alert sign, as on Save.
    r.alert = r:CreateTexture(nil, "OVERLAY")
    r.alert:SetSize(14, 14)
    r.alert:SetPoint("RIGHT", r.copy, "LEFT", -2, 0)
    r.alert:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    r.alert:Hide()
    -- Hover: the issues, line by line, and where it is on the action bars; another character's macro: its text.
    r:SetScript("OnEnter", function()
        lit(true)
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        if r.what == "alt" then
            AddAltLines(r.alt)
        elseif r.what == "altMacro" then
            AddAltMacroLines(r.alt, r.macro)
        else
            GameTooltip:AddLine(r.text:GetText(), 1, 1, 1)
            AddIssueLines(r.issues or {})
            AddBarsLines(r.scope, r.name)
        end
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function()
        lit(false)
        GameTooltip:Hide()
    end)
    r:SetScript("OnClick", function()
        if r.what == "alt" then
            expanded[r.alt.key] = not expanded[r.alt.key]
            return Window.RefreshList()
        end
        if r.what == "altMacro" then return OpenAltCopyMenu(r, r.macro) end
        Window.Select(r.index)
    end)
    -- Drag a macro onto an action bar, like in the Blizzard macro window.
    r:RegisterForDrag("LeftButton")
    r:SetScript("OnDragStart", function() if r.what == "macro" then Window.Pickup(r.index) end end)
    -- The name is red with errors, yellow with warnings only; another character's in its class color, its macros dim.
    function r:Paint()
        local s = ns.scheme
        if not s then return end
        self.bg:SetColorTexture(ns.RGB(s.selection))
        local color = self.severity == "error" and s.invalid or self.severity == "warning" and s.warning or s.text
        self.text:SetTextColor(ns.RGB(self.what == "altMacro" and s.dim or color))
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

-- Row `n` of the list as a row of `what` (see Row), not selected, without marks.
local function UseRow(n, what)
    rows[n] = rows[n] or Row(n)
    local r = rows[n]
    r.what, r.index, r.selected, r.severity, r.issues = what, nil, false, nil, nil
    r.icon:SetPoint("LEFT", what == "altMacro" and 18 or 6, 0) -- a character's macros under its name
    if what == "alt" then r.icon:SetTexCoord(0, 1, 0, 1) else r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    r.copy:SetShown(what ~= "alt")
    r.remove:SetShown(what ~= "altMacro")
    r.alert:Hide()
    r.text:SetPoint("RIGHT", what == "alt" and r.remove or r.copy, "LEFT", -2, 0)
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
            r.icon:SetTexture(open and MINUS or PLUS)
            r.text:SetText(string.format("%s  |cff%s%d|r", alt.label, ns.scheme.dim, #alt.macros))
            r:Paint()
            for _, m in ipairs(open and found or {}) do
                n = n + 1
                r = UseRow(n, "altMacro")
                r.alt, r.macro, r.name = alt, m, m.name
                r.icon:SetTexture(ns.IconTexture(m.icon))
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

function Window.RefreshList()
    if not frame then return end
    local q = Query()
    local first, last = MacroRange(state.scope)
    local n = 0
    for index = first, last do
        local name, icon, body = GetMacroInfo(index)
        if name and Shown(q, state.scope, name, body) then
            n = n + 1
            local r = UseRow(n, "macro")
            r.index, r.name, r.scope, r.selected = index, name, state.scope, index == state.index
            r.icon:SetTexture(ns.IconTexture(icon))
            r.text:SetText(name)
            -- Marks follow the saved text: the one being edited shows its issues in the editor.
            r.severity, r.issues = MacroIssues(body)
            local alert = r.severity == "error"
            r.alert:SetShown(alert)
            r.text:SetPoint("RIGHT", alert and r.alert or r.copy, "LEFT", alert and -4 or -2, 0)
            r:Paint()
            r.bg:SetShown(r.selected)
        end
    end
    altHint:Hide()
    if state.scope == "character" and not notOnBars then n = AltRows(n, q) end
    for i = n + 1, #rows do rows[i]:Hide() end
    list.child:SetHeight(math.max(n * ROW_H + (altHint:IsShown() and 40 or 0), 1))
    noMatch:SetShown(n == 0 and (q ~= "" or notOnBars))

    -- While searching or filtering, the tabs say how many match.
    if q == "" and not notOnBars then
        local general, character = GetNumMacros()
        tabs.general.label:SetText(string.format(L["General  %d/%d"], general, MAX_GENERAL))
        tabs.character.label:SetText(string.format(L["Character  %d/%d"], character, MAX_CHARACTER))
    else
        tabs.general.label:SetText(string.format(L["General  (%d)"], CountMatches("general", q)))
        tabs.character.label:SetText(string.format(L["Character  (%d)"], CountMatches("character", q)))
    end
    for scope, tab in pairs(tabs) do tab.active = scope == state.scope; tab:Paint() end
end

------------------------------------------------------------------------
-- Editing
------------------------------------------------------------------------
local function Load(index)
    if index then
        local name, _, body = GetMacroInfo(index)
        state.index, state.name, state.icon, state.body = index, name, ns.MacroIcon(index) or NEW_ICON, body or ""
    else
        state.index, state.name, state.icon, state.body = nil, "", NEW_ICON, ""
    end
    state.savedIcon, state.iconPicked = state.icon, false
    nameBox:SetText(state.name)
    ShowIcon()
    ns.IconPicker.SetCurrent(state.icon)
    code:SetRaw(state.body, 0)
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
    if index == state.index then return end
    Guard(function() Load(index) end)
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

-- An empty new macro in the tab that is open, if the tab has a free slot.
local function Fresh()
    local first, last, max = MacroRange(state.scope)
    if last - first + 1 >= max then
        NoRoom(state.scope)
        return false
    end
    Load(nil)
    return true
end

function Window.New()
    Guard(function()
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
    if Letters(body) > MAX_BODY then return ns.Print("macro is longer than %d characters", MAX_BODY) end
    local index
    -- Earlier versions follow a new name.
    local renamed = state.index and name ~= state.name
    if renamed then ns.History.Renamed(state.scope, state.name, name) end
    if state.index then
        -- The game keeps macros sorted by name, so the index may change.
        index = EditMacro(state.index, name, state.icon, body)
    else
        index = CreateMacro(name, state.icon or NEW_ICON, body, state.scope == "character")
    end
    if not index or index == 0 then
        if renamed then ns.History.Renamed(state.scope, name, state.name) end
        return ns.Print("could not save the macro")
    end
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

-- A copy of macro `index` (the one being edited when nil) in `scope`, opened then. The one being edited is copied
-- with what the editor shows (name, icon, text) and keeps its saved text; another one as saved, after asking
-- about unsaved changes.
function Window.Copy(scope, index)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    index = index or state.index
    if not index then return end
    local first, last, max = MacroRange(scope)
    if last - first + 1 >= max then return NoRoom(scope) end
    local function make(name, icon, body)
        local copy = CreateMacro(FreeName(name), icon or NEW_ICON, body, scope == "character")
        if not copy or copy == 0 then return ns.Print("could not copy the macro") end
        ns.History.Scan()
        state.scope, ns.db.scope = scope, scope
        Load(copy)
    end
    if index ~= state.index then
        return Guard(function()
            local name, _, body = GetMacroInfo(index)
            make(name, ns.MacroIcon(index), body or "")
        end)
    end
    local body = code:GetRaw()
    if Letters(body) > MAX_BODY then return ns.Print("macro is longer than %d characters", MAX_BODY) end
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
        same = L["A copy in this tab with what the editor shows now, under a free name like \"Fear 2\". The macro "
            .. "copied keeps its saved text."],
        character = L["A copy for this character only with what the editor shows now, under a free name like "
            .. "\"Fear 2\". The macro copied keeps its saved text."],
        general = L["A copy for all your characters with what the editor shows now, under a free name like "
            .. "\"Fear 2\". The macro copied keeps its saved text."],
    } or {
        same = L["A copy in this tab, under a free name like \"Fear 2\"."],
        character = L["A copy for this character only, under a free name like \"Fear 2\"."],
        general = L["A copy for all your characters, under a free name like \"Fear 2\"."],
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
    if last - first + 1 >= max then return NoRoom(scope) end
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
        local made, first = 0, nil
        for _, p in ipairs(Window.ImportPlan(macros)) do
            if p.name then
                local m = p.macro
                CreateMacro(p.name, m.icon ~= "" and m.icon or NEW_ICON, m.body, m.scope == "character")
                made, first = made + 1, first or p
            end
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
        item(L["Export this macro"], state.index and L["Its code, as saved, to copy and share."]
            or L["Save the macro first, then export it."], function()
            ns.ShareWindow.Export({ { scope = state.scope, name = state.name, icon = state.savedIcon,
                body = state.body } })
        end, not state.index),
        item(string.format(L["Export the %s tab (%d)"], tab, here), L["The code of every macro in this tab."],
            function() ns.ShareWindow.Export(Macros(state.scope)) end, here == 0),
        item(string.format(L["Export all macros (%d)"], general + character),
            L["The code of every macro of both tabs; imported, each goes into its own tab."],
            function() ns.ShareWindow.Export(Macros()) end, general + character == 0),
        item(L["Import a code..."], L["Paste a code to make its macros. Nothing is replaced: a taken name gets a "
            .. "number, like \"Fear 2\"."], function() ns.ShareWindow.Import() end),
    }
end

------------------------------------------------------------------------
-- Trash: macros deleted anywhere, to bring back (History.lua keeps them)
------------------------------------------------------------------------
local TRASH_SHOWN = 12 -- deleted macros in the menu: the newest

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
    if last - first + 1 >= max then return NoRoom(scope) end
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
    for n = 1, math.min(#deleted, TRASH_SHOWN) do
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
    if #deleted > TRASH_SHOWN then
        items[#items + 1] = { name = ns.Plural(#deleted - TRASH_SHOWN, "%d older", "%d older"), disabled = true,
            onClick = noop }
    end
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
    text = "Restore the backup of %s?\n\nIts macros get their text and icon back and the missing ones are made "
        .. "again; macros made since stay. A backup of your macros now is made first.",
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
-- A name no macro has, cut to fit (see FreeName).
function Window.FreeName(name) return FreeName(FirstLetters(name, MAX_NAME)) end

-- The wizard's macro: saved in the tab `scope` under a free name, then opened in the editor.
function Window.CreateFromWizard(name, body, scope)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local first, last, max = MacroRange(scope)
    if last - first + 1 >= max then return NoRoom(scope) end
    if Letters(body) > MAX_BODY then return ns.Print("macro is longer than %d characters", MAX_BODY) end
    Guard(function()
        local index = CreateMacro(Window.FreeName(name), NEW_ICON, body, scope == "character")
        if not index or index == 0 then return ns.Print("could not save the macro") end
        ns.History.Scan()
        state.scope, ns.db.scope = scope, scope
        ns.WizardWindow.Close()
        Load(index)
    end)
end

-- The macro list changed elsewhere (Blizzard UI, another addon): keep our selection by name.
function Window.OnMacrosChanged()
    if not frame or not frame:IsShown() then return end
    if state.index then
        local name = GetMacroInfo(state.index)
        if name ~= state.name then
            local index = GetMacroIndexByName(state.name)
            state.index = index and index > 0 and index or nil
        end
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
    frame:SetFrameStrata("HIGH") -- below StaticPopup dialogs
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(MIN_W, MIN_H) else frame:SetMinResize(MIN_W, MIN_H) end
    local pos = ns.db.window
    frame:SetSize(math.max(pos and pos.w or 0, MIN_W), math.max(pos and pos.h or 0, MIN_H))
    frame:SetPoint(pos and pos.point or "CENTER", UIParent, pos and pos.relPoint or "CENTER", pos and pos.x or 0, pos and pos.y or 40)
    frame:EnableMouse(true)
    ns.Backdrop(frame, "bg", "border")
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

    -- The language: the texts are made in it, so switching it reloads the interface (asked in the new language).
    local languageDrop = ns.Dropdown(title, 104, function()
        return { { key = "en", name = L["English"] }, { key = "uk", name = L["Ukrainian"] } }
    end, function() return ns.db.language end, function(key)
        ns.db.language = key
        if key ~= ns.language then ns.Ask("MACROSENSE_RELOAD", nil, nil, nil, key) end
    end)
    languageDrop:SetPoint("RIGHT", close, "LEFT", -10, 0)
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
        GameTooltip:AddLine(L["See exactly how the macro will act: next to each line, what it would do if you "
            .. "pressed the macro now."], 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(string.format(L["Hold modifiers (%s), point the mouse at someone, change your target: use "
            .. "everything the macro checks to see which ability it uses, and when."], keys), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    previewCheck:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- Sidebar: tabs, list, buttons.
    local side = CreateFrame("Frame", nil, frame, "BackdropTemplate")
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
        GameTooltip:Show()
    end)
    shareBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    local trashBtn = ns.MenuButton(side, L["Trash"], 64, TrashItems, true)
    trashBtn:SetPoint("BOTTOM", 0, 8)
    trashBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Trash"], 1, 1, 1)
        GameTooltip:AddLine(string.format(L["Macros deleted by this addon, by any other or in the game's macro "
            .. "window land here, and you can bring them back. The trash keeps the last %d deleted macros of each "
            .. "tab; older ones are deleted by themselves. The menu shows the %d newest."], ns.History.TRASH,
            TRASH_SHOWN), 0.8, 0.8, 0.8, true)
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
    wizardBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["New (Wizard)"], 1, 1, 1)
        GameTooltip:AddLine(L["Create a new macro with the built-in wizard! Answer a few simple questions, or fill "
            .. "in the whole form at once: what to cast and on whom (mouseover, focus, party members, yourself, the "
            .. "cursor...), other spells on Shift, Ctrl or Alt, trinkets and more."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    wizardBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

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
        Window.RefreshList()
    end)
    search:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    search:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if rows[1] and rows[1]:IsShown() and rows[1].what == "macro" then Window.Select(rows[1].index) end
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
    list:SetPoint("BOTTOMRIGHT", -13, 66)
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
        if state.icon == NEW_ICON then
            GameTooltip:AddLine(L["Its icon is the question mark: the macro shows the icon of the spell or item it "
                .. "uses."], 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    iconFrame:RegisterForDrag("LeftButton")
    iconFrame:SetScript("OnDragStart", function() Window.Pickup(state.index) end)
    iconFrame:SetScript("OnClick", function()
        if ns.IconPicker.IsShown() then return ns.IconPicker.Close() end
        ns.IconPicker.Open(frame, state.icon, function(icon)
            state.icon, state.iconPicked = icon, true
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

    nameBox = ns.Input(main, 220, 16)
    nameBox:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
    nameBox:SetScript("OnTextChanged", function() UpdateStatus() end)
    -- Tab or Enter: on to the text. A new macro whose icon was not picked gets the icon of the spell or item it is
    -- named after (the question mark when none), unless #showtooltip in its text wants the question mark.
    local function NameDone()
        if not state.index and not state.iconPicked and not ("\n" .. code:GetRaw():lower()):find("\n%s*#show") then
            state.icon = ns.Completion.IconFor(nameBox:GetText()) or NEW_ICON
            ShowIcon()
            ns.IconPicker.SetCurrent(state.icon)
            UpdateStatus()
        end
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
        GameTooltip:AddLine(L["Tries to remove spaces the game doesn't need, shorten constructs and make the macro "
            .. "shorter overall, keeping everything it does. For example: target= becomes @, modifier becomes mod, "
            .. "[pet:Imp][pet:Felhunter] becomes [pet:Imp/Felhunter], [x] Fear; Fear becomes [x][]Fear."], 0.8, 0.8,
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
            GameTooltip:AddLine(string.format(L["Earlier saved versions of this macro. Pick one to put it in the "
                .. "editor: Save keeps it, %s takes it back."], undo), 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine(L["When you save a change to this macro, here or in the game's macro window, the "
                .. "text it had before is kept here."], 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    historyBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local nameHint = ns.Text(main, 11, "dim")
    nameHint:SetPoint("LEFT", nameBox, "RIGHT", 10, 0)
    nameHint:SetText(L["click or drag the icon"])
    nameHint:SetPoint("RIGHT", historyBtn, "LEFT", -12, 0)
    nameHint:SetWordWrap(false)

    -- Status bar: position, length, Save / Revert.
    local bar = CreateFrame("Frame", nil, main, "BackdropTemplate")
    bar:SetPoint("BOTTOMLEFT")
    bar:SetPoint("BOTTOMRIGHT")
    bar:SetHeight(36)
    ns.Backdrop(bar, "panel", "panel")
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
    saveBtn:SetPoint("RIGHT", -24, 0) -- room for the resize grip in the corner
    revertBtn = ns.Button(bar, L["Revert"], 90, Window.Revert)
    revertBtn:SetPoint("RIGHT", saveBtn, "LEFT", -6, 0)
    counter = ns.Text(bar, 11, "dim")
    counter:SetPoint("LEFT", 12, 0)
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
            GameTooltip:AddLine(string.format(L["Click to use \"%s\""], warning.shown.fix), 0.4, 1, 0.4)
        end
        GameTooltip:Show()
    end)
    warningHover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Click: replace the misspelled name with the suggestion.
    warningHover:SetScript("OnMouseUp", function()
        local e = warning.shown
        if not (e and e.fix) then return end
        local raw = code:GetRaw()
        code:SetRaw(raw:sub(1, e.from - 1) .. e.fix .. raw:sub(e.to + 1), e.from - 1 + #e.fix, true)
        code:CheckNow()
        GameTooltip:Hide()
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
    -- Issues are found a frame after each change: the status bar and the preview follow them.
    code.onErrors = function()
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
    end)

    Window.ApplyLook()
end

function Window.Toggle()
    if not frame then Build() end
    if frame:IsShown() then return frame:Hide() end
    state.scope = ns.db.scope or "general"
    frame:Show()
    if IsDirty() then return end
    -- Reload: the macro may have changed in the Blizzard UI while we were closed.
    local index = state.name and state.name ~= "" and GetMacroIndexByName(state.name)
    if index and index > 0 then return Load(index) end
    local first, last = MacroRange(state.scope)
    Load(last >= first and first or nil)
end

-- The editor on macro `index`, opened if it is closed (Shift + right-click on an action bar). Unsaved changes
-- to another macro are asked about first; the macro's own stay. Below Build, like Toggle: it may build the
-- window, and a local function is only seen after it.
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
