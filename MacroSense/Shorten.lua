-- The same macro in fewer characters, for the 255 character limit. Pure Lua (5.1).
-- target= -> @, modifier -> mod (and the other long condition names), [pet:A][pet:B] -> [pet:A/B],
-- "[x] Spell; Spell" -> "[x][]Spell", no spaces the game does not need, no empty lines. Lines it can't
-- read for sure stay as they are: chat, Lua, other addons' commands, lines with errors.
local _, ns = ...
ns = ns or {}

local Shorten = {}
ns.Shorten = Shorten

local function trim(s) return s:match("^%s*(.-)%s*$") end

-- Short names of conditions: the game reads both the same.
local SHORT = { modifier = "mod", button = "btn", actionbar = "bar", stance = "form", equipped = "worn" }
-- Conditions whose values are alternatives: [pet:Imp][pet:Voidwalker] = [pet:Imp/Voidwalker].
-- Not their "no" forms: [nomod:alt][nomod:shift] is not [nomod:alt/shift].
local ALTERNATIVES = {
    mod = true, btn = true, form = true, bar = true, bonusbar = true, pet = true, spec = true, group = true,
    worn = true, channeling = true,
}

-- One condition, short: "target=focus" -> "@focus", "nomodifier:shift" -> "nomod:shift".
local function shortCondition(cond)
    local unit = cond:match("^target=(.*)$") or cond:match("^@(.*)$")
    if unit then return "@" .. trim(unit) end
    local name, values = cond:match("^([^:]*):(.*)$")
    name = trim(name or cond)
    local lower = name:lower()
    if SHORT[lower] then
        name = SHORT[lower]
    elseif lower:sub(1, 2) == "no" and SHORT[lower:sub(3)] then
        name = "no" .. SHORT[lower:sub(3)]
    end
    if not values then return name end
    local parts = {}
    for v in (values .. "/"):gmatch("([^/]*)/") do parts[#parts + 1] = trim(v) end
    return name .. ":" .. table.concat(parts, "/")
end

-- "[a,b][c] X; Y" -> { { groups = { { "a", "b" }, { "c" } }, action = "X" }, { groups = {}, action = "Y" } },
-- or nil when the brackets don't pair up.
local function parse(options)
    local texts, depth, start = {}, 0, 1
    for i = 1, #options do
        local c = options:sub(i, i)
        if c == "[" then
            depth = depth + 1
        elseif c == "]" then
            depth = depth - 1
        elseif c == ";" and depth == 0 then
            texts[#texts + 1] = options:sub(start, i - 1)
            start = i + 1
        end
        if depth < 0 or depth > 1 then return nil end
    end
    if depth ~= 0 then return nil end
    texts[#texts + 1] = options:sub(start)
    local clauses = {}
    for _, text in ipairs(texts) do
        local clause, rest = { groups = {} }, trim(text)
        while rest:sub(1, 1) == "[" do
            local close = rest:find("]", 1, true)
            -- Split on "," by hand: gmatch with an empty-matching pattern behaves differently in Lua 5.1.
            local group, inner, from = {}, rest:sub(2, close - 1), 1
            while true do
                local comma = inner:find(",", from, true)
                local cond = trim(inner:sub(from, (comma or #inner + 1) - 1))
                if cond ~= "" then group[#group + 1] = shortCondition(cond) end
                if not comma then break end
                from = comma + 1
            end
            clause.groups[#clause.groups + 1] = group
            rest = trim(rest:sub(close + 1))
        end
        if rest:find("[%[%]]") then return nil end
        clause.action = rest
        clauses[#clauses + 1] = clause
    end
    return clauses
end

-- The spell or item part; sequences and random lists also lose the spaces after their commas.
local function shortAction(action, base)
    if base ~= "castsequence" and base ~= "castrandom" and base ~= "userandom" then return action end
    local reset, list = action:match("^(reset=%S+)%s+(.*)$")
    local steps = {}
    for step in ((list or action) .. ","):gmatch("([^,]*),") do steps[#steps + 1] = trim(step) end
    return (reset and reset .. " " or "") .. table.concat(steps, ",")
end

-- Two groups side by side as one, or nil. The same conditions: the first one is enough. All the same but
-- one condition that takes alternatives: [pet:Imp,harm] + [pet:Voidwalker,harm] -> [pet:Imp/Voidwalker,harm].
local function mergeGroups(a, b)
    if #a ~= #b then return nil end
    local used, odd = {}, nil
    for i, cond in ipairs(a) do
        local found
        for j, other in ipairs(b) do
            if not used[j] and other == cond then
                found = j
                break
            end
        end
        if found then
            used[found] = true
        elseif odd then
            return nil
        else
            odd = i
        end
    end
    if not odd then return a end
    local other
    for j = 1, #b do
        if not used[j] then other = b[j] end
    end
    local name, values = a[odd]:match("^(%a+):(.+)$")
    local name2, values2 = other:match("^(%a+):(.+)$")
    if not name or name ~= name2 or not ALTERNATIVES[name] then return nil end
    local list, seen = {}, {}
    for v in (values .. "/" .. values2 .. "/"):gmatch("([^/]*)/") do
        if v ~= "" and not seen[v] then
            seen[v] = true
            list[#list + 1] = v
        end
    end
    local merged = {}
    for i, cond in ipairs(a) do merged[i] = cond end
    merged[odd] = name .. ":" .. table.concat(list, "/")
    return merged
end

local function shrink(clauses)
    -- Clauses side by side with the same spell: one clause with the groups of both ("[x] A; A" -> "[x][]A"),
    -- when "[]" for a clause without conditions costs less than the spell's name.
    local i = 1
    while clauses[i + 1] do
        local a, b = clauses[i], clauses[i + 1]
        local cost = (#a.groups == 0 and 2 or 0) + (#b.groups == 0 and 2 or 0)
        if a.action ~= "" and a.action == b.action and #a.action + 1 > cost then
            local groups = #a.groups > 0 and a.groups or { {} }
            for _, g in ipairs(#b.groups > 0 and b.groups or { {} }) do groups[#groups + 1] = g end
            a.groups = groups
            table.remove(clauses, i + 1)
        else
            i = i + 1
        end
    end
    for _, clause in ipairs(clauses) do
        local groups, j = clause.groups, 1
        while groups[j + 1] do
            local merged = mergeGroups(groups[j], groups[j + 1])
            if merged then
                groups[j] = merged
                table.remove(groups, j + 1)
            else
                j = j + 1
            end
        end
        if #groups == 1 and #groups[1] == 0 then clause.groups = {} end -- "[] X" is "X"
    end
end

local function build(clauses)
    local out = {}
    for i, clause in ipairs(clauses) do
        local groups = {}
        for _, g in ipairs(clause.groups) do groups[#groups + 1] = "[" .. table.concat(g, ",") .. "]" end
        out[i] = table.concat(groups) .. clause.action
    end
    return table.concat(out, ";")
end

-- A command's text, shorter; nil when it can't be read for sure. base: the action command ("cast", ...).
local function shortOptions(options, base)
    local clauses = parse(options)
    if not clauses then return nil end
    for _, clause in ipairs(clauses) do clause.action = shortAction(clause.action, base) end
    shrink(clauses)
    return build(clauses)
end

local function shortLine(line, conditional)
    local meta, options = line:match("^(#show%a*)(.*)$")
    if meta and (meta:lower() == "#show" or meta:lower() == "#showtooltip") then
        local args = shortOptions(options, "cast")
        if not args then return line end
        return args == "" and meta or meta .. " " .. args
    end
    local lead, cmd, rest = line:match("^(%s*)/(%S+)(.*)$")
    if not cmd or not conditional(cmd:lower()) then return line end
    local args = shortOptions(rest, ns.Parser.actionCommands[cmd:lower()])
    if not args then return line end
    return lead .. "/" .. cmd .. (args ~= "" and " " .. args or "")
end

-- opts.conditional(name) -> true for commands whose text goes through the game's condition check
-- (/cast, /petattack, ...); opts.skip: { [line] = true } for lines to leave alone (lines with errors).
function Shorten.Text(raw, opts)
    local out, n = {}, 0
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        n = n + 1
        local short = line
        if not (opts.skip and opts.skip[n]) then
            short = shortLine(line, opts.conditional)
            if #short > #line then short = line end
        end
        if short:find("%S") then out[#out + 1] = short end -- empty lines go
    end
    return table.concat(out, "\n")
end

return Shorten
