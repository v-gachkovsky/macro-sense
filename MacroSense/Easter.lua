-- Two things the window does that no button says. Shorten clicked ten times in a row with Shift and Ctrl held
-- shortens the windows themselves: every one open blows apart and closes. A macro saved that casts Polymorph on yourself
-- turns the window into a sheep that wanders the screen; a click on the sheep turns it back. Neither touches a
-- macro, and the window opens whole again.
local _, ns = ...
ns = ns or {}

local Easter = {}
ns.Easter = Easter

local CLICKS, GAP = 10, 2 -- clicks in a row, each within GAP seconds of the one before
local FALL, FADE = 4, 1.5 -- how long the parts fly, and the last part of it the window fades
local SHEEP_SIZE, SHEEP_SPEED = 44, 70
local POLYMORPH = 118
local FATALITY = "BugSack: Fatality" -- BugSack's sound, in LibSharedMedia when BugSack is there

-- Whether `body` casts Polymorph on yourself: a /cast or /use line with @player (or target=player) and the
-- spell, in English or in the game's language.
function Easter.SelfSheep(body, localName)
    local names = { "polymorph" }
    if localName and localName ~= "" then names[2] = localName:lower() end
    for line in ((body or "") .. "\n"):gmatch("([^\n]*)\n") do
        local text = line:lower()
        if text:match("^%s*/cast%s") or text:match("^%s*/use%s") then
            if text:find("@player", 1, true) or text:find("target=player", 1, true) then
                for _, name in ipairs(names) do
                    if text:find(name, 1, true) then return true end
                end
            end
        end
    end
    return false
end

-- Whether ten clicks have come, each soon after the one before: `times` the clicks so far, `now` this one's.
function Easter.Counted(times, now)
    local last = times[#times]
    if last and now - last > GAP then
        for i = #times, 1, -1 do times[i] = nil end
    end
    times[#times + 1] = now
    if #times < CLICKS then return false end
    for i = #times, 1, -1 do times[i] = nil end
    return true
end

local frame -- the editor's window
local ticker -- runs the fall each frame: the window's own OnUpdate is the editor's
local falling -- while they fall: { groups = their animations, time = so far }

-- Whether the window is falling apart now.
function Easter.Falling() return falling ~= nil end

-- A sound another addon put in LibSharedMedia: whether it played.
local function Shared(name)
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local file = LSM and LSM:Fetch("sound", name, true)
    return file and PlaySoundFile and pcall(PlaySoundFile, file, "Master") or false
end

local function Sound(...)
    if not (PlaySound and SOUNDKIT) then return end
    for _, name in ipairs({ ... }) do
        if SOUNDKIT[name] then
            pcall(PlaySound, SOUNDKIT[name])
            return
        end
    end
end

-- Every window that blew apart closed, every part back where it was. The parts only moved in
-- animations: their places in the windows (their anchors) were never changed; rows go back into their lists.
local function Mend()
    if not falling then return end
    local was = falling
    falling = nil
    ticker:Hide()
    for _, window in ipairs(was.windows) do window:Hide() end
    for _, group in ipairs(was.groups) do group:Stop() end
    for _, row in ipairs(was.rows) do
        row.part:SetParent(row.parent)
        row.part:SetFrameLevel(row.level)
    end
    for _, window in ipairs(was.windows) do window:SetAlpha(1) end
end

local function Fade(_, elapsed)
    falling.time = falling.time + elapsed
    local alpha = math.max(0, math.min(1, (FALL - falling.time) / FADE))
    for _, window in ipairs(falling.windows) do window:SetAlpha(alpha) end
    if falling.time >= FALL then Mend() end
end

local function Between(low, high) return low + math.random() * (high - low) end

-- An animation group of `object` with its `kinds` in turn, made once and kept on it as `key`.
local function Group(object, key, ...)
    local group = object[key]
    if group then return group end
    group = object:CreateAnimationGroup()
    for order, kind in ipairs({ ... }) do
        local a = group:CreateAnimation(kind)
        a:SetOrder(order)
        group[order] = a
    end
    object[key] = group
    return group
end

-- A part spins as it flies: a frame can't turn, its textures and texts can, each around the part's middle.
local function Spin(part, groups, time)
    local px, py = part:GetCenter()
    if not px then return end
    local degrees = Between(180, 1080) * (math.random(2) == 1 and -1 or 1)
    for _, region in ipairs({ part:GetRegions() }) do
        local rx, ry = region:GetCenter()
        if rx and region.CreateAnimationGroup and region:IsShown() then
            local group = Group(region, "spin", "Rotation")
            group[1]:SetDegrees(degrees)
            group[1]:SetDuration(time)
            group[1]:SetOrigin("CENTER", px - rx, py - ry)
            group:Play()
            groups[#groups + 1] = group
        end
    end
end

-- A part blown away from the window's middle (wx, wy): out fast, then down past the bottom of the screen.
local function Blow(part, wx, wy, groups)
    local group = Group(part, "fall", "Translation", "Translation")
    local blast, fall = group[1], group[2]
    group.down = fall
    local px, py = part:GetCenter()
    local dx, dy = (px or wx) - wx + Between(-40, 40), (py or wy) - wy + Between(-40, 40)
    local far = math.max(1, math.sqrt(dx * dx + dy * dy))
    local speed = Between(250, 650)
    local time = Between(0.5, 0.7) -- fast at once, slowing: the OUT smoothing
    local outX, outY = dx / far * speed * time, dy / far * speed * time + Between(30, 160)
    blast:SetStartDelay(Between(0, 0.08))
    blast:SetOffset(outX, outY)
    blast:SetDuration(time)
    blast:SetSmoothing("OUT")
    fall:SetOffset(dx / far * speed * Between(0.3, 0.8), -((part:GetBottom() or 0) + part:GetHeight() + outY + 80))
    fall:SetDuration(FALL - time)
    fall:SetSmoothing("IN")
    group:Play()
    groups[#groups + 1] = group
    Spin(part, groups, FALL)
end

-- A window jolts, as if hit.
local function Jolt(window, groups)
    local group = Group(window, "jolt", "Translation", "Translation", "Translation", "Translation")
    for i, a in ipairs(group) do
        a:SetOffset(Between(6, 14) * (i % 2 == 1 and 1 or -1), Between(-8, 8))
        a:SetDuration(0.035)
    end
    group:Play()
    groups[#groups + 1] = group
end

-- The parts of a window that fly: the frames in it, each on its own. A frame as wide or as high as half the
-- window holds others (the header, the list, the editor): its own parts fly instead, and it stays; a list's rows
-- fly each on its own. Its border stays too: it fades with the window.
local function Parts(window, holder, depth, out)
    local w, h = window:GetWidth(), window:GetHeight()
    for _, child in ipairs({ holder:GetChildren() }) do
        if child ~= window.nativeEdge and child:IsShown() and child.CreateAnimationGroup then
            local inner = child.GetScrollChild and child:GetScrollChild()
            local big = child:GetWidth() >= w / 2 or child:GetHeight() >= h / 2
            if inner then
                for _, row in ipairs({ inner:GetChildren() }) do
                    if row:IsShown() and row:GetBottom() then out[#out + 1] = { part = row, row = true } end
                end
                Parts(window, child, 0, out) -- its scroll bar
            elseif big and depth > 0 and child:GetChildren() then
                Parts(window, child, depth - 1, out)
            elseif child:GetBottom() then -- laid out
                out[#out + 1] = { part = child }
            end
        end
    end
    return out
end

-- Every window shown blows apart and closes.
function Easter.Shatter()
    if falling or not frame or not frame:IsShown() or InCombatLockdown() then return end
    local groups, rows, windows = {}, {}, {}
    for _, window in ipairs(ns.windows) do
        if window:IsShown() then
            windows[#windows + 1] = window
            local wx, wy = window:GetCenter()
            wx, wy = wx or 0, wy or 0
            local level = window:GetFrameLevel() + 25
            for _, p in ipairs(Parts(window, window, 3, {})) do
                if p.row then
                    -- Out of its list, which would hide it past its edges.
                    rows[#rows + 1] = { part = p.part, parent = p.part:GetParent(), level = p.part:GetFrameLevel() }
                    p.part:SetParent(window)
                    p.part:SetFrameLevel(level)
                end
                Blow(p.part, wx, wy, groups)
            end
            Jolt(window, groups)
        end
    end
    falling = { groups = groups, rows = rows, windows = windows, time = 0 }
    if not Shared(FATALITY) then Sound("IG_QUEST_FAILED", "IG_MAINMENU_CLOSE") end
    ns.Print("shortened by 100%%")
    ticker:Show()
end

------------------------------------------------------------------------
-- The sheep
------------------------------------------------------------------------
local sheep

local function Wander(self, elapsed)
    local x, y = self.x, self.y
    local dx, dy = self.toX - x, self.toY - y
    local far = math.sqrt(dx * dx + dy * dy)
    self.wait = (self.wait or 0) - elapsed
    if self.wait > 0 then return end
    if far < 4 then
        -- A pause to graze, then somewhere else.
        self.wait = math.random() * 1.5
        self.toX = math.random(40, math.floor(UIParent:GetWidth()) - 40)
        self.toY = math.random(60, math.floor(UIParent:GetHeight()) - 60)
        return
    end
    local step = math.min(far, SHEEP_SPEED * elapsed)
    self.x, self.y = x + dx / far * step, y + dy / far * step
    -- It faces the way it walks.
    if dx < 0 then self.icon:SetTexCoord(0.92, 0.08, 0.08, 0.92) else self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", self.x, self.y)
end

local function Sheep()
    if sheep then return sheep end
    sheep = CreateFrame("Button", nil, UIParent)
    sheep:SetSize(SHEEP_SIZE, SHEEP_SIZE)
    sheep:SetFrameStrata("DIALOG")
    sheep:SetClampedToScreen(true)
    sheep.icon = sheep:CreateTexture(nil, "ARTWORK")
    sheep.icon:SetAllPoints()
    sheep.icon:SetTexture("Interface\\Icons\\Spell_Nature_Polymorph")
    sheep.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    sheep:SetScript("OnUpdate", Wander)
    sheep:SetScript("OnClick", function(self)
        self:Hide()
        frame:Show()
    end)
    sheep:Hide()
    return sheep
end

-- The window becomes a sheep where it was.
function Easter.Polymorph()
    if not frame or not frame:IsShown() or falling then return end
    local s = Sheep()
    local x, y = frame:GetCenter()
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    s.x, s.y = (x or 400) * scale, (y or 300) * scale
    s.toX, s.toY, s.wait = s.x, s.y, 0.8
    s:ClearAllPoints()
    s:SetPoint("CENTER", UIParent, "BOTTOMLEFT", s.x, s.y)
    frame:Hide()
    s:Show()
    Sound("IG_SPELLBOOK_CLOSE", "IG_MAINMENU_CLOSE")
end

-- A macro was saved: its text.
function Easter.Saved(body)
    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(POLYMORPH)
        or GetSpellInfo and (GetSpellInfo(POLYMORPH))
    if Easter.SelfSheep(body, name) then Easter.Polymorph() end
end

-- The editor's window and its Shorten button.
function Easter.Attach(window, shorten)
    frame = window
    ticker = CreateFrame("Frame", nil, UIParent)
    ticker:Hide()
    ticker:SetScript("OnUpdate", Fade)
    frame:HookScript("OnHide", Mend)
    -- The window shown another way: no sheep then.
    frame:HookScript("OnShow", function() if sheep then sheep:Hide() end end)
    -- Clicks on Shorten count while it is dimmed too: a dimmed button gets no clicks, so the game's word that
    -- a mouse button went down is listened to.
    local times = {}
    local watch = CreateFrame("Frame")
    pcall(watch.RegisterEvent, watch, "GLOBAL_MOUSE_DOWN")
    watch:SetScript("OnEvent", function(_, _, button)
        if button ~= "LeftButton" or not shorten:IsVisible() or not shorten:IsMouseOver() then return end
        if not (IsShiftKeyDown() and IsControlKeyDown()) then
            for i = #times, 1, -1 do times[i] = nil end
            return
        end
        if Easter.Counted(times, GetTime()) then Easter.Shatter() end
    end)
end

return Easter
