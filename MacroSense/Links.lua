-- Macros linked in chat. "[MacroSense: Fear MO]" goes into the message as plain text, so everyone can read it; with
-- MacroSense it shows as a link, and a click asks the one who wrote it for the macro (addon messages, a whisper)
-- and opens its code in the import window. Only macros linked here are given, as they were when linked. The text
-- and the pieces of a code are pure Lua (5.1); the rest needs the game.
local _, ns = ...
ns = ns or {}
local L = ns.L

local Links = {}
ns.Links = Links

Links.PREFIX = "MacroSense" -- of the addon messages
Links.CHUNK = 240 -- characters of a code in one message: 255 at most, with "A:1/2:" before them
Links.KEPT = 20 -- macros linked lately, whose codes are given when asked
Links.WAIT = 6 -- seconds to wait for an answer

local OPEN, CLOSE = "[MacroSense: ", "]"

-- The text a link of macro `name` is in chat.
function Links.Text(name) return OPEN .. name .. CLOSE end

-- `msg` with each link a clickable one: a local link (the game doesn't send those) to ask `sender` for the macro.
function Links.Decorate(msg, sender)
    return (msg:gsub("%[MacroSense: ([^%]|]+)%]", function(name)
        return "|cff569cd6|Haddon:MacroSense:" .. sender .. ":" .. name .. "|h" .. OPEN .. name .. CLOSE .. "|h|r"
    end))
end

-- "addon:MacroSense:<sender>:<name>" (the link a click gives) -> sender, name; nil for other links.
function Links.Parse(link)
    local sender, name = link:match("^addon:MacroSense:([^:]+):(.+)$")
    return sender, name
end

-- A code in addon messages: "A:1/2:...", "A:2/2:...".
function Links.Parts(code)
    local out, total = {}, math.ceil(#code / Links.CHUNK)
    for i = 1, total do
        out[i] = string.format("A:%d/%d:%s", i, total, code:sub((i - 1) * Links.CHUNK + 1, i * Links.CHUNK))
    end
    return out
end

-- Gathers the parts of a code from one sender in `got` (a table kept per sender): the whole code once the last part
-- came, else nil. A first part starts over; one out of turn is left out.
function Links.Collect(got, text)
    local i, total, data = text:match("^A:(%d+)/(%d+):(.*)$")
    i, total = tonumber(i), tonumber(total)
    if not i then return nil end
    if i == 1 then
        for k in pairs(got) do got[k] = nil end
    elseif got.total ~= total or #got ~= i - 1 then
        return nil
    end
    got.total, got[i] = total, data
    if i < total then return nil end
    return table.concat(got)
end

------------------------------------------------------------------------
-- In the game
------------------------------------------------------------------------
local CHAT_EVENTS = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_CHANNEL" }
local asked, answered, gathered = {}, {}, {} -- by sender: the macro asked for; when last answered; parts so far

local function Me() return UnitName("player") end

-- A player as "Name-Realm": chat and addon messages give a name with its realm, or without it for your own.
local function Who(name)
    if name:find("-", 1, true) then return name end
    local realm = GetNormalizedRealmName and GetNormalizedRealmName()
    return realm and (name .. "-" .. realm) or name
end

local function IsMe(who) return Who(who) == Who(Me()) end

-- The codes of the macros linked lately, by name: { code, time }.
local function Offered()
    ns.db.links = ns.db.links or {}
    return ns.db.links
end

local function Send(text, to)
    local ok, result = pcall(C_ChatInfo.SendAddonMessage, Links.PREFIX, text, "WHISPER", to)
    if not ok then return false end
    return result == nil or result == true or result == 0, result
end

-- Puts the link of macro `m` ({ scope, name, icon, body }) into the chat input (opened for it when closed), and keeps
-- its code to give to whoever asks; the oldest of more than KEPT go.
function Links.Insert(m)
    local offered = Offered()
    offered[m.name] = { code = ns.Share.Encode({ m }), time = time() }
    local names = {}
    for name in pairs(offered) do names[#names + 1] = name end
    table.sort(names, function(a, b) return offered[a].time > offered[b].time end)
    for i = Links.KEPT + 1, #names do offered[names[i]] = nil end
    local edit = ChatFrameUtil.GetActiveWindow()
    if edit then
        edit:Insert(Links.Text(m.name))
    else
        ChatFrameUtil.OpenChat(Links.Text(m.name))
    end
end

-- Asks `sender` for macro `name` they linked; one of yours opens at once.
function Links.Ask(sender, name)
    if IsMe(sender) then
        local mine = Offered()[name]
        if mine then return ns.ShareWindow.Import(mine.code, Me()) end
        return ns.Print("you no longer share \"%s\": link it again", name)
    end
    local sent, result = Send("Q:" .. name, sender)
    if not sent then
        if result == 11 then return ns.Print("addon messages are blocked now (in combat in an instance): try later") end
        if result == 12 then return ns.Print("%s is offline", sender) end
        return ns.Print("could not ask %s now: try again in a moment", sender)
    end
    local who = Who(sender)
    asked[who], gathered[who] = name, {}
    ns.Print("asking %s for \"%s\"...", sender, name)
    C_Timer.After(Links.WAIT, function()
        if asked[who] == name then
            asked[who] = nil
            ns.Print("no answer from %s: they may be offline or not have MacroSense", sender)
        end
    end)
end

-- An addon message: a question for one of the macros linked here, or the answer to ours.
local function OnMessage(text, sender)
    local who = Who(sender)
    local wanted = text:match("^Q:(.+)$")
    if wanted then
        -- One answer every 2 seconds to one player: a loop of questions gets no flood back.
        if answered[who] and GetTime() - answered[who] < 2 then return end
        answered[who] = GetTime()
        local mine = Offered()[wanted]
        if not mine then return Send("N:" .. wanted, sender) end
        for _, part in ipairs(Links.Parts(mine.code)) do Send(part, sender) end
        return
    end
    local name = asked[who]
    if not name then return end
    if text:match("^N:") then
        asked[who] = nil
        return ns.Print("%s no longer shares \"%s\"", sender, name)
    end
    local code = Links.Collect(gathered[who], text)
    if not code then return end
    asked[who] = nil
    ns.ShareWindow.Import(code, sender)
end

-- Chat lines with a link: clickable, unless the game hides them from addons (in combat in an instance).
local function Filter(_, event, msg, author, ...)
    if type(msg) ~= "string" or (issecretvalue and (issecretvalue(msg) or issecretvalue(author))) then return false end
    if not msg:find(OPEN, 1, true) then return false end
    local sender = event == "CHAT_MSG_WHISPER_INFORM" and Me() or author
    return false, Links.Decorate(msg, sender), author, ...
end

-- On login: the chat filters, the link clicks and the addon messages.
function Links.Setup()
    if Links.ready or not (C_ChatInfo and ChatFrameUtil and EventRegistry) then return end
    Links.ready = true
    C_ChatInfo.RegisterAddonMessagePrefix(Links.PREFIX)
    for _, event in ipairs(CHAT_EVENTS) do ChatFrameUtil.AddMessageEventFilter(event, Filter) end
    EventRegistry:RegisterCallback("SetItemRef", function(_, link)
        local sender, name = Links.Parse(link)
        if sender then Links.Ask(sender, name) end
    end, Links)
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:SetScript("OnEvent", function(_, _, prefix, text, _, sender)
        if prefix == Links.PREFIX and type(text) == "string" and type(sender) == "string" then
            OnMessage(text, sender)
        end
    end)
end

return Links
