-- Multi-line EditBox with syntax highlighting. The EditBox holds colored text; callers only see raw text.
local _, ns = ...

local H = ns.Highlight
local UNDO_LIMIT = 200
local INSET_L, INSET_T = 6, 4
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
    edit:SetTextInsets(INSET_L, 6, INSET_T, 4)
    self.underlines = {}
    edit:HookScript("OnSizeChanged", function() self:ScheduleUnderlines() end)
    edit:SetFont(ns.fonts[1].path, 13, "")
    scroll:SetScrollChild(edit)
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
        self.caretX, self.caretY, self.caretH = x, y, h
        self.lastCursor = H.ToRaw(e:GetText(), e:GetCursorPosition())
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
    if key ~= "UP" and key ~= "DOWN" then self.lockCursor = nil end
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
-- Error underlines. An EditBox cannot underline, so lines are drawn under the text. Their place comes
-- from the game itself: the cursor is moved to each error for a moment and OnCursorChanged reports x / y.
------------------------------------------------------------------------
function CodeBox:ScheduleUnderlines()
    if self.underlinePending then return end
    self.underlinePending = true
    C_Timer.After(0, function()
        self.underlinePending = false
        self:DrawUnderlines()
    end)
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
    local fs = self.measurer
    if not fs then
        fs = self.edit:CreateFontString(nil, "BACKGROUND")
        fs:SetAlpha(0)
        fs:SetWordWrap(true)
        self.measurer = fs
    end
    fs:SetFont(self.edit:GetFont())
    local wrapWidth = self.edit:GetWidth() - INSET_L - 6
    local function rows(text)
        fs:SetWidth(wrapWidth)
        fs:SetText(text ~= "" and text or " ")
        return math.max(1, fs.GetNumLines and fs:GetNumLines() or 1)
    end
    -- Trailing spaces do not count in a string's width: measure with a letter after them.
    local function width(text)
        fs:SetWidth(0)
        local function w(t)
            fs:SetText(t)
            return fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
        end
        return w(text .. "x") - w("x")
    end
    local raw = self:GetRaw()
    local before = raw:sub(1, pos)
    local prefix = before:match("[^\n]*$")
    local line = prefix .. raw:sub(pos + 1):match("^[^\n]*")
    local above = 0
    for l in before:sub(1, #before - #prefix):gmatch("([^\n]*)\n") do above = above + rows(l) end
    if rows(line) > 1 and rows(prefix) > 1 then return nil end
    local h = self.caretH
    if not h then
        fs:SetText("Ag")
        h = fs:GetStringHeight()
    end
    return { x = INSET_L + width(prefix), y = -INSET_T - above * h, h = h }
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
        local offX = origin and origin.x < 1 and INSET_L or 0
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
    self:Render(self:GetRaw(), self.edit:HasFocus() and self:GetRawCursor() or nil)
end

-- Returns false when the game could not load the font.
function CodeBox:SetFont(path, size)
    local ok = self.edit:SetFont(path, size, "") ~= false
    self:ScheduleUnderlines()
    return ok
end

function CodeBox:SetFocus() self.edit:SetFocus() end
