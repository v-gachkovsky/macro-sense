-- Syntax highlighting for macro text. Pure Lua (5.1): tokenizer, colorizer and cursor mapping.
-- The EditBox holds "colored" text (raw text + |cffrrggbb ... |r codes); everything else works on raw text.
local _, ns = ...
ns = ns or {}

local Highlight = {}
ns.Highlight = Highlight

-- Set by Sources: function(name) -> true when "/name" is a registered command. Unknown commands are errors.
Highlight.isCommand = nil

local CHAT = {
    say = true, s = true, yell = true, y = true, party = true, p = true, raid = true, ra = true, rw = true,
    guild = true, g = true, officer = true, o = true, instance = true, i = true, emote = true, e = true,
    me = true, whisper = true, w = true, tell = true, t = true, reply = true, r = true, bg = true,
}
local LUA = { run = true, script = true, dump = true }
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

-- One condition inside brackets, e.g. "nomod:shift/ctrl", "@focus", "target=pet".
local function conditionSpans(s, base, add)
    local lead = #s:match("^%s*")
    local body = s:sub(lead + 1):match("^(.-)%s*$")
    if body == "" then return end
    local at = base + lead
    local unit = body:match("^@(.*)$")
    if unit then
        add(at + 1, at + 1, "operator")
        if unit ~= "" then add(at + 2, at + #body, "unit") end
        return
    end
    unit = body:match("^target=(.*)$")
    if unit then
        add(at + 1, at + 7, "operator")
        if unit ~= "" then add(at + 8, at + #body, "unit") end
        return
    end
    local name, values = body:match("^([^:]*):(.*)$")
    name = name or body
    add(at + 1, at + #name, isCondition(name) and "condition" or "error")
    if values then
        local pos = at + #name + 1
        add(pos, pos, "operator")
        for part, slash in values:gmatch("([^/]*)(/?)") do
            if part ~= "" then add(pos + 1, pos + #part, "value") end
            pos = pos + #part
            if slash ~= "" then
                add(pos + 1, pos + 1, "operator")
                pos = pos + 1
            end
        end
    end
end

-- Arguments of a secure command: "[cond] arg; [cond] arg".
local function argSpans(s, base, add, argKind, sequence)
    local i = 1
    while i <= #s do
        local c = s:sub(i, i)
        if c == "[" then
            add(base + i, base + i, "bracket")
            local close = s:find("]", i + 1, true) or (#s + 1)
            local inner, pos = s:sub(i + 1, close - 1), base + i
            for part, comma in inner:gmatch("([^,]*)(,?)") do
                conditionSpans(part, pos, add)
                pos = pos + #part
                if comma ~= "" then
                    add(pos + 1, pos + 1, "operator")
                    pos = pos + 1
                end
            end
            if close <= #s then add(base + close, base + close, "bracket") end
            i = close + 1
        elseif c == ";" or (sequence and c == ",") then
            add(base + i, base + i, "operator")
            i = i + 1
        elseif c:find("%s") then
            i = i + 1
        else
            local stop = (s:find(sequence and "[;,%[]" or "[;%[]", i) or (#s + 1)) - 1
            local word = s:sub(i, stop):match("^(.-)%s*$")
            local reset = word:match("^reset=%S+")
            if reset then
                add(base + i, base + i + #reset - 1, "option")
                i = i + #reset
            else
                if word:sub(1, 1) == "!" then
                    add(base + i, base + i, "operator")
                    i, word = i + 1, word:sub(2)
                end
                -- "Fireball(Rank 3)": the rank is a value.
                local name, rank = word:match("^(.-)(%(.*%))$")
                if name and name ~= "" then
                    add(base + i, base + i + #name - 1, argKind)
                    add(base + i + #name, base + i + #word - 1, "value")
                elseif word ~= "" then
                    add(base + i, base + i + #word - 1, argKind)
                end
                i = stop + 1
            end
        end
    end
end

local function lineSpans(line, base, add)
    local meta = line:match("^#%a+")
    if meta then
        add(base + 1, base + #meta, "meta")
        argSpans(line:sub(#meta + 1), base + #meta, add, "action")
        return
    end
    local lead, cmd = line:match("^(%s*)/(%S*)")
    if not lead then return end
    local cmdFrom, cmdTo = base + #lead + 1, base + #lead + 1 + #cmd
    local name = cmd:lower()
    local known = name == "" or not Highlight.isCommand or Highlight.isCommand(name)
    add(cmdFrom, cmdTo, known and "command" or "error")
    local restBase = cmdTo - base
    local rest = line:sub(restBase + 1)
    if CHAT[name] then return end
    if LUA[name] then return luaSpans(rest, cmdTo, add) end
    local action = ns.Parser and ns.Parser.actionCommands[name]
    local argKind = UNIT_ARGS[name] and "unit" or (action and "action") or "option"
    argSpans(rest, cmdTo, add, argKind, action == "castsequence")
end

function Highlight.Spans(raw)
    local spans = {}
    local function add(from, to, kind)
        if to >= from then spans[#spans + 1] = { from, to, kind } end
    end
    local pos = 0
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        lineSpans(line, pos, add)
        pos = pos + #line + 1
    end
    table.sort(spans, function(a, b) return a[1] < b[1] end)
    return spans
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

-- Cursor in raw text -> cursor in colored text (after any codes at that spot, so typing joins the next token).
function Highlight.ToColored(colored, rawCursor)
    local raw, i = 0, 1
    while i <= #colored do
        local code = codeAt(colored, i)
        if code then
            i = i + code
        elseif raw == rawCursor then
            break
        else
            raw, i = raw + 1, i + 1
        end
    end
    return i - 1
end

return Highlight
