-- Multi-line EditBox with syntax highlighting. The EditBox holds colored text; callers only see raw text.
local _, ns = ...

local H = ns.Highlight
local UNDO_LIMIT = 200
local INSET_T = 4    -- text inset at the top; the left one follows the line number gutter (self.insetL)
local INSET_R = 6    -- text inset on the right, plus the notes column when it is shown (self.insetR)
local GUTTER_PAD = 6 -- space around the line numbers
local NOTE_PAD = 6   -- space around the notes
local UNDO_GROUP = 0.8 -- keystrokes closer than this (seconds) undo together
local TYPING_PAUSE = 0.8 -- seconds after the last key: then the word being typed is checked too

local CodeBox = {}
CodeBox.__index = CodeBox

local function Debug(...)
    if ns.db and ns.db.debug then ns.Print(...) end
end

-- parent: frame to fill; name: global name of the scroll frame.
-- Callbacks (set by the owner): onChange(raw, userInput), onCaret(x, y, h), onKey(key) -> true when consumed
function ns.CreateCodeBox(parent, name)
    local self = setmetatable({ undo = {}, redo = {}, colors = { text = "ffffff" } }, CodeBox)

    local scroll = CreateFrame("ScrollFrame", name, parent)
    self.scroll = scroll
    self.bar = ns.AttachScrollBar(scroll, 42)

    local edit = CreateFrame("EditBox", nil, scroll)
    self.edit = edit
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    self.insetL, self.insetR = GUTTER_PAD, INSET_R
    edit:SetTextInsets(self.insetL, self.insetR, INSET_T, 4)
    self.underlines, self.numbers, self.notes, self.lineTops = {}, {}, {}, {}
    edit:HookScript("OnSizeChanged", function() self:ScheduleUnderlines() end)
    edit:SetFont(ns.fonts[1].path, 13, "")
    scroll:SetScrollChild(edit)

    -- Line number gutter: the strip stays put, the numbers are in the text and scroll with it.
    self.gutterBg = scroll:CreateTexture(nil, "BACKGROUND")
    self.gutterBg:SetPoint("TOPLEFT", -3, 3)
    self.gutterBg:SetPoint("BOTTOMLEFT", -3, -3)
    self.gutterLine = scroll:CreateTexture(nil, "BORDER")
    self.gutterLine:SetWidth(1)
    self.gutterLine:SetPoint("TOPLEFT", self.gutterBg, "TOPRIGHT")
    self.gutterLine:SetPoint("BOTTOMLEFT", self.gutterBg, "BOTTOMRIGHT")
    -- Notes column on the right (the live preview), the same way: the strip stays, the notes scroll.
    self.notesBg = scroll:CreateTexture(nil, "BACKGROUND")
    self.notesBg:SetPoint("TOPRIGHT", 0, 3)
    self.notesBg:SetPoint("BOTTOMRIGHT", 0, -3)
    self.notesBg:Hide()
    self.notesLine = scroll:CreateTexture(nil, "BORDER")
    self.notesLine:SetWidth(1)
    self.notesLine:SetPoint("TOPRIGHT", self.notesBg, "TOPLEFT")
    self.notesLine:SetPoint("BOTTOMRIGHT", self.notesBg, "BOTTOMLEFT")
    self.notesLine:Hide()
    scroll:SetScript("OnSizeChanged", function(_, w) edit:SetWidth(w) end)

    -- Clicks below the last line still focus the text.
    local catcher = CreateFrame("Button", nil, scroll)
    catcher:SetAllPoints()
    catcher:SetFrameLevel(scroll:GetFrameLevel())
    catcher:SetScript("OnClick", function()
        edit:SetFocus()
        edit:SetCursorPosition(#edit:GetText())
    end)

    edit:SetScript("OnTextChanged", function(e, userInput)
        if self.updating then return end
        local colored = e:GetText()
        local raw = H.Strip(colored)
        if userInput then
            local cursor = H.ToRaw(colored, e:GetCursorPosition())
            -- Backspace / Delete took an invisible color code instead of a character: remove the character.
            local old = self.raw or ""
            if raw == old and self.keyDownTime == GetTime() then
                if self.keyDown == "BACKSPACE" and cursor > 0 then
                    raw, cursor = raw:sub(1, cursor - 1) .. raw:sub(cursor + 1), cursor - 1
                elseif self.keyDown == "DELETE" then
                    raw = raw:sub(1, cursor) .. raw:sub(cursor + 2)
                end
            end
            raw, cursor = ns.Editing.AutoPair(old, raw, cursor)
            self:PushUndo()
            self:Render(raw, cursor)
            self:Typed()
        end
        self.raw = raw
        if self.onChange then self.onChange(raw, userInput) end
    end)

    edit:SetScript("OnCursorChanged", function(e, x, y, w, h)
        if self.measuring then
            self.measured = { x = x, y = y, h = h }
            return
        end
        if ScrollingEdit_OnCursorChanged then ScrollingEdit_OnCursorChanged(e, x, y, w, h) end
        -- A new row height (the font size changed): numbers and underlines move with it.
        if h ~= self.caretH then self:ScheduleUnderlines() end
        self.caretX, self.caretY, self.caretH = x, y, h
        self.lastCursor = H.ToRaw(e:GetText(), e:GetCursorPosition())
        self:HighlightLineNumber()
        if self.lockCursor and e:GetCursorPosition() ~= self.lockCursor then
            Debug("cursor locked at %d", self.lockCursor)
            e:SetCursorPosition(self.lockCursor)
            return
        end
        if self.onCaret then self.onCaret(x, y, h) end
    end)
    edit:SetScript("OnUpdate", function(e, elapsed)
        self.frameRaw = self:GetRaw() -- text as of the last frame, see NewlineFallback
        if ScrollingEdit_OnUpdate then ScrollingEdit_OnUpdate(e, elapsed, scroll) end
    end)
    edit:SetScript("OnEscapePressed", function(e)
        if not self:Key("ESCAPE", "script") then e:ClearFocus() end
    end)
    edit:SetScript("OnTabPressed", function() self:Key("TAB", "script") end)
    edit:SetScript("OnEnterPressed", function() self:Key("ENTER", "script") end)
    edit:SetScript("OnArrowPressed", function(_, key) self:Key(key, "arrow") end)
    edit:SetScript("OnKeyDown", function(_, key)
        self.keyDown, self.keyDownTime = key, GetTime()
        local mod = IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())
        if mod and key == "Z" then
            if IsShiftKeyDown() then self:Redo() else self:Undo() end
        elseif mod and key == "Y" then
            self:Redo()
        else
            self:Key(key, "keydown")
        end
    end)
    edit:SetScript("OnMouseDown", function() self.lockCursor = nil end)
    return self
end

-- A key may arrive twice in one frame (OnKeyDown and OnArrowPressed / OnEnterPressed ...): handle it once.
function CodeBox:Key(key, source)
    Debug("key %s (%s)", key, source)
    if key ~= "UP" and key ~= "DOWN" and key ~= "PAGEUP" and key ~= "PAGEDOWN" then self.lockCursor = nil end
    local now = GetTime()
    if self.lastKey == key and self.lastKeyTime == now and self.lastKeySource ~= source then
        return self.lastKeyResult
    end
    if key == "NUMPADENTER" then key = "ENTER" end
    local result = self.onKey and self.onKey(key) or false
    self.lastKey, self.lastKeyTime, self.lastKeySource, self.lastKeyResult = key, now, source, result
    if key == "ENTER" and not result then self:NewlineFallback() end
    return result
end

-- A multi-line EditBox with an OnEnterPressed script may not insert the newline itself.
-- If the text did not change this frame or the next one, insert it here.
function CodeBox:NewlineFallback()
    local raw, cursor = self:GetRaw(), self:GetRawCursor()
    if self.frameRaw and raw ~= self.frameRaw then return end -- the EditBox already did it
    C_Timer.After(0, function()
        if self:GetRaw() ~= raw then return end
        self:PushUndo(true)
        local newRaw = raw:sub(1, cursor) .. "\n" .. raw:sub(cursor + 1)
        self:Render(newRaw, cursor + 1)
        if self.onChange then self.onChange(newRaw, true) end
    end)
end

-- Recolor raw text and put the cursor at raw position `cursor`.
function CodeBox:Render(raw, cursor)
    local colored = H.Colorize(raw, self.colors)
    self.updating = true
    if colored ~= self.edit:GetText() then self.edit:SetText(colored) end
    self.updating = false
    if cursor then self.edit:SetCursorPosition(H.ToColored(colored, cursor)) end
    self.raw = raw
    self:ScheduleUnderlines()
end

------------------------------------------------------------------------
-- Text layout: line numbers and error underlines, redrawn a frame after the text or its look changes.
------------------------------------------------------------------------
function CodeBox:ScheduleUnderlines()
    if self.underlinePending then return end
    self.underlinePending = true
    C_Timer.After(0, function()
        self.underlinePending = false
        -- A wider gutter or notes column moves and re-wraps the text: measure again on the next frame.
        if self:DrawLineNumbers() then return self:ScheduleUnderlines() end
        self:DrawUnderlines()
    end)
end

-- A hidden FontString in the editor's font measures text the way the EditBox lays it out.
function CodeBox:Measurer()
    local fs = self.measurer
    if not fs then
        fs = self.edit:CreateFontString(nil, "BACKGROUND")
        fs:SetAlpha(0)
        fs:SetWordWrap(true)
        self.measurer = fs
    end
    fs:SetFont(self.edit:GetFont())
    return fs
end

-- Rows a line takes once wrapped to the text width.
function CodeBox:Rows(text)
    local fs = self:Measurer()
    fs:SetWidth(self.edit:GetWidth() - self.insetL - self.insetR)
    fs:SetText(text ~= "" and text or " ")
    return math.max(1, fs.GetNumLines and fs:GetNumLines() or 1)
end

-- Width of text on one row. Trailing spaces do not count in a string's width: measure with a letter after.
function CodeBox:TextWidth(text)
    local fs = self:Measurer()
    fs:SetWidth(0)
    local function w(t)
        fs:SetText(t)
        return fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
    end
    return w(text .. "x") - w("x")
end

-- Height of a row: the cursor's height once the game reported it for this font, else two rows minus one.
function CodeBox:LineHeight()
    if self.caretH then return self.caretH end
    local fs = self:Measurer()
    fs:SetWidth(0)
    fs:SetText("A\nA")
    local two = fs:GetStringHeight()
    fs:SetText("A")
    return two - fs:GetStringHeight()
end

------------------------------------------------------------------------
-- Line numbers: one per line of the macro, on the first row of a wrapped line.
------------------------------------------------------------------------
-- Width of the notes column: 30% of the editor, 140 to 240 px.
local function NotesWidth(editWidth)
    return math.floor(math.max(140, math.min(240, editWidth * 0.3)))
end

-- Returns true when the gutter or the notes column changed width (the text then moves: measure again).
function CodeBox:DrawLineNumbers()
    local lines = {}
    for l in (self:GetRaw() .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = l end
    local digits = math.max(2, #tostring(#lines))
    local gutter = math.ceil(self:TextWidth(string.rep("0", digits))) + 2 * GUTTER_PAD
    local notes = self.notesShown and NotesWidth(self.edit:GetWidth()) or 0
    if gutter ~= self.gutterWidth or notes ~= self.notesWidth then
        self.gutterWidth, self.insetL = gutter, gutter + GUTTER_PAD
        self.notesWidth, self.insetR = notes, INSET_R + notes
        self.edit:SetTextInsets(self.insetL, self.insetR, INSET_T, 4)
        self.gutterBg:SetWidth(gutter + 3)
        self.notesBg:SetWidth(math.max(notes, 1))
        self.notesBg:SetShown(notes > 0)
        self.notesLine:SetShown(notes > 0)
        return true
    end
    local h, above, tops = self:LineHeight(), 0, {}
    for i, line in ipairs(lines) do
        local fs = self.numbers[i]
        if not fs then
            fs = self.edit:CreateFontString(nil, "OVERLAY")
            fs:SetJustifyH("RIGHT")
            fs.isLineNumber = true
            self.numbers[i] = fs
        end
        fs:SetFont(self.edit:GetFont())
        fs:SetWidth(gutter - GUTTER_PAD)
        fs:ClearAllPoints()
        tops[i] = -INSET_T - above * h
        fs:SetPoint("TOPLEFT", self.edit, "TOPLEFT", 0, tops[i])
        fs:SetText(i)
        fs:Show()
        above = above + self:Rows(line)
    end
    for i = #lines + 1, #self.numbers do self.numbers[i]:Hide() end
    self.lineCount, self.lineTops, self.rowHeight = #lines, tops, h
    self:HighlightLineNumber()
    self:DrawNotes()
    return false
end

------------------------------------------------------------------------
-- Notes: a short text per line in a column on the right (the live preview), on the line's first row.
------------------------------------------------------------------------
-- Show or hide the column; hidden, the text gets its room back.
function CodeBox:ShowNotes(on)
    self.notesShown = on and true or false
    self:DrawNotes()
    self:ScheduleUnderlines()
end

-- notes: one string per line, with color codes; "" for none.
function CodeBox:SetLineNotes(notes)
    local old = self.lineNotes
    if old and #old == #notes then
        local same = true
        for i, note in ipairs(notes) do
            if note ~= old[i] then same = false; break end
        end
        if same then return end
    end
    self.lineNotes = notes
    self:DrawNotes()
end

function CodeBox:DrawNotes()
    local notes = self.lineNotes or {}
    local width = self.notesShown and self.notesWidth or 0
    local _, size = self.edit:GetFont()
    for i = 1, math.max(#notes, #self.notes) do
        local fs, text, top = self.notes[i], notes[i], self.lineTops[i]
        if not fs then -- one per line, no holes: all of them get hidden when the macro gets shorter
            fs = self.edit:CreateFontString(nil, "OVERLAY")
            fs:SetJustifyH("LEFT")
            fs:SetJustifyV("MIDDLE")
            fs:SetWordWrap(false)
            fs.isNote = true
            self.notes[i] = fs
        end
        if width > 0 and top and text and text ~= "" then
            fs:SetFont(ns.UIFont(), math.max(9, (size or 13) - 2), "")
            fs:SetWidth(width - 2 * NOTE_PAD)
            fs:SetHeight(self.rowHeight or 14)
            fs:ClearAllPoints()
            fs:SetPoint("TOPRIGHT", self.edit, "TOPRIGHT", -NOTE_PAD, top)
            fs:SetText(text)
            fs:Show()
        else
            fs:Hide()
        end
    end
end

-- The cursor's line number is bright, the others dim.
function CodeBox:HighlightLineNumber()
    if not self.lineColors then return end
    local current = select(2, self:GetRaw():sub(1, self.lastCursor or 0):gsub("\n", "")) + 1
    for i, fs in ipairs(self.numbers) do
        fs:SetTextColor(ns.RGB(i == current and self.lineColors.text or self.lineColors.dim))
    end
end

-- The number of the line the mouse is on, when it is over the line numbers or the notes column (not the text):
-- nil elsewhere.
function CodeBox:HoveredLine()
    local tops = self.lineTops
    if not self.scroll:IsMouseOver() or #tops == 0 then return nil end
    local left, right, top = self.scroll:GetLeft(), self.scroll:GetRight(), self.edit:GetTop()
    if not (left and right and top) then return nil end
    local scale = self.edit:GetEffectiveScale() or 1
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    local onNumbers = x <= left + (self.gutterWidth or 0)
    local onNotes = self.notesShown and x >= right - (self.notesWidth or 0)
    if not (onNumbers or onNotes) then return nil end
    local down = y - top -- from the top of the text, so below it is negative
    local lines = {}
    for l in (self:GetRaw() .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = l end
    for i = 1, #tops do
        local bottom = tops[i + 1] or (tops[i] - self:Rows(lines[i] or "") * (self.rowHeight or 14))
        if down <= tops[i] and down > bottom then return i end
    end
    return nil
end

-- The raw position (1-based) of the letter under the mouse in the text, or nil off the text. A wrapped line is
-- split into its rows as the measurer wraps it.
function CodeBox:HoveredPos()
    local tops = self.lineTops
    if not self.scroll:IsMouseOver() or #tops == 0 then return nil end
    local left, right, top = self.scroll:GetLeft(), self.scroll:GetRight(), self.edit:GetTop()
    if not (left and right and top) then return nil end
    local scale = self.edit:GetEffectiveScale() or 1
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    x = x - left - (self.insetL or 0) -- from the text's left edge
    if x < 0 then return nil end
    local down, h = y - top, self.rowHeight or 14
    local lines, starts, at = {}, {}, 1
    for l in (self:GetRaw() .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1], starts[#starts + 1] = l, at
        at = at + #l + 1
    end
    for i = 1, #tops do
        local line = lines[i] or ""
        local rows = self:Rows(line)
        local bottom = tops[i + 1] or (tops[i] - rows * h)
        if down <= tops[i] and down > bottom then
            -- The row of the line under the mouse, and the letters on it.
            local row = math.min(rows - 1, math.floor((tops[i] - down) / h))
            local from, to = 1, #line
            for r = 1, row do
                local lo, hi = from, #line
                while lo < hi do -- the first letter on row r: the shortest start that takes r + 1 rows
                    local mid = math.floor((lo + hi) / 2)
                    if self:Rows(line:sub(1, mid)) > r then hi = mid else lo = mid + 1 end
                end
                from = lo
            end
            if row < rows - 1 then
                local lo, hi = from, #line
                while lo < hi do
                    local mid = math.floor((lo + hi) / 2)
                    if self:Rows(line:sub(1, mid)) > row + 1 then hi = mid else lo = mid + 1 end
                end
                to = lo - 1
            end
            local text = line:sub(from, to)
            if text == "" or self:TextWidth(text) < x then return nil end
            local lo, hi = 1, #text -- the letter whose right edge is past the mouse
            while lo < hi do
                local mid = math.floor((lo + hi) / 2)
                if self:TextWidth(text:sub(1, mid)) > x then hi = mid else lo = mid + 1 end
            end
            return starts[i] + from - 2 + lo
        end
    end
    return nil
end

-- Where the cursor would be at raw position `pos`, asking the game: { x, y, h } or nil when the game
-- does not report it right away.
function CodeBox:MeasureByCursor(pos)
    self.measured = nil
    self.measuring = true
    self.edit:SetCursorPosition(H.ToColored(self.edit:GetText(), pos))
    self.measuring = false
    return self.measured
end

-- The same from text widths: a hidden FontString in the editor's font. Positions inside a wrapped
-- part of a line are not known this way (nil).
function CodeBox:MeasureByLayout(pos)
    local raw = self:GetRaw()
    local before = raw:sub(1, pos)
    local prefix = before:match("[^\n]*$")
    local line = prefix .. raw:sub(pos + 1):match("^[^\n]*")
    local above = 0
    for l in before:sub(1, #before - #prefix):gmatch("([^\n]*)\n") do above = above + self:Rows(l) end
    if self:Rows(line) > 1 and self:Rows(prefix) > 1 then return nil end
    local h = self:LineHeight()
    return { x = self.insetL + self:TextWidth(prefix), y = -INSET_T - above * h, h = h }
end

-- The word ending at the cursor may still become valid: a suggestion starts with it and is longer
-- ("comb" -> "combat", "mouse" -> "mouseover"). "mousovr" or "btn:7" can't.
local function Unfinished(raw, cursor)
    local ctx = ns.Parser.GetContext(raw, cursor)
    if not ctx then return false end
    local prefix = ctx.prefix:lower()
    for _, item in ipairs(ns.Completion.Get(ctx)) do
        local name = item.name:lower()
        if #name > #prefix and name:sub(1, #prefix) == prefix then return true end
    end
    return false
end

-- While a key was pressed less than TYPING_PAUSE ago, an unfinished word at the cursor is not marked;
-- then (or on Save, see CheckNow) it is.
function CodeBox:Typed()
    self.typing = true
    self.typingToken = (self.typingToken or 0) + 1
    local token = self.typingToken
    C_Timer.After(TYPING_PAUSE, function()
        if self.typingToken ~= token then return end
        self.typing = false
        self:ScheduleUnderlines()
    end)
end

-- Check everything right now, the word being typed included.
function CodeBox:CheckNow()
    self.typing = false
    self:DrawUnderlines()
end

-- Syntax issues, except an unfinished word being typed right now.
function CodeBox:Errors()
    local raw = self:GetRaw()
    local cursor = self.typing and self.edit:HasFocus() and self:GetRawCursor()
    local out = {}
    for _, e in ipairs(H.Errors(raw)) do
        if not (cursor and e.to == cursor and Unfinished(raw, cursor)) then out[#out + 1] = e end
    end
    return out
end

function CodeBox:DrawUnderlines()
    local errors = self:Errors()
    self.errors = errors
    for _, tex in ipairs(self.underlines) do tex:Hide() end
    if #errors > 0 and self.edit:IsVisible() then
        local saved = self.edit:GetCursorPosition()
        -- Ask the game where the text is; when it does not answer at once, measure the text instead.
        -- The game may report positions with or without the text insets: position 0 tells which.
        -- Once the game did not answer, stop moving the cursor: its late events would scroll the text.
        local probed = not self.layoutOnly
        local origin = probed and self:MeasureByCursor(0)
        if not origin then self.layoutOnly = true end
        local offX = origin and origin.x < 1 and self.insetL or 0
        local offY = origin and origin.y > -1 and -INSET_T or 0
        local function measure(pos)
            if not origin then return self:MeasureByLayout(pos) end
            local m = self:MeasureByCursor(pos)
            return m and { x = m.x + offX, y = m.y + offY, h = m.h }
        end
        Debug("underlines: %d errors, %s", #errors, origin and "cursor positions" or "text widths")
        local n = 0 -- textures used; no holes, so all of them get hidden next time
        for _, e in ipairs(errors) do
            local a, b = measure(e.from - 1), measure(e.to)
            if a then
                n = n + 1
                local tex = self.underlines[n]
                if not tex then
                    tex = self.edit:CreateTexture(nil, "OVERLAY")
                    tex.isUnderline = true
                    self.underlines[n] = tex
                end
                -- A word wrapped onto the next line: underline its start only.
                local width = (b and math.abs(b.y - a.y) < 1) and (b.x - a.x) or 8
                local color = e.severity == "warning" and self.warningColor or self.errorColor
                tex:SetColorTexture(ns.RGB(color or "f14c4c"))
                tex:SetSize(math.max(width, 6), 2)
                tex:ClearAllPoints()
                tex:SetPoint("TOPLEFT", self.edit, "TOPLEFT", a.x, a.y - a.h + 1)
                tex:Show()
                Debug("  line %d %q: x=%.1f y=%.1f w=%.1f%s", e.line, self:GetRaw():sub(e.from, e.to),
                    a.x, a.y, width, b and "" or " (end not measured)")
            else
                Debug("  line %d: start not measured", e.line)
            end
        end
        if probed then -- put the cursor back where the player left it
            self.measuring = true
            self.edit:SetCursorPosition(saved)
            self.measuring = false
        end
    end
    if self.onErrors then self.onErrors(errors) end
end

function CodeBox:GetRaw() return self.raw or H.Strip(self.edit:GetText()) end

function CodeBox:GetRawCursor()
    return H.ToRaw(self.edit:GetText(), self.edit:GetCursorPosition())
end

-- Puts the cursor at raw position `rawCursor`, in the text box.
function CodeBox:SetRawCursor(rawCursor)
    self.edit:SetFocus()
    self.edit:SetCursorPosition(H.ToColored(self.edit:GetText(), rawCursor))
end

-- Programmatic change (load a macro, accept a suggestion). `keepHistory` = record it for undo.
function CodeBox:SetRaw(raw, cursor, keepHistory)
    if keepHistory then self:PushUndo(true) else self.undo, self.redo = {}, {} end
    self:Render(raw, cursor)
    if self.onChange then self.onChange(raw, false) end
end

-- Keep the cursor at raw position `rawCursor` (default: where it is) while the suggestion list takes Up / Down.
function CodeBox:LockCursor(on, rawCursor)
    if not on then
        self.lockCursor = nil
        return
    end
    local text = self.edit:GetText()
    self.lockCursor = rawCursor and H.ToColored(text, rawCursor) or self.edit:GetCursorPosition()
    if self.edit:GetCursorPosition() ~= self.lockCursor then self.edit:SetCursorPosition(self.lockCursor) end
end

------------------------------------------------------------------------
-- Undo: snapshots of raw text + cursor
------------------------------------------------------------------------
function CodeBox:PushUndo(force)
    local raw = self.raw or ""
    local last = self.undo[#self.undo]
    if last and last.raw == raw then return end
    local now = GetTime()
    local grouped = not force and self.lastPush and now - self.lastPush < UNDO_GROUP
    self.lastPush = now
    if grouped then return end
    table.insert(self.undo, { raw = raw, cursor = self.lastCursor or #raw })
    if #self.undo > UNDO_LIMIT then table.remove(self.undo, 1) end
    self.redo = {}
end

local function swap(self, from, to)
    local snap = table.remove(from)
    if not snap then return end
    table.insert(to, { raw = self:GetRaw(), cursor = self:GetRawCursor() })
    self:Render(snap.raw, snap.cursor)
    if self.onChange then self.onChange(snap.raw, true) end
end

function CodeBox:Undo() swap(self, self.undo, self.redo) end
function CodeBox:Redo() swap(self, self.redo, self.undo) end

------------------------------------------------------------------------
-- Look
------------------------------------------------------------------------
function CodeBox:SetScheme(scheme)
    self.colors = ns.TokenColors(scheme)
    self.edit:SetTextColor(ns.RGB(scheme.text))
    local r, g, b = ns.RGB(scheme.selection)
    self.edit:SetHighlightColor(r, g, b, 0.6)
    self.errorColor, self.warningColor = scheme.invalid, scheme.warning
    self.lineColors = { text = scheme.text, dim = scheme.dim }
    self.gutterBg:SetColorTexture(ns.RGB(scheme.panel))
    self.gutterLine:SetColorTexture(ns.RGB(scheme.border))
    self.notesBg:SetColorTexture(ns.RGB(scheme.panel))
    self.notesLine:SetColorTexture(ns.RGB(scheme.border))
    self:Render(self:GetRaw(), self.edit:HasFocus() and self:GetRawCursor() or nil)
end

-- Returns false when the game could not load the font.
function CodeBox:SetFont(path, size)
    local ok = self.edit:SetFont(path, size, "") ~= false
    -- The old cursor height no longer fits: measure rows until the game reports the new one.
    self.caretH = nil
    self.edit:SetCursorPosition(self.edit:GetCursorPosition())
    self:ScheduleUnderlines()
    return ok
end

function CodeBox:SetFocus() self.edit:SetFocus() end
