-- The closest known name to a misspelled one ("Shadwo Bolt" -> "Shadow Bolt"). Pure Lua (5.1).
local _, ns = ...
ns = ns or {}

local Spelling = {}
ns.Spelling = Spelling

-- Typos between two names, case-insensitive: a missing, extra or wrong letter, or two letters swapped,
-- each count as one. Gives up (returns max + 1) once it is sure to be over `max`.
function Spelling.Distance(a, b, max)
    a, b = a:lower(), b:lower()
    if math.abs(#a - #b) > max then return max + 1 end
    local before, prev = nil, {}
    for j = 0, #b do prev[j] = j end
    for i = 1, #a do
        local cur, low = { [0] = i }, i
        local ca = a:byte(i)
        for j = 1, #b do
            local cb = b:byte(j)
            local v = math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca == cb and 0 or 1))
            if before and j > 1 and ca == b:byte(j - 1) and a:byte(i - 1) == cb then
                v = math.min(v, before[j - 2] + 1)
            end
            cur[j] = v
            if v < low then low = v end
        end
        -- A swap reaches back two rows, so stop only when both rows are over the limit.
        local prevLow = math.huge
        for j = 0, #b do prevLow = math.min(prevLow, prev[j]) end
        if low > max and prevLow > max then return max + 1 end
        before, prev = prev, cur
    end
    return prev[#b]
end

-- Typos a name of this length may have. Short names get none: "Fear" is not a typo of "Feat".
function Spelling.Allowed(len)
    if len <= 4 then return 0 end
    if len <= 8 then return 1 end
    if len <= 15 then return 2 end
    return 3
end

-- The candidate closest to `name` within its allowance, or nil. Ties go to the first candidate.
function Spelling.Suggest(name, candidates)
    local max = Spelling.Allowed(#name)
    if max == 0 then return nil end
    local best, bestDistance = nil, max + 1
    for _, candidate in ipairs(candidates) do
        local d = Spelling.Distance(name, candidate, bestDistance - 1)
        if d < bestDistance then
            best, bestDistance = candidate, d
            if d == 1 then break end
        end
    end
    return best
end

return Spelling
