-- RaidStation :: Settings.lua
-- Part of RaidStation by Marfin | 2026
-- Unauthorized redistribution without credit is prohibited.
local addonName, ns = ...
local Settings = {}

function Settings.CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()
    
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 35, -45)
    title:SetText("|cff00ffffAJUSTES|r")
    
    -- TTL Slider
    local ttlSlider = CreateFrame("Slider", "MarfinRBrowserTTLSlider", panel, "OptionsSliderTemplate")
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
    local mergeToggle = CreateFrame("CheckButton", "MarfinRBrowserMergeToggle", panel, "ChatConfigCheckButtonTemplate")
    mergeToggle:SetPoint("TOPLEFT", 35, -100)
    mergeToggle:SetScale(0.95)
    _G[mergeToggle:GetName() .. "Text"]:SetText("Agrupar mensajes por Líder")
    mergeToggle:SetScript("OnClick", function(self)
        RaidStationDB.mergeByLeader = self:GetChecked()
        ns.Config.DEFAULTS.mergeByLeader = self:GetChecked()
    end)
    mergeToggle:SetChecked(RaidStationDB.mergeByLeader)

    -- Debug Toggle
    local debugToggle = CreateFrame("CheckButton", "MarfinRBrowserDebugToggle", panel, "ChatConfigCheckButtonTemplate")
    debugToggle:SetPoint("TOPLEFT", 35, -120)
    debugToggle:SetScale(0.95)
    _G[debugToggle:GetName() .. "Text"]:SetText("Habilitar Modo Debug")
    debugToggle:SetScript("OnClick", function(self)
        RaidStationDB.debug = self:GetChecked()
        ns.Config.DEFAULTS.debug = self:GetChecked()
    end)
    debugToggle:SetChecked(RaidStationDB.debug)

    -- Minimap Toggle (Shifted up to make room)
    local minimapToggle = CreateFrame("CheckButton", "MarfinRBrowserMinimapToggle", panel, "ChatConfigCheckButtonTemplate")
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

    -- NEW: Reactive Sync Toggle
    local reactiveToggle = CreateFrame("CheckButton", "MarfinRBrowserReactiveToggle", panel, "ChatConfigCheckButtonTemplate")
    reactiveToggle:SetPoint("TOPLEFT", 35, -160)
    reactiveToggle:SetScale(0.95)
    _G[reactiveToggle:GetName() .. "Text"]:SetText("Vista previa en vivo (anunciador de banda)")
    reactiveToggle:SetScript("OnClick", function(self)
        RaidStationDB.reactiveSync = self:GetChecked()
    end)
    reactiveToggle:SetChecked(RaidStationDB.reactiveSync)

    local windowLockToggle = CreateFrame("CheckButton", "RSWindowLockToggle", panel, "ChatConfigCheckButtonTemplate")
    windowLockToggle:SetPoint("TOPLEFT", 35, -180)
    windowLockToggle:SetScale(0.95)
    _G[windowLockToggle:GetName() .. "Text"]:SetText("Anclar ventana a la pantalla")
    windowLockToggle:SetScript("OnClick", function(self)
        if ns.GUI and ns.GUI.ApplyWindowLock then
            ns.GUI.ApplyWindowLock(self:GetChecked())
        end
    end)
    windowLockToggle:SetChecked(RaidStationDB.windowLocked)

    local bgSectionTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bgSectionTitle:SetPoint("TOPLEFT", 35, -210)
    bgSectionTitle:SetText("|cff00ffffAPARIENCIA|r")

    local bgLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bgLabel:SetPoint("TOPLEFT", 35, -230)
    bgLabel:SetText("Estilo del panel:")
    bgLabel:SetTextColor(0.9, 0.7, 0.2)

    local bgDropdown = CreateFrame("Frame", "RSBgStyleDropdown", panel, "UIDropDownMenuTemplate")
    bgDropdown:SetPoint("TOPLEFT", 20, -250)
    UIDropDownMenu_SetWidth(bgDropdown, 150)

    local BG_OPTIONS = {
        { value = 0, label = "Sin fondo" },
        { value = 1, label = "Fondo 1" },
        { value = 2, label = "Fondo 2" },
        -- { value = 3, label = "Fondo 3" },
        -- { value = 4, label = "Fondo 4" },
        -- { value = 5, label = "Fondo 5" },
        -- { value = 6, label = "Fondo 6" },
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

    -- Inicializar con valor guardado
    local savedChoice = RaidStationDB.bgChoice or 0
    local savedLabel = "Sin fondo"
    for _, opt in ipairs(BG_OPTIONS) do
        if opt.value == savedChoice then savedLabel = opt.label; break end
    end
    UIDropDownMenu_SetSelectedValue(bgDropdown, savedChoice)
    UIDropDownMenu_SetText(bgDropdown, savedLabel)
    ns.GUI.SkinDropDown(bgDropdown)

    local alphaLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    alphaLabel:SetPoint("TOPLEFT", 35, -280)
    alphaLabel:SetTextColor(0.9, 0.7, 0.2)

    local savedAlphaPct = math.floor((RaidStationDB.bgAlpha or 1.0) * 100)
    alphaLabel:SetText("Opacidad del fondo: " .. savedAlphaPct .. "%")

    local alphaSlider = CreateFrame("Slider", "RSBgAlphaSlider", panel, "OptionsSliderTemplate")
    alphaSlider:SetPoint("TOPLEFT", 35, -300)
    alphaSlider:SetMinMaxValues(10, 100)
    alphaSlider:SetValueStep(5)
    alphaSlider:SetSize(200, 16)
    _G[alphaSlider:GetName() .. "Low"]:SetText("10%")
    _G[alphaSlider:GetName() .. "High"]:SetText("100%")
    _G[alphaSlider:GetName() .. "Text"]:SetText("")   -- usamos alphaLabel en su lugar
    local alphaSliderReady = false
    alphaSlider:SetScript("OnValueChanged", function(self, value)
        if not alphaSliderReady then return end   -- ignorar disparo de init
        value = math.floor(value / 5) * 5   -- snap a múltiplos de 5
        local alpha = value / 100
        RaidStationDB.bgAlpha = alpha
        alphaLabel:SetText("Opacidad del fondo: " .. value .. "%")
        -- Aplicar EN VIVO solo si hay estilo activo
        local choice = RaidStationDB.bgChoice or 0
        if choice > 0 and ns.GUI.MainFrame and ns.GUI.MainFrame.bgTexture then
            ns.GUI.MainFrame.bgTexture:SetAlpha(alpha)
        end
    end)
    alphaSlider:SetValue(savedAlphaPct)
    alphaSliderReady = true

    local borderToggle = CreateFrame("CheckButton", "RSBorderToggle", panel, "ChatConfigCheckButtonTemplate")
    borderToggle:SetPoint("TOPLEFT", 35, -350)
    borderToggle:SetScale(0.95)
    _G[borderToggle:GetName() .. "Text"]:SetText("Mostrar borde del panel")
    borderToggle:SetChecked(RaidStationDB.showBorder ~= false)
    borderToggle:SetScript("OnClick", function(self)
        ns.GUI.ApplyBorder(self:GetChecked() and true or false)
    end)

    panel.ttlSlider = ttlSlider
    panel.mergeToggle = mergeToggle
    panel.debugToggle = debugToggle
    panel.reactiveToggle = reactiveToggle
    panel.windowLockToggle = windowLockToggle
    
    -- === SKIN ELVUI-STYLE ===
    -- Aplicar skin a todos los sliders del panel
    local function SkinSlider(slider)
        if not slider then return end
        local name = slider:GetName()
        if name then
            if _G[name.."Low"]  then _G[name.."Low"]:SetTextColor(0.7,0.7,0.7) end
            if _G[name.."High"] then _G[name.."High"]:SetTextColor(0.7,0.7,0.7) end
            if _G[name.."Text"] then _G[name.."Text"]:SetTextColor(0.9,0.7,0.2) end
        end
        -- Thumb del slider
        local thumb = slider:GetThumbTexture()
        if thumb then
            thumb:SetWidth(8)
            thumb:SetHeight(16)
            thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
            thumb:SetVertexColor(0.9, 0.7, 0.2, 0.9)
        end
        -- Track del slider
        slider:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left=0, right=0, top=0, bottom=0 }
        })
        slider:SetBackdropColor(0.1, 0.1, 0.1, 1)
        slider:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end

    -- Aplicar a los sliders que existan en el panel
    if panel.ttlSlider  then SkinSlider(panel.ttlSlider)  end
    if panel.alphaSlider then SkinSlider(panel.alphaSlider) end

    -- Aplicar skin al dropdown de fondo si existe
    if _G["RSBgStyleDropdown"] then ns.GUI.SkinDropDown(_G["RSBgStyleDropdown"]) end

    -- Skin de checkboxes (colorear el borde dorado cuando están activos)
    local function SkinCheckBox(cb)
        if not cb then return end
        local name = cb:GetName()
        if not name then return end
        local text = _G[name.."Text"]
        if text then text:SetTextColor(1, 1, 1) end
        -- Borde dorado en el checkbox frame
        local cbname = name
        cb:HookScript("OnClick", function(self)
            if self:GetChecked() then
                -- No hay una API directa, pero podemos colorear el check texture
                local ct = self:GetCheckedTexture()
                if ct then ct:SetVertexColor(0.9, 0.7, 0.2) end
            end
        end)
        -- Aplicar color inicial
        if cb:GetChecked() then
            local ct = cb:GetCheckedTexture()
            if ct then ct:SetVertexColor(0.9, 0.7, 0.2) end
        end
    end

    -- Aplicar a todos los checkboxes del panel
    -- (buscar todos los children que sean CheckButton)
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
