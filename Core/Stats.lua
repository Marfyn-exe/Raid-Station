-- RaidStation :: Core/Stats.lua
-- Part of RaidStation by Marfin- | 2026
-- Unauthorized redistribution without credit is prohibited.
local addonName, ns = ...
local Stats = {}

local raidLockoutCache = {}

function Stats.RequestRaidLockouts()
    wipe(raidLockoutCache)
    for i = 1, GetNumSavedInstances() do
        -- 3.3.5a API: name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress
        local name, id, reset, difficulty, locked, _, _, isRaid, _, _, _, _ = GetSavedInstanceInfo(i)
        if isRaid and locked then
            -- Normalize name to get our internal raidId (e.g. "Ciudadela..." -> "icc")
            local clean = ns.Parser.Normalize(name)
            local tokens = ns.Parser.Tokenize(clean)
            local raid = ns.Matcher.FindRaid(tokens)
            
            if raid then
                local key = raid.id .. ":" .. difficulty
                raidLockoutCache[key] = { reset = reset, locked = locked, id = id }
            end
        end
    end
end

function Stats.RaidLockInfo(raidId, difficultyId)
    local key = raidId .. ":" .. difficultyId
    local data = raidLockoutCache[key]
    if data then
        return data.locked, data.reset, data.id
    end
    return false, nil, nil
end

function Stats.BuildInvString(raidName)
    local message = "inv "
    local class = UnitClass("player")
    local spec = "DPS" -- Fallback or get from Talent/GS if available
    local gs = 0       -- Fallback
    
    -- Try to get from GearScore if available
    if _G.GearScore_GetScore then
        gs = _G.GearScore_GetScore(UnitName("player"), "player")
    end

    message = message .. (gs > 0 and (gs .. "gs ") or "") .. spec .. " " .. class
    return message
end

ns.Stats = Stats
