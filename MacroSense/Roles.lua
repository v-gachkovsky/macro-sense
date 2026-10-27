-- Your group's tank and healer in the wizard's macros. A macro has the name of the one with the role ("/cast
-- [@Bob,help,nodead] Misdirection"), and the wizard's answers are kept with it: when your group changes, MacroSense
-- writes the macro again for the names then, out of combat. One changed since it was written stays as it is and is
-- let go. Needs the game.
local _, ns = ...

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

-- Your group's tank and healer now, other than you: { tank = "Bob", healer = "Ann-Realm" }, the first of each in
-- the group's order; a raid's main tank comes first.
function Roles.Names()
    local out, main = {}, nil
    for _, unit in ipairs(Others()) do
        local role = UnitGroupRolesAssigned(unit)
        local key = not Secret(role) and (role == "TANK" and "tank" or role == "HEALER" and "healer")
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
-- The wizard's macros that name the tank or the healer, by name: { spec = the wizard's answers, written = the text
-- MacroSense gave the macro last }. General macros are the account's, character macros this character's.
local function Store(scope)
    local db = scope == "character" and ns.char or ns.db
    db.roleMacros = db.roleMacros or {}
    return db.roleMacros
end

local function Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Copy(v) end
    return out
end

-- A macro the wizard just made in tab `scope`, as `written`: kept up to date from now on, if it names the tank or
-- the healer.
function Roles.Register(scope, name, spec, written)
    if not ns.Wizard.UsesRoles(spec) then return end
    local kept = Copy(spec)
    kept.roles = nil -- the names of now: those of the moment it is written go in
    Store(scope)[name] = { spec = kept, written = written }
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

-- Each macro still as MacroSense wrote it gets the names of your group now; one changed or deleted since is let go,
-- one renamed is followed. A text the new names make too long stays as it was. Not in combat, when macros can't be
-- changed: after it.
function Roles.Update()
    if InCombatLockdown() then return end
    local names = Roles.Names()
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
                entry.spec.roles = names
                local text = ns.Wizard.Text(entry.spec)
                entry.spec.roles = nil
                if Letters(text) > MAX_BODY then
                    if not told[text] then
                        told[text] = true
                        ns.Print("could not put your group's new names into \"%s\": it would be longer than %d "
                            .. "characters", now, MAX_BODY)
                    end
                elseif text ~= entry.written then
                    EditMacro(index, nil, nil, text) -- as the game's macro window does: the name and icon stay
                    entry.written = select(3, GetMacroInfo(index))
                    ns.History.Rewritten(scope, now, entry.written)
                end
            end
        end
    end
end

-- The group or its roles changed, or combat ended: a second later (the game tells it several times at once), the
-- wizard and the macros follow.
local soon
local function Soon()
    if soon then return end
    soon = true
    C_Timer.After(1, function()
        soon = false
        ns.WizardWindow.RolesChanged()
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
