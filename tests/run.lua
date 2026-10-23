-- Plain Lua tests for the parser and completion: `lua tests/run.lua` from the repo root.
local ns = {}
for _, file in ipairs({ "Parser.lua", "Data.lua", "Themes.lua", "Completion.lua", "Highlight.lua", "Shortcuts.lua" }) do
    assert(loadfile("MacroSense/" .. file))("MacroSense", ns)
end
ns.sources.spells = function()
    return {
        { name = "Fireball", ranks = { "Rank 1", "Rank 2", "Rank 3" } }, { name = "Fire Blast", ranks = {} },
        { name = "Frostbolt", ranks = { "Rank 1" } }, { name = "Polymorph", ranks = {} },
    }
end
ns.sources.items = function()
    return {
        { name = "Healthstone", usable = true },
        { name = "Fire Ring", equippable = true },
        { name = "Hearthstone", usable = true },
    }
end

local failed, passed = 0, 0
local function check(name, cond, detail)
    if cond then passed = passed + 1 else
        failed = failed + 1
        print("FAIL " .. name .. (detail and (": " .. detail) or ""))
    end
end

-- "|" marks the cursor.
local function ctx(src)
    local cursor = src:find("|", 1, true) - 1
    return ns.Parser.GetContext(src:sub(1, cursor) .. src:sub(cursor + 2), cursor)
end

local function expect(src, kind, prefix, extra)
    local c = ctx(src)
    local got = c and (c.kind .. " '" .. c.prefix .. "'") or "nil"
    local ok = c ~= nil and c.kind == kind and c.prefix == prefix
    for k, v in pairs(extra or {}) do ok = ok and c[k] == v end
    check(src, ok, "got " .. got)
end

local function expectNil(src)
    local c = ctx(src)
    check(src, c == nil, c and ("got " .. c.kind) or nil)
end

expect("/|", "command", "")
expect("/ca|", "command", "ca")
expect("#showtooltip\n/ca|", "command", "ca")
expect("#sh|", "meta", "sh")
expect("#showtooltip Fire|", "action", "Fire")
expect("/cast [|", "condition", "")
expect("/cast [comb|", "condition", "comb")
expect("/cast [combat,ha|", "condition", "ha")
expect("/cast [combat, ha|", "condition", "ha")
expect("/cast [@|", "unit", "")
expect("/cast [@mouse|", "unit", "mouse")
expect("/cast [target=fo|", "unit", "fo")
expect("/cast [mod:|", "modifier", "")
expect("/cast [mod:shift/c|", "modifier", "c")
expect("/cast [nomod:a|", "modifier", "a")
expect("/cast [btn:|", "conditionValue", "", { condition = "btn" })
expect("/cast |", "action", "")
expect("/cast Fire|", "action", "Fire")
expect("/cast [mod:shift] Poly|", "action", "Poly")
expect("/cast [mod:shift] Polymorph; Fro|", "action", "Fro")
expect("/cast [mod:shift] Polymorph; [@focus] |", "action", "")
expect("/cast !Fro|", "action", "Fro")
expect("/castsequence reset=10 Fireball, Fro|", "action", "Fro")
expect("/castsequence reset=10 Fire|", "action", "Fire")
expect("/target [@|", "unit", "")
expect("/cast Fireball(Ra|", "rank", "Ra", { spell = "Fireball" })
expect("/cast [mod] !Fireball(|", "rank", "", { spell = "Fireball" })
expectNil("/cast Fireball(Rank 3)|")
expectNil("/castsequence reset=1|")
expectNil("/say hel|")
expectNil("just text|")

-- Apply replaces only the word under the cursor.
do
    local text = "/cast [mod:sh] Fireball"
    local cursor = #"/cast [mod:sh"
    local c = ns.Parser.GetContext(text, cursor)
    local newText, newCursor = ns.Parser.Apply(text, cursor, c, "shift")
    check("apply modifier", newText == "/cast [mod:shift] Fireball", newText)
    check("apply cursor", newCursor == #"/cast [mod:shift", tostring(newCursor))
end

-- Completion.
local function names(src)
    local out = {}
    for _, item in ipairs(ns.Completion.Get(ctx(src))) do out[#out + 1] = item.name end
    return table.concat(out, ",")
end

check("spells by prefix", names("/cast Fi|") == "Fireball,Fire Blast", names("/cast Fi|"))
check("spells substring after prefix", names("/cast bol|") == "Frostbolt", names("/cast bol|"))
check("modifiers", names("/cast [mod:|") == "shift,ctrl,alt", names("/cast [mod:|"))
check("complete word hides list", names("/cast [mod:shift|") == "", names("/cast [mod:shift|"))
check("commands first", names("/cas|"):find("^cast,castsequence,castrandom") ~= nil, names("/cas|"))
local modItem = ns.Completion.Get(ctx("/cast [mo|"))[1]
check("condition with value inserts ':'", modItem and modItem.insert == "mod:", modItem and modItem.insert)
local castItem = ns.Completion.Get(ctx("/cas|"))[1]
check("command inserts space", castItem and castItem.insert == "cast ", castItem and castItem.insert)

-- Items: /equip wants gear, /use puts items first, /cast puts spells first.
check("equip items", names("/equip F|") == "Fire Ring", names("/equip F|"))
check("equipslot skips slot", names("/equipslot 13 F|") == "Fire Ring", names("/equipslot 13 F|"))
check("use items first", names("/use He|") == "Healthstone,Hearthstone", names("/use He|"))
check("cast spells then items", names("/cast Fi|") == "Fireball,Fire Blast", names("/cast Fi|"))
check("cast includes usable items", names("/cast Heal|") == "Healthstone", names("/cast Heal|"))

-- Ranks: a complete spell name with 2+ learned ranks offers them, highest first.
check("ranks after spell", names("/cast Fireball|") == "Rank 3,Rank 2,Rank 1", names("/cast Fireball|"))
local rank = ns.Completion.Get(ctx("/cast Fireball|"))[1]
check("rank inserts spell(rank)", rank and rank.insert == "Fireball(Rank 3)", rank and rank.insert)
check("ranks case-insensitive", names("/cast fireball|") == "Rank 3,Rank 2,Rank 1", names("/cast fireball|"))
check("single rank: no list", names("/cast Frostbolt|") == "", names("/cast Frostbolt|"))
check("no ranks: no list", names("/cast Polymorph|") == "", names("/cast Polymorph|"))
check("ranks after (", names("/cast Fireball(|") == "Rank 3,Rank 2,Rank 1", names("/cast Fireball(|"))
check("ranks filtered", names("/cast Fireball(rank 2|") == "", names("/cast Fireball(rank 2|"))
local inner = ns.Completion.Get(ctx("/cast Fireball(R|"))[1]
check("rank after ( inserts rank)", inner and inner.insert == "Rank 3)", inner and inner.insert)
do
    local text = "/cast Fireball"
    local c = ns.Parser.GetContext(text, #text)
    check("apply rank", ns.Parser.Apply(text, #text, c, "Fireball(Rank 3)") == "/cast Fireball(Rank 3)")
end

-- Highlighting.
local H = ns.Highlight
local function kinds(raw)
    local out = {}
    for _, sp in ipairs(H.Spans(raw)) do out[#out + 1] = raw:sub(sp[1], sp[2]) .. "=" .. sp[3] end
    return table.concat(out, " ")
end
local function expectKinds(raw, want)
    local got = kinds(raw)
    check("spans " .. raw, got == want, "\n  got  " .. got .. "\n  want " .. want)
end
expectKinds("/cast [@focus,mod:shift] Polymorph; Fireball",
    "/cast=command [=bracket @=operator focus=unit ,=operator mod=condition :=operator shift=value ]=bracket"
    .. " Polymorph=action ;=operator Fireball=action")
expectKinds("#showtooltip Fireball", "#showtooltip=meta Fireball=action")
expectKinds("/cast Fireball(Rank 3); X", "/cast=command Fireball=action (Rank 3)=value ;=operator X=action")
expectKinds("/cast [nocombat, bogus] !Fire Ball", "/cast=command [=bracket nocombat=condition ,=operator"
    .. " bogus=error ]=bracket !=operator Fire Ball=action")
expectKinds("/castsequence reset=10 A, B", "/castsequence=command reset=10=option A=action ,=operator B=action")
expectKinds("/target [@mouseover] party1", "/target=command [=bracket @=operator mouseover=unit ]=bracket party1=unit")
expectKinds("/cast [mod:shift/ctrl] X", "/cast=command [=bracket mod=condition :=operator shift=value"
    .. " /=operator ctrl=value ]=bracket X=action")
expectKinds("/say hello [x]", "/say=command")
expectKinds("/run if x then print(\"hi\", 5) end", "/run=command if=keyword then=keyword \"hi\"=string 5=number end=keyword")
expectKinds("line one\n/cast A", "/cast=command A=action")
H.isCommand = function(name) return name == "cast" end
expectKinds("/bogus x", "/bogus=error x=option")
H.isCommand = nil

local scheme = { text = "ffffff", command = "111111", action = "222222", operator = "333333",
    bracket = "444444", unit = "555555", condition = "666666", value = "777777", error = "888888", meta = "999999" }
for _, raw in ipairs({
    "/cast [@focus,mod:shift] Polymorph; Fireball",
    "#showtooltip\n/cast [nocombat] A\n/run print(\"a||b\")",
    "", "plain", "/",
}) do
    local colored = H.Colorize(raw, scheme)
    check("strip(colorize) " .. raw, H.Strip(colored) == raw, H.Strip(colored))
    local ok = true
    for cur = 0, #raw do
        local c = H.ToColored(colored, cur)
        if H.ToRaw(colored, c) ~= cur then ok = false end
    end
    check("cursor roundtrip " .. raw, ok)
end
check("colorize wraps", H.Colorize("/cast A", scheme) == "|cff111111/cast|r |cff222222A|r", H.Colorize("/cast A", scheme))

-- macOS shortcuts hit by [mod:cmd].
local S = ns.Shortcuts
local function conflicts(raw, keys)
    local out = {}
    for _, c in ipairs(S.Conflicts(raw, keys)) do out[#out + 1] = c.combo end
    return table.concat(out, ",")
end
check("cmd on Q", conflicts("/cast [mod:cmd] A; B", { "Q" }) == "Cmd+Q", conflicts("/cast [mod:cmd] A; B", { "Q" }))
check("no cmd, no warning", conflicts("/cast [mod:shift] A; B", { "Q" }) == "")
check("nomod:cmd is not cmd", conflicts("/cast [nomod:cmd] A", { "Q" }) == "")
check("cmd on a free key", conflicts("/cast [mod:cmd] A", { "1", "E" }) == "")
check("cmd + shift in one group", conflicts("/cast [mod:cmd,mod:shift] A", { "3" }) == "Cmd+Shift+3",
    conflicts("/cast [mod:cmd,mod:shift] A", { "3" }))
check("shift from the binding", conflicts("/cast [mod:cmd] A", { "SHIFT-Q" }) == "Cmd+Shift+Q",
    conflicts("/cast [mod:cmd] A", { "SHIFT-Q" }))
check("cmd in a list", conflicts("/cast [mod:alt/cmd] A", { "W" }) == "Cmd+W", conflicts("/cast [mod:alt/cmd] A", { "W" }))
check("alt/cmd list does not add alt", conflicts("/cast [mod:alt/cmd] A", { "H" }) == "Cmd+H")
check("modifier: long form", conflicts("/cast [modifier:CMD] A", { "tab" }) == "Cmd+Tab", conflicts("/cast [modifier:CMD] A", { "tab" }))
check("option label", conflicts("/cast [mod:cmd,mod:alt] A", { "ESCAPE" }) == "Cmd+Option+Esc",
    conflicts("/cast [mod:cmd,mod:alt] A", { "ESCAPE" }))
check("unclosed bracket before", conflicts("/cast [@mouse\n/cast [mod:cmd] A", { "Q" }) == "Cmd+Q",
    conflicts("/cast [@mouse\n/cast [mod:cmd] A", { "Q" }))
check("several keys", conflicts("/cast [mod:cmd] A", { "Q", "W" }) == "Cmd+Q,Cmd+W")
check("message one", S.Message(S.Conflicts("/cast [mod:cmd] A", { "Q" })) == "Cmd+Q is a macOS shortcut (quits the game)")
check("message many", S.Message(S.Conflicts("/cast [mod:cmd] A", { "Q", "W" })) == "Cmd+Q, Cmd+W are macOS shortcuts")
check("message none", S.Message({}) == nil)
check("slot 1", S.slotCommand(1) == "ACTIONBUTTON1")
check("slot 13 page 2", S.slotCommand(13) == "ACTIONBUTTON1")
check("slot 30 right bar", S.slotCommand(30) == "MULTIACTIONBAR3BUTTON6")
check("slot 61 bottom left", S.slotCommand(61) == "MULTIACTIONBAR1BUTTON1")
check("slot 80 form bar", S.slotCommand(80) == "ACTIONBUTTON8")
check("slot 150 bar 5", S.slotCommand(150) == "MULTIACTIONBAR5BUTTON6")
check("slot 130 none", S.slotCommand(130) == nil)

-- Every scheme colors every role and UI part.
for _, scheme in ipairs(ns.schemes) do
    local missing = {}
    for _, role in pairs(ns.TOKEN_ROLES) do
        if not (scheme[role] or ""):find("^%x%x%x%x%x%x$") then missing[#missing + 1] = role end
    end
    for _, ui in ipairs({ "bg", "panel", "border", "selection", "accent", "warning", "text", "dim" }) do
        if not (scheme[ui] or ""):find("^%x%x%x%x%x%x$") then missing[#missing + 1] = ui end
    end
    check("scheme " .. scheme.key, #missing == 0, table.concat(missing, ","))
end
check("default scheme exists", ns.FindByKey(ns.schemes, ns.DEFAULT_SCHEME) ~= nil)
check("default font exists", ns.FindByKey(ns.fonts, ns.DEFAULT_FONT) ~= nil)
for _, f in ipairs(ns.fonts) do
    local file = f.path:match("MacroSense\\(.+)$")
    if file then
        local h = io.open("MacroSense/" .. file:gsub("\\", "/"), "rb")
        check("font file " .. f.name, h ~= nil)
        if h then h:close() end
    end
end

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
