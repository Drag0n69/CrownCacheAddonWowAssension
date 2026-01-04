local CCA = CrownCacheAddon

-- Spec Data
CCA.ClassSpecs = {
    ["MAGE"] = {
        { name = "Arcane", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
        { name = "Fire", icon = "Interface\\Icons\\Spell_Fire_FireBolt02" },
        { name = "Frost", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02" }
    },
    ["WARRIOR"] = {
        { name = "Arms", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow" },
        { name = "Fury", icon = "Interface\\Icons\\Ability_Warrior_InnerRage" },
        { name = "Prot", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance" }
    },
    ["ROGUE"] = {
        { name = "Assass", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate" },
        { name = "Combat", icon = "Interface\\Icons\\Ability_BackStab" },
        { name = "Subtlety", icon = "Interface\\Icons\\Ability_Stealth" }
    },
    ["PRIEST"] = {
        { name = "Disc", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
        { name = "Holy", icon = "Interface\\Icons\\Spell_Holy_Guardians" },
        { name = "Shadow", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain" }
    },
    ["HUNTER"] = {
        { name = "Beast", icon = "Interface\\Icons\\Ability_Mount_JungleTiger" },
        { name = "Marks", icon = "Interface\\Icons\\Ability_Hunter_AimedShot" },
        { name = "Surv", icon = "Interface\\Icons\\Ability_Hunter_QuickShot" }
    },
    ["DRUID"] = {
        { name = "Balance", icon = "Interface\\Icons\\Spell_Nature_StarFall" },
        { name = "Feral", icon = "Interface\\Icons\\Ability_Racial_BearForm" },
        { name = "Resto", icon = "Interface\\Icons\\Spell_Nature_HealingTouch" }
    },
    ["SHAMAN"] = {
        { name = "Elem", icon = "Interface\\Icons\\Spell_Nature_Lightning" },
        { name = "Enhance", icon = "Interface\\Icons\\Spell_Nature_LightningShield" },
        { name = "Resto", icon = "Interface\\Icons\\Spell_Nature_MagicAura" }
    },
    ["PALADIN"] = {
        { name = "Holy", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
        { name = "Prot", icon = "Interface\\Icons\\Spell_Holy_DevotionAura" },
        { name = "Ret", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight" }
    },
    ["WARLOCK"] = {
        { name = "Afflic", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil" },
        { name = "Demo", icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis" },
        { name = "Destro", icon = "Interface\\Icons\\Spell_Shadow_RainOfFire" }
    },
    ["DEATHKNIGHT"] = {
        { name = "Blood", icon = "Interface\\Icons\\Spell_Deathknight_BloodPresence" },
        { name = "Frost", icon = "Interface\\Icons\\Spell_Deathknight_FrostPresence" },
        { name = "Unholy", icon = "Interface\\Icons\\Spell_Deathknight_UnholyPresence" }
    }
}

--------------------------------------------------------------------------------
-- Minimap Button Logic
--------------------------------------------------------------------------------
function CCA:InitMinimapIcon()
    local btn = CreateFrame("Button", "CrownCacheMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameLevel(8)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Icon Texture - SKULL
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bone_Skull_01") 
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    
    -- Border
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT")
    
    -- Dragging Logic
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    
    -- Initial Position logic
    if not CCA.DB.minimapPos then CCA.DB.minimapPos = 45 end

    local function UpdatePosition()
        local angle = CCA.DB.minimapPos or 45
        local radius = 80
        local x = math.cos(math.rad(angle)) * radius
        local y = math.sin(math.rad(angle)) * radius
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
    
    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local angle = math.deg(math.atan2(py - my, px - mx))
            CCA.DB.minimapPos = angle
            UpdatePosition()
        end)
    end)
    
    btn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)
    
    btn:SetScript("OnClick", function()
        CCA:ToggleUI()
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Crown Cache Addon")
        GameTooltip:AddLine("Left-click to toggle dashboard.", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    btn:Show()
    UpdatePosition()
end

--------------------------------------------------------------------------------
-- HUD Timer
--------------------------------------------------------------------------------
function CCA:InitHUDTimer()
    self.hudFrame = CreateFrame("Frame", "CrownCacheHUD", UIParent)
    self.hudFrame:SetSize(200, 32) -- Widen for location
    
    -- Restore Position
    if CCA.DB.hudPos then
        local p = CCA.DB.hudPos
        self.hudFrame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    else
        self.hudFrame:SetPoint("TOP", 0, -50)
    end

    self.hudFrame:SetMovable(true)
    self.hudFrame:EnableMouse(true)
    self.hudFrame:RegisterForDrag("LeftButton")
    self.hudFrame:SetScript("OnDragStart", self.hudFrame.StartMoving)
    self.hudFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        CCA.DB.hudPos = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)
    
    -- Icon: Chest
    self.hudFrame.icon = self.hudFrame:CreateTexture(nil, "ARTWORK")
    self.hudFrame.icon:SetSize(24, 24)
    self.hudFrame.icon:SetPoint("LEFT", 5, 0)
    self.hudFrame.icon:SetTexture("Interface\\Icons\\INV_Box_01")
    
    self.hudFrame.text = self.hudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.hudFrame.text:SetPoint("LEFT", self.hudFrame.icon, "RIGHT", 5, 0)
    self.hudFrame.text:SetText("00h00")
    self.hudFrame.text:SetTextColor(1, 0.8, 0)
    
    self.hudFrame.location = self.hudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.hudFrame.location:SetPoint("LEFT", self.hudFrame.text, "RIGHT", 10, 0)
    self.hudFrame.location:SetText("") -- Hidden by default
    self.hudFrame.location:SetTextColor(0.8, 0.8, 0.8)
    
    if CCA.DB.showHUD then self.hudFrame:Show() else self.hudFrame:Hide() end
end

function CCA:ToggleHUD()
    CCA.DB.showHUD = not CCA.DB.showHUD
    if CCA.DB.showHUD then self.hudFrame:Show() else self.hudFrame:Hide() end
end

function CCA:ToggleAutoActivate()
    CCA.DB.autoActivate = not CCA.DB.autoActivate
end

--------------------------------------------------------------------------------
-- Main UI
--------------------------------------------------------------------------------
function CCA:InitUI()
    self:InitMinimapIcon()
    self:InitHUDTimer()

    self.mainFrame = CreateFrame("Frame", "CrownCacheMainFrame", UIParent)
    self.mainFrame:SetSize(350, 450) -- Increased Height for buttons
    
    -- Restore Position
    if CCA.DB.mainPos then
        local p = CCA.DB.mainPos
        self.mainFrame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    else
        self.mainFrame:SetPoint("CENTER")
    end
    
    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", self.mainFrame.StartMoving)
    self.mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        CCA.DB.mainPos = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)
    
    -- Grey Theme Backdrop (Standard WoW)
    self.mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    self.mainFrame:Hide()
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, self.mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() CCA.mainFrame:Hide() end)
    
    -- Title Header
    local header = self.mainFrame:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(400)
    header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)
    
    self.mainFrame.title = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.mainFrame.title:SetPoint("TOP", header, "TOP", 0, -14)
    self.mainFrame.title:SetText("Crown Cache Event")
    
    -- Timer Section (Left Aligned)
    self.mainFrame.timerLabel = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.mainFrame.timerLabel:SetPoint("TOPLEFT", 15, -25)
    self.mainFrame.timerLabel:SetText("Next Event In:")
    self.mainFrame.timerLabel:SetTextColor(0.7, 0.7, 0.7)

    self.mainFrame.timer = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    self.mainFrame.timer:SetPoint("TOPLEFT", 15, -38)
    self.mainFrame.timer:SetText("00h00")
    self.mainFrame.timer:SetTextColor(1, 0.8, 0)
    
    -- Location (Right of Timer)
    self.mainFrame.location = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.mainFrame.location:SetPoint("LEFT", self.mainFrame.timer, "RIGHT", 10, 0)
    self.mainFrame.location:SetText("Loc: Unknown")
    self.mainFrame.location:SetTextColor(0.8, 0.8, 0.8)

    -- Option: HUD (Top Left)
    self.hudCheck = CreateFrame("CheckButton", nil, self.mainFrame, "UICheckButtonTemplate")
    self.hudCheck:SetSize(24, 24)
    self.hudCheck:SetPoint("TOPLEFT", 15, -5) 
    self.hudCheck.text = self.hudCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.hudCheck.text:SetPoint("LEFT", self.hudCheck, "RIGHT", 2, 0)
    self.hudCheck.text:SetText("HUD")
    self.hudCheck:SetChecked(CCA.DB.showHUD)
    self.hudCheck:SetScript("OnClick", function() CCA:ToggleHUD() end)

    -- DEBUG BUTTON (Test Warning)
    self.debugBtn = CreateFrame("Button", nil, self.mainFrame, "UIPanelButtonTemplate")
    self.debugBtn:SetSize(20, 20)
    self.debugBtn:SetPoint("TOPRIGHT", -30, -5)
    self.debugBtn:SetText("T")
    self.debugBtn:SetScript("OnClick", function() 
        CCA:Print("Test Warning (Hold Shift to Skip Popup)...")
        -- Small logic adjustment: if Shift held, don't show popup
        if IsShiftKeyDown() then
             CCA:Print("Popup skipped.")
             self:Print("Crown Cache in 30 minutes! (Test)")
             RaidNotice_AddMessage(RaidWarningFrame, "Crown Cache in 30 minutes! (Test)", ChatTypeInfo["RAID_WARNING"])
        else
             CCA:TriggerWarning() 
        end
    end)
    self.debugBtn:SetScript("OnEnter", function(self) 
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT") 
        GameTooltip:SetText("Debug: Test Warning\n(Shift+Click to skip Popup)") 
        GameTooltip:Show() 
    end)
    self.debugBtn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    -- Group Management Button (Top Right, below Debug/Close)
    self.btnGroupManage = CreateFrame("Button", nil, self.mainFrame, "UIPanelButtonTemplate")
    self.btnGroupManage:SetSize(120, 22)
    self.btnGroupManage:SetPoint("TOPRIGHT", -15, -35)
    self.btnGroupManage:SetText("Gestion du groupe")
    self.btnGroupManage:SetScript("OnClick", function()
         if CCA.groupManageFrame:IsShown() then CCA.groupManageFrame:Hide() else CCA.groupManageFrame:Show() end
    end)
    self:CreateGroupManageFrame()

    -- Mode Selection (Row 1) - Compacted
    self.mode = "WM" 
    
    -- War Mode
    self.wmCheck = CreateFrame("CheckButton", nil, self.mainFrame, "UICheckButtonTemplate")
    self.wmCheck:SetPoint("TOP", -70, -65) -- Moved Up
    self.wmCheck.text = self.wmCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.wmCheck.text:SetPoint("LEFT", self.wmCheck, "RIGHT", 0, 0)
    self.wmCheck.text:SetText("War Mode")
    self.wmCheck:SetChecked(true)
    
    local wmIcon = self.mainFrame:CreateTexture(nil, "ARTWORK")
    wmIcon:SetTexture("Interface\\Icons\\PVPCurrency-Honor-Horde")
    wmIcon:SetSize(20, 20)
    wmIcon:SetPoint("RIGHT", self.wmCheck, "LEFT", -5, 0)
    
    -- High Risk
    self.hrCheck = CreateFrame("CheckButton", nil, self.mainFrame, "UICheckButtonTemplate")
    self.hrCheck:SetPoint("TOP", 70, -65) -- Moved Up
    self.hrCheck.text = self.hrCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.hrCheck.text:SetPoint("LEFT", self.hrCheck, "RIGHT", 0, 0)
    self.hrCheck.text:SetText("High Risk")
    self.hrCheck.text:SetTextColor(1, 0.2, 0.2)
    self.hrCheck:SetChecked(false)
    
    local hrIcon = self.mainFrame:CreateTexture(nil, "ARTWORK")
    hrIcon:SetTexture("Interface\\Icons\\Spell_Shadow_DeathCoil")
    hrIcon:SetSize(20, 20)
    hrIcon:SetPoint("RIGHT", self.hrCheck, "LEFT", -5, 0)
    
    -- Modes OnClick Logic
    local function UpdateMacro()
        local m = "/cast Mercenary for Hire!\n"
        local txt = "Activate "
        if CCA.mode == "HR" then 
            m = m .. "/cast High-Risk (PvP)" 
            txt = txt .. "High Risk"
        else 
            m = m .. "/cast War Mode (PvPC)" 
            txt = txt .. "War Mode"
        end
        
        if CCA.btnActivate then 
            CCA.btnActivate:SetAttribute("macrotext", m) 
            CCA.btnActivate:SetText(txt)
        end
        if CCA.secureBtn then CCA.secureBtn:SetAttribute("macrotext", m) end
    end

    self.wmCheck:SetScript("OnClick", function()
        if self.wmCheck:GetChecked() then
            CCA.mode = "WM"
            self.hrCheck:SetChecked(false)
            if CCA.DB.mySpec then CCA:Register(CCA.DB.mySpec, CCA.mode) end
        else
             CCA:Unregister()
             self.hrCheck:SetChecked(false)
             CCA:UpdateParticipateButton()
        end
        UpdateMacro()
    end)
    
    self.hrCheck:SetScript("OnClick", function()
        if self.hrCheck:GetChecked() then
            CCA.mode = "HR"
            self.wmCheck:SetChecked(true) -- Wait, logic check: HR implies checked
            self.wmCheck:SetChecked(false)
            if CCA.DB.mySpec then CCA:Register(CCA.DB.mySpec, CCA.mode) end
        else
             CCA:Unregister()
             self.wmCheck:SetChecked(false)
             CCA:UpdateParticipateButton()
        end
        UpdateMacro()
    end)

    -- Spec Selection (Row 2) - Compacted
    self.specLabel = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.specLabel:SetPoint("TOP", 0, -100) -- Moved Up
    self.specLabel:SetText("Select Specialization:")
    
    local _, englishClass = UnitClass("player")
    local specs = CCA.ClassSpecs[englishClass] or {}
    
    self.specButtons = {}
    local totalWidth = (#specs * 45) - 5
    local startX = -(totalWidth / 2) + 20
    
    for i, specData in ipairs(specs) do
        local btn = CreateFrame("Button", nil, self.mainFrame)
        btn:SetSize(40, 40)
        btn:SetPoint("TOP", startX + ((i-1)*45), -115) -- Moved Up
        
        local tex = btn:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        tex:SetTexture(specData.icon)
        
        local check = btn:CreateTexture(nil, "OVERLAY")
        check:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        check:SetBlendMode("ADD")
        check:SetAllPoints()
        check:Hide()
        btn.check = check
        
        btn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT") GameTooltip:SetText(specData.name) GameTooltip:Show() end)
        btn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
        btn:SetScript("OnClick", function()
             for _, otherBtn in pairs(CCA.specButtons) do otherBtn.check:Hide() end
             btn.check:Show()
             CCA.DB.selectedSpec = specData.name 
             
             -- Auto-update if already registered
             if CCA.DB.mySpec then
                 CCA:Register(specData.name, CCA.mode)
                 -- CCA:Print("Specialization updated.") -- Optional feedback
             end
        end)
        table.insert(self.specButtons, btn)
    end

    -- Participate Button
    self.btnParticipate = CreateFrame("Button", nil, self.mainFrame, "UIPanelButtonTemplate")
    self.btnParticipate:SetSize(130, 25)
    self.btnParticipate:SetPoint("TOPRIGHT", self.mainFrame, "TOP", -5, -170) -- Left of Center
    self.btnParticipate:SetText("Participer")
    self.btnParticipate:SetScript("OnClick", function()
        if CCA.DB.mySpec then
            CCA:Unregister()
            CCA:UpdateParticipateButton()
        else
            local selSpec = CCA.DB.selectedSpec
            if not selSpec then
                for i, btn in ipairs(self.specButtons) do
                    if btn.check:IsShown() then selSpec = specs[i].name break end
                end
            end
            if not selSpec then CCA:Print("Select a specialization first!") return end
            
            if not self.wmCheck:GetChecked() and not self.hrCheck:GetChecked() then
                self.wmCheck:SetChecked(true)
                CCA.mode = "WM"
            end
            CCA:Register(selSpec, CCA.mode)
            CCA:UpdateParticipateButton()
        end
    end)
    
    -- Manual Activate Secure Button (NEW)
    self.btnActivate = CreateFrame("Button", "CCAMainActivateBtn", self.mainFrame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
    self.btnActivate:SetSize(130, 25)
    self.btnActivate:SetPoint("TOPLEFT", self.mainFrame, "TOP", 5, -170) -- Right of Center
    self.btnActivate:SetText("Activate War Mode") -- Default
    self.btnActivate:SetAttribute("type", "macro")
    -- Set Initial Macro
    UpdateMacro() 

    -- Auto Activate Option
    self.autoCheck = CreateFrame("CheckButton", nil, self.mainFrame, "UICheckButtonTemplate")
    self.autoCheck:SetSize(24, 24)
    self.autoCheck:SetPoint("TOP", -40, -200) -- Moved Up from -220
    self.autoCheck.text = self.autoCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.autoCheck.text:SetPoint("LEFT", self.autoCheck, "RIGHT", 2, 0)
    self.autoCheck.text:SetText("Rappel Activation (30mn)")
    self.autoCheck:SetChecked(CCA.DB.autoActivate)
    self.autoCheck:SetScript("OnClick", function() CCA:ToggleAutoActivate() end)

    self.autoDesc = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.autoDesc:SetPoint("TOP", 0, -220) -- Moved Up from -240
    self.autoDesc:SetText("Affiche la popup d'activation 30mn avant l'event.")
    self.autoDesc:SetTextColor(0.6, 0.6, 0.6)

    -- Participant List Header
    self.listHeader = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.listHeader:SetPoint("TOPLEFT", 15, -240) -- Moved Up from -260
    self.listHeader:SetText("Participants:")
    
    -- List Scroll Frame (Fill rest of window)
    self.participantFrame = CreateFrame("ScrollFrame", "CCAParticipantScroll", self.mainFrame, "UIPanelScrollFrameTemplate")
    self.participantFrame:SetPoint("TOPLEFT", 15, -260) -- Moved Up from -280
    self.participantFrame:SetPoint("BOTTOMRIGHT", -30, 10) 
    
    -- Black background for list
    local listBg = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    listBg:SetColorTexture(0, 0, 0, 0.5)
    listBg:SetPoint("TOPLEFT", self.participantFrame, "TOPLEFT", -5, 5)
    listBg:SetPoint("BOTTOMRIGHT", self.participantFrame, "BOTTOMRIGHT", 25, -5)

    -- Scroll Child
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetSize(self.participantFrame:GetWidth() or 300, 500)
    self.participantFrame:SetScrollChild(scrollChild)
    self.scrollChild = scrollChild 

    self.listText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.listText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    self.listText:SetJustifyH("LEFT")
    self.listText:SetWidth(self.participantFrame:GetWidth() or 300)
    self.listText:SetText("No participants.")
    
    self.participantFrame:SetScript("OnSizeChanged", function(self)
        if CCA.listText then CCA.listText:SetWidth(self:GetWidth()) end
    end)
    
    -- Initial State
    self:UpdateParticipateButton()
    self:UpdateParticipantList() -- Populate list from DB on load
    
    self:CreateSecurePopup()
end

function CCA:UpdateParticipateButton()
    if not self.btnParticipate then return end
    
    local myName = UnitName("player")
    local isRegistered = false
    
    if CCA.DB.participants and CCA.DB.participants[myName] then
        isRegistered = true
    end
    
    if isRegistered then
        self.btnParticipate:SetText("Ne plus participer")
    else
        self.btnParticipate:SetText("Participer")
    end
end

function CCA:CreateSecurePopup()
    self.secureFrame = CreateFrame("Frame", "CrownCacheSecurePopup", UIParent)
    self.secureFrame:SetSize(300, 150)
    self.secureFrame:SetPoint("CENTER", 0, 200)
    self.secureFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Solid Background to prevent transparency issues
    local bg = self.secureFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 11, -12)
    bg:SetPoint("BOTTOMRIGHT", -12, 11)
    bg:SetColorTexture(0, 0, 0, 0.9) -- High opacity black
    
    self.secureFrame:Hide()
    
    self.secureFrame.text = self.secureFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    self.secureFrame.text:SetPoint("TOP", 0, -30)
    self.secureFrame.text:SetText("PREPARE FOR BATTLE!")
    
    self.secureFrame.subtext = self.secureFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.secureFrame.subtext:SetPoint("TOP", 0, -60)
    self.secureFrame.subtext:SetText("Click to activate PvP Modes")
    
    -- Secure Button
    self.secureBtn = CreateFrame("Button", "CCASecureBtn", self.secureFrame, "SecureActionButtonTemplate, GameMenuButtonTemplate")
    self.secureBtn:SetPoint("BOTTOMLEFT", 20, 30)
    self.secureBtn:SetSize(120, 30)
    self.secureBtn:SetText("ACTIVATE")
    self.secureBtn:SetAttribute("type", "macro")
    
    -- Ready Button
    self.readyBtn = CreateFrame("Button", nil, self.secureFrame, "UIPanelButtonTemplate")
    self.readyBtn:SetPoint("BOTTOMRIGHT", -20, 30)
    self.readyBtn:SetSize(120, 30)
    self.readyBtn:SetText("Je suis Prêt")
    self.readyBtn:SetScript("OnClick", function()
        CCA:SendReady()
        -- self.readyBtn:Disable() -- Removing disable to allow spam if needed/re-click, but hiding frame anyway
        self.secureFrame:Hide() -- Close popup on Ready
    end)
    
    -- Close button
    -- ... (Existing close btn logic is fine)
end

function CCA:SendReady()
    if IsInGuild() then
        SendAddonMessage("CCA_MAIN", "READY", "GUILD")
        CCA:Print("Statut 'Prêt' envoyé !")
    else
        CCA:Print("Erreur: Pas de guilde.")
    end
end

function CCA:ShowPreparePopup()
    if InCombatLockdown() then return end
    
    local macro = "/cast Mercenary for Hire!\n"
    local txt = "ACTIVATE"
    
    if self.mode == "HR" then
        macro = macro .. "/cast High-Risk (PvP)"
        txt = "ACTIVATE HR"
    else
        macro = macro .. "/cast War Mode (PvPC)"
        txt = "ACTIVATE WM"
    end
    
    -- Update Secure Button
    self.secureBtn:SetAttribute("macrotext", macro)
    self.secureBtn:SetText(txt)
    
    self.secureFrame:Show()
    if self.readyBtn then self.readyBtn:Enable() end
end

function CCA:ToggleUI()
    if self.mainFrame:IsShown() then self.mainFrame:Hide() else self.mainFrame:Show() end
end

function CCA:CreateGroupManageFrame()
    local f = CreateFrame("Frame", "CCAGroupManage", self.mainFrame)
    f:SetSize(250, 180) -- Increased height
    f:SetPoint("TOPLEFT", self.mainFrame, "TOPRIGHT", 5, 0) -- Attached to right side
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    f:Hide()
    self.groupManageFrame = f
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Leader Tools")
    
    -- Close Button
    local closeVal = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeVal:SetPoint("TOPRIGHT", -5, -5)
    closeVal:SetScript("OnClick", function() f:Hide() end)
    
    -- 1. Invite All
    local btnInvite = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
-- ... (existing code)
end

function CCA:ShowUpdatePopup(newVer)
    if not self.updateFrame then
        self:CreateUpdatePopup()
    end
    self.updateFrame.verText:SetText("New Version Available: " .. newVer)
    self.updateFrame:Show()
end

function CCA:CreateUpdatePopup()
    local f = CreateFrame("Frame", "CCAUpdateFrame", UIParent)
    f:SetSize(350, 120)
    f:SetPoint("CENTER", 0, 100)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("ADDON UPDATE REQUIRED")
    title:SetTextColor(1, 0, 0) -- RED ALERT
    
    f.verText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.verText:SetPoint("TOP", 0, -45)
    f.verText:SetText("New Version Available!")
    
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("TOP", 0, -65)
    sub:SetText("Press Ctrl+C to copy the link:")
    sub:SetTextColor(0.8, 0.8, 0.8)
    
    local editBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    editBox:SetSize(300, 20)
    editBox:SetPoint("BOTTOM", 0, 20)
    editBox:SetAutoFocus(true)
    editBox:SetText(CCA.DownloadURL)
    editBox:HighlightText()
    editBox:SetScript("OnEscapePressed", function() f:Hide() end)
    editBox:SetScript("OnTextChanged", function(self)
        self:SetText(CCA.DownloadURL)
        self:HighlightText()
    end)
    
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() f:Hide() end)
    
    self.updateFrame = f
end
    btnInvite:SetSize(160, 22)
    btnInvite:SetPoint("TOP", 0, -40)
    btnInvite:SetText("Invite All Participants")
    btnInvite:SetScript("OnClick", function()
        CCA:Print("Inviting all...")
        for name, _ in pairs(CCA.DB.participants) do
            if name ~= UnitName("player") then
                InviteUnit(name)
            end
        end
    end)
    
    -- 2. Ready Check / Force Popup
    local btnReady = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnReady:SetSize(160, 22)
    btnReady:SetPoint("TOP", 0, -65)
    btnReady:SetText("Lancer l'Appel (Popup)")
    btnReady:SetScript("OnClick", function()
        if IsInGuild() then
            SendAddonMessage("CCA_MAIN", "REQ_READY", "GUILD")
            CCA:Print("Demande d'appel envoyée !")
        end
    end)
    
    -- 3. Message Box
    local editBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    editBox:SetSize(200, 20)
    editBox:SetPoint("TOP", 0, -115)
    editBox:SetAutoFocus(false)
    
    local lblInit = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblInit:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", -5, 2)
    lblInit:SetText("Broadcast Message:")
    
    local btnSend = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnSend:SetSize(80, 22)
    btnSend:SetPoint("TOP", editBox, "BOTTOM", 0, -5)
    btnSend:SetText("Send")
    btnSend:SetScript("OnClick", function()
        local msg = editBox:GetText()
        if msg and msg ~= "" then
            -- Send to GUILD? or RAID?
            -- We use GUILD as main comm channel for now
            if IsInGuild() then
                SendAddonMessage("CCA_MAIN", "MSG:"..msg, "GUILD")
                CCA:Print("Broadcast sent: " .. msg)
            else
                CCA:Print("You must be in a guild to broadcast.")
            end
            editBox:SetText("")
            editBox:ClearFocus()
        end
    end)
    
end

function CCA:UpdateUITimer(remaining)
    if not remaining then return end
    local h = floor(remaining / 3600)
    local m = floor((remaining % 3600) / 60)
    -- Seconds ignored as requested "Juste heure et minute"
    local str = string.format("%02dh%02d", h, m)

    if self.mainFrame:IsShown() then
        self.mainFrame.timer:SetText(str)
    end
    
    if self.hudFrame and self.hudFrame:IsShown() then
        self.hudFrame.text:SetText(str)
    end
end

function CCA:UpdateParticipantList()
    local text = ""
    for name, data in pairs(CCA.DB.participants) do
        local color = RAID_CLASS_COLORS[data.class]
        local hex = "FFFFFF"
        if color then
            hex = string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255)
        end
        
        local modeIcon = "|TInterface\\Icons\\PVPCurrency-Honor-Horde:16|t" 
        if data.mode == "HR" then 
            modeIcon = "|TInterface\\Icons\\Spell_Shadow_DeathCoil:16|t" 
        end
        
        local readyIcon = ""
        if data.isReady then
            readyIcon = "|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t "
        end
        
        local ilvl = tonumber(data.ilvl) or 0
        -- PvP Power removed as requested
        
        text = text .. string.format("%s%s |cFF%s%s|r - %s |cFFFFD700(%.2f ilvl)|r\n", modeIcon, readyIcon, hex, name, data.spec, ilvl)
    end
    
    if text == "" then text = "No participants." end
    self.listText:SetText(text)
    
    -- Update ScrollChild height logic
    if self.scrollChild then
        local height = self.listText:GetStringHeight()
        self.scrollChild:SetHeight(math.max(height + 10, 100))
    end
end
