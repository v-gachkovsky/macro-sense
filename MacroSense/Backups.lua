-- Backups of all the macros, to go back to: one by itself on the first login of a day when they changed, and
-- one whenever asked. Restoring gives the macros of a backup their text and icon back and makes the missing
-- ones again; macros made since stay. Pure Lua (5.1); taking and restoring them needs the game (Window.lua).
local _, ns = ...
ns = ns or {}

local Backups = {}
ns.Backups = Backups

Backups.LIMIT = 10 -- backups kept per character

-- macros: { { scope, name, icon, body }, ... }, as Window takes them.
local function Key(m) return m.scope .. "\1" .. m.name end

-- Whether `a` and `b` hold the same macros, in any order.
function Backups.Same(a, b)
    if #a ~= #b then return false end
    local seen = {}
    for _, m in ipairs(a) do seen[Key(m)] = m end
    for _, m in ipairs(b) do
        local x = seen[Key(m)]
        if not x or x.body ~= m.body or x.icon ~= m.icon then return false end
    end
    return true
end

-- list: { { time, macros }, ... }, oldest first. Adds a backup of `macros` unless it has none or the newest
-- backup holds the same; the oldest go. True when added.
function Backups.Add(list, macros, time)
    local last = list[#list]
    if #macros == 0 or (last and Backups.Same(last.macros, macros)) then return false end
    list[#list + 1] = { time = time, macros = macros }
    while #list > Backups.LIMIT do table.remove(list, 1) end
    return true
end

-- Takes `backup` out of `list`: that one, though another may hold the same macros. True when it was there.
function Backups.Remove(list, backup)
    for i, b in ipairs(list) do
        if b == backup then
            table.remove(list, i)
            return true
        end
    end
    return false
end

-- The day's backup is due: none yet, or the newest is from another day.
function Backups.Due(list, now)
    local last = list[#list]
    return not last or date("%Y-%m-%d", last.time) ~= date("%Y-%m-%d", now)
end

-- What restoring `backup` (its macros) does to `now`, with `room` free slots per tab ({ general, character }):
-- { back = macros to give their text and icon back, again = macros to make again, full = no free slot for
-- them, same = nothing to do }, each a list of the backup's macros.
function Backups.Plan(backup, now, room)
    local current, free = {}, { general = room.general, character = room.character }
    for _, m in ipairs(now) do current[Key(m)] = m end
    local plan = { back = {}, again = {}, full = {}, same = {} }
    for _, m in ipairs(backup) do
        local c = current[Key(m)]
        local into
        if c then
            into = (c.body == m.body and c.icon == m.icon) and plan.same or plan.back
        elseif free[m.scope] > 0 then
            free[m.scope] = free[m.scope] - 1
            into = plan.again
        else
            into = plan.full
        end
        into[#into + 1] = m
    end
    return plan
end

return Backups
