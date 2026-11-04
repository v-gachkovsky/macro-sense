-- Macro sets, what they are: a window that tells it, and turns them on (the check box "Macro sets" in the editor
-- asks with it). Also "Sort by spells", asked first. The sets themselves are in the editor's list (Window.lua); the logic is Sets.lua.
local _, ns = ...
local L = ns.L

local SetsWindow = {}
ns.SetsWindow = SetsWindow

local WIDTH, HEIGHT, PAD = 560, 360, 14
local MAX_LISTED = 12 -- moves listed in the question of "Sort by spells"; the rest are counted

local frame, onBtn, onNote

-- A set's name: "class", "character" or a specialization's key.
function SetsWindow.Label(id)
    if id == "class" then return L["Class macros"] end
    if id == "character" then return L["This character's"] end
    for _, spec in ipairs(ns.Sets.Specs()) do
        if spec.key == id then return spec.label end
    end
    return id
end

-- Turned on already: no button, it says so.
local function Refresh()
    if not frame then return end
    local on = ns.Sets.Mine().enabled
    onBtn:SetShown(not on)
    onNote:SetShown(on)
end
SetsWindow.Refresh = Refresh

StaticPopupDialogs.MACROSENSE_SETS_SORT = {
    text = "Move these macros to where their spells are?\n\n%s",
    button1 = "Move", button2 = "Cancel",
    OnAccept = function(_, moves)
        ns.Print("moved: %d", ns.Sets.ApplySort(moves))
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

function SetsWindow.Sort()
    local moves = ns.Sets.SortPlan()
    if #moves == 0 then return ns.Print("nothing to move: each macro is where its spells are") end
    local lines = {}
    for i, move in ipairs(moves) do
        if i > MAX_LISTED then
            lines[#lines + 1] = string.format(L["and %d more"], #moves - MAX_LISTED)
            break
        end
        lines[#lines + 1] = string.format("%s: %s > %s", move.name, SetsWindow.Label(move.from),
            SetsWindow.Label(move.to))
    end
    ns.Ask("MACROSENSE_SETS_SORT", table.concat(lines, "\n"), nil, moves)
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseSets", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseSets") -- Esc closes it
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 40)
    ns.Backdrop(frame, "bg", "border", true)
    frame:Hide()
    frame:SetScript("OnShow", Refresh)
    -- Closed without turning them on: the check box in the editor stays clear.
    frame:SetScript("OnHide", function() ns.Window.SetsChanged() end)

    -- Title bar: drag to move.
    local bar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(34)
    ns.Backdrop(bar, "panel", "panel")
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() frame:StartMoving() end)
    bar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local barText = ns.Text(bar, 14)
    barText:SetPoint("LEFT", 12, 0)
    barText:SetText(L["Macro sets"])
    local close = ns.Button(bar, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    local intro = ns.Text(frame, 13)
    intro:SetPoint("TOPLEFT", PAD * 2, -34 - PAD * 2)
    intro:SetPoint("RIGHT", -PAD * 2, 0)
    intro:SetSpacing(4)
    intro:SetText(L["A character has only 30 macro slots. Macro sets make room: each specialization gets macros "
        .. "of its own. Choose a specialization, and its macros come into the game, onto their buttons, while the "
        .. "others' wait behind the scenes.\n\nClass macros are the same on all your characters of one class: "
        .. "change one, and the others get it too. This character's macros stay in every specialization.\n\nOnce "
        .. "turned on, all your character macros go into \"This character's\". Move them to a specialization or to "
        .. "the class in the list of macros: drag one there (hold Ctrl to copy it), or use \"...\" by its name. Or "
        .. "let \"Sort by spells\" do it. A backup of your macros is made first."])
    onBtn = ns.Button(frame, L["Turn on macro sets"], 200, function()
        ns.Sets.Enable()
        frame:Hide()
    end, true)
    onBtn:SetPoint("BOTTOMLEFT", PAD * 2, PAD * 2)
    local cancel = ns.Button(frame, L["Cancel"], 120, function() frame:Hide() end)
    cancel:SetPoint("LEFT", onBtn, "RIGHT", 10, 0)
    onNote = ns.Text(frame, 12, "dim")
    onNote:SetPoint("BOTTOMLEFT", PAD * 2, PAD * 2 + 4)
    onNote:SetPoint("RIGHT", -PAD * 2, 0)
    onNote:SetText(L["Macro sets are on. Clear \"Macro sets\" to turn them off: the macros in the game stay as "
        .. "they are, and the sets are kept for later."])
    onBtn:HookScript("OnShow", function() cancel:Show() end)
    onBtn:HookScript("OnHide", function() cancel:Hide() end)
end

function SetsWindow.Open()
    ns.Window.Ready() -- its colors
    if not frame then Build() end
    frame:Show()
    frame:Raise()
    Refresh()
end
function SetsWindow.Close() if frame then frame:Hide() end end
function SetsWindow.IsShown() return frame ~= nil and frame:IsShown() end
function SetsWindow.Toggle()
    if SetsWindow.IsShown() then return SetsWindow.Close() end
    SetsWindow.Open()
end

-- For the tests: whether it offers to turn them on.
function SetsWindow.Offers() return onBtn ~= nil and onBtn:IsShown() end

return SetsWindow
