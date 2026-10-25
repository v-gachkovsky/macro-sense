-- Shift + right-click on a macro on an action bar opens it in the editor instead of running it, and the
-- button's tooltip says so; on a Mac it also warns when Cmd with the macro's key is a macOS shortcut, as the
-- editor's status bar does, and such a button turns red. On the game's own buttons and those made from them
-- (Dominos), and on the buttons of LibActionButton (Bartender, ElvUI). The click is caught in the game's
-- secure code, so the buttons work in combat as before and every other click goes on as it did.
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
-- quits the game). The key is a binding of the game's bars, so buttons of other addons' bars get none.
local tints, tinted = {}, {} -- button -> its tint; the buttons that follow their action

local function Danger(button)
    local slot = button.action
    local index = type(slot) == "number" and ns.Shortcuts.Enabled() and ActionBars.MacroAt(slot)
    local command = index and ns.Shortcuts.slotCommand(slot)
    if not command then return false end
    local _, _, body = GetMacroInfo(index)
    return #ns.Shortcuts.Conflicts(body or "", { GetBindingKey(command) }) > 0
end

local function Tint(button)
    local danger, tint = Danger(button), tints[button]
    if danger and not tint then
        tint = button:CreateTexture(nil, "BACKGROUND", nil, 1) -- over the icon, under its border
        tint:SetAllPoints(button.icon)
        tint:SetColorTexture(1, 0, 0, 0.4)
        if button.IconMask then tint:AddMaskTexture(button.IconMask) end -- the icon's round corners
        tints[button] = tint
    end
    if tint then tint:SetShown(danger) end
end

-- The game calls Update when the button's action changes: a new one on it, a page, a stance.
local function Follow(button)
    if tinted[button] or not button.Update then return end
    tinted[button] = true
    hooksecurefunc(button, "Update", Tint)
    Tint(button)
end

-- Bindings or macros changed: every button again.
function ActionBars.Tint()
    for button in pairs(tinted) do Tint(button) end
end

-- A button just made may still be setting itself up: it is taken a frame later. Only the game's own get the
-- tint.
local function Later(button, game)
    C_Timer.After(0, function()
        Wrap(button)
        if game then Follow(button) end
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

-- A macro's tooltip: the macOS warning, on any button, then how to edit it, where the click is ours.
local function AddTip(tooltip, slot)
    if GetActionInfo(slot) ~= "macro" then return end
    local warning, ours = MacWarning(slot), wrapped[tooltip:GetOwner()]
    if warning then tooltip:AddLine(warning, 1, 0.35, 0.35, true) end -- red, as errors in the editor's tooltips
    if ours then tooltip:AddLine(ns.L[ActionBars.TIP], 0.34, 0.61, 0.84) end
    if warning or ours then tooltip:Show() end
end

local hooked, watched = false, {} -- watched: the LibActionButton libraries told of new buttons

-- On login and after combat (buttons made during it); buttons made later are wrapped as they come.
function ActionBars.Setup()
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
        end
        for button in pairs(lib and lib.buttonRegistry or {}) do Wrap(button) end
    end
end

return ActionBars
