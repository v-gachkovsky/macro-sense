-- The macro wizard: a window with a form, or with its questions one at a time (Step by step: for players new to
-- macros, and what it shows the first time). Pick the command, what it casts or uses, on whom and in what order,
-- what Shift, Ctrl, Alt (Cmd on a Mac) do instead, and what else the macro does; the macro shows at the bottom as
-- you choose, and Create macro saves it and opens it in the editor. The text comes from Wizard.lua, the questions
-- from Questions.lua.
local _, ns = ...
local L = ns.L

local WizardWindow = {}
ns.WizardWindow = WizardWindow

local W, Q = ns.Wizard, ns.Questions
local WIDTH, PAD, LABEL, ROW = 600, 14, 70, 32
local X = PAD + LABEL -- where the controls of a row start
local TOP = 84 -- the title bar and the command row
local BOTTOM = 322 -- Also, the macro and the buttons, at the bottom whatever the command
local STEPS_H = 538 -- the window step by step, whatever the question
local STEP_TOP = 124 -- where the answers start, under a question and a hint of two lines and one
local ANSWERS, ANSWER_W = 18, 280 -- the answers a question shows: two columns of nine at most
local MATCHES, MATCH_H = 6, 20 -- names shown under a spell box at a time; the wheel scrolls through the rest
local LIST_W = 260 -- the list under a spell box is at least this wide, so long names fit under a narrow box
local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local KEY_NAMES = { shift = "Shift", ctrl = "Ctrl", alt = "Alt", cmd = "Cmd" }

local frame, preview, counter, createBtn
local form, steps -- the form's parts and the questions': one of them is shown
local blocks = {} -- parts of the form, one under another: what (one / list / name / pet), on whom, the rest
local keyRows = {} -- per key: its spell box, pet command and unit lists, placed by Arrange
local panels = {} -- the answers of a question, by its kind (Questions.Ask): a choice, a spell box, checks...
local controls = {} -- by name: what the tests drive and what starts over with each new form
local spec -- the answers so far
local scope -- the tab the macro goes into
local suggested -- the name the form put in the name box, until someone types another
local keys -- the keys a macro checks here: Cmd only on a Mac
local stepsShown -- the questions are shown, not the form
local step, asked -- the question shown (Questions.Steps) and what it asks (Questions.Ask)
local Arrange, Answered, Go

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

-- The name box shown: the form's, or the last question's.
local function NameBox() return stepsShown and controls.stepName or controls.name end

-- The answers changed: the macro at the bottom, its length, a name while none was typed, Next.
local function Update()
    local text, name = W.Text(spec), W.Name(spec)
    local box = NameBox()
    local typed = strtrim(box:GetText())
    if name and (typed == "" or typed == suggested) then
        suggested = ns.Window.FreeName(name)
        box:SetText(suggested)
    end
    local s = ns.scheme
    preview:SetText(text and ns.Highlight.Colorize(text, ns.TokenColors(s))
        or ("|cff" .. s.dim .. L["Pick a spell or item to cast, and the macro shows here."] .. "|r"))
    local letters = text and Letters(text) or 0
    counter:SetText(string.format("|cff%s%d / %d|r", letters > MAX_BODY and s.invalid or s.dim, letters, MAX_BODY))
    createBtn:SetEnabled(text ~= nil and letters <= MAX_BODY)
    if stepsShown and asked then controls.next:SetEnabled(Answered()) end
end

------------------------------------------------------------------------
-- A spell or item box: type a name, or pick one of yours from the list under it
------------------------------------------------------------------------
-- What a box offers: your spells and the items you can use. /use offers the items first, with the equipment
-- slots whose item has a use effect ("13", Trinket 1).
local function Candidates()
    local spells, items = {}, {}
    for _, spell in ipairs(ns.sources.spells()) do
        spells[#spells + 1] = { name = spell.name, icon = spell.icon, hint = L["spell"], ranks = spell.ranks }
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
                out[#out + 1] = { name = slot.name, hint = L[slot.hint] .. ": " .. name, item = true, label = name }
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
                r.hint:SetText(item.hint and L[item.hint] or "")
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

-- The rows of a spell's ranks: the spell itself first (the highest rank you know, also once you learn a new one),
-- then each rank learned, the highest first.
local function RankItems(spell)
    local out = { { name = spell.name, icon = spell.icon, hint = L["highest rank"] } }
    for i = #spell.ranks, 1, -1 do
        out[#out + 1] = { name = W.Spelled({ name = spell.name, rank = spell.ranks[i] }), icon = spell.icon }
    end
    return out
end

-- set(action) takes what the box says: one of yours under its own name ("Shadow Bolt(Rank 3)" with a rank), any
-- other name as a spell (one of another spec, say), nil when it is empty. `candidates()`: what the list offers,
-- your spells and items if nil. A spell with ranks to pick from lists them once picked, unless `box.noRanks`.
local function SpellBox(parent, width, hint, get, set, candidates)
    candidates = candidates or Candidates
    local box = ns.Input(parent, width, 60)
    box.list = MatchList(box, width)
    local placeholder = ns.Text(box, 12, "dim")
    placeholder:SetPoint("LEFT", 6, 0)
    placeholder:SetText(hint)
    box.placeholder = placeholder
    local function idle() placeholder:SetShown(box:GetText() == "" and not box:HasFocus()) end

    function box:Commit()
        local typed = strtrim(self:GetText() or "")
        local action
        if typed ~= "" then
            local base, rank = typed:match("^(.-)%s*%((.+)%)$") -- "Shadow Bolt(Rank 3)"
            base = base and base:lower()
            for _, c in ipairs(candidates()) do
                local name = c.name:lower()
                if name == typed:lower() or (name == base and not c.item) then
                    action = { name = c.name, item = c.item, label = c.label, ranks = c.ranks,
                        rank = name == base and rank or nil,
                        selfOnly = ns.sources.selfOnly(c.label or c.name, c.item) or nil }
                    break
                end
            end
            action = action or { name = typed }
        end
        self:SetText(action and W.Spelled(action) or "")
        idle()
        local old = get()
        if (old and W.Spelled(old)) == (action and W.Spelled(action)) and (old and old.item) == (action and action.item)
        then
            return
        end
        set(action)
        Update()
    end

    -- A name from the list: taken, and done (true); a spell with ranks to pick from is taken and lists its ranks
    -- next, with the keys still on the box (Esc keeps the spell as it is).
    function box:Pick(item)
        if not item then return false end
        self:SetText(item.name)
        if not self.noRanks and item.ranks and #item.ranks > 1 then
            self:Commit()
            self:SetFocus()
            self.list:Open(RankItems(item))
            return false
        end
        self.list:Hide()
        self:ClearFocus()
        self:Commit()
        return true
    end

    function box:Refresh()
        self:SetText(get() and W.Spelled(get()) or "")
        idle()
    end

    box:SetScript("OnTextChanged", function(self, userInput)
        idle()
        if userInput then self.list:Open(ns.Completion.Match(candidates(), self:GetText())) end
    end)
    box:HookScript("OnEditFocusGained", function(self)
        idle()
        self.list:Open(ns.Completion.Match(candidates(), self:GetText()))
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

-- A list to choose from: `items` { { key, name } }, or a function giving them; the answer through get / set. The
-- names are shown in the chosen language.
local function Choice(parent, name, width, items, get, set)
    local list = type(items) == "function" and items or function() return items end
    local function shown()
        local out = {}
        for i, item in ipairs(list()) do out[i] = { key = item.key, name = L[item.name] } end
        return out
    end
    local d = ns.Dropdown(parent, width, shown, get, function(key)
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
    local b = CreateFrame("Frame", nil, form)
    b:SetSize(WIDTH, height)
    b.height = height
    b:Hide()
    return b
end

-- What the game says a spell or item is for: "friends", "enemies" or nil.
local function ReactionOf(action)
    return action and ns.sources.reaction(action.name, action.item) or nil
end

-- The macro's spell picked: friends or enemies, when the game says which it is for; anyone there again when the
-- game said it for the spell before and doesn't for this one.
local function FollowReaction(action)
    local reaction = ReactionOf(action)
    if reaction or spec.reaction then
        spec.only = reaction or "any"
        controls.only:Refresh()
    end
    spec.reaction = reaction
end

-- A spell or item that goes to nobody but you picked (Demon Armor, a potion): the units of what casts it are as
-- usual, nobody after (Wizard.SelfOnly): the macro's, a list's, a key's.
local function FollowSelf()
    local function usual(on)
        for i = 1, #on do on[i] = i == 1 and "default" or "none" end
    end
    if W.SelfOnly(spec) then usual(spec.on) end
    for _, key in ipairs(W.KEYS) do
        if W.SelfOnly(spec, key) then usual(spec.keys[key].on) end
    end
    -- The form's lists of units show it (the keys of this client: Cmd on a Mac).
    for _, name in ipairs({ "on1", "on2", "on3", "shiftOn", "shiftThen", "ctrlOn", "ctrlThen", "altOn", "altThen",
        "cmdOn", "cmdThen" }) do
        if controls[name] then controls[name]:Refresh() end
    end
end

-- A key's own spell picked: its units are checked for what it is for (Wizard.Only).
local function SetKeyAction(key, action)
    spec.keys[key].action, spec.keys[key].reaction = action, ReactionOf(action)
    FollowSelf()
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

-- Another command: what was picked comes along (Wizard.Switch).
local function SwitchTo(command)
    W.Switch(spec, command)
    for _, control in pairs(controls) do
        if control.Refresh then control:Refresh() end
    end
    Arrange()
end

-- The parts the command asks for, one under another, and the window as tall as they are.
function Arrange()
    local list, target, pet = W.IsList(spec.command), W.IsTarget(spec.command), spec.command == "pet"
    local parts = {}
    if list then
        parts[1] = blocks.list
    elseif pet then
        parts[1] = blocks.pet
    elseif not target then
        parts[1] = blocks.one
    elseif spec.command == "target" then
        parts[1] = blocks.name
    end
    -- Units for a cast or a target; for the pet only when it attacks.
    if not pet or spec.pet == "attack" then parts[#parts + 1] = blocks.on end
    if spec.command == "castsequence" then parts[#parts + 1] = blocks.reset end
    if not list then parts[#parts + 1] = blocks.keys end
    -- A key casts something (or tells the pet something) in the first column and has its units in the On row's
    -- last ones; for /target, /focus and /assist it only has units, in the first ones.
    for key, row in pairs(keyRows) do
        local x = target and X or X + 158
        local units = not pet or spec.keys[key].pet == "attack"
        row.box:SetShown(not target and not pet)
        row.pet:SetShown(pet)
        row.on:SetPoint("TOPLEFT", x, row.y - 1)
        row["then"]:SetPoint("TOPLEFT", x + 158, row.y - 1)
        row.word:SetPoint("TOPLEFT", x + 126, row.y - 5)
        row.on:SetShown(units)
        row["then"]:SetShown(units)
        row.word:SetShown(units)
    end
    blocks.keys.on:SetPoint("TOPLEFT", target and X or X + 158, -8)
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
    if not stepsShown then frame:SetHeight(-y + BOTTOM) end
    controls.castLabel:SetText(spec.command == "use" and L["Use"] or L["Cast"])
    controls.listTitle:SetText(spec.command == "castsequence" and L["In turn, one per press"]
        or spec.command == "castrandom" and L["One of these at random"] or "")
end

-- What else the macro does, in three columns of yes / no, then a buff to cancel first and what to say in chat last:
-- in the form, and as a question. `prefix` names the controls: "" the form's ("stopcasting"), "step" the
-- question's ("stepStopcasting").
local function BuildAlso(parent, prefix)
    local function named(name) return prefix == "" and name or prefix .. (name:gsub("^%l", string.upper)) end
    -- By name and by place from the top left.
    local also = {
        { "stopcasting", L["Stop your cast first"], L["For an interrupt or a save: it goes off at once, even in the "
            .. "middle of another cast."] },
        { "trinket1", L["Trinket 1"] },
        { "nearest", L["Nearest enemy if none"], L["When your target is not an enemy, or is dead, the nearest enemy "
            .. "becomes the target first (/targetenemy [noharm][dead])."] },
        { "startattack", L["Start auto attack"] },
        { "trinket2", L["Trinket 2"], L["Your trinkets go off first (/use 13, /use 14), whenever they are ready."] },
        { "cancelform", L["Leave your form first"], L["Out of a form or stance first (/cancelform): to heal out of "
            .. "Bear Form, say."] },
        { "petattack", L["Pet attacks your target"] },
        { "dismount", L["Off your mount first"], L["Off the mount first (/dismount [mounted]), so the cast doesn't "
            .. "fail on it."] },
    }
    for i, c in ipairs(also) do
        local name = c[1]
        local check = Check(parent, named(name), c[2], function() return spec[name] end,
            function(on) spec[name] = on end)
        check:SetPoint("TOPLEFT", PAD + (i - 1) % 3 * 192, -math.floor((i - 1) / 3) * 24)
        if c[3] then Tip(check, c[2], c[3]) end
    end
    Text(parent, L["Cancel a buff"], PAD, -78)
    local buff = SpellBox(parent, 200, L["the buff's name"], function() return spec.cancelaura end,
        function(action) spec.cancelaura = action end, ns.sources.buffs)
    buff:SetPoint("TOPLEFT", PAD + 120, -74)
    controls[named("cancelaura")] = buff
    Tip(buff, L["Cancel a buff first"], L["Removes the buff before the rest (/cancelaura Ice Block): leave it empty "
        .. "for none. It offers the buffs on you now and those you have had."])
    Text(parent, L["Say in chat"], PAD, -110)
    Choice(parent, named("channel"), 100, W.channels, function() return spec.channel end,
        function(key) spec.channel = key end):SetPoint("TOPLEFT", PAD + 120, -107)
    local say = ns.Input(parent, 344, 255)
    say:SetPoint("TOPLEFT", PAD + 228, -106)
    say:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        spec.say = self:GetText()
        Update()
    end)
    function say:Refresh() self:SetText(spec.say or "") end
    Tip(say, L["Say in chat"], L["Said after the rest, in the channel on the left; %t is your target's name. Leave "
        .. "it empty to say nothing."])
    controls[named("say")] = say
end

-- Cmd on a key macOS keeps for itself: what it does there.
local function CmdTip(check)
    Tip(check, "Cmd", L["On a key macOS uses with Cmd itself (Q quits the game, W, H, Tab, Space...) macOS comes "
        .. "first: the editor warns when the macro sits on one."])
end

------------------------------------------------------------------------
-- Step by step: the form's questions one at a time (Questions.lua)
------------------------------------------------------------------------
-- Whether the question has its answer: a spell for the macro (a key's may stay empty: it casts the macro's), one
-- in the list, a name to look for. What is being typed counts: Next takes it.
function Answered()
    local kind = asked and asked.kind
    local function typed(box) return strtrim(box:GetText() or "") ~= "" end
    if kind == "spell" then return spec.action ~= nil or typed(controls.stepSpell) end
    if kind == "list" then
        for i = 1, W.LIST do
            if spec.list[i] or typed(controls["stepList" .. i]) then return true end
        end
        return false
    end
    if kind == "byName" then return strtrim(spec.byName or "") ~= "" end
    return true
end

-- The question of `step`: what it asks and its answers; Back, and Next or at the end Create macro.
local function ShowStep()
    asked = Q.Ask(spec, step, keys)
    controls.context:SetText(asked.context or "")
    controls.question:SetText(asked.text or "")
    controls.hint:SetText(asked.hint or "")
    for kind, panel in pairs(panels) do panel:SetShown(kind == asked.kind) end
    for i = 1, ANSWERS do
        local b, answer = controls["answer" .. i], asked.answers and asked.answers[i]
        b:SetShown(answer ~= nil)
        if answer then
            b.key, b.tip = answer.key, answer.tip
            b.label:SetText(answer.name)
            b.hint:SetText(answer.hint or "")
            b:SetChosen(answer.key == asked.chosen)
        end
    end
    for _, control in pairs(controls) do
        if control.Refresh then control:Refresh() end
    end
    -- A key casts the macro's spell unless it has one of its own.
    local box = controls.stepSpell
    box.placeholder:SetText(asked.key and L["same spell"] or L["type a spell or item"])
    if asked.kind == "spell" and not asked.key and not spec.action then box:SetFocus() end
    controls.stepGeneral:SetChosen(scope == "general")
    controls.stepCharacter:SetChosen(scope == "character")
    controls.back:SetEnabled(Q.Next(spec, keys, step, true) ~= nil)
    controls.next:SetShown(asked.kind ~= "finish")
    controls.next:SetEnabled(Answered())
    createBtn:SetShown(asked.kind == "finish")
end

-- What is being typed is taken, as if Enter was pressed.
local function TakeTyped()
    for _, control in pairs(controls) do
        if control.HasFocus and control:HasFocus() then control:ClearFocus() end
    end
end

-- On to the next question, or back to the one before. What is being typed is taken first.
function Go(back)
    TakeTyped()
    if not back and not Answered() then return end
    step = Q.Next(spec, keys, step, back) or step
    ShowStep()
end

-- The question, what it is about (a key held) and a hint over it; under them the answers of its kind.
local function BuildSteps()
    steps = CreateFrame("Frame", nil, frame)
    steps:SetAllPoints()
    controls.context = ns.Text(steps, 12, "dim")
    controls.context:SetPoint("TOPLEFT", PAD, -44)
    controls.question = ns.Text(steps, 14)
    controls.question:SetPoint("TOPLEFT", PAD, -60)
    controls.question:SetWidth(WIDTH - 2 * PAD)
    controls.hint = ns.Text(steps, 12, "dim")
    controls.hint:SetPoint("TOPLEFT", controls.question, "BOTTOMLEFT", 0, -6)
    controls.hint:SetWidth(WIDTH - 2 * PAD)
    for _, kind in ipairs({ "choice", "spell", "list", "reset", "byName", "keys", "also", "finish" }) do
        local panel = CreateFrame("Frame", nil, steps)
        panel:SetPoint("TOPLEFT", 0, -STEP_TOP)
        panel:SetSize(WIDTH, STEPS_H - STEP_TOP - 150)
        panel:Hide()
        panels[kind] = panel
    end

    -- A choice: a click answers and goes on. The hint says the macro's words for it, the tooltip what it is.
    for i = 1, ANSWERS do
        local b = ns.Answer(panels.choice, ANSWER_W, function(self)
            Q.Choose(spec, step, self.key)
            Update()
            Go()
        end)
        b:SetPoint("TOPLEFT", PAD + (i - 1) % 2 * (ANSWER_W + 12), -math.floor((i - 1) / 2) * 28)
        b:HookScript("OnEnter", function(self)
            if not self.tip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.label:GetText(), 1, 1, 1)
            GameTooltip:AddLine(self.tip, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", function() GameTooltip:Hide() end)
        controls["answer" .. i] = b
    end

    -- A spell or item: the macro's, or a key's. Picked from the list, it goes on.
    local function keyOf() return asked and asked.key end
    local box = SpellBox(panels.spell, 400, L["type a spell or item"], function()
        local key = keyOf()
        if key then return spec.keys[key].action end
        return spec.action
    end, function(action)
        local key = keyOf()
        if key then
            SetKeyAction(key, action)
        else
            spec.action = action
            FollowReaction(action)
            FollowKind(action)
            FollowSelf()
        end
    end)
    box:SetPoint("TOPLEFT", PAD, 0)
    box:HookScript("OnTextChanged", function() controls.next:SetEnabled(Answered()) end)
    box.noRanks = true -- the next question asks for the rank
    local pick = box.Pick
    function box:Pick(item)
        if pick(self, item) then Go() end
    end
    controls.stepSpell = box

    -- A list, in two columns read across.
    for i = 1, W.LIST do
        local x, y = PAD + 16 + (i - 1) % 2 * 272, -math.floor((i - 1) / 2) * ROW
        Text(panels.list, tostring(i), x - 16, y - 5, "dim")
        local item = SpellBox(panels.list, 236, L["spell or item"], function() return spec.list[i] end,
            function(action)
                spec.list[i] = action
                if i == 1 then FollowReaction(action) end
                FollowSelf()
            end)
        item:SetPoint("TOPLEFT", x, y)
        item:HookScript("OnTextChanged", function() controls.next:SetEnabled(Answered()) end)
        controls["stepList" .. i] = item
    end

    -- What starts a sequence over: one a line.
    local y = 0
    for _, what in ipairs(W.RESETS) do
        local label = what == "target" and L["When you take a new target"] or what == "combat"
            and L["When combat ends"] or string.format(L["When you press it with %s held"], KEY_NAMES[what])
        Check(panels.reset, "stepReset" .. what:gsub("^%l", string.upper), label,
            function() return spec.reset[what] end, function(on) spec.reset[what] = on end):SetPoint("TOPLEFT", PAD, y)
        y = y - 26
    end
    local timed = Check(panels.reset, "stepResetTimed", L["After"], function() return spec.reset.timed end,
        function(on) spec.reset.timed = on end)
    timed:SetPoint("TOPLEFT", PAD, y)
    local seconds = ns.Stepper(panels.reset, 1, 60, function() return spec.reset.seconds end, function(v)
        spec.reset.seconds = v
        Update()
    end)
    seconds:SetPoint("LEFT", timed, "RIGHT", 8, 0)
    controls.stepResetSeconds = seconds
    local secondsText = ns.Text(panels.reset, 12, "dim")
    secondsText:SetPoint("LEFT", seconds, "RIGHT", 8, 0)
    secondsText:SetText(L["seconds without a press"])

    -- /target by name. Enter goes on.
    local name = ns.Input(panels.byName, 240, 60)
    name:SetPoint("TOPLEFT", PAD, 0)
    name:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        spec.byName = self:GetText()
        Update()
    end)
    name:SetScript("OnEnterPressed", function() Go() end)
    function name:Refresh() self:SetText(spec.byName or "") end
    controls.stepByName = name

    -- The keys held: what each one does comes next.
    for i, key in ipairs(keys) do
        Check(panels.keys, "step" .. KEY_NAMES[key], KEY_NAMES[key], function() return spec.keys[key].active end,
            function(on) spec.keys[key].active = on end):SetPoint("TOPLEFT", PAD, -(i - 1) * 26)
    end
    if controls.stepCmd then CmdTip(controls.stepCmd) end

    BuildAlso(panels.also, "step")

    -- The name and the tab. Enter in the name creates the macro.
    Text(panels.finish, L["Name"], PAD, -5)
    controls.stepName = ns.Input(panels.finish, 200, 16)
    controls.stepName:SetPoint("TOPLEFT", PAD + 60, 0)
    controls.stepName:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        WizardWindow.Create()
    end)
    local tabs = { { "general", L["For all your characters"] }, { "character", L["Only for this character"] } }
    for i, tab in ipairs(tabs) do
        local b = ns.Answer(panels.finish, ANSWER_W, function(self)
            scope = self.key
            controls.stepGeneral:SetChosen(scope == "general")
            controls.stepCharacter:SetChosen(scope == "character")
        end)
        b.key = tab[1]
        b.label:SetText(tab[2])
        b:SetPoint("TOPLEFT", PAD + (i - 1) * (ANSWER_W + 12), -40)
        controls[i == 1 and "stepGeneral" or "stepCharacter"] = b
    end
end

-- The form or its questions, as chosen last: the questions the first time. They start from the first one.
local function ShowMode()
    stepsShown = not ns.db.wizardForm
    form:SetShown(not stepsShown)
    steps:SetShown(stepsShown)
    controls.mode.label:SetText(stepsShown and L["All options"] or L["Step by step"])
    controls.cancel:SetShown(not stepsShown)
    controls.back:SetShown(stepsShown)
    if stepsShown then
        step = "what"
        frame:SetHeight(STEPS_H)
        return ShowStep()
    end
    asked = nil
    controls.next:Hide()
    createBtn:Show()
    for _, control in pairs(controls) do
        if control.Refresh then control:Refresh() end
    end
    Arrange()
end

local function Build()
    -- Cmd is a key only on a Mac.
    keys = {}
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
    titleText:SetText(L["New macro (Wizard)"])
    local close = ns.Button(title, "x", 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -6, 0)
    -- The form or its questions: the answers and the name typed stay.
    local mode = ns.Button(title, "", 110, function()
        TakeTyped()
        local name = NameBox():GetText()
        ns.db.wizardForm = stepsShown or nil
        ShowMode()
        NameBox():SetText(name)
        Update()
    end)
    mode:SetPoint("RIGHT", close, "LEFT", -6, 0)
    mode:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(self.label:GetText(), 1, 1, 1)
        GameTooltip:AddLine(stepsShown and L["The whole form at once, with what you chose so far."]
            or L["One question at a time, in plain words. What you chose stays."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    mode:HookScript("OnLeave", function() GameTooltip:Hide() end)
    controls.mode = mode

    form = CreateFrame("Frame", nil, frame)
    form:SetAllPoints()
    -- The command, the name, the tab.
    Text(form, L["Command"], PAD, -55)
    Choice(form, "command", 130, W.commands, function() return spec.command end, SwitchTo)
        :SetPoint("TOPLEFT", X, -51)
    Text(form, L["Name"], X + 144, -55)
    controls.name = ns.Input(form, 140, 16)
    controls.name:SetPoint("TOPLEFT", X + 186, -50)
    Text(form, L["Tab"], X + 338, -55)
    Choice(form, "tab", 110, { { key = "general", name = "General" }, { key = "character", name = "Character" } },
        function() return scope end, function(key) scope = key end):SetPoint("TOPLEFT", X + 392, -51)

    -- One spell or item: /cast, /use.
    blocks.one = Block(34)
    controls.castLabel = Text(blocks.one, L["Cast"], PAD, -5)
    controls.cast = SpellBox(blocks.one, 330, L["type a spell or item"], function() return spec.action end,
        function(action)
            spec.action = action
            FollowReaction(action)
            FollowKind(action)
            FollowSelf()
        end)
    controls.cast:SetPoint("TOPLEFT", X, 0)

    -- A list: /castsequence, /castrandom. Two columns, read across.
    blocks.list = Block(22 + 3 * ROW + 2)
    controls.listTitle = Text(blocks.list, "", PAD, 0, "dim")
    for i = 1, W.LIST do
        local x, y = X + (i - 1) % 2 * 252, -22 - math.floor((i - 1) / 2) * ROW
        Text(blocks.list, tostring(i), x - 16, y - 5, "dim")
        local box = SpellBox(blocks.list, 236, L["spell or item"], function() return spec.list[i] end, function(action)
            spec.list[i] = action
            if i == 1 then FollowReaction(action) end
            FollowSelf()
        end)
        box:SetPoint("TOPLEFT", x, y)
        controls["list" .. i] = box
    end

    -- /target by name: a rare, say.
    blocks.name = Block(34)
    Text(blocks.name, L["By name"], PAD, -5)
    controls.byName = ns.Input(blocks.name, 240, 60)
    controls.byName:SetPoint("TOPLEFT", X, 0)
    controls.byName:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        spec.byName = self:GetText()
        Update()
    end)
    function controls.byName:Refresh() self:SetText(spec.byName or "") end
    Tip(controls.byName, L["By name"], L["Targets the nearest one with this name, when none of the units above is "
        .. "there. Leave On empty (-) to target by name only."])

    -- What the pet does without a key.
    blocks.pet = Block(34)
    Text(blocks.pet, L["Pet"], PAD, -5)
    -- Only what this game has (no Move To before Cataclysm).
    local function petActions() return W.PetActions(LE_EXPANSION_LEVEL_CURRENT) end
    Choice(blocks.pet, "pet", 150, petActions, function() return spec.pet end, function(action)
        spec.pet = action
        Arrange()
    end):SetPoint("TOPLEFT", X, -1)

    -- On whom, and who: for every command (the units a command takes, Wizard.Units).
    blocks.on = Block(2 * 34)
    Text(blocks.on, L["On"], PAD, -5)
    for i = 1, 3 do
        local d = Choice(blocks.on, "on" .. i, 120, function() return W.Units(spec.command, i == 1 and "first" or "then") end,
            function() return spec.on[i] end, function(key) spec.on[i] = key end)
        d:SetPoint("TOPLEFT", X + (i - 1) * 158, -1)
        if i > 1 then Text(blocks.on, L["then"], X + (i - 1) * 158 - 32, -5, "dim") end
        Tip(d, i == 1 and L["On"] or L["Then"], i == 1 and (L["Who the macro casts on. As usual: your target, or "
            .. "you when the game casts on you by itself (Auto Self Cast)."] .. " " .. L["Group's tank or healer: "
            .. "@tank and @heal, the name of the one with the role in the game's macro, kept up to date."])
            or L["When the one before is not there, or not the one asked for: this one."])
    end
    Text(blocks.on, L["Only"], PAD, -39)
    local only = Choice(blocks.on, "only", 120, { { key = "any", name = L["Anyone there"] },
        { key = "friends", name = L["Friends"] }, { key = "enemies", name = L["Enemies"] } },
        function() return spec.only end, function(key) spec.only = key end)
    only:SetPoint("TOPLEFT", X, -35)
    Tip(only, L["Only"], L["What the units above must be: friends, enemies or anyone there. Yourself, As usual and "
        .. "At the cursor need no check. It follows the spell you pick, when the game knows what it is for; a key's "
        .. "own spell is checked for what it is for."])
    Check(blocks.on, "alive", L["Alive only"], function() return spec.alive end, function(on) spec.alive = on end)
        :SetPoint("TOPLEFT", X + 136, -35)

    -- Keys held (/cast, /use): another spell or the same one, on units of their own, in the On row's columns.
    blocks.keys = Block(8 + 22 + #keys * ROW)
    Text(blocks.keys, L["With a key held"], PAD, -8, "dim")
    blocks.keys.on = Text(blocks.keys, L["on"], X + 158, -8, "dim")
    for i, key in ipairs(keys) do
        local y = -30 - (i - 1) * ROW
        Check(blocks.keys, key, KEY_NAMES[key], function() return spec.keys[key].active end,
            function(on) spec.keys[key].active = on end):SetPoint("TOPLEFT", PAD, y - 1)
        local box = SpellBox(blocks.keys, 150, L["same spell"], function() return spec.keys[key].action end,
            function(action) SetKeyAction(key, action) end)
        box:SetPoint("TOPLEFT", X, y)
        controls[key .. "Cast"] = box
        local row = { y = y, box = box, word = Text(blocks.keys, L["then"], X + 284, y - 5, "dim") }
        row.pet = Choice(blocks.keys, key .. "Pet", 150, petActions, function() return spec.keys[key].pet end,
            function(action)
                spec.keys[key].pet = action
                Arrange()
            end)
        row.pet:SetPoint("TOPLEFT", X, y - 1)
        for j, suffix in ipairs({ "On", "Then" }) do
            row[j == 1 and "on" or "then"] = Choice(blocks.keys, key .. suffix, 120,
                function() return W.Units(spec.command, j == 1 and "key" or "then") end,
                function() return spec.keys[key].on[j] end, function(unit) spec.keys[key].on[j] = unit end)
        end
        keyRows[key] = row
    end
    if controls.cmd then CmdTip(controls.cmd) end

    -- What starts a sequence over (/castsequence).
    blocks.reset = Block(8 + 22 + 2 * 26)
    Text(blocks.reset, L["Start over"], PAD, -8, "dim")
    local x = PAD
    local resetNames = { target = L["New target"], combat = L["Combat ends"], shift = "Shift", ctrl = "Ctrl",
        alt = "Alt" }
    for _, what in ipairs(W.RESETS) do
        local c = Check(blocks.reset, "reset" .. what:gsub("^%l", string.upper), resetNames[what],
            function() return spec.reset[what] end, function(on) spec.reset[what] = on end)
        c:SetPoint("TOPLEFT", x, -30)
        Tip(c, L["Start over"], L["What makes the sequence begin again from its first spell: a new target, the end "
            .. "of combat, a press with Shift, Ctrl or Alt held, or some seconds without a press."])
        x = x + c:GetWidth() + 18
    end
    local timed = Check(blocks.reset, "resetTimed", L["After"], function() return spec.reset.timed end,
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
    secondsText:SetText(L["seconds without a press"])

    -- Also, the macro, the buttons: at the bottom, from the bottom up.
    local function Low(region, x, y) region:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", x, y) end
    Low(Text(form, L["Also"], 0, 0, "dim"), PAD, 314)
    local also = CreateFrame("Frame", nil, form)
    also:SetSize(WIDTH, 140)
    Low(also, 0, 292)
    BuildAlso(also, "")

    BuildSteps()

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
    createBtn = ns.Button(frame, L["Create macro"], 110, function() WizardWindow.Create() end, true)
    createBtn:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    controls.create = createBtn
    local cancel = ns.Button(frame, L["Cancel"], 80, function() frame:Hide() end)
    cancel:SetPoint("RIGHT", createBtn, "LEFT", -6, 0)
    controls.cancel = cancel
    -- Step by step: Next where Create macro is, Back where Cancel is.
    controls.next = ns.Button(frame, L["Next >"], 110, function() Go() end, true)
    controls.next:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    controls.back = ns.Button(frame, L["< Back"], 80, function() Go(true) end)
    controls.back:SetPoint("RIGHT", createBtn, "LEFT", -6, 0)
end

-- The macro goes into the tab chosen, under the name in the box (a free one: "Fear 2" when "Fear" is taken).
function WizardWindow.Create()
    local text = W.Text(spec)
    if not text then return end
    local name = strtrim(NameBox():GetText())
    if name == "" then name = W.Name(spec) or L["Macro"] end
    ns.Window.CreateFromWizard(name, text, scope)
end

-- A fresh form, for a macro in `tab`: the questions from the first, or the form.
function WizardWindow.Open(tab)
    spec, scope, suggested = W.Fresh(), tab or "general", nil -- before the form: its controls read them
    if not frame then Build() end
    controls.name:SetText("")
    controls.stepName:SetText("")
    -- The editor's font, when it is one of ours (not one from another addon).
    local font = ns.FindByKey(ns.fonts, ns.db.font)
    preview:SetFont(font and font.path or ns.UIFont(), 12, "")
    for slot = 13, 14 do
        local name = ns.sources.equipped(slot)
        local label = string.format(L["Trinket %d: %s"], slot - 12, name and Short(name, 14) or L["empty"])
        controls["trinket" .. (slot - 12)]:SetLabel(label)
        controls["stepTrinket" .. (slot - 12)]:SetLabel(label)
    end
    ShowMode()
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

-- A control of the form by name: "command", "cast", "list1", "byName", "on1", "shift", "shiftCast", "shiftOn", "shiftThen",
-- "resetTarget", "resetTimed", "resetSeconds", "pet", "shiftPet", "trinket1", "cancelaura", "channel", "say",
-- "create", ...; of the questions: "mode", "question", "hint", "context", "answer1", "stepSpell", "stepList1",
-- "stepResetTarget", "stepByName", "stepShift", "stepStopcasting", "stepName", "stepGeneral", "back", "next"... (the
-- tests fill the form through it).
function WizardWindow.Control(name) return controls[name] end
