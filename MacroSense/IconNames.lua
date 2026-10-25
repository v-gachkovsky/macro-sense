-- Names for the game's icons, so the icon search finds an icon by any spell or achievement that uses it, not
-- only by your own spells and items. The game has no names for its icon files, so all its spells are looked
-- through in the background while the icon grid is open: a few seconds, once per session.
local _, ns = ...
ns = ns or {}

local IconNames = {}
ns.IconNames = IconNames

-- Spell IDs pass 1.2 million, with long empty stretches (2026): the lookup goes at least this far, then on
-- until this many in a row are empty.
IconNames.SPELLS, IconNames.EMPTY = 1500000, 200000
local KEEP = 4 -- names kept per icon
local CHUNK = 500 -- spells between looks at the clock

local wanted, found -- icon -> true: the icons of the grid; icon -> { names..., text = what the search reads }
local nextID, empty, finished = 1, 0, false

-- The icons to name; the first call counts, the game's icons don't change.
function IconNames.Want(icons)
    if wanted then return end
    wanted, found = {}, {}
    for _, icon in ipairs(icons) do wanted[icon] = true end
end

local function Add(icon, name)
    if not (icon and wanted[icon]) or not name or name == "" then return end
    local names = found[icon]
    if not names then
        found[icon] = { name, text = ns.Completion.Lower(name) }
    elseif #names < KEEP then
        for _, n in ipairs(names) do
            if n == name then return end
        end
        names[#names + 1] = name
        names.text = names.text .. "\n" .. ns.Completion.Lower(name) -- a search can't run across two names
    end
end

-- Looks up names for about `ms` milliseconds; true once there are none left to look up. Not in combat: it
-- takes time from every frame.
function IconNames.Step(ms)
    if finished or not wanted then return finished end
    if InCombatLockdown() then return false end
    local GetTexture, GetName = C_Spell.GetSpellTexture, C_Spell.GetSpellName
    local stop = debugprofilestop() + ms
    while nextID <= IconNames.SPELLS or empty < IconNames.EMPTY do
        for id = nextID, nextID + CHUNK - 1 do
            local icon = GetTexture(id)
            if icon then
                empty = 0
                if wanted[icon] then Add(icon, GetName(id)) end
            else
                empty = empty + 1
            end
        end
        nextID = nextID + CHUNK
        if debugprofilestop() >= stop then return false end
    end
    -- Achievements (from Wrath on) have icons of their own.
    if GetCategoryList and GetAchievementInfo then
        for _, category in ipairs(GetCategoryList()) do
            for i = 1, GetCategoryNumAchievements(category, true) do
                local _, name, _, _, _, _, _, _, _, icon = GetAchievementInfo(category, i)
                Add(icon, name)
            end
        end
    end
    finished = true
    return true
end

-- How far the lookup is: 0 to 1.
function IconNames.Progress()
    if finished then return 1 end
    return math.min(nextID / IconNames.SPELLS, 0.99)
end

-- The names found for `icon` so far, or nil; .text is what the search reads (small letters, a name a line).
function IconNames.For(icon)
    return found and found[icon]
end

return IconNames
