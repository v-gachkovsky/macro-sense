-- Notes on the macros: a line of your own about a macro, kept by MacroSense outside its 255 characters (History.lua
-- keeps them). Written from the macro's "..." menu, shown in its tooltip in the list.
local _, ns = ...
local L = ns.L

local Window, shared = ns.Window, ns.WindowShared

local MAX_NOTE = 255
local frame, title, box

-- The small window with the note's line: Save keeps it (an empty line deletes the note), Cancel or Esc leaves it.
local function Build()
    frame = CreateFrame("Frame", "MacroSenseNote", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseNote") -- Esc closes it
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetSize(420, 112)
    ns.Backdrop(frame, "bg", "border", true)
    frame:Hide()
    title = ns.Text(frame, 14)
    title:SetPoint("TOPLEFT", 14, -14)
    title:SetPoint("RIGHT", -14, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    box = ns.Input(frame, 392, MAX_NOTE)
    box:SetPoint("TOPLEFT", 14, -40)
    local save = ns.Button(frame, L["Save"], 100, function() frame.save() end, true)
    save:SetPoint("BOTTOMRIGHT", -14, 12)
    local cancel = ns.Button(frame, L["Cancel"], 100, function() frame:Hide() end)
    cancel:SetPoint("RIGHT", save, "LEFT", -8, 0)
    frame:SetScript("OnHide", function() box:ClearFocus() end)
    box:SetScript("OnEnterPressed", function() frame.save() end)
    box:SetScript("OnEscapePressed", function() frame:Hide() end)
end

-- A line to write, under `heading`, with `text` in it first: save(text) when Save or Enter is pressed (a true
-- return keeps the window open: the line can't be taken). The notes, and the folders' names (Folders.lua) too.
local function AskLine(heading, text, save, maxLetters)
    if not frame then Build() end
    Window.ClearFocus() -- the keys come here, not to the editor
    title:SetText(heading)
    box:SetMaxLetters(maxLetters or MAX_NOTE)
    box:SetText(text or "")
    function frame.save()
        if save(box:GetText()) then return end
        frame:Hide()
        Window.RefreshList()
    end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", shared.frame or UIParent, "CENTER", 0, 60)
    frame:Show()
    box:SetFocus()
    box:HighlightText()
end
shared.AskLine = AskLine

-- The note of macro `name` in tab `scope` (one behind the scenes is the character's), to write.
function Window.EditNote(scope, name)
    AskLine(string.format(L["Note on \"%s\""], name), ns.History.Note(scope, name),
        function(text) ns.History.SetNote(scope, name, text) end)
end

-- Its menu item, for the "..." menus of a macro.
local function NoteItem(scope, name)
    local has = ns.History.Note(scope, name) ~= nil
    return { name = has and L["Change the note"] or L["Add a note"],
        onClick = function() Window.EditNote(scope, name) end }
end

-- Its tooltip line, when it has one.
local function AddNoteLine(scope, name)
    local note = ns.History.Note(scope, name)
    -- Yellow, written into the text too: the tooltip keeps it whatever colored its lines before.
    if note then GameTooltip:AddLine("|cffffd100" .. note:gsub("|", "||") .. "|r", 1, 0.82, 0, true) end
end

shared.NoteItem, shared.AddNoteLine = NoteItem, AddNoteLine
