-- RaidStation :: UI/Advertiser.lua
-- Part of RaidStation by Marfin- | 2026
-- Unauthorized redistribution without credit is prohibited.
local addonName, ns = ...
local AdvertiserUI = {}

local function SkinRoleEditBox(eb)
    ns.GUI.SkinEditBox(eb)
    eb:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 14,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    eb:SetBackdropColor(0.06, 0.06, 0.06, 1)
    eb:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
end


function AdvertiserUI.CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()

    -- (Clear button moved to header)

    -- Raid & Interval
    local raidLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raidLabel:SetPoint("TOPLEFT", 35, -50)
    raidLabel:SetText("|cffffff00Banda|r")

    -- Raid Dropdown
    local raidDrop = CreateFrame("Frame", "RaidStationRaidDrop", panel, "UIDropDownMenuTemplate")
    raidDrop:SetPoint("LEFT", raidLabel, "RIGHT", -5, -5)
    UIDropDownMenu_SetWidth(raidDrop, 60)

    local raids = { "ICC", "SR", "TOC", "ARCHA", "SEMANAL", "ULDUAR", "VIAJEROS" }
    UIDropDownMenu_Initialize(raidDrop, function(self, level)
        for _, r in ipairs(raids) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = r
            info.func = function()
                UIDropDownMenu_SetSelectedValue(raidDrop, r)
                UIDropDownMenu_SetText(raidDrop, r)
                ns.Advertiser.patterns.raidName = r

                -- Auto-fallback to Normal for ARCHA
                if r == "ARCHA" then
                    ns.Advertiser.patterns.difficulty = "N"
                    UIDropDownMenu_SetSelectedValue(AdvertiserUI.diffDrop, "N")
                    UIDropDownMenu_SetText(AdvertiserUI.diffDrop, "N")
                end

                if RaidStationDB.reactiveSync then
                    AdvertiserUI:ActualizarHeader(true)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(raidDrop, raids[1])
    UIDropDownMenu_SetText(raidDrop, raids[1])
    ns.GUI.SkinDropDown(raidDrop)
    AdvertiserUI.raidDrop = raidDrop

    local intervalLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    intervalLabel:SetPoint("LEFT", raidDrop, "RIGHT", 8, 4)
    intervalLabel:SetText("|cffffff00Intervalo (s)|r")

    local intervalInput = CreateFrame("EditBox", nil, panel)
    intervalInput:SetSize(30, 20)
    intervalInput:SetPoint("LEFT", intervalLabel, "RIGHT", 0,-2)
    intervalInput:SetAutoFocus(false)
    intervalInput:SetFontObject("ChatFontNormal")
    intervalInput:SetText("25")
    intervalInput:SetNumeric(true)
    ns.GUI.SkinEditBox(intervalInput)
    intervalInput:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 14,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    intervalInput:SetBackdropColor(0.06, 0.06, 0.06, 1)
    intervalInput:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
    intervalInput:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    intervalInput:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)
    intervalInput:SetScript("OnTextChanged", function(self)
        local val = tonumber(self:GetText()) or 60
        ns.Advertiser.interval = val
    end)
    AdvertiserUI.intervalInput = intervalInput

    -- Start/Stop Button
    local startBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    startBtn:SetSize(60, 20)
    startBtn:SetPoint("LEFT", intervalInput, "RIGHT", 0, 0)
    startBtn:SetText("INICIAR")
    ns.GUI.ApplyCustomTexture(startBtn, "Interface\\AddOns\\RaidStation\\Textures\\nbutton1.blp")
    startBtn:SetScript("OnClick", function(self)
        if ns.Advertiser.isSpamming then
            ns.Advertiser:Stop()
            self:SetText("INICIAR")
        else
            ns.Advertiser:Start()
            self:SetText("PARAR")
        end
        AdvertiserUI:UpdateStatus()
    end)
    AdvertiserUI.startBtn = startBtn

    --Countdown Timer Display
    local countdownText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countdownText:SetPoint("LEFT", startBtn, "RIGHT", 5, 0)
    countdownText:SetText("")
    AdvertiserUI.countdownText = countdownText

    --Section: Composition
    local compTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    compTitle:SetPoint("TOP", 0, -85)
    compTitle:SetText("|cffffff00COMPOSICIÓN|r")

    local roles = {
        { id = "tank",    label = "Tanque", color = "|cff0070de" },
        { id = "healer",  label = "Healer", color = "|cff1eff00" },
        { id = "melee",   label = "Melee",  color = "|cffff7d0a" },
        { id = "caster",  label = "Caster", color = "|cffa335ee" },
        { id = "message", label = "Notas",  color = "|cffffffff" }
    }

    AdvertiserUI.roleInputs = {}
    local roleColors = {
        tank = { 0.0, 0.44, 1.0 },    -- Blue
        healer = { 0.12, 1.0, 0.0 },  -- Green
        melee = { 1.0, 0.49, 0.04 },  -- Orange
        caster = { 0.64, 0.21, 0.93 } -- Purple
    }

    for i, role in ipairs(roles) do
        local yOffset = -70 - (i * 34)

        -- No custom color for border as requested
        local box = ns.GUI.CreateBox(panel, 335, 34)
        box:SetPoint("TOP", 0, yOffset)

        local label = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", 12, 0)
        label:SetText(role.color .. role.label .. "|r")
        label:SetWidth(60)
        label:SetJustifyH("LEFT")

        local needInput
        if role.id ~= "message" then
            needInput = CreateFrame("EditBox", nil, box)
            needInput:SetSize(40, 22)
            needInput:SetPoint("LEFT", label, "RIGHT", 10, 0)
            needInput:SetNumeric(true)
            needInput:SetAutoFocus(false)
            needInput:SetFontObject("ChatFontNormal")
            needInput:SetText("")
            SkinRoleEditBox(needInput)
            needInput:SetScript("OnTextChanged", function(self)
                ns.Advertiser.patterns.roles[role.id].need = tonumber(self:GetText()) or 0
                if RaidStationDB.reactiveSync then
                    AdvertiserUI:ActualizarHeader(true)
                end
            end)
            needInput:SetScript("OnEditFocusGained", function(self)
                AdvertiserUI.lastFocusedEB = self
                self:HighlightText()
            end)
            needInput:SetScript("OnEditFocusLost", function(self)
                self:HighlightText(0, 0)
            end)
        end

        local classInput = CreateFrame("EditBox", nil, box)
        if role.id == "message" then
            classInput:SetSize(200, 22)
            classInput:SetPoint("LEFT", label, "RIGHT", 10, 0)
        else
            classInput:SetSize(150, 22)
            classInput:SetPoint("LEFT", needInput, "RIGHT", 10, 0)
        end
        classInput:SetAutoFocus(false)
        classInput:SetFontObject("ChatFontNormal")
        SkinRoleEditBox(classInput)
        classInput:SetScript("OnTextChanged", function(self)
            if role.id == "message" then
                ns.Advertiser.patterns.message = self:GetText()
            else
                ns.Advertiser.patterns.roles[role.id].class = self:GetText()
            end
            if RaidStationDB.reactiveSync then
                AdvertiserUI:ActualizarHeader(true)
            end
        end)
        classInput:SetScript("OnEditFocusGained", function(self)
            AdvertiserUI.lastFocusedEB = self
            if role.id == "message" then
                self:HighlightText()
            end
        end)
        if role.id == "message" then
            classInput:SetScript("OnEditFocusLost", function(self)
                self:HighlightText(0, 0)
            end)
        end

        AdvertiserUI.roleInputs[role.id] = { need = needInput, class = classInput }
    end

    -- Section: Channels
    local chanBox = ns.GUI.CreateBox(panel, 335, 30)
    chanBox:SetPoint("TOP", 0, -280)

    local chanLabel = chanBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chanLabel:SetPoint("LEFT", 12, 0)
    chanLabel:SetText("|cffffff00Canales|r")

    local channels = { "1", "2", "3", "4", "5", "GLD" }
    AdvertiserUI.chanChecks = {}
    for i, chan in ipairs(channels) do
        local check = CreateFrame("CheckButton", "RaidStationChanCheck" .. i, chanBox, "ChatConfigCheckButtonTemplate")
        if i == 1 then
            check:SetPoint("LEFT", chanLabel, "RIGHT", 5, 0)
        else
            check:SetPoint("LEFT", AdvertiserUI.chanChecks[i - 1], "RIGHT", 30, 0)
        end
        check:SetScale(0.8)

        local checkText = _G[check:GetName() .. "Text"]
        checkText:SetText(chan)
        checkText:SetFontObject("GameFontHighlightSmall")
        checkText:SetWidth(chan == "GLD" and 35 or 12)
        check:SetHitRectInsets(0, -checkText:GetWidth(), 0, 0)

        check:SetScript("OnClick", function(self)
            ns.Advertiser.channels[chan] = self:GetChecked()
            AdvertiserUI:ActualizarHeader(true)
        end)
        AdvertiserUI.chanChecks[i] = check
    end

    -- Section: Progress & Count
    local progBox = ns.GUI.CreateBox(panel, 335, 34)
    progBox:SetPoint("TOP", 0, -315)

    local countLabel = progBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("LEFT", 12, 0)
    countLabel:SetText("|cffffff00Progreso|r")

    local currentInput = CreateFrame("EditBox", nil, progBox)
    currentInput:SetSize(30, 22)
    currentInput:SetPoint("LEFT", countLabel, "RIGHT", 15, 0)
    currentInput:SetNumeric(true)
    currentInput:SetAutoFocus(false)
    currentInput:SetFontObject("ChatFontNormal")
    currentInput:SetText("0")
    ns.GUI.SkinEditBox(currentInput)
    currentInput:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    currentInput:SetBackdropColor(0.06, 0.06, 0.06, 1)
    currentInput:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
    currentInput:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    currentInput:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)
    currentInput:SetScript("OnTextChanged", function(self)
        ns.Advertiser.patterns.currentCount = tonumber(self:GetText()) or 0
        if RaidStationDB.reactiveSync then
            AdvertiserUI:ActualizarHeader(true)
        end
    end)
    AdvertiserUI.currentCountInput = currentInput

    -- Size Dropdown (10 / 25)
    local sizeDrop = CreateFrame("Frame", "RaidStationSizeDrop", progBox, "UIDropDownMenuTemplate")
    sizeDrop:SetPoint("LEFT", currentInput, "RIGHT", -5, -2)
    UIDropDownMenu_SetWidth(sizeDrop, 45)

    local sizes = { 10, 25 }
    UIDropDownMenu_Initialize(sizeDrop, function(self, level)
        for _, s in ipairs(sizes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = tostring(s)
            info.func = function()
                UIDropDownMenu_SetSelectedValue(sizeDrop, s)
                UIDropDownMenu_SetText(sizeDrop, tostring(s))
                ns.Advertiser.patterns.totalCount = s
                if RaidStationDB.reactiveSync then
                    AdvertiserUI:ActualizarHeader(true)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedValue(sizeDrop, 10)
    UIDropDownMenu_SetText(sizeDrop, "10")
    ns.Advertiser.patterns.totalCount = 10
    ns.GUI.SkinDropDown(sizeDrop)
    AdvertiserUI.sizeDrop = sizeDrop

    -- Difficulty Dropdown
    local diffDrop = CreateFrame("Frame", "RaidStationDiffDrop", progBox, "UIDropDownMenuTemplate")
    diffDrop:SetPoint("LEFT", sizeDrop, "RIGHT", -15, 0)
    UIDropDownMenu_SetWidth(diffDrop, 35)

    UIDropDownMenu_Initialize(diffDrop, function(self, level)
        UIDropDownMenu_AddButton({
            text = "N",
            value = "N",
            func = function(self)
                UIDropDownMenu_SetSelectedValue(AdvertiserUI.diffDrop, self.value)
                ns.Advertiser.patterns.difficulty = self.value
                if RaidStationDB.reactiveSync then
                    AdvertiserUI:ActualizarHeader(true)
                end
            end
        })
        if ns.Advertiser.patterns.raidName ~= "ARCHA" then
            UIDropDownMenu_AddButton({
                text = "H",
                value = "H",
                func = function(self)
                    UIDropDownMenu_SetSelectedValue(AdvertiserUI.diffDrop, self.value)
                    ns.Advertiser.patterns.difficulty = self.value
                    if RaidStationDB.reactiveSync then
                        AdvertiserUI:ActualizarHeader(true)
                    end
                end
            })
        end
    end)
    UIDropDownMenu_SetSelectedValue(diffDrop, "N")
    UIDropDownMenu_SetText(diffDrop, "N")
    ns.Advertiser.patterns.difficulty = "N"
    ns.GUI.SkinDropDown(diffDrop)
    AdvertiserUI.diffDrop = diffDrop

    -- Botón SYNC: lee composición del raid y actualiza currentCount
    local syncBtn = CreateFrame("Button", nil, progBox, "UIPanelButtonTemplate")
    syncBtn:SetSize(45, 16)
    syncBtn:SetPoint("LEFT", diffDrop, "RIGHT", -3, 2)
    syncBtn:SetText("SYNC")
    ns.GUI.ApplyCustomTexture(syncBtn, "Interface\\AddOns\\RaidStation\\Textures\\nbutton1.blp")
    syncBtn:SetScript("OnClick", function()
        AdvertiserUI:SyncRosterCount()
    end)
    AdvertiserUI.syncBtn = syncBtn

    -- Sync Status Text (Punto indicador, feedback visual)
    local syncStatus = progBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    syncStatus:SetPoint("LEFT", syncBtn, "RIGHT", 0, 0)
    syncStatus:SetText("|cff555555● SYNC|r")

    AdvertiserUI.syncStatus = syncStatus

    -- Section: Preview
    local prevBox = ns.GUI.CreateBox(panel, 335, 85)
    prevBox:SetPoint("TOP", 0, -355)

    local prevLabel = prevBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevLabel:SetPoint("TOPLEFT", 10, -5)
    prevLabel:SetText("|cffffff00Vista Previa|r")

    -- Symbols Grid (Inside prevBox header)
    local symbolsGrid = CreateFrame("Frame", nil, prevBox)
    symbolsGrid:SetSize(150, 20)
    symbolsGrid:SetPoint("LEFT", prevLabel, "RIGHT", 10, 0)

    for i = 1, 8 do
        local btn = CreateFrame("Button", nil, symbolsGrid)
        btn:SetSize(16, 16)
        if i == 1 then
            btn:SetPoint("LEFT", 0, 0)
        else
            btn:SetPoint("LEFT", symbolsGrid.btns[i - 1], "RIGHT", 4, 0)
        end
        btn:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i)
        btn:SetScript("OnClick", function()
            local rt = "{rt" .. i .. "}"
            local target = ns.GUI.activeEditBox or AdvertiserUI.previewEdit
            if target then
                target:Insert(rt)
            else
                print("|cff00ff00Marfin|r: Primero haz clic en un cuadro de texto para insertar el símbolo.")
            end
        end)
        ns.GUI.SkinButton(btn, false)
        symbolsGrid.btns = symbolsGrid.btns or {}
        symbolsGrid.btns[i] = btn
    end

    local previewCount = prevBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    previewCount:SetPoint("TOPRIGHT", -10, -7)
    previewCount:SetText("0/255")
    AdvertiserUI.previewCount = previewCount

    local previewEdit = CreateFrame("EditBox", nil, prevBox)
    previewEdit:SetPoint("TOPLEFT", 1, -22)
    previewEdit:SetPoint("BOTTOMRIGHT", -1, 16) -- Leave space for manualAlert at bottom
    previewEdit:SetTextInsets(8, 8, 8, 8)
    previewEdit:SetMultiLine(true)
    previewEdit:SetAutoFocus(false)
    previewEdit:SetFontObject("ChatFontNormal")
    previewEdit:SetMaxLetters(255)
    ns.GUI.SkinEditBox(previewEdit)

    -- Customize background of the editbox to be flatter inside the box
    if previewEdit.SetBackdropColor then
        previewEdit:SetBackdropColor(0, 0, 0, 0)
        previewEdit:SetBackdropBorderColor(0, 0, 0, 0)
    end

    previewEdit:SetScript("OnTextChanged", function(self, userInput)
        local p = ns.Advertiser.patterns
        if userInput then
            p.fullMessage = self:GetText()
        end
        AdvertiserUI:UpdatePreviewCount()
    end)

    previewEdit:SetScript("OnEditFocusGained", function(self)
        ns.GUI.activeEditBox = self
    end)

    AdvertiserUI.previewEdit = previewEdit


    -- Patterns & Padlock (Bottom Section - Above status)
    local patternsDrop = CreateFrame("Frame", "RaidStationPatternsDrop", panel, "UIDropDownMenuTemplate")
    patternsDrop:SetPoint("BOTTOMLEFT", 18, 30)
    UIDropDownMenu_SetWidth(patternsDrop, 80)

    local function UpdatePatternsMenu()
        UIDropDownMenu_Initialize(patternsDrop, function(self, level)
            for i = 1, 6 do
                local info = UIDropDownMenu_CreateInfo()
                info.text = "Patron " .. i
                info.func = function()
                    UIDropDownMenu_SetSelectedValue(patternsDrop, i)
                    UIDropDownMenu_SetText(patternsDrop, "Patron " .. i)
                    if ns.Advertiser:LoadPattern(i) then
                        AdvertiserUI:RefreshAllInputs()
                    end
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
    end
    UpdatePatternsMenu()
    UIDropDownMenu_SetText(patternsDrop, "Patrones")
    ns.GUI.SkinDropDown(patternsDrop)
    AdvertiserUI.patternsDrop = patternsDrop

    local savePatternBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    savePatternBtn:SetSize(55, 16)
    savePatternBtn:SetPoint("LEFT", patternsDrop, "RIGHT", -115, 25)
    savePatternBtn:SetText("Guardar")
    ns.GUI.ApplyCustomTexture(savePatternBtn, "Interface\\AddOns\\RaidStation\\Textures\\nbutton1.blp")
    savePatternBtn:SetScript("OnClick", function()
        local idx = UIDropDownMenu_GetSelectedValue(patternsDrop)
        if idx and idx >= 1 and idx <= 6 then
            ns.Advertiser:SavePattern(idx)
        else
            print("|cff00ff00Marfin|r: Selecciona un slot (Patron 1-6) primero.")
        end
    end)
    AdvertiserUI.savePatternBtn = savePatternBtn

    -- Status Text (Footer)
    local statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOMRIGHT", -35, 75)
    statusText:SetText("Estado: |cffff0000OFF|r")
    AdvertiserUI.statusText = statusText

    function AdvertiserUI:ActualizarHeader(isSilent)
        local p = ns.Advertiser.patterns
        local parts = ns.Advertiser:GetHeaderParts() -- Separate tech parts: base, needs, progress
        local current = self.previewEdit:GetText()

        -- 1. Sync Technical Parts (A, B, C)
        -- Part A: Header (Armo ICC 25 H)
        local basePattern = "Armo [^{%-%[]+"
        if current:find(basePattern) then
            current = current:gsub(basePattern, parts.base .. " ", 1)
        end

        -- Part B: Needs (- need Tank, Healer, ...)
        local needsPattern = "%- need [^{%[]+"
        if current:find(needsPattern) then
            if parts.needs ~= "" then
                current = current:gsub(needsPattern, parts.needs .. " ", 1)
            else
                current = current:gsub(needsPattern, "", 1)
            end
        elseif parts.needs ~= "" then
            -- If needs missing, append them after the base header (Part A)
            local basePattern = "(Armo [^{%- ]+)" -- Added capture group and a space check
            if current:find(basePattern) then
                current = current:gsub(basePattern, "%1 " .. parts.needs .. " ", 1)
            else
                current = current .. " " .. parts.needs
            end
        end

        -- Part C: Progress ([x/y])
        local countPattern = "%[%d+/%d+%]"
        if current:find(countPattern) then
            current = current:gsub(countPattern, parts.progress, 1)
        else
            -- If progress missing, append it after needs or at the end
            current = current .. " " .. parts.progress
        end

        -- 2. Sync 'Notas' field — anchored on [x/y] progress block
        -- Capture any {rtN} marker wrapping the notes BEFORE we cut, so we can re-wrap on re-append.
        -- Pattern: [x/y] ... {rtN}<notes>{rtN}  →  capture the marker tag (e.g. "rt8")
        local progressAnchor = current:match("%[%d+/%d+%]")

        -- Extract the live notes marker from the string (if present) so we can re-apply it.
        -- We look for {rtN} immediately after [x/y] (with optional space) wrapping any text.
        local liveMarker = current:match("%[%d+/%d+%]%s*{(rt%d)}") -- e.g. "rt8"
        if liveMarker then
            p.notesMarker = liveMarker
        end
        -- p.notesMarker persists across calls; only reset when notes are cleared.
        if not p.message or p.message == "" then
            p.notesMarker = nil
        end

        local function wrapNotes(base, notes, marker)
            if marker and marker ~= "" then
                return base .. " {" .. marker .. "}" .. notes .. "{" .. marker .. "}"
            end
            return base .. " " .. notes
        end

        if progressAnchor then
            -- Has a progress block: cut everything after [x/y] and re-append notes.
            current = current:gsub("%[%d+/%d+%].*$", progressAnchor)
            if p.message and p.message ~= "" then
                current = wrapNotes(current, p.message, p.notesMarker)
            end
        else
            -- No progress block: fall back to end-of-string strip (legacy path).
            if p.lastSyncNotes and p.lastSyncNotes ~= "" then
                local escapedOldNotes = p.lastSyncNotes:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
                local stripped = current:gsub("%s*{rt%d}%s*" .. escapedOldNotes .. "%s*{rt%d}%s*$", "")
                if stripped == current then
                    stripped = current:gsub("%s*" .. escapedOldNotes .. "%s*$", "")
                end
                current = stripped
            end
            if p.message and p.message ~= "" then
                current = wrapNotes(current, p.message, p.notesMarker)
            end
        end
        p.lastSyncNotes = p.message

        -- Finish
        self.previewEdit:SetText(current)
        p.fullMessage = current

        if not isSilent then
            print("|cff00ff00Marfin|r: Composición actualizada.")
        end

        -- Sync Performance & Visual Feedback
        if self.syncStatus then
            self.syncStatus:SetText("|cff00ff00«»|r")
            self.syncTime = GetTime()
        end
    end

    function AdvertiserUI:SyncRosterCount()
        local count = 0
        local numRaid = GetNumRaidMembers()
        if numRaid > 0 then
            -- Raid: contar solo conectados
            for i = 1, numRaid do
                local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
                if name and online then
                    count = count + 1
                end
            end
        else
            -- Grupo de 5: GetNumPartyMembers() no incluye al jugador
            local numParty = GetNumPartyMembers()
            if numParty > 0 then
                count = numParty + 1
            end
        end

        -- Solo actualizar si el valor cambió (evitar updates innecesarios)
        if count ~= ns.Advertiser.patterns.currentCount then
            ns.Advertiser.patterns.currentCount = count
            AdvertiserUI.currentCountInput:SetText(tostring(count))
            AdvertiserUI:ActualizarHeader(true)
        end
    end

    function AdvertiserUI:UpdatePreview()
        self:UpdatePreviewCount()
    end

    function AdvertiserUI:UpdatePreviewCount()
        local msg = self.previewEdit:GetText()
        local len = strlen(msg)
        local color = (len > 255) and "|cffff0000" or "|cff00ff00"
        self.previewCount:SetText(color .. len .. "|r/255")
    end

    function AdvertiserUI:UpdateStatus()
        if ns.Advertiser.isSpamming then
            self.statusText:SetText("Estado: |cff00ff00ON|r (Enviando...)")
        else
            self.statusText:SetText("Estado: |cffff0000OFF|r")
        end
    end

    function AdvertiserUI:RefreshAllInputs()
        local p = ns.Advertiser.patterns
        UIDropDownMenu_SetSelectedValue(self.raidDrop, p.raidName)
        UIDropDownMenu_SetText(self.raidDrop, p.raidName)
        self.intervalInput:SetText(tostring(ns.Advertiser.interval))
        UIDropDownMenu_SetText(self.diffDrop, p.difficulty)

        -- Special handling for role inputs including "message"
        for id, inputs in pairs(self.roleInputs) do
            if id == "message" then
                inputs.class:SetText(p.message or "")
            else
                if inputs.need then inputs.need:SetText(tostring(p.roles[id].need)) end
                inputs.class:SetText(p.roles[id].class or "")
            end
        end

        self.currentCountInput:SetText(tostring(p.currentCount))
        UIDropDownMenu_SetSelectedValue(self.sizeDrop, p.totalCount)
        UIDropDownMenu_SetText(self.sizeDrop, tostring(p.totalCount))

        -- Reset Sync State (Sync V3)
        local base = ns.Advertiser:GetLatestAutoHeader()
        p.lastAutoGenerated = base
        p.lastSyncNotes = ""
        self.previewEdit:SetText(base)
        p.fullMessage = base
    end

    -- === SKIN ELVUI-STYLE ===
    -- Skinear todos los EditBox del panel
    for i = 1, panel:GetNumChildren() do
        local child = select(i, panel:GetChildren())
        if child then
            if child:IsObjectType("EditBox") then
                ns.GUI.SkinEditBox(child)
            elseif child:IsObjectType("CheckButton") then
                -- Colorear checkboxes de canales
                local name = child:GetName()
                if name then
                    local text = _G[name.."Text"]
                    if text then text:SetTextColor(0.4, 0.4, 0.4) end
                end
                if child:GetChecked() then
                    local ct = child:GetCheckedTexture()
                    if ct then ct:SetVertexColor(0.4, 0.4, 0.4) end
                end
                child:HookScript("OnClick", function(self)
                    local ct2 = self:GetCheckedTexture()
                    if ct2 then
                        if self:GetChecked() then
                            ct2:SetVertexColor(0.4, 0.4, 0.4)
                        else
                            ct2:SetVertexColor(1, 1, 1)
                        end
                    end
                end)
            end
        end
    end

    -- Skinear el dropdown de Banda si existe
    if _G["RaidStationRaidDrop"] then
        ns.GUI.SkinDropDown(_G["RaidStationRaidDrop"])
    end
    -- === FIN SKIN ===

    AdvertiserUI.Panel = panel

    -- Initial Sync (Corrected for V3)
    local p = ns.Advertiser.patterns
    local base = ns.Advertiser:GetLatestAutoHeader()
    local combined = base
    if p.message and p.message ~= "" then
        combined = combined .. " " .. p.message
    end

    p.lastAutoGenerated = base
    p.lastSyncNotes = p.message
    p.fullMessage = combined
    AdvertiserUI.previewEdit:SetText(combined)

    AdvertiserUI:UpdatePreview()

    -- Eventos y Tickers locales de UI
    panel:RegisterEvent("RAID_ROSTER_UPDATE")
    panel:RegisterEvent("PARTY_MEMBERS_CHANGED")
    panel:SetScript("OnEvent", function(self, event)
        if event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
            AdvertiserUI:SyncRosterCount()
        end
    end)

    -- Countdown OnUpdate
    local lastCountdown = -1
    panel:SetScript("OnUpdate", function(self, elapsed)
        -- Sync Status Logic
        if AdvertiserUI.syncTime and AdvertiserUI.syncTime > 0 then
            if (GetTime() - AdvertiserUI.syncTime) > 3 then
                AdvertiserUI.syncStatus:SetText("|cff555555«»|r")
                AdvertiserUI.syncTime = 0
            end
        end

        -- Countdown Logic
        if not ns.Advertiser.isSpamming then
            if AdvertiserUI.countdownText:GetText() ~= "" then
                AdvertiserUI.countdownText:SetText("")
            end
            return
        end

        local now = GetTime()
        local remaining = math.ceil(ns.Advertiser.interval - (now - ns.Advertiser.lastSpamTime))
        if remaining < 0 then remaining = 0 end

        -- Solo actualizar el texto si el valor cambió (evitar renders innecesarios)
        if remaining ~= lastCountdown then
            lastCountdown = remaining
            if remaining == 0 then
                AdvertiserUI.countdownText:SetText("|cff00ff00Enviando...|r")
            else
                AdvertiserUI.countdownText:SetText("|cffffff00" .. remaining .. "s|r")
            end
        end
    end)

    return panel
end

function AdvertiserUI.Initialize()
    AdvertiserUI.CreatePanel(ns.GUI.MainFrame)
end

ns.AdvertiserUI = AdvertiserUI
