-- The editor's Trash and Backups menus: macros deleted anywhere, to bring back (History.lua keeps them), and all
-- the macros saved as they were, to go back to (Backups.lua). The menus' buttons are made in Window.lua.
local _, ns = ...
local L = ns.L

local Window, shared = ns.Window, ns.WindowShared
local state = shared.state
local NEW_ICON = shared.NEW_ICON
local MacroRange, IndexIn, TabName, When = shared.MacroRange, shared.IndexIn, shared.TabName, shared.When
local Load, Guard, Full, FreeName = shared.Load, shared.Guard, shared.Full, shared.FreeName
local Macros = shared.Macros

------------------------------------------------------------------------
-- Trash: macros deleted anywhere, to bring back (History.lua keeps them)
------------------------------------------------------------------------
StaticPopupDialogs.MACROSENSE_EMPTY_TRASH = {
    text = "Empty the trash? Its %s deleted macros will be gone for good.",
    button1 = "Yes", button2 = "No",
    OnAccept = function()
        for _, scope in ipairs({ "general", "character" }) do
            local trash = ns.History.Trash(scope)
            for i = #trash, 1, -1 do trash[i] = nil end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs.MACROSENSE_FORGET_DELETED = {
    text = "Delete \"%s\" from the trash? It will be gone for good.",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function(_, d) ns.History.TakeOut(ns.History.Trash(d.scope), d.entry) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- The deleted macros of both tabs, newest first: { scope, entry }.
local function Deleted()
    local out = {}
    for _, scope in ipairs({ "general", "character" }) do
        for _, entry in ipairs(ns.History.Trash(scope)) do out[#out + 1] = { scope = scope, entry = entry } end
    end
    table.sort(out, function(a, b) return a.entry.time > b.entry.time end)
    return out
end

-- A deleted macro back in its tab, under a free name, and opened. Unsaved changes are asked about first.
function Window.Undelete(scope, entry)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local first, last, max = MacroRange(scope)
    if last - first + 1 >= max then
        return Full(scope, function()
            Guard(function()
                ns.History.TakeOut(ns.History.Trash(scope), entry)
                local made = Window.MakeBehind(entry.name, entry.icon, entry.body)
                ns.History.SetNote("character", made, entry.note)
            end)
        end)
    end
    Guard(function()
        local name = FreeName(entry.name)
        local index = CreateMacro(name, entry.icon or NEW_ICON, entry.body, scope == "character")
        if not index or index == 0 then return ns.Print("could not restore the macro") end
        ns.History.TakeOut(ns.History.Trash(scope), entry)
        ns.History.Scan()
        ns.History.SetNote(scope, name, entry.note)
        state.scope, ns.db.scope = scope, scope
        Load(GetMacroIndexByName(name))
    end)
end

local function TrashItems()
    local items, dim, deleted = {}, ns.scheme.dim, Deleted()
    for n = 1, #deleted do
        local d = deleted[n]
        local first, last, max = MacroRange(d.scope)
        local full = last - first + 1 >= max
        items[n] = {
            name = string.format("%s  |cff%s%s|r", d.entry.name, dim, When(d.entry.time)),
            disabled = full,
            onClick = function() Window.Undelete(d.scope, d.entry) end,
            onRemove = function() ns.Ask("MACROSENSE_FORGET_DELETED", d.entry.name, nil, d) end,
            removeTip = L["Delete for good"],
            onEnter = function(row)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:AddLine(d.entry.name, 1, 1, 1)
                GameTooltip:AddLine(full and string.format(L["The %s tab is full."], TabName(d.scope))
                    or string.format(L["Deleted from %s: %s. Click to bring it back."], TabName(d.scope),
                        When(d.entry.time)), 0.8, 0.8, 0.8, true)
                for line in ((d.entry.body or "") .. "\n"):gmatch("([^\n]*)\n") do
                    GameTooltip:AddLine(line ~= "" and line:gsub("|", "||") or " ", 0.6, 0.6, 0.6, true)
                end
                GameTooltip:Show()
            end,
        }
    end
    local noop = function() end
    if #deleted == 0 then items[1] = { name = L["No deleted macros"], disabled = true, onClick = noop } end
    items[#items + 1] = { name = L["Empty the trash"], disabled = #deleted == 0,
        onClick = function() ns.Ask("MACROSENSE_EMPTY_TRASH", #deleted) end }
    return items
end

------------------------------------------------------------------------
-- Backups: all the macros, to go back to (Backups.lua); kept per character
------------------------------------------------------------------------
local NAMES_SHOWN = 15 -- macro names in a backup's tooltip

local function BackupList()
    ns.char.backups = ns.char.backups or {}
    return ns.char.backups
end

-- A backup now, unless the macros are as in the last one.
function Window.BackupNow() ns.Backups.Add(BackupList(), Macros(), time()) end

-- On login: the day's backup, if the macros changed since the last one.
function Window.DailyBackup()
    local list = BackupList()
    if ns.Backups.Due(list, time()) then ns.Backups.Add(list, Macros(), time()) end
end

-- The macros of `backup` as they were, after a backup of them now; macros made since stay. Unsaved changes are
-- asked about first.
function Window.RestoreBackup(backup)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    Guard(function()
        ns.Backups.Add(BackupList(), Macros(), time())
        local room = {}
        for _, s in ipairs({ "general", "character" }) do
            local first, last, max = MacroRange(s)
            room[s] = max - (last - first + 1)
        end
        local plan = ns.Backups.Plan(backup.macros, Macros(), room)
        for _, m in ipairs(plan.back) do EditMacro(IndexIn(m.scope, m.name), m.name, m.icon, m.body) end
        for _, m in ipairs(plan.again) do CreateMacro(m.name, m.icon or NEW_ICON, m.body, m.scope == "character") end
        ns.History.Scan()
        ns.Print("backup restored: %d changed back, %d made again", #plan.back, #plan.again)
        if #plan.full > 0 then
            ns.Print(ns.Plural(#plan.full, "%d did not fit: no free slot in its tab",
                "%d did not fit: no free slot in their tab"))
        end
        local first, last = MacroRange(state.scope)
        Load(state.index and IndexIn(state.scope, state.name) or (last >= first and first or nil))
    end)
end

StaticPopupDialogs.MACROSENSE_RESTORE_BACKUP = {
    text = "Restore the backup of %s?\n\nYour macros get back the text and icons they had then, and the missing ones "
        .. "are made again. Macros you made after it stay. First, MacroSense backs up your macros as they are now.",
    button1 = "Yes", button2 = "No",
    OnAccept = function(_, backup) Window.RestoreBackup(backup) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs.MACROSENSE_DELETE_BACKUP = {
    text = "Delete the backup of %s? It will be gone for good.",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function(_, backup) ns.Backups.Remove(BackupList(), backup) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function BackupItems()
    local dim, list = ns.scheme.dim, BackupList()
    local function tip(row, title, text)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title, 1, 1, 1)
        GameTooltip:AddLine(text, 0.8, 0.8, 0.8, true)
    end
    local items = { {
        name = L["Back up now"],
        onClick = function()
            local macros = Macros()
            if #macros == 0 then return ns.Print("no macros to back up") end
            if ns.Backups.Add(list, macros, time()) then
                return ns.Print(ns.Plural(#macros, "backed up %d macro", "backed up %d macros"))
            end
            ns.Print("your macros are as in the last backup")
        end,
        onEnter = function(row)
            tip(row, L["Back up now"], string.format(L["Saves all your macros now, General and this character's. "
                .. "Each character keeps its last %d backups; older ones are deleted by themselves."],
                ns.Backups.LIMIT))
            GameTooltip:Show()
        end,
    } }
    for i = #list, 1, -1 do
        local b = list[i]
        items[#items + 1] = {
            name = string.format("%s  |cff%s%s|r", When(b.time), dim, ns.Plural(#b.macros, "%d macro", "%d macros")),
            onClick = function() ns.Ask("MACROSENSE_RESTORE_BACKUP", When(b.time), nil, b) end,
            onRemove = function() ns.Ask("MACROSENSE_DELETE_BACKUP", When(b.time), nil, b) end,
            removeTip = L["Delete this backup"],
            onEnter = function(row)
                local count = { general = 0, character = 0 }
                local names = {}
                for n, m in ipairs(b.macros) do
                    count[m.scope] = count[m.scope] + 1
                    if n <= NAMES_SHOWN then names[n] = m.name end
                end
                tip(row, string.format(L["Backup of %s"], When(b.time)), string.format(L["General %d, Character %d. "
                    .. "Click to restore it."], count.general, count.character))
                local more = #b.macros > NAMES_SHOWN and string.format(L[" and %d more"], #b.macros - NAMES_SHOWN)
                    or ""
                GameTooltip:AddLine(table.concat(names, ", ") .. more, 0.6, 0.6, 0.6, true)
                GameTooltip:Show()
            end,
        }
    end
    if #list == 0 then items[2] = { name = L["No backups yet"], disabled = true, onClick = function() end } end
    return items
end
shared.TrashItems, shared.BackupItems = TrashItems, BackupItems
