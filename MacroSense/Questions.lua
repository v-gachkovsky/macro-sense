-- The wizard step by step: its form (Wizard.lua) as questions, one at a time and in plain words, for players new
-- to macros. Each answer fills the form, so the macro is the one the form would make. Pure Lua; the window shows
-- the questions (WizardWindow.lua).
local _, ns = ...
ns = ns or {}
local L = ns.L

local Questions = {}
ns.Questions = Questions

local W = ns.Wizard

-- Whether nothing is asked after a unit: it always holds, or it is nobody, or clears the target.
local function Last(unit) return unit == "none" or unit == "clear" or W.Always(unit) end

-- Whether a spell has ranks to pick from: two learned at least (Classic; Retail has none).
local function Ranked(action) return action ~= nil and action.ranks ~= nil and #action.ranks > 1 end

-- A key's step ("shiftCast", "shiftPet", "shiftOn2"): the key and what is asked about it.
local function KeyStep(step)
    for _, key in ipairs(W.KEYS) do
        local rest = step:match("^" .. key .. "(%u.*)$")
        if rest then return key, rest end
    end
end

-- The questions for the form as it is, in order: "what" the macro does; "spell" (/cast, /use; "rank" when it has
-- ranks to pick from), "list" (and "reset" for /castsequence) or "pet"; on whom, "on1" to "on3", each while the one
-- before may not be there, then "byName" when /target goes by name; "keys", and for each key held "shiftCast" (and
-- "shiftRank") or "shiftPet", "shiftOn1", "shiftOn2"; "also"; "finish". Friends or enemies ("only") comes after the
-- first unit checked for it, unless the game says what the spell is for (a key's own spell too); the pet attacks
-- enemies. A spell that goes to nobody but you (Demon Armor) asks for no units. `keys`: the keys of this client (Cmd
-- on a Mac).
function Questions.Steps(spec, keys)
    local command = spec.command
    local list, target, pet = W.IsList(command), W.IsTarget(command), command == "pet"
    local out, only = { "what" }, nil
    local ask = not pet and (target or not spec.reaction)
    local function add(step) out[#out + 1] = step end
    -- `own`: a key's own spell the game says what it is for: its units are checked for that.
    local function units(prefix, on, n, own)
        for i = 1, n do
            add(prefix .. i)
            if ask and not own and not only and W.Checked(on[i]) then only = #out end
            if prefix == "on" and command == "target" and on[i] == "none" and spec.byName then return add("byName") end
            if Last(on[i]) then return end
        end
    end
    if list then
        add("list")
        if command == "castsequence" then add("reset") end
    elseif pet then
        add("pet")
    elseif not target then
        add("spell")
        if Ranked(spec.action) then add("rank") end
    end
    if (not pet or spec.pet == "attack") and not W.SelfOnly(spec) then units("on", spec.on, 3) end
    if not list then
        add("keys")
        for _, key in ipairs(keys) do
            local k = spec.keys[key]
            if k.active then
                if pet then
                    add(key .. "Pet")
                elseif not target then
                    add(key .. "Cast")
                    if Ranked(k.action) then add(key .. "Rank") end
                end
                local own = not target and k.action ~= nil and k.reaction ~= nil
                if (not pet or k.pet == "attack") and not W.SelfOnly(spec, key) then
                    units(key .. "On", k.on, 2, own)
                end
            end
        end
    end
    if only then table.insert(out, only + 1, "only") end
    add("also")
    add("finish")
    return out
end

-- The question after `step`, or before it with `back`; nil past either end. A step the form no longer asks starts
-- them over.
function Questions.Next(spec, keys, step, back)
    local steps = Questions.Steps(spec, keys)
    for i, s in ipairs(steps) do
        if s == step then return steps[i + (back and -1 or 1)] end
    end
    return steps[1]
end

------------------------------------------------------------------------
-- What each question says, and its answers
------------------------------------------------------------------------
-- What the macro casts or uses, a key's own or the macro's: its name (the item in a slot, not the slot's number).
local function Subject(spec, key)
    local action = key and spec.keys[key].action or spec.action
    return action and (action.label or action.name) or "?"
end

-- The units a step asks about: a key's own, or the macro's.
local function Units(spec, key)
    return key and spec.keys[key].on or spec.on
end

-- What the spell of a step is for, when the game says: a key's own spell's, or the macro's. The pet attacks
-- enemies; /target, /focus and /assist cast nothing.
local function Reaction(spec, key)
    if spec.command == "pet" then return "enemies" end
    if W.IsTarget(spec.command) then return nil end
    local k = key and spec.keys[key]
    if k and k.action then return k.reaction end
    return spec.reaction
end

-- Whom a spell for enemies never goes to, and one for friends.
local NOT_FOR = {
    enemies = { player = true, pet = true, party1 = true, party2 = true, party3 = true, party4 = true, tank = true,
        heal = true },
    friends = { arena1 = true, arena2 = true, arena3 = true },
}

-- How an answer names a unit. A cast goes "On whoever is under the mouse"; /target, /focus, /assist and the pet
-- take "Whoever is under the mouse". Your target, next to As usual, is the one checked for `only`.
local function Name(spec, unit, cast, only)
    local party, arena = unit:match("^party(%d)$"), unit:match("^arena(%d)$")
    if party then return string.format(cast and L["On party member %d"] or L["Party member %d"], tonumber(party)) end
    if arena then return string.format(cast and L["On arena enemy %d"] or L["Arena enemy %d"], tonumber(arena)) end
    if unit == "target" and not W.IsTarget(spec.command) then
        if cast then
            return only == "friends" and L["On your target, if a friend"] or only == "enemies"
                and L["On your target, if an enemy"] or L["On your target, if there is one"]
        end
        return only == "friends" and L["Your target, if a friend"] or only == "enemies"
            and L["Your target, if an enemy"] or L["Your target, if there is one"]
    end
    if cast then
        return ({ default = L["On your target, as usual"], mouseover = L["On whoever is under the mouse"],
            cursor = L["On the ground under the cursor"], player = L["On yourself"], focus = L["On your focus"],
            pet = L["On your pet"], targettarget = L["On your target's target"], tank = L["On your group's tank"],
            heal = L["On your group's healer"] })[unit]
    end
    return ({ default = L["Your target, as usual"], target = L["Your target"],
        mouseover = L["Whoever is under the mouse"], player = L["Yourself"], focus = L["Your focus"],
        pet = L["Your pet"], targettarget = L["Your target's target"], tank = L["Your group's tank"],
        heal = L["Your group's healer"] })[unit]
end

-- What a unit is, for whoever doesn't know the word.
local function UnitTip(unit)
    if unit:find("^party") then return L["Your party members, as your party frames list them from the top."] end
    if unit:find("^arena") then return L["The enemies of an arena match, in the order of their frames."] end
    if W.ROLES[unit] then
        return (unit == "tank" and L["The one with the tank role in your party or raid, other than you."]
            or L["The one with the healer role in your party or raid, other than you."]) .. " "
            .. L["MacroSense puts in the name of the one with the role now, and a new one when your group changes "
                .. "(out of combat)."]
    end
    return ({ default = L["The game's own choice: your target, or you when the game casts on you by itself "
            .. "(Auto Self Cast)."],
        mouseover = L["The one your mouse points at, in the world or on a frame (party, raid). Your target stays as "
            .. "it is."],
        cursor = L["For spells cast on the ground, like Blizzard: it lands under the cursor at once, with no circle "
            .. "to place."],
        focus = L["A second target you keep an eye on; /focus sets it."],
        targettarget = L["Whoever your target has targeted: the one a boss attacks, say."] })[unit]
end

-- The units a step offers: those the command takes there, but none asked about before it in the same order, nor
-- one the spell never goes to (yourself for Shadow Bolt); then /target by name, clearing the target or the focus,
-- nobody.
local function UnitAnswers(spec, key, i)
    local on, place = Units(spec, key), i > 1 and "then" or key and "key" or "first"
    local cast, only = not (W.IsTarget(spec.command) or spec.command == "pet"), W.Only(spec, key)
    local used, out, last = {}, {}, {}
    for j = 1, i - 1 do used[on[j]] = true end
    for unit in pairs(NOT_FOR[Reaction(spec, key)] or {}) do used[unit] = true end
    for _, u in ipairs(W.Units(spec.command, place)) do
        if u.key == "clear" then
            last[#last + 1] = { key = "clear", name = L[u.name] }
        elseif u.key ~= "none" and not used[u.key] then
            out[#out + 1] = { key = u.key, name = Name(spec, u.key, cast, only),
                tip = (cast or u.key ~= "default") and UnitTip(u.key) or nil,
                hint = (u.key ~= "default" and u.key ~= "target") and "@" .. u.key or nil }
        end
    end
    if not key and spec.command == "target" then out[#out + 1] = { key = "byName", name = L["Someone by name"] } end
    for _, a in ipairs(last) do out[#out + 1] = a end
    if i > 1 then out[#out + 1] = { key = "none", name = L["Do nothing"] } end
    return out
end

-- "And if nobody is under the mouse?": what the next unit is for.
local function Missing(unit)
    local party, arena = unit:match("^party(%d)$"), unit:match("^arena(%d)$")
    if party then return string.format(L["And if party member %d is not there?"], tonumber(party)) end
    if arena then return string.format(L["And if arena enemy %d is not there?"], tonumber(arena)) end
    return ({ mouseover = L["And if nobody is under the mouse?"], target = L["And if you have no target?"],
        focus = L["And if you have no focus?"], pet = L["And if your pet is not out?"],
        targettarget = L["And if your target has no target?"], tank = L["And if your group has no tank?"],
        heal = L["And if your group has no healer?"] })[unit]
end

-- Or the one there doesn't do: not a friend, not an enemy, dead.
local function NotThere(spec, key)
    local only = W.Only(spec, key)
    if only == "friends" then
        return spec.alive and L["Or the one there is not a friend, or is dead."]
            or L["Or the one there is not a friend."]
    elseif only == "enemies" then
        return spec.alive and L["Or the one there is not an enemy, or is dead."]
            or L["Or the one there is not an enemy."]
    end
    return spec.alive and L["Or the one there is dead."] or nil
end

-- The first question of an order of units: whom the command takes, or where its spell or item goes (a key's own or
-- the macro's).
local function OnWhom(spec, key)
    local command = spec.command
    if command == "target" then return L["Who should become your target?"] end
    if command == "focus" then return L["Who should become your focus?"] end
    if command == "assist" then return L["Whose target should you take?"] end
    if command == "pet" then return L["Who should your pet attack?"] end
    if W.IsList(command) then return L["Where should these spells go?"] end
    return string.format(L["Where should %s go?"], Subject(spec, key))
end

local function What()
    return {
        { key = "cast", name = L["Cast a spell"], hint = "/cast" },
        { key = "use", name = L["Use an item"], hint = "/use",
            tip = L["A potion, a healthstone, a toy... or a trinket you wear."] },
        { key = "castsequence", name = L["Several spells in turn"], hint = "/castsequence",
            tip = L["Each press casts the next spell of the list: the first press the first spell, the next press "
                .. "the second, and so on."] },
        { key = "castrandom", name = L["One of several at random"], hint = "/castrandom",
            tip = L["Each press casts one of the spells at random: a random mount, say."] },
        { key = "target", name = L["Target someone"], hint = "/target" },
        { key = "focus", name = L["Set your focus"], hint = "/focus",
            tip = L["Your focus is a second target to keep an eye on: to interrupt it or keep it crowd controlled "
                .. "while you fight another."] },
        { key = "assist", name = L["Take someone's target"], hint = "/assist",
            tip = L["Your target becomes the target of someone else: the tank's, say."] },
        { key = "pet", name = L["Command your pet"], hint = "/petattack",
            tip = L["Tell your pet to attack, follow you, stay..."] },
    }
end

local function PetAnswers()
    local out = {}
    for _, a in ipairs(W.PetActions(LE_EXPANSION_LEVEL_CURRENT)) do
        out[#out + 1] = { key = a.key, name = L[a.name], hint = a.command }
    end
    return out
end

-- The ranks of a spell: the one that follows what you learn first, then each one learned, the highest first.
local function RankAnswers(action)
    local out = { { key = "", name = L["The highest you know"], hint = action.name } }
    for i = #action.ranks, 1, -1 do
        local rank = action.ranks[i]
        out[#out + 1] = { key = rank, name = rank, hint = W.Spelled({ name = action.name, rank = rank }) }
    end
    return out
end

local function OnlyAnswers()
    return { { key = "friends", name = L["Friends"] }, { key = "enemies", name = L["Enemies"] },
        { key = "any", name = L["Anyone there"] },
        { key = "dead", name = L["Friends, dead or alive"], tip = L["For a resurrection."] } }
end

-- What `step` asks, in the chosen language: { kind = "choice", "spell", "list", "reset", "byName", "keys", "also"
-- or "finish", text = the question, hint, context = the key held it is about, key = that key; a choice has
-- answers = { { key, name, hint = the macro's words for it, tip } } and chosen = the key of the one chosen }.
function Questions.Ask(spec, step, keys)
    local key, rest = KeyStep(step)
    local context = key and string.format(L["With %s held"], (key:gsub("^%l", string.upper))) or nil
    local i = tonumber(step:match("^on(%d)$") or rest and rest:match("^On(%d)$"))
    if step == "what" then
        return { kind = "choice", text = L["What should the macro do?"], answers = What(), chosen = spec.command }
    elseif step == "spell" then
        return { kind = "spell", text = spec.command == "use" and L["Which item should the macro use?"]
            or L["Which spell should the macro cast?"], hint = L["Start typing its name, or pick it from the list."] }
    elseif rest == "Cast" then
        return { kind = "spell", key = key, context = context, text = L["What should the macro cast instead?"],
            hint = L["Leave it empty for the same one, on someone else."] }
    elseif step == "rank" or rest == "Rank" then
        local action = key and spec.keys[key].action or spec.action
        return { kind = "choice", key = key, context = context, text = string.format(L["Which rank of %s?"], action.name),
            hint = L["Usually the highest you know: it follows when you learn a new one."],
            answers = RankAnswers(action), chosen = action.rank or "" }
    elseif step == "list" then
        if spec.command == "castsequence" then
            return { kind = "list", text = L["Pick the spells in the order the macro should cast them"],
                hint = L["One per press: the first press casts the first spell, "
                    .. "the next press the second, and so on."] }
        end
        return { kind = "list", text = L["Pick the spells the macro chooses from"],
            hint = L["Each press casts one of them at random."] }
    elseif step == "reset" then
        return { kind = "reset", text = L["When should the sequence start again from the first spell?"],
            hint = L["Pick any of these, or none: then it starts again only after the last spell."] }
    elseif step == "pet" or rest == "Pet" then
        return { kind = "choice", key = key, context = context, text = L["What should your pet do?"],
            answers = PetAnswers(), chosen = key and spec.keys[key].pet or spec.pet }
    elseif i then
        local on = Units(spec, key)
        local chosen = on[i]
        if not key and spec.command == "target" and chosen == "none" and spec.byName then chosen = "byName" end
        return { kind = "choice", key = key, context = context,
            text = i == 1 and OnWhom(spec, key) or Missing(on[i - 1]), hint = i > 1 and NotThere(spec, key) or nil,
            answers = UnitAnswers(spec, key, i), chosen = chosen }
    elseif step == "only" then
        local text = L["Friends or enemies?"]
        if W.IsList(spec.command) then
            text = L["Who are these spells for?"]
        elseif not W.IsTarget(spec.command) then
            local before = Questions.Next(spec, keys, step, true)
            text = string.format(L["Who is %s for?"], Subject(spec, (KeyStep(before or ""))))
        end
        return { kind = "choice", text = text, answers = OnlyAnswers(),
            chosen = (spec.only == "friends" and not spec.alive) and "dead" or spec.only }
    elseif step == "byName" then
        return { kind = "byName", text = L["What name should it look for?"],
            hint = L["The nearest one with this name becomes your target: a rare, say."] }
    elseif step == "keys" then
        return { kind = "keys", text = string.format(L["Should the macro do something else while you hold %s?"],
            #keys > 3 and L["Shift, Ctrl, Alt or Cmd"] or L["Shift, Ctrl or Alt"]),
            hint = L["Pick the keys, or none: for each one, the next questions ask what it does."] }
    elseif step == "also" then
        return { kind = "also", text = L["Would you like to add anything else?"],
            hint = L["Pick any of these, or none."] }
    end
    return { kind = "finish", text = L["Almost done: name your macro"],
        hint = L["Then drag its icon from the editor onto an action bar."] }
end

-- The answer `answer` to the choice `step`. A unit after which nothing is asked ends the order there, and with it
-- /target by name; the pet attacks enemies.
function Questions.Choose(spec, step, answer)
    local key, rest = KeyStep(step)
    local i = tonumber(step:match("^on(%d)$") or rest and rest:match("^On(%d)$"))
    if step == "what" then
        W.Switch(spec, answer)
        if answer == "pet" and spec.pet == "attack" then spec.only = "enemies" end
    elseif step == "rank" or rest == "Rank" then
        local action = key and spec.keys[key].action or spec.action
        action.rank = answer ~= "" and answer or nil
    elseif step == "pet" or rest == "Pet" then
        if key then spec.keys[key].pet = answer else spec.pet = answer end
        if answer == "attack" then spec.only = "enemies" end
    elseif step == "only" then
        spec.only, spec.alive = answer == "dead" and "friends" or answer, answer ~= "dead"
    elseif i then
        local on = Units(spec, key)
        if answer == "byName" then
            for j = i, #on do on[j] = "none" end
            spec.byName = spec.byName or ""
            return
        end
        on[i] = answer
        if not key and Last(answer) then spec.byName = nil end
    end
end

return Questions
