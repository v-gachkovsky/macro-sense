-- The window of a code (Share.lua). Export: the code of the macros picked, selected, to copy. Import: a pasted
-- code, what it holds and where each macro would go; Import creates them (Window.Import).
local _, ns = ...
local L = ns.L

local ShareWindow = {}
ns.ShareWindow = ShareWindow

local WIDTH, HEIGHT, PAD = 560, 390, 14
local LISTED = 8 -- macros named in the summary; the rest are counted
local SCOPE_NAMES = { general = "General", character = "Character" }

local frame, titleText, hint, box, info, importBtn, closeBtn
local controls = {} -- by name, for the tests
local mode, code, found -- "export" | "import"; the code shown; the macros of a pasted code

local function Keys(letter) return (IsMacClient and IsMacClient() and "Cmd+" or "Ctrl+") .. letter end

local function Names(list)
    local names = {}
    for i = 1, math.min(#list, LISTED) do names[i] = list[i].name end
    local text = table.concat(names, ", ")
    if #list > LISTED then text = text .. string.format(L[" and %d more"], #list - LISTED) end
    return text
end

-- What a pasted code holds and where it goes: a line per macro, the rest counted.
local function Preview()
    local text = box:GetText()
    found = nil
    importBtn:SetEnabled(false)
    if not text:find("%S") then return info:SetText("") end
    local macros, problem = ns.Share.Decode(text)
    if not macros then return info:SetText("|cff" .. ns.scheme.invalid .. problem .. "|r") end
    local lines, fit = {}, 0
    for i, p in ipairs(ns.Window.ImportPlan(macros)) do
        local tab = L[SCOPE_NAMES[p.macro.scope]]
        local line
        if p.name then
            fit = fit + 1
            line = p.name == p.macro.name and string.format(L["%s: into %s"], p.name, tab)
                or string.format(L["%s: into %s as \"%s\" (the name is taken)"], p.macro.name, tab, p.name)
        elseif p.long then
            line = string.format(L["%s: longer than the game allows, not imported"], p.macro.name)
        else
            line = string.format(L["%s: no free slot in %s"], p.macro.name, tab)
        end
        if i <= LISTED then lines[#lines + 1] = line end
    end
    if #macros > LISTED then lines[#lines + 1] = string.format(L["... and %d more"], #macros - LISTED) end
    table.insert(lines, 1, ns.Plural(#macros, "%d macro in the code:", "%d macros in the code:"))
    info:SetText(table.concat(lines, "\n"))
    found = macros
    importBtn:SetEnabled(fit > 0)
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseShare", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseShare") -- Esc closes it
    frame:SetFrameStrata("HIGH") -- below StaticPopup dialogs (unsaved changes are asked about)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(WIDTH, HEIGHT)
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
    titleText = ns.Text(title, 14)
    titleText:SetPoint("LEFT", 12, 0)
    local close = ns.Button(title, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    hint = ns.Text(frame, 12, "dim")
    hint:SetPoint("TOPLEFT", PAD, -48)
    hint:SetPoint("RIGHT", -PAD, 0)

    -- The code: a box that scrolls; a click anywhere on it goes into it.
    local back = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    back:SetPoint("TOPLEFT", PAD, -70)
    back:SetPoint("TOPRIGHT", -PAD, -70)
    back:SetHeight(150)
    ns.Backdrop(back, "bg", "border")
    local scroll = CreateFrame("ScrollFrame", nil, back)
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -19, 6)
    box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetMaxLetters(0)
    box:SetFont(ns.UIFont(), 12, "")
    box:SetSize(WIDTH - 2 * PAD - 25, 138)
    ns.OnStyle(function(s) box:SetTextColor(ns.RGB(s.text)) end)
    scroll:SetScrollChild(box)
    ns.AttachScrollBar(scroll, 40)
    back:EnableMouse(true)
    back:SetScript("OnMouseDown", function() box:SetFocus() end)
    box:SetScript("OnEscapePressed", function() frame:Hide() end)
    box:SetScript("OnTextChanged", function(_, userInput)
        if mode == "import" then return Preview() end
        if userInput then -- the export's code stays as it is
            box:SetText(code)
            box:HighlightText()
        end
    end)

    info = ns.Text(frame, 12)
    info:SetPoint("TOPLEFT", back, "BOTTOMLEFT", 2, -10)
    info:SetPoint("RIGHT", -PAD, 0)
    info:SetJustifyV("TOP")
    info:SetWordWrap(true)

    closeBtn = ns.Button(frame, L["Close"], 80, function() frame:Hide() end)
    closeBtn:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    importBtn = ns.Button(frame, L["Import"], 90, function()
        if found then ns.Window.Import(found, function() frame:Hide() end) end
    end, true)
    importBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    controls.title, controls.box, controls.info, controls.import, controls.close = titleText, box, info, importBtn,
        closeBtn
end

local function Open(newMode)
    if not frame then Build() end
    mode = newMode
    importBtn:SetShown(mode == "import")
    closeBtn.label:SetText(mode == "import" and L["Cancel"] or L["Close"])
    frame:Show()
    frame:Raise()
    box:SetFocus()
end

-- The code of `macros` (as Share.Encode takes them), selected to copy.
function ShareWindow.Export(macros)
    code = ns.Share.Encode(macros)
    Open("export")
    titleText:SetText(#macros == 1 and L["Export a macro"]
        or ns.Plural(#macros, "Export %d macros", "Export %d macros"))
    hint:SetText(string.format(L["Press %s to copy the code, then share it: anyone with MacroSense can import it."],
        Keys("C")))
    box:SetText(code)
    box:HighlightText()
    info:SetText(Names(macros))
end

-- An empty box to paste a code into, or the code of a macro someone linked in chat (`from`: who).
function ShareWindow.Import(text, from)
    Open("import")
    titleText:SetText(L["Import macros"])
    hint:SetText(from and string.format(L["The macro %s linked in chat: see what it holds, then import it. Nothing is "
        .. "replaced: a taken name gets a number."], from)
        or string.format(L["Paste a MacroSense code (%s). Nothing is replaced: a taken name gets a number."], Keys("V")))
    box:SetText(text or "")
    Preview()
end

function ShareWindow.Close()
    if frame then frame:Hide() end
end

-- A part of the window by name: "title", "box", "info", "import", "close" (the tests use them).
function ShareWindow.Control(name) return controls[name] end

return ShareWindow
