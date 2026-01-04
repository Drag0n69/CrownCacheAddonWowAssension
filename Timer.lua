local CCA = CrownCacheAddon

-- Cache times in GMT+1: 01:30, 04:30, 07:30, 10:30, 13:30, 16:30, 19:30, 22:30
-- Converted to UTC (GMT+0): 00:30, 03:30, 06:30, 09:30, 12:30, 15:30, 18:30, 21:30
local SPAWN_INTERVAL = 3 * 3600 -- 3 hours in seconds
local FIRST_SPAWN_UTC = 30 * 60 -- 00:30 UTC in seconds from midnight

function CCA:InitTimer()
    self.timerFrame = CreateFrame("Frame")
    self.timerFrame:SetScript("OnUpdate", function(self, elapsed)
        CCA:UpdateTimer(elapsed)
    end)
end

function CCA:GetNextSpawnTime()
    local dateTable = date("!*t") -- Get UTC time
    local currentSeconds = (dateTable.hour * 3600) + (dateTable.min * 60) + dateTable.sec
    
    -- Normalize to start of day + offset
    -- We want to find the next k * SPAWN_INTERVAL + FIRST_SPAWN_UTC that is > currentSeconds
    -- However, the pattern starts at 00:30. 
    -- 00:30 (1800), 03:30 (12600), etc.
    
    local nextSpawn = FIRST_SPAWN_UTC
    while nextSpawn <= currentSeconds do
        nextSpawn = nextSpawn + SPAWN_INTERVAL
    end
    
    -- If we passed the last spawn of the day (21:30 UTC), nextSpawn will be > 24h
    -- This logic handles wrapping to next day implicitly if we just subtract currentSeconds,
    -- but usually we want a timestamp or just delta.
    
    local timeRemaining = nextSpawn - currentSeconds
    
    -- Handle wrap around midnight (if needed, but the loop covers up to 24h+ if we consider next day)
    if nextSpawn >= 86400 then -- 24h * 3600
         -- It's tomorrow 00:30
         -- timeRemaining is correct logic-wise (nextSpawn is > 86400, current is e.g. 86000)
    end
    
    return timeRemaining
end

local lastUpdate = 0
function CCA:UpdateTimer(elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < 1 then return end
    lastUpdate = 0
    
    local remaining = self:GetNextSpawnTime()
    
    if CCA.UpdateUITimer then
        CCA:UpdateUITimer(remaining)
    end
    
    -- Check for 30 min warning (1800 seconds)
    -- We use a small range to avoid spamming if update is fast, but just == 1800 might miss
    if remaining == 1800 then
        self:TriggerWarning()
    end
end

function CCA:TriggerWarning()
    self:Print("Crown Cache in 30 minutes! Get ready!")
    RaidNotice_AddMessage(RaidWarningFrame, "Crown Cache in 30 minutes!", ChatTypeInfo["RAID_WARNING"])
    
    -- Auto Popup if enabled
    if CCA.DB.autoActivate and CCA.ShowPreparePopup then
        CCA:ShowPreparePopup()
    end
end
