-- Drives the suggestion popup from a CodeBox.
local _, ns = ...

local Popup = ns.Popup

-- Attach to a CodeBox. Suggestions are built from a snapshot (text, cursor, context) so that
-- accepting one never depends on what the key that accepted it did to the text.
function ns.AttachAutocomplete(box)
    local snap, pending, guard

    local function Update()
        pending = false
        if not ns.db.enabled or not box.edit:HasFocus() then return Popup:Hide() end
        local raw, cursor = box:GetRaw(), box:GetRawCursor()
        local ctx = ns.Parser.GetContext(raw, cursor)
        snap = { raw = raw, cursor = cursor, ctx = ctx }
        Popup:Open(box.edit, ns.Completion.Get(ctx), box.caretX or 0, box.caretY or 0, box.caretH or 14)
        if not Popup:IsShown() then box:LockCursor(false) end
    end

    -- Wait one frame so OnCursorChanged has reported where the cursor is now.
    local function Schedule()
        if pending then return end
        pending = true
        C_Timer.After(0, Update)
    end

    Popup.onAccept = function(item)
        if not snap or not snap.ctx then return end
        local raw, cursor = ns.Parser.Apply(snap.raw, snap.cursor, snap.ctx, item.insert)
        box:LockCursor(false)
        box:SetRaw(raw, cursor, true)
        box:SetFocus()
        -- Enter / Tab may still put a newline or tab into the text this frame: drop it.
        guard = { raw = raw, cursor = cursor, time = GetTime() }
        Schedule() -- "/cast " opens spells, "mod:" opens modifiers
    end

    box.onChange = function(raw, userInput)
        if not userInput then return end
        if guard and guard.time == GetTime() and raw ~= guard.raw then
            local g = guard
            guard = nil
            return box:SetRaw(g.raw, g.cursor, true)
        end
        guard = nil
        box:LockCursor(false)
        Schedule()
    end

    box.onCaret = function()
        -- Clicking elsewhere in the text re-checks (or closes) the list.
        if Popup:IsShown() then Schedule() end
    end

    box.onKey = function(key)
        if not Popup:IsShown() then return false end
        if key == "UP" or key == "DOWN" then
            -- The EditBox may already have moved the cursor to another line: put it back.
            box:LockCursor(true, snap and snap.cursor)
            Popup:Move(key == "UP" and -1 or 1)
            return true
        elseif key == "TAB" or key == "ENTER" then
            Popup:Accept()
            return true
        elseif key == "ESCAPE" then
            Popup:Hide()
            box:LockCursor(false)
            return true
        end
        return false
    end

    box.edit:HookScript("OnEditFocusLost", function()
        Popup:Hide()
        box:LockCursor(false)
    end)
    box.edit:HookScript("OnHide", function() Popup:Hide() end)
end
