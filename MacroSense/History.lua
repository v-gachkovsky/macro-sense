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

-- trash: { { name, icon, body, time, note }, ... }, oldest first. A deleted macro goes in with its note, the oldest
-- go out.
function History.Discard(trash, name, macro, time, note)
    trash[#trash + 1] = { name = name, icon = macro.icon, body = macro.body, time = time, note = note }
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
-- `after` has the same text (each new name once), or when one went and one came (renamed and changed in one save),
-- else deleted. Returns { [old] = new } and the deleted names.
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
    if #gone == 1 and #new == 1 and #deleted == 1 then
        renamed[gone[1]], deleted = new[1], {}
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

-- Text `from` becoming text `to`, line by line as diff shows it: { text, kind = "same", "gone" (only in `from`)
-- or "new" (only in `to`) }, in order, a line gone before the one that takes its place.
function History.Diff(from, to)
    local function Lines(s)
        local out = {}
        for line in (s .. "\n"):gmatch("([^\n]*)\n") do out[#out + 1] = line end
        return out
    end
    local a, b = Lines(from), Lines(to)
    -- kept[i][j]: the most lines a[i..] and b[j..] have in common, in order.
    local kept = {}
    for i = #a + 1, 1, -1 do
        kept[i] = {}
        for j = #b + 1, 1, -1 do
            if i > #a or j > #b then
                kept[i][j] = 0
            elseif a[i] == b[j] then
                kept[i][j] = kept[i + 1][j + 1] + 1
            else
                kept[i][j] = math.max(kept[i + 1][j], kept[i][j + 1])
            end
        end
    end
    local out, i, j = {}, 1, 1
    while i <= #a or j <= #b do
        if i <= #a and j <= #b and a[i] == b[j] then
            out[#out + 1] = { text = a[i], kind = "same" }
            i, j = i + 1, j + 1
        elseif i <= #a and (j > #b or kept[i + 1][j] >= kept[i][j + 1]) then
            out[#out + 1] = { text = a[i], kind = "gone" }
            i = i + 1
        else
            out[#out + 1] = { text = b[j], kind = "new" }
            j = j + 1
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

-- A note on a macro, kept by MacroSense outside its 255 characters: by the macro's name, as its versions. It
-- follows the macro renamed or moved, and goes into the trash with it.
function History.Note(scope, name) return name and Saved(scope, "notes")[name] or nil end
function History.SetNote(scope, name, text)
    text = text and text:gsub("^%s+", ""):gsub("%s+$", "")
    Saved(scope, "notes")[name] = text ~= "" and text or nil
end
-- And the General tab's favorite and folder (Folders.lua).
local function MoveNote(from, old, to, new)
    if from == to and old == new then return end
    local a, b = Saved(from, "notes"), Saved(to, "notes")
    if a[old] then b[new], a[old] = a[old], nil end
    if ns.Folders then ns.Folders.Moved(from, old, to, new) end
    if ns.Tag then ns.Tag.Moved(from, old, to, new) end
end
History.MoveNote = MoveNote

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
-- only learns the macros. This character's macros are also kept for your other characters to copy
-- (ns.Character().macros: name -> { body, icon }).
function History.Scan()
    local now = Macros()
    local mine = {}
    for name, m in pairs(now.character) do mine[name] = { body = m.body, icon = m.icon } end
    local c = ns.Character()
    c.macros, c.seen = mine, time()
    if known then
        for scope, macros in pairs(now) do
            local store, before = History.Store(scope), known[scope]
            for name, m in pairs(macros) do
                local old = before[name]
                if old and old.body ~= m.body then History.Add(store, name, old.body, time()) end
            end
            local renamed, deleted = History.Gone(before, macros)
            for old, new in pairs(renamed) do
                History.Rename(store, old, new)
                MoveNote(scope, old, scope, new)
            end
            local notes = Saved(scope, "notes")
            for _, name in ipairs(deleted) do
                -- One MacroSense took out of the slots itself (macro sets) is not in the trash, and keeps its note.
                if not (scope == "character" and ns.Sets and ns.Sets.Ours(name)) then
                    History.Discard(History.Trash(scope), name, before[name], time(), notes[name])
                    notes[name] = nil
                    if ns.Folders then ns.Folders.Moved(scope, name, nil, nil) end
                    if ns.Tag then ns.Tag.Moved(scope, name, nil, nil) end
                end
            end
        end
    end
    known = now
end

-- This editor moves a macro into the other tab: its versions and its last text go along, so it is not taken for
-- deleted. Before the one in `from` is deleted.
function History.Moved(from, to, old, new)
    local source, target = History.Store(from), History.Store(to)
    if source[old] then target[new], source[old] = Merge(target[new] or {}, source[old]), nil end
    MoveNote(from, old, to, new)
    if known and known[from][old] then known[to][new], known[from][old] = known[from][old], nil end
end

-- MacroSense changed the macros by itself (macro sets): they are learned as they are, with no versions or trash.
function History.Settle() known = Macros() end

-- MacroSense wrote macro `name` again by itself (your group's new tank, Roles.lua): the text it replaced is no
-- version to keep.
function History.Rewritten(scope, name, body)
    if known and known[scope][name] then known[scope][name].body = body end
end

-- This editor is about to rename a macro: its versions and its last text go with the name.
function History.Renamed(scope, old, new)
    History.Rename(History.Store(scope), old, new)
    MoveNote(scope, old, scope, new)
    if known and known[scope][old] then
        known[scope][new], known[scope][old] = known[scope][old], nil
    end
end

return History
