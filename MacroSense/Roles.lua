-- Your group's tank and healer: @tank and @heal in a macro. The game doesn't know them, so the macro it keeps has the
-- name of the one with the role ("/cast [@Bob,help,nodead] Misdirection"), and MacroSense keeps the text with the
-- tags: the editor shows and saves that, and when your group changes MacroSense writes the game's macro again for
-- the names then, out of combat, and says a new name on the screen. A macro changed outside MacroSense since is let
-- go. Needs the game.
local _, ns = ...
local L = ns.L

local Roles = {}
ns.Roles = Roles

local MAX_BODY = MAX_MACRO_CHARACTERS or 255
local MAX_GENERAL = ns.MAX_GENERAL

local function Letters(s) return select(2, s:gsub("[^\128-\191]", "")) end

local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end

-- "Bob", or "Bob-Realm" for one from another realm: the name a macro takes. Nil while the game doesn't know it yet
-- ("Unknown") or hides it from addons.
local function FullName(unit)
    local name, realm = UnitName(unit)
    if not name or Secret(name) or name == UNKNOWNOBJECT then return nil end
    return (realm and realm ~= "") and (name .. "-" .. realm) or name
end

-- The units of your group other than you, in its order: party1..4, or raid1..40.
local function Others()
    local raid = IsInRaid()
    local out = {}
    for i = 1, raid and GetNumGroupMembers() or GetNumSubgroupMembers() do
        local unit = (raid and "raid" or "party") .. i
        if not UnitIsUnit(unit, "player") then out[#out + 1] = unit end
    end
    return out
end

-- Your group's tank and healer now, other than you: { tank = "Bob", heal = "Ann-Realm" }, the first of each in the
-- group's order; a raid's main tank comes first.
function Roles.Names()
    local out, main = {}, nil
    for _, unit in ipairs(Others()) do
        local role = UnitGroupRolesAssigned(unit)
        local key = not Secret(role) and (role == "TANK" and "tank" or role == "HEALER" and "heal")
        if key and not out[key] then out[key] = FullName(unit) end
        if not main and GetPartyAssignment("MAINTANK", unit) then main = FullName(unit) end
    end
    out.tank = main or out.tank
    return out
end

-- The editor takes the names in your group for units: "@Bob" is no unknown unit while Bob is in it (with the realm
-- or without).
function ns.Highlight.isMember(name)
    name = name:lower()
    for _, unit in ipairs(Others()) do
        local full = (FullName(unit) or ""):lower()
        if full == name or full:match("^[^-]+") == name then return true end
    end
    return false
end

------------------------------------------------------------------------
-- The macros kept up to date
------------------------------------------------------------------------
-- The macros with @tank or @heal, by name: { text = with the tags, written = the text the game's macro was given
-- last }. General macros are the account's, character macros this character's.
local function Store(scope)
    local db = scope == "character" and ns.char or ns.db
    db.roleMacros = db.roleMacros or {}
    return db.roleMacros
end

-- `text` as the game takes it: the names of your group now for @tank and @heal.
function Roles.Fill(text) return ns.Conditions.Fill(text, Roles.Names()) end

-- What MacroSense shows of macro `name` in tab `scope`, saved as `body`: its text with the tags, while the game's
-- macro is as MacroSense wrote it.
function Roles.Text(scope, name, body)
    local kept = Store(scope)[name]
    return kept and kept.written == body and kept.text or body
end

-- MacroSense saved macro `name` (`old` before, when renamed) as `text`, the game's as `written`: kept up to date
-- while it has a tag, else let go.
function Roles.Saved(scope, old, name, text, written)
    local store = Store(scope)
    if old then store[old] = nil end
    store[name] = text ~= written and { text = text, written = written } or nil
end

-- This editor moves a macro into the other tab: it is kept up to date there.
function Roles.Moved(from, to, old, new)
    local source = Store(from)
    if source[old] then Store(to)[new], source[old] = source[old], nil end
end

local function Range(scope)
    local general, character = GetNumMacros()
    if scope == "general" then return 1, general end
    return MAX_GENERAL + 1, MAX_GENERAL + character
end

-- The macro of an entry in its tab: the one with its name and the text it was given, or, renamed since, one with
-- that text no other entry names. Nil once it was deleted or changed.
local function Find(scope, name, written, store)
    local first, last = Range(scope)
    local renamed
    for index = first, last do
        local n, _, body = GetMacroInfo(index)
        if body == written then
            if n == name then return index, n end
            if not store[n] then renamed = index end
        end
    end
    if renamed then return renamed, (GetMacroInfo(renamed)) end
end

local told = {} -- the texts too long to write, said once
local shown -- the names last told on the screen: { tank = "Bob" }; nil before the first look of a session

-- The texts told, in the language MacroSense is in now.
local function Put(tag)
    if tag == "tank" then return L["MacroSense: your group's new tank is %s"] end
    return L["MacroSense: your group's new healer is %s"]
end
local function Failed(tag)
    if tag == "tank" then
        return L["MacroSense: could not set your group's new tank, %s: the macro would be too long"]
    end
    return L["MacroSense: could not set your group's new healer, %s: the macro would be too long"]
end

-- A tank or healer new since the last look is told in red mid-screen, as the game's errors are: put into the
-- macros with its tag, or not, one of them too long then. The first look of a session only learns them.
local function Notice(names, put, failed)
    if shown then
        for _, tag in ipairs({ "tank", "heal" }) do
            if names[tag] and names[tag] ~= shown[tag] then
                if put[tag] then UIErrorsFrame:AddMessage(Put(tag):format(names[tag]), 1, 0.1, 0.1, 1) end
                if failed[tag] then UIErrorsFrame:AddMessage(Failed(tag):format(names[tag]), 1, 0.1, 0.1, 1) end
            end
        end
    end
    shown = names
end

-- Each macro still as MacroSense wrote it gets the names of your group now; one changed or deleted since is let go,
-- one renamed is followed. A text the new names make too long stays as it was. Not in combat, when macros can't be
-- changed: after it.
function Roles.Update()
    if InCombatLockdown() then return end
    local names, put, failed = Roles.Names(), {}, {}
    for _, scope in ipairs({ "general", "character" }) do
        local store = Store(scope)
        local list = {}
        for name in pairs(store) do list[#list + 1] = name end
        table.sort(list)
        for _, name in ipairs(list) do
            local entry = store[name]
            local index, now = Find(scope, name, entry.written, store)
            store[name] = nil
            if index then
                store[now] = entry
                local text = ns.Conditions.Fill(entry.text, names)
                if Letters(text) > MAX_BODY then
                    for tag in pairs(ns.Conditions.Tags(entry.text)) do failed[tag] = true end
                    if not told[text] then
                        told[text] = true
                        ns.Print("could not put your group's new names into \"%s\": it would be longer than %d "
                            .. "characters", now, MAX_BODY)
                    end
                elseif text ~= entry.written then
                    -- The game tells the macro changed while EditMacro runs: by then it must be known as written
                    -- here, or the editor would show the names (@none) as a change of its own, and the history keep
                    -- a version.
                    entry.written = text
                    ns.History.Rewritten(scope, now, text)
                    EditMacro(index, nil, nil, text) -- as the game's macro window does: the name and icon stay
                    entry.written = select(3, GetMacroInfo(index))
                    ns.History.Rewritten(scope, now, entry.written)
                end
                if entry.written == text then
                    for tag in pairs(ns.Conditions.Tags(entry.text)) do put[tag] = true end
                end
            end
        end
    end
    Notice(names, put, failed)
end

-- The group or its roles changed, or combat ended: a second later (the game tells it several times at once), the
-- macros follow.
local soon
local function Soon()
    if soon then return end
    soon = true
    C_Timer.After(1, function()
        soon = false
        Roles.Update()
    end)
end

local f = CreateFrame("Frame")
for _, event in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED" }) do
    pcall(f.RegisterEvent, f, event)
end
f:SetScript("OnEvent", Soon)

return Roles
