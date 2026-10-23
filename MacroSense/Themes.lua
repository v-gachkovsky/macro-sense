-- Fonts and color schemes for the editor window.
local _, ns = ...
ns = ns or {}

local FONT_DIR = "Interface\\AddOns\\MacroSense\\Media\\Fonts\\"

-- Shipped fonts (free licenses, see Media/Fonts/*.txt), then game fonts. LibSharedMedia fonts are added at runtime.
ns.fonts = {
    { key = "dejavu",        name = "DejaVu Sans Mono", path = FONT_DIR .. "DejaVuSansMono.ttf" },
    { key = "jetbrains",     name = "JetBrains Mono",   path = FONT_DIR .. "JetBrainsMono-Regular.ttf" },
    { key = "fira",          name = "Fira Mono",        path = FONT_DIR .. "FiraMono-Regular.ttf" },
    { key = "sourcecodepro", name = "Source Code Pro",  path = FONT_DIR .. "SourceCodePro-Regular.ttf" },
    { key = "inconsolata",   name = "Inconsolata",      path = FONT_DIR .. "Inconsolata-Regular.ttf" },
    { key = "friz",          name = "Friz Quadrata",    path = "Fonts\\FRIZQT__.TTF" },
    { key = "arialn",        name = "Arial Narrow",     path = "Fonts\\ARIALN.TTF" },
}
ns.DEFAULT_FONT = "dejavu"

-- Like VS Code / JetBrains semantic tokens: every macro token has a role, schemes color roles.
-- Token kinds come from Highlight.lua.
ns.TOKEN_ROLES = {
    command = "keyword",       -- /cast
    meta = "directive",        -- #showtooltip
    condition = "property",    -- combat, mod
    value = "enumMember",      -- shift, 1
    unit = "type",             -- @focus
    action = "string",         -- spell / item names
    option = "attribute",      -- reset=10, /click Button
    operator = "punctuation",  -- ; , : / @ !
    bracket = "bracket",       -- [ ]
    keyword = "keyword",       -- Lua in /run
    string = "string",
    number = "number",
    error = "invalid",         -- unknown command or condition
}

-- Colors are "rrggbb". UI: bg, panel, border, selection, accent, text, dim.
-- Palettes follow the built-in themes of VS Code (Dark / Light Modern) and JetBrains IDEs
-- (Dark, Darcula, IntelliJ Light); names are plain words, players need not know the editors.
ns.schemes = {
    {
        key = "darkmodern", name = "Dark",
        bg = "1f1f1f", panel = "181818", border = "2b2b2b", selection = "264f78", accent = "0078d4",
        text = "cccccc", dim = "6e7681",
        keyword = "c586c0", directive = "569cd6", property = "9cdcfe", enumMember = "4fc1ff", type = "4ec9b0",
        string = "ce9178", attribute = "dcdcaa", punctuation = "cccccc", bracket = "ffd700", number = "b5cea8",
        invalid = "f14c4c",
    },
    {
        key = "lightmodern", name = "Light",
        bg = "ffffff", panel = "f8f8f8", border = "e5e5e5", selection = "add6ff", accent = "005fb8",
        text = "3b3b3b", dim = "6e7781",
        keyword = "af00db", directive = "0000ff", property = "001080", enumMember = "0070c1", type = "267f99",
        string = "a31515", attribute = "795e26", punctuation = "3b3b3b", bracket = "0431fa", number = "098658",
        invalid = "cd3131",
    },
    {
        key = "jbdark", name = "Graphite",
        bg = "1e1f22", panel = "2b2d30", border = "393b40", selection = "214283", accent = "3574f0",
        text = "bcbec4", dim = "7a7e85",
        keyword = "cf8e6d", directive = "b3ae60", property = "c77dbb", enumMember = "2aacb8", type = "56a8f5",
        string = "6aab73", attribute = "56a8f5", punctuation = "bcbec4", bracket = "bcbec4", number = "2aacb8",
        invalid = "f75464",
    },
    {
        key = "darcula", name = "Charcoal",
        bg = "2b2b2b", panel = "3c3f41", border = "515151", selection = "214283", accent = "3592c4",
        text = "a9b7c6", dim = "808080",
        keyword = "cc7832", directive = "bbb529", property = "9876aa", enumMember = "6897bb", type = "ffc66d",
        string = "6a8759", attribute = "ffc66d", punctuation = "a9b7c6", bracket = "a9b7c6", number = "6897bb",
        invalid = "bc3f3c",
    },
    {
        key = "intellijlight", name = "Paper",
        bg = "ffffff", panel = "f7f8fa", border = "ebecf0", selection = "a6d2ff", accent = "3574f0",
        text = "080808", dim = "8c8c8c",
        keyword = "0033b3", directive = "9e880d", property = "871094", enumMember = "1750eb", type = "00627a",
        string = "067d17", attribute = "00627a", punctuation = "080808", bracket = "080808", number = "1750eb",
        invalid = "f50000",
    },
    {
        key = "monokai", name = "Monokai",
        bg = "272822", panel = "1e1f1c", border = "414339", selection = "49483e", accent = "a6e22e",
        text = "f8f8f2", dim = "75715e",
        keyword = "f92672", directive = "75715e", property = "66d9ef", enumMember = "ae81ff", type = "fd971f",
        string = "e6db74", attribute = "a6e22e", punctuation = "f8f8f2", bracket = "f8f8f2", number = "ae81ff",
        invalid = "f44747",
    },
    {
        key = "solarized", name = "Solarized Dark",
        bg = "002b36", panel = "00212b", border = "073642", selection = "274642", accent = "268bd2",
        text = "93a1a1", dim = "586e75",
        keyword = "859900", directive = "cb4b16", property = "268bd2", enumMember = "d33682", type = "b58900",
        string = "2aa198", attribute = "6c71c4", punctuation = "93a1a1", bracket = "93a1a1", number = "d33682",
        invalid = "dc322f",
    },
}
ns.DEFAULT_SCHEME = "darkmodern"

function ns.FindByKey(list, key)
    for _, v in ipairs(list) do
        if v.key == key then return v end
    end
end

-- Token kind -> color for Highlight.Colorize.
function ns.TokenColors(scheme)
    local out = { text = scheme.text }
    for kind, role in pairs(ns.TOKEN_ROLES) do out[kind] = scheme[role] or scheme.text end
    return out
end

-- "rrggbb" -> r, g, b (0..1)
function ns.RGB(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end
