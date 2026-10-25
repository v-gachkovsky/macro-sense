-- Macros as a code to copy and paste: "MacroSense1:", one run of letters and digits (base64), which chat apps
-- and forums leave as it is, and a dot: words around the code don't get into it. Inside: each macro's tab,
-- icon, name and text, and a sum that tells a code cut short or changed. Pure Lua (5.1).
local _, ns = ...
ns = ns or {}

local Share = {}
ns.Share = Share

local PREFIX = "MacroSense1:"
local FIELD, MACRO, SUM = "\31", "\30", "\29" -- between a macro's parts, between macros, before the sum
local DIGITS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local VALUE = {}
for i = 1, 64 do VALUE[DIGITS:byte(i)] = i - 1 end
local SCOPES = { general = "g", character = "c", g = "general", c = "character" }

-- Three bytes to four digits; "=" fills the last group.
local function ToDigits(s)
    local out = {}
    for i = 1, #s, 3 do
        local a, b, c = s:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local d = {}
        for k, size in ipairs({ 262144, 4096, 64, 1 }) do
            local v = math.floor(n / size) % 64
            d[k] = DIGITS:sub(v + 1, v + 1)
        end
        if not c then d[4] = "=" end
        if not b then d[3] = "=" end
        out[#out + 1] = table.concat(d)
    end
    return table.concat(out)
end

-- A code damaged anywhere gives other bytes: the sum tells.
local function FromDigits(s)
    local out = {}
    for i = 1, #s, 4 do
        local n, pad = 0, 0
        for k = 0, 3 do
            local byte = s:byte(i + k)
            if byte == 61 then pad = pad + 1 end -- "="
            n = n * 64 + (VALUE[byte] or 0)
        end
        local bytes = string.char(math.floor(n / 65536), math.floor(n / 256) % 256, n % 256)
        out[#out + 1] = bytes:sub(1, 3 - pad)
    end
    return table.concat(out)
end

local function Sum(s)
    local sum = 0
    for i = 1, #s do sum = (sum * 31 + s:byte(i)) % 65521 end
    return tostring(sum)
end

-- macros: { { scope = "general" | "character", icon = file ID or path, name, body } } -> the code.
function Share.Encode(macros)
    local parts = {}
    for i, m in ipairs(macros) do
        parts[i] = table.concat({ SCOPES[m.scope] or "g", tostring(m.icon or ""), m.name, m.body or "" }, FIELD)
    end
    local plain = table.concat(parts, MACRO)
    return PREFIX .. ToDigits(plain .. SUM .. Sum(plain)) .. "."
end

-- The macros in `text`, which holds a code (spaces and line breaks in it, words around it are fine), or nil and
-- what is wrong with it.
function Share.Decode(text)
    local at = text:find(PREFIX, 1, true)
    if not at then return nil, "This is not a MacroSense code." end
    local digits = text:sub(at + #PREFIX):gsub("%s", ""):match("^([%w+/=]*)%.")
    local plain = digits and FromDigits(digits) -- nil: no dot, the end is missing
    local body, sum = (plain or ""):match("^(.*)" .. SUM .. "(%d+)$")
    if not body or Sum(body) ~= sum then return nil, "The code is cut short or changed: copy all of it again." end
    local macros = {}
    for part in (body .. MACRO):gmatch("(.-)" .. MACRO) do
        local scope, icon, name, macroText = part:match("^(%a)" .. FIELD .. "(.-)" .. FIELD .. "(.-)" .. FIELD .. "(.*)$")
        if not SCOPES[scope or ""] or name == "" then return nil, "The code is damaged." end
        macros[#macros + 1] = { scope = SCOPES[scope], icon = tonumber(icon) or icon, name = name, body = macroText }
    end
    return macros
end

return Share
