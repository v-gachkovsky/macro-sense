-- Macros in short: what a macro is, how to make one, how a line reads, and the link to the full guide
-- (docs/GUIDE.md, GUIDE_UA.md), to copy. The ? in the editor's title bar and /ms help open it.
local _, ns = ...
local L = ns.L

local HelpWindow = {}
ns.HelpWindow = HelpWindow

local WIDTH, PAD = 560, 16
local GUIDE = "https://github.com/v-gachkovsky/macro-sense/blob/main/docs/"

local frame
local controls = {} -- by name, for the tests

local function Keys(letter) return (IsMacClient and IsMacClient() and "Cmd+" or "Ctrl+") .. letter end

-- The guide in the language MacroSense speaks.
function HelpWindow.URL()
    return GUIDE .. (ns.language == "uk" and "GUIDE_UA.md" or "GUIDE.md")
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseHelp", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseHelp") -- Esc closes it
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetWidth(WIDTH)
    frame:SetPoint("CENTER", 0, 60)
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
    title:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local titleText = ns.Text(title, 14)
    titleText:SetPoint("LEFT", 12, 0)
    titleText:SetText(L["Macros in short"])
    local close = ns.Button(title, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    -- The paragraphs, one under another: a heading in the text color, its words dimmer.
    local paragraphs = {
        { L["What a macro is"], L["A button that does several things at once, or a different thing depending on "
            .. "the moment. You put it on an action bar and press it like a spell."] },
        { L["How to make one"], L["Press New, give it a name, write its lines (a list suggests commands and "
            .. "spells as you type), Save, then drag it onto an action bar. Or press New (Wizard): it asks a few "
            .. "simple questions and writes the macro for you."] },
        { L["How a line reads"], L["/cast [mod:shift,@focus] Polymorph; Frostbolt: with Shift held, Polymorph "
            .. "on your focus; otherwise Frostbolt. The game takes the first part whose conditions in [ ] are "
            .. "all true, and [ ] with nothing inside is always true."] },
        { L["Help as you go"], L["Point at a word in the editor to see what it means, and at a line's number to "
            .. "read the whole line in plain words. Next to each line is what it would do right now."] },
    }
    local above
    local function Under(fs, gap)
        if above then fs:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -gap) else fs:SetPoint("TOPLEFT", PAD, -50) end
        fs:SetPoint("RIGHT", -PAD, 0)
        above = fs
    end
    for i, p in ipairs(paragraphs) do
        local head = ns.Text(frame, 13)
        Under(head, 14)
        head:SetText(p[1])
        local body = ns.Text(frame, 12, "dim")
        Under(body, 4)
        body:SetWordWrap(true)
        body:SetText(p[2])
        controls["paragraph" .. i] = body
    end

    -- The link to the full guide: selected, to copy.
    local more = ns.Text(frame, 13)
    Under(more, 18)
    more:SetText(L["The full guide, with pictures and ready-made macros"])
    local link = ns.Input(frame, WIDTH - 2 * PAD)
    link:SetPoint("TOPLEFT", more, "BOTTOMLEFT", 0, -6)
    local function select()
        link:SetText(HelpWindow.URL())
        link:HighlightText()
    end
    link:SetScript("OnEditFocusGained", select)
    link:SetScript("OnMouseUp", select)
    -- It is there to copy: a key typed into it puts the link back.
    link:SetScript("OnTextChanged", function(_, userInput) if userInput then select() end end)
    controls.link = link
    local copy = ns.Text(frame, 12, "dim")
    copy:SetPoint("TOPLEFT", link, "BOTTOMLEFT", 0, -6)
    copy:SetText(string.format(L["%s copies it; open it in your browser."], Keys("C")))
    controls.copy = copy
    -- As tall as the wrapped text, once it is laid out.
    frame:SetHeight(420)
    frame:SetScript("OnShow", function()
        local top, bottom = frame:GetTop(), copy:GetBottom()
        if top and bottom then frame:SetHeight(top - bottom + PAD) end
    end)
end

function HelpWindow.Open()
    if not frame then Build() end
    controls.link:SetText(HelpWindow.URL())
    frame:Show()
    frame:Raise()
    controls.link:SetFocus()
    controls.link:HighlightText()
end

function HelpWindow.Toggle()
    if frame and frame:IsShown() then return frame:Hide() end
    HelpWindow.Open()
end

function HelpWindow.IsShown() return frame ~= nil and frame:IsShown() end

function HelpWindow.Control(name) return controls[name] end
