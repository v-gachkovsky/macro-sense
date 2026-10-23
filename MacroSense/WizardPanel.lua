-- The wizard panel next to the editor: pick what the macro should do, answer a few questions, and the macro goes
-- into the editor as you answer, with its colors, checks and live preview. Save keeps it.
-- The recipes and the text they write are in Wizard.lua.
local _, ns = ...

local Panel = {}
ns.WizardPanel = Panel

local W = ns.Wizard
local WIDTH, PAD, HEADER = 300, 12, 34
local LABEL = 96 -- the labels' column on a recipe's page
local MATCHES, MATCH_H = 6, 20 -- names shown under a spell box at a time; the wheel scrolls through the rest

local frame, titleText, backBtn, listPage, footer, replaceBtn
local forms = {} -- recipe key -> its page, made the first time it opens
local recipe, choices -- the recipe open and its answers so far
local held -- { text, name }: the wizard's macro the editor did not take, as it was changed there

------------------------------------------------------------------------
-- Writing the macro
------------------------------------------------------------------------
local function UpdateFooter()
    replaceBtn:SetShown(held ~= nil)
    footer:ClearAllPoints()
    footer:SetPoint("BOTTOMLEFT", PAD, PAD)
    if held then
        footer:SetPoint("BOTTOMRIGHT", replaceBtn, "BOTTOMLEFT", -8, 0)
        footer:SetText("|cff" .. ns.scheme.warning .. "You changed the macro in the editor, so the wizard left it.|r")
        return
    end
    footer:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    if recipe then
        local undo = IsMacClient and IsMacClient() and "Cmd+Z" or "Ctrl+Z"
        footer:SetText("Each answer goes into the editor at once. Save keeps the macro, " .. undo
            .. " takes a change back.")
    else
        footer:SetText("A new macro, in the tab that is open.")
    end
end

-- The answers changed: show the questions that apply now and write the macro (none while it lacks what it
-- needs).
local function Changed()
    forms[recipe.key]:Layout()
    local text = W.Text(recipe, choices)
    local name = text and W.Name(recipe, choices)
    held = nil
    if not ns.Window.WizardWrite(text or "", name) and text then held = { text = text, name = name } end
    UpdateFooter()
end

-- The main spell picked: friends or enemies, when the game says which it is for.
local function FollowReaction(action)
    for _, f in ipairs(recipe.fields) do
        local on = f.reaction and ns.sources.reaction(action.name, action.item)
        if on then
            choices[f.key] = on
            forms[recipe.key].controls[f.key]:Refresh()
        end
    end
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

-- Names that start with what was typed, then those that have it further in.
local function Matches(typed)
    local q = strtrim(typed or ""):lower()
    local first, rest = {}, {}
    for _, c in ipairs(Candidates()) do
        local at = c.name:lower():find(q, 1, true)
        if at == 1 then first[#first + 1] = c elseif at then rest[#rest + 1] = c end
    end
    for _, c in ipairs(rest) do first[#first + 1] = c end
    return first
end

-- Under the box, as wide as its row: long names fit.
local function MatchList(box, row)
    local list = CreateFrame("Frame", nil, box, "BackdropTemplate")
    list:SetFrameStrata("FULLSCREEN_DIALOG") -- over the questions under the box
    list:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, -2)
    list:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", 0, -2)
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

local function ActionBox(owner, row, field, width)
    local box = ns.Input(row, width, 60)
    box.list = MatchList(box, row)
    local placeholder = ns.Text(box, 12, "dim")
    placeholder:SetPoint("LEFT", 6, 0)
    placeholder:SetText("type to search")
    local function idle() placeholder:SetShown(box:GetText() == "" and not box:HasFocus()) end

    -- What the box says goes into the answers: one of yours under its own name, any other name as a spell
    -- (one of another spec, say). Not once its page is gone: a box loses the focus as it hides.
    function box:Commit()
        if recipe ~= owner then return end
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
        local old = choices[field.key]
        if (old and old.name) == (action and action.name) and (old and old.item) == (action and action.item) then
            return
        end
        choices[field.key] = action
        if action and field.key == "action" then FollowReaction(action) end
        Changed()
    end

    function box:Pick(item)
        if not item then return end
        self:SetText(item.name)
        self.list:Hide()
        self:ClearFocus()
        self:Commit()
    end

    box:SetScript("OnTextChanged", function(self, userInput)
        idle()
        if userInput then self.list:Open(Matches(self:GetText())) end
    end)
    box:HookScript("OnEditFocusGained", function(self)
        idle()
        self.list:Open(Matches(self:GetText()))
    end)
    box:HookScript("OnEditFocusLost", function(self)
        if self.list:IsShown() and self.list:IsMouseOver() then return end -- a click on a name picks it
        self.list:Hide()
        self:Commit()
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
-- Pages: the recipes, and the questions of one
------------------------------------------------------------------------
local function Form(r)
    local form = CreateFrame("Frame", nil, frame)
    form:SetPoint("TOPLEFT", 0, -HEADER)
    form:SetPoint("BOTTOMRIGHT")
    form:Hide()
    local text = ns.Text(form, 12, "dim")
    text:SetPoint("TOPLEFT", PAD, -PAD)
    text:SetWidth(WIDTH - 2 * PAD)
    text:SetText(r.text)
    form.rows, form.controls = {}, {}
    local width = WIDTH - 2 * PAD - LABEL
    for _, field in ipairs(r.fields) do
        local row = CreateFrame("Frame", nil, form)
        row.field = field
        row:SetHeight(field.kind == "note" and 16 or 24)
        local control
        if field.kind == "action" or field.kind == "choice" then
            local label = ns.Text(row, 12)
            label:SetPoint("LEFT")
            label:SetText(field.label)
            if field.kind == "action" then
                control = ActionBox(r, row, field, width)
            else
                control = ns.Dropdown(row, width, function() return field.options end,
                    function() return choices[field.key] end,
                    function(key)
                        choices[field.key] = key
                        Changed()
                    end)
            end
            control:SetPoint("RIGHT")
        elseif field.kind == "check" then
            control = ns.Check(row, field.label, function() return choices[field.key] end, function(on)
                choices[field.key] = on
                Changed()
            end)
            control:SetPoint("LEFT")
            if field.tip then Tip(control, field.label, field.tip) end
        else
            local note = ns.Text(row, 11, "dim")
            note:SetPoint("LEFT")
            note:SetPoint("RIGHT")
            note:SetText(field.text)
        end
        if control then form.controls[field.key] = control end
        form.rows[#form.rows + 1] = row
    end

    -- One question under another, without those that don't apply now.
    function form:Layout()
        local y = -PAD - math.ceil(text:GetStringHeight()) - 14
        for _, row in ipairs(self.rows) do
            local shown = W.Asked(row.field, choices)
            row:SetShown(shown)
            if shown then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", PAD, y)
                row:SetPoint("TOPRIGHT", -PAD, y)
                y = y - row:GetHeight() - 8
            end
        end
    end
    return form
end

local function RecipeList()
    local page = CreateFrame("Frame", nil, frame)
    page:SetPoint("TOPLEFT", 0, -HEADER)
    page:SetPoint("BOTTOMRIGHT")
    local ask = ns.Text(page, 12, "dim")
    ask:SetPoint("TOPLEFT", PAD, -PAD)
    ask:SetText("What should the macro do?")
    for i, r in ipairs(W.recipes) do
        local b = ns.Button(page, "", WIDTH - 2 * PAD, function() Panel.ShowRecipe(r) end)
        b:SetHeight(54)
        b:SetPoint("TOPLEFT", PAD, -PAD - 22 - (i - 1) * 58)
        b.title = ns.Text(b, 13)
        b.title:SetPoint("TOPLEFT", 10, -8)
        b.title:SetText(r.title)
        b.text = ns.Text(b, 11, "dim")
        b.text:SetPoint("TOPLEFT", b.title, "BOTTOMLEFT", 0, -4)
        b.text:SetPoint("RIGHT", -10, 0)
        b.text:SetJustifyV("TOP")
        b.text:SetText(r.text)
    end
    return page
end

function Panel.ShowList()
    recipe, held = nil, nil
    for _, form in pairs(forms) do form:Hide() end
    listPage:Show()
    backBtn:Hide()
    titleText:SetPoint("LEFT", 12, 0)
    titleText:SetText("Macro wizard")
    UpdateFooter()
end

-- Fresh answers each time: the defaults, and a trinket checked when it has a use effect.
function Panel.ShowRecipe(r)
    recipe, choices, held = r, W.Defaults(r), nil
    forms[r.key] = forms[r.key] or Form(r)
    local form = forms[r.key]
    for _, f in ipairs(r.fields) do
        local control = f.key and form.controls[f.key]
        if f.kind == "action" then
            control:SetText("")
        elseif f.slot then
            local name, usable = ns.sources.equipped(f.slot)
            choices[f.key] = usable
            control:SetLabel(string.format("%s: %s", f.label, name or "empty"))
        end
        if control and control.Refresh then control:Refresh() end
    end
    listPage:Hide()
    for _, other in pairs(forms) do other:SetShown(other == form) end
    backBtn:Show()
    titleText:SetPoint("LEFT", backBtn, "RIGHT", 8, 0)
    titleText:SetText(r.title)
    Changed()
end

------------------------------------------------------------------------
-- The panel
------------------------------------------------------------------------
local function Create(editor)
    frame = CreateFrame("Frame", "MacroSenseWizard", editor, "BackdropTemplate")
    frame:SetWidth(WIDTH)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    ns.Backdrop(frame, "bg", "border")
    frame:Hide()

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(HEADER)
    ns.Backdrop(header, "panel", "panel")
    backBtn = ns.Button(header, "<", 24, function() Panel.ShowList() end)
    backBtn:SetPoint("LEFT", 6, 0)
    Tip(backBtn, "Back", "To the macros the wizard makes. The editor keeps what is there.")
    titleText = ns.Text(header, 14)
    local close = ns.Button(header, "x", 24, function() Panel.Close() end)
    close:SetPoint("RIGHT", -6, 0)

    listPage = RecipeList()
    footer = ns.Text(frame, 11, "dim")
    replaceBtn = ns.Button(frame, "Replace", 80, function()
        if held then ns.Window.WizardWrite(held.text, held.name, true) end
        held = nil
        UpdateFooter()
    end)
    replaceBtn:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    Tip(replaceBtn, "Replace", "Put the wizard's macro in the editor instead of what is there now.")
end

-- Next to `editor` (the MacroSense window): on its left, or on its right when the screen has no room there.
function Panel.Open(editor)
    if not frame then Create(editor) end
    frame:ClearAllPoints()
    local left = editor:GetLeft()
    if left and left < WIDTH + 4 then
        frame:SetPoint("TOPLEFT", editor, "TOPRIGHT", 4, 0)
        frame:SetPoint("BOTTOMLEFT", editor, "BOTTOMRIGHT", 4, 0)
    else
        frame:SetPoint("TOPRIGHT", editor, "TOPLEFT", -4, 0)
        frame:SetPoint("BOTTOMRIGHT", editor, "BOTTOMLEFT", -4, 0)
    end
    Panel.ShowList()
    frame:Show()
end

function Panel.Close()
    recipe, held = nil, nil
    if frame then frame:Hide() end
end

function Panel.IsShown() return frame ~= nil and frame:IsShown() end

-- The control of a question on the page open now (the tests answer through it).
function Panel.Control(key) return recipe and forms[recipe.key].controls[key] end
