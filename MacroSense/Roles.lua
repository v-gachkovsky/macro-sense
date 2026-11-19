-- Your group's tank and healer: @tank and @heal in a macro. The game doesn't know them, so the macro it keeps has the
-- name of the one with the role ("/cast [@Bob,help,nodead] Misdirection"), and MacroSense keeps the text with the
-- tags: the editor shows and saves that, and when your group changes MacroSense writes the game's macro again for
-- the names then, out of combat, and says a new name on the screen. A macro changed outside MacroSense since is let
-- go; other names in the places of the tags are no change. Needs the game.
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

-- Whether `body` is `text` with a name in the place of each @tank and @heal ("Bob", "Ann-Realm", or "none"): the
-- game's macro as MacroSense wrote it for some group, now or before. The game may keep a write that MacroSense's
-- saved data missed (the game closed before it saved them). A unit there ("target") is no name: a change.
local function Filled(text, body)
    local from, at = 1, 1
    for start, lead, tag, after in text:gmatch("()([@=])(%l+)()") do
        if ns.Conditions.TAGS[tag] then
            local same = text:sub(from, start - 1) .. lead
            if body:sub(at, at + #same - 1) ~= same then return false end
            at = at + #same
            local name = body:match("^none", at) or body:match("^[%u\128-\255][^%s,;%[%]]*", at)
            if not name then return false end
            at, from = at + #name, after
        end
    end
    return body:sub(at) == text:sub(from)
end

-- What MacroSense shows of macro `name` in tab `scope`, saved as `body`: its text with the tags, while the game's
-- macro is as MacroSense wrote it.
function Roles.Text(scope, name, body)
    local kept = Store(scope)[name]
    return kept and (kept.written == body or Filled(kept.text, body)) and kept.text or body
end

-- MacroSense saved macro `name` (`old` before, when renamed) as `text`, the game's as `written`: kept up to date
-- while it has a tag, else let go. The game tells the macro changed while EditMacro and CreateMacro run, so this
-- comes before them, and again after with the text the game has. Returns what puts back the entries as they were,
-- for a macro the game didn't take.
function Roles.Saved(scope, old, name, text, written)
    local store = Store(scope)
    local was, wasOld = store[name], old and store[old]
    if old then store[old] = nil end
    store[name] = text ~= written and { text = text, written = written } or nil
    return function()
        store[name] = was
        if old then store[old] = wasOld end
    end
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

-- The macro of `entry` in its tab: the one with its name and its text as MacroSense wrote it (Filled), or, renamed
-- since, one with the text it was given that no other entry names. Nil once it was deleted or changed.
local function Find(scope, name, entry, store)
    local first, last = Range(scope)
    local renamed
    for index = first, last do
        local n, _, body = GetMacroInfo(index)
        if n == name and (body == entry.written or Filled(entry.text, body or "")) then return index, n end
        if n ~= name and body == entry.written and not store[n] then renamed = index end
    end
    if renamed then return renamed, (GetMacroInfo(renamed)) end
end

-- The macros changed (UPDATE_MACROS): one renamed elsewhere (the game's macro window, another addon) is followed at
-- once, as Roles.Update follows it, so what MacroSense shows of it keeps the tags until the group changes. Nothing
-- is written, nothing let go.
function Roles.Follow()
    for _, scope in ipairs({ "general", "character" }) do
        local store = Store(scope)
        local first, last = Range(scope)
        local have = {}
        for index = first, last do
            local name = GetMacroInfo(index)
            if name then have[name] = true end
        end
        local gone = {}
        for name in pairs(store) do
            if not have[name] then gone[#gone + 1] = name end
        end
        table.sort(gone)
        for _, name in ipairs(gone) do
            local index, now = Find(scope, name, store[name], store)
            if index then store[now], store[name] = store[name], nil end
        end
    end
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
            local index, now = Find(scope, name, entry, store)
            store[name] = nil
            if index then
                store[now] = entry
                entry.written = select(3, GetMacroInfo(index)) -- as the game has it: maybe the names of another time
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
