-- Turns a parser context into a ranked list of suggestions. Pure Lua: sources come from ns.data and ns.sources.
local _, ns = ...
ns = ns or {}

local Completion = {}
ns.Completion = Completion
ns.sources = ns.sources or {} -- Sources fills: commands(), spells(), items()

Completion.limit = 500 -- the list shows 10 rows and scrolls through the rest

local function source(name)
    return ns.sources[name] and ns.sources[name]() or {}
end

-- Items that fit the command: /equip wants gear, /use and /cast want items with a use effect.
local function items(want)
    local out = {}
    for _, item in ipairs(source("items")) do
        if item[want] then out[#out + 1] = item end
    end
    return out
end

local function concat(a, b)
    local out, seen = {}, {}
    for _, l in ipairs({ a, b }) do
        for _, item in ipairs(l) do
            if not seen[item.name] then
                seen[item.name] = true
                out[#out + 1] = item
            end
        end
    end
    return out
end

local function actions(cmd)
    if cmd == "equip" or cmd == "equipslot" then return items("equippable") end
    if cmd == "cancelaura" then return source("buffs") end
    if cmd == "use" or cmd == "userandom" then return concat(items("usable"), source("spells")) end
    return concat(source("spells"), items("usable"))
end

local function list(kind, ctx)
    local d = ns.data
    if kind == "command" then return ns.sources.commands and ns.sources.commands() or d.commands end
    if kind == "meta" then return d.meta end
    if kind == "condition" then
        -- Not those that came with a later expansion than this client's.
        local out = {}
        for _, c in ipairs(d.conditions) do
            if not ns.HasExpansion or ns.HasExpansion(c.since) then out[#out + 1] = c end
        end
        return out
    end
    if kind == "unit" then return ns.Conditions.UnitItems(ctx.prefix) end
    if kind == "modifier" then return d.modifiers end
    if kind == "action" then return actions(ctx.base) end
    if kind == "conditionValue" then return ns.Conditions.Values(ctx.condition) end
    if kind == "reset" then return ns.Conditions.ResetItems(ctx.used) end
    if kind == "slot" then return ns.sources.slots and ns.sources.slots() or d.slots end
    if kind == "bagSlot" then return ns.sources.bagSlots and ns.sources.bagSlots(ctx.bag) or {} end
    if kind == "clickButton" then return source("clickButtons") end
    if kind == "clickMouse" then return d.mouseButtons end
    if kind == "clickDown" then return d.clickDown end
    return {}
end

-- Text inserted for a suggestion: commands get a trailing space, conditions with a value get ":".
local function insertText(kind, item)
    if item.insert then return item.insert end
    if kind == "command" or kind == "meta" then return item.name .. " " end
    if kind == "condition" and item.arg then return item.name .. ":" end
    return item.name
end

local function findSpell(name)
    name = name:lower()
    for _, spell in ipairs(source("spells")) do
        if spell.name:lower() == name then return spell end
    end
end

-- Learned ranks of a spell, highest first. `withName`: insert "Spell(Rank 3)" (the spell name is the
-- word being replaced), otherwise just "Rank 3)" after the typed "(". All ranks show, the limit does not apply.
local function rankItems(spell, withName, prefix)
    local out = {}
    for i = #spell.ranks, 1, -1 do
        local rank = spell.ranks[i]
        if not prefix or rank:lower():find(prefix, 1, true) then
            out[#out + 1] = {
                name = rank, hint = i == #spell.ranks and "highest" or nil, icon = spell.icon, rank = true,
                insert = (withName and spell.name .. "(" or "") .. rank .. ")",
            }
        end
    end
    return out
end

------------------------------------------------------------------------
-- What was typed against a name
------------------------------------------------------------------------
local SEPARATOR = "[%s%-:/(),]"
local WORD = "[^%s%-:/(),]+" -- what is between them
local LETTER = "[^\128-\191][\128-\191]*" -- one letter of UTF-8, whole

-- Capitals besides A-Z, in UTF-8: À-Þ and Cyrillic Ѐ-Я. Each: the lead byte and the range of the second, the
-- lead byte of the small letter and how far its second byte is.
local CASES = {
    { "\195([\128-\150\152-\158])", "\195", 32 },
    { "\208([\128-\143])", "\209", 16 },
    { "\208([\144-\159])", "\208", 32 },
    { "\208([\160-\175])", "\209", -32 },
}

local function Lower(s)
    s = s:lower()
    for _, case in ipairs(CASES) do
        s = s:gsub(case[1], function(c) return case[2] .. string.char(c:byte() + case[3]) end)
    end
    return s
end
Completion.Lower = Lower -- the icon search ignores case the same way

-- A name's words, to compare names: lower case, apostrophes dropped, other marks as spaces, and a space at both
-- ends, so that " fire blast " is in " fire blast focus " as whole words.
local function Words(s)
    return " " .. (Lower(s):gsub("'", ""):gsub("[%s%p]+", " "):match("^ *(.-) *$")) .. " "
end

-- Words of a macro's name that say whom it is for, not what it casts ("Poly Focus", "Heal MO", "Kick arena1").
local TARGET_WORDS = { focus = true, mouseover = true, mo = true, target = true, self = true, player = true,
    cursor = true, party = true, arena = true, pet = true, boss = true }

-- The icon of the spell or item (of yours: spellbook, bags, gear) a macro is named after, or nil: the longest
-- whose name is in the macro's name as whole words, in any case ("fireball", "Kick Focus": Kick); else the
-- shortest with a word that starts like the macro's first word that is not a target, of 3 letters or more
-- ("Poly MO": Polymorph, "Nova": Frost Nova).
function Completion.IconFor(name)
    local macro, all, best = Words(name), {}, nil
    for _, kind in ipairs({ "spells", "items" }) do
        for _, c in ipairs(source(kind)) do
            if c.icon then all[#all + 1] = { icon = c.icon, words = Words(c.name) } end
        end
    end
    for _, c in ipairs(all) do
        if macro:find(c.words, 1, true) and (not best or #c.words > #best.words) then best = c end
    end
    if best then return best.icon end
    for word in macro:gmatch("%S+") do
        if not TARGET_WORDS[word:gsub("%d+$", "")] then
            if select(2, word:gsub("[^\128-\191]", "")) < 3 then return nil end
            for _, c in ipairs(all) do
                if c.words:find(" " .. word, 1, true) and (not best or #c.words < #best.words) then best = c end
            end
            return best and best.icon
        end
    end
end

-- Two capitals or more ("DA", "SWP", "CoA"; not "Da" or "D"): then each letter is the first letter of a word.
local function Capitals(s)
    local n = 0
    for c in s:gmatch(LETTER) do
        if Lower(c) ~= c then n = n + 1 end
    end
    return n >= 2
end

-- Where the words of `name` start: its first letter, and each one after a space or - : / ( ) ,
local function WordStarts(name)
    local out = {}
    for i = 1, #name do
        if not name:sub(i, i):find(SEPARATOR) and (i == 1 or name:sub(i - 1, i - 1):find(SEPARATOR)) then
            out[#out + 1] = i
        end
    end
    return out
end

-- The first letter of each word, whole: "curse of agony" -> "coa".
local function Initials(name)
    local out = {}
    for _, i in ipairs(WordStarts(name)) do out[#out + 1] = name:match("^" .. LETTER, i) end
    return table.concat(out)
end

-- Whether each part of `q` between spaces begins a word of `name`, in that order, words may be left out:
-- "fi" -> "soul fire", "sh wo" -> "shadow word: pain".
local function WordsBegin(name, q)
    local starts, k = WordStarts(name), 1
    for part in q:gmatch("%S+") do
        while starts[k] and name:sub(starts[k], starts[k] + #part - 1) ~= part do k = k + 1 end
        if not starts[k] then return false end
        k = k + 1
    end
    return true
end

-- Whether the letters of `q` come in `s` in that order, from `at` on: "nmd" in "nomod".
local function InOrder(s, q, at)
    at = at or 1
    for c in q:gmatch(LETTER) do
        local i = s:find(c, at, true)
        if not i then return false end
        at = i + #c
    end
    return true
end

-- Whether a word of `name` has the letters of `q` in that order, the first one starting it: "nmd" -> "nomod",
-- "frbl" -> "frostbolt"; not "ds" -> "demon skin" (two words), not "mnd" -> "nomod" (not from its start).
local function InWord(name, q)
    local first = q:match("^" .. LETTER)
    if not first then return false end
    for word in name:gmatch(WORD) do
        if word:sub(1, #first) == first and InOrder(word, q:sub(#first + 1), #first + 1) then return true end
    end
    return false
end

-- The group of Match a name goes in, if any.
local function Group(name, q, bare, caps)
    if caps then
        local initials = Initials(name)
        return (initials == bare and 1) or (InOrder(initials, bare) and 2)
    end
    local at = q == "" and 1 or name:find(q, 1, true)
    return (at == 1 and 1) or (bare ~= "" and WordsBegin(name, q) and 2) or (at and 3)
        or (bare ~= "" and q == bare and InWord(name, q) and 4)
end

-- The items whose names fit what was typed, best first, each group in the list's order. Two capitals or more
-- make each letter the first letter of a word ("DA" -> Demon Armor, "CoA" -> Curse of Agony): the names with just
-- those first, then those with more words ("CA"); if no name has them, they count as small letters. Small
-- letters stay in a word: the names that start with them, those with a word that starts with them ("fi" -> Soul
-- Fire; a space goes on to the next word: "sh wo" -> Shadow Word: Pain), those that have them inside, those with
-- a word that has them in that order from its start ("nmd" -> nomod). A name typed in full keeps only the names
-- that start with it.
function Completion.Match(items, typed)
    local q = Lower(typed)
    local bare = q:gsub("%s+", "")
    local caps = Capitals(typed)
    local groups, full = { {}, {}, {}, {} }, false
    for _, item in ipairs(items) do
        local name = Lower(item.name)
        full = full or (not caps and name == q)
        local group = Group(name, q, bare, caps)
        if group then table.insert(groups[group], item) end
    end
    if caps and #groups[1] + #groups[2] == 0 then return Completion.Match(items, q) end
    local out = {}
    for _, group in ipairs(groups) do
        for _, item in ipairs(group) do
            if not full or Lower(item.name):find(q, 1, true) == 1 then out[#out + 1] = item end
        end
    end
    return out
end

-- The best fits first (see Match). Returns nothing when the word is already complete (the only match is the
-- word itself), except for a spell with several learned ranks: then its ranks (Esc keeps the plain name).
function Completion.Get(ctx)
    if not ctx then return {} end
    local prefix = ctx.prefix:lower()
    if ctx.kind == "rank" or ctx.kind == "action" then
        local spell = findSpell(ctx.kind == "rank" and ctx.spell or ctx.prefix)
        if spell and #spell.ranks >= 2 then
            if ctx.kind == "action" then return rankItems(spell, true) end
            local out = rankItems(spell, false, prefix ~= "" and prefix or nil)
            if #out == 1 and out[1].name:lower() == prefix then return {} end
            return out
        end
        if ctx.kind == "rank" then return {} end
    end
    local out = {}
    for _, item in ipairs(Completion.Match(list(ctx.kind, ctx), ctx.prefix)) do
        if #out >= Completion.limit then return out end
        out[#out + 1] = { name = item.name, hint = item.hint, icon = item.icon, insert = insertText(ctx.kind, item) }
    end
    if #out == 1 and Lower(out[1].name) == Lower(ctx.prefix) then return {} end
    return out
end

return Completion
