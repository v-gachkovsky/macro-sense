-- Typing helpers like in a code editor. Pure Lua (5.1).
local _, ns = ...
ns = ns or {}

local Editing = {}
ns.Editing = Editing

local PAIRS = { ["["] = "]" }
local CLOSERS = { ["]"] = "[" }

-- old/new: raw text before and after one keystroke; cursor: raw cursor after it.
-- Returns the text and cursor to show instead (unchanged when no rule applies):
--   "["          -> "[]" with the cursor inside (when nothing but space or ";" follows)
--   "]" before "]" -> steps over the existing one
--   Backspace on "[" of an empty "[]" -> removes both
function Editing.AutoPair(old, new, cursor)
    if #new == #old + 1 then
        local ch = new:sub(cursor, cursor)
        if new:sub(1, cursor - 1) .. new:sub(cursor + 1) ~= old then return new, cursor end
        local nextCh = new:sub(cursor + 1, cursor + 1)
        local close = PAIRS[ch]
        if close and (nextCh == "" or nextCh:find("[%s;]")) then
            return new:sub(1, cursor) .. close .. new:sub(cursor + 1), cursor
        end
        if CLOSERS[ch] and nextCh == ch then
            return old, cursor
        end
    elseif #new == #old - 1 then
        -- Backspace: the removed character was right before the cursor.
        local removed = old:sub(cursor + 1, cursor + 1)
        if old:sub(1, cursor) .. old:sub(cursor + 2) ~= new then return new, cursor end
        local close = PAIRS[removed]
        if close and new:sub(cursor + 1, cursor + 1) == close then
            return new:sub(1, cursor) .. new:sub(cursor + 2), cursor
        end
    end
    return new, cursor
end

return Editing
