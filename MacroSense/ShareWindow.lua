-- The window of a code (Share.lua). Export: the code of the macros picked, selected, to copy; of macro sets, a check
-- box for each set, the code of those checked. Import: a pasted code, or the macro sets of another character of
-- yours, what it holds and where each macro would go; Import creates them (Window.Import, Window.ImportSets).
local _, ns = ...
local L = ns.L

local ShareWindow = {}
ns.ShareWindow = ShareWindow

local WIDTH, HEIGHT, PAD = 560, 390, 14
local LISTED = 8 -- macros named in the summary; the rest are counted
local SCOPE_NAMES = { general = "General", character = "Character" }

local SET_ROW, SET_COLUMNS = 22, 2
local frame, titleText, hint, box, back, info, importBtn, closeBtn, picks, allBtn, fromChar
local controls = {} -- by name, for the tests
-- "export" | "sets" (export of macro sets) | "import"; the code shown; the macros of a pasted code; the sets of a
-- pasted code or of a character (`source`: its key), to import; the sets to export and those checked.
local mode, code, found, foundSets, source, exporting, picked
local pickRows = {}

local function ClassName(class)
    return class and (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class) or "?"
end

local function Keys(letter) return (IsMacClient and IsMacClient() and "Cmd+" or "Ctrl+") .. letter end

local function Names(list)
    local names = {}
    for i = 1, math.min(#list, LISTED) do names[i] = list[i].name end
    local text = table.concat(names, ", ")
    if #list > LISTED then text = text .. string.format(L[" and %d more"], #list - LISTED) end
    return text
end

-- What a pasted code holds and where it goes: a line per macro, the rest counted.
-- What sets `data` hold and where they go: a line per set, another class's said, the sets off said.
local function PreviewSets(data, who)
    local plan = ns.Window.SetsImportPlan(data)
    local lines, total = {}, 0
    for _, p in ipairs(plan.sets) do
        total = total + #p.items
        local parts = { ns.Plural(p.new, "%d new", "%d new") }
        if p.same > 0 then parts[#parts + 1] = ns.Plural(p.same, "%d here already", "%d here already") end
        if p.long > 0 then parts[#parts + 1] = ns.Plural(p.long, "%d too long", "%d too long") end
        local label = p.from.label or ns.SetsWindow.Label(p.from.id)
        if plan.other then label = string.format(L["%s > This character's"], label) end
        lines[#lines + 1] = string.format("%s: %s", label, table.concat(parts, ", "))
    end
    table.insert(lines, 1, string.format(L["Macro sets of %s: %d macros"], who, total))
    local s = ns.scheme
    if plan.other then
        lines[#lines + 1] = "|cff" .. s.invalid .. string.format(L["These are the sets of another class (%s): its "
            .. "specializations aren't yours, so all the macros go into \"This character's\"."], ClassName(data.class))
            .. "|r"
    end
    local on = ns.Sets.Mine().enabled
    if not on then
        lines[#lines + 1] = "|cff" .. s.invalid .. L["Turn on \"Macro sets\" first: these macros go into them."] .. "|r"
    elseif plan.new > 0 then
        lines[#lines + 1] = L["They come in behind the scenes: take in those you need."]
    end
    info:SetText(table.concat(lines, "\n"))
    foundSets = data
    importBtn:SetEnabled(on and plan.new > 0)
end

local function Preview()
    local text = box:GetText()
    found, foundSets = nil, nil
    importBtn:SetEnabled(false)
    if source then
        local c = ns.db.characters[source]
        return PreviewSets(ns.Window.SetsData(source), c and c.name or source)
    end
    if not text:find("%S") then return info:SetText("") end
    if ns.Share.IsSets(text) then
        local data, problem = ns.Share.DecodeSets(text)
        if not data then return info:SetText("|cff" .. ns.scheme.invalid .. problem .. "|r") end
        return PreviewSets(data, ClassName(data.class))
    end
    local macros, problem = ns.Share.Decode(text)
    local plain = not macros and ns.Share.FromText(text, ns.db.scope)
    if plain then
        macros = plain
    elseif not macros then
        if not text:find("MacroSense%d?:") then
            problem = L["This is neither a MacroSense code nor a macro. Each line of a macro starts with / or #."]
        end
        return info:SetText("|cff" .. ns.scheme.invalid .. problem .. "|r")
    end
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
    table.insert(lines, 1, plain and ns.Plural(#macros, "%d macro in the text:", "%d macros in the text:")
        or ns.Plural(#macros, "%d macro in the code:", "%d macros in the code:"))
    info:SetText(table.concat(lines, "\n"))
    found = macros
    importBtn:SetEnabled(fit > 0)
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseShare", UIParent, "BackdropTemplate")
    frame:HookScript("OnShow", function() ns.Window.ClearFocus() end) -- the keys come here, not to the editor
    table.insert(UISpecialFrames, "MacroSenseShare") -- Esc closes it
    frame:SetFrameStrata("MEDIUM") -- with the game's windows; below StaticPopup dialogs (unsaved changes are asked)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 60)
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
    title:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    titleText = ns.Text(title, 14)
    titleText:SetPoint("LEFT", 12, 0)
    local close = ns.Button(title, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    hint = ns.Text(frame, 12, "dim")
    hint:SetPoint("TOPLEFT", PAD, -48)
    hint:SetPoint("RIGHT", -PAD, 0)

    -- The code: a box that scrolls; a click anywhere on it goes into it.
    back = CreateFrame("Frame", nil, frame, "BackdropTemplate")
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
        if mode == "import" then
            if userInput and source then
                source = nil
                fromChar:Refresh()
            end
            return Preview()
        end
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
        if foundSets then return ns.Window.ImportSets(foundSets, function() frame:Hide() end) end
        if found then ns.Window.Import(found, function() frame:Hide() end) end
    end, true)
    importBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)

    -- The sets to export: a check box each, in columns; all checked or cleared at once.
    picks = CreateFrame("Frame", nil, frame)
    picks:SetPoint("TOPLEFT", back, "BOTTOMLEFT", 2, -10)
    picks:SetPoint("RIGHT", -PAD, 0)
    allBtn = ns.Button(frame, L["Select all"], 120, function()
        local all = true
        for _, set in ipairs(exporting.sets) do all = all and picked[set.id] end
        for _, set in ipairs(exporting.sets) do picked[set.id] = not all or nil end
        ShareWindow.ShowSetsCode()
    end)
    allBtn:SetPoint("BOTTOMLEFT", PAD, PAD)

    -- Or the macro sets of another character of yours.
    local function characters()
        local items = { { key = "", name = L["Or from a character..."] } }
        local mine = ns.Character()
        local keys = {}
        for key, c in pairs(ns.db.characters or {}) do
            if c ~= mine and (c.sets or (c.macros and next(c.macros))) then keys[#keys + 1] = key end
        end
        table.sort(keys)
        for _, key in ipairs(keys) do
            local c = ns.db.characters[key]
            local name = c.realm == mine.realm and c.name or key
            items[#items + 1] = { key = key, name = string.format("%s (%s)", name, ClassName(c.class)) }
        end
        return items
    end
    fromChar = ns.Dropdown(frame, 220, characters, function() return source or "" end, function(key)
        source = key ~= "" and key or nil
        box:SetText("")
        Preview()
    end)
    fromChar:SetPoint("BOTTOMLEFT", PAD, PAD)
    controls.title, controls.box, controls.info, controls.import, controls.close = titleText, box, info, importBtn,
        closeBtn
    controls.all, controls.from, controls.picks = allBtn, fromChar, pickRows
end

local function Open(newMode)
    ns.Window.Ready() -- its colors: a macro linked in chat opens it before the editor
    if not frame then Build() end
    mode = newMode
    source = nil
    frame:SetHeight(HEIGHT)
    info:ClearAllPoints()
    info:SetPoint("TOPLEFT", back, "BOTTOMLEFT", 2, -10)
    info:SetPoint("RIGHT", -PAD, 0)
    picks:SetShown(mode == "sets")
    allBtn:SetShown(mode == "sets")
    fromChar:SetShown(mode == "import")
    fromChar:Refresh()
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

-- The code of the sets checked, selected to copy, with what it holds; "Select all" or "Clear all".
function ShareWindow.ShowSetsCode()
    local chosen, sets, macros, all = { class = exporting.class, sets = {} }, 0, 0, true
    for _, set in ipairs(exporting.sets) do
        if picked[set.id] then
            chosen.sets[#chosen.sets + 1] = set
            sets, macros = sets + 1, macros + #set.macros
        else
            all = false
        end
    end
    for _, row in ipairs(pickRows) do row:Refresh() end
    code = sets > 0 and ns.Share.EncodeSets(chosen) or ""
    box:SetText(code)
    box:HighlightText()
    info:SetText(sets > 0 and string.format(L["%d macros in %d sets"], macros, sets) or L["Check the sets to export."])
    allBtn.label:SetText(all and L["Clear all"] or L["Select all"])
end

-- The code of macro sets `data` (as Window.SetsData gives them): a check box for each set, all checked first.
function ShareWindow.ExportSets(data)
    Open("sets")
    exporting, picked = data, {}
    for _, set in ipairs(data.sets) do picked[set.id] = true end
    titleText:SetText(L["Export macro sets"])
    hint:SetText(string.format(L["Check the sets to export. Press %s to copy the code: import it on another "
        .. "character, or share it."], Keys("C")))
    local width = (WIDTH - 2 * PAD) / SET_COLUMNS
    for i, set in ipairs(data.sets) do
        local row = pickRows[i]
        if not row then
            row = ns.Check(picks, "", function()
                    local r = pickRows[i] -- nil while it is made
                    return r ~= nil and r.set ~= nil and picked[r.set.id] ~= nil
                end,
                function(on)
                    picked[pickRows[i].set.id] = on or nil
                    ShareWindow.ShowSetsCode()
                end)
            pickRows[i] = row
        end
        row.set = set
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ((i - 1) % SET_COLUMNS) * width, -math.floor((i - 1) / SET_COLUMNS) * SET_ROW)
        row:SetLabel(string.format("%s  |cff%s%d|r", set.label or ns.SetsWindow.Label(set.id), ns.scheme.dim,
            #set.macros))
        row:Show()
    end
    for i = #data.sets + 1, #pickRows do
        pickRows[i]:Hide()
        pickRows[i].set = nil
    end
    local height = math.ceil(#data.sets / SET_COLUMNS) * SET_ROW
    picks:SetHeight(math.max(1, height))
    info:ClearAllPoints()
    info:SetPoint("TOPLEFT", picks, "BOTTOMLEFT", 0, -10)
    info:SetPoint("RIGHT", -PAD, 0)
    frame:SetHeight(HEIGHT + height)
    ShareWindow.ShowSetsCode()
end

-- The text of macro `m` ({ name, body }), selected to copy: for guides, forums and chat.
function ShareWindow.ExportText(m)
    code = m.body
    Open("export")
    titleText:SetText(L["The macro's text"])
    hint:SetText(string.format(L["Press %s to copy the text, then paste it into a guide, a forum or Discord. "
        .. "MacroSense can import it too."], Keys("C")))
    box:SetText(code)
    box:HighlightText()
    info:SetText(m.name)
end

-- An empty box to paste a code into, or the code of a macro someone linked in chat (`from`: who).
function ShareWindow.Import(text, from)
    Open("import")
    titleText:SetText(L["Import macros"])
    hint:SetText(from and string.format(L["The macro %s shared in chat. See what is in it, then import it. Nothing "
        .. "gets replaced: if the name is taken, a number is added to it."], from)
        or string.format(L["Paste a MacroSense code, or a macro's text from a guide (%s), or choose a character of "
            .. "yours. Nothing gets replaced: if a name is taken, a number is added to it."], Keys("V")))
    box:SetText(text or "")
    Preview()
end

function ShareWindow.Close()
    if frame then frame:Hide() end
end

-- A part of the window by name: "title", "box", "info", "import", "close", "all", "from", "picks" (the tests use
-- them).
function ShareWindow.Control(name) return controls[name] end

return ShareWindow
