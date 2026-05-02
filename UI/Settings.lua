-- RaidStation :: UI/Settings.lua
-- Part of RaidStation by Marfyn- | 2026
-- Unauthorized redistribution without credit is prohibited.
local addonName, ns = ...
local Settings = {}

function Settings.CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()

    -- Título
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 35, -45)
    title:SetText("|cff00ffffAJUSTES|r")

    -- TTL Slider
    local ttlSlider = CreateFrame("Slider", "RaidStationTTLSlider", panel, "OptionsSliderTemplate")
    ttlSlider:SetPoint("TOPLEFT", 36, -72)
    ttlSlider:SetMinMaxValues(35, 600)
    ttlSlider:SetValueStep(8)
    ttlSlider:SetSize(200, 16)
    _G[ttlSlider:GetName() .. "Low"]:SetText("30s")
    _G[ttlSlider:GetName() .. "High"]:SetText("600s")
    _G[ttlSlider:GetName() .. "Text"]:SetText("Tiempo de Vida (segundos): " .. (RaidStationDB.ttl or 120))
    ttlSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText("TTL del Mensaje (segundos): " .. value)
        RaidStationDB.ttl = value
        ns.Config.DEFAULTS.ttl = value
    end)
    ttlSlider:SetValue(RaidStationDB.ttl or 120)

    -- Merge Toggle
    local mergeToggle = CreateFrame("CheckButton", "RaidStationMergeToggle", panel, "ChatConfigCheckButtonTemplate")
    mergeToggle:SetPoint("TOPLEFT", 35, -100)
    mergeToggle:SetScale(0.95)
    _G[mergeToggle:GetName() .. "Text"]:SetText("Agrupar mensajes por Líder")
    mergeToggle:SetScript("OnClick", function(self)
        RaidStationDB.mergeByLeader = self:GetChecked()
        ns.Config.DEFAULTS.mergeByLeader = self:GetChecked()
    end)
    mergeToggle:SetChecked(RaidStationDB.mergeByLeader)

    -- Debug Toggle
    local debugToggle = CreateFrame("CheckButton", "RaidStationDebugToggle", panel, "ChatConfigCheckButtonTemplate")
    debugToggle:SetPoint("TOPLEFT", 35, -120)
    debugToggle:SetScale(0.95)
    _G[debugToggle:GetName() .. "Text"]:SetText("Habilitar Modo Debug")
    debugToggle:SetScript("OnClick", function(self)
        RaidStationDB.debug = self:GetChecked()
        ns.Config.DEFAULTS.debug = self:GetChecked()
    end)
    debugToggle:SetChecked(RaidStationDB.debug)

    -- Minimap Toggle
    local minimapToggle = CreateFrame("CheckButton", "RaidStationMinimapToggle", panel, "ChatConfigCheckButtonTemplate")
    minimapToggle:SetPoint("TOPLEFT", 35, -140)
    minimapToggle:SetScale(0.95)
    _G[minimapToggle:GetName() .. "Text"]:SetText("Mostrar icono del Minimapa")
    minimapToggle:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        RaidStationDB.showMinimap = checked
        ns.Config.DEFAULTS.showMinimap = checked
        if ns.Minimap.Button then
            if checked then ns.Minimap.Button:Show() else ns.Minimap.Button:Hide() end
        end
    end)
    minimapToggle:SetChecked(RaidStationDB.showMinimap)

    -- Floating Button Toggle
    local floatToggle = CreateFrame("CheckButton", "RSFloatBtnToggle", panel, "ChatConfigCheckButtonTemplate")
    floatToggle:SetPoint("TOPLEFT", 35, -160)
    floatToggle:SetScale(0.95)
    _G[floatToggle:GetName() .. "Text"]:SetText("Mostrar boton flotante de acceso rapido")
    floatToggle:SetScript("OnClick", function(self)
        RaidStationDB.showFloatBtn = self:GetChecked()
        if ns.GUI.FloatBtn then
            if RaidStationDB.showFloatBtn then
                ns.GUI.FloatBtn:Show()
            else
                ns.GUI.FloatBtn:Hide()
            end
        end
    end)
    floatToggle:SetChecked(RaidStationDB.showFloatBtn ~= false)

    -- Reactive Sync Toggle
    local reactiveToggle = CreateFrame("CheckButton", "RaidStationReactiveToggle", panel, "ChatConfigCheckButtonTemplate")
    reactiveToggle:SetPoint("TOPLEFT", 35, -180)
    reactiveToggle:SetScale(0.95)
    _G[reactiveToggle:GetName() .. "Text"]:SetText("Vista previa en vivo (anunciador de banda)")
    reactiveToggle:SetScript("OnClick", function(self)
        RaidStationDB.reactiveSync = self:GetChecked()
    end)
    reactiveToggle:SetChecked(RaidStationDB.reactiveSync)

    -- Window Lock Toggle
    local windowLockToggle = CreateFrame("CheckButton", "RSWindowLockToggle", panel, "ChatConfigCheckButtonTemplate")
    windowLockToggle:SetPoint("TOPLEFT", 35, -200)
    windowLockToggle:SetScale(0.95)
    _G[windowLockToggle:GetName() .. "Text"]:SetText("Anclar ventana a la pantalla")
    windowLockToggle:SetScript("OnClick", function(self)
        if ns.GUI and ns.GUI.ApplyWindowLock then
            ns.GUI.ApplyWindowLock(self:GetChecked())
        end
    end)
    windowLockToggle:SetChecked(RaidStationDB.windowLocked)

    -- Sección APARIENCIA
    local bgSectionTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bgSectionTitle:SetPoint("TOPLEFT", 35, -230)
    bgSectionTitle:SetText("|cff00ffffAPARIENCIA|r")

    local bgLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bgLabel:SetPoint("TOPLEFT", 35, -250)
    bgLabel:SetText("Estilo del panel:")
    bgLabel:SetTextColor(0.9, 0.7, 0.2)

    -- IMPORTANTE: dropdown creado en panel desde el inicio para evitar
    -- problemas de reparenting de UIDropDownMenuTemplate en 3.3.5a
    local bgDropdown = CreateFrame("Frame", "RSBgStyleDropdown", panel, "UIDropDownMenuTemplate")
    bgDropdown:SetPoint("TOPLEFT", 20, -265)
    UIDropDownMenu_SetWidth(bgDropdown, 150)

    local BG_OPTIONS = {
        { value = 0, label = "Sin fondo" },
        { value = 1, label = "Fondo 1" },
        { value = 2, label = "Fondo 2" },
    }

    UIDropDownMenu_Initialize(bgDropdown, function(self, level)
        for _, opt in ipairs(BG_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = opt.label
            info.value   = opt.value
            info.checked = (RaidStationDB.bgChoice == opt.value)
            info.func    = function()
                UIDropDownMenu_SetSelectedValue(bgDropdown, opt.value)
                UIDropDownMenu_SetText(bgDropdown, opt.label)
                ns.GUI.ApplyBackground(opt.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local savedChoice = RaidStationDB.bgChoice or 0
    local savedLabel = "Sin fondo"
    for _, opt in ipairs(BG_OPTIONS) do
        if opt.value == savedChoice then savedLabel = opt.label; break end
    end
    UIDropDownMenu_SetSelectedValue(bgDropdown, savedChoice)
    UIDropDownMenu_SetText(bgDropdown, savedLabel)
    ns.GUI.SkinDropDown(bgDropdown)

    -- Alpha label y slider
    local alphaLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    alphaLabel:SetPoint("TOPLEFT", 35, -300)
    alphaLabel:SetTextColor(0.9, 0.7, 0.2)

    local savedAlphaPct = math.floor((RaidStationDB.bgAlpha or 1.0) * 100)
    alphaLabel:SetText("Opacidad del fondo: " .. savedAlphaPct .. "%")

    local alphaSlider = CreateFrame("Slider", "RSBgAlphaSlider", panel, "OptionsSliderTemplate")
    alphaSlider:SetPoint("TOPLEFT", 35, -320)
    alphaSlider:SetMinMaxValues(10, 100)
    alphaSlider:SetValueStep(5)
    alphaSlider:SetSize(200, 16)
    _G[alphaSlider:GetName() .. "Low"]:SetText("10%")
    _G[alphaSlider:GetName() .. "High"]:SetText("100%")
    _G[alphaSlider:GetName() .. "Text"]:SetText("")
    local alphaSliderReady = false
    alphaSlider:SetScript("OnValueChanged", function(self, value)
        if not alphaSliderReady then return end
        value = math.floor(value / 5) * 5
        local alpha = value / 100
        RaidStationDB.bgAlpha = alpha
        alphaLabel:SetText("Opacidad del fondo: " .. value .. "%")
        local choice = RaidStationDB.bgChoice or 0
        if choice > 0 and ns.GUI.MainFrame and ns.GUI.MainFrame.bgTexture then
            ns.GUI.MainFrame.bgTexture:SetAlpha(alpha)
        end
    end)
    alphaSlider:SetValue(savedAlphaPct)
    alphaSliderReady = true

    -- Border Toggle
    local borderToggle = CreateFrame("CheckButton", "RSBorderToggle", panel, "ChatConfigCheckButtonTemplate")
    borderToggle:SetPoint("TOPLEFT", 35, -370)
    borderToggle:SetScale(0.95)
    _G[borderToggle:GetName() .. "Text"]:SetText("Mostrar borde del panel")
    borderToggle:SetChecked(RaidStationDB.showBorder ~= false)
    borderToggle:SetScript("OnClick", function(self)
        ns.GUI.ApplyBorder(self:GetChecked() and true or false)
    end)

    -- Referencias en panel para compatibilidad con código externo
    panel.ttlSlider        = ttlSlider
    panel.mergeToggle      = mergeToggle
    panel.debugToggle      = debugToggle
    panel.reactiveToggle   = reactiveToggle
    panel.windowLockToggle = windowLockToggle

    -- === SKIN ELVUI-STYLE ===
    local function SkinSlider(slider)
        if not slider then return end
        local name = slider:GetName()
        if name then
            if _G[name.."Low"]  then _G[name.."Low"]:SetTextColor(0.7,0.7,0.7) end
            if _G[name.."High"] then _G[name.."High"]:SetTextColor(0.7,0.7,0.7) end
            if _G[name.."Text"] then _G[name.."Text"]:SetTextColor(0.9,0.7,0.2) end
        end
        local thumb = slider:GetThumbTexture()
        if thumb then
            thumb:SetWidth(8)
            thumb:SetHeight(16)
            thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
            thumb:SetVertexColor(0.9, 0.7, 0.2, 0.9)
        end
        slider:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left=0, right=0, top=0, bottom=0 }
        })
        slider:SetBackdropColor(0.1, 0.1, 0.1, 1)
        slider:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end

    SkinSlider(ttlSlider)
    SkinSlider(alphaSlider)

    if _G["RSBgStyleDropdown"] then ns.GUI.SkinDropDown(_G["RSBgStyleDropdown"]) end

    local function SkinCheckBox(cb)
        if not cb then return end
        local name = cb:GetName()
        if not name then return end
        local text = _G[name.."Text"]
        if text then text:SetTextColor(1, 1, 1) end
        cb:HookScript("OnClick", function(self)
            if self:GetChecked() then
                local ct = self:GetCheckedTexture()
                if ct then ct:SetVertexColor(0.9, 0.7, 0.2) end
            end
        end)
        if cb:GetChecked() then
            local ct = cb:GetCheckedTexture()
            if ct then ct:SetVertexColor(0.9, 0.7, 0.2) end
        end
    end

    -- Skin checkboxes del panel
    for i = 1, panel:GetNumChildren() do
        local child = select(i, panel:GetChildren())
        if child and child:IsObjectType("CheckButton") then
            SkinCheckBox(child)
        end
    end
    -- === FIN SKIN ===

    Settings.Panel = panel
    return panel
end

function Settings.Initialize()
    Settings.CreatePanel(ns.GUI.MainFrame)
end

ns.Settings = Settings
