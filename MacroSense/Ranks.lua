-- A new rank of a spell, yours or your pet's: the macros that cast it with no rank are saved again. In the older
-- flavors the game keeps the rank such a macro had (/cast Shadow Bolt shows and casts Rank 2 after Rank 3 is
-- learned) until the macro's text changes, so it is changed and put back, as one would by hand. The history keeps no
-- version of it. Not in combat, when macros can't be changed: after it. Retail has no ranks: nothing to do there.
local _, ns = ...
ns = ns or {}

local Ranks = {}
ns.Ranks = Ranks

-- How many ranks each spell has: name -> count; spells with none are left out. The pet's spells (`pet`: name -> the
-- highest rank its book shows) count by that number.
function Ranks.Count(spells, pet)
    local out = {}
    for _, s in ipairs(spells or {}) do
        if s.ranks and #s.ranks > 0 then out[s.name] = #s.ranks end
    end
    for name, rank in pairs(pet or {}) do out[name] = math.max(out[name] or 0, rank) end
    return out
end

-- The spells with more ranks than `before` knew of; a spell new to the book is not one.
function Ranks.Learned(before, now)
    local out = {}
    for name, count in pairs(now) do
        if before[name] and count > before[name] then out[#out + 1] = name end
    end
    table.sort(out)
    return out
end

-- The commands that cast what they name, by their English names (the client's own: Parser.actionCommands).
local CASTS = { cast = true, use = true, castsequence = true, castrandom = true, userandom = true }

-- Whether `body` casts or shows (#showtooltip) one of `spells` by its whole name with no rank after it: "Shadow
-- Bolt", not "Shadow Bolt(Rank 2)", nor "Greater Shadow Bolt", a condition or a line said in chat.
function Ranks.Uses(body, spells)
    local wanted = {}
    for _, name in ipairs(spells) do wanted[name:lower()] = true end
    for line in (body or ""):gmatch("[^\n]+") do
        local options = line:match("^%s*#show%a*(.*)$")
        local command, rest = line:match("^%s*/(%S+)%s*(.*)$")
        if command and CASTS[ns.Parser.actionCommands[command:lower()] or ""] then options = rest end
        for clause in ((options or "") .. ";"):gmatch("([^;]*);") do
            local names = clause:gsub("%b[]", ""):gsub("reset=%S*", "")
            for name in (names .. ","):gmatch("([^,]*),") do
                if wanted[name:match("^[%s!]*(.-)%s*$"):lower()] then return true end
            end
        end
    end
    return false
end

local known -- the ranks of the last look; the first look of a session only learns them
local due = {} -- spells with a new rank whose macros wait for the end of combat

-- Save one macro again: changed, then as it was.
local function Resave(scope, index)
    local name, _, body = GetMacroInfo(index)
    -- The game tells the macro changed while EditMacro runs: by then it must be known as written here, or the
    -- history would keep a version and the editor take it for a change.
    ns.History.Rewritten(scope, name, "")
    EditMacro(index, nil, nil, "")
    ns.History.Rewritten(scope, name, body)
    EditMacro(index, nil, nil, body)
end

-- Spells changed: the macros of spells with a new rank are saved again, the pet's spells too (the Imp's Fire Shield
-- Rank 2 left a macro on Rank 1).
function Ranks.Update()
    local now = Ranks.Count(ns.sources.spells(), ns.sources.petRanks())
    if known then
        for _, name in ipairs(Ranks.Learned(known, now)) do due[name] = true end
    end
    known = now
    if not next(due) or InCombatLockdown() then return end
    local spells = {}
    for name in pairs(due) do spells[#spells + 1] = name end
    due = {}
    local general, character = GetNumMacros()
    for index = 1, general do
        if Ranks.Uses(select(3, GetMacroInfo(index)), spells) then Resave("general", index) end
    end
    for index = ns.MAX_GENERAL + 1, ns.MAX_GENERAL + character do
        if Ranks.Uses(select(3, GetMacroInfo(index)), spells) then Resave("character", index) end
    end
end

return Ranks
