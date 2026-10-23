-- Earlier saved texts of each macro, to bring one back: the game keeps only the last one. A change saved
-- anywhere (this editor, the Blizzard window, another addon) keeps the text it replaced. The lists are pure
-- Lua (5.1); watching the macros needs the game.
local _, ns = ...
ns = ns or {}

local History = {}
ns.History = History

History.LIMIT = 10 -- versions kept per macro

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

-- The macro got a new name: its versions go with it, in time order with any kept under that name before.
function History.Rename(store, old, new)
    if old == new or not store[old] then return end
    local a, b, list, i, j = store[new] or {}, store[old], {}, 1, 1
    while a[i] or b[j] do
        if not b[j] or (a[i] and a[i].time <= b[j].time) then
            list[#list + 1], i = a[i], i + 1
        else
            list[#list + 1], j = b[j], j + 1
        end
    end
    while #list > History.LIMIT do table.remove(list, 1) end
    store[new], store[old] = list, nil
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
local known -- { general = { [name] = body }, character = { ... } }: the texts as of the last look

-- General macros are the account's, character macros this character's.
function History.Store(scope)
    local db = scope == "character" and ns.char or ns.db
    db.history = db.history or {}
    return db.history
end

local function Texts()
    local now = { general = {}, character = {} }
    local general, character = GetNumMacros()
    local function add(scope, index)
        local name, _, body = GetMacroInfo(index)
        if name then now[scope][name] = body or "" end
    end
    for index = 1, general do add("general", index) end
    for index = MAX_GENERAL + 1, MAX_GENERAL + character do add("character", index) end
    return now
end

-- The macros may have changed (UPDATE_MACROS, a save): a changed text is kept as a version.
-- The first look of a session only learns the texts.
function History.Scan()
    local now = Texts()
    if known then
        for scope, texts in pairs(now) do
            for name, body in pairs(texts) do
                local old = known[scope][name]
                if old and old ~= body then History.Add(History.Store(scope), name, old, time()) end
            end
        end
    end
    known = now
end

-- This editor is about to rename a macro: its versions and its last text go with the name.
function History.Renamed(scope, old, new)
    History.Rename(History.Store(scope), old, new)
    if known and known[scope][old] then
        known[scope][new], known[scope][old] = known[scope][old], nil
    end
end

return History
