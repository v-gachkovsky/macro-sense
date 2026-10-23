-- What each line of a macro would do right now, for the live preview next to the text. Pure Lua (5.1):
-- the game's own condition check (SecureCmdOptionParse) comes in through `env`.
local _, ns = ...
ns = ns or {}

local Preview = {}
ns.Preview = Preview

local function trim(s) return s:match("^%s*(.-)%s*$") end

-- A spell or item the way a note shows it: "!Shoot" -> "Shoot", "Summon Imp(Summon)" -> "Summon Imp",
-- "13" -> "Trinket 1" (the equipment slot), "0 1" -> "bag 0, slot 1".
local function displayName(action)
    local s = trim(action):gsub("^!", "")
    if s:find("^%d+$") then
        local slot = ns.data and ns.data.slots[tonumber(s)]
        return slot and slot.hint or "slot " .. s
    end
    local bag, slot = s:match("^(%d+)%s+(%d+)$")
    if bag then return string.format("bag %s, slot %s", bag, slot) end
    return trim((s:gsub("%b()$", "")))
end

-- "reset=10 Corruption, !Immolate" -> { "Corruption", "Immolate" }
local function steps(sequence)
    local out = {}
    local list = trim(sequence):gsub("^reset=%S+%s*", "")
    for step in (list .. ","):gmatch("([^,]*),") do
        if step:find("%S") then out[#out + 1] = displayName(step) end
    end
    return out
end

-- /castsequence: the step that comes next when the game tells (env.sequenceStep), else the whole list.
-- The game names steps in lower case, so the name comes from the macro.
local function sequence(action, unit, env)
    local list = steps(action)
    if env.sequenceStep then
        local ok, index = pcall(env.sequenceStep, action)
        local name = ok and type(index) == "number" and list[index]
        if name then
            return { kind = "cast", name = name, unit = unit, step = index, steps = #list, icon = name }
        end
    end
    return { kind = "cast", name = table.concat(list, ", "), unit = unit, icon = list[1] }
end

-- One "/command options" line.
local function command(name, rest, env)
    local P = ns.Parser
    if P.luaCommands[name] then return { kind = "lua" } end
    if P.chatCommands[name] then return { kind = "chat" } end
    local ok, action, unit = pcall(env.parse, rest)
    if not ok then return nil end
    if action == nil then return { kind = "nomatch" } end
    if unit == "" then unit = nil end
    action = trim(action)
    if P.stopCommands[name] then return { kind = "stop" } end
    local base = P.actionCommands[name]
    if not base then return { kind = "runs", arg = action ~= "" and action or nil, unit = unit } end
    if action == "" then return { kind = "nothing" } end
    if base == "castsequence" then return sequence(action, unit, env) end
    if base == "castrandom" or base == "userandom" then
        return { kind = "cast", name = table.concat(steps(action), ", "), unit = unit }
    end
    if base == "equip" or base == "equipslot" then
        return { kind = "cast", verb = "equip", name = displayName((action:gsub("^%d+%s+", ""))), unit = unit }
    end
    if base == "cancelaura" then return { kind = "cast", verb = "cancel", name = displayName(action) } end
    local spell = displayName(action)
    return { kind = "cast", name = spell, unit = unit, icon = spell }
end

-- Per line (1 .. results.n): what it does now, or nil for an empty line, a comment or a line in `skip`
-- (lines with syntax errors: how the game reads those is anyone's guess).
--   { kind = "cast", name, unit?, verb?, step?, steps?, icon? }  casts, uses, equips (verb) or cancels
--   { kind = "runs", arg?, unit? }  another command that runs
--   { kind = "nothing" }            a clause matches, but it names no spell or item
--   { kind = "nomatch" }            no clause matches: the line does nothing
--   { kind = "stop" }, { kind = "unreached" }  /stopmacro stops here; the lines after it
--   { kind = "icon", name? }        #showtooltip / #show: the icon shown now (nil: the question mark)
--   { kind = "lua" }, { kind = "chat" }
-- env.parse(options) -> action, unit: the game's SecureCmdOptionParse.
-- env.sequenceStep(sequence) -> index of the next step: the game's QueryCastSequence (optional).
function Preview.Evaluate(raw, env, skip)
    local results, metas, stopped, n = {}, {}, false, 0
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        n = n + 1
        if not (skip and skip[n]) then
            local meta, options = line:match("^#(%a+)(.*)$")
            local cmd, rest = line:match("^%s*/(%S+)%s*(.*)$")
            local said = line:find("%S") and not line:find("^%s*[#/]") -- a line without a command is said in chat
            meta = meta and meta:lower()
            if meta == "showtooltip" or meta == "show" then
                metas[#metas + 1] = { line = n, options = options }
            elseif stopped and (cmd or said) then
                results[n] = { kind = "unreached" }
            elseif cmd then
                results[n] = command(cmd:lower(), rest, env)
                stopped = results[n] ~= nil and results[n].kind == "stop"
            elseif said then
                results[n] = { kind = "chat" }
            end
        end
    end
    -- The icon: what #showtooltip names, or else the first spell or item a line casts now.
    local auto
    for i = 1, n do
        if results[i] and results[i].icon then
            auto = results[i].icon
            break
        end
    end
    for _, m in ipairs(metas) do
        local name = auto
        if m.options:find("%S") then
            local ok, action = pcall(env.parse, trim(m.options))
            if ok and action == nil then
                name = nil
            elseif ok and trim(action) ~= "" then
                name = displayName(action)
            end
        end
        results[m.line] = { kind = "icon", name = name }
    end
    results.n = n
    return results
end

local QUIET = { nothing = "nothing", nomatch = "no match", unreached = "not reached", lua = "Lua", chat = "chat" }

-- The note for one result, with color codes. c = { action, unit, text, dim, warning } ("rrggbb").
function Preview.Note(r, c)
    if not r then return "" end
    local function paint(color, s) return "|cff" .. color .. s .. "|r" end
    local unit = r.unit and paint(c.unit, " @" .. r.unit) or ""
    if r.kind == "cast" then
        local s = (r.verb and paint(c.text, r.verb .. " ") or "") .. paint(c.action, r.name)
        if r.step then s = s .. paint(c.dim, string.format(" (%d/%d)", r.step, r.steps)) end
        return s .. unit
    elseif r.kind == "runs" then
        return paint(c.text, "runs") .. (r.arg and " " .. paint(c.action, r.arg) or "") .. unit
    elseif r.kind == "icon" then
        return paint(c.dim, "icon: ") .. (r.name and paint(c.action, r.name) or paint(c.dim, "?"))
    elseif r.kind == "stop" then
        return paint(c.warning, "stops here")
    end
    return paint(c.dim, QUIET[r.kind] or "")
end

return Preview
