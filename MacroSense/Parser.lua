-- Pure Lua (5.1) macro parser: no WoW API here, so it can be tested outside the game (see tests/).
local _, ns = ...
ns = ns or {}

local Parser = {}
ns.Parser = Parser

-- Commands whose arguments are spells / items -> their English name.
-- Sources adds localized aliases (SLASH_CAST1..n etc.).
Parser.actionCommands = {
    cast = "cast", spell = "cast", use = "use", castsequence = "castsequence", castrandom = "castrandom",
    userandom = "userandom", cancelaura = "cancelaura", equip = "equip", equipslot = "equipslot",
    showtooltip = "cast",
}

-- Chat commands: the rest of the line is said as it is, conditions included.
Parser.chatCommands = {
    say = true, s = true, yell = true, y = true, party = true, p = true, raid = true, ra = true, rw = true,
    guild = true, g = true, officer = true, o = true, instance = true, i = true, emote = true, e = true,
    me = true, whisper = true, w = true, tell = true, t = true, reply = true, r = true, bg = true,
}
-- Commands that run Lua.
Parser.luaCommands = { run = true, script = true, dump = true }
-- "/stopmacro"; Sources adds localized aliases.
Parser.stopCommands = { stopmacro = true }

-- Conditions whose value is a modifier key list (mod:shift/ctrl).
local MODIFIER_CONDS = { mod = true, modifier = true, nomod = true, nomodifier = true }

local function trimLeft(s)
    local spaces = s:match("^%s*")
    return s:sub(#spaces + 1), #spaces
end

-- Context of the word being typed at `cursor` (bytes before the cursor, as EditBox:GetCursorPosition()).
-- Returns nil or a table:
--   kind    = "command" | "meta" | "condition" | "unit" | "modifier" | "conditionValue" | "action" | "reset"
--             ("action" = a spell or item name, "rank" = inside "Spell(" -> `spell`, "reset" = a value after
--             "/castsequence reset=", with `used` = the values before it)
--   prefix  = text typed so far for that word
--   start   = 1-based index in `text` where the word begins (replace text[start .. cursor])
--   command = the slash command of the line (lowercase, without "/"), when there is one
--   base    = English name of an action command ("/zaubern" -> "cast"), for "action"
--   condition = condition name, for "conditionValue"
function Parser.GetContext(text, cursor)
    cursor = cursor or #text
    local before = text:sub(1, cursor)
    local lineStart = 1
    for i = #before, 1, -1 do
        if before:byte(i) == 10 then lineStart = i + 1; break end
    end
    local line = before:sub(lineStart)

    -- "/ca|" -> commands
    local lead, cmdPrefix = line:match("^(%s*/)([^%s%[]*)$")
    if lead then
        return { kind = "command", prefix = cmdPrefix, start = lineStart + #lead }
    end

    -- "#sho|" -> meta lines
    local metaPrefix = line:match("^#(%w*)$")
    if metaPrefix then
        return { kind = "meta", prefix = metaPrefix, start = lineStart + 1 }
    end

    local head, cmd, rest
    head, rest = line:match("^(#show%a*%s+)(.*)$")
    if head then
        cmd = "showtooltip"
    else
        head, cmd, rest = line:match("^(%s*/(%S+)%s+)(.*)$")
        if not head then return nil end
        cmd = cmd:lower()
    end
    local restStart = lineStart + #head

    -- Find the clause the cursor is in: track brackets, remember the last separator.
    local inBracket, tokenStart = false, 1
    for i = 1, #rest do
        local c = rest:sub(i, i)
        if c == "[" then
            inBracket, tokenStart = true, i + 1
        elseif c == "]" then
            inBracket, tokenStart = false, i + 1
        elseif inBracket and c == "," then
            tokenStart = i + 1
        elseif not inBracket and (c == ";" or (c == "," and cmd:find("sequence"))) then
            tokenStart = i + 1
        end
    end

    local token, skipped = trimLeft(rest:sub(tokenStart))
    local tokenAbs = restStart + tokenStart - 1 + skipped

    if inBracket then
        local unit = token:match("^@(.*)$")
        if unit then
            return { kind = "unit", prefix = unit, start = tokenAbs + 1, command = cmd }
        end
        unit = token:match("^target=(.*)$")
        if unit then
            return { kind = "unit", prefix = unit, start = tokenAbs + 7, command = cmd }
        end
        local name, values = token:match("^([%a]+):(.*)$")
        if name then
            -- Value lists are separated by "/": complete the last one.
            local last = values:match("([^/]*)$")
            local start = tokenAbs + #token - #last
            if MODIFIER_CONDS[name:lower()] then
                return { kind = "modifier", prefix = last, start = start, command = cmd }
            end
            return { kind = "conditionValue", prefix = last, start = start, command = cmd, condition = name:lower() }
        end
        return { kind = "condition", prefix = token, start = tokenAbs, command = cmd }
    end

    if Parser.actionCommands[cmd] then
        -- "/castsequence reset=10/ta": the reset values, "/" between them.
        local values = token:match("^reset=(%S*)$")
        if values then
            if Parser.actionCommands[cmd] ~= "castsequence" then return nil end
            local last = values:match("([^/]*)$")
            local used = {}
            for v in values:sub(1, #values - #last):gmatch("[^/]+") do used[v:lower()] = true end
            return { kind = "reset", prefix = last, start = tokenAbs + #token - #last, command = cmd, used = used }
        end
        -- "/castsequence reset=10 Spell": skip the reset option.
        local reset = token:match("^reset=%S+%s+")
        if reset then token, tokenAbs = token:sub(#reset + 1), tokenAbs + #reset end
        -- "/equipslot 13 Trinket": skip the slot number.
        local slot = token:match("^%d+%s+")
        if slot then token, tokenAbs = token:sub(#slot + 1), tokenAbs + #slot end
        -- "/cast !Spell": the "!" toggles, it is not part of the name.
        local bang = token:match("^!") and 1 or 0
        local word, wordAbs = token:sub(1 + bang), tokenAbs + bang
        -- "Fireball(Ra": typing a rank. "Fireball(Rank 3)" is complete.
        local spell, rank = word:match("^(.-)%(([^%)]*)$")
        if spell then
            return {
                kind = "rank", prefix = rank, start = wordAbs + #spell + 1, spell = spell,
                command = cmd, base = Parser.actionCommands[cmd],
            }
        end
        if word:find("%(.*%)") then return nil end
        return { kind = "action", prefix = word, start = wordAbs, command = cmd, base = Parser.actionCommands[cmd] }
    end
    return nil
end

-- Replace the word described by `ctx` with `insert`. Returns new text and new cursor (bytes before it).
function Parser.Apply(text, cursor, ctx, insert)
    local newText = text:sub(1, ctx.start - 1) .. insert .. text:sub(cursor + 1)
    return newText, ctx.start - 1 + #insert
end

return Parser
