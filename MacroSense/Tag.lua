-- The tag macro: one macro of yours, picked in its "..." menu. A creature or player clicked with Ctrl + Alt held (the
-- keys picked in the settings, Options.lua) goes into it by name: "/targetexact Hogger". Pressed, the macro targets
-- that one: a rare or a quest mob in a crowd, to hit it first, or a player in PvP. Clicked on yourself, the name
-- goes. Not in combat, when macros can't be changed: once it ends.
local _, ns = ...
ns = ns or {}
local L = ns.L

local Tag = {}
ns.Tag = Tag

local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local function Letters(s) return select(2, s:gsub("[^\128-\191]", "")) end

-- This character's tag macro: { scope, name }, or nil.
function Tag.Get() return ns.char and ns.char.tag end

function Tag.Is(scope, name)
    local tag = Tag.Get()
    return tag ~= nil and tag.scope == scope and tag.name == name
end

-- The macro renamed or moved into the other tab (History's notes follow it the same way); `to` nil: deleted.
function Tag.Moved(from, old, to, new)
    if Tag.Is(from, old) then ns.char.tag = to and { scope = to, name = new } or nil end
end

-- "Ctrl + Alt + click on a creature or player": how a name goes in, as the list's tooltip tells it.
function Tag.Hint()
    return string.format(L["Tag macro: %s + click on a creature or player puts its name in"],
        ns.ActionBars.KeysText(ns.db.tagKeys))
end

-- Its item in a macro's "..." menu: picked as the tag macro, or no longer.
function Tag.Item(scope, name)
    if Tag.Is(scope, name) then
        return { name = L["Not the tag macro"], onClick = function() ns.char.tag = nil end }
    end
    return { name = L["Make it the tag macro"], onClick = function()
        ns.char.tag = { scope = scope, name = name }
        ns.Print("tag macro \"%s\": hold %s and click a creature or player to put its name in", name,
            ns.ActionBars.KeysText(ns.db.tagKeys))
    end }
end

-- The commands a line targets by name with, by their keys (Sources: ns.CommandKey).
local TARGETS = { TARGET = true, TARGET_EXACT = true }

-- `body` with `name` in its line that targets by name (/targetexact or /target with no conditions): in place of the
-- one there, else in a new /targetexact line after #showtooltip. Nil `name`: that line goes.
function Tag.Body(body, name)
    local lines = {}
    if body ~= "" then
        for line in (body .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
    end
    local at
    for i, line in ipairs(lines) do
        local command, rest = line:match("^%s*/(%S+)%s*(.-)%s*$")
        if not at and command and TARGETS[ns.CommandKey(command:lower()) or ""] and rest ~= ""
            and not rest:find("^%[") then
            at = i
        end
    end
    if at and name then
        lines[at] = lines[at]:match("^%s*/%S+") .. " " .. name
    elseif at then
        table.remove(lines, at)
    elseif name then
        local i = 1
        while lines[i] and lines[i]:find("^%s*#") do i = i + 1 end
        -- /targetexact takes the whole name, not the first that starts with it; a game without it has /target.
        table.insert(lines, i, (SLASH_TARGET_EXACT1 or SLASH_TARGET1 or "/target") .. " " .. name)
    end
    return table.concat(lines, "\n")
end

-- The index of macro `name` in tab `scope`, or nil.
local function Find(scope, name)
    local general, character = GetNumMacros()
    local first, last = 1, general
    if scope == "character" then first, last = ns.MAX_GENERAL + 1, ns.MAX_GENERAL + character end
    for index = first, last do
        if GetMacroInfo(index) == name then return index end
    end
end

-- `name` into the tag macro (nil: out of it), as MacroSense writes a macro by itself: the history keeps no version
-- of it, @tank and @heal stay (Roles.lua).
local function Write(name)
    local tag = Tag.Get()
    if not tag then return end
    local index = Find(tag.scope, tag.name)
    if not index then
        ns.char.tag = nil
        return ns.Print("the tag macro \"%s\" is gone: pick another one in a macro's \"...\" menu", tag.name)
    end
    local written = select(3, GetMacroInfo(index)) or ""
    local shown = ns.Roles.Text(tag.scope, tag.name, written)
    local text = Tag.Body(shown, name)
    if text ~= shown then
        local game = ns.Roles.Fill(text)
        if Letters(game) > MAX_BODY then
            return ns.Print("tag macro \"%s\": %s doesn't fit, the macro would be longer than %d characters",
                tag.name, name, MAX_BODY)
        end
        ns.History.Rewritten(tag.scope, tag.name, game)
        EditMacro(index, nil, nil, game) -- as the game's macro window does: the name and icon stay
        local now = select(3, GetMacroInfo(index))
        ns.History.Rewritten(tag.scope, tag.name, now)
        ns.Roles.Saved(tag.scope, nil, tag.name, text, now)
    end
    if name then
        ns.Print("tag macro \"%s\": %s", tag.name, name)
    else
        ns.Print("tag macro \"%s\": no name", tag.name)
    end
end

local pending -- a name (false: none) for the tag macro once combat ends; nil: nothing waits

-- `name` into the tag macro, now or once combat ends (nil: out of it).
function Tag.Take(name)
    local tag = Tag.Get()
    if not tag then return end
    if not InCombatLockdown() then return Write(name) end
    pending = name or false
    if name then
        ns.Print("tag macro \"%s\": %s, once combat ends", tag.name, name)
    else
        ns.Print("tag macro \"%s\": no name, once combat ends", tag.name)
    end
end

-- Whether exactly the keys `keys` are held ("ctrl-alt": Ctrl and Alt, not Shift).
local function Held(keys)
    return not IsShiftKeyDown() == not keys:find("shift") and not IsControlKeyDown() == not keys:find("ctrl")
        and not IsAltKeyDown() == not keys:find("alt")
end

-- The name of the unit under the mouse ("Bob-Silvermoon" from another realm), or nil: none, or Retail keeps it from
-- addons now.
local function MouseoverName()
    local name, realm = UnitName("mouseover")
    if issecretvalue and (issecretvalue(name) or issecretvalue(realm)) then return nil end
    if type(name) ~= "string" or name == "" then return nil end
    return realm and realm ~= "" and name .. "-" .. realm or name
end

-- A left click with the keys held on a creature or player, in the world, on its frame or its nameplate: its name in
-- the tag macro; on yourself, the name out. The unit under the mouse, not the target: a click on a unit frame takes
-- no target in Retail's clients with keys held (no click binding for them), your own portrait among them.
local events = CreateFrame("Frame")
pcall(events.RegisterEvent, events, "GLOBAL_MOUSE_UP")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, button)
    if event == "PLAYER_REGEN_ENABLED" then
        if pending == nil then return end
        local name = pending or nil
        pending = nil
        return Write(name)
    end
    if event ~= "GLOBAL_MOUSE_UP" or button ~= "LeftButton" then return end
    if not Tag.Get() or not ns.db or not Held(ns.db.tagKeys) or not UnitExists("mouseover") then return end
    if UnitIsUnit("mouseover", "player") then return Tag.Take(nil) end
    local name = MouseoverName()
    if name then Tag.Take(name) end
end)

return Tag
