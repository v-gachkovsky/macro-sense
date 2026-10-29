-- Names for the game's icons, so the icon search finds an icon by any spell or achievement that uses it, not
-- only by your own spells and items. The game has no names for its icon files, so all its spells are looked
-- through in the background while the icon grid is open: a few seconds, once per game patch and language. What
-- is found, and how far the lookup got, is kept in MacroSenseDB (ns.db.iconNames): the next session goes on from
-- there, and once done the names are there at once.
local _, ns = ...
ns = ns or {}

local IconNames = {}
ns.IconNames = IconNames

-- Spell IDs pass 1.2 million, with long empty stretches (2026): the lookup goes at least this far, then on
-- until this many in a row are empty.
IconNames.SPELLS, IconNames.EMPTY = 1500000, 200000
local KEEP = 4 -- names kept per icon
local CHUNK = 500 -- spells between looks at the clock

local wanted, found -- icon -> true: the icons of the grid; icon -> { names... }
local texts = {} -- icon -> what the search reads: its names in small letters, a name a line (not kept on disk)
local state = { nextID = 1, empty = 0 } -- how far the lookup got; kept in ns.db.iconNames when there is one

-- The lookup of this game build and language, kept from earlier sessions, or a new one.
local function Saved()
    local db = ns.db
    if not db then return nil end
    local build = GetBuildInfo and select(2, GetBuildInfo()) or ""
    local locale = GetLocale and GetLocale() or ""
    local saved = db.iconNames
    if not saved or saved.build ~= build or saved.locale ~= locale then
        saved = { build = build, locale = locale, nextID = 1, empty = 0, found = {} }
        db.iconNames = saved
    end
    return saved
end

-- The icons to name; the first call counts, the game's icons don't change.
function IconNames.Want(icons)
    if wanted then return end
    wanted = {}
    for _, icon in ipairs(icons) do wanted[icon] = true end
    local saved = Saved()
    if saved then state, found = saved, saved.found else found = {} end
end

local function Add(icon, name)
    if not (icon and wanted[icon]) or not name or name == "" then return end
    local names = found[icon]
    if not names then
        found[icon] = { name }
    elseif #names < KEEP then
        for _, n in ipairs(names) do
            if n == name then return end
        end
        names[#names + 1] = name
    end
    texts[icon] = nil
end

-- Looks up names for about `ms` milliseconds; true once there are none left to look up. Not in combat: it
-- takes time from every frame.
function IconNames.Step(ms)
    if state.finished or not wanted then return state.finished == true end
    if InCombatLockdown() then return false end
    local GetTexture, GetName = C_Spell.GetSpellTexture, C_Spell.GetSpellName
    local stop = debugprofilestop() + ms
    while state.nextID <= IconNames.SPELLS or state.empty < IconNames.EMPTY do
        for id = state.nextID, state.nextID + CHUNK - 1 do
            local icon = GetTexture(id)
            if icon then
                state.empty = 0
                if wanted[icon] then Add(icon, GetName(id)) end
            else
                state.empty = state.empty + 1
            end
        end
        state.nextID = state.nextID + CHUNK
        if debugprofilestop() >= stop then return false end
    end
    -- Achievements (from Wrath on) have icons of their own. Done first: should they go wrong, it is once, not
    -- every frame.
    state.finished = true
    if GetCategoryList and GetAchievementInfo then
        for _, category in ipairs(GetCategoryList()) do
            -- TBC has the functions without the achievements: no count.
            for i = 1, GetCategoryNumAchievements(category, true) or 0 do
                local _, name, _, _, _, _, _, _, _, icon = GetAchievementInfo(category, i)
                Add(icon, name)
            end
        end
    end
    return true
end

-- How far the lookup is: 0 to 1.
function IconNames.Progress()
    if state.finished then return 1 end
    return math.min(state.nextID / IconNames.SPELLS, 0.99)
end

-- The names found for `icon` so far, or nil; .text is what the search reads (small letters, a name a line: a
-- search can't run across two names).
function IconNames.For(icon)
    local names = found and found[icon]
    if not names then return nil end
    local text = texts[icon]
    if not text then
        local lower = {}
        for i, name in ipairs(names) do lower[i] = ns.Completion.Lower(name) end
        text = { text = table.concat(lower, "\n") }
        for i, name in ipairs(names) do text[i] = name end
        texts[icon] = text
    end
    return text
end

return IconNames
