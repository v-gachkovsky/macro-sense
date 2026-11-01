-- A new rank of a spell: the macros that cast it with no rank are saved again. In the older flavors the game keeps
-- the rank such a macro had (/cast Shadow Bolt shows and casts Rank 2 after Rank 3 is learned) until the macro's
-- text changes, so it is changed and put back, as one would by hand. The history keeps no version of it. Not in
-- combat, when macros can't be changed: after it. Retail has no ranks: nothing to do there.
local _, ns = ...
ns = ns or {}

local Ranks = {}
ns.Ranks = Ranks

-- How many ranks each spell has: name -> count; spells with none are left out.
function Ranks.Count(spells)
    local out = {}
    for _, s in ipairs(spells or {}) do
        if s.ranks and #s.ranks > 0 then out[s.name] = #s.ranks end
    end
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

-- Whether `body` names one of `spells` with no rank after it: "Shadow Bolt", not "Shadow Bolt(Rank 2)".
function Ranks.Uses(body, spells)
    local text = (body or ""):lower()
    for _, name in ipairs(spells) do
        local from, last = 1, nil
        repeat
            local s, e = text:find(name:lower(), from, true)
            if s then
                if not text:sub(e + 1):match("^%s*%(") then return true end
                from = e + 1
            end
            last = s
        until not last
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

-- Spells changed: the macros of spells with a new rank are saved again.
function Ranks.Update()
    local now = Ranks.Count(ns.sources.spells())
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
