-- Shift + right-click on a macro on an action bar opens it in the editor instead of running it, and the
-- button's tooltip says so; on a Mac it also warns when Cmd with the macro's key is a macOS shortcut, as the
-- editor's status bar does, and such a button turns red. A macro with a spell you don't have now (a talent not
-- chosen, another specialization's spell) turns yellow, and its tooltip says which. On the game's own buttons and
-- those made from them (Dominos), and on the buttons of LibActionButton (Bartender, ElvUI). The click is caught in
-- the game's secure code, so the buttons work in combat as before and every other click goes on as it did.
local _, ns = ...
ns = ns or {}

local ActionBars = {}
ns.ActionBars = ActionBars

ActionBars.TIP = "Shift + right-click: edit in MacroSense"
-- The libraries Bartender and ElvUI make their buttons with.
local LIBRARIES = { "LibActionButton-1.0", "LibActionButton-1.0-ElvUI" }

local GetActionText = C_ActionBar and C_ActionBar.GetActionText or GetActionText

-- The index of the macro on action slot `slot`, or nil. For a macro that shows a spell the game gives the
-- spell's ID, not the macro's, so the macro is found by its name, which the button shows (of two macros with
-- one name, the first, as a MACRO binding runs it).
function ActionBars.MacroAt(slot)
    if GetActionInfo(slot) ~= "macro" then return nil end
    local index = GetMacroIndexByName(GetActionText(slot) or "")
    return index and index > 0 and index or nil
end

------------------------------------------------------------------------
-- Where macros are on the action bars. The game shows the bars of this character's specialization now; those of
-- its other specializations (each has bars of its own) and of your other characters (general macros are theirs
-- too) are kept as last seen: ns.Character().bars = { [specialization] = { label, names = { [macro] = buttons } } }.
------------------------------------------------------------------------
local MAX_SLOT = 180
local nowCache -- the macros on the bars now, until they change (ActionBars.Tint)
local ready -- after login: this character is known

-- The macros on the bars now: name -> buttons; and whether the bars have anything on them at all.
local function OnBarsNow()
    if not nowCache then
        local names, any = {}, false
        for slot = 1, MAX_SLOT do
            local kind = GetActionInfo(slot)
            any = any or kind ~= nil
            local name = kind == "macro" and GetActionText(slot)
            if name then names[name] = (names[name] or 0) + 1 end
        end
        nowCache = { names = names, any = any }
    end
    return nowCache.names, nowCache.any
end

-- The specialization the bars are of now: a key and its name. Retail and WoW Forever keep bars for each
-- specialization, the Classic clients for each talent group (dual specialization).
local function Spec()
    local S = C_SpecializationInfo or {}
    local group = S.GetActiveSpecGroup and S.GetActiveSpecGroup() or 1
    local index = S.GetSpecialization and S.GetSpecialization()
    local id, name
    if index and index > 0 and S.GetSpecializationInfo then id, name = S.GetSpecializationInfo(index) end
    local key = C_ClassTalents and id and id ~= 0 and ("spec" .. id) or ("group" .. group)
    return key, name or string.format(ns.L["Specialization %d"], group)
end

-- What is on the bars now, kept for this character's specialization. Bars with nothing at all on them are not
-- kept: the game may not have shown them yet.
function ActionBars.Remember()
    local names, any = OnBarsNow()
    if not ready or not any then return end
    local key, label = Spec()
    local c = ns.Character()
    c.bars = c.bars or {}
    c.bars[key] = { label = label, names = names }
end

-- Where macro `name` of tab `scope` is on action bars: the buttons of the bars now, and where else it was when last
-- seen: your other specializations and, for a general macro, other characters (their names), each once.
function ActionBars.Uses(scope, name)
    local here = OnBarsNow()[name] or 0
    if not ready then return here, {} end
    local mine, spec = ns.Character(), Spec()
    local places, seen = {}, {}
    local function add(place)
        if not seen[place] then places[#places + 1], seen[place] = place, true end
    end
    for _, c in pairs(ns.db.characters or {}) do
        for key, bars in pairs(c.bars or {}) do
            if bars.names[name] and c == mine and key ~= spec then add(bars.label) end
            if bars.names[name] and c ~= mine and scope == "general" then
                add(c.realm == mine.realm and c.name or (c.name .. "-" .. c.realm))
            end
        end
    end
    table.sort(places)
    return here, places
end

-- The action slots of the bars now with macro `name` on them.
function ActionBars.SlotsOf(name)
    local out = {}
    for slot = 1, MAX_SLOT do
        if GetActionInfo(slot) == "macro" and GetActionText(slot) == name then out[#out + 1] = slot end
    end
    return out
end

-- Macro `index` on each of `slots` (out of combat).
function ActionBars.Place(index, slots)
    for _, slot in ipairs(slots) do
        PickupMacro(index)
        PlaceAction(slot)
        ClearCursor()
    end
end

-- Runs in the game's secure code before each click on a button (self: the button, control: our frame below).
-- Shift + right-click on an action with a macro goes no further, and the macro opens when the mouse button is
-- let go (a drag doesn't open it). The slot is found as the button finds it
-- (SecureActionButtonMixin:CalculateAction): from its ID and the bar's page, or its "action" attribute.
local PRE_CLICK = [[
    if button ~= "RightButton" or not IsShiftKeyDown() then return end
    if self:GetEffectiveAttribute("type", button) ~= "action" then return end
    local slot = self:GetID()
    if slot > 0 then
        slot = slot + ((self:GetEffectiveAttribute("actionpage", button) or GetActionBarPage()) - 1) * 12
    else
        slot = self:GetEffectiveAttribute("action", button)
    end
    if not slot or GetActionInfo(slot) ~= "macro" then return end
    if not down then control:CallMethod("Edit", slot) end
    return false
]]

local header -- the secure frame PRE_CLICK belongs to; it opens the editor
local wrapped = {} -- button -> true when its clicks go through PRE_CLICK, false when they don't

local function Wrap(button)
    if wrapped[button] ~= nil or InCombatLockdown() then return end -- after combat then
    -- The extra action button and the totem bar find their slots on bars of their own, with no macros.
    if button.isExtra or button.buttonType == "MULTICASTACTIONBUTTON" then
        wrapped[button] = false
        return
    end
    if not header then
        header = CreateFrame("Frame", nil, nil, "SecureHandlerBaseTemplate")
        function header:Edit(slot)
            local index = ActionBars.MacroAt(slot)
            if index then ns.Window.Open(index) end
        end
    end
    local before = button:GetScript("OnClick")
    pcall(SecureHandlerWrapScript, button, "OnClick", header, PRE_CLICK)
    wrapped[button] = button:GetScript("OnClick") ~= before
end

-- On a Mac, a red tint over a game button whose own key, with Cmd, is a macOS shortcut its macro uses (Cmd+Q
-- quits the game). The key is a binding of the game's bars, so buttons of other addons' bars get none. A yellow
-- one over a macro with a spell you don't have now, on any button.
-- tints: button -> its tint; tinted: the buttons that follow their action (true; "lab": LibActionButton's).
local tints, tinted = {}, {}
local RED, YELLOW = { 1, 0, 0, 0.4 }, { 1, 0.82, 0, 0.4 }

local function Danger(button)
    local slot = button.action
    local index = type(slot) == "number" and ns.Shortcuts.Enabled() and ActionBars.MacroAt(slot)
    local command = index and ns.Shortcuts.slotCommand(slot)
    if not command then return false end
    local _, _, body = GetMacroInfo(index)
    return #ns.Shortcuts.Conflicts(body or "", { GetBindingKey(command) }) > 0
end

-- What the macro on action slot `slot` says, as saved, about spells the game can't cast now (the editor's
-- warnings), or nil. Kept by text until the next ActionBars.Tint.
local missingCache = {}
local function MissingIn(body)
    body = body or ""
    local found = missingCache[body]
    if not found then
        found = {}
        for _, e in ipairs(ns.Highlight.Errors(body)) do
            if e.missing then found[#found + 1] = e.message end
        end
        missingCache[body] = found
    end
    return #found > 0 and found or nil
end
local function Missing(slot)
    local index = type(slot) == "number" and ActionBars.MacroAt(slot)
    return index and MissingIn(select(3, GetMacroInfo(index))) or nil
end

local function Tint(button)
    local color = tinted[button] ~= "lab" and Danger(button) and RED or Missing(button.action) and YELLOW or nil
    local tint = tints[button]
    if color and not tint then
        tint = button:CreateTexture(nil, "BACKGROUND", nil, 1) -- over the icon, under its border
        tint:SetAllPoints(button.icon)
        if button.IconMask then tint:AddMaskTexture(button.IconMask) end -- the icon's round corners
        tints[button] = tint
    end
    if tint then
        if color then tint:SetColorTexture(color[1], color[2], color[3], color[4]) end
        tint:SetShown(color ~= nil)
    end
end

-- The game calls Update when the button's action changes: a new one on it, a page, a stance.
local function Follow(button)
    if tinted[button] or not button.Update then return end
    tinted[button] = true
    hooksecurefunc(button, "Update", Tint)
    Tint(button)
end

-- LibActionButton tells when its button's action changes; such a button gets the yellow tint only.
local function FollowLab(button)
    tinted[button] = tinted[button] or "lab"
    Tint(button)
end

-- Bindings, macros, action bars, spells or talents changed: every button again, and what is on the bars is kept a
-- moment later (the game changes many slots at once, a specialization all of them).
local rememberDue
function ActionBars.Tint()
    missingCache, nowCache = {}, nil
    for button in pairs(tinted) do Tint(button) end
    if rememberDue then return end
    rememberDue = true
    C_Timer.After(1, function()
        rememberDue = false
        ActionBars.Remember()
        ns.Window.BarsChanged()
    end)
end

local broken -- the macros on the bars that use spells you don't have now: name -> true; nil before the first look
local loadedAt = GetTime() -- the session's start

-- Your talents or specialization changed: the macros on the bars now that use spells you don't have, and didn't
-- before, are told on the screen and in chat. Before, and in the first seconds of a session (the game tells of
-- talents then too, before it knows them all), they are only learned.
function ActionBars.TellBroken(talents)
    local now, new = {}, {}
    for name in pairs((OnBarsNow())) do
        local index = GetMacroIndexByName(name)
        if index and index > 0 and MissingIn(select(3, GetMacroInfo(index))) then
            now[name] = true
            if broken and not broken[name] then new[#new + 1] = name end
        end
    end
    local tell = talents and GetTime() - loadedAt > 10
    broken = now
    if not tell or #new == 0 then return end
    table.sort(new)
    UIErrorsFrame:AddMessage(ns.Plural(#new, "MacroSense: %d macro on your bars uses a spell you don't have now",
        "MacroSense: %d macros on your bars use spells you don't have now"), 1, 0.82, 0, 1)
    ns.Print("on your bars, with spells you don't have now: %s", table.concat(new, ", "))
end

-- A button just made may still be setting itself up: it is taken a frame later.
local function Later(button, game)
    C_Timer.After(0, function()
        Wrap(button)
        if game then Follow(button) else FollowLab(button) end
    end)
end

-- On a Mac: what the editor's status bar says when Cmd with the macro's keys is a macOS shortcut (Cmd+Q quits
-- the game), or nil.
local function MacWarning(slot)
    local index = ns.Shortcuts.Enabled() and ActionBars.MacroAt(slot)
    if not index then return nil end
    local name, _, body = GetMacroInfo(index)
    return ns.Shortcuts.Message(ns.Shortcuts.Conflicts(body or "", ns.Shortcuts.KeysFor(index, name)))
end

-- A macro's tooltip: the macOS warning and the spells it can't cast now, on any button, then how to edit it,
-- where the click is ours. A blank line first sets them apart from the game's own lines.
local function AddTip(tooltip, slot)
    if GetActionInfo(slot) ~= "macro" then return end
    local warning, missing, ours = MacWarning(slot), Missing(slot), wrapped[tooltip:GetOwner()]
    if not (warning or missing or ours) then return end
    tooltip:AddLine(" ")
    if warning then tooltip:AddLine(warning, 1, 0.35, 0.35, true) end -- red, as errors in the editor's tooltips
    for _, message in ipairs(missing or {}) do tooltip:AddLine(message, 1, 0.82, 0, true) end -- yellow: warnings
    if ours then tooltip:AddLine(ns.L[ActionBars.TIP], 0.34, 0.61, 0.84) end
    tooltip:Show()
end

local hooked, watched = false, {} -- watched: the LibActionButton libraries told of new buttons

-- On login and after combat (buttons made during it); buttons made later are wrapped as they come.
function ActionBars.Setup()
    ready = true
    if not SecureHandlerWrapScript then return end
    local blizzard = ActionBarButtonEventsFrame -- every button of the game's template registers with it
    if not hooked then
        hooked = true
        hooksecurefunc(GameTooltip, "SetAction", AddTip)
        if blizzard then hooksecurefunc(blizzard, "RegisterFrame", function(_, button) Later(button, true) end) end
    end
    if blizzard and blizzard.frames then
        for _, button in pairs(blizzard.frames) do
            Wrap(button)
            Follow(button)
        end
    end
    for _, name in ipairs(LIBRARIES) do
        local lib = LibStub and LibStub(name, true)
        if lib and lib.RegisterCallback and not watched[lib] then
            watched[lib] = true
            lib.RegisterCallback(ActionBars, "OnButtonCreated", function(_, button) Later(button) end)
            lib.RegisterCallback(ActionBars, "OnButtonUpdate", function(_, button) FollowLab(button) end)
        end
        for button in pairs(lib and lib.buttonRegistry or {}) do
            Wrap(button)
            FollowLab(button)
        end
    end
end

return ActionBars
