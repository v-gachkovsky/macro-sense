-- Syntax highlighting for macro text. Pure Lua (5.1): tokenizer, colorizer and cursor mapping.
-- The EditBox holds "colored" text (raw text + |cffrrggbb ... |r codes); everything else works on raw text.
local _, ns = ...
ns = ns or {}

local Highlight = {}
ns.Highlight = Highlight

-- Set by Sources: function(name) -> true when "/name" is a registered command. Unknown commands are errors.
Highlight.isCommand = nil
-- Set by Sources: function(name, command) -> nil, or { message, short, fix } when a spell / item name
-- looks like a typo of a known one ("Shadwo Bolt" -> "Shadow Bolt"). command: "cast", "use", "equip", ...
Highlight.checkAction = nil

local UNIT_ARGS = { target = true, tar = true, focus = true, assist = true, a = true }
local LUA_KEYWORDS = {}
for w in ("and break do else elseif end false for function if in local nil not or repeat return then true until while")
    :gmatch("%a+") do LUA_KEYWORDS[w] = true end

-- Condition names (plus their "no" forms) from Data.lua.
local conditionSet
local function isCondition(name)
    if not conditionSet then
        conditionSet = {}
        for _, c in ipairs(ns.data.conditions) do
            local n = c.name:match("^%a+$")
            if n then
                conditionSet[n] = true
                conditionSet["no" .. n] = true
            end
        end
        for _, n in ipairs({ "modifier", "stance", "flyable", "group", "party", "raid", "shapeshift" }) do
            conditionSet[n], conditionSet["no" .. n] = true, true
        end
    end
    return conditionSet[name:lower()]
end

------------------------------------------------------------------------
-- Tokenizer: spans { from, to, kind } over raw text (1-based, inclusive)
------------------------------------------------------------------------
local function luaSpans(s, base, add)
    local i = 1
    while i <= #s do
        local c = s:sub(i, i)
        if c == '"' or c == "'" then
            local j = i + 1
            while j <= #s and s:sub(j, j) ~= c do
                if s:sub(j, j) == "\\" then j = j + 1 end
                j = j + 1
            end
            add(base + i, base + math.min(j, #s), "string")
            i = j + 1
        elseif c:find("%d") then
            local num = s:match("^%d+%.?%d*", i)
            add(base + i, base + i + #num - 1, "number")
            i = i + #num
        elseif c:find("[%a_]") then
            local word = s:match("^[%w_]+", i)
            if LUA_KEYWORDS[word] then add(base + i, base + i + #word - 1, "keyword") end
            i = i + #word
        else
            i = i + 1
        end
    end
end

-- A unit after "@" / "target=". Not a unit id: may still be a player's name, so only a warning.
local function unitSpan(unit, from, add)
    local to = from + #unit - 1
    if ns.Conditions and not ns.Conditions.IsUnit(unit) then
        add(from, to, "unit", string.format('unknown unit "%s" (fine if it is a player\'s name)', unit), "warning")
    else
        add(from, to, "unit")
    end
end

-- One condition inside brackets, e.g. "nomod:shift/ctrl", "@focus", "target=pet".
local function conditionSpans(s, base, add)
    local lead = #s:match("^%s*")
    local body = s:sub(lead + 1):match("^(.-)%s*$")
    if body == "" then return end
    local at = base + lead
    local unit = body:match("^@(.*)$")
    if unit then
        if unit == "" then return add(at + 1, at + 1, "error", "@ needs a unit") end
        add(at + 1, at + 1, "operator")
        unitSpan(unit, at + 2, add)
        return
    end
    unit = body:match("^target=(.*)$")
    if unit then
        if unit == "" then return add(at + 1, at + 7, "error", "target= needs a unit") end
        add(at + 1, at + 7, "operator")
        unitSpan(unit, at + 8, add)
        return
    end
    local name, values = body:match("^([^:]*):(.*)$")
    name = name or body
    if isCondition(name) then
        add(at + 1, at + #name, "condition")
    else
        add(at + 1, at + #name, "error", string.format('unknown condition "%s"', name))
    end
    local C = ns.Conditions
    if values == "" then
        add(at + #name + 1, at + #name + 1, "error", name .. ": needs a value")
    elseif values and isCondition(name) and C and not C.TakesValue(name) then
        add(at + #name + 1, at + #body, "error", name:lower() .. " takes no value")
    elseif values then
        local pos = at + #name + 1
        add(pos, pos, "operator")
        for part, slash in values:gmatch("([^/]*)(/?)") do
            local problem = part ~= "" and C and C.CheckValue(name, part)
            if problem then
                add(pos + 1, pos + #part, "error", problem)
            elseif part ~= "" then
                add(pos + 1, pos + #part, "value")
            end
            pos = pos + #part
            if slash ~= "" then
                add(pos + 1, pos + 1, "operator")
                pos = pos + 1
            end
        end
    end
end

-- A spell or item name. One that looks like a typo of a known name gets a warning with the fix.
local function actionSpan(name, from, add, command)
    local to = from + #name - 1
    local typo = command and Highlight.checkAction and Highlight.checkAction(name, command)
    if typo then
        add(from, to, "action", typo.message, "warning", typo)
    else
        add(from, to, "action")
    end
end

-- "reset=10/target" in front of a /castsequence list: seconds or what starts the sequence over, "/" between.
local function resetSpans(reset, from, add, sequence)
    if not sequence then
        return add(from, from + #reset - 1, "error", "reset= works only in /castsequence")
    end
    add(from, from + 4, "option")
    add(from + 5, from + 5, "operator")
    local values = reset:sub(7)
    if values == "" then return add(from + 5, from + 5, "error", "reset= needs a value") end
    local at, start = from + 5, 1 -- values[k] is at `at + k`
    while true do
        local slash = values:find("/", start, true)
        local part = values:sub(start, (slash or #values + 1) - 1)
        if part ~= "" then
            local problem = ns.Conditions and ns.Conditions.CheckReset(part)
            add(at + start, at + start + #part - 1, problem and "error" or "value", problem or nil)
        end
        if not slash then break end
        add(at + slash, at + slash, "operator")
        start = slash + 1
    end
end

-- Arguments of a secure command: "[cond] arg; [cond] arg". command: the action command ("cast", ...), if any.
local function argSpans(s, base, add, argKind, sequence, command)
    local i = 1
    while i <= #s do
        local c = s:sub(i, i)
        if c == "[" then
            local close = s:find("]", i + 1, true)
            local addCond = add
            if close then
                add(base + i, base + i, "bracket")
            else
                add(base + i, base + i, "error", "[ is not closed with ]")
                close = #s + 1
                -- One error is enough: the rest of the line still gets colors, not more errors.
                addCond = function(from, to, kind, message)
                    if not message or kind ~= "error" then add(from, to, kind) end
                end
            end
            -- Split on "," by hand: gmatch with an empty-matching pattern behaves differently in Lua 5.1.
            local inner, from = s:sub(i + 1, close - 1), 1
            local split = inner:find(",", 1, true) ~= nil
            while true do
                local comma = inner:find(",", from, true)
                local part = inner:sub(from, (comma or #inner + 1) - 1)
                local pos = base + i + from - 1
                if split and not part:find("%S") then
                    local at = base + i + (comma or from - 1) -- the comma next to the gap
                    addCond(at, at, "error", "empty condition")
                else
                    conditionSpans(part, pos, addCond)
                end
                if not comma then break end
                addCond(base + i + comma, base + i + comma, "operator")
                from = comma + 1
            end
            if close <= #s then add(base + close, base + close, "bracket") end
            i = close + 1
        elseif c == "]" then
            add(base + i, base + i, "error", "] without [")
            i = i + 1
        elseif c == ";" or (sequence and c == ",") then
            add(base + i, base + i, "operator")
            i = i + 1
        elseif c:find("%s") then
            i = i + 1
        else
            local stop = (s:find(sequence and "[;,%[%]]" or "[;%[%]]", i) or (#s + 1)) - 1
            local word = s:sub(i, stop):match("^(.-)%s*$")
            local reset = argKind == "action" and word:match("^reset=%S*")
            if reset then
                resetSpans(reset, base + i, add, sequence)
                i = i + #reset
            else
                if word:sub(1, 1) == "!" then
                    add(base + i, base + i, "operator")
                    i, word = i + 1, word:sub(2)
                end
                -- "Fireball(Rank 3)": the rank is a value.
                local name, rank = word:match("^(.-)(%(.*%))$")
                local nameOnly = (name and name ~= "") and name or word
                if nameOnly ~= "" then
                    if argKind == "action" then
                        actionSpan(nameOnly, base + i, add, command)
                    else
                        add(base + i, base + i + #nameOnly - 1, argKind)
                    end
                end
                if name and name ~= "" then add(base + i + #name, base + i + #word - 1, "value") end
                i = stop + 1
            end
        end
    end
end

local function lineSpans(line, base, add)
    local meta = line:match("^#%a+")
    if meta then
        add(base + 1, base + #meta, "meta")
        argSpans(line:sub(#meta + 1), base + #meta, add, "action", false, "cast")
        return
    end
    local lead, cmd = line:match("^(%s*)/(%S*)")
    if not lead then return end
    local cmdFrom, cmdTo = base + #lead + 1, base + #lead + 1 + #cmd
    local name = cmd:lower()
    local known = name == "" or not Highlight.isCommand or Highlight.isCommand(name)
    if known then
        add(cmdFrom, cmdTo, "command")
    else
        add(cmdFrom, cmdTo, "error", string.format('unknown command "/%s"', cmd))
    end
    local restBase = cmdTo - base
    local rest = line:sub(restBase + 1)
    local P = ns.Parser
    if P.chatCommands[name] then return end
    if P.luaCommands[name] then return luaSpans(rest, cmdTo, add) end
    local action = P.actionCommands[name]
    local argKind = UNIT_ARGS[name] and "unit" or (action and "action") or "option"
    argSpans(rest, cmdTo, add, argKind, action == "castsequence", action)
end

function Highlight.Spans(raw)
    local spans = {}
    -- extra: { short, fix } for issues that come with a shorter text or a fix.
    local function add(from, to, kind, message, severity, extra)
        if to >= from then
            spans[#spans + 1] = { from, to, kind, message, message and (severity or "error"), extra }
        end
    end
    local pos = 0
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        lineSpans(line, pos, add)
        pos = pos + #line + 1
    end
    table.sort(spans, function(a, b) return a[1] < b[1] end)
    return spans
end

-- Syntax problems: { from, to, message, line, severity = "error" | "warning", short?, fix? }
-- (raw positions, 1-based, inclusive; fix replaces from..to).
function Highlight.Errors(raw)
    local out = {}
    for _, span in ipairs(Highlight.Spans(raw)) do
        if span[4] then
            local line = select(2, raw:sub(1, span[1]):gsub("\n", "")) + 1
            local extra = span[6] or {}
            out[#out + 1] = {
                from = span[1], to = span[2], message = span[4], line = line, severity = span[5],
                short = extra.short, fix = extra.fix,
            }
        end
    end
    return out
end

------------------------------------------------------------------------
-- Colors
------------------------------------------------------------------------
function Highlight.Colorize(raw, scheme)
    local out, pos = {}, 1
    for _, span in ipairs(Highlight.Spans(raw)) do
        local from, to, kind = span[1], span[2], span[3]
        if from >= pos then
            out[#out + 1] = raw:sub(pos, from - 1)
            out[#out + 1] = "|cff" .. (scheme[kind] or scheme.text) .. raw:sub(from, to) .. "|r"
            pos = to + 1
        end
    end
    out[#out + 1] = raw:sub(pos)
    return table.concat(out)
end

-- Length of the color code starting at `i` in colored text, or nil. "||" is an escaped pipe, not a code.
local function codeAt(s, i)
    if s:byte(i) ~= 124 then return nil end
    local nxt = s:sub(i + 1, i + 1)
    if nxt == "r" then return 2 end
    if nxt == "c" and s:sub(i + 2, i + 9):find("^%x%x%x%x%x%x%x%x$") then return 10 end
    return nil
end

-- Raw text from colored text. Note: a "|cxxxxxxxx" / "|r" typed by the user is dropped, like the game shows it.
function Highlight.Strip(colored)
    local out, i = {}, 1
    while i <= #colored do
        local code = codeAt(colored, i)
        if code then
            i = i + code
        elseif colored:sub(i, i + 1) == "||" then
            out[#out + 1] = "||"
            i = i + 2
        else
            out[#out + 1] = colored:sub(i, i)
            i = i + 1
        end
    end
    return table.concat(out)
end

-- Cursor (bytes before it) in colored text -> cursor in raw text.
function Highlight.ToRaw(colored, cursor)
    local raw, i = 0, 1
    while i <= cursor do
        local code = codeAt(colored, i)
        if code then
            i = i + code
        else
            raw, i = raw + 1, i + 1
        end
    end
    return raw
end

-- Cursor in raw text -> cursor in colored text: right after the visible character before it, before the
-- codes that follow. Then Backspace removes that character, not an invisible color code.
function Highlight.ToColored(colored, rawCursor)
    if rawCursor <= 0 then return 0 end
    local raw, i = 0, 1
    while i <= #colored do
        local code = codeAt(colored, i)
        if code then
            i = i + code
        else
            raw, i = raw + 1, i + 1
            if raw == rawCursor then break end
        end
    end
    return i - 1
end

return Highlight
