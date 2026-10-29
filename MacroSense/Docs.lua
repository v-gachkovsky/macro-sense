-- What a word of a macro means, for the tooltip of the word under the mouse: a command, a condition, a unit,
-- #showtooltip, reset=. A spell or item name is the game's own tooltip (Window). Pure Lua (5.1).
local _, ns = ...
ns = ns or {}
local L = ns.L

local Docs = {}
ns.Docs = Docs

local COMMANDS = {
    cast = "Casts a spell or uses an item by its name. Branches split by \";\" are tried in order: the first whose "
        .. "conditions hold runs.",
    use = "Uses an item: by name, item:ID, an equipment slot (13, 14 for trinkets) or a bag and slot (0 1). Spells "
        .. "work too, as with /cast.",
    castsequence = "Casts the next spell of the list on each press. reset= says when it starts over: after seconds "
        .. "without a press, a new target, the end of combat, or Shift, Ctrl, Alt held.",
    castrandom = "Casts one spell of the list, picked at random.",
    userandom = "Uses one item of the list, picked at random (mounts, toys).",
    stopcasting = "Stops the spell you are casting, so the line after it can cast at once.",
    stopmacro = "Stops the macro here when its conditions hold: the lines below it don't run.",
    startattack = "Starts auto attack on your target, or on the unit given. It never turns auto attack off.",
    stopattack = "Stops auto attack.",
    cancelaura = "Removes a buff from you, by its name.",
    cancelform = "Leaves your form or stance (Bear Form, Shadowform...).",
    target = "Targets a unit, or the nearest player or creature with that name.",
    targetenemy = "Targets the next enemy in front of you, as Tab does.",
    targetfriend = "Targets the next friendly player.",
    targetlasttarget = "Targets your previous target again.",
    cleartarget = "Clears your target.",
    assist = "Targets the target of a unit: /assist [@focus] takes your focus's target.",
    focus = "Sets your focus: the unit given, or your target. A focus stays while you target others.",
    clearfocus = "Clears your focus.",
    petattack = "Your pet attacks your target, or the unit given.",
    petfollow = "Your pet comes back and follows you.",
    petstay = "Your pet stays where it is.",
    petpassive = "Your pet doesn't attack by itself.",
    petdefensive = "Your pet attacks what attacks you or it.",
    petassist = "Your pet attacks what you attack.",
    equip = "Puts on an item from your bags, in the slot it goes to.",
    equipslot = "Puts on an item in the slot given: /equipslot 14 Name for the second trinket.",
    click = "Clicks a button by its frame name, as if you pressed it: /click ActionButton1.",
    dismount = "Gets you off your mount.",
    leavevehicle = "Leaves the vehicle you are in.",
    run = "Runs a line of Lua code. Addons' code can't cast spells, so this can't either.",
    say = "Says the text in chat, to players near you. %t is your target's name.",
    yell = "Yells the text in chat, to players in a wide area. %t is your target's name.",
    party = "Says the text in your party's chat. %t is your target's name.",
    raid = "Says the text in your raid's chat. %t is your target's name.",
    emote = "Shows the text as your emote: \"Bob waves.\" %t is your target's name.",
    whisper = "Whispers the text to one player: /whisper Name text.",
}
COMMANDS.script = COMMANDS.run

local CONDITIONS = {
    combat = "You are in combat.",
    mod = "A modifier key is held: mod:shift, mod:ctrl, mod:alt, several with \"/\". Without a value, any of them.",
    harm = "The unit is an enemy you can attack.",
    help = "The unit is friendly: you can heal or buff it.",
    exists = "The unit is there. With nobody under the mouse, @mouseover is not.",
    dead = "The unit is dead.",
    form = "Your form or stance, by its number: form:1, form:2/3. form:0 or noform: no form.",
    stealth = "You are in stealth.",
    mounted = "You are on a mount.",
    flying = "You are flying.",
    flyable = "You can fly here: the zone allows it.",
    advflyable = "Skyriding is allowed here.",
    swimming = "You are swimming.",
    indoors = "You are indoors, where mounts can't be summoned.",
    outdoors = "You are outdoors.",
    resting = "You are in a rested area: an inn or a city.",
    channeling = "You are channeling a spell, any or the one named: channeling:Drain Life.",
    group = "You are in a group: group:party or group:raid.",
    party = "The unit is in your party.",
    raid = "The unit is in your raid.",
    pet = "Your pet is out, or that one: pet:Felhunter, pet:Imp/Voidwalker.",
    spec = "Your active specialization: spec:1, spec:2...",
    known = "You know that spell: known:Name or its number.",
    talent = "That talent is chosen: talent:row/column.",
    pvptalent = "That PvP talent is chosen.",
    equipped = "You wear that kind of item: equipped:Shields, equipped:Two-Handed Axes.",
    btn = "The mouse button that clicked the action button: btn:1 left, btn:2 right.",
    bar = "The page of your action bar now: bar:2.",
    bonusbar = "A bonus bar is up (forms and stances change it): bonusbar:1.",
    extrabar = "The extra action button is shown.",
    overridebar = "An override bar replaces your action bar.",
    possessbar = "You control another creature's actions.",
    vehicleui = "You are in a vehicle with its own action bar.",
    unithasvehicleui = "The unit is in a vehicle.",
    canexitvehicle = "You can leave the vehicle you are in.",
    petbattle = "You are in a pet battle.",
    cursor = "You hold something on the mouse cursor: a spell, an item, a macro.",
}

-- The same, the other way round: "nodead", "nomod:shift".
local NOT = {
    combat = "You are not in combat.",
    mod = "No modifier key is held: nomod:shift, no Shift. Without a value, none of them.",
    harm = "The unit is not an enemy you can attack.",
    help = "The unit is not friendly.",
    exists = "The unit is not there. For example, nobody is under the mouse.",
    dead = "The unit is not dead.",
    form = "You are not in that form or stance: noform, in none.",
    stealth = "You are not in stealth.",
    mounted = "You are not on a mount.",
    flying = "You are not flying.",
    flyable = "You can't fly here.",
    advflyable = "Skyriding is not allowed here.",
    swimming = "You are not swimming.",
    indoors = "You are not indoors.",
    outdoors = "You are not outdoors.",
    resting = "You are not in a rested area.",
    channeling = "You are not channeling a spell, or not that one.",
    group = "You are not in a group, or not in that kind.",
    party = "The unit is not in your party.",
    raid = "The unit is not in your raid.",
    pet = "Your pet is not out, or not that one.",
    spec = "That specialization is not active.",
    known = "You don't know that spell.",
    talent = "That talent is not chosen.",
    pvptalent = "That PvP talent is not chosen.",
    equipped = "You don't wear that kind of item.",
    btn = "Another mouse button clicked the action button.",
    bar = "Your action bar is on another page.",
    bonusbar = "No bonus bar is up, or not that one.",
    extrabar = "The extra action button is not shown.",
    overridebar = "No override bar replaces your action bar.",
    possessbar = "You don't control another creature.",
    vehicleui = "You are not in a vehicle with its own action bar.",
    unithasvehicleui = "The unit is not in a vehicle.",
    canexitvehicle = "You can't leave a vehicle now.",
    petbattle = "You are not in a pet battle.",
    cursor = "Nothing is on the mouse cursor.",
}

local UNITS = {
    target = "The one you have targeted.",
    focus = "A unit you set with /focus: you act on it without targeting it.",
    mouseover = "The unit under the mouse: in the world, on its nameplate or on a unit frame.",
    player = "You.",
    cursor = "The ground under the mouse: a spell you aim lands there at once, without a click.",
    none = "Nobody: a spell that needs a target asks you to click one.",
    tank = "Your group's tank, other than you. MacroSense puts in the name of the one with the role, and a new one "
        .. "when your group changes.",
    anyenemy = "Your target if it is an enemy, else the enemy your soft targeting picks.",
    anyfriend = "Your target if it is friendly, else the friend your soft targeting picks.",
    softenemy = "The enemy your soft targeting picks: the one in front of you.",
    softfriend = "The friend your soft targeting picks.",
    softinteract = "What your soft targeting picks to interact with.",
    anyinteract = "Your target if you can interact with it, else what soft targeting picks.",
    nameplate = "The unit of a nameplate shown, by its number.",
}
UNITS.heal = "Your group's healer, other than you. MacroSense puts in the name of the one with the role, and a new "
    .. "one when your group changes."

local META = {
    showtooltip = "The macro's icon and tooltip are of the spell or item it would use now: of the first line that "
        .. "casts, or of the one named after it.",
    show = "The macro's icon is of the spell or item it would use now, with no tooltip.",
}

local AT = "On whom the branch acts: @mouseover, @focus, @player... target= is the same."
local RESET = "When the sequence starts over: seconds without a press, target, combat, shift, ctrl or alt."

-- Every text, for the translation check.
function Docs.Texts()
    local out = { AT, RESET }
    for _, set in ipairs({ COMMANDS, CONDITIONS, NOT, UNITS, META }) do
        for _, text in pairs(set) do out[#out + 1] = text end
    end
    return out
end

local function base(name)
    local C = ns.Conditions
    return C and C.Base(name) or name
end

-- What the word at raw position `pos` of `raw` means: { title, lines } for MacroSense's own text,
-- { action = name } for a spell or item name, or nil. env: { commandKey = function(name) -> "TARGET" or nil }.
function Docs.At(raw, pos, env)
    local span
    for _, s in ipairs(ns.Highlight.Spans(raw)) do
        if pos >= s[1] and pos <= s[2] then span = s end
    end
    if not span then return nil end
    local word, kind = raw:sub(span[1], span[2]), span[3]
    if kind == "command" then
        local name = word:sub(2):lower()
        local key = env and env.commandKey and env.commandKey(name)
        local text = COMMANDS[name] or (key and COMMANDS[key:lower()])
        if text then return { title = word, lines = { L[text] } } end
    elseif kind == "meta" then
        local text = META[word:sub(2):lower()]
        if text then return { title = word, lines = { L[text] } } end
    elseif kind == "condition" or kind == "value" then
        -- A value tells about its condition: "shift" in "mod:shift".
        local name = kind == "condition" and word or raw:sub(1, span[1] - 1):match("([%a]+):[^,%]:]*$")
        if not name then return nil end
        -- "nocombat", "nomod": the other way round ("no" first, as Base drops it from "nomod").
        local lower = name:lower()
        local no = lower:sub(1, 2) == "no" and CONDITIONS[base(lower:sub(3))] ~= nil
        local text = (no and NOT or CONDITIONS)[base(no and lower:sub(3) or lower)]
        if not text then return nil end
        return { title = name, lines = { L[text] } }
    elseif kind == "operator" and (word == "@" or word == "target=") then
        return { title = word, lines = { L[AT] } }
    elseif kind == "unit" then
        local u = word:lower()
        local lines = { (ns.Explain.Unit(u):gsub("^%l", string.upper)) }
        local text = UNITS[u] or UNITS[u:match("^(%a+)%d+$") or ""]
        if text then lines[1] = L[text] end
        return { title = "@" .. word, lines = lines }
    elseif kind == "option" and word:lower() == "reset" then
        return { title = "reset=", lines = { L[RESET] } }
    elseif kind == "action" then
        return { action = word }
    end
    return nil
end

return Docs
