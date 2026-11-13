-- Items your spells make, a better one with each rank: a warlock's stones (Minor Healthstone to Major, Master in
-- TBC), a mage's water and food. When you can make a better one than a macro uses, MacroSense offers to put it in
-- that macro. Classic Era, TBC and WoW Forever: the later games make one item at every level.
local _, ns = ...
ns = ns or {}
local L = ns.L

local Conjured = {}
ns.Conjured = Conjured

-- Each kind by its ranks, worst first: the spell of the rank and the item it makes (the game's tables of Classic
-- Era 1.15.9, TBC 2.5.6 and WoW Forever 1.60.1). A healthstone of each rank is three items, by the talent, with one
-- name: macros name it. Mana gems are left out: a mage keeps one of each and uses them all.
Conjured.KINDS = {
    { -- Create Healthstone: Minor, Lesser, Healthstone, Greater, Major, Master
        { spell = 6201, item = 5512 }, { spell = 6202, item = 5511 }, { spell = 5699, item = 5509 },
        { spell = 11729, item = 5510 }, { spell = 11730, item = 9421 }, { spell = 27230, item = 22103 },
    },
    { -- Create Soulstone
        { spell = 693, item = 5232 }, { spell = 20752, item = 16892 }, { spell = 20755, item = 16893 },
        { spell = 20756, item = 16895 }, { spell = 20757, item = 16896 }, { spell = 27238, item = 22116 },
    },
    { -- Create Spellstone
        { spell = 2362, item = 5522 }, { spell = 17727, item = 13602 }, { spell = 17728, item = 13603 },
        { spell = 28172, item = 22646 },
    },
    { -- Create Firestone
        { spell = 6366, item = 1254 }, { spell = 17951, item = 13699 }, { spell = 17952, item = 13700 },
        { spell = 17953, item = 13701 }, { spell = 27250, item = 22128 },
    },
    { -- Conjure Water: Conjured Water to Crystal Water, then Mountain Spring Water and Glacier Water
        { spell = 5504, item = 5350 }, { spell = 5505, item = 2288 }, { spell = 5506, item = 2136 },
        { spell = 6127, item = 3772 }, { spell = 10138, item = 8077 }, { spell = 10139, item = 8078 },
        { spell = 10140, item = 8079 }, { spell = 37420, item = 30703 }, { spell = 27090, item = 22018 },
    },
    { -- Conjure Food: Conjured Muffin to Cinnamon Roll, then Croissant
        { spell = 587, item = 5349 }, { spell = 597, item = 1113 }, { spell = 990, item = 1114 },
        { spell = 6129, item = 1487 }, { spell = 10144, item = 8075 }, { spell = 10145, item = 8076 },
        { spell = 28612, item = 22895 }, { spell = 33717, item = 22019 },
    },
}

-- The commands that use, cast or put on what they name, by their English names (the client's own:
-- Parser.actionCommands).
local USES = { cast = true, use = true, castsequence = true, castrandom = true, userandom = true, equip = true,
    equipslot = true }

-- Where `line` names what it uses: { from, to } of each name, after those commands and #show. Not a condition, a
-- reset, a slot's number, a "!" or a line said in chat.
local function NameSpans(line)
    local base, list, slot
    local meta = line:match("^%s*#show%a*")
    if meta then
        base = #meta
    else
        local head, command = line:match("^(%s*/(%S+))")
        local action = head and ns.Parser.actionCommands[command:lower()]
        if not USES[action or ""] then return {} end
        base = #head
        list = action == "castsequence" or action == "castrandom" or action == "userandom"
        slot = action == "equipslot"
    end
    local s, out, i = line:sub(base + 1), {}, 1
    while i <= #s do
        local c = s:sub(i, i)
        if c == "[" then
            i = (s:find("]", i + 1, true) or #s) + 1
        elseif c == ";" or c == "," or c:find("%s") then
            i = i + 1
        else
            local stop = (s:find(list and "[;,%[]" or "[;%[]", i) or #s + 1) - 1
            local word = s:sub(i, stop)
            local skip = #(word:match("^reset=%S*%s*") or "")
            if slot then skip = skip + #(word:sub(skip + 1):match("^%d+%s+") or "") end
            skip = skip + #(word:sub(skip + 1):match("^!") or "")
            local name = word:sub(skip + 1):match("^(.-)%s*$")
            if name ~= "" then out[#out + 1] = { from = base + i + skip, to = base + i + skip + #name - 1 } end
            i = stop + 1
        end
    end
    return out
end

-- `body` with the names in `swap` (lowercase old name -> new name) put in where the macro uses them, and how many.
function Conjured.Swap(body, swap)
    local count, lines = 0, {}
    for each in ((body or "") .. "\n"):gmatch("([^\n]*)\n") do
        local line, spans = each, NameSpans(each)
        for k = #spans, 1, -1 do
            local new = swap[line:sub(spans[k].from, spans[k].to):lower()]
            if new then
                line = line:sub(1, spans[k].from - 1) .. new .. line:sub(spans[k].to + 1)
                count = count + 1
            end
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n"), count
end

-- The best of `names` (a kind's items by rank, worst first; false where the game hasn't told one yet) that `body`
-- uses: its rank, or nil.
function Conjured.Top(body, names)
    local used = {}
    for line in (body or ""):gmatch("[^\n]+") do
        for _, sp in ipairs(NameSpans(line)) do used[line:sub(sp.from, sp.to):lower()] = true end
    end
    for k = #names, 1, -1 do
        if names[k] and used[names[k]:lower()] then return k end
    end
end

-- Only the clients with ranks: Classic Era and WoW Forever (0), TBC (1).
local function HasRanks()
    return LE_EXPANSION_LEVEL_CURRENT ~= nil and LE_EXPANSION_LEVEL_CURRENT <= 1
end

local function Knows(spell)
    local known = C_SpellBook and C_SpellBook.IsSpellKnown or IsSpellKnown or IsPlayerSpell
    local ok, yes = pcall(known, spell)
    return ok and yes == true
end

local waiting -- names asked of the game: the next look comes when one arrives

-- An item's name in the game's language, or nil until the game has it: with `ask`, it is asked for then. Those of the
-- ranks you don't know yet are not: Classic Era has no Master Healthstone.
local function NameOf(id, ask)
    local get = C_Item and C_Item.GetItemNameByID or GetItemInfo
    local ok, name = pcall(get, id)
    if ok and type(name) == "string" and name ~= "" then return name end
    if not ask then return nil end
    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
    waiting = true
end

-- The kinds whose best item you make is better than one your macros use, each with those macros:
-- { new = its name, item = its ID, old = { the names in them }, macros = { { index, name, general, old } } }. A macro
-- that has the best already, or a better one than you make (stones from another warlock), is left alone; one with a
-- worse one after its best (a fallback) gets only its best changed.
function Conjured.Outdated()
    local out = {}
    if not HasRanks() then return out end
    local general, character = GetNumMacros()
    for _, kind in ipairs(Conjured.KINDS) do
        local best
        for k = #kind, 1, -1 do
            if Knows(kind[k].spell) then
                best = k
                break
            end
        end
        local new = best and best > 1 and NameOf(kind[best].item, true)
        if new then
            local names, entry, olds = {}, { new = new, item = kind[best].item, old = {}, macros = {} }, {}
            for k = 1, #kind do names[k] = k == best and new or NameOf(kind[k].item, k < best) or false end
            local function look(index)
                local name, _, body = GetMacroInfo(index)
                local top = Conjured.Top(body, names)
                if not (top and top < best) then return end
                local old = names[top]
                entry.macros[#entry.macros + 1] = { index = index, name = name, general = index <= ns.MAX_GENERAL,
                    old = old }
                if not olds[old] then
                    olds[old] = true
                    entry.old[#entry.old + 1] = old
                end
            end
            for index = 1, general do look(index) end
            for index = ns.MAX_GENERAL + 1, ns.MAX_GENERAL + character do look(index) end
            if #entry.macros > 0 then out[#out + 1] = entry end
        end
    end
    return out
end

-- The popup's list: "Major Healthstone instead of Greater Healthstone: Heal, Panic (for all characters)".
function Conjured.Describe(list)
    local lines = {}
    for _, kind in ipairs(list) do
        local names = {}
        for _, m in ipairs(kind.macros) do
            names[#names + 1] = m.general and string.format(L["%s (for all characters)"], m.name) or m.name
        end
        lines[#lines + 1] = string.format(L["%s instead of %s: %s"], kind.new, table.concat(kind.old, ", "),
            table.concat(names, ", "))
    end
    return table.concat(lines, "\n")
end

local due -- a look or an update that waits for the end of combat: true, or the list to put in

-- Puts the new items in the macros of `list` (Outdated), out of combat; those offered are not offered again.
function Conjured.Apply(list)
    if InCombatLockdown() then
        due = list
        return
    end
    local swaps, order = {}, {}
    for _, kind in ipairs(list) do
        ns.char.conjured[kind.item] = true
        for _, m in ipairs(kind.macros) do
            if not swaps[m.index] then
                swaps[m.index] = { name = m.name, swap = {} }
                order[#order + 1] = m.index
            end
            swaps[m.index].swap[m.old:lower()] = kind.new
        end
    end
    for _, index in ipairs(order) do
        local name, _, body = GetMacroInfo(index)
        if name == swaps[index].name then
            local text, count = Conjured.Swap(body, swaps[index].swap)
            if count > 0 then EditMacro(index, nil, nil, text) end
        end
    end
end

StaticPopupDialogs.MACROSENSE_CONJURED = {
    text = "You can make better items now than some of your macros use:\n\n%s\n\nPut the new ones in these macros?",
    button1 = "Update", button2 = "Not now",
    OnAccept = function(_, list) Conjured.Apply(list) end,
    -- Not now: not offered again until a better one comes.
    OnCancel = function(_, list, reason)
        if reason == "override" or reason == "timeout" then return end
        for _, kind in ipairs(list or {}) do ns.char.conjured[kind.item] = true end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- Spells or macros changed, or the game told a name: the kinds with a better item than macros use, not offered yet,
-- are offered. Not in combat: after it.
function Conjured.Check()
    if not (ns.char and ns.char.conjured) then return end
    if InCombatLockdown() then
        due = due or true
        return
    end
    if StaticPopup_Visible and StaticPopup_Visible("MACROSENSE_CONJURED") then return end
    waiting = false
    local list = {}
    for _, kind in ipairs(Conjured.Outdated()) do
        if not ns.char.conjured[kind.item] then list[#list + 1] = kind end
    end
    if #list > 0 then ns.Ask("MACROSENSE_CONJURED", Conjured.Describe(list), nil, list) end
end

-- Combat ended: what waited for it.
function Conjured.CombatEnded()
    local list = due
    due = nil
    if type(list) == "table" then Conjured.Apply(list) elseif list then Conjured.Check() end
end

-- The game told an item's name: a look once the names asked for have come.
local soon
function Conjured.ItemArrived()
    if not waiting or soon then return end
    soon = true
    C_Timer.After(1, function()
        soon = false
        Conjured.Check()
    end)
end

return Conjured
