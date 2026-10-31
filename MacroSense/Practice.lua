-- Practice: tasks to write a macro, with the player's own spells, checked by what the macro does (WizardRead):
-- [@mouseover,harm][] and [harm,@mouseover] [] are the same answer. The guide shows them (HelpWindow). Pure Lua
-- (5.1): the spells come in a kit, Practice.Kit makes it in game.
local _, ns = ...
ns = ns or {}
local L = ns.L or setmetatable({}, { __index = function(_, k) return k end })

local Practice = {}
ns.Practice = Practice

-- Each class's interrupt, by spell ID: the name comes from the game, in its language. The first one known counts.
local INTERRUPTS = {
    WARRIOR = { 6552 }, ROGUE = { 1766 }, MAGE = { 2139 }, SHAMAN = { 57994, 8042 }, DEATHKNIGHT = { 47528 },
    HUNTER = { 147362, 187707, 34490 }, DEMONHUNTER = { 183752 }, MONK = { 116705 }, PALADIN = { 96231 },
    DRUID = { 106839, 78675 }, PRIEST = { 15487 }, EVOKER = { 351338 }, WARLOCK = { 119910, 19244 },
}
-- Classes with a pet to command.
local PETS = { HUNTER = true, WARLOCK = true }

-- The spells the tasks use, from your spellbook: harm = spells for enemies (in book order, interrupts left out),
-- help = spells for friends that go to others, interrupt, pet = a class with a pet.
function Practice.Kit()
    local class = UnitClass and select(2, UnitClass("player"))
    local spellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
    local known, kit = {}, { harm = {}, help = {}, pet = PETS[class or ""] or false }
    local S = ns.sources
    for _, s in ipairs(S.spells and S.spells() or {}) do
        if not s.offSpec then known[s.name:lower()] = s.name end
    end
    for _, id in ipairs(INTERRUPTS[class or ""] or {}) do
        local ok, name = pcall(spellName, id)
        if ok and name and known[name:lower()] then
            kit.interrupt = known[name:lower()]
            break
        end
    end
    for _, s in ipairs(S.spells and S.spells() or {}) do
        if not s.offSpec and s.name ~= kit.interrupt then
            local reaction = S.reaction and S.reaction(s.name)
            if reaction == "enemies" then
                kit.harm[#kit.harm + 1] = s.name
            elseif reaction == "friends" and S.selfOnly and S.selfOnly(s.name) == false then
                kit.help[#kit.help + 1] = s.name
            end
        end
    end
    return kit
end

local function Same(a, b)
    local function base(s) return (s or ""):gsub("%s*%b()$", ""):lower() end
    return a ~= nil and b ~= nil and base(a) == base(b)
end
local function Usual(unit) return unit == "default" or unit == "target" end
local function Name(action) return action and action.name end

-- The tasks the kit has spells for: { id, goal, answer, check = function(spec) -> problem or nil }.
function Practice.Tasks(kit)
    local tasks = {}
    local A, B = kit.harm[1], kit.harm[2]
    local function casts(spec, spell)
        if spec.command ~= "cast" then return L["The macro should cast with /cast."] end
        if not Same(Name(spec.action), spell) then
            return string.format(L["The macro casts %s; the task wants %s."], Name(spec.action) or "?", spell)
        end
    end
    if A then
        tasks[#tasks + 1] = {
            id = "mouseover",
            goal = string.format(L["Cast %s at the enemy under your mouse, or at your target when you point at "
                .. "nobody."], A),
            answer = "#showtooltip\n/cast [@mouseover,harm][] " .. A,
            check = function(spec)
                local problem = casts(spec, A)
                if problem then return problem end
                if spec.on[1] ~= "mouseover" then
                    return L["First, the macro should go to the unit under the mouse: @mouseover."]
                end
                if not Usual(spec.on[2]) then
                    return L["When nobody is under the mouse, it should go to your target: add [] after the first "
                        .. "brackets."]
                end
                if spec.only ~= "enemies" then
                    return L["Add harm next to @mouseover, so the macro casts at the unit under the mouse only when "
                        .. "it is an enemy."]
                end
            end,
        }
    end
    if A and B then
        tasks[#tasks + 1] = {
            id = "shift",
            goal = string.format(L["Cast %s as usual, and %s on your focus while you hold Shift."], A, B),
            answer = string.format("#showtooltip\n/cast [mod:shift,@focus] %s; %s", B, A),
            check = function(spec)
                local problem = casts(spec, A)
                if problem then return problem end
                local shift = spec.keys.shift
                if not (shift and shift.active) then
                    return string.format(L["With Shift held, the macro should cast %s: [mod:shift] before it."], B)
                end
                if not Same(Name(shift.action), B) then
                    return string.format(L["With Shift held, the macro casts %s; the task wants %s."],
                        Name(shift.action) or A, B)
                end
                if shift.on[1] ~= "focus" then
                    return string.format(L["With Shift held, %s should go to your focus: @focus."], B)
                end
                if not Usual(spec.on[1]) then
                    return L["Without Shift, the spell should go to your target, as usual."]
                end
            end,
        }
    end
    if kit.interrupt then
        local I = kit.interrupt
        tasks[#tasks + 1] = {
            id = "interrupt",
            goal = string.format(L["Stop whatever you are casting, then cast %s at your focus, or at your target "
                .. "when you have no focus."], I),
            answer = string.format("#showtooltip\n/stopcasting\n/cast [@focus,harm,nodead][] %s", I),
            check = function(spec)
                local problem = casts(spec, I)
                if problem then return problem end
                if not spec.stopcasting then return L["Add /stopcasting on a line before the cast."] end
                if spec.on[1] ~= "focus" then return L["First, the macro should go to your focus: @focus."] end
                if not Usual(spec.on[2]) then
                    return L["When you have no focus, it should go to your target: add harm next to @focus, then []."]
                end
            end,
        }
    end
    if A and B then
        tasks[#tasks + 1] = {
            id = "sequence",
            goal = string.format(L["Cast %s, then %s, one each press, starting over on a new target."], A, B),
            answer = string.format("#showtooltip\n/castsequence reset=target %s, %s", A, B),
            check = function(spec)
                if spec.command ~= "castsequence" then return L["The macro should use /castsequence."] end
                local list = spec.list
                if not (list[1] and list[2] and Same(Name(list[1]), A) and Same(Name(list[2]), B) and not list[3]) then
                    return string.format(L["The list should be %s, then %s, split by a comma."], A, B)
                end
                if not spec.reset.target then return L["It should start over on a new target: reset=target."] end
            end,
        }
    end
    if kit.pet then
        tasks[#tasks + 1] = {
            id = "pet",
            goal = L["Send your pet to attack the enemy under your mouse, or your target when you point at nobody."],
            answer = "/petattack [@mouseover,harm][]",
            check = function(spec)
                if spec.command ~= "pet" or spec.pet ~= "attack" then
                    return L["The macro should send your pet with /petattack."]
                end
                if spec.on[1] ~= "mouseover" then
                    return L["First, the pet should go to the unit under the mouse: @mouseover."]
                end
                if not Usual(spec.on[2]) then
                    return L["When nobody is under the mouse, it should go to your target: add [] after the first "
                        .. "brackets."]
                end
                if spec.only ~= "enemies" then
                    return L["Add harm next to @mouseover, so the pet goes only for an enemy."]
                end
            end,
        }
    end
    local H = kit.help[1]
    if H then
        tasks[#tasks + 1] = {
            id = "heal",
            goal = string.format(L["Cast %s on a friend under your mouse; if there is none, on your target if it is a "
                .. "friend; if not, on yourself."], H),
            answer = string.format("#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] %s", H),
            check = function(spec)
                local problem = casts(spec, H)
                if problem then return problem end
                if spec.on[1] ~= "mouseover" then
                    return L["First, the macro should go to the unit under the mouse: @mouseover."]
                end
                if spec.on[2] ~= "target" then
                    return L["Then to your target, if it is a friend: [help] with no @, after the first brackets."]
                end
                if spec.on[3] ~= "player" then return L["Last, to yourself: [@player]."] end
                if spec.only ~= "friends" then
                    return L["Add help to the brackets, so the macro casts only at friends."]
                end
            end,
        }
    end
    return tasks
end

-- Whether `text` does what `task` asks: true, or false and what to change.
function Practice.Check(task, text)
    if not (text or ""):find("%S") then return false, L["Write the macro in the editor first."] end
    local spec = ns.Wizard.Read(text)
    if not spec then
        return false, L["This macro is not one the task asks for. Start from the task's words, line by line."]
    end
    local problem = task.check(spec)
    if problem then return false, problem end
    return true, L["Right: the macro does what the task asks."]
end

return Practice
