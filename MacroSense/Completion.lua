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

-- Prefix matches first, then substring matches; both keep the source order.
-- Returns nothing when the word is already complete (the only match is the word itself),
-- except for a spell with several learned ranks: then its ranks (Esc keeps the plain name).
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
    local starts, contains = {}, {}
    for _, item in ipairs(list(ctx.kind, ctx)) do
        local at = prefix == "" and 1 or item.name:lower():find(prefix, 1, true)
        if at == 1 then
            starts[#starts + 1] = item
        elseif at then
            contains[#contains + 1] = item
        end
    end
    -- A word typed in full: longer words that start with it still help, matches inside other words not.
    for _, item in ipairs(starts) do
        if item.name:lower() == prefix then contains = {} break end
    end
    local out = {}
    for _, group in ipairs({ starts, contains }) do
        for _, item in ipairs(group) do
            if #out >= Completion.limit then return out end
            out[#out + 1] = { name = item.name, hint = item.hint, icon = item.icon, insert = insertText(ctx.kind, item) }
        end
    end
    if #out == 1 and out[1].name:lower() == prefix then return {} end
    return out
end

return Completion
