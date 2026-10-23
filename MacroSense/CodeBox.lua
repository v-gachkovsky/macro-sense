-- Multi-line EditBox with syntax highlighting. The EditBox holds colored text; callers only see raw text.
local _, ns = ...

local H = ns.Highlight
local UNDO_LIMIT = 200
local UNDO_GROUP = 0.8 -- keystrokes closer than this (seconds) undo together

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
    edit:SetTextInsets(6, 6, 4, 4)
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
            self:PushUndo()
            self:Render(raw, cursor)
        end
        self.raw = raw
        if self.onChange then self.onChange(raw, userInput) end
    end)

    edit:SetScript("OnCursorChanged", function(e, x, y, w, h)
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
    self:Render(self:GetRaw(), self.edit:HasFocus() and self:GetRawCursor() or nil)
end

-- Returns false when the game could not load the font.
function CodeBox:SetFont(path, size)
    return self.edit:SetFont(path, size, "") ~= false
end

function CodeBox:SetFocus() self.edit:SetFocus() end
