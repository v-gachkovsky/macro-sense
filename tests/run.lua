-- Plain Lua tests for the parser and completion: `lua tests/run.lua` from the repo root.
local ns = {}
for _, file in ipairs({ "Locale.lua", "Ukrainian.lua", "Parser.lua", "Data.lua", "Conditions.lua", "Themes.lua", "Completion.lua", "Highlight.lua", "Shortcuts.lua", "Editing.lua", "Spelling.lua", "Preview.lua", "Shorten.lua", "History.lua", "Share.lua", "Backups.lua", "Wizard.lua", "Questions.lua", "MinimapButton.lua" }) do
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
-- reset= values: after "=" and each "/"; only /castsequence has them.
expect("/castsequence reset=|", "reset", "")
expect("/castsequence reset=1|", "reset", "1")
expect("/castsequence [mod] reset=10/ta|", "reset", "ta")
expectNil("/cast reset=|")
-- Items by where they are: an equipment slot, a bag and its slot; /equipslot takes the slot first.
expect("/use 1|", "slot", "1")
expect("/use 0 |", "bagSlot", "", { bag = 0 })
expect("/use [mod] 2 1|", "bagSlot", "1", { bag = 2 })
expect("/castsequence reset=10 13, 1|", "slot", "1")
expect("/equipslot |", "slot", "")
expect("/equipslot 13 Fire|", "action", "Fire")
expect("/equipslot 13 0 |", "bagSlot", "", { bag = 0 })
expect("/cancelaura 1|", "action", "1")
-- /click: the button, the mouse button, then yes / no for a click on key press.
expect("/click |", "clickButton", "")
expect("/click Act|", "clickButton", "Act")
expect("/click [mod] ActionButton1 |", "clickMouse", "")
expect("/click ActionButton1 Ri|", "clickMouse", "Ri")
expect("/click ActionButton1 LeftButton t|", "clickDown", "t")
expectNil("/click A B true x|")
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
check("modifiers", names("/cast [mod:|"):find("^shift,ctrl,alt,lshift") ~= nil, names("/cast [mod:|"))
check("complete word hides list", names("/cast [mod:shift|") == "", names("/cast [mod:shift|"))
check("commands first", names("/cas|"):find("^cast,castsequence,castrandom") ~= nil, names("/cas|"))
local modItem = ns.Completion.Get(ctx("/cast [mo|"))[1]
check("condition with value inserts ':'", modItem and modItem.insert == "mod:", modItem and modItem.insert)
local nomodItem = ns.Completion.Get(ctx("/cast [nom|"))[1]
check("nomod inserts no ':'", nomodItem and nomodItem.insert == "nomod", nomodItem and nomodItem.insert)
check("nomod: with a value, still the modifiers", names("/cast [nomod:|"):find("^shift,ctrl,alt") ~= nil)
local castItem = ns.Completion.Get(ctx("/cas|"))[1]
check("command inserts space", castItem and castItem.insert == "cast ", castItem and castItem.insert)

-- Two capitals or more find names by the first letters of their words ("DA" -> Demon Armor), small letters by
-- the letters of a word in that order ("nmd" -> nomod), the best fits first.
do
    local spells = ns.sources.spells
    ns.sources.spells = function()
        local out = {}
        for _, name in ipairs({ "Demon Armor", "Dark Pact", "Demon Skin", "Curse of Agony", "Sweeping Strikes",
            "Shadow Word: Pain", "Searing Pain", "Fear", "Fel Armor", "Soul Fire", "Anti-Magic Shell", "Дбайливість",
            "Демонічна броня", "Темний союз", "Іскра", "Іскра життя", "Éclair de givre" }) do
            out[#out + 1] = { name = name, ranks = {} }
        end
        return out
    end
    check("capitals: the first letters of words", names("/cast DA|") == "Demon Armor", names("/cast DA|"))
    check("capitals: just those first, then with more words", names("/cast SP|") == "Searing Pain,Shadow Word: Pain",
        names("/cast SP|"))
    check("capitals: the small words left out", names("/cast CA|") == "Curse of Agony", names("/cast CA|"))
    check("capitals: a small letter for a small word", names("/cast CoA|") == "Curse of Agony", names("/cast CoA|"))
    check("capitals: words after a colon and a hyphen", names("/cast SWP|") == "Shadow Word: Pain"
        and names("/cast AMS|") == "Anti-Magic Shell", names("/cast AMS|"))
    check("capitals with spaces between", names("/cast S W P|") == "Shadow Word: Pain", names("/cast S W P|"))
    check("capitals: each one a word of its own", names("/cast SS|") == "Sweeping Strikes", names("/cast SS|"))
    check("capitals no name has that way: as small letters", names("/cast FEA|") == "Fear", names("/cast FEA|"))
    check("one capital: a letter like any", names("/cast F|") == names("/cast f|") and names("/cast f|") ~= "",
        names("/cast F|"))
    check("small: not the first letters of words", names("/cast da|") == "Dark Pact" and names("/cast ds|") == ""
        and names("/cast coa|") == "", names("/cast da|") .. " / " .. names("/cast ds|") .. " / " .. names("/cast coa|"))
    check("small: a word that starts with it", names("/cast fi|") == "Soul Fire", names("/cast fi|"))
    check("small: a space goes on to the next word", names("/cast sh wo|") == "Shadow Word: Pain"
        and names("/cast curse ag|") == "Curse of Agony", names("/cast sh wo|") .. " / " .. names("/cast curse ag|"))
    check("names that start with it before the rest", names("/cast fe|") == "Fear,Fel Armor,Soul Fire",
        names("/cast fe|"))
    check("a name typed in full: no other fits", names("/cast Fear|") == "", names("/cast Fear|"))
    check("letters inside a word", names("/cast rmo|") == "Demon Armor,Fel Armor", names("/cast rmo|"))
    check("the letters of a word in that order", names("/cast dmn|") == "Demon Armor,Demon Skin"
        and names("/cast swp|") == "Sweeping Strikes", names("/cast dmn|") .. " / " .. names("/cast swp|"))
    check("the letters of a word from its start", names("/cast mnr|") == "", names("/cast mnr|"))
    check("letters of other alphabets", names("/cast Дб|") == "Дбайливість", names("/cast Дб|"))
    check("other alphabets: case doesn't count", names("/cast дб|") == "Дбайливість"
        and names("/cast іск|") == "Іскра,Іскра життя", names("/cast дб|") .. " / " .. names("/cast іск|"))
    check("other alphabets: capitals", names("/cast ДБ|") == "Демонічна броня" and names("/cast ТС|") == "Темний союз"
        and names("/cast ІЖ|") == "Іскра життя", names("/cast ТС|") .. " / " .. names("/cast ІЖ|"))
    check("other alphabets: a name typed in full, small", names("/cast демонічна броня|") == ""
        and names("/cast іскра|") == "Іскра,Іскра життя", names("/cast іскра|"))
    check("letters with accents", names("/cast ÉDG|") == "Éclair de givre" and names("/cast écl|") == "Éclair de givre",
        names("/cast ÉDG|") .. " / " .. names("/cast écl|"))
    ns.sources.spells = spells
end
do
    local out = ns.Completion.Match({ { name = "Fire Blast" }, { name = "fb" } }, "FB")
    check("capitals: a name like them is not a name typed in full", #out == 1 and out[1].name == "Fire Blast",
        out[1] and out[1].name)
    out = ns.Completion.Match({ { name = "Soul Fire" }, { name = "Fireball" } }, "fi")
    check("small: names that start with it before a later word", #out == 2 and out[1].name == "Fireball",
        out[1] and out[1].name)
end
check("conditions by the letters of a word", names("/cast [nmd|") == "nomod", names("/cast [nmd|"))
check("letters inside before letters apart", names("/cast [nd|") == "indoors,nomod,nodead", names("/cast [nd|"))

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
expectKinds("/castsequence reset=10 A, B", "/castsequence=command reset=option ==operator 10=value A=action ,=operator B=action")
expectKinds("/castsequence reset=10/target A", "/castsequence=command reset=option ==operator 10=value /=operator"
    .. " target=value A=action")
expectKinds("/use 13; 0 1", "/use=command 13=value ;=operator 0=value 1=value")
expectKinds("/click [mod] ActionButton1 RightButton true", "/click=command [=bracket mod=condition ]=bracket"
    .. " ActionButton1=action RightButton=value true=value")
expectKinds("/use item:6948", "/use=command item:=option 6948=value")
expectKinds("/equipslot 13 Fire Ring", "/equipslot=command 13=value Fire Ring=action")
expectKinds("/target [@mouseover] party1", "/target=command [=bracket @=operator mouseover=unit ]=bracket party1=unit")
expectKinds("/cast [mod:shift/ctrl] X", "/cast=command [=bracket mod=condition :=operator shift=value"
    .. " /=operator ctrl=value ]=bracket X=action")
expectKinds("/say hello [x]", "/say=command")
expectKinds("/run if x then print(\"hi\", 5) end", "/run=command if=keyword then=keyword \"hi\"=string 5=number end=keyword")
expectKinds("line one\n/cast A", "/cast=command A=action")
H.isCommand = function(name) return name == "cast" end
expectKinds("/bogus x", "/bogus=error x=option")
H.isCommand = nil

-- Syntax errors.
local function errs(raw)
    local out = {}
    for _, e in ipairs(H.Errors(raw)) do out[#out + 1] = raw:sub(e.from, e.to) .. "=" .. e.message .. "@" .. e.line end
    return table.concat(out, " | ")
end
local function expectErrs(raw, want)
    local got = errs(raw)
    check("errors " .. raw, got == want, "\n  got  " .. got .. "\n  want " .. want)
end
expectErrs("/cast [@mouseover, harm, nodead] Spell", "")     -- spaces after commas are fine (checked in game)
expectErrs("/cast [@mouseover,harm,nodead][] Spell", "")
expectErrs("/cast [harmm] Spell", 'harmm=unknown condition "harmm"@1')
expectErrs("/cast [harm Spell", "[=[ is not closed with ]@1")
expectErrs("/cast harm] Spell", "]=] without [@1")
expectErrs("/cast [harm,,dead] X", ",=empty condition@1")
expectErrs("/cast [,harm] X", ",=empty condition@1")
expectErrs("/cast [harm,] X", ",=empty condition@1")
expectErrs("/cast [@] X", "@=@ needs a unit@1")
expectErrs("/cast [target=] X", "target==target= needs a unit@1")
expectErrs("/cast [mod:] X", ":=mod: needs a value@1")
expectErrs("/cast [ ] X", "")
expectErrs("#showtooltip\n/cast [nocombat] A\n/cast [bogus] B", 'bogus=unknown condition "bogus"@3')
H.isCommand = function(name) return name == "cast" end
expectErrs("/cats X", '/cats=unknown command "/cats"@1')
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

-- Auto-closing brackets. "|" marks the cursor in `after`.
local function keystroke(before, after)
    local cur = after:find("|", 1, true) - 1
    local new = after:sub(1, cur) .. after:sub(cur + 2)
    local text, c = ns.Editing.AutoPair(before, new, cur)
    return text:sub(1, c) .. "|" .. text:sub(c + 1)
end
local function expectKey(before, after, want)
    local got = keystroke(before, after)
    check("autopair " .. before .. " -> " .. after, got == want, got)
end
expectKey("/cast ", "/cast [|", "/cast [|]")
expectKey("/cast  X", "/cast [| X", "/cast [|] X")
expectKey("/cast A;", "/cast A[|;", "/cast A[|];")
expectKey("/cast X", "/cast [|X", "/cast [|X")              -- a word follows: no pair
expectKey("/cast [mod]", "/cast [mod]|]", "/cast [mod]|")   -- typing "]" before "]" steps over
expectKey("/cast [mod", "/cast [mod]|", "/cast [mod]|")      -- no "]" ahead: inserted normally
expectKey("/cast []", "/cast |]", "/cast |")                -- backspace in "[]" removes both
expectKey("/cast [x]", "/cast |x]", "/cast |x]")            -- not empty: only "["
expectKey("/cast ", "/cast a|", "/cast a|")

-- Condition values and units.
local C = ns.Conditions
for _, u in ipairs({ "player", "target", "focus", "mouseover", "party1", "party4", "raid40", "arena5", "boss8",
    "partypet2", "targettarget", "focustargettarget", "party1target", "arena1pet", "pettarget", "Mouseover",
    "nameplate12", "none", "cursor", "softenemy" }) do
    check("unit " .. u, C.IsUnit(u))
end
for _, u in ipairs({ "mousover", "party5", "party0", "raid41", "raid01", "Thrall", "targettarg", "boss", "party" }) do
    check("not a unit " .. u, not C.IsUnit(u))
end
check("base noform", C.Base("noform") == "form")
check("base stance", C.Base("stance") == "form")
check("base nomodifier", C.Base("nomodifier") == "mod")
check("combat takes no value", not C.TakesValue("combat"))
check("nopet takes a value", C.TakesValue("nopet"))
for _, ok in ipairs({ { "mod", "shift" }, { "mod", "LSHIFT" }, { "mod", "SELFCAST" }, { "btn", "2" },
    { "btn", "RightButton" }, { "group", "raid" }, { "bar", "6" }, { "form", "0" }, { "stance", "3" }, { "spec", "2" },
    { "equipped", "Shields" }, { "pet", "Fluffy" } }) do
    check("valid " .. ok[1] .. ":" .. ok[2], C.CheckValue(ok[1], ok[2]) == nil, C.CheckValue(ok[1], ok[2]))
end
for _, bad in ipairs({ { "mod", "shfit" }, { "btn", "7" }, { "button", "Left" }, { "group", "arena" },
    { "bar", "7" }, { "bar", "x" }, { "form", "1.5" }, { "spec", "0" } }) do
    check("invalid " .. bad[1] .. ":" .. bad[2], C.CheckValue(bad[1], bad[2]) ~= nil)
end
check("invalid message", C.CheckValue("btn", "7") == 'invalid btn value "7" (expected 1-5 or a button name)',
    C.CheckValue("btn", "7"))

ns.sources.forms = function() return { { name = "0", hint = "no form" }, { name = "1", hint = "Bear Form" } } end
ns.sources.specs = function() return { { name = "1", hint = "Affliction" }, { name = "2", hint = "Demonology" } } end
ns.sources.itemTypes = function() return { { name = "Shields" }, { name = "Daggers" } } end
check("form values", names("/cast [form:|") == "0,1", names("/cast [form:|"))
check("noform values", names("/cast [noform:|") == "0,1", names("/cast [noform:|"))
check("stance values", names("/cast [stance:|") == "0,1")
check("spec values", names("/cast [spec:|") == "1,2")
check("equipped values", names("/cast [equipped:Sh|") == "Shields")
check("group values", names("/cast [group:|") == "party,raid")
check("bar values", names("/cast [bar:|") == "1,2,3,4,5,6")
check("btn names", names("/cast [btn:Ri|") == "RightButton", names("/cast [btn:Ri|"))
check("second value after /", names("/cast [btn:1/|"):find("^1,2,3") ~= nil)
check("unit suffixes", names("/cast [@party1|"):find("party1target") ~= nil, names("/cast [@party1|"))
check("unit suffix filtered", names("/cast [@party1t|") == "party1target", names("/cast [@party1t|"))
check("chained suffix", names("/cast [@focustarget|"):find("focustargettarget") ~= nil, names("/cast [@focustarget|"))
check("exact word hides inner matches", names("/cast [mod:shift|") == "")
check("reset values", names("/castsequence reset=|") == "target,combat,shift,ctrl,alt,5,10,30",
    names("/castsequence reset=|"))
check("reset: not the ones used", names("/castsequence reset=target/|") == "combat,shift,ctrl,alt,5,10,30",
    names("/castsequence reset=target/|"))
check("reset: one number", names("/castsequence reset=15/|") == "target,combat,shift,ctrl,alt",
    names("/castsequence reset=15/|"))
check("reset: by prefix", names("/castsequence reset=c|") == "combat,ctrl", names("/castsequence reset=c|"))
do
    ns.sources.clickButtons = function() return { { name = "ActionButton1", hint = "Fireball" }, { name = "BT4Button1" } } end
    check("click: the buttons there are", names("/click |") == "ActionButton1,BT4Button1", names("/click |"))
    check("click: by name", names("/click bt|") == "BT4Button1", names("/click bt|"))
    ns.sources.clickButtons = nil
end
check("click: mouse buttons", names("/click X |") == "LeftButton,RightButton,MiddleButton,Button4,Button5",
    names("/click X |"))
check("click: then true", names("/click X LeftButton |") == "true", names("/click X LeftButton |"))
check("slots after a digit", names("/use 1|") == "1,10,11,12,13,14,15,16,17,18,19", names("/use 1|"))
do
    local items = ns.Completion.Get(ctx("/equipslot |"))
    check("equipslot: every slot, with its name", #items == 19 and items[13].name == "13" and items[13].hint == "Trinket 1",
        items[13] and items[13].hint)
end

-- Issues with severity.
local function issues(raw)
    local out = {}
    for _, e in ipairs(H.Errors(raw)) do out[#out + 1] = e.severity .. ":" .. raw:sub(e.from, e.to) end
    return table.concat(out, " ")
end
check("unknown unit is a warning", issues("/cast [@mousover] X") == "warning:mousover", issues("/cast [@mousover] X"))
check("player name is only a warning", issues("/cast [target=Thrall] X") == "warning:Thrall")
check("bad value is an error", issues("/cast [btn:7] X") == "error:7", issues("/cast [btn:7] X"))
check("second bad value", issues("/cast [mod:shift/shfit] X") == "error:shfit", issues("/cast [mod:shift/shfit] X"))
check("nomod: alone or with modifiers", issues("/cast [nomod] X; [nomod:shift/ctrl] Y; [nomodifier:alt] Z") == "",
    issues("/cast [nomod] X; [nomod:shift/ctrl] Y; [nomodifier:alt] Z"))
check("nomod: a bad modifier", issues("/cast [nomod:shfit] X") == "error:shfit", issues("/cast [nomod:shfit] X"))
check("value for a no-value condition", issues("/cast [combat:1] X") == "error::1", issues("/cast [combat:1] X"))
check("reset: a bad value", issues("/castsequence reset=10/tagret A, B") == "error:tagret",
    issues("/castsequence reset=10/tagret A, B"))
check("reset: good values in any case", issues("/castsequence [mod] reset=Target/COMBAT/5/shift A, B") == "",
    issues("/castsequence [mod] reset=Target/COMBAT/5/shift A, B"))
check("reset: no fraction of a second", issues("/castsequence reset=1.5 A, B") == "error:1.5")
check("reset: a value is needed", issues("/castsequence reset= A, B") == "error:=", issues("/castsequence reset= A, B"))
check("reset: only in /castsequence", issues("/cast reset=10 Fireball") == "error:reset=10",
    issues("/cast reset=10 Fireball"))
check("slots: one that doesn't exist", issues("/use 23") == "error:23" and issues("/use [mod] 20; 13") == "error:20",
    issues("/use 23"))
check("slots: 0 is fine for /use (Classic's ammo, or a bag on its way)", issues("/use 0") == "")
check("slots: not for /equipslot", issues("/equipslot 0 Fire Ring") == "error:0", issues("/equipslot 0 Fire Ring"))
check("slots: fine ones", issues("/use 13\n/use 0 1\n/castsequence 13, 14\n#showtooltip 14\n/use item:6948") == "",
    issues("/use 13\n/use 0 1\n/castsequence 13, 14\n#showtooltip 14\n/use item:6948"))
check("item: needs a number", issues("/use item:abc") == "error:item:abc", issues("/use item:abc"))
check("equipslot: the slot first", issues("/equipslot Fire Ring") == "error:Fire Ring", issues("/equipslot Fire Ring"))
check("equipslot: then the item", issues("/equipslot 13") == "error:13", issues("/equipslot 13"))
check("equipslot: a real slot", issues("/equipslot 20 Fire Ring") == "error:20", issues("/equipslot 20 Fire Ring"))
check("equipslot: an item from a bag", issues("/equipslot 16 0 3") == "", issues("/equipslot 16 0 3"))
check("click: down reads as no", issues("/click X LeftButton down") == "warning:down", issues("/click X LeftButton down"))
check("click: yes and no the game reads", issues("/click X LeftButton true\n/click X LeftButton 1\n/click X LeftButton false") == "")
check("click: a mouse button misspelled", issues("/click X RigthButton") == "warning:RigthButton",
    issues("/click X RigthButton"))
do
    local typo = H.Errors("/click X RigthButton")[1]
    check("click: with its fix", typo and typo.fix == "RightButton", typo and typo.fix)
end
check("click: other words go to the button as they are", issues("/click X Keybind\n/click X Button7\n/click X leftbutton") == "warning:leftbutton",
    issues("/click X Keybind\n/click X Button7\n/click X leftbutton"))
H.checkClick = function(name) return name == "Nope" and "no button" or nil end
check("click: a button that isn't there", issues("/click [mod] Nope; ActionButton1") == "warning:Nope",
    issues("/click [mod] Nope; ActionButton1"))
H.checkClick = nil
check("good values pass", issues("/cast [@party1target,mod:SELFCAST,form:1,group:raid,btn:RightButton] X") == "",
    issues("/cast [@party1target,mod:SELFCAST,form:1,group:raid,btn:RightButton] X"))

-- Spelling: typos of known names.
local S2 = ns.Spelling
check("swap is one typo", S2.Distance("Shadwo Bolt", "Shadow Bolt", 3) == 1)
check("missing letter", S2.Distance("Firebal", "Fireball", 3) == 1)
check("case does not count", S2.Distance("fear", "Fear", 1) == 0)
check("gives up over the limit", S2.Distance("Drain Mana", "Drain Life", 2) == 3)
check("suggest typo", S2.Suggest("Shadwo Bolt", { "Searing Pain", "Shadow Bolt" }) == "Shadow Bolt")
check("suggest picks the closest", S2.Suggest("Curse of Agny", { "Curse of Agony", "Curse of Doom" }) == "Curse of Agony")
check("short names get no guess", S2.Suggest("Feat", { "Fear" }) == nil)
check("not close enough", S2.Suggest("Drain Mana", { "Drain Life", "Drain Soul" }) == nil)
check("nothing close", S2.Suggest("Seduction", { "Spell Lock", "Fear" }) == nil)

-- The typo check on real macros: no false alarms, and a typo gets its fix.
local known = { "Bane of Agony", "Corruption", "Summon Voidwalker", "Summon Imp", "Summon Succubus", "Drain Life",
    "Drain Soul", "Drain Mana", "Fear", "Lesser Healthstone", "Create Healthstone", "Create Soulstone",
    "Health Funnel", "Immolate", "Curse of the Elements", "Spell Lock", "Seduction", "Sacrifice",
    "Consume Shadows", "Fire Shield", "Lash of Pain", "Devour Magic", "Curse of Tongues", "Curse of Exhaustion",
    "Minor Soulstone", "Curse of Recklessness", "Curse of Weakness", "Wool Bandage", "Cannibalize", "Shoot" }
local function useKnown(list)
    local set = {}
    for _, n in ipairs(list) do set[n:lower()] = true end
    H.checkAction = function(name)
        if set[name:lower()] then return nil end
        local guess = S2.Suggest(name, list)
        return guess and { message = "unknown name", short = 'did you mean "' .. guess .. '"?', fix = guess } or nil
    end
end
useKnown(known)
local fixtures = dofile("tests/fixtures/macros.lua")
for name, body in pairs(fixtures) do
    local found = {}
    for _, e in ipairs(H.Errors(body)) do found[#found + 1] = e.severity .. ":" .. body:sub(e.from, e.to) end
    check("no false alarms in macro " .. name, #found == 0, table.concat(found, ", "))
end
do
    local typo = "/cast [@mouseover,harm,nodead] Bane of Agny; Bane of Agony"
    local e = H.Errors(typo)[1]
    check("typo found", e and typo:sub(e.from, e.to) == "Bane of Agny" and e.severity == "warning")
    check("typo fix", e and e.fix == "Bane of Agony" and e.short == 'did you mean "Bane of Agony"?', e and e.short)
    local ranked = H.Errors("/cast [nomod] Summon Voidwalkr(Summon)")[1]
    check("typo before a rank", ranked and ranked.fix == "Summon Voidwalker", ranked and ranked.fix)
    local bang = H.Errors("/cast !Shoto")[1]
    check("typo after !", bang and bang.fix == "Shoot" and bang.from == #"/cast !" + 1, bang and bang.fix)
    check("no guess for a short name", #H.Errors("/cast Fera") == 0)
    local seq = H.Errors("/castsequence reset=10 Corruption, Imolate")[1]
    check("typo in a sequence", seq and seq.fix == "Immolate", seq and seq.fix)
    local tip = H.Errors("#showtooltip Corrupton")[1]
    check("typo in #showtooltip", tip and tip.fix == "Corruption", tip and tip.fix)
end
-- A spell of a pet that is not out (not known now) and close to nothing: no warning.
local withoutSeduction = {}
for _, n in ipairs(known) do if n ~= "Seduction" then withoutSeduction[#withoutSeduction + 1] = n end end
useKnown(withoutSeduction)
check("pet spell not known now: quiet", #H.Errors(fixtures.petCC) == 0)
H.checkAction = nil

-- Live preview: what each line does now, for a game state (tests/fakeparse.lua stands in for the game).
local P = ns.Preview
local fakeParse = dofile("tests/fakeparse.lua")
local noteColors = { action = "aaaaaa", unit = "bbbbbb", text = "cccccc", dim = "dddddd", warning = "eeeeee" }
-- The notes without colors, " | " between lines.
local function preview(body, state, env, skip)
    local results = P.Evaluate(body, env or { parse = fakeParse(state or {}) }, skip)
    local out = {}
    for i = 1, results.n do
        out[i] = P.Note(results[i], noteColors):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    end
    return table.concat(out, " | ")
end
local function expectPreview(label, body, state, want, env, skip)
    local got = preview(body, state, env, skip)
    check("preview " .. label, got == want, "\n  got  " .. got .. "\n  want " .. want)
end
local harmful = { harm = true }
-- The author's macros: modifiers pick the line, and #showtooltip follows.
expectPreview("demons, no modifier", fixtures.demons, {},
    "icon: Summon Voidwalker | Summon Voidwalker | no match | no match")
expectPreview("demons, alt", fixtures.demons, { mods = { alt = true } },
    "icon: Summon Imp | no match | Summon Imp | no match")
expectPreview("demons, cmd", fixtures.demons, { mods = { cmd = true } },
    "icon: Summon Succubus | no match | no match | Summon Succubus")
expectPreview("drains, alt", fixtures.drains, { mods = { alt = true } }, "icon: Drain Soul | no match | Drain Soul | no match")
-- @mouseover: only a living enemy under the mouse takes the first branch.
expectPreview("agony, no mouseover", fixtures.agony, {}, "icon: Bane of Agony | Bane of Agony")
expectPreview("agony on an enemy", fixtures.agony, { units = { mouseover = harmful } },
    "icon: Bane of Agony | Bane of Agony @mouseover")
expectPreview("agony on a dead enemy", fixtures.agony, { units = { mouseover = { harm = true, dead = true } } },
    "icon: Bane of Agony | Bane of Agony")
expectPreview("agony on a friend", fixtures.agony, { units = { mouseover = { harm = false } } },
    "icon: Bane of Agony | Bane of Agony")
expectPreview("fear: stopcasting runs", fixtures.fear, {}, "icon: Fear | runs | Fear")
expectPreview("slow, alt on an enemy", fixtures.slow, { mods = { alt = true }, units = { mouseover = harmful } },
    "icon: Curse of Tongues | Curse of Tongues @mouseover")
expectPreview("slow, alt", fixtures.slow, { mods = { alt = true } }, "icon: Curse of Tongues | Curse of Tongues")
expectPreview("slow, no modifier", fixtures.slow, {}, "icon: Curse of Exhaustion | Curse of Exhaustion")
-- The icon comes from the first line that casts something now.
expectPreview("healthstone, no modifier", fixtures.healthstone, {}, "icon: Lesser Healthstone | Lesser Healthstone | no match")
expectPreview("healthstone, shift", fixtures.healthstone, { mods = { shift = true } },
    "icon: Create Soulstone | no match | Create Soulstone")
expectPreview("healthstone, ctrl", fixtures.healthstone, { mods = { ctrl = true } },
    "icon: Health Funnel | no match | Health Funnel")
-- The pet out decides.
expectPreview("petCC, Felhunter", fixtures.petCC, { pet = "Felhunter" }, "icon: Spell Lock | Spell Lock")
expectPreview("petCC, Succubus on an enemy", fixtures.petCC, { pet = "Succubus", units = { mouseover = harmful } },
    "icon: Seduction | Seduction @mouseover")
expectPreview("petCC, no pet", fixtures.petCC, {}, "icon: ? | no match")
expectPreview("petSpells, Voidwalker + alt", fixtures.petSpells, { pet = "Voidwalker", mods = { alt = true } },
    "icon: Sacrifice | Sacrifice")
expectPreview("petSpells, Voidwalker", fixtures.petSpells, { pet = "Voidwalker" }, "icon: Consume Shadows | Consume Shadows")
expectPreview("petSpells, Imp", fixtures.petSpells, { pet = "Imp" }, "icon: Fire Shield | Fire Shield @player")
expectPreview("petSpells, Felhunter + alt", fixtures.petSpells, { pet = "Felhunter", mods = { alt = true } },
    "icon: Devour Magic | Devour Magic @player")
expectPreview("petSpells, Felhunter on a unit", fixtures.petSpells, { pet = "Felhunter", units = { mouseover = {} } },
    "icon: Devour Magic | Devour Magic @mouseover")
-- Pet commands: no spell, so no icon; the line that runs says so.
expectPreview("petControl, no modifier", fixtures.petControl, {}, "icon: ? | runs | no match | no match | no match")
expectPreview("petControl, ctrl on an enemy target", fixtures.petControl,
    { mods = { ctrl = true }, units = { target = harmful } }, "icon: ? | no match | runs | no match | no match")
expectPreview("petControl, ctrl on an enemy mouseover", fixtures.petControl,
    { mods = { ctrl = true }, units = { mouseover = harmful } }, "icon: ? | no match | runs @mouseover | no match | no match")
expectPreview("petControl, shift", fixtures.petControl, { mods = { shift = true } }, "icon: ? | no match | no match | runs | no match")
expectPreview("petControl, alt", fixtures.petControl, { mods = { alt = true } }, "icon: ? | no match | no match | no match | runs")
expectPreview("shot: ! and an empty group", fixtures.shot, {}, "icon: Shoot | Shoot")
expectPreview("cannibalize: the rank is not shown", fixtures.cannibalize, { mods = { alt = true } },
    "icon: Cannibalize | no match | Cannibalize")
expectPreview("bare #showtooltip", fixtures.bh, {}, "icon: ?")
expectPreview("emote", fixtures.kiss, {}, "runs")
expectPreview("empty macro", fixtures.yfyt, {}, "")
-- Every macro gets a note per line without errors.
for name, body in pairs(fixtures) do
    local ok = pcall(preview, body, { mods = { alt = true }, pet = "Imp", units = { mouseover = harmful } })
    check("preview runs for macro " .. name, ok)
end
-- /stopmacro: the lines after it are not reached.
local stop = "/stopmacro [nocombat]\n/cast Fireball\n\n/say hi\n# a comment"
expectPreview("stopmacro stops", stop, {}, "stops here | not reached |  | not reached | ")
expectPreview("stopmacro in combat", stop, { combat = true }, "no match | Fireball |  | chat | ")
-- #showtooltip with a name, or with conditions of its own.
local tip = "#showtooltip [mod:alt] Fear; Corruption\n/cast Shadow Bolt"
expectPreview("showtooltip names the icon", tip, {}, "icon: Corruption | Shadow Bolt")
expectPreview("showtooltip with alt", tip, { mods = { alt = true } }, "icon: Fear | Shadow Bolt")
expectPreview("showtooltip no clause: question mark", "#showtooltip [mod:alt] Fear\n/cast Shadow Bolt", {},
    "icon: ? | Shadow Bolt")
expectPreview("#show", "#show\n/use [combat] Healthstone; 13", {}, "icon: Trinket 1 | Trinket 1")
-- Other commands.
expectPreview("sequence: the list", "#showtooltip\n/castsequence reset=10 Corruption, !Immolate", {},
    "icon: Corruption | Corruption, Immolate")
expectPreview("sequence: the next step from the game", "#showtooltip\n/castsequence reset=10 Corruption, !Immolate", nil,
    "icon: Immolate | Immolate (2/2)",
    -- QueryCastSequence: index, item, spell, the spell in lower case.
    { parse = fakeParse({}), sequenceStep = function(s) return s == "reset=10 Corruption, !Immolate" and 2, nil, "immolate" end })
expectPreview("random", "/castrandom Fear, Howl of Terror", {}, "Fear, Howl of Terror")
expectPreview("equip", "/equip Fire Ring\n/equipslot 13 Healthstone", {}, "equip Fire Ring | equip Healthstone")
expectPreview("an item by its slot", "/use 13\n/use 0 1\n/use 23", {}, "Trinket 1 | bag 0, slot 1 | slot 23")
expectPreview("cancelaura", "/cancelaura [combat] Demon Armor; Fel Armor", {}, "cancel Fel Armor")
expectPreview("an empty clause casts nothing", "/cast [mod:alt]; Fear", { mods = { alt = true } }, "nothing")
expectPreview("target with a unit", "/target party1\n/focus [@mouseover,exists]", { units = { mouseover = {} } },
    "runs party1 | runs @mouseover")
expectPreview("lua, chat", "/run print(1)\n/s hi\nhello", {}, "Lua | chat | chat")
expectPreview("lines with errors: no note", "/cast [harmm] Fear\n/cast Fear", {}, " | Fear", nil, { [1] = true })
expectPreview("a failing check: no note", "/cast Fear", nil, "", { parse = function() error("no") end })
-- Colors: the spell in the action color, the unit in the unit color, quiet notes dim.
do
    local results = P.Evaluate("/cast [@focus] Fear\n/cast [combat] Fear", { parse = fakeParse({ units = { focus = {} } }) })
    check("note colors", P.Note(results[1], noteColors) == "|cffaaaaaaFear|r|cffbbbbbb @focus|r", P.Note(results[1], noteColors))
    check("quiet note is dim", P.Note(results[2], noteColors) == "|cffddddddno match|r", P.Note(results[2], noteColors))
end

-- Shorten: the same macro in fewer characters.
local conditionalSet = { stopcasting = true, target = true, focus = true, click = true, petattack = true,
    petmoveto = true, petstay = true, petfollow = true }
local function conditional(name)
    return ns.Parser.actionCommands[name] ~= nil or ns.Parser.stopCommands[name] == true or conditionalSet[name] == true
end
local function short(body, skip) return ns.Shorten.Text(body, { conditional = conditional, skip = skip }) end
local function expectShort(label, body, want, skip)
    local got = short(body, skip)
    check("shorten " .. label, got == want, "\n  got  " .. got .. "\n  want " .. want)
end
expectShort("target= becomes @", "/cast [target=focus,harm] Fear", "/cast [@focus,harm]Fear")
expectShort("long condition names", "/cast [modifier:shift,nomodifier:ctrl,button:2,actionbar:1,stance:2,equipped:Shields] X",
    "/cast [mod:shift,nomod:ctrl,btn:2,bar:1,form:2,worn:Shields]X")
expectShort("spaces the game doesn't need", "/cast [ @mouseover , harm ] [mod: shift / ctrl] Fear ; Corruption  ",
    "/cast [@mouseover,harm][mod:shift/ctrl]Fear;Corruption")
expectShort("values keep their own spaces", "/cast [worn:Two-Handed Swords] Overpower", "/cast [worn:Two-Handed Swords]Overpower")
expectShort("the same spell side by side", "/cast [@mouseover,harm,nodead] Fear; Fear", "/cast [@mouseover,harm,nodead][]Fear")
expectShort("alternatives join", "/cast [mod:alt] Fear; [mod:shift] Fear", "/cast [mod:alt/shift]Fear")
expectShort("pets join", "/cast [pet:Succubus,@mouseover,harm][pet:Incubus,@mouseover,harm] Seduction",
    "/cast [pet:Succubus/Incubus,@mouseover,harm]Seduction")
expectShort("in any order", "/cast [harm,pet:Imp][pet:Felhunter,harm] X", "/cast [harm,pet:Imp/Felhunter]X")
expectShort("a group twice", "/cast [harm][harm] Fear", "/cast [harm]Fear")
expectShort("not the no forms", "/cast [nomod:alt][nomod:shift] X", "/cast [nomod:alt][nomod:shift]X")
expectShort("not other units", "/cast [@focus,harm][@target,harm] X", "/cast [@focus,harm][@target,harm]X")
expectShort("not two differences", "/cast [mod:alt,pet:Imp][mod:shift,pet:Felhunter] X", "/cast [mod:alt,pet:Imp][mod:shift,pet:Felhunter]X")
expectShort("not groups apart", "/cast [pet:Imp,@player][@focus][pet:Voidwalker,@player] X",
    "/cast [pet:Imp,@player][@focus][pet:Voidwalker,@player]X")
expectShort("not conditions without a list", "/cast [known:Fear][known:Howl of Terror] X", "/cast [known:Fear][known:Howl of Terror]X")
expectShort("[] alone", "/cast [] Fear", "/cast Fear")
expectShort("[] costs more than a short name", "/cast [mod] X; X", "/cast [mod]X;X")
expectShort("sequence steps", "/castsequence reset=10 Corruption, Immolate , Shadow Bolt",
    "/castsequence reset=10 Corruption,Immolate,Shadow Bolt")
expectShort("random lists", "/castrandom Fear, Howl of Terror", "/castrandom Fear,Howl of Terror")
expectShort("empty lines", "#showtooltip\n\n/cast Fear\n  \n", "#showtooltip\n/cast Fear")
expectShort("#showtooltip", "#showtooltip [mod:alt] Fear; Corruption", "#showtooltip [mod:alt]Fear;Corruption")
expectShort("#showtooltip alone", "#showtooltip ", "#showtooltip")
expectShort("one space after the command", "/cast   Fear", "/cast Fear")
expectShort("leading spaces stay", "  /cast [mod] Fear", "  /cast [mod]Fear")
expectShort("commands without conditions", "/stopcasting  \n/petattack [mod:ctrl, harm]", "/stopcasting\n/petattack [mod:ctrl,harm]")
for _, same in ipairs({ "/say hi ; [mod] x", "/run print( 1 )", "/dance  ", "hello ; world", "# a comment ; x",
    "/cast [mod Fear", "/cast [[mod]] Fear", "/cast Fear [mod]" }) do
    expectShort("leaves alone: " .. same, same, same)
end
expectShort("lines with errors stay", "/cast [harmm] Fear; Fear\n/cast [harm] Fear; Fear",
    "/cast [harmm] Fear; Fear\n/cast [harm][]Fear", { [1] = true })
-- The author's macros, shorter.
expectShort("petSpells", fixtures.petSpells, "#showtooltip\n/cast [pet:Voidwalker,mod:alt]Sacrifice;[pet:Voidwalker]"
    .. "Consume Shadows;[pet:Imp,@player]Fire Shield;[pet:Succubus/Incubus]Lash of Pain;[pet:Felhunter,mod:alt,@player]"
    .. "[pet:Felhunter,@mouseover,exists][pet:Felhunter]Devour Magic")
expectShort("petCC", fixtures.petCC, "#showtooltip\n/cast [pet:Felhunter,@mouseover,harm][pet:Felhunter]Spell Lock;"
    .. "[pet:Succubus/Incubus,@mouseover,harm][pet:Succubus/Incubus]Seduction")
expectShort("slow", fixtures.slow, "#showtooltip\n/cast [mod:alt,@mouseover,harm,nodead][mod:alt]Curse of Tongues;"
    .. "[@mouseover,harm,nodead][]Curse of Exhaustion")
expectShort("petControl: nothing to do", fixtures.petControl, fixtures.petControl)
-- Shortened, a macro does the same in every state (the stand-in for the game's check decides).
do
    local states = {
        {}, { mods = { alt = true } }, { mods = { shift = true } }, { mods = { ctrl = true } }, { mods = { cmd = true } },
        { mods = { alt = true, shift = true } }, { units = { mouseover = harmful } },
        { units = { mouseover = { harm = true, dead = true } } }, { units = { mouseover = {}, focus = harmful } },
        { mods = { alt = true }, units = { mouseover = harmful } }, { pet = "Felhunter" }, { pet = "Imp" },
        { pet = "Succubus", units = { mouseover = harmful } }, { pet = "Incubus" },
        { pet = "Voidwalker", mods = { alt = true } }, { combat = true, mods = { ctrl = true }, units = { target = harmful } },
    }
    local function notes(body, state)
        local results, out = P.Evaluate(body, { parse = fakeParse(state) }), {}
        for i = 1, results.n do
            if results[i] then out[#out + 1] = P.Note(results[i], noteColors) end
        end
        return table.concat(out, " | ")
    end
    local bodies = {}
    for name, body in pairs(fixtures) do bodies[name] = body end
    bodies.alternatives = "/cast [mod:alt] Fear; [mod:shift] Fear; Corruption"
    bodies.noForms = "/cast [nomod:alt][nomod:shift] Fear; Corruption"
    bodies.units = "/cast [@focus,harm][@mouseover,harm][] Fear"
    bodies.apart = "/cast [pet:Imp,@player][@focus,harm][pet:Felhunter,@player] Fear"
    bodies.stop = "/stopmacro [combat]\n/cast [@mouseover,harm] Fear; Fear"
    for name, body in pairs(bodies) do
        local s = short(body)
        local same = true
        for _, state in ipairs(states) do
            if notes(body, state) ~= notes(s, state) then same = false end
        end
        check("shortened does the same: " .. name, same and #s <= #body, s)
    end
end

-- History: versions of a macro's text, oldest first in the store, newest first when offered.
do
    local H = ns.History
    local store = {}
    H.Add(store, "Fear", "/cast Fear", 100)
    H.Add(store, "Fear", "/cast Fear", 200)
    check("history: the same text once in a row", #store.Fear == 1)
    H.Add(store, "Fear", "  \n", 300)
    check("history: an empty text is not a version", #store.Fear == 1)
    H.Add(store, "Fear", "/cast [@focus] Fear", 400)
    H.Add(store, "Fear", "/cast Fear", 500)
    local function bodies(list)
        local out = {}
        for i, v in ipairs(list) do out[i] = v.body end
        return table.concat(out, " | ")
    end
    check("history: newest first, without the saved text", bodies(H.Versions(store, "Fear", "/cast [@focus] Fear"))
        == "/cast Fear", bodies(H.Versions(store, "Fear", "/cast [@focus] Fear")))
    check("history: each text once", bodies(H.Versions(store, "Fear", "x")) == "/cast Fear | /cast [@focus] Fear",
        bodies(H.Versions(store, "Fear", "x")))
    check("history: none for an unknown macro", #H.Versions(store, "Nope", "") == 0)
    for i = 1, 12 do H.Add(store, "Many", "v" .. i, i) end
    check("history: only the last versions are kept", #store.Many == H.LIMIT and store.Many[1].body == "v3",
        #store.Many)
    -- Renamed: the versions move, in time order with any the new name had.
    store.Old, store.New = { { body = "a", time = 1 }, { body = "c", time = 3 } }, { { body = "b", time = 2 } }
    H.Rename(store, "Old", "New")
    check("history: a rename moves the versions", store.Old == nil and bodies(store.New) == "a | b | c",
        store.New and bodies(store.New))
    H.Rename(store, "Gone", "New")
    check("history: renaming a macro without versions changes nothing", bodies(store.New) == "a | b | c")
    -- Trash: a deleted macro goes in, the oldest go out.
    local trash = {}
    for i = 1, H.TRASH + 2 do H.Discard(trash, "M" .. i, { body = "/sit", icon = i }, i) end
    check("trash: the last ones, oldest first", #trash == H.TRASH and trash[1].name == "M3" and trash[1].icon == 3
        and trash[1].body == "/sit" and trash[1].time == 3, #trash)
    local entry, first = trash[2], trash[1]
    check("trash: one taken out", H.TakeOut(trash, entry) and #trash == H.TRASH - 1 and trash[2] ~= entry)
    check("trash: only that one", not H.TakeOut(trash, { name = first.name, icon = first.icon, body = first.body,
        time = first.time }) and #trash == H.TRASH - 1)
    -- Gone: renamed when a new name has its text (each new name once), else deleted.
    local before = { A = { body = "/cast A" }, B = { body = "/cast B" }, C = { body = "/same" }, D = { body = "/same" } }
    local after = { B = { body = "/cast B" }, A2 = { body = "/cast A" }, E = { body = "/same" } }
    local renamed, deleted = H.Gone(before, after)
    check("trash: a rename is no delete", renamed.A == "A2" and renamed.C == "E" and renamed.D == nil
        and #deleted == 1 and deleted[1] == "D", table.concat(deleted, ","))
end

-- Wizard: the form as macro text.
do
    local W = ns.Wizard
    local made = {}
    -- A fresh form with `set` filled in; set.keys = { shift = { action, pet, on = units, or unit = one } } holds keys.
    local function form(set)
        local spec = W.Fresh()
        for k, v in pairs(set) do
            if k == "keys" then
                for key, row in pairs(v) do
                    local k = spec.keys[key]
                    k.active, k.on = true, row.on or { row.unit or "default", "none" }
                    k.action, k.pet, k.reaction = row.action, row.pet or k.pet, row.reaction
                end
            else
                spec[k] = v
            end
        end
        return spec
    end
    local function text(set) return W.Text(form(set)) end
    local function expectText(label, got, want)
        made[label] = got
        check("wizard " .. label, got == want, "\n  got  " .. tostring(got) .. "\n  want " .. want)
    end
    local heal, bolt, stone = { name = "Flash Heal" }, { name = "Frostbolt" }, { name = "Healthstone", item = true }
    local kick, sheep = { name = "Counterspell" }, { name = "Polymorph" }
    local usual = { "default", "none", "none" }

    check("wizard: nothing to cast, no macro", W.Text(W.Fresh()) == nil)
    expectText("mouseover, then as usual", text({ action = heal, only = "friends" }),
        "#showtooltip\n/cast [@mouseover,help,nodead][] Flash Heal")
    expectText("a friend under the mouse, then your target, then you", text({ action = heal, only = "friends",
        on = { "mouseover", "target", "player" } }),
        "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] Flash Heal")
    expectText("an enemy", text({ action = bolt, only = "enemies" }),
        "#showtooltip\n/cast [@mouseover,harm,nodead][] Frostbolt")
    expectText("anyone, dead or alive: but someone", text({ action = bolt, alive = false }),
        "#showtooltip\n/cast [@mouseover,exists][] Frostbolt")
    expectText("as usual alone", text({ action = bolt, on = usual }), "#showtooltip\n/cast Frostbolt")
    expectText("the focus, then as usual", text({ action = kick, only = "enemies", on = { "focus", "default", "none" },
        stopcasting = true }), "#showtooltip\n/stopcasting\n/cast [@focus,harm,nodead][] Counterspell")
    expectText("a party member, then you", text({ action = heal, only = "friends", on = { "party2", "player", "none" } }),
        "#showtooltip\n/cast [@party2,help,nodead][@player] Flash Heal")
    expectText("at the cursor", text({ action = { name = "Blizzard" }, on = { "cursor", "none", "none" } }),
        "#showtooltip\n/cast [@cursor] Blizzard")
    expectText("nothing after one that always holds", text({ action = heal, on = { "player", "mouseover", "target" } }),
        "#showtooltip\n/cast [@player] Flash Heal")
    expectText("a gap in the order", text({ action = heal, only = "friends", on = { "mouseover", "none", "player" } }),
        "#showtooltip\n/cast [@mouseover,help,nodead][@player] Flash Heal")
    expectText("keys: other spells, on their own units", text({ action = bolt, only = "enemies", on = usual,
        keys = { shift = { action = sheep, unit = "focus" }, alt = { action = kick } } }),
        "#showtooltip\n/cast [mod:shift,@focus,harm,nodead] Polymorph; [mod:alt] Counterspell; Frostbolt")
    expectText("keys: the same spell on other units", text({ action = heal, only = "friends",
        on = { "party1", "none", "none" }, keys = { shift = { unit = "party2" }, ctrl = { unit = "party3" },
        alt = { unit = "party4" } } }), "#showtooltip\n/cast [mod:shift,@party2,help,nodead]"
        .. "[mod:ctrl,@party3,help,nodead][mod:alt,@party4,help,nodead][@party1,help,nodead] Flash Heal")
    expectText("keys: a spell of its own is checked for what it is for", text({ action = bolt, only = "enemies",
        reaction = "enemies", keys = { shift = { action = heal, reaction = "friends", unit = "mouseover" },
        alt = { action = sheep, unit = "focus" } } }), "#showtooltip\n/cast [mod:shift,@mouseover,help,nodead] "
        .. "Flash Heal; [mod:alt,@focus,harm,nodead] Polymorph; [@mouseover,harm,nodead][] Frostbolt")
    expectText("keys: the same spell, the form's choice", text({ action = bolt, only = "enemies",
        keys = { shift = { reaction = "friends", unit = "focus" } } }),
        "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][@mouseover,harm,nodead][] Frostbolt")
    check("wizard only: what a key's units are checked for", W.Only(form({ only = "any",
        keys = { shift = { action = heal, reaction = "friends" } } }), "shift") == "friends"
        and W.Only(form({ only = "any", keys = { shift = { action = heal } } }), "shift") == "any"
        and W.Only(form({ command = "focus", only = "enemies",
            keys = { shift = { action = heal, reaction = "friends" } } }), "shift") == "enemies"
        and W.Only(form({ only = "friends" }), nil) == "friends")
    expectText("keys: Shift on yourself", text({ action = heal, only = "friends", keys = { shift = { unit = "player" } } }),
        "#showtooltip\n/cast [mod:shift,@player][@mouseover,help,nodead][] Flash Heal")
    local fire = { name = "Fireball" }
    expectText("keys: a fallback of their own", text({ action = fire, only = "enemies", on = { "mouseover", "target", "none" },
        keys = { alt = { action = bolt, on = { "mouseover", "target" } } } }), "#showtooltip\n/cast "
        .. "[mod:alt,@mouseover,harm,nodead][mod:alt,harm,nodead] Frostbolt; [@mouseover,harm,nodead][harm,nodead] Fireball")
    expectText("keys: then as usual", text({ action = fire, only = "enemies", keys = { alt = { action = bolt,
        on = { "mouseover", "default" } } } }), "#showtooltip\n/cast [mod:alt,@mouseover,harm,nodead][mod:alt] Frostbolt; "
        .. "[@mouseover,harm,nodead][] Fireball")
    expectText("keys: nothing after one that always holds", text({ action = heal, on = usual,
        keys = { shift = { on = { "player", "target" } } } }), "#showtooltip\n/cast [mod:shift,@player][] Flash Heal")
    expectText("keys: Cmd on a Mac, after the others", text({ action = bolt, only = "enemies", on = usual,
        keys = { shift = { action = sheep }, cmd = { action = kick, on = { "focus", "default" } } } }),
        "#showtooltip\n/cast [mod:shift] Polymorph; [mod:cmd,@focus,harm,nodead][mod:cmd] Counterspell; Frostbolt")
    expectText("keys: a key alone", text({ keys = { ctrl = { action = sheep } } }), "#showtooltip\n/cast [mod:ctrl] Polymorph")
    expectText("keys: items with /use", text({ command = "use", action = stone, on = usual,
        keys = { shift = { action = { name = "Major Healing Potion", item = true } } } }),
        "#showtooltip\n/use [mod:shift] Major Healing Potion; Healthstone")
    expectText("keys: the command as chosen", text({ action = bolt, on = usual, keys = { shift = { action = stone } } }),
        "#showtooltip\n/cast [mod:shift] Healthstone; Frostbolt")
    expectText("trinkets, then the spell", text({ action = bolt, on = usual, trinket1 = true, trinket2 = true }),
        "#showtooltip Frostbolt\n/use 13\n/use 14\n/cast Frostbolt")
    expectText("a trinket alone", text({ trinket2 = true }), "#showtooltip\n/use 14")
    expectText("stop the cast, attack, the pet too", text({ action = bolt, only = "enemies", stopcasting = true,
        startattack = true, petattack = true }),
        "#showtooltip\n/stopcasting\n/cast [@mouseover,harm,nodead][] Frostbolt\n/startattack\n/petattack")
    expectText("an item", text({ command = "use", action = { name = "Wool Bandage", item = true }, only = "friends",
        on = { "mouseover", "player", "none" } }), "#showtooltip\n/use [@mouseover,help,nodead][@player] Wool Bandage")
    -- Other commands: a slot for /use; a list for /castsequence (with what starts it over) and /castrandom.
    local slot = { name = "14", item = true, label = "Burning Talisman" }
    expectText("use: a slot", text({ command = "use", action = slot, on = usual }), "#showtooltip\n/use 14")
    local corruption, immolate = { name = "Corruption" }, { name = "Immolate" }
    expectText("castsequence", text({ command = "castsequence", list = { corruption, immolate }, on = usual }),
        "#showtooltip\n/castsequence Corruption, Immolate")
    expectText("castsequence: units for the whole list, what starts it over", text({ command = "castsequence",
        only = "enemies", list = { corruption, nil, immolate }, reset = { timed = true, seconds = 12, target = true,
        combat = true, shift = true } }), "#showtooltip\n/castsequence [@mouseover,harm,nodead][] "
        .. "reset=12/target/combat/shift Corruption, Immolate")
    expectText("castsequence: seconds only when asked", text({ command = "castsequence", list = { corruption, immolate },
        on = usual, reset = { seconds = 30, alt = true } }), "#showtooltip\n/castsequence reset=alt Corruption, Immolate")
    expectText("castrandom: no starting over", text({ command = "castrandom", list = { corruption, immolate },
        on = { "focus", "none", "none" }, only = "enemies", reset = { target = true } }),
        "#showtooltip\n/castrandom [@focus,harm,nodead] Corruption, Immolate")
    expectText("a list with trinkets first", text({ command = "castsequence", list = { corruption, immolate },
        on = usual, trinket1 = true }), "#showtooltip Corruption\n/use 13\n/castsequence Corruption, Immolate")
    check("wizard: a list empty, no macro", W.Text(form({ command = "castsequence", action = bolt })) == nil)
    -- /target, /focus, /assist: units only, keys too; a key may clear; /target by name; the nearest enemy.
    expectText("focus: the mouseover, then your target", text({ command = "focus", on = { "mouseover", "target", "none" } }),
        "/focus [@mouseover,exists,nodead][@target,exists,nodead]")
    expectText("target: party members by key", text({ command = "target", only = "friends", alive = false,
        on = { "party1", "none", "none" }, keys = { shift = { unit = "party2" }, ctrl = { unit = "party3" },
        alt = { unit = "party4" } } }), "/target [mod:shift,@party2,help][mod:ctrl,@party3,help][mod:alt,@party4,help]"
        .. "[@party1,help]")
    expectText("focus: Shift clears it", text({ command = "focus", on = { "mouseover", "target", "none" },
        keys = { shift = { unit = "clear" }, alt = { unit = "clear" } } }), "/clearfocus [mod:shift/alt]\n"
        .. "/stopmacro [mod:shift/alt]\n/focus [@mouseover,exists,nodead][@target,exists,nodead]")
    expectText("target: by name, after the mouseover", text({ command = "target", byName = " Hogger ", only = "enemies",
        on = { "mouseover", "none", "none" } }), "/target [@mouseover,harm,nodead][] Hogger")
    expectText("target: by name only", text({ command = "target", byName = "Hogger", on = { "none", "none", "none" } }),
        "/target Hogger")
    expectText("assist: the tank", text({ command = "assist", alive = false, on = { "party1", "none", "none" } }),
        "/assist [@party1,exists]")
    expectText("target: trinkets show their icon", text({ command = "target", only = "enemies", trinket1 = true,
        on = { "mouseover", "none", "none" } }), "#showtooltip\n/use 13\n/target [@mouseover,harm,nodead]")
    expectText("the nearest enemy when none is targeted", text({ action = bolt, only = "enemies", on = usual,
        nearest = true }), "#showtooltip\n/targetenemy [noharm][dead]\n/cast Frostbolt")
    check("wizard: /focus on nobody, no macro", W.Text(form({ command = "focus", on = { "none", "none", "none" } })) == nil)
    -- The pet: without a key (none of those held), then each key's; Attack on units, Move to at the cursor.
    expectText("pet: attack, and a command per key", text({ command = "pet", only = "enemies", keys = { shift = {},
        ctrl = { pet = "moveto" }, alt = { pet = "attack", on = { "focus", "default" } } } }), "/petattack "
        .. "[nomod:shift/ctrl/alt,@mouseover,harm,nodead][nomod:shift/ctrl/alt]\n/petfollow [mod:shift]\n"
        .. "/petmoveto [mod:ctrl,@cursor]\n/petattack [mod:alt,@focus,harm,nodead][mod:alt]")
    expectText("pet: one command, no key", text({ command = "pet", pet = "stay" }), "/petstay")
    expectText("pet: attack your target", text({ command = "pet", on = usual, nearest = true }),
        "/targetenemy [noharm][dead]\n/petattack")
    expectText("pet: with trinkets, an icon", text({ command = "pet", pet = "passive", trinket2 = true }),
        "#showtooltip\n/use 14\n/petpassive")
    check("wizard name: the pet's", W.Name(form({ command = "pet" })) == "Pet")
    -- Also: out of the form, off the mount, a buff cancelled first; something said in chat last.
    expectText("also: what goes first and what is said", text({ action = bolt, on = usual, cancelform = true,
        dismount = true, cancelaura = { name = "Ice Block" }, say = " Casting on %t ", channel = "party",
        startattack = true }), "#showtooltip\n/cancelform\n/dismount [mounted]\n/cancelaura Ice Block\n"
        .. "/cast Frostbolt\n/startattack\n/party Casting on %t")
    expectText("also: nothing to say, no line", text({ action = bolt, on = usual, say = "  ", channel = "yell" }),
        "#showtooltip\n/cast Frostbolt")
    check("wizard: a name only for /target", text({ command = "focus", byName = "Hogger", on = { "mouseover", "none",
        "none" } }) == "/focus [@mouseover,exists,nodead]")
    check("wizard name: what it targets", W.Name(form({ command = "focus" })) == "Focus"
        and W.Name(form({ command = "target", byName = "Hogger" })) == "Hogger")
    local function keys(list)
        local out = {}
        for i, u in ipairs(list) do out[i] = u.key end
        return table.concat(out, ",")
    end
    check("wizard units: a cast goes anywhere", keys(W.Units("cast", "first")):find("^default,target,mouseover") ~= nil
        and keys(W.Units("cast", "then")):find("^none,default,target") ~= nil, keys(W.Units("cast", "first")))
    check("wizard units: /target, by name or units, not your target", keys(W.Units("target", "first"))
        == "none,mouseover,focus,player,pet,party1,party2,party3,party4,targettarget,arena1,arena2,arena3",
        keys(W.Units("target", "first")))
    check("wizard pet: Move To only from Cataclysm on (Classic Era 0, TBC 1)", not keys(W.PetActions(1)):find("moveto")
        and keys(W.PetActions(3)):find("moveto") ~= nil and keys(W.PetActions(nil)):find("moveto") ~= nil
        and keys(W.PetActions(0)):find("^attack,follow,stay,passive") ~= nil, keys(W.PetActions(1)))
    check("wizard units: the pet attacks neither the cursor, you nor itself", keys(W.Units("pet", "first"))
        == "default,target,mouseover,focus,party1,party2,party3,party4,targettarget,arena1,arena2,arena3",
        keys(W.Units("pet", "first")))
    check("wizard units: /focus keys clear it, no focus to focus", keys(W.Units("focus", "key"))
        :find("^clear,target,mouseover,player,") ~= nil and W.Units("focus", "key")[1].name == "Clear focus",
        keys(W.Units("focus", "key")))
    local fitted = form({ command = "focus", on = { "mouseover", "default", "none" },
        keys = { shift = { on = { "cursor", "default" } } } })
    W.Fit(fitted)
    check("wizard fit: As usual is your target for /focus", table.concat(fitted.on, ",") == "mouseover,target,none"
        and table.concat(fitted.keys.shift.on, ",") == "none,target", table.concat(fitted.on, ","))
    fitted.command = "target"
    W.Fit(fitted)
    check("wizard fit: /target takes not your target", table.concat(fitted.on, ",") == "mouseover,none,none",
        table.concat(fitted.on, ","))
    fitted.command, fitted.on[1], fitted.keys.shift.on[1] = "cast", "none", "clear"
    W.Fit(fitted)
    check("wizard fit: a cast goes somewhere again, Clear goes", fitted.on[1] == "default"
        and fitted.keys.shift.on[1] == "default", fitted.keys.shift.on[1])
    fitted.command, fitted.on = "pet", { "player", "cursor", "focus" }
    W.Fit(fitted)
    check("wizard fit: the pet attacks somebody", table.concat(fitted.on, ",") == "default,none,focus",
        table.concat(fitted.on, ","))
    check("wizard: the spell of /cast is not in a list", W.Text(form({ command = "castrandom", action = bolt,
        list = { corruption } })) == "#showtooltip\n/castrandom [@mouseover,exists,nodead][] Corruption")
    for label, body in pairs(made) do
        check("wizard " .. label .. ": no issues", body and issues(body) == "", body and issues(body))
    end
    -- Ranks: the one picked in brackets, as the game names it; the spell alone is the highest learned.
    local ranked = { name = "Fireball", rank = "Rank 2", ranks = { "Rank 1", "Rank 2", "Rank 3" } }
    check("wizard spelled: with a rank, without", W.Spelled(ranked) == "Fireball(Rank 2)"
        and W.Spelled({ name = "Fireball", ranks = ranked.ranks }) == "Fireball")
    expectText("a rank", text({ action = ranked, only = "enemies" }),
        "#showtooltip\n/cast [@mouseover,harm,nodead][] Fireball(Rank 2)")
    expectText("a rank: the same one goes together", text({ action = ranked, only = "enemies", on = usual,
        keys = { shift = { action = { name = "Fireball", rank = "Rank 2" }, unit = "focus" } } }),
        "#showtooltip\n/cast [mod:shift,@focus,harm,nodead][] Fireball(Rank 2)")
    expectText("a rank: another one apart", text({ action = ranked, only = "enemies", on = usual,
        keys = { shift = { action = { name = "Fireball", rank = "Rank 1" }, unit = "focus" } } }),
        "#showtooltip\n/cast [mod:shift,@focus,harm,nodead] Fireball(Rank 1); Fireball(Rank 2)")
    expectText("a rank in a list, and with trinkets first", text({ command = "castsequence", list = { ranked,
        { name = "Frostbolt" } }, on = usual, trinket1 = true }),
        "#showtooltip Fireball(Rank 2)\n/use 13\n/castsequence Fireball(Rank 2), Frostbolt")
    check("wizard name: a spell without its rank", W.Name(form({ action = ranked })) == "Fireball")
    check("wizard name: a slot by what is in it", W.Name(form({ command = "use", action = slot })) == "Burning Talisman")
    check("wizard name: the first of a list", W.Name(form({ command = "castsequence", list = { nil, immolate } }))
        == "Immolate")
    check("wizard name: what it casts", W.Name(form({ action = heal })) == "Flash Heal")
    check("wizard name: a key's spell", W.Name(form({ keys = { ctrl = { action = sheep } } })) == "Polymorph")
    check("wizard name: trinkets alone", W.Name(form({ trinket1 = true })) == "Trinkets")
    check("wizard name: nothing yet", W.Name(W.Fresh()) == nil)

    -- The game reads them as meant (the stand-in for its check decides).
    local chain = text({ action = heal, only = "friends", on = { "mouseover", "target", "player" } })
    expectPreview("wizard: a friend under the mouse", chain, { units = { mouseover = {} } },
        "icon: Flash Heal | Flash Heal @mouseover")
    expectPreview("wizard: a dead one, a friend targeted", chain, { units = { mouseover = { dead = true }, target = {} } },
        "icon: Flash Heal | Flash Heal")
    expectPreview("wizard: an enemy targeted", chain, { units = { target = harmful } }, "icon: Flash Heal | Flash Heal @player")
    local byKey = text({ action = heal, only = "friends", on = { "party1", "none", "none" },
        keys = { shift = { unit = "party2" }, ctrl = { unit = "party3" }, alt = { unit = "party4" } } })
    local party = { party1 = {}, party2 = {}, party3 = {}, party4 = {} }
    expectPreview("wizard: Ctrl, member 3", byKey, { mods = { ctrl = true }, units = party },
        "icon: Flash Heal | Flash Heal @party3")
    expectPreview("wizard: no key, member 1", byKey, { units = party }, "icon: Flash Heal | Flash Heal @party1")
    local altBolt = text({ action = fire, only = "enemies", on = { "mouseover", "target", "none" },
        keys = { alt = { action = bolt, on = { "mouseover", "target" } } } })
    expectPreview("wizard: Alt, nobody under the mouse: the target", altBolt,
        { mods = { alt = true }, units = { target = harmful } }, "icon: Frostbolt | Frostbolt")
    expectPreview("wizard: Alt on an enemy under the mouse", altBolt,
        { mods = { alt = true }, units = { mouseover = harmful, target = harmful } }, "icon: Frostbolt | Frostbolt @mouseover")
    expectPreview("wizard: no key: the other spell", altBolt, { units = { target = harmful } }, "icon: Fireball | Fireball")
    expectPreview("wizard: Shift with nobody there", byKey, { mods = { shift = true }, units = { party1 = {} } },
        "icon: Flash Heal | Flash Heal @party1")
end

-- Step by step: the form's questions one at a time; each answer fills the form, the macro is the form's.
do
    local W, Q = ns.Wizard, ns.Questions
    local KEYS = { "shift", "ctrl", "alt" }
    local function steps(spec, keys) return table.concat(Q.Steps(spec, keys or KEYS), ",") end
    local function ask(spec, step, keys) return Q.Ask(spec, step, keys or KEYS) end
    local function keys(spec, step)
        local out = {}
        for i, a in ipairs(ask(spec, step).answers) do out[i] = a.key end
        return table.concat(out, ",")
    end
    local function find(spec, step, key)
        for _, a in ipairs(ask(spec, step).answers) do
            if a.key == key then return a end
        end
    end
    local made = {}
    local function macro(label, spec, want)
        local got = W.Text(spec)
        made[#made + 1] = got
        check("questions: " .. label, got == want, "\n  got  " .. tostring(got) .. "\n  want " .. want)
    end

    -- A heal on whoever is under the mouse, then on your target if a friend, then on you.
    local spec = W.Fresh()
    check("questions: a fresh form", steps(spec) == "what,spell,on1,only,on2,keys,also,finish", steps(spec))
    local what = ask(spec, "what")
    check("questions: what the macro does", what.kind == "choice" and what.text == "What should the macro do?"
        and keys(spec, "what") == "cast,use,castsequence,castrandom,target,focus,assist,pet" and what.chosen == "cast"
        and what.answers[1].name == "Cast a spell" and what.answers[1].hint == "/cast"
        and what.answers[3].tip ~= nil, keys(spec, "what"))
    check("questions: the spell", ask(spec, "spell").kind == "spell"
        and ask(spec, "spell").text == "Which spell should the macro cast?" and ask(spec, "spell").key == nil)
    spec.action = { name = "Flash Heal" }
    local on1 = ask(spec, "on1")
    check("questions: where it goes, by the spell's name", on1.text == "Where should Flash Heal go?"
        and on1.chosen == "mouseover" and on1.hint == nil, on1.text)
    check("questions: a cast goes anywhere, nobody is no first answer", keys(spec, "on1") == "default,target,mouseover,"
        .. "focus,player,pet,party1,party2,party3,party4,targettarget,arena1,arena2,arena3,cursor", keys(spec, "on1"))
    local mouse, party = find(spec, "on1", "mouseover"), find(spec, "on1", "party2")
    local usual = find(spec, "on1", "default")
    check("questions: units in plain words, the macro's words as the hint",
        mouse.name == "On whoever is under the mouse" and mouse.hint == "@mouseover" and mouse.tip ~= nil
        and party.name == "On party member 2" and party.hint == "@party2" and usual.name == "On your target, as usual" and usual.hint == nil
        and find(spec, "on1", "cursor").name == "On the ground under the cursor", party.name)
    local only = ask(spec, "only")
    check("questions: friends or enemies, after the first unit checked", only.text == "Who is Flash Heal for?"
        and keys(spec, "only") == "friends,enemies,any,dead" and only.chosen == "any", only.text)
    Q.Choose(spec, "only", "friends")
    check("questions: your target, if a friend", find(spec, "on1", "target").name == "On your target, if a friend")
    local on2 = ask(spec, "on2")
    check("questions: and if nobody is under the mouse", on2.text == "And if nobody is under the mouse?"
        and on2.hint == "Or the one there is not a friend, or is dead." and on2.chosen == "default"
        and not keys(spec, "on2"):find("mouseover") and keys(spec, "on2"):find(",none$") ~= nil
        and find(spec, "on2", "none").name == "Do nothing", keys(spec, "on2"))
    Q.Choose(spec, "on2", "target")
    check("questions: a third, after one that may not be there", steps(spec)
        == "what,spell,on1,only,on2,on3,keys,also,finish" and ask(spec, "on3").text == "And if you have no target?"
        and not find(spec, "on3", "target") and not find(spec, "on3", "mouseover"), steps(spec))
    Q.Choose(spec, "on3", "player")
    macro("a heal: the mouseover, your target, you", spec,
        "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] Flash Heal")
    Q.Choose(spec, "only", "dead")
    check("questions: dead friends too, for a resurrection", spec.only == "friends" and not spec.alive
        and ask(spec, "only").chosen == "dead" and ask(spec, "on2").hint == "Or the one there is not a friend.")
    macro("a resurrection", spec, "#showtooltip\n/cast [@mouseover,help][help][@player] Flash Heal")
    Q.Choose(spec, "only", "enemies")
    check("questions: alive again",
        spec.alive and ask(spec, "on2").hint == "Or the one there is not an enemy, or is dead.")
    Q.Choose(spec, "only", "any")
    local anyAlive = ask(spec, "on2").hint
    spec.alive = false
    check("questions: anyone, alive or not", anyAlive == "Or the one there is dead." and ask(spec, "on2").hint == nil
        and ask(spec, "only").chosen == "any", anyAlive)
    spec.alive = true
    Q.Choose(spec, "on1", "player")
    check("questions: nothing after yourself", steps(spec) == "what,spell,on1,keys,also,finish", steps(spec))
    -- The game says what the spell is for: no question about it, and no unit the spell never goes to.
    local bolt = W.Fresh()
    bolt.action, bolt.only, bolt.reaction = { name = "Shadow Bolt" }, "enemies", "enemies"
    check("questions: the game says it is for enemies: not asked", steps(bolt) == "what,spell,on1,on2,keys,also,finish",
        steps(bolt))
    check("questions: a spell for enemies goes to no friend", find(bolt, "on1", "arena1") ~= nil
        and not find(bolt, "on1", "player") and not find(bolt, "on1", "pet") and not find(bolt, "on1", "party1")
        and find(bolt, "on1", "focus") ~= nil and find(bolt, "on2", "targettarget") ~= nil, keys(bolt, "on1"))
    bolt.action, bolt.only, bolt.reaction = { name = "Flash Heal" }, "friends", "friends"
    check("questions: a spell for friends goes to no enemy", find(bolt, "on1", "party1") ~= nil
        and find(bolt, "on1", "player") ~= nil and not find(bolt, "on1", "arena1"), keys(bolt, "on1"))
    bolt.keys.shift.active = true
    bolt.keys.shift.action, bolt.keys.shift.reaction = { name = "Shadow Bolt" }, "enemies"
    Q.Choose(bolt, "shiftOn1", "mouseover")
    check("questions: a key's own spell for what it is for", steps(bolt)
        == "what,spell,on1,on2,keys,shiftCast,shiftOn1,shiftOn2,also,finish"
        and find(bolt, "shiftOn1", "arena2") ~= nil and not find(bolt, "shiftOn1", "party2")
        and ask(bolt, "shiftOn2").hint == "Or the one there is not an enemy, or is dead."
        and find(bolt, "shiftOn2", "target").name == "On your target, if an enemy"
        and find(bolt, "on2", "target").name == "On your target, if a friend", steps(bolt))
    bolt.keys.shift.reaction = nil
    check("questions: a key's spell the game says nothing about: every unit", find(bolt, "shiftOn1", "party2") ~= nil
        and find(bolt, "shiftOn1", "arena2") ~= nil and steps(bolt):find("only") == nil, keys(bolt, "shiftOn1"))
    bolt.reaction = nil
    check("questions: asked when the game says nothing", steps(bolt)
        == "what,spell,on1,only,on2,keys,shiftCast,shiftOn1,shiftOn2,also,finish", steps(bolt))
    bolt.keys.shift.reaction = "enemies"
    Q.Choose(bolt, "on1", "player")
    check("questions: not for a key's own spell the game says", steps(bolt)
        == "what,spell,on1,keys,shiftCast,shiftOn1,shiftOn2,also,finish", steps(bolt))
    bolt.reaction, bolt.keys.shift.action, bolt.keys.shift.reaction = "enemies", nil, "friends"
    check("questions: a key casting the macro's spell, for what that is for", not find(bolt, "shiftOn1", "party2")
        and find(bolt, "shiftOn1", "arena2") ~= nil, keys(bolt, "shiftOn1"))
    check("questions: Next and Back", Q.Next(spec, KEYS, "what") == "spell" and Q.Next(spec, KEYS, "on1") == "keys"
        and Q.Next(spec, KEYS, "keys", true) == "on1" and Q.Next(spec, KEYS, "what", true) == nil
        and Q.Next(spec, KEYS, "finish") == nil and Q.Next(spec, KEYS, "on3") == "what")

    -- Keys: what each one held casts, and where; friends or enemies after the first unit checked, a key's too.
    spec = W.Fresh()
    spec.action = { name = "Frostbolt" }
    Q.Choose(spec, "on1", "default")
    spec.keys.shift.active = true
    check("questions: a key held", steps(spec) == "what,spell,on1,keys,shiftCast,shiftOn1,also,finish", steps(spec))
    local cast = ask(spec, "shiftCast")
    check("questions: what the key casts", cast.kind == "spell" and cast.key == "shift" and cast.context
        == "With Shift held" and cast.text == "What should the macro cast instead?", cast.context)
    check("questions: the macro's spell, unless the key has one",
        ask(spec, "shiftOn1").text == "Where should Frostbolt go?"
        and ask(spec, "shiftOn1").context == "With Shift held")
    spec.keys.shift.action = { name = "Polymorph" }
    Q.Choose(spec, "shiftOn1", "focus")
    check("questions: friends or enemies after a key's unit", steps(spec)
        == "what,spell,on1,keys,shiftCast,shiftOn1,only,shiftOn2,also,finish"
        and ask(spec, "shiftOn1").text == "Where should Polymorph go?"
        and ask(spec, "only").text == "Who is Polymorph for?", steps(spec))
    local on = ask(spec, "shiftOn2")
    check("questions: and if the key's unit is not there", on.text == "And if you have no focus?"
        and on.context == "With Shift held" and not keys(spec, "shiftOn2"):find("focus")
        and keys(spec, "shiftOn2"):find(",none$") ~= nil, keys(spec, "shiftOn2"))
    Q.Choose(spec, "only", "enemies")
    Q.Choose(spec, "shiftOn2", "none")
    spec.keys.ctrl.active = true
    Q.Choose(spec, "ctrlOn1", "player")
    macro("keys: another spell on the focus, the same one on you", spec,
        "#showtooltip\n/cast [mod:shift,@focus,harm,nodead] Polymorph; [mod:ctrl,@player][] Frostbolt")
    check("questions: the keys of this client", ask(spec, "keys").text
        == "Should the macro do something else while you hold Shift, Ctrl or Alt?"
        and ask(spec, "keys", { "shift", "ctrl", "alt", "cmd" }).text
        == "Should the macro do something else while you hold Shift, Ctrl, Alt or Cmd?"
        and steps(spec, { "shift" }) == "what,spell,on1,keys,shiftCast,shiftOn1,only,shiftOn2,also,finish")
    spec.keys.cmd.active = true
    check("questions: Cmd's, on a Mac", ask(spec, "cmdCast").context == "With Cmd held"
        and steps(spec, { "shift", "ctrl", "alt", "cmd" }):find("ctrlOn1,cmdCast,cmdOn1,also") ~= nil)

    -- An item; a list; what the macro does changes, and what was picked comes along.
    spec = W.Fresh()
    Q.Choose(spec, "what", "use")
    spec.action = { name = "14", item = true, label = "Burning Talisman" }
    check("questions: an item", ask(spec, "spell").text == "Which item should the macro use?"
        and ask(spec, "on1").text == "Where should Burning Talisman go?")
    spec.action = { name = "Corruption" }
    Q.Choose(spec, "what", "castsequence")
    check("questions: a list, the spell first", spec.list[1].name == "Corruption" and steps(spec)
        == "what,list,reset,on1,only,on2,also,finish" and ask(spec, "list").kind == "list"
        and ask(spec, "list").text == "Pick the spells in the order the macro should cast them"
        and ask(spec, "reset").kind == "reset" and ask(spec, "on1").text == "Where should these spells go?"
        and ask(spec, "only").text == "Who are these spells for?", steps(spec))
    Q.Choose(spec, "what", "castrandom")
    check("questions: at random, nothing starts it over", steps(spec) == "what,list,on1,only,on2,also,finish"
        and ask(spec, "list").text == "Pick the spells the macro chooses from", steps(spec))
    spec.list[2] = { name = "Immolate" }
    Q.Choose(spec, "only", "enemies")
    macro("one of them at random", spec, "#showtooltip\n/castrandom [@mouseover,harm,nodead][] Corruption, Immolate")
    Q.Choose(spec, "what", "cast")
    spec.action = { name = "Fireball" }
    Q.Choose(spec, "what", "castsequence")
    check("questions: a list keeps its first", spec.list[1].name == "Corruption" and spec.list[2].name == "Immolate")
    Q.Choose(spec, "what", "castrandom")

    -- /target: who, friends or enemies, someone by name; nobody ends it, and the name with it.
    spec = W.Fresh()
    spec.reaction = "enemies" -- what the game said for a spell picked before
    Q.Choose(spec, "what", "target")
    check("questions: /target", steps(spec) == "what,on1,only,on2,keys,also,finish"
        and find(spec, "on1", "party1") ~= nil and find(spec, "on1", "arena1") ~= nil
        and ask(spec, "on1").text == "Who should become your target?"
        and ask(spec, "only").text == "Friends or enemies?"
        and keys(spec, "on1") == "mouseover,focus,player,pet,party1,party2,party3,party4,targettarget,arena1,arena2,"
        .. "arena3,byName" and find(spec, "on1", "mouseover").name == "Whoever is under the mouse"
        and find(spec, "on1", "party1").name == "Party member 1", keys(spec, "on1"))
    Q.Choose(spec, "on1", "byName")
    check("questions: by name only", steps(spec) == "what,on1,byName,keys,also,finish"
        and ask(spec, "on1").chosen == "byName" and ask(spec, "byName").kind == "byName"
        and table.concat(spec.on, ",") == "none,none,none", steps(spec))
    spec.byName = "Hogger"
    macro("target: by name", spec, "/target Hogger")
    Q.Choose(spec, "on1", "mouseover")
    check("questions: the mouseover, then by name", steps(spec) == "what,on1,only,on2,byName,keys,also,finish"
        and ask(spec, "on2").chosen == "byName" and keys(spec, "on2"):find(",byName,none$") ~= nil, steps(spec))
    Q.Choose(spec, "only", "enemies")
    macro("target: the mouseover, then by name", spec, "/target [@mouseover,harm,nodead][] Hogger")
    Q.Choose(spec, "on2", "none")
    check("questions: nobody next, no name", spec.byName == nil and steps(spec) == "what,on1,only,on2,keys,also,finish"
        and ask(spec, "on2").chosen == "none")
    spec.keys.shift.active = true
    check("questions: a key's target, or none", steps(spec):find("keys,shiftOn1,also") ~= nil
        and find(spec, "shiftOn1", "clear").name == "Clear target" and keys(spec, "shiftOn1"):find(",clear$") ~= nil
        and not keys(spec, "shiftOn1"):find("byName"), keys(spec, "shiftOn1"))
    spec.keys.shift.action, spec.keys.shift.reaction = { name = "Shadow Bolt" }, "enemies" -- from a /cast before
    Q.Choose(spec, "on1", "player")
    Q.Choose(spec, "shiftOn1", "focus")
    check("questions: /target keys take no spell of their own", steps(spec)
        == "what,on1,keys,shiftOn1,only,shiftOn2,also,finish", steps(spec))
    spec.keys.shift.action, spec.keys.shift.reaction = nil, nil
    Q.Choose(spec, "on1", "mouseover")
    Q.Choose(spec, "shiftOn1", "clear")
    check("questions: nothing after clearing", steps(spec) == "what,on1,only,on2,keys,shiftOn1,also,finish",
        steps(spec))
    macro("target: Shift clears it", spec, "/cleartarget [mod:shift]\n/stopmacro [mod:shift]\n/target "
        .. "[@mouseover,harm,nodead]")
    spec.byName = "Hogger"
    Q.Choose(spec, "on2", "byName")
    Q.Choose(spec, "shiftOn1", "clear")
    check("questions: a key's answer keeps the name", spec.byName == "Hogger")
    Q.Choose(spec, "shiftOn1", "focus")
    check("questions: by name for the macro only, not a key", steps(spec)
        == "what,on1,only,on2,byName,keys,shiftOn1,shiftOn2,also,finish", steps(spec))
    Q.Choose(spec, "shiftOn1", "clear")
    Q.Choose(spec, "on2", "focus")
    Q.Choose(spec, "on3", "party1")
    Q.Choose(spec, "on1", "byName")
    check("questions: by name only: nobody else, the name typed kept", table.concat(spec.on, ",") == "none,none,none"
        and spec.byName == "Hogger", table.concat(spec.on, ","))
    Q.Choose(spec, "on1", "mouseover")
    Q.Choose(spec, "on2", "none")
    Q.Choose(spec, "what", "focus")
    check("questions: /focus: your target as it is, and no name",
        ask(spec, "on1").text == "Who should become your focus?"
        and find(spec, "on1", "target").name == "Your target" and not keys(spec, "on1"):find("byName")
        and find(spec, "shiftOn1", "clear").name == "Clear focus", keys(spec, "on1"))
    Q.Choose(spec, "what", "assist")
    check("questions: /assist", ask(spec, "on1").text == "Whose target should you take?")

    -- The pet: what it does; whom it attacks (enemies), without asking friends or enemies.
    spec = W.Fresh()
    Q.Choose(spec, "what", "pet")
    check("questions: the pet attacks enemies", spec.only == "enemies"
        and steps(spec) == "what,pet,on1,on2,keys,also,finish"
        and ask(spec, "pet").text == "What should your pet do?" and ask(spec, "pet").chosen == "attack"
        and keys(spec, "pet") == "attack,follow,stay,moveto,passive,defensive,aggressive,dismiss"
        and find(spec, "pet", "follow").hint == "/petfollow", steps(spec))
    check("questions: the pet attacks no friend",
        not find(spec, "on1", "party1") and find(spec, "on1", "arena1") ~= nil)
    check("questions: whom it attacks", ask(spec, "on1").text == "Who should your pet attack?"
        and find(spec, "on1", "target").name == "Your target, if an enemy"
        and find(spec, "on1", "default").name == "Your target, as usual" and find(spec, "on1", "default").tip == nil
        and not keys(spec, "on1"):find("player") and not keys(spec, "on1"):find("cursor"), keys(spec, "on1"))
    macro("pet: attack the mouseover", spec, "/petattack [@mouseover,harm,nodead][]")
    Q.Choose(spec, "pet", "follow")
    spec.keys.alt.active = true
    check("questions: no units but for an attack", steps(spec) == "what,pet,keys,altPet,also,finish"
        and ask(spec, "altPet").context == "With Alt held" and ask(spec, "altPet").chosen == "passive", steps(spec))
    spec.only = "any"
    Q.Choose(spec, "altPet", "attack")
    check("questions: a key's attack, on enemies", steps(spec) == "what,pet,keys,altPet,altOn1,also,finish"
        and spec.only == "enemies", steps(spec))
    spec.keys.alt.action, spec.keys.alt.reaction = { name = "Flash Heal" }, "friends" -- from a /cast before
    check("questions: the pet's keys cast nothing of their own", find(spec, "altOn1", "target").name
        == "Your target, if an enemy" and not find(spec, "altOn1", "party1"), find(spec, "altOn1", "target").name)
    macro("pet: follow, Alt attacks", spec, "/petfollow [nomod:alt]\n/petattack [mod:alt]")

    -- Ranks (Classic): a question of their own after the spell, the macro's or a key's, when two are learned.
    spec = W.Fresh()
    spec.action = { name = "Fireball", ranks = { "Rank 1", "Rank 2", "Rank 3" } }
    spec.keys.shift.active = true
    spec.keys.shift.action = { name = "Frostbolt", ranks = { "Rank 1" } }
    check("questions: a rank, not for one learned", steps(spec)
        == "what,spell,rank,on1,only,on2,keys,shiftCast,shiftOn1,also,finish", steps(spec))
    local rank = ask(spec, "rank")
    check("questions: which rank", rank.kind == "choice" and rank.text == "Which rank of Fireball?"
        and keys(spec, "rank") == ",Rank 3,Rank 2,Rank 1" and rank.chosen == ""
        and rank.answers[1].name == "The highest you know" and rank.answers[1].hint == "Fireball"
        and rank.answers[2].name == "Rank 3" and rank.answers[2].hint == "Fireball(Rank 3)", keys(spec, "rank"))
    Q.Choose(spec, "rank", "Rank 2")
    check("questions: a rank picked", spec.action.rank == "Rank 2" and ask(spec, "rank").chosen == "Rank 2"
        and ask(spec, "on1").text == "Where should Fireball go?", spec.action.rank)
    Q.Choose(spec, "rank", "")
    check("questions: the highest again", spec.action.rank == nil)
    spec.keys.shift.action = { name = "Fireball", ranks = { "Rank 1", "Rank 2", "Rank 3" } }
    Q.Choose(spec, "shiftRank", "Rank 1")
    check("questions: a key's rank", steps(spec):find("shiftCast,shiftRank,shiftOn1") ~= nil
        and spec.keys.shift.action.rank == "Rank 1" and spec.action.rank == nil
        and ask(spec, "shiftRank").context == "With Shift held", steps(spec))
    check("questions: the last ones", ask(spec, "also").kind == "also" and ask(spec, "finish").kind == "finish"
        and ask(spec, "finish").text == "Almost done: name your macro")
    ns.SetLanguage("uk")
    spec = W.Fresh()
    spec.action = { name = "Flash Heal" }
    check("questions: in Ukrainian", ask(spec, "what").text == "Що має робити макрос?"
        and ask(spec, "on1").text == "На кого чи куди застосувати «Flash Heal»?"
        and find(spec, "on1", "mouseover").name == "На того, хто під мишею"
        and find(spec, "on1", "party3").name == "На члена групи 3"
        and ask(spec, "on2").text == "А якщо під мишею нікого немає?",
        ask(spec, "on1").text)
    ns.SetLanguage("en")
    for _, body in ipairs(made) do
        check("questions: " .. body:gsub("\n", " | ") .. ": no issues", issues(body) == "", issues(body))
    end
end

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
-- Minimap button: its center on the round edge, or on the side where a square minimap has its corner.
do
    local function at(angle, shape)
        local x, y = ns.MinimapButton.Offset(angle, 140, 140, shape)
        return string.format("%.1f,%.1f", x, y)
    end
    check("minimap: right", at(0) == "75.0,0.0", at(0))
    check("minimap: up", at(90) == "0.0,75.0", at(90))
    check("minimap: round corner", at(45) == "53.0,53.0", at(45))
    check("minimap: square corner", at(45, "SQUARE") == "75.0,75.0", at(45, "SQUARE"))
    check("minimap: square side", at(30, "SQUARE") == "75.0,43.3", at(30, "SQUARE"))
    check("minimap: the one round corner", at(135, "CORNER-TOPLEFT") == "-53.0,53.0", at(135, "CORNER-TOPLEFT"))
    check("minimap: the other corners", at(45, "CORNER-TOPLEFT") == "75.0,75.0", at(45, "CORNER-TOPLEFT"))
    check("minimap: round side", at(225, "SIDE-LEFT") == "-53.0,-53.0", at(225, "SIDE-LEFT"))
    check("minimap: square side of SIDE-LEFT", at(315, "SIDE-LEFT") == "75.0,-75.0", at(315, "SIDE-LEFT"))
    check("minimap: round top of SIDE-TOP", at(45, "SIDE-TOP") == "53.0,53.0", at(45, "SIDE-TOP"))
    check("minimap: tricorner, round", at(45, "TRICORNER-TOPLEFT") == "53.0,53.0", at(45, "TRICORNER-TOPLEFT"))
    check("minimap: tricorner, the square one", at(315, "TRICORNER-TOPLEFT") == "75.0,-75.0",
        at(315, "TRICORNER-TOPLEFT"))
    check("minimap: a shape it doesn't know is round", at(45, "HEXAGON") == "53.0,53.0", at(45, "HEXAGON"))
end

-- Share: macros as a code and back, whatever a chat app does around it.
do
    local S = ns.Share
    local macros = {
        { scope = "general", icon = 136183, name = "Fear Focus", body = "#showtooltip\n/cast [@focus,harm] Fear" },
        { scope = "character", icon = "Interface\\Icons\\My_Skull", name = "Чорна стріла", body = "/say |cffff0000hi|r" },
        { scope = "general", icon = 134400, name = "Empty", body = "" },
    }
    local code = S.Encode(macros)
    check("share: a code of letters and digits", code:match("^MacroSense1:[%w+/=]+%.$") ~= nil, code)
    local function Same(a, b)
        if not (a and #a == #b) then return false end
        for i, m in ipairs(b) do
            local x = a[i]
            if x.scope ~= m.scope or x.icon ~= m.icon or x.name ~= m.name or x.body ~= m.body then return false end
        end
        return true
    end
    check("share: the same macros back", Same(S.Decode(code), macros))
    for _, body in ipairs({ "a", "ab", "abc", "abcd" }) do -- each length of the last group of three
        local one = { { scope = "general", icon = 1, name = "N", body = body } }
        check("share: a text of " .. #body .. " letters", Same(S.Decode(S.Encode(one)), one))
    end
    local chat = "here: " .. code:sub(1, 30) .. "\n" .. code:sub(31, 60) .. "  " .. code:sub(61) .. " thanks!"
    check("share: line breaks, spaces and words around", Same(S.Decode(chat), macros))
    local function Problem(text) return select(2, S.Decode(text)) or "" end
    check("share: not a code", Problem("/cast Fear"):find("not a MacroSense code") ~= nil, Problem("/cast Fear"))
    check("share: cut short", Problem(code:sub(1, -12)):find("cut short") ~= nil, Problem(code:sub(1, -12)))
    check("share: without its end", Problem(code:sub(1, -2)):find("cut short") ~= nil)
    local i = #code - 20
    local changed = code:sub(1, i - 1) .. (code:sub(i, i) == "A" and "B" or "A") .. code:sub(i + 1)
    check("share: a letter changed", Problem(changed):find("changed") ~= nil, Problem(changed))
    local nameless = S.Encode({ { scope = "general", icon = 1, name = "", body = "/sit" } })
    check("share: a macro without a name", Problem(nameless):find("damaged") ~= nil, Problem(nameless))
end

-- Icon for a macro's name: of the spell or item (yours) it is named after.
do
    local spells, items = ns.sources.spells, ns.sources.items
    ns.sources.spells = function()
        return { { name = "Blast", icon = 13 }, { name = "Fireball", icon = 1 }, { name = "Fire Blast", icon = 2 },
            { name = "Frost Nova", icon = 4 }, { name = "Frostbolt", icon = 3 }, { name = "Polymorph", icon = 5 },
            { name = "Shadow Word: Pain", icon = 6 }, { name = "Pain Suppression", icon = 7 },
            { name = "Nature's Swiftness", icon = 8 }, { name = "Kick", icon = 9 }, { name = "Focus Magic", icon = 10 },
            { name = "Огненный шар", icon = 11 }, { name = "Iconless" }, { name = "Healthstone" } }
    end
    ns.sources.items = function() return { { name = "Healthstone", icon = 20 }, { name = "Kick", icon = 21 } } end
    local I = ns.Completion.IconFor
    check("icon for: named like it, in any case", I("fireball") == 1 and I("FIRE BLAST") == 2 and I("огненный Шар") == 11)
    check("icon for: marks don't count", I("Natures Swiftness") == 8 and I("Shadow Word Pain") == 6
        and I("Kick(focus)") == 9 and I("Fire Blast!") == 2)
    check("icon for: an item; a spell without an icon doesn't count", I("healthstone") == 20)
    check("icon for: a spell before an item", I("Kick") == 9)
    check("icon for: in the name as whole words, the longest", I("Fire Blast focus") == 2 and I("MO Kick") == 9
        and I("Shadow Word: Pain arena1") == 6 and I("Fireballs") ~= 1, tostring(I("Fireballs")))
    check("icon for: the start of a word, the shortest", I("Poly") == 5 and I("Poly MO") == 5 and I("Frost") == 3
        and I("Nova") == 4 and I("Swift") == 8 and I("Bolt") == nil, tostring(I("Frost")))
    check("icon for: target words are skipped", I("Focus Poly") == 5 and I("arena2 poly") == 5)
    check("icon for: 3 letters at least, of the first other word", I("Fi") == nil and I("SW Pain") == nil
        and I("Ог") == nil and I("Огн") == 11)
    check("icon for: nothing", I("Mount") == nil and I("") == nil and I("   ") == nil and I("Focus") == nil)
    check("icon for: no icon, no match", I("Iconless") == nil)
    ns.sources.spells, ns.sources.items = spells, items
end

-- Ukrainian: texts in the chosen language, counts in their three forms, and every translation keeps the %s and
-- %d of its English text, in the same order.
do
    local L = ns.L
    ns.SetLanguage("uk")
    check("locale: a text in Ukrainian", L["Save"] == "Зберегти" and ns.language == "uk")
    check("locale: one not translated stays English", L["no such text"] == "no such text")
    local forms = {}
    for _, n in ipairs({ 1, 2, 4, 5, 11, 12, 14, 21, 22, 25, 111, 0 }) do
        forms[#forms + 1] = ns.Plural(n, "%d macro", "%d macros")
    end
    check("locale: the three forms of a count", table.concat(forms, ",") == "1 макрос,2 макроси,4 макроси,5 макросів,"
        .. "11 макросів,12 макросів,14 макросів,21 макрос,22 макроси,25 макросів,111 макросів,0 макросів",
        table.concat(forms, ","))
    check("locale: in another language", ns.Translate("en", "Save") == "Save"
        and ns.Translate("uk", "Save") == "Зберегти")
    check("locale: a code's problem", select(2, ns.Share.Decode("hello")) == "Це не код MacroSense.")
    check("locale: a value's problem, with what is expected", ns.Conditions.CheckValue("bar", "9")
        == "неправильне значення bar «9» (очікується сторінка панелі 1-6)", ns.Conditions.CheckValue("bar", "9"))
    check("locale: the macOS warning", ns.Shortcuts.Message({ { combo = "Cmd+Q", what = "quits the game" } })
        == "Cmd+Q — сполучення клавіш macOS (закриває гру)")
    ns.SetLanguage("xx")
    check("locale: another language is English", ns.language == "en" and L["Save"] == "Save")
    check("locale: English counts", ns.Plural(1, "%d macro", "%d macros") == "1 macro"
        and ns.Plural(2, "%d macro", "%d macros") == "2 macros")
    ns.SetLanguage("en")

    local function percents(s)
        local out = {}
        for m in s:gmatch("%%[%-%+ #0]*%d*%.?%d*[%a%%]") do out[#out + 1] = m end
        return table.concat(out, " ")
    end
    local function braces(s) -- {month} {day}: their order may differ
        local out = {}
        for m in s:gmatch("{%a+}") do out[#out + 1] = m end
        table.sort(out)
        return table.concat(out, " ")
    end
    local bad = {}
    for english, translation in pairs(ns.locales.uk) do
        local list = type(translation) == "table" and translation or { translation }
        if type(translation) == "table" and #translation ~= 3 then bad[#bad + 1] = english end
        for _, t in ipairs(list) do
            if percents(t) ~= percents(english) or braces(t) ~= braces(english) then bad[#bad + 1] = english end
        end
    end
    check("locale: every translation keeps its %s and %d", #bad == 0, table.concat(bad, " | "))
end

-- Backups: all the macros, to go back to.
do
    local B = ns.Backups
    local function M(scope, name, icon, body) return { scope = scope, name = name, icon = icon, body = body } end
    local a = { M("general", "Fear", 1, "/cast Fear"), M("character", "Heal", 2, "/cast Heal") }
    check("backups: the same macros in any order", B.Same(a, { a[2], a[1] }))
    check("backups: another text", not B.Same(a, { a[1], M("character", "Heal", 2, "/cast Heal!") }))
    check("backups: another icon", not B.Same(a, { a[1], M("character", "Heal", 3, "/cast Heal") }))
    check("backups: another tab", not B.Same(a, { a[1], M("general", "Heal", 2, "/cast Heal") }))
    check("backups: one more", not B.Same(a, { a[1], a[2], M("general", "X", 1, "") }))
    check("backups: one less", not B.Same(a, { a[1] }))
    local list = {}
    check("backups: the first one", B.Add(list, a, 100) and #list == 1)
    check("backups: not the same again", not B.Add(list, { a[2], a[1] }, 200) and #list == 1)
    check("backups: none of no macros", not B.Add(list, {}, 300) and #list == 1)
    for i = 1, B.LIMIT + 1 do B.Add(list, { M("general", "N", 1, tostring(i)) }, 1000 + i) end
    check("backups: the last ones, oldest first", #list == B.LIMIT and list[1].time == 1002
        and list[#list].time == 1000 + B.LIMIT + 1, #list)
    local b1, b2, b3 = { time = 1 }, { time = 2 }, { time = 3 }
    local kept = { b1, b2, b3 }
    check("backups: one taken out", B.Remove(kept, b2) and #kept == 2 and kept[1] == b1 and kept[2] == b3)
    check("backups: only that one", not B.Remove(kept, { time = 1 }) and #kept == 2)
    date = os.date
    local day = os.time({ year = 2026, month = 10, day = 25, hour = 9 })
    check("backups: due with none", B.Due({}, day))
    check("backups: not due the same day", not B.Due({ { time = day } }, day + 3600 * 10))
    check("backups: due the next day", B.Due({ { time = day } }, day + 86400))
    date = nil
    -- A restore: text and icon back, the missing made again where there is room; the rest is left as it is.
    local backup = { M("general", "Same", 1, "/same"), M("general", "Changed", 1, "/old"), M("general", "Icon", 1, "/x"),
        M("general", "Gone 1", 1, "/g1"), M("general", "Gone 2", 1, "/g2"), M("character", "Changed", 1, "/c") }
    local now = { M("general", "Same", 1, "/same"), M("general", "Changed", 1, "/new"), M("general", "Icon", 2, "/x"),
        M("general", "Made since", 1, "/n") }
    local plan = B.Plan(backup, now, { general = 1, character = 5 })
    local function names(l)
        local out = {}
        for i, m in ipairs(l) do out[i] = m.scope:sub(1, 1) .. ":" .. m.name end
        return table.concat(out, ",")
    end
    check("backups: what a restore does", names(plan.same) == "g:Same" and names(plan.back) == "g:Changed,g:Icon"
        and names(plan.again) == "g:Gone 1,c:Changed" and names(plan.full) == "g:Gone 2",
        names(plan.back) .. " | " .. names(plan.again) .. " | " .. names(plan.full))
end

-- Icon names: the game's spells, then its achievements, name the icons they use; looked up a part at a time.
do
    local spells = { [3] = { 10, "Fear" }, [4] = { 10, "Howl of Terror" }, [5] = { 10, "Fear" },
        [6] = { 11, "Shadow Bolt" }, [7] = { 99, "Fireball" }, [8] = { 12, "Страх" }, [10] = { 12, "Жах" },
        [2600] = { 12, "Late" } }
    for id = 20, 24 do spells[id] = { 13, "Spell " .. id } end
    local clock, fighting = 0, false
    C_Spell = {
        GetSpellTexture = function(id) return spells[id] and spells[id][1] end,
        GetSpellName = function(id) return spells[id] and spells[id][2] end,
    }
    InCombatLockdown = function() return fighting end
    debugprofilestop = function() -- a millisecond later at each look at the clock
        clock = clock + 1
        return clock
    end
    -- A fresh lookup for icons 10-13: at least to spell `last`, then on until `empty` in a row are empty.
    local function Lookup(last, empty)
        local t = { Completion = ns.Completion }
        assert(loadfile("MacroSense/IconNames.lua"))("MacroSense", t)
        t.IconNames.SPELLS, t.IconNames.EMPTY = last, empty
        t.IconNames.Want({ 10, 11, 12, 13 })
        return t.IconNames
    end
    local function Names(lookup, icon)
        local names = lookup.For(icon)
        return names and table.concat(names, ",") or ""
    end
    local names = Lookup(1000, 3000)
    check("icon names: a millisecond's worth at a time", names.Step(1) == false and names.Progress() > 0
        and names.Progress() < 1, names.Progress())
    fighting = true
    local before = names.Progress()
    check("icon names: none in combat", names.Step(1) == false and names.Progress() == before)
    fighting = false
    local steps = 1
    while not names.Step(1) do steps = steps + 1 end
    check("icon names: then the rest, step by step", steps > 1 and names.Progress() == 1, steps)
    check("icon names: each name once", Names(names, 10) == "Fear,Howl of Terror", Names(names, 10))
    check("icon names: only the grid's icons", names.For(99) == nil)
    check("icon names: four at most", Names(names, 13) == "Spell 20,Spell 21,Spell 22,Spell 23", Names(names, 13))
    check("icon names: past a long empty stretch", Names(names, 12) == "Страх,Жах,Late", Names(names, 12))
    check("icon names: searched in small letters, a name a line", names.For(12).text == "страх\nжах\nlate",
        names.For(12).text)
    names = Lookup(1000, 2000)
    while not names.Step(1000) do end
    check("icon names: they end after that many empty in a row", Names(names, 12) == "Страх,Жах", Names(names, 12))
    names = Lookup(3000, 100)
    while not names.Step(1000) do end
    check("icon names: not before the last spell to look at", Names(names, 12) == "Страх,Жах,Late",
        Names(names, 12))
    spells[1600] = { 11, "Shadow Bolt Volley" } -- 1575 empty before it, 999 after
    names = Lookup(100, 1600)
    while not names.Step(1000) do end
    check("icon names: each spell found starts the count over", Names(names, 12) == "Страх,Жах,Late",
        Names(names, 12))
    spells[1600] = nil
    -- Achievements, where the game has them: after the spells.
    GetCategoryList = function() return { 92, 95 } end
    GetCategoryNumAchievements = function(category) return category == 92 and 2 or 1 end
    local read = 0
    GetAchievementInfo = function(category, i)
        read = read + 1
        local icon = ({ [92] = { 11, 98 }, [95] = { 13 } })[category][i]
        return category * 10 + i, "Achievement " .. category .. "." .. i, 10, false, nil, nil, nil, "", 0, icon
    end
    names = Lookup(1000, 100)
    while not names.Step(1000) do end
    check("icon names: achievements", Names(names, 11) == "Shadow Bolt,Achievement 92.1", Names(names, 11))
    check("icon names: of the grid's icons only", names.For(98) == nil)
    check("icon names: achievements keep the four", Names(names, 13) == "Spell 20,Spell 21,Spell 22,Spell 23",
        Names(names, 13))
    check("icon names: once done, nothing is read again", names.Step(1000) and read == 3, read)
    -- TBC has the functions without the achievements: its one category has no count.
    GetCategoryList = function() return { 81 } end
    GetCategoryNumAchievements = function() return nil end
    names = Lookup(1000, 100)
    local ok, done = pcall(names.Step, 1000)
    check("icon names: TBC: the functions without achievements", ok and done and Names(names, 11) == "Shadow Bolt",
        tostring(done))
    -- Classic: seven categories, the first without a count; the others still count.
    GetCategoryList = function() return { 14808, 92 } end
    GetCategoryNumAchievements = function(category) return category == 92 and 2 or nil end
    names = Lookup(1000, 100)
    ok, done = pcall(names.Step, 1000)
    check("icon names: a category without a count is skipped", ok and done
        and Names(names, 11) == "Shadow Bolt,Achievement 92.1", Names(names, 11))
    -- Anything else odd there comes up once, not every frame.
    GetCategoryNumAchievements = function() return 1 end
    GetAchievementInfo = function() error("odd") end
    names = Lookup(1000, 100)
    local first = pcall(names.Step, 1000)
    local again, over = pcall(names.Step, 1000)
    check("icon names: an error in the achievements comes once", not first and again and over)
    C_Spell, InCombatLockdown, debugprofilestop = nil, nil, nil
    GetCategoryList, GetCategoryNumAchievements, GetAchievementInfo = nil, nil, nil
end

-- Macro slots per tab: Forever and Retail keep them in Constants.MacroConsts, the Classic clients in globals.
do
    local function slots(constants, general, character)
        Constants, MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = constants, general, character
        local t = {}
        assert(loadfile("MacroSense/Data.lua"))("MacroSense", t)
        Constants, MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = nil, nil, nil
        return t.MAX_GENERAL .. "/" .. t.MAX_CHARACTER
    end
    local retail = { MacroConsts = { MAX_ACCOUNT_MACROS = 120, MAX_CHARACTER_MACROS = 30 } }
    check("macro slots: Retail", slots(retail) == "120/30", slots(retail))
    check("macro slots: what the client says", slots({ MacroConsts = { MAX_ACCOUNT_MACROS = 150,
        MAX_CHARACTER_MACROS = 40 } }) == "150/40")
    check("macro slots: Classic globals", slots(nil, 36, 18) == "36/18", slots(nil, 36, 18))
    check("macro slots: neither", slots(nil) == "120/30", slots(nil))
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
