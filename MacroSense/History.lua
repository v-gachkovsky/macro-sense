-- Earlier saved texts of each macro, to bring one back: the game keeps only the last one. A change saved
-- anywhere (this editor, the Blizzard window, another addon) keeps the text it replaced, and a macro deleted
-- anywhere goes into the trash. The lists are pure Lua (5.1); watching the macros needs the game.
local _, ns = ...
ns = ns or {}

local History = {}
ns.History = History

History.LIMIT = 10 -- versions kept per macro
History.TRASH = 30 -- deleted macros kept per tab

-- store: { [macro name] = { { body = text, time = seconds }, ... } }, oldest first.
-- Adds `body` as the newest version, unless it is the newest already or empty.
function History.Add(store, name, body, time)
    if not body:find("%S") then return end
    local list = store[name] or {}
    local last = list[#list]
    if last and last.body == body then return end
    list[#list + 1] = { body = body, time = time }
    while #list > History.LIMIT do table.remove(list, 1) end
    store[name] = list
end

-- Two lists of versions as one, in time order: the last LIMIT.
local function Merge(a, b)
    local list, i, j = {}, 1, 1
    while a[i] or b[j] do
        if not b[j] or (a[i] and a[i].time <= b[j].time) then
            list[#list + 1], i = a[i], i + 1
        else
            list[#list + 1], j = b[j], j + 1
        end
    end
    while #list > History.LIMIT do table.remove(list, 1) end
    return list
end

-- The macro got a new name: its versions go with it, in time order with any kept under that name before.
function History.Rename(store, old, new)
    if old == new or not store[old] then return end
    store[new], store[old] = Merge(store[new] or {}, store[old]), nil
end

-- trash: { { name, icon, body, time }, ... }, oldest first. A deleted macro goes in, the oldest go out.
function History.Discard(trash, name, macro, time)
    trash[#trash + 1] = { name = name, icon = macro.icon, body = macro.body, time = time }
    while #trash > History.TRASH do table.remove(trash, 1) end
end

-- Takes `entry` out of `trash`, brought back or deleted for good: that one, though another may have its name
-- and text. True when it was there.
function History.TakeOut(trash, entry)
    for i, e in ipairs(trash) do
        if e == entry then
            table.remove(trash, i)
            return true
        end
    end
    return false
end

-- The macros of `before` missing from `after` (both: name -> { body, icon }): renamed when a name new in
-- `after` has the same text (each new name once), else deleted. Returns { [old] = new } and the deleted names.
function History.Gone(before, after)
    local gone, new = {}, {}
    for name in pairs(before) do
        if not after[name] then gone[#gone + 1] = name end
    end
    for name in pairs(after) do
        if not before[name] then new[#new + 1] = name end
    end
    table.sort(gone)
    table.sort(new)
    local renamed, deleted, taken = {}, {}, {}
    for _, name in ipairs(gone) do
        for _, other in ipairs(new) do
            if not taken[other] and after[other].body == before[name].body then
                renamed[name], taken[other] = other, true
                break
            end
        end
        if not renamed[name] then deleted[#deleted + 1] = name end
    end
    return renamed, deleted
end

-- Versions to offer, newest first: not the text the macro has now, and each text once.
function History.Versions(store, name, saved)
    local out, seen, list = {}, { [saved or ""] = true }, store[name] or {}
    for i = #list, 1, -1 do
        local v = list[i]
        if not seen[v.body] then
            seen[v.body] = true
            out[#out + 1] = v
        end
    end
    return out
end

------------------------------------------------------------------------
-- Watching the macros (game API)
------------------------------------------------------------------------
local MAX_GENERAL = ns.MAX_GENERAL
local known -- { general = { [name] = { body, icon } }, character = { ... } }: the macros as of the last look

-- General macros are the account's, character macros this character's: their versions and their trash.
local function Saved(scope, key)
    local db = scope == "character" and ns.char or ns.db
    db[key] = db[key] or {}
    return db[key]
end
function History.Store(scope) return Saved(scope, "history") end
function History.Trash(scope) return Saved(scope, "trash") end

local function Macros()
    local now = { general = {}, character = {} }
    local general, character = GetNumMacros()
    local function add(scope, index)
        local name, _, body = GetMacroInfo(index)
        if name then now[scope][name] = { body = body or "", icon = ns.MacroIcon(index) } end
    end
    for index = 1, general do add("general", index) end
    for index = MAX_GENERAL + 1, MAX_GENERAL + character do add("character", index) end
    return now
end

-- The macros may have changed (UPDATE_MACROS, a save): a changed text is kept as a version, a macro gone
-- under a new name takes its versions along, a deleted one goes into the trash. The first look of a session
-- only learns the macros.
function History.Scan()
    local now = Macros()
    if known then
        for scope, macros in pairs(now) do
            local store, before = History.Store(scope), known[scope]
            for name, m in pairs(macros) do
                local old = before[name]
                if old and old.body ~= m.body then History.Add(store, name, old.body, time()) end
            end
            local renamed, deleted = History.Gone(before, macros)
            for old, new in pairs(renamed) do History.Rename(store, old, new) end
            for _, name in ipairs(deleted) do History.Discard(History.Trash(scope), name, before[name], time()) end
        end
    end
    known = now
end

-- This editor moves a macro into the other tab: its versions and its last text go along, so it is not taken for
-- deleted. Before the one in `from` is deleted.
function History.Moved(from, to, old, new)
    local source, target = History.Store(from), History.Store(to)
    if source[old] then target[new], source[old] = Merge(target[new] or {}, source[old]), nil end
    if known and known[from][old] then known[to][new], known[from][old] = known[from][old], nil end
end

-- This editor is about to rename a macro: its versions and its last text go with the name.
function History.Renamed(scope, old, new)
    History.Rename(History.Store(scope), old, new)
    if known and known[scope][old] then
        known[scope][new], known[scope][old] = known[scope][old], nil
    end
end

return History
