-- The macro guide in game: docs/GUIDE.md in short, section by section. The sections on the left, the text on the
-- right with its macros colored as in the editor; ready-made macros have a Create button. The ? in the editor's
-- title bar and /ms help open it; the last section links the full guide on GitHub, to copy.
local _, ns = ...
local L = ns.L

local HelpWindow = {}
ns.HelpWindow = HelpWindow

local WIDTH, HEIGHT, NAV, PAD = 800, 560, 190, 16
local TEXT_W = WIDTH - NAV - 2 * PAD - 18 -- the scroll bar
local LEFT_W = 170 -- the left column of a two-column list
local GUIDE = "https://github.com/v-gachkovsky/macro-sense/blob/main/docs/"

local frame, scroll, navButtons
local built, current = {}, nil -- section frames by index, made when first shown; the one shown
local controls = {} -- by name, for the tests

local function Keys(letter) return (IsMacClient and IsMacClient() and "Cmd+" or "Ctrl+") .. letter end

-- The guide in the language MacroSense speaks.
function HelpWindow.URL()
    return GUIDE .. (ns.language == "uk" and "GUIDE_UA.md" or "GUIDE.md")
end

local function CodeFont()
    local font = ns.FindByKey(ns.fonts, ns.db and ns.db.font)
    return font and font.path or ns.UIFont()
end

-- A unit for @: what Docs says, else its name in words ("party member 1").
local function UnitText(u)
    return ns.Docs.Text("unit", u) or (ns.Explain.Unit(u):gsub("^%l", string.upper))
end

-- The sections: a title, then blocks in order.
--   { "p", text }                    a paragraph
--   { "code", macro, name? }         a macro, colored; with a name, a Create button makes it under that name
--   { "rows", { { left, right } } }  two columns: a word of a macro and what it means
--   { "list", { { head, text } } }   two columns: a short heading and its words
--   { "button", label, onClick }
--   { "link" }                       the full guide's link, to copy
--   { "tasks" }                      the practice tasks with your spells (Practice.lua), each with Check and Answer
local function Sections()
    local rows = {}
    for _, c in ipairs({ "cast", "use", "castsequence", "castrandom", "stopcasting", "stopmacro", "startattack",
        "target", "focus", "assist", "petattack", "petfollow", "equip", "equipslot", "dismount", "cancelaura",
        "cancelform", "click", "say" }) do
        rows[#rows + 1] = { "/" .. c, ns.Docs.Text("command", c) }
    end
    local conds = {}
    for _, c in ipairs({ "help", "harm", "dead", "exists", "mod", "combat", "stealth", "mounted", "flying",
        "swimming", "flyable", "group", "pet", "form", "spec", "known", "equipped", "channeling" }) do
        conds[#conds + 1] = { c, ns.Docs.Text("condition", c) }
    end
    local units = {}
    for _, u in ipairs({ "target", "mouseover", "focus", "player", "pet", "party1", "targettarget", "arena1",
        "cursor" }) do
        units[#units + 1] = { "@" .. u, UnitText(u) }
    end
    local LINE = "/cast [mod:shift,@focus] Polymorph; [@mouseover,harm][] Frostbolt"
    return {
        { L["What a macro is"], {
            { "p", L["A macro is a button that does several things at once, or a different thing depending on the "
                .. "moment. You put it on an action bar like a spell and press it the same way. Inside are lines of "
                .. "text, one command each:"] },
            { "code", "#showtooltip\n/cast Fireball" },
            { "p", L["Press it, and the game reads the lines from the top and does what they say: here, it casts "
                .. "Fireball."] },
            { "p", L["General macros, up to 120, are the same for every character on your account. Character "
                .. "macros, up to 30, belong to the character you play. A macro holds at most 255 characters, about "
                .. "five or six lines."] },
        } },
        { L["Your first macro"], {
            { "p", L["Let's make a macro that casts Shadow Bolt at the enemy under your mouse, or at your target "
                .. "when you point at nobody. Swap in any spell of yours."] },
            { "list", {
                { "1", L["Pick the Character tab and press New under the list. The new macro already has "
                    .. "#showtooltip on its first line, and the cursor waits on the second."] },
                { "2", L["Type a name at the top, such as Bolt MO (MO for mouseover), and press Tab."] },
                { "3", L["Type /ca and take /cast from the list with Tab. Type [@ and pick mouseover, then type "
                    .. ",harm and ]. Then a few letters of the spell, and pick it."] },
                { "4", L["Add [] before the spell name. It means \"otherwise, as usual\", so with nobody under the "
                    .. "mouse the spell goes to your target:"] },
            } },
            { "code", "#showtooltip\n/cast [@mouseover,harm][] Shadow Bolt", "Bolt MO" },
            { "list", {
                { "5", L["Next to the line, the editor shows what it would do right now. Point at the line's number "
                    .. "to read the whole line in plain words."] },
                { "6", L["Press Save, then drag the macro from the list onto an action bar. Done."] },
            } },
            { "button", L["New macro"], function() ns.Window.Make() end },
        } },
        { L["The wizard"], {
            { "p", L["You don't have to write anything: New (Wizard) under the list makes the macro for you."] },
            { "p", L["Step by step, it asks one question at a time: what the macro should do, which spell, on whom, "
                .. "and if not, on whom then, what Shift, Ctrl or Alt change, when it works. All options in its "
                .. "title bar shows the whole form at once instead."] },
            { "p", L["The macro grows at the bottom of the wizard as you answer. Create macro saves it and opens it "
                .. "in the editor."] },
            { "p", L["To change a macro you have with the same questions, open it and press Wizard above its text."] },
            { "button", L["Open the wizard"], function() ns.WizardWindow.Open(ns.db.scope) end },
        } },
        { L["How a line reads"], {
            { "code", LINE },
            { "rows", {
                { "/cast", L["The command: what to do. /cast casts a spell, /use uses an item."] },
                { "[mod:shift,@focus]", L["Conditions: when this part works. All of them in one pair of brackets "
                    .. "must be true."] },
                { "@focus", L["On whom. Without it, the spell goes to your target as usual."] },
                { "Polymorph", L["The spell or item."] },
                { ";", L["Otherwise: the game tries the next part."] },
                { "[@mouseover,harm][]", L["Two pairs of brackets in a row: this, or else that, for the same "
                    .. "spell."] },
                { "[]", L["Empty brackets are always true: otherwise, as usual."] },
            } },
            { "p", L["Two more things you will meet in macros:"] },
            { "rows", {
                { "!Shoot", L["Only turns it on: a press doesn't stop your shooting or take you out of stealth."] },
                { "#showtooltip", L["A setting, not a command: the macro shows the tooltip of what it would cast, "
                    .. "and its icon while the macro's icon is the question mark."] },
            } },
        } },
        { L["How the game picks"], {
            { "p", L["On each line, the game reads the parts from left to right and takes the first one whose "
                .. "conditions are all true. The rest of the line is skipped."] },
            { "code", LINE },
            { "rows", {
                { "[mod:shift,@focus]", L["Is Shift held, and do you have a focus? Then Polymorph on your focus."] },
                { "[@mouseover,harm]", L["If not: is there an enemy under the mouse? Then Frostbolt on it."] },
                { "[]", L["If not: Frostbolt on your target."] },
            } },
            { "p", L["So put the special cases first and the usual one last."] },
            { "p", L["One press casts only one spell that starts the global cooldown. Lines after it still run if "
                .. "they don't need it: /startattack, a trinket, a chat line."] },
        } },
        { L["What macros can do"], {
            { "rows", rows },
            { "p", L["Type / in the editor to see every command your game has, addons' too. Point at a command to "
                .. "read what it does."] },
        } },
        { L["Conditions and units"], {
            { "p", L["Each condition works the other way round with no in front: nocombat, nomod, nodead."] },
            { "rows", conds },
            { "p", L["The units, for @:"] },
            { "rows", units },
            { "p", L["Type [ in the editor for every condition, and [@ for every unit."] },
        } },
        { L["What macros can't do"], {
            { "list", {
                { L["Think for you"], L["A macro can't check your health, a cooldown or how long a buff lasts. It "
                    .. "knows only what conditions can say."] },
                { L["Cast at once"], L["One spell with the global cooldown per press."] },
                { L["Press itself"], L["Every cast needs your key press or click."] },
                { L["Be long"], L["255 characters at most. Shorten at the top writes the same macro in fewer."] },
                { L["Cast from /run"], L["Lua in a macro can't cast or target."] },
            } },
        } },
        { L["Ready-made macros"], {
            { "p", L["Create puts the macro into the tab that is open, under a free name, and opens it. Change the "
                .. "spell names to yours."] },
            { "p", L["Heal whoever is under the mouse; if nobody, your target if it is a friend; if not, you:"] },
            { "code", "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] Flash Heal", "Heal MO" },
            { "p", L["Interrupt your focus, or your target:"] },
            { "code", "#showtooltip\n/stopcasting\n/cast [@focus,harm,nodead][] Counterspell", "Kick Focus" },
            { "p", L["Another spell with Shift held:"] },
            { "code", "#showtooltip\n/cast [mod:shift,@focus] Polymorph; Frostbolt", "Poly Shift" },
            { "p", L["A trinket with your big spell:"] },
            { "code", "#showtooltip Arcane Power\n/use 13\n/cast Arcane Power", "Trinket" },
            { "p", L["Two curses in turn, from the start on a new target:"] },
            { "code", "#showtooltip\n/castsequence reset=target Corruption, Curse of Agony", "Curses" },
            { "p", L["Shoot with a wand, and keep shooting however often you press:"] },
            { "code", "#showtooltip\n/cast !Shoot", "Wand" },
            { "p", L["The pet attacks what you point at, and follows you with Shift:"] },
            { "code", "/petattack [nomod,@mouseover,harm,nodead][nomod]\n/petfollow [mod:shift]", "Pet" },
            { "p", L["One mount button:"] },
            { "code", "#showtooltip\n/cast [nomounted,swimming] Sea Turtle; [nomounted,flyable] Gryphon; "
                .. "[nomounted] Steed\n/dismount [mounted,noflying]", "Mount" },
        } },
        { L["Typing less"], {
            { "p", L["The list that comes up as you type doesn't need the whole word, or even its start:"] },
            { "rows", {
                { "SB", L["Shadow Bolt: capitals are the first letters of the words."] },
                { "CoA", L["Curse of Agony: small words may be left out, or typed in small letters."] },
                { "sh wo", L["Shadow Word: Pain: a space goes on to the next word."] },
                { "nct", L["nocombat: letters in order, from the start of the word, with others between them."] },
                { "mntd", L["mounted: the same for conditions, commands and units."] },
            } },
            { "p", L["Tab or Enter takes the highlighted one, Up and Down move through the list, Esc closes it."] },
        } },
        { L["Practice"], {
            { "p", L["A few tasks with your own spells. Write each macro in the editor: press New there, write it, "
                .. "then press Check here. Answer shows one way to write it."] },
            { "tasks" },
        } },
        { L["The full guide"], {
            { "p", L["The full guide, with pictures and more examples, is on GitHub. Copy the link and open it in "
                .. "your browser:"] },
            { "link" },
        } },
    }
end

-- A word of a macro in the code font, colored as the editor colors it when it can be.
local function MacroText(parent, text, width)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(CodeFont(), 12, "")
    fs:SetJustifyH("LEFT")
    fs:SetWidth(width)
    fs:SetWordWrap(true)
    local colors = ns.TokenColors(ns.scheme)
    local colored = ns.Highlight.Colorize(text, colors)
    fs:SetText(colored ~= text and colored or ("|cff" .. ns.scheme.attribute .. text .. "|r"))
    return fs
end

local function Height(fs) return math.max(fs:GetStringHeight() or 0, 14) end

-- Section `i` as a frame of its blocks, one under another; its height fits them.
local function BuildSection(i, section)
    local f = CreateFrame("Frame", nil, scroll)
    f:SetWidth(TEXT_W)
    local y = 0
    local title = ns.Text(f, 16)
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(section[1])
    y = y - 30
    local function place(widget, h, gap)
        widget:SetPoint("TOPLEFT", 0, y)
        y = y - h - (gap or 12)
    end
    for _, b in ipairs(section[2]) do
        local kind = b[1]
        if kind == "p" then
            local fs = ns.Text(f, 13)
            fs:SetWidth(TEXT_W)
            fs:SetWordWrap(true)
            fs:SetText(b[2])
            place(fs, Height(fs))
        elseif kind == "code" then
            local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
            ns.Backdrop(box, "bg", "border")
            box:SetWidth(TEXT_W)
            local make = b[3] and ns.Button(box, L["Create"], 80, function() ns.Window.Make(b[3], b[2]) end)
            local fs = MacroText(box, b[2], TEXT_W - 20 - (make and 90 or 0))
            fs:SetPoint("TOPLEFT", 10, -8)
            local h = Height(fs) + 16
            if make then
                make:SetPoint("TOPRIGHT", -6, -6)
                h = math.max(h, 34)
                controls["create " .. b[3]] = make
            end
            box:SetHeight(h)
            place(box, h)
        elseif kind == "rows" or kind == "list" then
            for _, r in ipairs(b[2]) do
                local left
                if kind == "rows" then
                    left = MacroText(f, r[1], LEFT_W - 10)
                else
                    left = ns.Text(f, 13)
                    left:SetWidth(LEFT_W - 10)
                    left:SetWordWrap(true)
                    left:SetText(r[1])
                end
                left:SetPoint("TOPLEFT", 0, y)
                local right = ns.Text(f, 13, "dim")
                right:SetWidth(TEXT_W - LEFT_W)
                right:SetWordWrap(true)
                right:SetText(r[2] or "")
                right:SetPoint("TOPLEFT", LEFT_W, y)
                y = y - math.max(Height(left), Height(right)) - 8
            end
            y = y - 6
        elseif kind == "button" then
            local btn = ns.Button(f, b[2], 160, b[3])
            place(btn, 22)
            controls[b[2]] = btn
        elseif kind == "tasks" then
            local tasks = ns.Practice.Tasks(ns.Practice.Kit())
            if #tasks == 0 then
                local fs = ns.Text(f, 13, "dim")
                fs:SetWidth(TEXT_W)
                fs:SetWordWrap(true)
                fs:SetText(L["The tasks need a spell of yours for enemies. Learn one, then open this section again."])
                place(fs, Height(fs))
            end
            ns.db.practice = ns.db.practice or {}
            for n, task in ipairs(tasks) do
                local head = ns.Text(f, 14)
                local function mark()
                    local done = ns.db.practice[task.id]
                    head:SetText(string.format(L["Task %d"], n)
                        .. (done and ("  |cff" .. ns.scheme.type .. L["done"] .. "|r") or ""))
                end
                mark()
                place(head, 16, 6)
                local goal = ns.Text(f, 13)
                goal:SetWidth(TEXT_W)
                goal:SetWordWrap(true)
                goal:SetText(task.goal)
                place(goal, Height(goal), 8)
                local result = ns.Text(f, 12, "dim")
                result:SetWidth(TEXT_W)
                result:SetWordWrap(true)
                local check = ns.Button(f, L["Check"], 100, function()
                    local ok, said = ns.Practice.Check(task, ns.Window.Text())
                    result:SetText("|cff" .. (ok and ns.scheme.type or ns.scheme.warning) .. said .. "|r")
                    if ok then
                        ns.db.practice[task.id] = true
                        mark()
                    end
                end)
                local answer = ns.Button(f, L["Answer"], 100, function()
                    result:SetText(L["One way to write it:"] .. "\n"
                        .. ns.Highlight.Colorize(task.answer, ns.TokenColors(ns.scheme)))
                end)
                answer:SetPoint("LEFT", check, "RIGHT", 8, 0)
                place(check, 22, 6)
                result:SetFont(CodeFont(), 12, "")
                place(result, 64, 14)
                controls["check " .. task.id], controls["answer " .. task.id] = check, answer
                controls["result " .. task.id] = result
            end
        elseif kind == "link" then
            local link = ns.Input(f, TEXT_W)
            local function select()
                link:SetText(HelpWindow.URL())
                link:HighlightText()
            end
            link:SetScript("OnEditFocusGained", select)
            link:SetScript("OnMouseUp", select)
            -- It is there to copy: a key typed into it puts the link back.
            link:SetScript("OnTextChanged", function(_, userInput) if userInput then select() end end)
            link:SetText(HelpWindow.URL())
            place(link, 24, 6)
            controls.link = link
            local copy = ns.Text(f, 12, "dim")
            copy:SetText(string.format(L["%s copies it; open it in your browser."], Keys("C")))
            place(copy, 14)
        end
    end
    f:SetHeight(-y)
    return f
end

-- Shows section `i`: its frame in the scroll area, its button lit.
local function Show(i)
    current = i
    local sections = Sections()
    built[i] = built[i] or BuildSection(i, sections[i])
    for j, f in pairs(built) do f:SetShown(j == i) end
    scroll:SetScrollChild(built[i])
    scroll:SetVerticalScroll(0)
    for j, b in ipairs(navButtons) do b:SetAlpha(j == i and 1 or 0.6) end
    controls.section = sections[i][1]
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseHelp", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseHelp") -- Esc closes it
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 40)
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
    titleText:SetText(L["Macro guide"])
    local close = ns.Button(title, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    -- The sections, on the left.
    local nav = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    nav:SetPoint("TOPLEFT", 1, -35)
    nav:SetPoint("BOTTOMLEFT", 1, 1)
    nav:SetWidth(NAV)
    ns.Backdrop(nav, "panel", "panel")
    navButtons = {}
    for i, section in ipairs(Sections()) do
        local b = ns.Button(nav, section[1], NAV - 20, function() Show(i) end)
        b:SetPoint("TOPLEFT", 10, -10 - (i - 1) * 28)
        navButtons[i] = b
    end

    -- The section's text, scrolling.
    scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", NAV + PAD, -35 - PAD)
    scroll:SetPoint("BOTTOMRIGHT", -PAD - 18, PAD)
    ns.AttachScrollBar(scroll, 40)
end

function HelpWindow.Open(section)
    if not frame then Build() end
    -- Made again each time: the colors and the code font follow the editor's.
    for _, f in pairs(built) do f:Hide() end
    built = {}
    frame:Show()
    frame:Raise()
    Show(section or current or 1)
end

function HelpWindow.Toggle()
    if frame and frame:IsShown() then return frame:Hide() end
    HelpWindow.Open()
end

function HelpWindow.IsShown() return frame ~= nil and frame:IsShown() end

-- The sections' titles, in order (the tests).
function HelpWindow.Titles()
    local out = {}
    for i, s in ipairs(Sections()) do out[i] = s[1] end
    return out
end

function HelpWindow.Control(name) return controls[name] end
