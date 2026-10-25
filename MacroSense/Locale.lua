-- Player-facing text in the chosen language. L["English text"] is its translation, or the English text itself
-- when there is none. Texts are looked up when they are shown, so the language only has to be known by then: it
-- is MacroSense's own setting (ns.db.language), as the game has no Ukrainian client. Pure Lua (5.1).
local _, ns = ...
ns = ns or {}

ns.locales = ns.locales or {} -- language -> { [English text] = translation }; Ukrainian.lua fills "uk"

local current = {}
ns.L = setmetatable({}, { __index = function(_, text) return current[text] or text end })
ns.language = "en"

-- "en" or "uk"; anything else is English.
function ns.SetLanguage(language)
    current = ns.locales[language] or {}
    ns.language = ns.locales[language] and language or "en"
end

-- `n` with its noun in the chosen language, from English "%d macro" (`one`) and "%d macros" (`other`). Ukrainian
-- has three forms, for 1 (21, 31...), for 2-4 (22-24...) and for the rest: the translation of `other` lists them.
function ns.Plural(n, one, other)
    local forms = current[other]
    if type(forms) ~= "table" then return string.format(n == 1 and one or other, n) end
    local m10, m100 = n % 10, n % 100
    local form = (m10 == 1 and m100 ~= 11) and 1 or (m10 >= 2 and m10 <= 4 and (m100 < 12 or m100 > 14)) and 2 or 3
    return string.format(forms[form], n)
end

-- `text` in `language`, whatever the language now (a question asked in the language being switched to).
function ns.Translate(language, text)
    return (ns.locales[language] or {})[text] or text
end

return ns.L
