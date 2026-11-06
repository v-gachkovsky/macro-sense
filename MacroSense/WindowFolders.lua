-- The General tab's favorites and folders (Folders.lua keeps them): a macro's "..." marks it a favorite or puts it
-- in a folder, a right click on a folder's name renames or deletes it. Picked macros go into one all at once.
local _, ns = ...
local L = ns.L

local Window, shared = ns.Window, ns.WindowShared
local F = ns.Folders

-- A folder's name asked for, then `done(name)`; one taken or empty is asked again.
local function AskName(heading, text, done)
    shared.AskLine(heading, text, function(name)
        local ok, why = done(name)
        if ok then return end
        if why == "taken" then
            ns.Print("there is a folder of that name already")
        else
            ns.Print("the folder needs a name")
        end
        return true
    end, F.MAX_NAME)
end

-- What `names` (General macros) can do with the folders: a favorite or not, into a folder, a new one or out.
local function Items(names)
    local items, favorite, inFolder = {}, true, false
    for _, name in ipairs(names) do
        favorite = favorite and F.IsFavorite(name)
        inFolder = inFolder or F.Of(name) ~= nil
    end
    items[#items + 1] = { name = favorite and L["Remove from favorites"] or L["Add to favorites"], onClick = function()
        for _, name in ipairs(names) do F.SetFavorite(name, not favorite) end
        Window.RefreshList()
    end }
    for _, folder in ipairs(F.List()) do
        local all = true
        for _, name in ipairs(names) do all = all and F.Of(name) == folder end
        if not all then
            items[#items + 1] = { name = string.format(L["Into the folder: %s"], folder), onClick = function()
                for _, name in ipairs(names) do F.Put(name, folder) end
                Window.RefreshList()
            end }
        end
    end
    items[#items + 1] = { name = L["Into a new folder"], onClick = function()
        AskName(L["A new folder"], "", function(text)
            local ok, folder = F.Add(text)
            if not ok then return false, folder end
            for _, name in ipairs(names) do F.Put(name, folder) end
            return true
        end)
    end }
    if inFolder then
        items[#items + 1] = { name = L["Out of the folder"], onClick = function()
            for _, name in ipairs(names) do F.Put(name, nil) end
            Window.RefreshList()
        end }
    end
    return items
end
shared.FolderItems = Items

StaticPopupDialogs.MACROSENSE_DELETE_FOLDER = {
    text = "Delete the folder \"%s\"? Its macros stay, out of any folder.",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function(_, folder)
        F.Remove(folder)
        Window.RefreshList()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- A right click on the name of Favorites or of a folder: pick all of it; a folder, renamed or deleted.
function shared.OpenFolderMenu(r)
    local items = { { name = L["Pick this group"], onClick = function() shared.PickGroup(r) end } }
    if r.folder then
        items[#items + 1] = { name = L["Rename the folder"], onClick = function()
            AskName(L["Rename the folder"], r.folder, function(text)
                local ok, why = F.Rename(r.folder, text)
                if ok then shared.groupOpen["shelf:" .. why] = shared.groupOpen["shelf:" .. r.folder] end
                return ok, why
            end)
        end }
        items[#items + 1] = { name = L["Delete the folder"], onClick = function()
            ns.Ask("MACROSENSE_DELETE_FOLDER", r.folder, nil, r.folder)
        end }
    end
    ns.OpenMenu(r, items, 200, false, true)
end
