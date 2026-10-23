-- The macro wizard: a window with a form. Pick what to cast, on whom and in what order, what Shift, Ctrl or Alt
-- cast instead, and what else the macro does; the macro shows under the form as you choose, and Create macro
-- saves it and opens it in the editor. The text comes from Wizard.lua.
local _, ns = ...

local WizardWindow = {}
ns.WizardWindow = WizardWindow

local W = ns.Wizard
local WIDTH, HEIGHT, PAD, LABEL = 560, 576, 14, 70
local MATCHES, MATCH_H = 6, 20 -- names shown under a spell box at a time; the wheel scrolls through the rest
local LIST_W = 260 -- the list under a spell box is at least this wide, so long names fit under a narrow box
local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local KEY_NAMES = { shift = "Shift", ctrl = "Ctrl", alt = "Alt" }

local frame, preview, counter, createBtn
local controls = {} -- by name: what the tests drive and what starts over with each new form
local spec -- the answers so far
local scope -- the tab the macro goes into
local suggested -- the name the form put in the name box, until someone types another

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
-- Your spells, then the items you can use.
local function Candidates()
    local out = {}
    for _, spell in ipairs(ns.sources.spells()) do
        out[#out + 1] = { name = spell.name, icon = spell.icon, hint = "spell" }
    end
    for _, item in ipairs(ns.sources.items()) do
        if item.usable then out[#out + 1] = { name = item.name, icon = item.icon, hint = item.hint, item = true } end
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
        self.items, self.offset, self.selected = items, 0, 1
        if #items == 0 then return self:Hide() end
        self:Refresh()
        self:Show()
    end

    -- Up / Down: the next name, around the list, scrolled into view.
    function list:Move(delta)
        local n = #self.items
        if n == 0 then return end
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
local function SpellBox(width, hint, get, set)
    local box = ns.Input(frame, width, 60)
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
                    action = { name = c.name, item = c.item }
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
        if frame:IsShown() then self:Commit() end
    end)
    box:SetScript("OnArrowPressed", function(self, key)
        if key == "UP" then self.list:Move(-1) elseif key == "DOWN" then self.list:Move(1) end
    end)
    local function accept(self)
        if self.list:IsShown() then return self:Pick(self.list.items[self.list.selected]) end
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
local function Text(text, x, y, colorKey)
    local fs = ns.Text(frame, 12, colorKey)
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

-- A list to choose from: `items` { { key, name } }, the answer at spec[...] through get / set.
local function Choice(name, width, items, get, set)
    local d = ns.Dropdown(frame, width, function() return items end, get, function(key)
        set(key)
        Update()
    end)
    controls[name] = d
    return d
end

local function Check(name, label, get, set)
    local c = ns.Check(frame, label, get, function(on)
        set(on)
        Update()
    end)
    controls[name] = c
    return c
end

-- The main spell picked: friends or enemies, when the game says which it is for.
local function FollowReaction(action)
    local only = action and ns.sources.reaction(action.name, action.item)
    if only then
        spec.only = only
        controls.only:Refresh()
    end
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseWizard", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseWizard") -- Esc closes it
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetSize(WIDTH, HEIGHT)
    local pos = ns.db.wizard
    frame:SetPoint(pos and pos.point or "CENTER", UIParent, pos and pos.relPoint or "CENTER", pos and pos.x or 0,
        pos and pos.y or 20)
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

    local x = PAD + LABEL
    -- Name and tab.
    Text("Name", PAD, -55)
    controls.name = ns.Input(frame, 200, 16)
    controls.name:SetPoint("TOPLEFT", x, -50)
    Text("Tab", x + 230, -55)
    Choice("tab", 130, { { key = "general", name = "General" }, { key = "character", name = "Character" } },
        function() return scope end, function(key) scope = key end):SetPoint("TOPLEFT", x + 262, -51)

    -- What, on whom, who.
    Text("Cast", PAD, -89)
    controls.cast = SpellBox(330, "type a spell or item", function() return spec.action end, function(action)
        spec.action = action
        FollowReaction(action)
    end)
    controls.cast:SetPoint("TOPLEFT", x, -84)

    Text("On", PAD, -123)
    local none = { { key = "none", name = "-" } }
    for _, u in ipairs(W.units) do none[#none + 1] = u end
    for i = 1, 3 do
        local d = Choice("on" .. i, 120, i == 1 and W.units or none, function() return spec.on[i] end,
            function(key) spec.on[i] = key end)
        d:SetPoint("TOPLEFT", x + (i - 1) * 158, -119)
        if i > 1 then Text("then", x + (i - 1) * 158 - 32, -123, "dim") end
        Tip(d, i == 1 and "On" or "Then", i == 1 and "Who the macro casts on. As usual: your target, or you when "
            .. "the game casts on you by itself (Auto Self Cast)." or "When the one before is not there, or not "
            .. "the one asked for: this one.")
    end

    Text("Only", PAD, -157)
    local only = Choice("only", 120, { { key = "any", name = "Anyone there" }, { key = "friends", name = "Friends" },
        { key = "enemies", name = "Enemies" } }, function() return spec.only end, function(key) spec.only = key end)
    only:SetPoint("TOPLEFT", x, -153)
    Tip(only, "Only", "What the units above must be: friends, enemies or anyone there. Yourself, As usual and At "
        .. "the cursor need no check. It follows the spell you pick, when the game knows what it is for.")
    Check("alive", "Alive only", function() return spec.alive end, function(on) spec.alive = on end)
        :SetPoint("TOPLEFT", x + 136, -153)

    -- Keys held: another spell or the same one, on units of their own, in the On row's columns.
    Text("With a key held", PAD, -195, "dim")
    Text("on", x + 158, -195, "dim")
    for i, key in ipairs(W.KEYS) do
        local y = -217 - (i - 1) * 32
        Check(key, KEY_NAMES[key], function() return spec.keys[key].active end,
            function(on) spec.keys[key].active = on end):SetPoint("TOPLEFT", PAD, y - 1)
        local box = SpellBox(150, "same spell", function() return spec.keys[key].action end,
            function(action) spec.keys[key].action = action end)
        box:SetPoint("TOPLEFT", x, y)
        controls[key .. "Cast"] = box
        for j, suffix in ipairs({ "On", "Then" }) do
            Choice(key .. suffix, 120, j == 1 and W.units or none, function() return spec.keys[key].on[j] end,
                function(unit) spec.keys[key].on[j] = unit end):SetPoint("TOPLEFT", x + j * 158, y - 1)
        end
        Text("then", x + 284, y - 5, "dim")
    end

    -- Also.
    Text("Also", PAD, -317, "dim")
    Check("stopcasting", "Stop your cast first", function() return spec.stopcasting end,
        function(on) spec.stopcasting = on end):SetPoint("TOPLEFT", PAD, -337)
    Check("startattack", "Start auto attack", function() return spec.startattack end,
        function(on) spec.startattack = on end):SetPoint("TOPLEFT", PAD, -361)
    Check("petattack", "Your pet attacks your target", function() return spec.petattack end,
        function(on) spec.petattack = on end):SetPoint("TOPLEFT", PAD, -385)
    Check("trinket1", "Use trinket 1", function() return spec.trinket1 end,
        function(on) spec.trinket1 = on end):SetPoint("TOPLEFT", PAD + 260, -337)
    Check("trinket2", "Use trinket 2", function() return spec.trinket2 end,
        function(on) spec.trinket2 = on end):SetPoint("TOPLEFT", PAD + 260, -361)
    Tip(controls.stopcasting, "Stop your cast first",
        "For an interrupt or a save: it goes off at once, even in the middle of another cast.")

    -- The macro.
    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetPoint("TOPLEFT", PAD, -419)
    box:SetPoint("TOPRIGHT", -PAD, -419)
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

-- A control of the form by name: "cast", "on1", "shift", "shiftCast", "shiftOn", "shiftThen", "trinket1", ...
-- (the tests fill the form through it).
function WizardWindow.Control(name) return controls[name] end
