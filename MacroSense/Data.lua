local _, ns = ...
ns = ns or {}

-- Static completion data. `arg` = the condition takes a value ("mod:" opens modifier completion).
-- Conditions missing in some game versions are harmless: the game just ignores them.
ns.data = {
    meta = {
        { name = "showtooltip", hint = "icon + tooltip of a spell" },
        { name = "show",        hint = "icon of a spell" },
    },

    -- Fallback list; Core adds every slash command registered in the game (Blizzard and addons).
    commands = {
        { name = "cast",             hint = "cast a spell" },
        { name = "use",              hint = "use an item or spell" },
        { name = "castsequence",     hint = "cast spells in order" },
        { name = "castrandom",       hint = "cast a random spell" },
        { name = "userandom",        hint = "use a random item" },
        { name = "stopcasting",      hint = "stop the current cast" },
        { name = "stopmacro",        hint = "stop the macro" },
        { name = "startattack",      hint = "start auto attack" },
        { name = "stopattack",       hint = "stop auto attack" },
        { name = "cancelaura",       hint = "remove a buff" },
        { name = "cancelform",       hint = "leave the current form" },
        { name = "target",           hint = "target a unit" },
        { name = "targetenemy",      hint = "next enemy" },
        { name = "targetfriend",     hint = "next friend" },
        { name = "targetlasttarget", hint = "previous target" },
        { name = "cleartarget",      hint = "clear the target" },
        { name = "assist",           hint = "target of a unit" },
        { name = "focus",            hint = "set focus" },
        { name = "clearfocus",       hint = "clear focus" },
        { name = "petattack",        hint = "pet attacks" },
        { name = "petfollow",        hint = "pet follows" },
        { name = "petstay",          hint = "pet stays" },
        { name = "petpassive",       hint = "pet passive" },
        { name = "petdefensive",     hint = "pet defensive" },
        { name = "petassist",        hint = "pet assist" },
        { name = "equip",            hint = "equip an item" },
        { name = "equipslot",        hint = "equip into a slot" },
        { name = "click",            hint = "click a button" },
        { name = "dismount",         hint = "leave the mount" },
        { name = "leavevehicle",     hint = "leave the vehicle" },
        { name = "run",              hint = "run Lua" },
        { name = "script",           hint = "run Lua" },
        { name = "say",              hint = "chat" },
        { name = "yell",             hint = "chat" },
        { name = "party",            hint = "chat" },
        { name = "raid",             hint = "chat" },
        { name = "emote",            hint = "chat" },
        { name = "whisper",          hint = "chat" },
    },

    conditions = {
        -- Every condition has a "no" form, the other way round. Those that need a value ([noknown:Name]) insert
        -- ":" through `insert`: an `arg` on a "no" name would hide it from Conditions.Base. `since`: the expansion
        -- that brought it (LE_EXPANSION_LEVEL_CURRENT), not suggested in older clients.
        { name = "combat",           hint = "in combat" },
        { name = "nocombat",         hint = "out of combat" },
        { name = "mod",              hint = "modifier held", arg = true },
        { name = "modifier",         hint = "modifier held", arg = true },
        -- [nomod] alone is how it is used: no ":" after it. "nomod:shift" still gets mod's values and checks.
        { name = "nomod",            hint = "no modifier held" },
        { name = "harm",             hint = "unit is hostile" },
        { name = "noharm",           hint = "unit is not hostile" },
        { name = "help",             hint = "unit is friendly" },
        { name = "nohelp",           hint = "unit is not friendly" },
        { name = "exists",           hint = "unit exists" },
        { name = "noexists",         hint = "unit does not exist" },
        { name = "dead",             hint = "unit is dead" },
        { name = "nodead",           hint = "unit is alive" },
        { name = "party",            hint = "unit in your party" },
        { name = "noparty",          hint = "unit not in your party" },
        { name = "raid",             hint = "unit in your raid" },
        { name = "noraid",           hint = "unit not in your raid" },
        { name = "@",                hint = "target unit", insert = "@" },
        { name = "target=",          hint = "target unit" },
        { name = "stance",           hint = "stance / form", arg = true },
        { name = "form",             hint = "stance / form", arg = true },
        { name = "noform",           hint = "no form" },
        { name = "nostance",         hint = "no form" },
        { name = "shapeshift",       hint = "shapeshifted" },
        { name = "noshapeshift",     hint = "not shapeshifted" },
        { name = "stealth",          hint = "stealthed" },
        { name = "nostealth",        hint = "not stealthed" },
        { name = "mounted",          hint = "on a mount" },
        { name = "nomounted",        hint = "not on a mount" },
        { name = "flying",           hint = "flying" },
        { name = "noflying",         hint = "not flying" },
        { name = "flyable",          hint = "flying allowed" },
        { name = "noflyable",        hint = "flying not allowed" },
        { name = "advflyable",       hint = "skyriding allowed", since = 9 },
        { name = "noadvflyable",     hint = "skyriding not allowed", since = 9 },
        { name = "swimming",         hint = "swimming" },
        { name = "noswimming",       hint = "not swimming" },
        { name = "indoors",          hint = "indoors" },
        { name = "noindoors",        hint = "not indoors" },
        { name = "outdoors",         hint = "outdoors" },
        { name = "nooutdoors",       hint = "not outdoors" },
        { name = "resting",          hint = "in a rested area" },
        { name = "noresting",        hint = "not in a rested area" },
        { name = "channeling",       hint = "channeling a spell", arg = true },
        -- [nochanneling] alone, as nomod: a press doesn't cut your channel short. ":Name" still gets the spells.
        { name = "nochanneling",     hint = "not channeling" },
        { name = "group",            hint = "in a group", arg = true },
        { name = "nogroup",          hint = "not in a group" },
        { name = "pet",              hint = "pet is out", arg = true },
        { name = "nopet",            hint = "no pet" },
        { name = "spec",             hint = "active specialization", arg = true },
        { name = "nospec",           hint = "another specialization", insert = "nospec:" },
        { name = "known",            hint = "spell is known", arg = true },
        { name = "noknown",          hint = "spell is not known", insert = "noknown:" },
        { name = "talent",           hint = "talent row/column", arg = true },
        { name = "notalent",         hint = "talent not chosen", insert = "notalent:" },
        { name = "pvptalent",        hint = "pvp talent", arg = true, since = 6 },
        { name = "nopvptalent",      hint = "pvp talent not chosen", insert = "nopvptalent:", since = 6 },
        { name = "equipped",         hint = "item type equipped", arg = true },
        { name = "noequipped",       hint = "item type not equipped", insert = "noequipped:" },
        { name = "worn",             hint = "item type equipped", arg = true },
        { name = "noworn",           hint = "item type not equipped", insert = "noworn:" },
        { name = "button",           hint = "mouse button", arg = true },
        { name = "btn",              hint = "mouse button", arg = true },
        { name = "nobtn",            hint = "another mouse button", insert = "nobtn:" },
        { name = "actionbar",        hint = "action bar page", arg = true },
        { name = "bar",              hint = "action bar page", arg = true },
        { name = "nobar",            hint = "another action bar page", insert = "nobar:" },
        { name = "bonusbar",         hint = "bonus bar", arg = true },
        { name = "nobonusbar",       hint = "no bonus bar" },
        { name = "extrabar",         hint = "extra action bar", since = 3 },
        { name = "noextrabar",       hint = "no extra action bar", since = 3 },
        { name = "overridebar",      hint = "override bar" },
        { name = "nooverridebar",    hint = "no override bar" },
        { name = "possessbar",       hint = "possess bar" },
        { name = "nopossessbar",     hint = "no possess bar" },
        { name = "vehicleui",        hint = "in a vehicle" },
        { name = "novehicleui",      hint = "not in a vehicle" },
        { name = "unithasvehicleui", hint = "unit in a vehicle" },
        { name = "nounithasvehicleui", hint = "unit not in a vehicle" },
        { name = "canexitvehicle",   hint = "can leave vehicle" },
        { name = "nocanexitvehicle", hint = "can't leave vehicle" },
        { name = "petbattle",        hint = "in a pet battle", since = 4 },
        { name = "nopetbattle",      hint = "not in a pet battle", since = 4 },
        { name = "cursor",           hint = "holding something on cursor" },
        { name = "nocursor",         hint = "nothing on cursor" },
    },

    -- Values for "mod:". Sources adds "cmd" on the Mac client (4th place). ALL-CAPS values are the
    -- game's modified-click actions ([mod:SELFCAST]) and are accepted as they are.
    modifiers = {
        { name = "shift" }, { name = "ctrl" }, { name = "alt" },
        { name = "lshift", hint = "left" }, { name = "rshift", hint = "right" },
        { name = "lctrl", hint = "left" }, { name = "rctrl", hint = "right" },
        { name = "lalt", hint = "left" }, { name = "ralt", hint = "right" },
    },

    -- Values for "btn:" / "button:".
    buttons = {
        { name = "1", hint = "left" }, { name = "2", hint = "right" }, { name = "3", hint = "middle" },
        { name = "4" }, { name = "5" },
        { name = "LeftButton" }, { name = "RightButton" }, { name = "MiddleButton" },
        { name = "Button4" }, { name = "Button5" },
    },

    -- After "/click Name": the mouse button that clicks it, then whether the click comes on key press.
    mouseButtons = {
        { name = "LeftButton" }, { name = "RightButton" }, { name = "MiddleButton" },
        { name = "Button4" }, { name = "Button5" },
    },
    clickDown = { { name = "true", hint = "on key press" } },

    -- Values for "reset=" in /castsequence: what starts the sequence over. Any whole number is seconds.
    resets = {
        { name = "target", hint = "new target" }, { name = "combat", hint = "combat ends" },
        { name = "shift", hint = "with Shift" }, { name = "ctrl", hint = "with Ctrl" }, { name = "alt", hint = "with Alt" },
        { name = "5", hint = "seconds idle" }, { name = "10", hint = "seconds idle" }, { name = "30", hint = "seconds idle" },
    },

    -- Equipment slots for "/use 13", "/equipslot 13 Name" (Sources adds what is in them).
    slots = {
        { name = "1", hint = "Head" }, { name = "2", hint = "Neck" }, { name = "3", hint = "Shoulder" },
        { name = "4", hint = "Shirt" }, { name = "5", hint = "Chest" }, { name = "6", hint = "Waist" },
        { name = "7", hint = "Legs" }, { name = "8", hint = "Feet" }, { name = "9", hint = "Wrist" },
        { name = "10", hint = "Hands" }, { name = "11", hint = "Finger 1" }, { name = "12", hint = "Finger 2" },
        { name = "13", hint = "Trinket 1" }, { name = "14", hint = "Trinket 2" }, { name = "15", hint = "Back" },
        { name = "16", hint = "Main Hand" }, { name = "17", hint = "Off Hand" }, { name = "18", hint = "Ranged" },
        { name = "19", hint = "Tabard" },
    },

    groups = { { name = "party" }, { name = "raid" } },
    bars = { { name = "1" }, { name = "2" }, { name = "3" }, { name = "4" }, { name = "5" }, { name = "6" } },
    bonusbars = { { name = "1" }, { name = "2" }, { name = "3" }, { name = "4" }, { name = "5" } },

    units = {
        { name = "player" }, { name = "target" }, { name = "focus" }, { name = "mouseover" },
        { name = "cursor", hint = "ground at cursor" }, { name = "pet" }, { name = "none", hint = "no target" },
        { name = "tank", hint = "group's tank" }, { name = "heal", hint = "group's healer" },
        { name = "targettarget" }, { name = "focustarget" }, { name = "pettarget" }, { name = "mouseovertarget" },
        { name = "vehicle" }, { name = "npc", hint = "NPC you talk to" },
        { name = "anyenemy", hint = "Retail" }, { name = "anyfriend", hint = "Retail" },
        { name = "anyinteract", hint = "Retail" }, { name = "softenemy", hint = "Retail" },
        { name = "softfriend", hint = "Retail" }, { name = "softinteract", hint = "Retail" },
    },
}

-- Numbered units: party1-4, raid1-40, ...
for _, u in ipairs({ { "party", 4 }, { "partypet", 4 }, { "arena", 5 }, { "boss", 5 }, { "raid", 40 } }) do
    for i = 1, u[2] do
        table.insert(ns.data.units, { name = u[1] .. i })
    end
end

-- Macro slots per tab. Forever and Retail keep them in Constants.MacroConsts, the Classic clients in globals;
-- character macros are numbered after all the general slots.
local slots = Constants and Constants.MacroConsts or {}
ns.MAX_GENERAL = slots.MAX_ACCOUNT_MACROS or MAX_ACCOUNT_MACROS or 120
ns.MAX_CHARACTER = slots.MAX_CHARACTER_MACROS or MAX_CHARACTER_MACROS or 30

-- The icon chosen for macro `index`, to keep and to save. GetMacroInfo gives the one shown now, which for the
-- question mark and #showtooltip can be the shown spell's: the game's macro window too picks with this one.
function ns.MacroIcon(index)
    if C_Macro and C_Macro.GetSelectedMacroIcon then return C_Macro.GetSelectedMacroIcon(index) end
    return (select(2, GetMacroInfo(index)))
end

return ns.data
