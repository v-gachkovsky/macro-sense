-- Find and replace in the text of many macros at once: the General tab, the Character tab and, with macro sets on,
-- each of the sets in its place (in the game and behind the scenes). The game's macros keep the texts they had in
-- their History. Opened with "Replace" by the search, or Ctrl+H.
local _, ns = ...
local L = ns.L

local Window, shared = ns.Window, ns.WindowShared
local MAX_BODY = shared.MAX_BODY
local MacroRange, Letters, Guard = shared.MacroRange, shared.Letters, shared.Guard

local frame, findBox, withBox, countText, replaceBtn
local groupChecks = {}
local off = {} -- the groups ticked off, by key: the others are searched

-- Text `s` with each `find` in it as `with`, as typed (case counts), and how many there were.
local function Replace(s, find, with)
    if find == "" then return s, 0 end
    local out, n, from = {}, 0, 1
    while true do
        local a, b = s:find(find, from, true)
        if not a then break end
        out[#out + 1] = s:sub(from, a - 1) .. with
        n, from = n + 1, b + 1
    end
    out[#out + 1] = s:sub(from)
    return table.concat(out), n
end
Window.ReplaceText = Replace

-- The groups to search, in order: { key, label }. With macro sets on, the Character tab is its sets.
local function Groups()
    local out = { { key = "general", label = L["General"] } }
    if not ns.Sets.Mine().enabled then
        out[2] = { key = "character", label = L["Character"] }
        return out
    end
    for _, id in ipairs({ "character", "class" }) do out[#out + 1] = { key = id, label = ns.SetsWindow.Label(id) } end
    for _, spec in ipairs(ns.Sets.Specs()) do out[#out + 1] = { key = spec.key, label = spec.label } end
    return out
end

-- Every macro of the groups ticked: { group, index (in the game) or set (behind the scenes), name, icon, text }.
-- The text is the one MacroSense shows (@tank, not the tank's name).
local function Macros()
    local sets = ns.Sets.Mine().enabled
    local now = ns.ActionBars.Spec()
    local out = {}
    for _, scope in ipairs({ "general", "character" }) do
        local first, last = MacroRange(scope)
        for index = first, last do
            local name, _, body = GetMacroInfo(index)
            local group = scope
            if sets and scope == "character" then
                local layer = ns.Sets.LayerIn(name)
                group = layer == "spec" and now or layer == "class" and "class" or "character"
            end
            if name and not off[group] then
                out[#out + 1] = { group = group, scope = scope, index = index, name = name,
                    text = ns.Roles.Text(scope, name, body or "") }
            end
        end
    end
    if sets then
        for _, g in ipairs(Groups()) do
            if g.key ~= "general" and not off[g.key] then
                for _, m in ipairs(ns.Sets.List(g.key)) do
                    if ns.Sets.Behind(g.key, m) then
                        out[#out + 1] = { group = g.key, set = g.key, name = m.name, icon = m.icon,
                            text = m.body or "" }
                    end
                end
            end
        end
    end
    return out
end

-- What Replace all would change: { m, text = the new text, count }, and how many in all.
local function Plan()
    local find, with = findBox:GetText(), withBox:GetText()
    local out, total = {}, 0
    for _, m in ipairs(Macros()) do
        local text, n = Replace(m.text, find, with)
        if n > 0 then
            out[#out + 1] = { m = m, text = text, count = n }
            total = total + n
        end
    end
    return out, total
end

local function Refresh()
    if not frame or not frame:IsShown() then return end
    local plan, total = Plan()
    countText:SetText(findBox:GetText() == "" and L["Type what to find."]
        or total == 0 and L["Nothing found."]
        or ns.Plural(total, "%d match", "%d matches") .. " " .. ns.Plural(#plan, "in %d macro", "in %d macros"))
    replaceBtn:SetEnabled(total > 0)
end

-- Replace all: the game's macros with EditMacro (their History keeps what they had), those behind the scenes in
-- their sets. One too long then stays as it is, and says so. Not in combat; unsaved changes are asked about first.
local function ReplaceAll()
    if InCombatLockdown() then return ns.Print("macros cannot be changed in combat") end
    local plan = Plan()
    Guard(function() ns.Sets.Atomic(function()
        local done, long = 0, {}
        for _, p in ipairs(plan) do
            local m = p.m
            local written = ns.Roles.Fill(p.text)
            if Letters(written) > MAX_BODY then
                long[#long + 1] = m.name
            elseif m.set then
                if ns.Sets.Write(m.set, m.name, m.name, m.icon, written) then done = done + 1 end
            elseif EditMacro(m.index, nil, nil, written) then
                ns.Roles.Saved(m.scope, m.name, m.name, p.text, select(3, GetMacroInfo(m.index)))
                done = done + 1
            end
        end
        ns.History.Scan()
        ns.Say(ns.Plural(done, "changed %d macro: its History keeps the text it had",
            "changed %d macros: their History keeps the texts they had"))
        if #long > 0 then
            ns.Print("left as they are, they would be longer than %d characters: %s", MAX_BODY,
                table.concat(long, ", "))
        end
        -- The one open shows its new text.
        local state = shared.state
        if state.stored then shared.Load(nil, state.stored) elseif state.index then shared.Load(state.index) end
        Window.RefreshList()
        Refresh()
    end) end)
end

local function Build()
    frame = CreateFrame("Frame", "MacroSenseReplace", UIParent, "BackdropTemplate")
    table.insert(UISpecialFrames, "MacroSenseReplace") -- Esc closes it
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetWidth(440)
    ns.Backdrop(frame, "bg", "border", true)
    frame:Hide()
    local title = ns.Text(frame, 14)
    title:SetPoint("TOPLEFT", 14, -14)
    title:SetText(L["Find and replace"])
    local close = ns.Button(frame, "x", 22, function() frame:Hide() end)
    close:SetPoint("TOPRIGHT", -10, -10)
    local function Field(label, y)
        local text = ns.Text(frame, 12)
        text:SetPoint("TOPLEFT", 14, y - 5)
        text:SetText(label)
        local box = ns.Input(frame, 300, MAX_BODY)
        box:SetPoint("TOPLEFT", 126, y)
        box:SetScript("OnTextChanged", Refresh)
        return box
    end
    findBox = Field(L["Find"], -44)
    withBox = Field(L["Replace with"], -74)
    findBox:SetScript("OnTabPressed", function() withBox:SetFocus() end)
    withBox:SetScript("OnTabPressed", function() findBox:SetFocus() end)
    findBox:SetScript("OnEnterPressed", function() withBox:SetFocus() end)
    withBox:SetScript("OnEnterPressed", function() if replaceBtn:IsEnabled() then ReplaceAll() end end)
    local hint = ns.Text(frame, 11, "dim")
    hint:SetPoint("TOPLEFT", 126, -102)
    hint:SetText(L["As typed: big and small letters count."])
    local where = ns.Text(frame, 12)
    where:SetPoint("TOPLEFT", 14, -126)
    where:SetText(L["Where"])
    frame.where = where
    countText = ns.Text(frame, 12, "dim")
    replaceBtn = ns.Button(frame, L["Replace all"], 120, ReplaceAll, true)
    replaceBtn:SetPoint("BOTTOMRIGHT", -14, 12)
    -- On the button's line, both ends at its middle.
    countText:SetPoint("LEFT", frame, "BOTTOMLEFT", 14, 12 + 11)
    countText:SetPoint("RIGHT", replaceBtn, "LEFT", -12, 0)
    countText:SetJustifyH("LEFT")
    frame:SetScript("OnHide", function()
        findBox:ClearFocus()
        withBox:ClearFocus()
    end)
end

-- The groups' checks, two to a row, made as the groups are now (the specializations, macro sets on or off).
local function ShowGroups()
    for _, c in pairs(groupChecks) do c:Hide() end
    local groups = Groups()
    for i, g in ipairs(groups) do
        local c = groupChecks[i]
        if not c then
            -- Painted as it is made: ticked until it has its group.
            c = ns.Check(frame, "", function() return not (c and off[c.key]) end, function(on)
                off[c.key] = not on or nil
                Refresh()
            end)
            groupChecks[i] = c
        end
        c.key = g.key
        c:SetLabel(g.label)
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", 126 + (i - 1) % 2 * 150, -122 - math.floor((i - 1) / 2) * 24)
        c:Refresh()
        c:Show()
    end
    frame:SetHeight(122 + math.ceil(#groups / 2) * 24 + 56)
end

-- Opened with the search's text to find, the groups as they were ticked.
function Window.OpenReplace()
    if not frame then Build() end
    Window.ClearFocus()
    ShowGroups()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", shared.frame or UIParent, "CENTER", 0, 60)
    frame:Show()
    local q = strtrim(shared.search:GetText() or "")
    if q ~= "" then findBox:SetText(q) end
    findBox:SetFocus()
    findBox:HighlightText()
    Refresh()
end
