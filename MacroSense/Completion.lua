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
    if cmd == "cancelaura" then return source("spells") end
    if cmd == "use" or cmd == "userandom" then return concat(items("usable"), source("spells")) end
    return concat(source("spells"), items("usable"))
end

local function list(kind, ctx)
    local d = ns.data
    if kind == "command" then return ns.sources.commands and ns.sources.commands() or d.commands end
    if kind == "meta" then return d.meta end
    if kind == "condition" then return d.conditions end
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
    for _, i in ipairs(WordStarts(name)) do out[#out + 1] = name:match("^[^\128-\191][\128-\191]*", i) end
    return table.concat(out)
end

-- Whether `q` is made of beginnings of words of `name`, in order: each word used gives its first letters, and
-- words may be left out. "da" -> "demon armor", "shwp" -> "shadow word: pain", "ca" -> "curse of agony".
local function ByWords(name, q)
    local starts = WordStarts(name)
    local function from(i, w)
        if i > #q then return true end
        for k = w, #starts do
            local at, n = starts[k], 0
            while i + n <= #q and name:byte(at + n) == q:byte(i + n) do
                n = n + 1
                if from(i + n, k + 1) then return true end
            end
        end
        return false
    end
    return from(1, 1)
end

-- The items whose names fit what was typed, best first, each group in the list's order: those it is the
-- initials of ("da" -> Demon Armor), those that start with it, those whose words it begins ("ca" -> Curse of
-- Agony), those that have it inside. Case doesn't count, spaces typed between words neither. A name typed in
-- full keeps only the names that start with it.
function Completion.Match(items, typed)
    local q = typed:lower()
    local bare = q:gsub("%s+", "")
    local groups, full = { {}, {}, {}, {} }, false
    for _, item in ipairs(items) do
        local name = item.name:lower()
        local at = q == "" and 1 or name:find(q, 1, true)
        full = full or name == q
        local group = (#bare >= 2 and Initials(name) == bare and 1) or (at == 1 and 2)
            or (bare ~= "" and ByWords(name, bare) and 3) or (at and 4)
        if group then table.insert(groups[group], item) end
    end
    local out = {}
    for _, group in ipairs(groups) do
        for _, item in ipairs(group) do
            if not full or item.name:lower():find(q, 1, true) == 1 then out[#out + 1] = item end
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
    if #out == 1 and out[1].name:lower() == prefix then return {} end
    return out
end

return Completion
