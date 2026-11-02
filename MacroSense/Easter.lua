-- Two things the window does that no button says. Shorten clicked ten times in a row with Shift and Ctrl held
-- shortens the windows themselves: every one open blows apart and closes. A macro saved that casts Polymorph on yourself
-- turns the window into a sheep that wanders the screen; a click on the sheep turns it back. Neither touches a
-- macro, and the window opens whole again.
local _, ns = ...
ns = ns or {}

local Easter = {}
ns.Easter = Easter

local CLICKS, GAP = 10, 2 -- clicks in a row, each within GAP seconds of the one before
local FALL = 3.2 -- how long the parts fly; the windows close then
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

-- Every window that blew apart closed, every part back where it was: its anchors as they were, rows back in their
-- lists.
local function Mend()
    if not falling then return end
    local was = falling
    falling = nil
    ticker:Hide()
    for _, window in ipairs(was.windows) do window:Hide() end
    for _, group in ipairs(was.groups) do group:Stop() end
    for _, p in ipairs(was.pieces) do
        p.part:ClearAllPoints()
        for _, point in ipairs(p.points) do p.part:SetPoint(unpack(point)) end
    end
    for _, row in ipairs(was.rows) do
        row.part:SetParent(row.parent)
        row.part:SetFrameLevel(row.level)
    end
end

-- Each part on its own (a part anchored to another would follow it too): flung out, slowed by the air, pulled down.
local DRAG, GRAVITY = 2.2, 900
local function Fly(_, elapsed)
    falling.time = falling.time + elapsed
    local slow = math.max(0, 1 - DRAG * elapsed)
    for _, p in ipairs(falling.pieces) do
        p.vx, p.vy = p.vx * slow, p.vy * slow - GRAVITY * elapsed
        p.x, p.y = p.x + p.vx * elapsed, p.y + p.vy * elapsed
        p.part:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", p.x, p.y)
    end
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

local function IsText(region) return region.GetObjectType and region:GetObjectType() == "FontString" end

-- A part spins as it flies. A frame can't turn: its textures and texts do, each around the part's middle. A text
-- turns around its own.
local function Spin(part, groups)
    local px, py = part:GetCenter()
    if not px then return end
    local degrees = Between(180, 900) * (math.random(2) == 1 and -1 or 1)
    local regions = part.GetRegions and { part:GetRegions() } or { part }
    for _, region in ipairs(regions) do
        local rx, ry = region:GetCenter()
        if rx and region.CreateAnimationGroup and region:IsShown() then
            local group = Group(region, "spin", "Rotation")
            group[1]:SetDegrees(degrees)
            group[1]:SetDuration(FALL)
            group[1]:SetOrigin("CENTER", px - rx, py - ry)
            group:Play()
            groups[#groups + 1] = group
        end
    end
end

-- A part blown away from the window's middle (wx, wy): where it is now, and how fast it goes.
local function Blow(part, wx, wy, pieces)
    local left, bottom = part:GetLeft(), part:GetBottom()
    if not (left and bottom) then return end
    local px, py = part:GetCenter()
    local dx, dy = (px or wx) - wx + Between(-40, 40), (py or wy) - wy + Between(-40, 40)
    local far = math.max(1, math.sqrt(dx * dx + dy * dy))
    local speed = Between(250, 700)
    local points = {}
    for i = 1, part:GetNumPoints() do points[i] = { part:GetPoint(i) } end
    pieces[#pieces + 1] = { part = part, points = points, x = left, y = bottom, w = part:GetWidth(),
        h = part:GetHeight(), vx = dx / far * speed, vy = dy / far * speed + Between(100, 350) }
end

-- What holds the parts (the window, its panels, its border) is gone right after the blast; its texts fly too.
local function Vanish(shell, wx, wy, groups, pieces)
    for _, region in ipairs({ shell:GetRegions() }) do
        if region.CreateAnimationGroup and region:IsShown() then
            if IsText(region) then
                Blow(region, wx, wy, pieces)
            else
                -- Gone, then kept gone while the parts fly: the group stopped, it shows again.
                local group = Group(region, "vanish", "Alpha", "Alpha")
                group[1]:SetFromAlpha(1)
                group[1]:SetToAlpha(0)
                group[1]:SetStartDelay(0.12)
                group[1]:SetDuration(0.3)
                group[2]:SetFromAlpha(0)
                group[2]:SetToAlpha(0)
                group[2]:SetDuration(FALL)
                group:Play()
                groups[#groups + 1] = group
            end
        end
    end
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
-- window holds others (the header, the list, the editor): its own parts fly instead, and it is a shell that
-- vanishes; a list's rows fly each on its own. The border is a shell too.
local function Parts(window, holder, depth, out, shells)
    local w, h = window:GetWidth(), window:GetHeight()
    shells[#shells + 1] = holder
    for _, child in ipairs({ holder:GetChildren() }) do
        if child == window.nativeEdge then
            shells[#shells + 1] = child
        elseif child:IsShown() and child.CreateAnimationGroup then
            local inner = child.GetScrollChild and child:GetScrollChild()
            local big = child:GetWidth() >= w / 2 or child:GetHeight() >= h / 2
            if inner then
                for _, row in ipairs({ inner:GetChildren() }) do
                    if row:IsShown() and row:GetBottom() then out[#out + 1] = { part = row, row = true } end
                end
                Parts(window, child, 0, out, shells) -- its scroll bar
            elseif big and depth > 0 and child:GetChildren() then
                Parts(window, child, depth - 1, out, shells)
            elseif child:GetBottom() then -- laid out
                out[#out + 1] = { part = child }
            end
        end
    end
    return out, shells
end

-- Every window shown blows apart and closes.
function Easter.Shatter()
    if falling or not frame or not frame:IsShown() or InCombatLockdown() then return end
    local groups, rows, windows, pieces = {}, {}, {}, {}
    -- The addon's questions (the game's dialogs: they are not blown up, only gone), its menu and tooltip.
    if StaticPopup_Hide and StaticPopupDialogs then
        for which in pairs(StaticPopupDialogs) do
            if type(which) == "string" and which:find("^MACROSENSE_") then StaticPopup_Hide(which) end
        end
    end
    if ns.CloseMenu then ns.CloseMenu() end
    if GameTooltip then GameTooltip:Hide() end
    for _, window in ipairs(ns.windows) do
        if window:IsShown() then
            windows[#windows + 1] = window
            local wx, wy = window:GetCenter()
            wx, wy = wx or 0, wy or 0
            local level = window:GetFrameLevel() + 25
            local parts, shells = Parts(window, window, 3, {}, {})
            for _, p in ipairs(parts) do
                if p.row then
                    -- Out of its list, which would hide it past its edges.
                    rows[#rows + 1] = { part = p.part, parent = p.part:GetParent(), level = p.part:GetFrameLevel() }
                    p.part:SetParent(window)
                    p.part:SetFrameLevel(level)
                end
                Blow(p.part, wx, wy, pieces)
            end
            for _, shell in ipairs(shells) do Vanish(shell, wx, wy, groups, pieces) end
            Jolt(window, groups)
        end
    end
    -- All measured, then each let go of what it was anchored to: anchored to the screen where it is, its size
    -- kept (a frame between two anchors had it from them; a text keeps its own). One the game won't move stays.
    local free = {}
    for _, p in ipairs(pieces) do
        p.part:ClearAllPoints()
        if not IsText(p.part) then p.part:SetSize(p.w, p.h) end
        if pcall(p.part.SetPoint, p.part, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", p.x, p.y) then
            free[#free + 1] = p
            Spin(p.part, groups)
        else
            for _, point in ipairs(p.points) do p.part:SetPoint(unpack(point)) end
        end
    end
    falling = { groups = groups, rows = rows, windows = windows, pieces = free, time = 0 }
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
    ticker:SetScript("OnUpdate", Fly)
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
