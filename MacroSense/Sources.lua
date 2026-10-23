-- Game data for completion: registered slash commands and the spellbook. Cached until the game says it changed.
local _, ns = ...

local commandCache, spellCache, itemCache

-- The Mac client also knows the Command key.
if IsMacClient and IsMacClient() then
    table.insert(ns.data.modifiers, 4, { name = "cmd", hint = "Mac" })
end

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
local hints = {}
for _, c in ipairs(ns.data.commands) do hints[c.name] = c.hint end

-- Every alias of a command key: SLASH_CAST1 = "/cast", SLASH_CAST2 = "/spell", ...
local function aliases(key)
    local out, i = {}, 1
    while _G["SLASH_" .. key .. i] do
        out[#out + 1] = _G["SLASH_" .. key .. i]:gsub("^/", ""):lower()
        i = i + 1
    end
    return out
end

-- Localized aliases of the action commands and /stopmacro go to the parser (/zaubern = /cast in German clients).
local ACTION_KEYS = {
    CAST = "cast", USE = "use", CASTSEQUENCE = "castsequence", CASTRANDOM = "castrandom",
    USERANDOM = "userandom", CANCELAURA = "cancelaura", EQUIP = "equip", EQUIP_TO_SLOT = "equipslot",
}
function ns.RegisterActionCommands()
    for key, base in pairs(ACTION_KEYS) do
        for _, name in ipairs(aliases(key)) do ns.Parser.actionCommands[name] = base end
    end
    for _, name in ipairs(aliases("STOPMACRO")) do ns.Parser.stopCommands[name] = true end
end

-- The game's own condition check for the live preview: SecureCmdOptionParse is what macros run with.
ns.previewEnv = {
    parse = function(options) return SecureCmdOptionParse(options) end,
    sequenceStep = QueryCastSequence and function(sequence) return QueryCastSequence(sequence) end,
}

-- Secure commands (/cast, /petmoveto, ...): the game keeps their list from addons, but each alias is a
-- global SLASH_<KEY><n>, and IsSecureCmd("/alias") tells whether this client has it. The keys come from
-- Blizzard's chat code of every client; Retail also has them in SLASH_COMMAND.
local SECURE_KEYS = {
    "ASSIST", "CANCELAURA", "CANCELFORM", "CANCELQUEUEDSPELL", "CAST", "CASTRANDOM", "CASTSEQUENCE",
    "CHANGEACTIONBAR", "CLEAR_WORLD_MARKER", "CLEARFOCUS", "CLEARTARGET", "CLICK", "DUEL", "DUEL_CANCEL",
    "DUEL_TO_THE_DEATH", "EQUIP", "EQUIP_SET", "EQUIP_TO_SLOT", "FOCUS", "GUILD_DEMOTE", "GUILD_DISBAND",
    "GUILD_LEADER", "GUILD_LEAVE", "GUILD_PROMOTE", "GUILD_UNINVITE", "LOGOUT", "MAINASSISTOFF", "MAINASSISTON",
    "MAINTANKOFF", "MAINTANKON", "PET_AGGRESSIVE", "PET_ASSIST", "PET_ATTACK", "PET_AUTOCASTOFF",
    "PET_AUTOCASTON", "PET_AUTOCASTTOGGLE", "PET_DEFENSIVE", "PET_DEFENSIVEASSIST", "PET_DISMISS", "PET_FOLLOW",
    "PET_MOVE_TO", "PET_PASSIVE", "PET_STAY", "QUIT", "STARTATTACK", "STOPATTACK", "STOPCASTING", "STOPMACRO",
    "STOPSPELLTARGET", "SWAPACTIONBAR", "TARGET", "TARGET_EXACT", "TARGET_LAST_ENEMY", "TARGET_LAST_FRIEND",
    "TARGET_LAST_TARGET", "TARGET_NEAREST_ENEMY", "TARGET_NEAREST_ENEMY_PLAYER", "TARGET_NEAREST_FRIEND",
    "TARGET_NEAREST_FRIEND_PLAYER", "TARGET_NEAREST_PARTY", "TARGET_NEAREST_RAID", "TEAM_CAPTAIN",
    "TEAM_DISBAND", "TEAM_INVITE", "TEAM_QUIT", "TEAM_UNINVITE", "USE", "USERANDOM", "WORLD_MARKER",
}

local function isSecure(name)
    return IsSecureCmd ~= nil and IsSecureCmd("/" .. name) and true or false
end

local function secureNames()
    local keys, out = {}, {}
    for _, key in ipairs(SECURE_KEYS) do keys[key] = true end
    for _, list in ipairs({ type(SLASH_COMMAND) == "table" and SLASH_COMMAND or {}, SecureCmdList or {} }) do
        for key in pairs(list) do keys[key] = true end
    end
    for key in pairs(keys) do
        for _, name in ipairs(aliases(key)) do
            if not IsSecureCmd or isSecure(name) then out[#out + 1] = name end
        end
    end
    return out
end

function ns.sources.commands()
    if commandCache then return commandCache end
    local seen, out = {}, {}
    local function add(name)
        if not seen[name] and not name:find("%s") then
            seen[name] = true
            out[#out + 1] = { name = name, hint = hints[name] }
        end
    end
    -- Common macro commands first, then everything the game and addons registered.
    for _, c in ipairs(ns.data.commands) do add(c.name) end
    local extra = secureNames()
    -- Chat types (/say) and emotes (/dance) are not in SlashCmdList.
    for _, cmdList in ipairs({ SlashCmdList, ChatTypeInfo or {} }) do
        for key in pairs(cmdList) do
            for _, name in ipairs(aliases(key)) do extra[#extra + 1] = name end
        end
    end
    for i = 1, 1000 do
        if _G["EMOTE" .. i .. "_TOKEN"] then
            for j = 1, 10 do
                local cmd = _G["EMOTE" .. i .. "_CMD" .. j]
                if cmd then extra[#extra + 1] = cmd:gsub("^/", ""):lower() end
            end
        end
    end
    table.sort(extra)
    for _, name in ipairs(extra) do add(name) end
    commandCache = out
    return out
end

-- Highlighting marks commands the game does not know.
local commandSet, commandSetFor
function ns.Highlight.isCommand(name)
    local list = ns.sources.commands()
    if commandSetFor ~= list then
        commandSet, commandSetFor = {}, list
        for _, c in ipairs(list) do commandSet[c.name] = true end
    end
    return commandSet[name] or isSecure(name)
end

------------------------------------------------------------------------
-- Spellbook (Retail C_SpellBook, older flavors GetSpellBookItem*)
------------------------------------------------------------------------
local function retailSpells(add)
    local bank = Enum.SpellBookSpellBank.Player
    for tab = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local line = C_SpellBook.GetSpellBookSkillLineInfo(tab)
        if line and not line.shouldHide then
            for slot = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
                local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                if item and item.itemType == Enum.SpellBookItemType.Spell and not item.isPassive then
                    add(item.name, item.iconID, item.subName)
                end
            end
        end
    end
end

local function classicSpells(add)
    local book = BOOKTYPE_SPELL or "spell"
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, count = GetSpellTabInfo(tab)
        for slot = offset + 1, offset + count do
            local kind = GetSpellBookItemInfo(slot, book)
            if kind == "SPELL" and not IsPassiveSpell(slot, book) then
                local name, sub = GetSpellBookItemName(slot, book)
                add(name, GetSpellBookItemTexture(slot, book), sub)
            end
        end
    end
end

function ns.sources.spells()
    if spellCache then return spellCache end
    local seen, out = {}, {}
    -- Older flavors list every learned rank: one entry per name, its ranks ("Rank 1", ...) in spellbook order.
    local function add(name, icon, sub)
        if not name then return end
        local spell = seen[name]
        if not spell then
            spell = { name = name, icon = icon, ranks = {} }
            seen[name] = spell
            out[#out + 1] = spell
        end
        if sub and sub ~= "" then table.insert(spell.ranks, sub) end
    end
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        retailSpells(add)
    else
        classicSpells(add)
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    spellCache = out
    return out
end

------------------------------------------------------------------------
-- Items in bags and equipped gear
------------------------------------------------------------------------
local Container = C_Container or {}
local NumSlots = Container.GetContainerNumSlots or GetContainerNumSlots
local ItemLink = Container.GetContainerItemLink or GetContainerItemLink
local ItemSpell = C_Item and C_Item.GetItemSpell or GetItemSpell
local Equippable = C_Item and C_Item.IsEquippableItem or IsEquippableItem
local ItemIcon = C_Item and C_Item.GetItemIconByID or GetItemIcon
local ItemCount = C_Item and C_Item.GetItemCount or GetItemCount
local LAST_BAG = (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4)

-- "[Name]" from a link, without quality / texture markup (crafted reagents carry an atlas icon).
local function linkName(link)
    local name = link and link:match("%[(.-)%]")
    return name and name:gsub("|A.-|a", ""):gsub("|T.-|t", ""):match("^%s*(.-)%s*$")
end

function ns.sources.items()
    if itemCache then return itemCache end
    local seen, out = {}, {}
    local function add(link, where)
        local name = linkName(link)
        if not name or name == "" or seen[name] then return end
        seen[name] = true
        local id = tonumber(link:match("item:(%d+)"))
        local count = id and ItemCount(id) or 0
        out[#out + 1] = {
            name = name, icon = id and ItemIcon(id),
            hint = where == "equipped" and "equipped" or (count > 1 and ("x" .. count) or "item"),
            usable = ItemSpell(link) ~= nil,
            equippable = Equippable(link) and true or false,
        }
    end
    for slot = 1, 19 do add(GetInventoryItemLink("player", slot), "equipped") end
    for bag = 0, LAST_BAG do
        for slot = 1, NumSlots(bag) or 0 do add(ItemLink(bag, slot), "bag") end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    -- Remember every item seen, so macros for items not in the bags right now still count as known.
    if ns.db then
        ns.db.itemNames = ns.db.itemNames or {}
        for _, item in ipairs(out) do ns.db.itemNames[item.name] = true end
    end
    itemCache = out
    return out
end

------------------------------------------------------------------------
-- Condition values: forms, specializations, item types, pet
------------------------------------------------------------------------
local SpellName = C_Spell and C_Spell.GetSpellName or function(id) return GetSpellInfo and (GetSpellInfo(id)) end

-- "form:1" -> Bear Form ... (whatever the class has; Classic returns the name directly).
function ns.sources.forms()
    local out = { { name = "0", hint = "no form" } }
    for i = 1, GetNumShapeshiftForms and GetNumShapeshiftForms() or 0 do
        local icon, a, _, _, e = GetShapeshiftFormInfo(i)
        local name = type(a) == "string" and a or nil
        local spellID = type(a) == "string" and e or select(4, GetShapeshiftFormInfo(i))
        out[#out + 1] = { name = tostring(i), hint = name or (spellID and SpellName(spellID)), icon = icon }
    end
    return out
end

function ns.sources.specs()
    local out = {}
    if GetNumSpecializations and GetSpecializationInfo then
        for i = 1, GetNumSpecializations() do
            local _, name, _, icon = GetSpecializationInfo(i)
            out[#out + 1] = { name = tostring(i), hint = name, icon = icon }
        end
    end
    if #out == 0 then -- Classic: dual talent specs
        out = { { name = "1", hint = "primary" }, { name = "2", hint = "secondary" } }
    end
    return out
end

-- Weapon and armor types for "equipped:", in the client's language.
local itemTypeCache
local SubClassInfo = C_Item and C_Item.GetItemSubClassInfo or GetItemSubClassInfo
local ClassInfo = C_Item and C_Item.GetItemClassInfo or GetItemClassInfo
function ns.sources.itemTypes()
    if itemTypeCache then return itemTypeCache end
    local out, seen = {}, {}
    local function add(name, hint)
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            out[#out + 1] = { name = name, hint = hint }
        end
    end
    for _, class in ipairs({ { 2, 20 }, { 4, 11 } }) do
        local className = ClassInfo and ClassInfo(class[1])
        add(className)
        for sub = 0, class[2] do add(SubClassInfo and SubClassInfo(class[1], sub), className) end
    end
    itemTypeCache = out
    return out
end

-- "pet:" takes your pet's name or family.
function ns.sources.pets()
    local out = {}
    if UnitExists and UnitExists("pet") then
        local name = UnitName("pet")
        if name then out[#out + 1] = { name = name, hint = "your pet" } end
        local family = UnitCreatureFamily("pet")
        if family then out[#out + 1] = { name = family, hint = "pet family" } end
    end
    return out
end

------------------------------------------------------------------------
-- Known names for the typo check: your spells, your pets' spells, items, mounts
------------------------------------------------------------------------
local PetBank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet

-- Spells of the pet that is out now (any flavor).
local function petSpellNames()
    local out = {}
    if C_SpellBook and C_SpellBook.HasPetSpells and PetBank then
        for i = 1, C_SpellBook.HasPetSpells() or 0 do
            local name = C_SpellBook.GetSpellBookItemName(i, PetBank)
            if name then out[#out + 1] = name end
        end
    elseif HasPetSpells and GetSpellBookItemName then
        for i = 1, HasPetSpells() or 0 do
            local name = GetSpellBookItemName(i, BOOKTYPE_PET or "pet")
            if name then out[#out + 1] = name end
        end
    end
    return out
end

-- Collected mounts (Retail); older flavors have mounts as spells or items.
local function mountNames()
    local out = {}
    if C_MountJournal and C_MountJournal.GetMountIDs then
        for _, id in ipairs(C_MountJournal.GetMountIDs()) do
            local name, _, _, _, _, _, _, _, _, _, collected = C_MountJournal.GetMountInfoByID(id)
            if name and collected then out[#out + 1] = name end
        end
    end
    return out
end

local knownCache, guesses
-- { set = { lowercase name = true }, list = { names }, items = { item names } }
function ns.KnownActions()
    if knownCache then return knownCache end
    local set, list, items = {}, {}, {}
    local function add(name, isItem)
        if not name or name == "" then return end
        local key = name:lower()
        if not set[key] then
            set[key] = true
            list[#list + 1] = name
        end
        if isItem then items[#items + 1] = name end
    end
    for _, spell in ipairs(ns.sources.spells()) do add(spell.name) end
    -- A pet's spells are only in its spellbook while it is out: remember those of every pet seen.
    local petSpells = ns.char and ns.char.petSpells or {}
    for _, name in ipairs(petSpellNames()) do petSpells[name] = true end
    for name in pairs(petSpells) do add(name) end
    for _, item in ipairs(ns.sources.items()) do add(item.name, true) end
    for name in pairs(ns.db and ns.db.itemNames or {}) do add(name, true) end
    for _, name in ipairs(mountNames()) do add(name) end
    table.sort(list)
    table.sort(items)
    knownCache, guesses = { set = set, list = list, items = items }, {}
    return knownCache
end

-- A name that is not known but close to a known one is likely a typo. Names nothing is close to stay
-- unmarked: they may be spells of another spec or pet, items not in the bags, toys...
function ns.Highlight.checkAction(name, command)
    if name:find("^%d") or name:find("^item:") then return nil end -- slots, item links
    local known = ns.KnownActions()
    if known.set[name:lower()] then return nil end
    local key = command .. "\1" .. name
    if guesses[key] == nil then
        local pool = (command == "equip" or command == "equipslot") and known.items or known.list
        guesses[key] = ns.Spelling.Suggest(name, pool) or false
    end
    local guess = guesses[key]
    if not guess then return nil end
    return {
        message = string.format('unknown name "%s", did you mean "%s"?', name, guess),
        short = string.format('did you mean "%s"?', guess),
        fix = guess,
    }
end

function ns.InvalidateSources(what)
    if not what or what == "commands" then commandCache = nil end
    if not what or what == "spells" then spellCache = nil end
    if not what or what == "items" then itemCache = nil end
    if what ~= "commands" then knownCache = nil end
end
