-- Game data for completion: registered slash commands and the spellbook. Cached until the game says it changed.
local _, ns = ...
local L = ns.L

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
    for _, name in ipairs(aliases("CLICK")) do ns.Parser.clickCommands[name] = true end
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

-- Commands whose text goes through the game's condition check: the action commands, /stopmacro and the
-- other secure commands (/petattack, /target, ...).
function ns.IsConditionalCommand(name)
    local P = ns.Parser
    return P.actionCommands[name] ~= nil or P.stopCommands[name] == true or isSecure(name)
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

-- Commands every client has, but the game only carries out from an expansion on: the pet's Move To came with
-- Cataclysm (3). LE_EXPANSION_LEVEL_CURRENT is the client's: 0 Classic Era, 1 TBC, 4 Mists of Pandaria.
local LATER = { PET_MOVE_TO = 3 }

-- The expansion a command (any of its names) came with, or nil.
function ns.CommandSince(name)
    for key, since in pairs(LATER) do
        for _, alias in ipairs(aliases(key)) do
            if alias == name then return since end
        end
    end
end

-- Whether this client's game carries out what came with `since` (unknown clients do).
function ns.HasExpansion(since)
    return not since or (LE_EXPANSION_LEVEL_CURRENT or since) >= since
end

function ns.Highlight.checkCommand(name)
    if ns.HasExpansion(ns.CommandSince(name)) then return nil end
    return string.format(L["\"/%s\" does nothing in this version of the game (it came with a later one)"], name),
        L["not in this game version"]
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

-- Equipment slots with what is in them now: "13" -> "Trinket 1: Healthstone".
function ns.sources.slots()
    local out = {}
    for _, s in ipairs(ns.data.slots) do
        local item = linkName(GetInventoryItemLink("player", tonumber(s.name)))
        out[#out + 1] = { name = s.name, hint = item and (L[s.hint] .. ": " .. item) or s.hint }
    end
    return out
end

-- What is in an equipment slot: its name and whether it has a use effect.
function ns.sources.equipped(slot)
    local link = GetInventoryItemLink("player", slot)
    return linkName(link), link ~= nil and ItemSpell(link) ~= nil
end

-- Whether a spell or item is for friends or enemies, when the game knows: "friends", "enemies" or nil. Nil too when
-- it says both (Holy Shock heals friends and hurts enemies).
local IsHelpful = C_Spell and C_Spell.IsSpellHelpful or IsHelpfulSpell
local IsHarmful = C_Spell and C_Spell.IsSpellHarmful or IsHarmfulSpell
local IsHelpfulItem = C_Item and C_Item.IsHelpfulItem or IsHelpfulItem
local IsHarmfulItem = C_Item and C_Item.IsHarmfulItem or IsHarmfulItem
function ns.sources.reaction(name, item)
    local helpful, harmful = IsHelpful, IsHarmful
    if item then helpful, harmful = IsHelpfulItem, IsHarmfulItem end
    -- pcall: a name the game doesn't know (a spell of another spec) may be refused.
    local function says(fn) return fn ~= nil and select(2, pcall(fn, name)) == true end
    local harm, help = says(harmful), says(helpful)
    if harm ~= help then return harm and "enemies" or "friends" end
end

-- The slots of a bag that hold something, with its name: "/use 0 1".
function ns.sources.bagSlots(bag)
    local out = {}
    for slot = 1, NumSlots(bag) or 0 do
        local item = linkName(ItemLink(bag, slot))
        if item then out[#out + 1] = { name = tostring(slot), hint = item } end
    end
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
-- /click: the buttons there are now, with what is on them
------------------------------------------------------------------------
-- Names of bar buttons: the game's bars, then those of Bartender4 and Dominos (ElvUI below).
local CLICK_BARS = {
    { "ActionButton%d", 12 }, { "MultiBarBottomLeftButton%d", 12 }, { "MultiBarBottomRightButton%d", 12 },
    { "MultiBarRightButton%d", 12 }, { "MultiBarLeftButton%d", 12 }, { "MultiBar5Button%d", 12 },
    { "MultiBar6Button%d", 12 }, { "MultiBar7Button%d", 12 }, { "PetActionButton%d", 10 }, { "StanceButton%d", 10 },
    { "BT4Button%d", 180 }, { "DominosActionButton%d", 180 },
}
local CLICK_OTHERS = {
    { "ExtraActionButton1", "extra action" }, { "MainMenuBarVehicleLeaveButton", "leave the vehicle" },
    { "StaticPopup1Button1", "popup: first button" }, { "StaticPopup1Button2", "popup: second button" },
}
local ItemNameByID = C_Item and C_Item.GetItemNameByID or function(id) return GetItemInfo and (GetItemInfo(id)) end
local GetActionText = C_ActionBar and C_ActionBar.GetActionText or GetActionText

-- A button /click can click (the game checks the same). pcall: _G holds all kinds of things.
local function clickable(frame)
    if type(frame) ~= "table" then return false end
    local ok, yes = pcall(function()
        return frame:IsObjectType("Button") and not (frame.IsForbidden and frame:IsForbidden())
    end)
    return ok and yes and true or false
end

-- What a bar button does now: the spell, item or macro on its action slot.
local function onButton(button)
    local slot = button.action or button._state_action -- the game's bars; LibActionButton (Bartender4, ElvUI)
    if type(slot) ~= "number" and button.GetAttribute then slot = button:GetAttribute("action") end
    if type(slot) ~= "number" then return nil end
    local kind, id = GetActionInfo(slot)
    if kind == "spell" then return SpellName(id) end
    if kind == "item" then return ItemNameByID(id) end
    -- The name the button shows: for a macro that shows a spell, id is the spell's.
    if kind == "macro" then return GetActionText(slot) end
end

local function buttonHint(pattern, i, button)
    if pattern == "PetActionButton%d" then
        local name, _, isToken = GetPetActionInfo(i)
        return isToken and _G[name] or name -- "PET_ACTION_ATTACK" -> "Attack"
    elseif pattern == "StanceButton%d" then
        local _, a = GetShapeshiftFormInfo(i)
        if type(a) == "string" then return a end -- Classic: the name
        local spellID = select(4, GetShapeshiftFormInfo(i))
        return spellID and SpellName(spellID)
    end
    return onButton(button)
end

function ns.sources.clickButtons()
    local out = {}
    local function add(name, hint)
        if clickable(_G[name]) then out[#out + 1] = { name = name, hint = hint } end
    end
    for _, bar in ipairs(CLICK_BARS) do
        for i = 1, bar[2] do
            local name = bar[1]:format(i)
            local button = _G[name]
            if clickable(button) then out[#out + 1] = { name = name, hint = buttonHint(bar[1], i, button) } end
        end
    end
    for bar = 1, 15 do
        for i = 1, 12 do
            local name = string.format("ElvUI_Bar%dButton%d", bar, i)
            if clickable(_G[name]) then out[#out + 1] = { name = name, hint = onButton(_G[name]) } end
        end
    end
    for _, other in ipairs(CLICK_OTHERS) do add(other[1], other[2]) end
    return out
end

-- "/click Name": a warning when no button has that name now (an addon may still make it, so not an error).
function ns.Highlight.checkClick(name)
    if name:find("[%.:]") then return nil end -- not a plain global name: left to the game
    local frame = _G[name]
    if frame == nil then
        return string.format(L["no button \"%s\" now (an addon may make it later)"], name), L["no such button now"]
    end
    if not clickable(frame) then
        return string.format(L["\"%s\" is not a button /click can click"], name), L["not a button /click can click"]
    end
end

------------------------------------------------------------------------
-- Known names for the typo check: your spells, your pets' spells, items, mounts
------------------------------------------------------------------------
local PetBank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet

-- Spells of the pet that is out now. The Classic clients have C_SpellBook too, but only HasPetSpells and
-- a few others there: the names come from the old functions.
local function petSpellNames()
    local out = {}
    if C_SpellBook and C_SpellBook.HasPetSpells and C_SpellBook.GetSpellBookItemName and PetBank then
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
local sourcesFailed -- the typo check could not read a source once: reported then, not again
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
    for name in pairs(ns.char and ns.char.buffs or {}) do add(name) end
    table.sort(list)
    table.sort(items)
    knownCache, guesses = { set = set, list = list, items = items }, {}
    return knownCache
end

-- A name that is not known but close to a known one is likely a typo. Names nothing is close to stay
-- unmarked: they may be spells of another spec or pet, items not in the bags, toys...
function ns.Highlight.checkAction(name, command)
    if name:find("^%d") or name:find("^item:") then return nil end -- slots, item links
    -- A source that fails (a game function this client doesn't have) costs the typo check, not the editor.
    local ok, known = pcall(ns.KnownActions)
    if not ok then
        if not sourcesFailed then
            sourcesFailed = true
            geterrorhandler()(known)
        end
        knownCache, guesses = { set = {}, list = {}, items = {} }, {}
        return nil
    end
    if known.set[name:lower()] then return nil end
    local key = command .. "\1" .. name
    if guesses[key] == nil then
        local pool = (command == "equip" or command == "equipslot") and known.items or known.list
        guesses[key] = ns.Spelling.Suggest(name, pool) or false
    end
    local guess = guesses[key]
    if not guess then return nil end
    return {
        message = string.format(L["unknown name \"%s\", did you mean \"%s\"?"], name, guess),
        short = string.format(L["did you mean \"%s\"?"], guess),
        fix = guess,
    }
end

------------------------------------------------------------------------
-- Buffs for /cancelaura: those on you now, then those you have had (kept for each character)
------------------------------------------------------------------------
local GetAura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
ns.BUFFS_KEPT = 200 -- buff names kept for a character: the ones seen last

-- The buffs on you now: { name = icon }. Retail may hide aura data from addons (a secret value): those are left out.
local function BuffsNow()
    local out = {}
    if not GetAura then return out end
    for i = 1, 40 do
        local ok, aura = pcall(GetAura, "player", i, "HELPFUL")
        if not ok or not aura then break end
        local name, icon = aura.name, aura.icon
        local secret = issecretvalue and (issecretvalue(name) or issecretvalue(icon))
        if type(name) == "string" and name ~= "" and not secret then out[name] = icon end
    end
    return out
end

-- Keeps the buffs in `now` with when they were seen, and forgets the oldest past BUFFS_KEPT.
local function Remember(now)
    local kept = ns.char and ns.char.buffs
    if not kept then return end
    local seen, added = time(), false
    for name, icon in pairs(now) do
        added = added or kept[name] == nil
        kept[name] = { icon = icon, seen = seen }
    end
    if added then ns.InvalidateSources("buffs") end -- the typo check knows them as names
    local names = {}
    for name in pairs(kept) do names[#names + 1] = name end
    if #names <= ns.BUFFS_KEPT then return end
    table.sort(names, function(a, b) return kept[a].seen > kept[b].seen end)
    for i = ns.BUFFS_KEPT + 1, #names do kept[names[i]] = nil end
end

function ns.RememberBuffs() Remember(BuffsNow()) end

-- What /cancelaura takes: the buffs on you now, then those you have had, each group by name.
function ns.sources.buffs()
    local now = BuffsNow()
    Remember(now)
    local onYou, had = {}, {}
    for name, icon in pairs(now) do onYou[#onYou + 1] = { name = name, icon = icon, hint = "on you now" } end
    for name, b in pairs(ns.char and ns.char.buffs or {}) do
        if not now[name] then had[#had + 1] = { name = name, icon = b.icon, hint = "buff" } end
    end
    local function byName(a, b) return a.name < b.name end
    table.sort(onYou, byName)
    table.sort(had, byName)
    for _, b in ipairs(had) do onYou[#onYou + 1] = b end
    return onYou
end

function ns.InvalidateSources(what)
    if not what or what == "commands" then commandCache = nil end
    if not what or what == "spells" then spellCache = nil end
    if not what or what == "items" then itemCache = nil end
    if what ~= "commands" then knownCache = nil end
end
