-- A stand-in for the game's SecureCmdOptionParse: clauses, condition groups, @unit / target= and the
-- conditions the test macros use. Returns parse(options) -> action, unit for a game state:
--   { mods = { alt = true }, units = { mouseover = { harm = true, dead = false } }, pet = "Felhunter",
--     combat = false }
local function trim(s) return s:match("^%s*(.-)%s*$") end

return function(state)
    local function unit(u) return state.units and state.units[u:lower()] end
    local function held(list)
        local m = state.mods or {}
        if not list then return m.shift or m.ctrl or m.alt or m.cmd end
        for key in list:gmatch("[^/]+") do
            if m[key:lower()] then return true end
        end
        return false
    end
    local tests = {
        combat = function() return state.combat end,
        mod = held,
        modifier = held,
        exists = function(_, u) return unit(u) ~= nil end,
        harm = function(_, u) return unit(u) ~= nil and unit(u).harm end,
        help = function(_, u) return unit(u) ~= nil and not unit(u).harm end,
        dead = function(_, u) return unit(u) ~= nil and unit(u).dead end,
        pet = function(names)
            if not state.pet then return false end
            if not names then return true end
            for name in names:gmatch("[^/]+") do
                if name:lower() == state.pet:lower() then return true end
            end
            return false
        end,
    }
    local function check(cond, u)
        local name, value = cond:match("^(%a+):(.*)$")
        name = (name or cond):lower()
        local fn, negate = tests[name], false
        if not fn and name:sub(1, 2) == "no" then fn, negate = tests[name:sub(3)], true end
        if not fn then return false end
        return (fn(value, u) and true or false) ~= negate
    end
    return function(options)
        for clause in (options .. ";"):gmatch("([^;]*);") do
            local rest, groups = trim(clause), {}
            while rest:sub(1, 1) == "[" and rest:find("]", 1, true) do
                local close = rest:find("]", 1, true)
                groups[#groups + 1] = rest:sub(2, close - 1)
                rest = trim(rest:sub(close + 1))
            end
            if #groups == 0 then return rest end
            for _, group in ipairs(groups) do
                local conds, target = {}, nil
                for part in (group .. ","):gmatch("([^,]*),") do
                    local cond = trim(part)
                    local u = cond:match("^@(.+)$") or cond:match("^target=(.+)$")
                    if u then
                        target = u
                    elseif cond ~= "" then
                        conds[#conds + 1] = cond
                    end
                end
                local ok = true
                for _, cond in ipairs(conds) do
                    if not check(cond, target or "target") then
                        ok = false
                        break
                    end
                end
                if ok then return rest, target end
            end
        end
        return nil
    end
end
