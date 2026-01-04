local CCA = CrownCacheAddon
local PREFIX = "CCA_MAIN"

function CCA:InitComm()
    -- 3.3.5 doesn't always require prefix registration, but checking just in case
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(PREFIX)
    end
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function CCA:CHAT_MSG_ADDON(prefix, text, channel, sender)
    if prefix ~= PREFIX then return end
    
    local cmd, payload = strsplit(":", text, 2)
    
    if cmd == "REG" then
        -- Payload: Name, Class, Spec, Mode, ilvl, Resil
        local name, class, spec, mode, ilvl, resil = strsplit(",", payload)
        self:AddParticipant(name, class, spec, mode, ilvl, resil)
    elseif cmd == "REQ" then
        -- Someone requested list, send ours
        self:BroadcastRegistration()
    elseif cmd == "MSG" then
        -- Leader Broadcast
        -- Payload: Message text
        self:Print("|cFFFF0000[ANNOUNCE]|r: " .. payload)
        RaidNotice_AddMessage(RaidWarningFrame, payload, ChatTypeInfo["RAID_WARNING"])
    elseif cmd == "PREPARE" then
        -- Leader called prepare
        if CCA.ShowPreparePopup then
            CCA:ShowPreparePopup()
        end
    elseif cmd == "REQ_READY" then
        -- Leader requested Ready Check / Popup
        CCA:Print("Le leader demande un appel ! (Popup activée)")
        if CCA.ShowPreparePopup then CCA:ShowPreparePopup() end
    elseif cmd == "READY" then
        -- A player is ready (sender)
        if CCA.DB.participants[sender] then
            CCA.DB.participants[sender].isReady = true
            if CCA.UpdateParticipantList then CCA:UpdateParticipantList() end
        end
    elseif cmd == "VCHK" then
        -- Version Check Payload: "1.05"
        local remoteVer = tonumber(payload)
        if remoteVer and remoteVer > CCA.Version then
            -- We are outdated!
            if not CCA.hasShownUpdate then
                CCA.hasShownUpdate = true
                CCA:Print("|cFFFF0000NOUVELLE VERSION DISPONIBLE (" .. payload .. ") !|r")
                if CCA.ShowUpdatePopup then CCA:ShowUpdatePopup(payload) end
            end
        end
    end
end

function CCA:BroadcastVersion()
    if IsInGuild() then
        SendAddonMessage(PREFIX, "VCHK:" .. CCA.Version, "GUILD")
    end
end

function CCA:Register(spec, mode)
    local name = UnitName("player")
    local _, class = UnitClass("player")
    self.DB.mySpec = spec
    self.DB.myMode = mode or "WM" -- Default War Mode
    
    local ilvl = select(1, GetAverageItemLevel()) -- Exact value (float)
    -- 16 = COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN
    local resil = GetCombatRating(16) or 0
    
    -- Update local DB
    self:AddParticipant(name, class, spec, self.DB.myMode, ilvl, resil)
    
    -- Broadcast
    self:BroadcastRegistration()
end

function CCA:BroadcastRegistration()
    if not self.DB.mySpec or self.DB.mySpec == "None" then return end
    
    local name = UnitName("player")
    local _, class = UnitClass("player")
    local ilvl = select(1, GetAverageItemLevel())
    local resil = GetCombatRating(16) or 0
    
    -- Sending Mode as 4th arg
    -- Use %.2f for ilvl to send 2 decimals
    local msg = string.format("REG:%s,%s,%s,%s,%.2f,%s", name, class, self.DB.mySpec, self.DB.myMode or "WM", ilvl, resil)
    
    if IsInGuild() then
        SendAddonMessage(PREFIX, msg, "GUILD")
    end
end

function CCA:AddParticipant(name, class, spec, mode, ilvl, resil)
    -- Store in DB or Session Table
    CCA.DB.participants[name] = { 
        class = class, 
        spec = spec, 
        mode = mode, 
        ilvl = ilvl or 0, 
        resil = resil or 0, 
        time = time() 
    }
    
    if CCA.UpdateParticipantList then
        CCA:UpdateParticipantList()
    end
end

function CCA:RemoveParticipant(name)
    if CCA.DB.participants[name] then
        CCA.DB.participants[name] = nil
        if CCA.UpdateParticipantList then
            CCA:UpdateParticipantList()
        end
    end
end

function CCA:Unregister()
    self.DB.mySpec = nil
    self.DB.myMode = nil
    
    local name = UnitName("player")
    self:RemoveParticipant(name)
    
    if IsInGuild() then
        SendAddonMessage(PREFIX, "UNREG:" .. name, "GUILD")
    end
end
