-- Many macros at once: "Pick" puts a check before each macro and each group in the list, one click picks a macro or
-- a whole group and takes it back; Ctrl+click (Cmd+click on a Mac) picks a macro too. A row over the list says how
-- many are picked: "All" picks every macro the list shows or none, x none; its "Actions" menu shares, moves, puts
-- into a set or deletes them all.
local _, ns = ...
local L = ns.L

local Window, shared = ns.Window, ns.WindowShared
local state = shared.state
local MacroRange, IndexIn, TabName, Guard = shared.MacroRange, shared.IndexIn, shared.TabName, shared.Guard

-- The macros picked, in the order picked: { what = "macro", scope, name } in the game, { what = "stored", set,
-- name } behind the scenes. By name: the places in the list change as macros come and go.
local picked = {}
local bar, countText, allCheck
local mode = false -- "Pick" on: the checks show with nothing picked yet

-- Whether the list shows its checks: "Pick" on, or some picked.
function shared.Picking() return mode or #picked > 0 end

local function Key(p) return p.what == "stored" and "stored:" .. p.set .. ":" .. p.name or p.scope .. ":" .. p.name end
local function Of(r)
    if r.what == "stored" then return { what = "stored", set = r.set, name = r.name } end
    return { what = "macro", scope = r.scope, name = r.name }
end
local function Find(p)
    local key = Key(p)
    for i, x in ipairs(picked) do if Key(x) == key then return i end end
end

-- Whether row `r` (a macro, in the game or behind the scenes) is picked.
function shared.IsPicked(r)
    if r.what ~= "macro" and r.what ~= "stored" then return false end
    return Find(Of(r)) ~= nil
end

-- Those still there: a macro deleted or renamed since is no longer picked.
local function Prune()
    for i = #picked, 1, -1 do
        local p = picked[i]
        local there
        if p.what == "stored" then
            for _, m in ipairs(ns.Sets.Mine().enabled and ns.Sets.List(p.set) or {}) do
                there = there or m.name == p.name
            end
        else
            there = IndexIn(p.scope, p.name) ~= nil
        end
        if not there then table.remove(picked, i) end
    end
end

-- The row over the list, shown while picking; the list makes room for it.
function shared.RefreshPicks()
    if not bar then return end
    Prune()
    local on = shared.Picking()
    bar:SetShown(on)
    countText:SetText(ns.Plural(#picked, "%d picked", "%d picked"))
    allCheck:Refresh()
    shared.list:SetPoint("BOTTOMRIGHT", -13, on and 150 or 122)
end

function shared.TogglePick(r)
    local p = Of(r)
    local i = Find(p)
    if i then table.remove(picked, i) else picked[#picked + 1] = p end
    Window.RefreshList()
end

local function Clear()
    for i = #picked, 1, -1 do picked[i] = nil end
    Window.RefreshList()
end
Window.ClearPicks = Clear

-- A group's row: the macros its check picks (`members`), checked when all of them are.
function shared.SetMembers(r, members)
    r.members = members
    local all = #members > 0
    for _, p in ipairs(members) do all = all and Find(p) ~= nil end
    r.checked = all
    r.check:Refresh()
end

-- A click on a row's check: the macro picked or no longer; a group's all of it, or none of it when all were.
function shared.CheckRow(r)
    if r.what == "macro" or r.what == "stored" then return shared.TogglePick(r) end
    local members = r.members or {}
    for _, p in ipairs(members) do
        local i = Find(p)
        if r.checked and i then table.remove(picked, i) elseif not r.checked and not i then picked[#picked + 1] = p end
    end
    Window.RefreshList()
end

-- "Pick" on or off; off takes the picks back too.
function Window.SetPicking(on)
    mode = on and true or false
    if not mode then return Clear() end
    Window.RefreshList()
end
function Window.IsPicking() return mode end

-- The macro rows the list shows now, those under row `from` only (deeper than it, up to the next one as deep).
local function Shown(from)
    local out, inside = {}, from == nil
    for _, r in ipairs(shared.rows) do
        if not r:IsShown() then break end
        if from then
            if r == from then
                inside = true
            elseif inside and (r.depth or 0) <= (from.depth or 0) then
                break
            elseif inside and (r.what == "macro" or r.what == "stored") then
                out[#out + 1] = r
            end
        elseif r.what == "macro" or r.what == "stored" then
            out[#out + 1] = r
        end
    end
    return out
end

local function PickAll(rowsShown)
    for _, r in ipairs(rowsShown) do
        local p = Of(r)
        if not Find(p) then picked[#picked + 1] = p end
    end
    Window.RefreshList()
end

-- Whether every macro the list shows is picked (none shown: no).
local function AllShown()
    local shown = Shown()
    if #shown == 0 then return false end
    for _, r in ipairs(shown) do
        if not Find(Of(r)) then return false end
    end
    return true
end

-- All the macros of the group of row `r`, opened first if it was closed.
function shared.PickGroup(r)
    if not r.open then
        shared.groupOpen[r.group] = true
        Window.RefreshList()
    end
    PickAll(Shown(r))
end

-- A right click on a group's name: that.
function shared.OpenGroupPick(r)
    ns.OpenMenu(r, { { name = L["Pick this group"], onClick = function() shared.PickGroup(r) end } }, 200, false,
        true)
end

-- The picked macros as Share.Encode takes them.
local function Macros()
    local out = {}
    for _, p in ipairs(picked) do
        if p.what == "stored" then
            for _, m in ipairs(ns.Sets.List(p.set)) do
                if m.name == p.name then
                    out[#out + 1] = { scope = "character", name = m.name, icon = m.icon, body = m.body or "" }
                end
            end
        else
            local index = IndexIn(p.scope, p.name)
            local _, _, body = GetMacroInfo(index)
            out[#out + 1] = { scope = p.scope, name = p.name, icon = ns.MacroIcon(index), body = body or "" }
        end
    end
    return out
end

local function Count(what, scope)
    local n = 0
    for _, p in ipairs(picked) do
        if p.what == what and (not scope or p.scope == scope) then n = n + 1 end
    end
    return n
end

-- Those of tab `from` into the other one, while it has free slots; the rest stay and the chat says how many.
local function MoveAll(from)
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local to = from == "general" and "character" or "general"
    Guard(function() ns.Sets.Atomic(function()
        local moved, left = 0, 0
        for _, p in ipairs(picked) do
            if p.what == "macro" and p.scope == from then
                local first, last, max = MacroRange(to)
                local index = IndexIn(from, p.name)
                local name = index and last - first + 1 < max and shared.MoveOne(index, to)
                if name then
                    p.scope, p.name, moved = to, name, moved + 1
                else
                    left = left + 1
                end
            end
        end
        ns.History.Scan()
        ns.Say(ns.Plural(moved, "moved %d macro", "moved %d macros"))
        if left > 0 then ns.Print("no free slots for %d of them: they stay where they were", left) end
        state.scope, ns.db.scope = to, to
        local first, last = MacroRange(state.scope)
        shared.Load(last >= first and first or nil)
    end) end)
end

-- Each into set `to`, where it is now: in the game, or behind the scenes. The set of one in the game: its layer.
local function IntoSet(to)
    local now = ns.ActionBars.Spec()
    local done = 0
    ns.Sets.Atomic(function()
        for _, p in ipairs(picked) do
            local from = p.set
            if p.what == "macro" and p.scope == "character" then
                local layer = ns.Sets.LayerIn(p.name)
                from = layer == "spec" and now or layer or "character"
            end
            if from and from ~= to and ns.Sets.Place(from, p.name, to, p.what == "macro") then done = done + 1 end
        end
    end)
    ns.Say(string.format(L["%s: %s"], ns.SetsWindow.Label(to), ns.Plural(done, "%d macro put in", "%d macros put in")))
    Clear()
end

StaticPopupDialogs.MACROSENSE_DELETE_PICKED = {
    text = "Delete %s? Those in the game go into the trash.",
    button1 = "Delete", button2 = "Cancel",
    OnAccept = function() Window.DeletePicked() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- All of them: those in the game into the trash (as one deleted with x), those behind the scenes out of their sets.
function Window.DeletePicked()
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local list = {}
    for i, p in ipairs(picked) do list[i] = p end
    for _, p in ipairs(list) do
        if p.what == "stored" then
            Window.Forget(p.set, p.name)
        else
            local index = IndexIn(p.scope, p.name)
            if index then Window.Delete(index) end
        end
    end
    ns.History.Scan()
    Clear()
end

-- What "Actions" offers for the macros picked now.
local function Actions()
    local items = {
        { name = L["Pick all in the list"], onClick = function() PickAll(Shown()) end },
        { name = L["Clear the picks"], onClick = Clear },
        { name = L["Share"], onClick = function() ns.ShareWindow.Export(Macros()) end },
    }
    for _, from in ipairs({ "general", "character" }) do
        local n = Count("macro", from)
        local to = from == "general" and "character" or "general"
        if n > 0 then
            items[#items + 1] = { name = string.format(L["Move %d to %s"], n, TabName(to)),
                onClick = function() MoveAll(from) end }
        end
    end
    -- General ones: favorites and folders (WindowFolders.lua), when they are all General.
    if Count("macro", "general") == #picked then
        local names = {}
        for i, p in ipairs(picked) do names[i] = p.name end
        for _, item in ipairs(shared.FolderItems(names)) do items[#items + 1] = item end
    end
    if ns.Sets.Mine().enabled and Count("macro", "general") == 0 then
        local sets = { "character", "class" }
        for _, spec in ipairs(ns.Sets.Specs()) do sets[#sets + 1] = spec.key end
        for _, id in ipairs(sets) do
            items[#items + 1] = { name = string.format(L["Into: %s"], ns.SetsWindow.Label(id)),
                onClick = function() IntoSet(id) end }
        end
    end
    items[#items + 1] = { name = L["Delete"], onClick = function()
        ns.Ask("MACROSENSE_DELETE_PICKED", ns.Plural(#picked, "%d macro", "%d macros"))
    end }
    return items
end

-- The row, made with the window (Window.lua calls it): over the macro sets' check.
function Window.BuildPicks(side)
    bar = CreateFrame("Frame", nil, side)
    bar:SetPoint("BOTTOMLEFT", 8, 124)
    bar:SetPoint("BOTTOMRIGHT", -8, 124)
    bar:SetHeight(24)
    bar:Hide()
    -- "All": every macro the list shows, or none of them.
    allCheck = ns.Check(bar, L["All"], AllShown, function(on)
        if on then return PickAll(Shown()) end
        for _, r in ipairs(Shown()) do
            local i = Find(Of(r))
            if i then table.remove(picked, i) end
        end
        Window.RefreshList()
    end)
    allCheck:SetPoint("LEFT", 2, 0)
    countText = ns.Text(bar, 12)
    countText:SetPoint("LEFT", allCheck, "RIGHT", 8, 0)
    local clear = ns.Button(bar, "x", 22, Clear)
    clear:SetPoint("RIGHT")
    -- Narrow: the row is as wide as the list at its narrowest.
    local actions = ns.Button(bar, L["Actions"], 64, function(self) ns.OpenMenu(self, Actions(), 230, true, true) end)
    actions:SetPoint("RIGHT", clear, "LEFT", -4, 0)
end

-- Nothing picked when the editor opens again, and "Pick" off.
function Window.ForgetPicks()
    for i = #picked, 1, -1 do picked[i] = nil end
    mode = false
end
