-- The General tab's own order: favorites at the top, and folders of your own, each opened and closed in the list.
-- By the macros' names, as their versions and notes (History.lua moves them with a macro renamed, moved or
-- deleted). The account's, as the General macros are. Pure Lua (5.1).
local _, ns = ...
ns = ns or {}

local Folders = {}
ns.Folders = Folders

Folders.MAX_NAME = 24 -- letters in a folder's name

-- { favorites = { [macro] = true }, folders = { folder names, in order }, of = { [macro] = folder } }.
local loose = {} -- before the saved variables are loaded (the plain tests)
function Folders.Shelf()
    local db = ns.db or loose
    db.shelf = db.shelf or { favorites = {}, folders = {}, of = {} }
    return db.shelf
end

local function Trim(s) return ((s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

function Folders.IsFavorite(name) return Folders.Shelf().favorites[name] == true end
function Folders.SetFavorite(name, on) Folders.Shelf().favorites[name] = on and true or nil end

-- The folder of macro `name`, or nil.
function Folders.Of(name) return Folders.Shelf().of[name] end
-- Macro `name` into `folder` (it must be there), nil: out of any.
function Folders.Put(name, folder)
    local shelf = Folders.Shelf()
    if folder and not Folders.Has(folder) then return false end
    shelf.of[name] = folder
    return true
end

function Folders.List() return Folders.Shelf().folders end
function Folders.Has(folder)
    for _, f in ipairs(Folders.List()) do if f == folder then return true end end
    return false
end

-- A new folder, last: its name trimmed. False and why: "empty", "taken".
function Folders.Add(folder)
    folder = Trim(folder)
    if folder == "" then return false, "empty" end
    if Folders.Has(folder) then return false, "taken" end
    table.insert(Folders.List(), folder)
    return true, folder
end

-- Folder `old` as `new`, its macros with it. False and why, as Add.
function Folders.Rename(old, new)
    new = Trim(new)
    if new == "" then return false, "empty" end
    if new == old then return true, new end
    if Folders.Has(new) then return false, "taken" end
    local shelf = Folders.Shelf()
    for i, f in ipairs(shelf.folders) do if f == old then shelf.folders[i] = new end end
    for macro, f in pairs(shelf.of) do if f == old then shelf.of[macro] = new end end
    return true, new
end

-- Folder `folder` gone: its macros stay, out of any folder.
function Folders.Remove(folder)
    local shelf = Folders.Shelf()
    for i = #shelf.folders, 1, -1 do
        if shelf.folders[i] == folder then table.remove(shelf.folders, i) end
    end
    for macro, f in pairs(shelf.of) do if f == folder then shelf.of[macro] = nil end end
end

-- Macro `old` of tab `from` is `new` of tab `to` now (renamed, or moved into the other tab); `to` nil: deleted.
-- Only the General tab has them: one leaving it leaves its favorite and folder behind.
function Folders.Moved(from, old, to, new)
    if from ~= "general" then return end
    local shelf = Folders.Shelf()
    local favorite, folder = shelf.favorites[old], shelf.of[old]
    shelf.favorites[old], shelf.of[old] = nil, nil
    if to == "general" and new then shelf.favorites[new], shelf.of[new] = favorite, folder end
end

return Folders
