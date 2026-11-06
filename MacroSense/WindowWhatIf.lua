-- "What if", by Live preview: the notes next to the lines for a moment you set up yourself (WhatIf.lua) instead
-- of the game's now. The keys held, combat, and who your target, mouseover and focus are; with the editor open the
-- mouse can't be over someone in the world, so this is how a mouseover macro is checked.
local _, ns = ...
local L = ns.L

local Window = ns.Window

local ROW = 26
local moment = ns.WhatIf.Fresh() -- for the session: the editor opened again keeps it
local strip, editorBg, bar, keysRow, unitsRow, hint
local controls = {}

-- The env for Preview.Evaluate: the moment set up, while "What if" is on; else nil (the game's now).
function Window.PreviewEnv()
    if not (ns.db.preview and ns.db.whatIf) then return nil end
    -- What the moment doesn't set up, the game tells: one condition, for the unit of its group.
    local function real(cond, unit)
        local ok, action = pcall(SecureCmdOptionParse, "[@" .. unit .. "," .. cond .. "] x")
        return ok and action == "x"
    end
    return ns.WhatIf.Env(moment, real, ns.previewEnv.icon, ns.sources.reaction)
end

-- Shown with Live preview on; its second row and the keys with "What if" on. The editor ends over it.
function Window.RefreshWhatIf()
    if not strip then return end
    local on, live = ns.db.whatIf and true or false, ns.db.preview and true or false
    strip:SetShown(live)
    keysRow:SetShown(on)
    unitsRow:SetShown(on)
    hint:SetShown(not on)
    strip:SetHeight(on and 2 * ROW or ROW)
    editorBg:ClearAllPoints()
    editorBg:SetPoint("TOPLEFT", 12, -58)
    editorBg:SetPoint("BOTTOMRIGHT", live and strip or bar, "TOPRIGHT", live and 0 or -12, live and 4 or 10)
    for _, c in pairs(controls) do c:Refresh() end
end

local function Changed()
    Window.RefreshPreview()
end

-- Made with the window (Window.lua), over the status bar `barFrame`, the editor `bg` above it.
function Window.BuildWhatIf(main, bg, barFrame)
    editorBg, bar = bg, barFrame
    strip = CreateFrame("Frame", nil, main)
    strip:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 12, 6)
    strip:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -12, 6)
    strip:Hide()
    local check = ns.Check(strip, L["What if"], function() return ns.db.whatIf end, function(on)
        ns.db.whatIf = on or nil
        Window.RefreshWhatIf()
        Changed()
    end)
    check:SetPoint("TOPLEFT", 0, -2)
    controls.whatIf = check
    check:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["What if"], 1, 1, 1)
        GameTooltip:AddLine(L["The notes next to the lines for a moment you set up: the keys held, combat, and who "
            .. "your target, mouseover and focus are. With the editor open your mouse can't be over someone, so this "
            .. "is how to check a mouseover macro. Anything else the macro checks is as in the game now."],
            0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    check:HookScript("OnLeave", function() GameTooltip:Hide() end)
    hint = ns.Text(strip, 11, "dim")
    hint:SetPoint("LEFT", check, "RIGHT", 10, 0)
    hint:SetText(L["set up the keys, the target and the mouseover yourself"])

    -- The keys held and combat, after it.
    keysRow = CreateFrame("Frame", nil, strip)
    keysRow:SetPoint("TOPLEFT", check, "TOPRIGHT", 14, 0)
    keysRow:SetSize(400, ROW)
    local keys = { "shift", "ctrl", "alt" }
    if IsMacClient and IsMacClient() then keys[#keys + 1] = "cmd" end
    local names = { shift = "Shift", ctrl = "Ctrl", alt = "Alt", cmd = "Cmd" }
    local x = 0
    for _, key in ipairs(keys) do
        local c = ns.Check(keysRow, names[key], function() return moment.mods[key] end, function(on)
            moment.mods[key] = on or nil
            Changed()
        end)
        c:SetPoint("TOPLEFT", x, 0)
        controls[key] = c
        x = x + c:GetWidth() + 12
    end
    local combat = ns.Check(keysRow, L["In combat"], function() return moment.combat end, function(on)
        moment.combat = on
        Changed()
    end)
    combat:SetPoint("TOPLEFT", x + 6, 0)
    controls.combat = combat

    -- Who the target, the mouseover and the focus are.
    unitsRow = CreateFrame("Frame", nil, strip)
    unitsRow:SetPoint("TOPLEFT", 0, -ROW)
    unitsRow:SetPoint("TOPRIGHT", 0, -ROW)
    unitsRow:SetHeight(ROW)
    local kinds = { none = L["Nobody"], enemy = L["An enemy"], friend = L["A friend"], dead = L["A dead enemy"] }
    local labels = { target = L["Target"], mouseover = L["Mouseover"], focus = L["Focus"] }
    local items = {}
    for i, kind in ipairs(ns.WhatIf.KINDS) do items[i] = { key = kind, name = kinds[kind] } end
    local prev
    for _, unit in ipairs(ns.WhatIf.UNITS) do
        local label = ns.Text(unitsRow, 12)
        if prev then label:SetPoint("LEFT", prev, "RIGHT", 12, 0) else label:SetPoint("LEFT", 0, 0) end
        label:SetText(labels[unit])
        local d = ns.Dropdown(unitsRow, 104, function() return items end, function() return moment.units[unit] end,
            function(kind)
                moment.units[unit] = kind
                Changed()
            end)
        d:SetPoint("LEFT", label, "RIGHT", 6, 0)
        controls[unit] = d
        prev = d
    end
    Window.RefreshWhatIf()
end

-- The moment set up, for the tests.
function Window.WhatIfMoment() return moment end
