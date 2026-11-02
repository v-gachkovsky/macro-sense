-- Two things the window does that no button says. Shorten clicked ten times in a row with Shift and Ctrl held
-- shortens the window itself: its parts fall apart and it closes. A macro saved that casts Polymorph on yourself
-- turns the window into a sheep that wanders the screen; a click on the sheep turns it back. Neither touches a
-- macro, and the window opens whole again.
local _, ns = ...
ns = ns or {}

local Easter = {}
ns.Easter = Easter

local CLICKS, GAP = 10, 2 -- clicks in a row, each within GAP seconds of the one before
local FALL, FADE = 1.6, 0.7 -- how long the parts fall, and the last part of it the window fades
local SHEEP_SIZE, SHEEP_SPEED = 44, 70
local POLYMORPH = 118

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

local frame, parts -- the window, and the frames that fall: the children of its header, list and editor
local ticker -- runs the fall each frame: the window's own OnUpdate is the editor's
local falling -- while they fall: { groups = their animations, time = so far }

-- Whether the window is falling apart now.
function Easter.Falling() return falling ~= nil end

local function Sound(...)
    if not (PlaySound and SOUNDKIT) then return end
    for _, name in ipairs({ ... }) do
        if SOUNDKIT[name] then
            pcall(PlaySound, SOUNDKIT[name])
            return
        end
    end
end

-- Every part back where it was, the window as it was. The parts only moved in an animation: their places in the
-- window (their anchors) were never changed.
local function Mend()
    if not falling then return end
    for _, group in ipairs(falling.groups) do group:Stop() end
    falling = nil
    ticker:Hide()
    frame:SetAlpha(1)
end

local function Fade(_, elapsed)
    falling.time = falling.time + elapsed
    frame:SetAlpha(math.max(0, math.min(1, (FALL - falling.time) / FADE)))
    if falling.time >= FALL then
        frame:Hide() -- OnHide mends it
    end
end

-- A part's fall: up a little, then down past the bottom of the screen, to one side.
local RISE = 0.25
local function Drop(part)
    local group = part.fall
    if not group then
        group = part:CreateAnimationGroup()
        group.up = group:CreateAnimation("Translation")
        group.up:SetOrder(1)
        group.up:SetSmoothing("OUT")
        group.down = group:CreateAnimation("Translation")
        group.down:SetOrder(2)
        group.down:SetSmoothing("IN")
        part.fall = group
    end
    local rise, side = math.random(10, 50), math.random(-160, 160)
    group.up:SetOffset(side * RISE, rise)
    group.up:SetDuration(RISE)
    group.down:SetOffset(side * (FALL - RISE), -(part:GetBottom() + part:GetHeight() + rise + 40))
    group.down:SetDuration(FALL - RISE)
    group:Play()
    return group
end

-- The window falls apart and closes.
function Easter.Shatter()
    if falling or not frame or not frame:IsShown() or InCombatLockdown() then return end
    local groups = {}
    for _, holder in ipairs(parts) do
        for _, part in ipairs({ holder:GetChildren() }) do
            if part:IsShown() and part:GetBottom() and part.CreateAnimationGroup then groups[#groups + 1] = Drop(part) end
        end
    end
    falling = { groups = groups, time = 0 }
    Sound("IG_QUEST_FAILED", "IG_MAINMENU_CLOSE")
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

-- The window, its Shorten button, and the frames whose children fall apart.
function Easter.Attach(window, shorten, holders)
    frame, parts = window, holders
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
