-- The macro wizard: a window with a form. Pick the command, what it casts or uses, on whom and in what order,
-- what Shift, Ctrl, Alt (Cmd on a Mac) do instead, and what else the macro does; the macro shows under the form
-- as you choose, and Create macro saves it and opens it in the editor. The text comes from Wizard.lua.
local _, ns = ...

local WizardWindow = {}
ns.WizardWindow = WizardWindow

local W = ns.Wizard
local WIDTH, PAD, LABEL, ROW = 600, 14, 70, 32
local X = PAD + LABEL -- where the controls of a row start
local TOP = 84 -- the title bar and the command row
local BOTTOM = 276 -- Also, the macro and the buttons, at the bottom whatever the command
local MATCHES, MATCH_H = 6, 20 -- names shown under a spell box at a time; the wheel scrolls through the rest
local LIST_W = 260 -- the list under a spell box is at least this wide, so long names fit under a narrow box
local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local KEY_NAMES = { shift = "Shift", ctrl = "Ctrl", alt = "Alt", cmd = "Cmd" }
local RESET_NAMES = { target = "New target", combat = "Combat ends", shift = "Shift", ctrl = "Ctrl", alt = "Alt" }
local LIST_TITLES = { castsequence = "In turn, one per press", castrandom = "One of these at random" }

local frame, preview, counter, createBtn
local blocks = {} -- parts of the form, one under another: what (one / list), on whom, the rest (keys / reset)
local controls = {} -- by name: what the tests drive and what starts over with each new form
local spec -- the answers so far
local scope -- the tab the macro goes into
local suggested -- the name the form put in the name box, until someone types another
local Arrange

local function Letters(s)
    return select(2, s:gsub("[^\128-\191]", ""))
end

-- A long name cut to `n` letters (whole ones) and "...", so it stays inside the window.
local function Short(s, n)
    if Letters(s) <= n then return s end
    while Letters(s) > n - 1 do s = s:gsub("[\1-\127\192-\255][\128-\191]*$", "") end
    return s:match("^(.-)%s*$") .. "..."
end

local function Tip(owner, title, text)
    owner:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title, 1, 1, 1)
        GameTooltip:AddLine(text, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    owner:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- The answers changed: the macro under the form, its length, a name while none was typed.
local function Update()
    local text, name = W.Text(spec), W.Name(spec)
    local typed = strtrim(controls.name:GetText())
    if name and (typed == "" or typed == suggested) then
        suggested = ns.Window.FreeName(name)
        controls.name:SetText(suggested)
    end
    local s = ns.scheme
    preview:SetText(text and ns.Highlight.Colorize(text, ns.TokenColors(s))
        or ("|cff" .. s.dim .. "Pick a spell or item to cast, and the macro shows here.|r"))
    local letters = text and Letters(text) or 0
    counter:SetText(string.format("|cff%s%d / %d|r", letters > MAX_BODY and s.invalid or s.dim, letters, MAX_BODY))
    createBtn:SetEnabled(text ~= nil and letters <= MAX_BODY)
end

------------------------------------------------------------------------
-- A spell or item box: type a name, or pick one of yours from the list under it
------------------------------------------------------------------------
-- What a box offers: your spells and the items you can use. /use offers the items first, with the equipment
-- slots whose item has a use effect ("13", Trinket 1).
local function Candidates()
    local spells, items = {}, {}
    for _, spell in ipairs(ns.sources.spells()) do
        spells[#spells + 1] = { name = spell.name, icon = spell.icon, hint = "spell" }
    end
    for _, item in ipairs(ns.sources.items()) do
        if item.usable then items[#items + 1] = { name = item.name, icon = item.icon, hint = item.hint, item = true } end
    end
    local out = {}
    local function add(list)
        for _, c in ipairs(list) do out[#out + 1] = c end
    end
    if spec.command == "use" then
        add(items)
        for _, slot in ipairs(ns.data.slots) do
            local name, usable = ns.sources.equipped(tonumber(slot.name))
            if usable then
                out[#out + 1] = { name = slot.name, hint = slot.hint .. ": " .. name, item = true, label = name }
            end
        end
        add(spells)
    else
        add(spells)
        add(items)
    end
    return out
end

local function MatchList(box, width)
    local list = CreateFrame("Frame", nil, box, "BackdropTemplate")
    list:SetFrameStrata("FULLSCREEN_DIALOG") -- over the rows under the box
    list:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -2)
    list:SetWidth(math.max(width, LIST_W))
    ns.Backdrop(list, "panel", "border")
    list:Hide()
    list.rows, list.items, list.offset, list.selected = {}, {}, 0, 1

    function list:Refresh()
        for i, r in ipairs(self.rows) do
            local item = self.items[self.offset + i]
            r:SetShown(item ~= nil)
            if item then
                r.icon:SetTexture(item.icon and ns.IconTexture(item.icon) or nil)
                r.text:SetText(item.name)
                r.hint:SetText(item.hint or "")
                r.bg:SetShown(self.offset + i == self.selected)
            end
        end
        self:SetHeight(math.min(#self.items, MATCHES) * MATCH_H + 4)
    end

    for i = 1, MATCHES do
        local r = CreateFrame("Button", nil, list)
        r:SetHeight(MATCH_H)
        r:SetPoint("TOPLEFT", 2, -2 - (i - 1) * MATCH_H)
        r:SetPoint("TOPRIGHT", -2, -2 - (i - 1) * MATCH_H)
        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        ns.OnStyle(function(s) r.bg:SetColorTexture(ns.RGB(s.selection)) end)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(MATCH_H - 4, MATCH_H - 4)
        r.icon:SetPoint("LEFT", 2, 0)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.hint = ns.Text(r, 10, "dim")
        r.hint:SetPoint("RIGHT", -4, 0)
        r.text = ns.Text(r, 12)
        r.text:SetPoint("LEFT", r.icon, "RIGHT", 4, 0)
        r.text:SetPoint("RIGHT", r.hint, "LEFT", -6, 0)
        r.text:SetWordWrap(false)
        r:SetScript("OnEnter", function()
            list.selected = list.offset + i
            list:Refresh()
        end)
        r:SetScript("OnClick", function() box:Pick(list.items[list.offset + i]) end)
        list.rows[i] = r
    end

    function list:Open(items)
        self.items, self.offset, self.selected, self.moved = items, 0, 1, false
        if #items == 0 then return self:Hide() end
        self:Refresh()
        self:Show()
    end

    -- Up / Down: the next name, around the list, scrolled into view.
    function list:Move(delta)
        local n = #self.items
        if n == 0 then return end
        self.moved = true
        self.selected = (self.selected - 1 + delta) % n + 1
        if self.selected <= self.offset then
            self.offset = self.selected - 1
        elseif self.selected > self.offset + MATCHES then
            self.offset = self.selected - MATCHES
        end
        self:Refresh()
    end

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        self.offset = math.max(0, math.min(#self.items - MATCHES, self.offset - delta))
        self:Refresh()
    end)
    return list
end

-- set(action) takes what the box says: one of yours under its own name, any other name as a spell (one of
-- another spec, say), nil when it is empty.
local function SpellBox(parent, width, hint, get, set)
    local box = ns.Input(parent, width, 60)
    box.list = MatchList(box, width)
    local placeholder = ns.Text(box, 12, "dim")
    placeholder:SetPoint("LEFT", 6, 0)
    placeholder:SetText(hint)
    local function idle() placeholder:SetShown(box:GetText() == "" and not box:HasFocus()) end

    function box:Commit()
        local typed = strtrim(self:GetText() or "")
        local action
        if typed ~= "" then
            for _, c in ipairs(Candidates()) do
                if c.name:lower() == typed:lower() then
                    action = { name = c.name, item = c.item, label = c.label }
                    break
                end
            end
            action = action or { name = typed }
        end
        self:SetText(action and action.name or "")
        idle()
        local old = get()
        if (old and old.name) == (action and action.name) and (old and old.item) == (action and action.item) then
            return
        end
        set(action)
        Update()
    end

    function box:Pick(item)
        if not item then return end
        self:SetText(item.name)
        self.list:Hide()
        self:ClearFocus()
        self:Commit()
    end

    function box:Refresh()
        self:SetText(get() and get().name or "")
        idle()
    end

    box:SetScript("OnTextChanged", function(self, userInput)
        idle()
        if userInput then self.list:Open(ns.Completion.Match(Candidates(), self:GetText())) end
    end)
    box:HookScript("OnEditFocusGained", function(self)
        idle()
        self.list:Open(ns.Completion.Match(Candidates(), self:GetText()))
    end)
    box:HookScript("OnEditFocusLost", function(self)
        if self.list:IsShown() and self.list:IsMouseOver() then return end -- a click on a name picks it
        self.list:Hide()
        if frame:IsShown() and parent:IsShown() then self:Commit() end
    end)
    box:SetScript("OnArrowPressed", function(self, key)
        if key == "UP" then self.list:Move(-1) elseif key == "DOWN" then self.list:Move(1) end
    end)
    -- Enter takes the name picked in the list; in an empty box only one picked with the arrows (the list there
    -- is all there is to choose from, and Enter leaves the box empty).
    local function accept(self)
        local list = self.list
        if list:IsShown() and (strtrim(self:GetText()) ~= "" or list.moved) then
            return self:Pick(list.items[list.selected])
        end
        self:ClearFocus()
    end
    box:SetScript("OnEnterPressed", accept)
    box:SetScript("OnTabPressed", accept)
    box:SetScript("OnEscapePressed", function(self)
        if self.list:IsShown() then return self.list:Hide() end
        self:ClearFocus()
    end)
    return box
end

------------------------------------------------------------------------
-- The form
------------------------------------------------------------------------
local function Text(parent, text, x, y, colorKey)
    local fs = ns.Text(parent, 12, colorKey)
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

-- A list to choose from: `items` { { key, name } }, the answer through get / set.
local function Choice(parent, name, width, items, get, set)
    local d = ns.Dropdown(parent, width, function() return items end, get, function(key)
        set(key)
        Update()
    end)
    controls[name] = d
    return d
end

local function Check(parent, name, label, get, set)
    local c = ns.Check(parent, label, get, function(on)
        set(on)
        Update()
    end)
    controls[name] = c
    return c
end

-- A part of the form: as wide as the window, `height` tall, placed by Arrange.
local function Block(height)
    local b = CreateFrame("Frame", nil, frame)
    b:SetSize(WIDTH, height)
    b.height = height
    b:Hide()
    return b
end

local function FirstOf(list)
    for i = 1, W.LIST do
        if list[i] then return list[i] end
    end
end

-- The main spell picked: friends or enemies, when the game says which it is for.
local function FollowReaction(action)
    local only = action and ns.sources.reaction(action.name, action.item)
    if only then
        spec.only = only
        controls.only:Refresh()
    end
end

-- And /cast or /use as it is a spell or an item (you can still choose the other).
local function FollowKind(action)
    local command = action and (action.item and "use" or "cast")
    if command and command ~= spec.command then
        spec.command = command
        controls.command:Refresh()
        Arrange()
    end
end

-- Another command: what was picked comes along, the spell of /cast starting a list and the first of a list
-- becoming the spell.
local function SwitchTo(command)
    local wasList = W.IsList(spec.command)
    spec.command = command
    if W.IsList(command) and not wasList and spec.action and not FirstOf(spec.list) then
        spec.list[1] = spec.action
    elseif not W.IsList(command) and wasList and not spec.action then
        spec.action = FirstOf(spec.list)
    end
    for _, control in pairs(controls) do
        if control.Refresh then control:Refresh() end
    end
    Arrange()
end

-- The parts the command asks for, one under another, and the window as tall as they are.
function Arrange()
    local list = W.IsList(spec.command)
    local parts = { list and blocks.list or blocks.one, blocks.on }
    if spec.command == "castsequence" then parts[#parts + 1] = blocks.reset end
    if not list then parts[#parts + 1] = blocks.keys end
    local shown = {}
    for _, b in ipairs(parts) do shown[b] = true end
    for _, b in pairs(blocks) do
        if not shown[b] then b:Hide() end
    end
    local y = -TOP
    for _, b in ipairs(parts) do
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 0, y)
        b:Show()
        y = y - b.height
    end
    frame:SetHeight(-y + BOTTOM)
    controls.castLabel:SetText(spec.command == "use" and "Use" or "Cast")
    controls.listTitle:SetText(LIST_TITLES[spec.command] or "")
end

local function Build()
    -- Cmd is a key only on a Mac.
    local keys = {}
    for _, key in ipairs(W.KEYS) do
        if key ~= "cmd" or (IsMacClient and IsMacClient()) then keys[#keys + 1] = key end
    end

    frame = CreateFrame("Frame", "MacroSenseWizard", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseWizard") -- Esc closes it
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetWidth(WIDTH)
    -- Held by its top: another command makes it taller or shorter below.
    local pos = ns.db.wizard
    frame:SetPoint(pos and pos.point or "TOP", UIParent, pos and pos.relPoint or "TOP", pos and pos.x or 0,
        pos and pos.y or -120)
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
    title:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = frame:GetPoint()
        ns.db.wizard = { point = point, relPoint = relPoint, x = x, y = y }
    end)
    local titleText = ns.Text(title, 14)
    titleText:SetPoint("LEFT", 12, 0)
    titleText:SetText("New macro (Wizard)")
    local close = ns.Button(title, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)

    -- The command, the name, the tab.
    Text(frame, "Command", PAD, -55)
    Choice(frame, "command", 130, W.commands, function() return spec.command end, SwitchTo)
        :SetPoint("TOPLEFT", X, -51)
    Text(frame, "Name", X + 144, -55)
    controls.name = ns.Input(frame, 160, 16)
    controls.name:SetPoint("TOPLEFT", X + 186, -50)
    Text(frame, "Tab", X + 358, -55)
    Choice(frame, "tab", 110, { { key = "general", name = "General" }, { key = "character", name = "Character" } },
        function() return scope end, function(key) scope = key end):SetPoint("TOPLEFT", X + 392, -51)

    -- One spell or item: /cast, /use.
    blocks.one = Block(34)
    controls.castLabel = Text(blocks.one, "Cast", PAD, -5)
    controls.cast = SpellBox(blocks.one, 330, "type a spell or item", function() return spec.action end,
        function(action)
            spec.action = action
            FollowReaction(action)
            FollowKind(action)
        end)
    controls.cast:SetPoint("TOPLEFT", X, 0)

    -- A list: /castsequence, /castrandom. Two columns, read across.
    blocks.list = Block(22 + 3 * ROW + 2)
    controls.listTitle = Text(blocks.list, "", PAD, 0, "dim")
    for i = 1, W.LIST do
        local x, y = X + (i - 1) % 2 * 252, -22 - math.floor((i - 1) / 2) * ROW
        Text(blocks.list, tostring(i), x - 16, y - 5, "dim")
        local box = SpellBox(blocks.list, 236, "spell or item", function() return spec.list[i] end, function(action)
            spec.list[i] = action
            if i == 1 then FollowReaction(action) end
        end)
        box:SetPoint("TOPLEFT", x, y)
        controls["list" .. i] = box
    end

    -- On whom, and who: for every command.
    blocks.on = Block(2 * 34)
    Text(blocks.on, "On", PAD, -5)
    local none = { { key = "none", name = "-" } }
    for _, u in ipairs(W.units) do none[#none + 1] = u end
    for i = 1, 3 do
        local d = Choice(blocks.on, "on" .. i, 120, i == 1 and W.units or none, function() return spec.on[i] end,
            function(key) spec.on[i] = key end)
        d:SetPoint("TOPLEFT", X + (i - 1) * 158, -1)
        if i > 1 then Text(blocks.on, "then", X + (i - 1) * 158 - 32, -5, "dim") end
        Tip(d, i == 1 and "On" or "Then", i == 1 and "Who the macro casts on. As usual: your target, or you when "
            .. "the game casts on you by itself (Auto Self Cast)." or "When the one before is not there, or not "
            .. "the one asked for: this one.")
    end
    Text(blocks.on, "Only", PAD, -39)
    local only = Choice(blocks.on, "only", 120, { { key = "any", name = "Anyone there" },
        { key = "friends", name = "Friends" }, { key = "enemies", name = "Enemies" } },
        function() return spec.only end, function(key) spec.only = key end)
    only:SetPoint("TOPLEFT", X, -35)
    Tip(only, "Only", "What the units above must be: friends, enemies or anyone there. Yourself, As usual and At "
        .. "the cursor need no check. It follows the spell you pick, when the game knows what it is for.")
    Check(blocks.on, "alive", "Alive only", function() return spec.alive end, function(on) spec.alive = on end)
        :SetPoint("TOPLEFT", X + 136, -35)

    -- Keys held (/cast, /use): another spell or the same one, on units of their own, in the On row's columns.
    blocks.keys = Block(8 + 22 + #keys * ROW)
    Text(blocks.keys, "With a key held", PAD, -8, "dim")
    Text(blocks.keys, "on", X + 158, -8, "dim")
    for i, key in ipairs(keys) do
        local y = -30 - (i - 1) * ROW
        Check(blocks.keys, key, KEY_NAMES[key], function() return spec.keys[key].active end,
            function(on) spec.keys[key].active = on end):SetPoint("TOPLEFT", PAD, y - 1)
        local box = SpellBox(blocks.keys, 150, "same spell", function() return spec.keys[key].action end,
            function(action) spec.keys[key].action = action end)
        box:SetPoint("TOPLEFT", X, y)
        controls[key .. "Cast"] = box
        for j, suffix in ipairs({ "On", "Then" }) do
            Choice(blocks.keys, key .. suffix, 120, j == 1 and W.units or none,
                function() return spec.keys[key].on[j] end, function(unit) spec.keys[key].on[j] = unit end)
                :SetPoint("TOPLEFT", X + j * 158, y - 1)
        end
        Text(blocks.keys, "then", X + 284, y - 5, "dim")
    end
    if controls.cmd then
        Tip(controls.cmd, "Cmd", "On a key macOS uses with Cmd itself (Q quits the game, W, H, Tab, Space...) "
            .. "macOS comes first: the editor warns when the macro sits on one.")
    end

    -- What starts a sequence over (/castsequence).
    blocks.reset = Block(8 + 22 + 2 * 26)
    Text(blocks.reset, "Start over", PAD, -8, "dim")
    local x = PAD
    for _, what in ipairs(W.RESETS) do
        local c = Check(blocks.reset, "reset" .. what:gsub("^%l", string.upper), RESET_NAMES[what],
            function() return spec.reset[what] end, function(on) spec.reset[what] = on end)
        c:SetPoint("TOPLEFT", x, -30)
        Tip(c, "Start over", "What makes the sequence begin again from its first spell: a new target, the end of "
            .. "combat, a press with Shift, Ctrl or Alt held, or some seconds without a press.")
        x = x + c:GetWidth() + 18
    end
    local timed = Check(blocks.reset, "resetTimed", "After", function() return spec.reset.timed end,
        function(on) spec.reset.timed = on end)
    timed:SetPoint("TOPLEFT", PAD, -56)
    local seconds = ns.Stepper(blocks.reset, 1, 60, function() return spec.reset.seconds end, function(v)
        spec.reset.seconds = v
        Update()
    end)
    seconds:SetPoint("LEFT", timed, "RIGHT", 8, 0)
    controls.resetSeconds = seconds
    local secondsText = ns.Text(blocks.reset, 12, "dim")
    secondsText:SetPoint("LEFT", seconds, "RIGHT", 8, 0)
    secondsText:SetText("seconds without a press")

    -- Also, the macro, the buttons: at the bottom, from the bottom up.
    local function Low(region, x, y) region:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", x, y) end
    Low(Text(frame, "Also", 0, 0, "dim"), PAD, 268)
    Low(Check(frame, "stopcasting", "Stop your cast first", function() return spec.stopcasting end,
        function(on) spec.stopcasting = on end), PAD, 246)
    Low(Check(frame, "startattack", "Start auto attack", function() return spec.startattack end,
        function(on) spec.startattack = on end), PAD, 222)
    Low(Check(frame, "petattack", "Your pet attacks your target", function() return spec.petattack end,
        function(on) spec.petattack = on end), PAD, 198)
    Low(Check(frame, "trinket1", "Use trinket 1", function() return spec.trinket1 end,
        function(on) spec.trinket1 = on end), PAD + 280, 246)
    Low(Check(frame, "trinket2", "Use trinket 2", function() return spec.trinket2 end,
        function(on) spec.trinket2 = on end), PAD + 280, 222)
    Tip(controls.stopcasting, "Stop your cast first",
        "For an interrupt or a save: it goes off at once, even in the middle of another cast.")

    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetPoint("BOTTOMLEFT", PAD, 50)
    box:SetPoint("BOTTOMRIGHT", -PAD, 50)
    box:SetHeight(100)
    ns.Backdrop(box, "bg", "border")
    preview = box:CreateFontString(nil, "OVERLAY")
    preview:SetPoint("TOPLEFT", 8, -8)
    preview:SetPoint("BOTTOMRIGHT", -8, 8)
    preview:SetJustifyH("LEFT")
    preview:SetJustifyV("TOP")
    controls.preview = preview

    counter = ns.Text(frame, 11, "dim")
    counter:SetPoint("BOTTOMLEFT", PAD, PAD + 5)
    controls.counter = counter
    createBtn = ns.Button(frame, "Create macro", 110, function() WizardWindow.Create() end, true)
    createBtn:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    controls.create = createBtn
    local cancel = ns.Button(frame, "Cancel", 80, function() frame:Hide() end)
    cancel:SetPoint("RIGHT", createBtn, "LEFT", -6, 0)
end

-- The macro goes into the tab chosen, under the name in the box (a free one: "Fear 2" when "Fear" is taken).
function WizardWindow.Create()
    local text = W.Text(spec)
    if not text then return end
    local name = strtrim(controls.name:GetText())
    if name == "" then name = W.Name(spec) or "Macro" end
    ns.Window.CreateFromWizard(name, text, scope)
end

-- A fresh form, for a macro in `tab`.
function WizardWindow.Open(tab)
    spec, scope, suggested = W.Fresh(), tab or "general", nil -- before the form: its controls read them
    if not frame then Build() end
    controls.name:SetText("")
    -- The editor's font, when it is one of ours (not one from another addon).
    local font = ns.FindByKey(ns.fonts, ns.db.font)
    preview:SetFont(font and font.path or ns.UI_FONT, 12, "")
    for slot, check in pairs({ [13] = controls.trinket1, [14] = controls.trinket2 }) do
        local name = ns.sources.equipped(slot)
        check:SetLabel(string.format("Use trinket %d: %s", slot - 12, name and Short(name, 24) or "empty"))
    end
    for _, control in pairs(controls) do
        if control.Refresh then control:Refresh() end
    end
    Arrange()
    Update()
    frame:Show()
    frame:Raise()
end

function WizardWindow.Close()
    if frame then frame:Hide() end
end

function WizardWindow.IsShown() return frame ~= nil and frame:IsShown() end

function WizardWindow.Toggle(tab)
    if WizardWindow.IsShown() then return WizardWindow.Close() end
    WizardWindow.Open(tab)
end

-- A control of the form by name: "command", "cast", "list1", "on1", "shift", "shiftCast", "shiftOn", "shiftThen",
-- "resetTarget", "resetTimed", "resetSeconds", "trinket1", "create", ... (the tests fill the form through it).
function WizardWindow.Control(name) return controls[name] end
