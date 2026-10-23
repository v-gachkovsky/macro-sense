-- The wizard's recipes: common macros from a few choices. Each recipe says what it asks (fields) and writes the
-- macro from the answers. Pure Lua; the panel that asks the questions is WizardPanel.lua.
local _, ns = ...
ns = ns or {}

local Wizard = {}
ns.Wizard = Wizard

-- An action is { name = "Flash Heal" } or { name = "Healthstone", item = true }. A line of items says /use, one
-- with a spell /cast: the game takes either for both, /cast looks for a spell first and /use for an item.
local function Command(...)
    for i = 1, select("#", ...) do
        local action = select(i, ...)
        if action and not action.item then return "/cast" end
    end
    return "/use"
end

local function Cast(action, units)
    return Command(action) .. " " .. units .. " " .. action.name
end

-- #showtooltip, the lines before the cast, the cast, the lines after it.
local function Macro(c, parts)
    local out = { parts.tooltip and ("#showtooltip " .. parts.tooltip) or "#showtooltip" }
    for _, line in ipairs(parts.before or {}) do out[#out + 1] = line end
    if c.stopcasting then out[#out + 1] = "/stopcasting" end
    for _, line in ipairs(parts.uses or {}) do out[#out + 1] = line end
    out[#out + 1] = parts.cast
    if c.startattack then out[#out + 1] = "/startattack" end
    if c.petattack then out[#out + 1] = "/petattack" end
    return table.concat(out, "\n")
end

------------------------------------------------------------------------
-- Questions. kind: "action" (a spell or item), "choice" (options), "check" (yes / no), "note" (text only).
-- `when` = asked only when it makes sense for the answers so far; `reaction` = the panel sets it from the
-- spell picked, when the game says whether that is for friends or enemies.
------------------------------------------------------------------------
local function friends(c) return c.on == "friends" end
local function enemies(c) return c.on == "enemies" end

local function With(field, more)
    local out = {}
    for k, v in pairs(field) do out[k] = v end
    for k, v in pairs(more) do out[k] = v end
    return out
end

local ACTION = { key = "action", kind = "action", label = "Spell or item" }
local ON = { key = "on", kind = "choice", label = "Cast on", reaction = true, default = "friends",
    options = { { key = "friends", name = "Friends" }, { key = "enemies", name = "Enemies" } } }
local STOP = { key = "stopcasting", kind = "check", label = "Stop your cast first",
    tip = "For an interrupt or a save: it goes off at once, even in the middle of another cast." }
local ATTACK = { key = "startattack", kind = "check", label = "Start auto attack" }
local PET = { key = "petattack", kind = "check", label = "Your pet attacks your target" }

------------------------------------------------------------------------
-- Recipes: title and text for the list, the questions, the macro (nil while it lacks what it needs).
------------------------------------------------------------------------
Wizard.recipes = {
    {
        key = "mouseover",
        title = "Mouseover",
        text = "Cast on whoever is under your mouse, on frames or in the world. The target stays.",
        fields = {
            ACTION, ON,
            { key = "self", kind = "check", label = "No friend there: cast on yourself", default = true,
                when = friends },
            STOP, With(ATTACK, { when = enemies }), With(PET, { when = enemies }),
        },
        write = function(c)
            if not c.action then return nil end
            local units = "[@mouseover,harm,nodead][]"
            if c.on == "friends" then
                units = "[@mouseover,help,nodead]" .. (c.self and "[help,nodead][@player]" or "[]")
            end
            return Macro(c, { cast = Cast(c.action, units) })
        end,
    },
    {
        key = "focus",
        title = "Focus",
        text = "Interrupt or control your focus while you keep fighting your target.",
        fields = {
            ACTION, With(ON, { default = "enemies" }),
            { key = "fallback", kind = "check", label = "No focus: cast on your target", default = true },
            { key = "setFocus", kind = "check", label = "Shift: make your target the focus",
                tip = "Shift with this key sets the focus and casts nothing." },
            STOP,
        },
        write = function(c)
            if not c.action then return nil end
            local units = (c.on == "friends" and "[@focus,help,nodead]" or "[@focus,harm,nodead]")
                .. (c.fallback and "[]" or "")
            local before = c.setFocus and { "/focus [mod:shift] target", "/stopmacro [mod:shift]" } or nil
            return Macro(c, { before = before, cast = Cast(c.action, units) })
        end,
    },
    {
        key = "party",
        title = "Party member",
        text = "Cast on yourself or a party member by their place in the party frames.",
        fields = {
            ACTION,
            { key = "who", kind = "choice", label = "Cast on", default = "party1", options = {
                { key = "player", name = "Yourself" }, { key = "party1", name = "Party member 1" },
                { key = "party2", name = "Party member 2" }, { key = "party3", name = "Party member 3" },
                { key = "party4", name = "Party member 4" }, { key = "keys", name = "Members 1-4 by key" },
            } },
            { kind = "note", text = "No key: member 1, Shift: 2, Ctrl: 3, Alt: 4.",
                when = function(c) return c.who == "keys" end },
            STOP,
        },
        write = function(c)
            if not c.action then return nil end
            local units = "[@" .. c.who .. "]"
            if c.who == "keys" then units = "[mod:shift,@party2][mod:ctrl,@party3][mod:alt,@party4][@party1]" end
            return Macro(c, { cast = Cast(c.action, units) })
        end,
    },
    {
        key = "cursor",
        title = "At the cursor",
        text = "Area spells land where your mouse points, with no circle to place.",
        fields = {
            With(ACTION, { label = "Spell" }),
            { key = "feet", kind = "check", label = "Shift: at your feet" },
            STOP,
        },
        write = function(c)
            if not c.action then return nil end
            return Macro(c, { cast = Cast(c.action, (c.feet and "[mod:shift,@player]" or "") .. "[@cursor]") })
        end,
    },
    {
        key = "keys",
        title = "One key, several spells",
        text = "Hold Shift, Ctrl or Alt to cast something else with the same key.",
        fields = {
            With(ACTION, { label = "No key" }),
            With(ACTION, { key = "shift", label = "Shift" }),
            With(ACTION, { key = "ctrl", label = "Ctrl" }),
            With(ACTION, { key = "alt", label = "Alt" }),
            STOP, ATTACK, PET,
        },
        write = function(c)
            local clauses = {}
            for _, mod in ipairs({ "shift", "ctrl", "alt" }) do
                if c[mod] then clauses[#clauses + 1] = "[mod:" .. mod .. "] " .. c[mod].name end
            end
            if c.action then clauses[#clauses + 1] = c.action.name end
            if #clauses == 0 then return nil end
            return Macro(c, { cast = Command(c.action, c.shift, c.ctrl, c.alt) .. " " .. table.concat(clauses, "; ") })
        end,
        name = function(c) return c.action or c.shift or c.ctrl or c.alt end,
    },
    {
        key = "trinkets",
        title = "Trinkets with a spell",
        text = "Your trinkets go off with a spell, whenever they are ready.",
        fields = {
            With(ACTION, { label = "Spell" }),
            -- `slot`: the panel names what is in it and checks it when it has a use effect.
            { key = "top", kind = "check", label = "Trinket 1", slot = 13 },
            { key = "bottom", kind = "check", label = "Trinket 2", slot = 14 },
            STOP, ATTACK, PET,
        },
        write = function(c)
            if not (c.action or c.top or c.bottom) then return nil end
            local uses = {}
            if c.top then uses[#uses + 1] = "/use 13" end
            if c.bottom then uses[#uses + 1] = "/use 14" end
            -- The icon is the spell's: a bare #showtooltip would show the first trinket.
            return Macro(c, { uses = uses, cast = c.action and (Command(c.action) .. " " .. c.action.name),
                tooltip = c.action and c.action.name })
        end,
        name = function(c) return c.action or { name = "Trinkets" } end,
    },
}

function Wizard.Find(key)
    for _, recipe in ipairs(Wizard.recipes) do
        if recipe.key == key then return recipe end
    end
end

-- Fresh answers: each question's default.
function Wizard.Defaults(recipe)
    local c = {}
    for _, f in ipairs(recipe.fields) do
        if f.key and f.default ~= nil then c[f.key] = f.default end
    end
    return c
end

function Wizard.Asked(field, c) return not field.when or field.when(c) end

-- The macro for the answers, or nil while it lacks what it needs. Answers to questions not asked now (a pet
-- for a friendly spell) don't count.
function Wizard.Text(recipe, c)
    local asked = {}
    for _, f in ipairs(recipe.fields) do
        if f.key and Wizard.Asked(f, c) then asked[f.key] = c[f.key] end
    end
    return recipe.write(asked)
end

-- A name for the macro: what it casts.
function Wizard.Name(recipe, c)
    local action = recipe.name and recipe.name(c) or c.action
    return action and action.name
end

return Wizard
