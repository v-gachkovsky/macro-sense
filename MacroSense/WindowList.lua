-- The editor's macro list: the tabs' macros, other characters' (History.Scan keeps them), and with macro sets on
-- those behind the scenes, in groups; search, dragging and the "..." menus. The window and its widgets are made in
-- Window.lua (ns.WindowShared).
local _, ns = ...
local L = ns.L

local Window, shared = ns.Window, ns.WindowShared
local state, expanded, groupOpen = shared.state, shared.expanded, shared.groupOpen
local MAX_GENERAL, MAX_CHARACTER, NEW_ICON = shared.MAX_GENERAL, shared.MAX_CHARACTER, shared.NEW_ICON
local NO_ICON, PLUS_ICON, PLUS, MINUS, ROW_H = shared.NO_ICON, shared.PLUS_ICON, shared.PLUS, shared.MINUS, shared.ROW_H
local MacroRange, TabName, When = shared.MacroRange, shared.TabName, shared.When
local AddIssueLines, AddHintNote, AddLockNote = shared.AddIssueLines, shared.AddHintNote, shared.AddLockNote
local FoundIcon, ShowFound, LockMark, Locked = shared.FoundIcon, shared.ShowFound, shared.LockMark, shared.Locked

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
        if c ~= mine and ((c.macros and next(c.macros)) or c.sets) then
            -- Those in its slots, then those of its sets behind the scenes, each with its set; the class's of your
            -- class are yours too, not listed.
            local macros, have = {}, {}
            for name, m in pairs(c.macros or {}) do
                macros[#macros + 1] = { name = name, icon = m.icon, body = m.body or "" }
                have[name .. "\0" .. (m.body or "")] = true
            end
            for _, set in ipairs(Window.SetsData(key).sets) do
                if set.id ~= "class" or c.class ~= mine.class then
                    for _, m in ipairs(set.macros) do
                        local id = m.name .. "\0" .. m.body
                        if not have[id] then
                            have[id] = true
                            macros[#macros + 1] = { name = m.name, icon = m.icon, body = m.body, behind = set.label }
                        end
                    end
                end
            end
            table.sort(macros, function(a, b)
                if (a.behind ~= nil) ~= (b.behind ~= nil) then return a.behind == nil end
                return a.name < b.name
            end)
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

-- A menu item that makes a macro in tab `scope`, unless it is full. The Character tab full with macro sets on: the
-- macro goes behind the scenes.
local function TabItem(scope, label, tip, onClick)
    local first, last, max = MacroRange(scope)
    local full = last - first + 1 >= max
    local behind = full and scope == "character" and ns.Sets.Mine().enabled
    if behind then
        full, tip = false, L["All 30 slots are taken: it goes behind the scenes, in \"This character's\"."]
        label = string.format("%s  |cff%s%s|r", label, ns.scheme.dim, L["(behind the scenes)"])
    end
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
    GameTooltip:AddLine(string.format(L["Its own macros, those behind the scenes too, as they were "
        .. "when you last played it: %s. Click to show or hide them."], When(alt.c.seen or 0)), 0.8, 0.8, 0.8, true)
end

local function AddAltMacroLines(alt, m)
    GameTooltip:AddLine(m.name, 1, 1, 1)
    GameTooltip:AddLine(string.format(L["A macro of %s. Click to copy it."], alt.label), 0.8, 0.8, 0.8, true)
    if m.behind then
        GameTooltip:AddLine(string.format(L["Behind the scenes there, in \"%s\"."], m.behind), 0.8, 0.8, 0.8, true)
    end
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
    local r = CreateFrame("Button", nil, shared.list.child)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.pick = r:CreateTexture(nil, "BACKGROUND", nil, 1) -- picked with Ctrl+click (WindowPick.lua)
    r.pick:SetAllPoints()
    r.pick:Hide()
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
    -- At the end: "..." (a menu: copied in this tab or the other one, moved there, and what the sets do) and x
    -- (delete, after asking). Another character has an x (forget it), its macros a "...".
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
    -- "...": copied, moved to the other tab and, with macro sets on, what can be done with it in the sets (a right
    -- click too).
    r.copy = ns.RowButton(r, "...", "text", lit, function() return L["Copy, move and more"] end, function()
        Window.OpenRowMenu(r.copy, r)
    end)
    r.copy:SetPoint("RIGHT", r.remove, "LEFT")
    r.more = r.copy
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
            shared.AddNoteLine("character", r.name)
            AddIssueLines(r.issues or {})
            GameTooltip:AddLine(L["Behind the scenes: not in the game now, and on no slot."], 0.6, 0.6, 0.6, true)
            if r.kept then
                GameTooltip:AddLine(L["Kept behind the scenes: it doesn't come into the game when you choose this "
                    .. "specialization."], 0.6, 0.6, 0.6, true)
            end
            Window.AddSetsNote(r)
        else
            GameTooltip:AddLine(r.text:GetText(), 1, 1, 1)
            shared.AddNoteLine(r.scope, r.name)
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
            if r.copy:IsShown() then Window.OpenRowMenu(r, r) end
            -- A group's name: pick all of it.
            if r.what == "group" or r.what == "head" then shared.OpenGroupPick(r) end
            return
        end
        -- Ctrl+click (Cmd on a Mac): picked, or no longer, for many at once.
        if (r.what == "macro" or r.what == "stored") and ns.CtrlDown() then return shared.TogglePick(r) end
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
    -- Onto the other tab, moved or (Ctrl) copied there. With macro sets on, also anywhere in the list: into another
    -- set, in the game or behind the scenes.
    r:SetScript("OnDragStart", function()
        if r.what == "macro" then Window.Pickup(r.index) end
        if r.what == "macro" or r.what == "stored" then Window.dragging, Window.copying = r, IsControlKeyDown() end
        -- Behind the scenes, the game puts nothing on the cursor: its icon and name follow the mouse instead.
        if r.what == "stored" then Window.ShowGhost(r) end
        if Window.dragging == r then Window.Watch() end
    end)
    r:SetScript("OnDragStop", function()
        Window.HideGhost()
        Window.DragOver(nil)
        if Window.dragging ~= r then return end
        Window.dragging = nil
        for scope, tab in pairs(shared.tabs or {}) do
            if tab:IsShown() and tab:IsMouseOver() then
                return Window.DropOnTab(r, scope, Window.copying or IsControlKeyDown())
            end
        end
        if not r.set then return end
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
        -- Kept behind the scenes: grey, unless it has errors to show.
        local dim = self.what == "altMacro" or self.what == "head" or (self.kept and color == s.text)
        self.text:SetTextColor(ns.RGB(dim and s.dim or color))
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
local function Query() return strtrim(shared.search:GetText() or ""):lower() end

-- With "With mistakes", only a macro with a mistake or a warning.
local function Matches(q, name, body)
    if shared.mistakes and not MacroIssues(body) then return false end
    return q == "" or name:lower():find(q, 1, true) ~= nil or (body or ""):lower():find(q, 1, true) ~= nil
end

-- What the list shows: the macros the search matches (Matches), and with "Not on action bars" only those on no bar, of
-- this character's specializations and, for a general macro, of your other characters as last seen.
local function Shown(q, scope, name, body)
    if not Matches(q, name, body) then return false end
    if not shared.notOnBars then return true end
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
    r.depth = depth or (what == "altMacro" and 1 or 0)
    r.pick:Hide()
    r.tone, r.toggle, r.set, r.dropId, r.dropIn = tone, false, nil, nil, nil
    r.icon:SetPoint("LEFT", 6 + 12 * (depth or (what == "altMacro" and 1 or 0)), 0)
    local plain = what == "alt" or what == "group" or what == "head"
    if plain then r.icon:SetTexCoord(0, 1, 0, 1) else r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    r.band:Hide()
    r.copy:SetShown(what == "macro" or what == "altMacro" or what == "stored")
    r.remove:SetShown(what == "macro" or what == "alt" or what == "stored")
    r.alert:ClearAllPoints()
    r.alert:SetPoint("RIGHT", r.copy, "LEFT", -2, 0)
    r.alert:Hide()
    r.mark:Hide()
    r.auto, r.kept = false, false
    r.icon:SetDesaturated(false)
    r.icon.hint = false
    r.text:ClearAllPoints()
    r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
    if what == "group" or what == "head" then
        r.text:SetPoint("RIGHT", -6, 0)
    else
        r.text:SetPoint("RIGHT", what == "alt" and r.remove or r.copy, "LEFT", -2, 0)
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
                r.text:SetText(m.behind and string.format("%s  |cff%s%s|r", m.name, ns.scheme.dim, m.behind) or m.name)
                r:Paint()
            end
        end
    end
    -- None known yet: they show once you play them with MacroSense.
    shared.altHint:ClearAllPoints()
    shared.altHint:SetPoint("TOPLEFT", 8, -n * ROW_H - 6)
    shared.altHint:SetPoint("TOPRIGHT", -8, -n * ROW_H - 6)
    shared.altHint:SetShown(#alts == 0 and q == "")
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

-- A row picked with Ctrl+click: tinted in the scheme's accent.
local function ShowPick(r)
    local on = shared.IsPicked(r)
    r.pick:SetShown(on)
    if on then r.pick:SetColorTexture(ns.RGB(ns.scheme.accent)); r.pick:SetAlpha(0.3) end
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
    ShowPick(r)
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
    -- Kept behind the scenes in a specialization not chosen now: it won't come in with it. Grey.
    r.kept = not ns.Sets.InGame(id) and ns.Sets.IsParked(id, m) and true or false
    if r.kept then r.icon:SetDesaturated(true) end
    r.text:SetText(m.name)
    r.severity, r.issues = MacroIssues(m.body)
    r:Paint()
    r.bg:SetShown(r.selected)
    ShowPick(r)
end

-- The macros behind the scenes of set `id` that the search finds.
local function Behind(id, q)
    local out = {}
    for _, m in ipairs(ns.Sets.List(id)) do
        if ns.Sets.Behind(id, m) and Matches(q, m.name, m.body) then out[#out + 1] = m end
    end
    return out
end

-- Row `r` of set `id`, in the game or behind the scenes (`inGame`): its "..." has what can be done with a macro
-- there in the sets, and a macro dropped on the row goes there.
local function Belongs(r, id, inGame)
    r.dropId, r.dropIn = id, inGame
    if r.what ~= "macro" and r.what ~= "stored" then return end
    r.set = id
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
    if shared.notOnBars then return n end
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
local function SetsItems(r, parts)
    local Sets, id, name = ns.Sets, r.set, r.name
    local items, m = {}, nil
    for _, x in ipairs(Sets.List(id)) do if x.name == name then m = x end end
    if not m then return items end
    local parked = Sets.IsParked(id, m) or (Sets.InGame(id) and Sets.Behind(id, m))
    -- In a specialization not chosen now the macro is behind the scenes either way: the item says what happens
    -- when you choose it.
    local label = parked and L["Take in"] or L["Put away"]
    if not Sets.InGame(id) then
        label = parked and L["Come in with its specialization"] or L["Keep behind the scenes"]
    end
    items[#items + 1] = { name = label, onClick = function()
        local ok, why = Sets.Park(id, name, not parked)
        Window.Told(ok, why, { name = name, to = id, park = parked and "in" or "out" })
    end }
    -- Its copy in its set, and the other tab with the other sets (`parts`: { dup, move, copy }; behind the scenes,
    -- these below).
    if r.what == "stored" then
        parts = {
            dup = { name = L["Duplicate"], onClick = function() Window.Duplicate(id, name) end,
                onEnter = function(row)
                    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(L["Duplicate"], 1, 1, 1)
                    GameTooltip:AddLine(L["Makes a copy in the same set, behind the scenes, named like \"Fear 2\"."],
                        0.8, 0.8, 0.8, true)
                    GameTooltip:Show()
                end },
            move = TabItem("general", string.format(L["Move to: %s"], TabName("general")), L["Into the General tab, "
                .. "for all your characters: it leaves its set and comes into the game. Its history goes with it."],
                function() Window.StoredToGeneral(id, name, true) end),
            copy = TabItem("general", string.format(L["Copy to: %s"], TabName("general")), L["Makes a copy for all "
                .. "your characters, named like \"Fear 2\". This one stays where it is."],
                function() Window.StoredToGeneral(id, name, false) end),
        }
    end
    parts = parts or {}
    items[#items + 1] = parts.dup
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
    items[#items + 1] = parts.move
    for _, set in ipairs(sets) do
        local label = ns.SetsWindow.Label(set.id)
        if set.id ~= id then
            items[#items + 1] = { name = string.format(L["Copy to: %s"], label), onClick = function()
                local ok, why = Sets.MoveTo(id, name, set.id, true)
                Window.Told(ok, why, { name = name, to = set.id, copy = true })
            end }
        end
    end
    items[#items + 1] = parts.copy
    if id ~= "character" then
        items[#items + 1] = { name = L["Remove"], onClick = function()
            local ok, why = Sets.Release(id, name)
            Window.Told(ok, why, { name = name, to = "character" })
        end }
    end
    return items
end


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
        return string.format(L["\"%s\" stays behind the scenes, also when you choose its specialization. "
            .. "\"Come in with its specialization\" undoes it."], name)
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
-- The sign just above the dragged macro's icon: on it, the mouse pointer (and the game's icon of a macro in the game,
-- drawn over everything) would cover it.
local function MarkAt()
    mark:ClearAllPoints()
    if ghost and ghost:IsShown() then return mark:SetPoint("BOTTOM", ghost.icon, "TOP", 0, 3) end
    -- The game's icon hangs from the mouse to the right and down.
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    mark:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", x / scale + 16, y / scale + 3)
end
function Window.Watch()
    if not mark then
        mark = CreateFrame("Frame", nil, UIParent)
        mark:SetFrameStrata("TOOLTIP")
        mark:SetFrameLevel(100)
        mark:SetSize(27, 27)
        mark.icon = mark:CreateTexture(nil, "OVERLAY")
        mark.icon:SetAllPoints()
        mark:Hide()
        -- Follows the mouse while the drag lasts: the row under it, Ctrl held or let go.
        mark.watch = CreateFrame("Frame", nil, UIParent)
        mark.watch:SetScript("OnUpdate", function()
            if not Window.dragging then return mark.watch:Hide() end
            local at, tab
            for scope, t in pairs(shared.tabs or {}) do if t:IsShown() and t:IsMouseOver() then tab = scope end end
            for _, target in ipairs(rows) do
                if not tab and target:IsShown() and target.dropId and target:IsMouseOver() then at = target end
            end
            Window.DragOver(at, tab)
            if mark:IsShown() then MarkAt() end
        end)
    end
    mark.watch:Show()
end

-- The sign by the dragged macro, if one is shown (the tests).
function Window.DragSign() return mark ~= nil and mark:IsShown() and mark.sign or nil end

-- The dragged macro over tab `scope`: the sign and the tooltip, as over a group.
local function OverTab(source, scope)
    local copy = (Window.copying or IsControlKeyDown()) and true or false
    local ok, why = Window.TabPlan(source, scope, copy)
    local key = table.concat({ scope, tostring(copy), tostring(ok), tostring(why) }, " ")
    if key == over then return end
    over = key
    mark.sign = not ok and NO_ICON or PLUS_ICON
    mark.icon:SetTexture(mark.sign)
    mark:SetShown(not ok or copy)
    if mark:IsShown() then MarkAt() end
    local label = TabName(scope)
    GameTooltip:SetOwner(shared.tabs[scope], "ANCHOR_RIGHT")
    if ok then
        GameTooltip:SetText(string.format(copy and L["Copy to \"%s\""] or L["Move to \"%s\""], label), 0.3, 0.75,
            0.3)
        GameTooltip:AddLine(copy and L["A macro of its own goes there; this one stays as it is. Let go of Ctrl to "
            .. "move it instead."] or L["It leaves this tab and goes there. Hold Ctrl to copy it instead."],
            1, 1, 1, true)
        if why == "behind" then
            GameTooltip:AddLine(L["All 30 slots are taken: it goes behind the scenes, in \"This character's\"."],
                0.8, 0.8, 0.8, true)
        end
    else
        GameTooltip:SetText(string.format(copy and L["Can't copy to \"%s\""] or L["Can't move to \"%s\""], label),
            1, 0.3, 0.3)
        GameTooltip:AddLine(Window.TabWhy(why, scope), 1, 1, 1, true)
    end
    GameTooltip:Show()
end

-- The dragged macro over row `target` (nil: over none, or let go) or tab `tab`: the sign and the tooltip, as Ctrl is
-- now.
function Window.DragOver(target, tab)
    local source = Window.dragging
    if source and tab and mark then return OverTab(source, tab) end
    if not (source and source.set and target and target.dropId) or target == source then
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
    shared.side:SetWidth(width)
    for _, row in ipairs(shared.sideRows or {}) do
        for _, b in ipairs(row) do b:SetWidth((width - 16 - 6 * (#row - 1)) / #row) end
    end
end

function Window.RefreshList()
    if not shared.frame then return end
    local setsOn = ns.Sets.Mine().enabled
    Window.SideWidth(setsOn and 280 or 220)
    shared.sortBtn:SetShown(setsOn)
    shared.sortBtn:SetEnabled(#ns.Sets.Unvisited() == 0)
    shared.sortBtn:SetAlpha(shared.sortBtn:IsEnabled() and 1 or 0.4)
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
    shared.altHint:Hide()
    -- Your other characters' macros: not with the filters, they are for this character's.
    if state.scope == "character" and not shared.notOnBars and not shared.mistakes then n = AltRows(n, q) end
    for i = n + 1, #rows do rows[i]:Hide() end
    local height = math.max(n * ROW_H + (shared.altHint:IsShown() and 40 or 0), 1)
    shared.list.child:SetHeight(height)
    -- Fewer rows than before: not scrolled past the last.
    local bottom = math.max(0, height - shared.list:GetHeight())
    if shared.list:GetVerticalScroll() > bottom then shared.list:SetVerticalScroll(bottom) end
    local filtered = q ~= "" or shared.notOnBars or shared.mistakes
    shared.noMatch:SetText(shared.mistakes and q == "" and not shared.notOnBars and L["No mistakes found"]
        or L["No macros match"])
    shared.noMatch:SetShown(n == 0 and filtered)

    -- While searching or filtering, the tabs say how many match.
    if not filtered then
        local general, character = GetNumMacros()
        shared.tabs.general.label:SetText(string.format(L["General  %d/%d"], general, MAX_GENERAL))
        local behind = ns.Sets.Mine().enabled and BehindCount() or 0
        shared.tabs.character.label:SetText(behind > 0
            and string.format(L["Character  %d/%d  +%d"], character, MAX_CHARACTER, behind)
            or string.format(L["Character  %d/%d"], character, MAX_CHARACTER))
    else
        shared.tabs.general.label:SetText(string.format(L["General  (%d)"], CountMatches("general", q)))
        shared.tabs.character.label:SetText(string.format(L["Character  (%d)"], CountMatches("character", q)))
    end
    for scope, tab in pairs(shared.tabs) do tab.active = scope == state.scope; tab:Paint() end
    shared.RefreshPicks()
end

shared.rows = rows
shared.FollowRowIcons, shared.OpenAltCopyMenu, shared.SetsItems = FollowRowIcons, OpenAltCopyMenu, SetsItems
shared.SetsShown, shared.TabItem = SetsShown, TabItem
