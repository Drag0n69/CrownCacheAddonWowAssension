CrownCacheAddon = {}
local CCA = CrownCacheAddon

CCA.DB = {}
CCA.Defaults = {
    mySpec = "None",
    participants = {},
    showHUD = true,
    autoActivate = false
}

-- VERSIONING
CCA.Version = 1.00 -- Float is easier to compare (1.01 > 1.00)
CCA.VersionStr = "1.0"
CCA.DownloadURL = "https://github.com/Antigravity/CrownCacheAddon" -- Placeholder

local eventFrame = CreateFrame("Frame")
CCA.EventFrame = eventFrame

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if CCA[event] then
        CCA[event](CCA, ...)
    end
end)

function CCA:RegisterEvent(event)
    self.EventFrame:RegisterEvent(event)
end

function CCA:UnregisterEvent(event)
    self.EventFrame:UnregisterEvent(event)
end

function CCA:ADDON_LOADED(addonName)
    if addonName ~= "CrownCacheAddon" then return end
    
    if not CrownCacheAddonDB then
        CrownCacheAddonDB = CopyTable(CCA.Defaults)
    end
    CCA.DB = CrownCacheAddonDB
    
    self:Print("Loaded! Type /cca to toggle window.")
end

function CCA:PLAYER_LOGIN()
    if CCA.InitUI then CCA:InitUI() end
    if CCA.InitTimer then CCA:InitTimer() end
    if CCA.InitComm then CCA:InitComm() end
    
    -- Check Version with Guild
    C_Timer.After(5, function() 
        if CCA.BroadcastVersion then CCA:BroadcastVersion() end
    end)
end

function CCA:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[CrownCache]|r " .. msg)
end

SLASH_CROWNCACHE1 = "/cca"
SLASH_CROWNCACHE2 = "/crown"
SlashCmdList["CROWNCACHE"] = function(msg)
    local cmd, arg = strsplit(" ", msg, 2)
    if cmd == "call" then
        -- Send PREPARE message
        if IsInGuild() then
            SendAddonMessage("CCA_MAIN", "PREPARE:ALL", "GUILD")
            CCA:Print("Sent preparation call to guild!")
        else
            CCA:Print("You need to be in a guild to use this.")
        end
    elseif cmd == "stats" then
        CCA:Print("--- DEEP STAT SCAN ---")
        
        -- 1. Scan ALL Combat Ratings safely (using pcall to avoid crash)
        CCA:Print("[Combat Ratings 0-100]")
        for i = 0, 100 do
            local success, val = pcall(GetCombatRating, i)
            if success and val and val > 0 then
                CCA:Print("CR ID " .. i .. ": " .. val)
            end
        end

        -- 2. Basic Stats
        CCA:Print("[Basic Stats]")
        local stats = {"Strength", "Agility", "Stamina", "Intellect", "Spirit"}
        for i=1, 5 do
            local _, val = UnitStat("player", i)
            CCA:Print(stats[i] .. ": " .. val)
        end
        
        -- 3. Power / Damage
        local base, pos, neg = UnitAttackPower("player")
        CCA:Print("Attack Power: " .. (base + pos + neg))
        CCA:Print("Spell Power (Arcane): " .. GetSpellBonusDamage(6))
        
        -- 4. Custom / Extended
        CCA:Print("[Custom / Other]")
        local resil = GetCombatRating(16) or 0
        CCA:Print("Resilience (16): " .. resil)
        
        -- Try random known Custom APIs
        local customFuncs = {"GetPVPPower", "GetPvpPower", "GetPvpPowerDamage", "GetVersatility", "GetMastery"}
        for _, funcName in ipairs(customFuncs) do
            if _G[funcName] then
                local s, v = pcall(_G[funcName], "player")
                if s then CCA:Print(funcName .. ": " .. tostring(v)) end
            end
        end
        
        CCA:Print("--- END SCAN ---")
        
        -- 5. UI Scan (Character Sheet)
        -- Ascension might display it as text in the character frame
        CCA:Print("[UI Text Scan]")
        -- Check children of CharacterAttributesFrame or similar
        local framesToScan = {CharacterAttributesFrame, PaperDollFrame}
        for _, frame in ipairs(framesToScan) do
            if frame then
                local regions = {frame:GetRegions()}
                for _, region in ipairs(regions) do
                     if region:GetObjectType() == "FontString" then
                         local text = region:GetText()
                         if text and (string.find(text, "PvP") or string.find(text, "Power") or string.find(text, "%d+")) then
                             CCA:Print("Found Text: " .. text)
                         end
                     end
                end
                
                 -- Also scan children frames
                local children = {frame:GetChildren()}
                for _, child in ipairs(children) do
                    local regions = {child:GetRegions()}
                    for _, region in ipairs(regions) do
                        if region:GetObjectType() == "FontString" then
                            local text = region:GetText()
                            if text and (string.find(text, "PvP") or string.find(text, "Power")) then
             -- Load DB
    self.DB = CrownCacheDB or {}
    
    -- Set Defaults
    for k, v in pairs(self.Defaults) do
        if self.DB[k] == nil then
            self.DB[k] = v
        end
    end
    CrownCacheDB = self.DB
    
    -- RESTORE Session State from DB
    -- We now KEEP the participants list (Persistence).
    -- Check if we are in it to sync our local state.
    local myName = UnitName("player")
    if self.DB.participants and self.DB.participants[myName] then
        local data = self.DB.participants[myName]
        self.DB.mySpec = data.spec
        self.DB.myMode = data.mode
    else
        -- Not in list, ensure clean state
        self.DB.mySpec = nil
        self.DB.myMode = nil
    end
    
    -- Init Modules
    self:InitComm()
    self:InitTimer()
    self:InitUI()end
                        end
                    end
                end
            end
        end
        CCA:Print("--- UI DEBUG END ---")
    else
        if CCA.ToggleUI then CCA:ToggleUI() end
    end
end

-- Global reference for XML or other files if needed
_G.CrownCacheAddon = CrownCacheAddon

-- Init
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
