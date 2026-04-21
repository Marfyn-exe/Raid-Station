local addonName, ns = ...
local GUI = {
    rows = {},
    selectedSender = nil,
    activeFilter = "ALL",
    searchPattern = ""
}

local ROWS_LIMIT = 20
local ROW_HEIGHT = 18
local IsElvUI = _G.ElvUI ~= nil

local RAID_CLASS_COLORS = _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS

local strlower = string.lower
local strfind = string.find
local tinsert = table.insert
local tsort = table.sort

function GUI.SkinButton(btn, strip)
    if not btn then return end

    -- Hide default textures if requested (for Blizzard templates)
    if strip then
        if btn.SetNormalTexture then btn:SetNormalTexture("") end
        if btn.SetPushedTexture then btn:SetPushedTexture("") end
        if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
        if btn.SetDisabledTexture then btn:SetDisabledTexture("") end

        local name = btn:GetName()
        if name then
            if _G[name .. "Left"] then _G[name .. "Left"]:Hide() end
            if _G[name .. "Right"] then _G[name .. "Right"]:Hide() end
            if _G[name .. "Middle"] then _G[name .. "Middle"]:Hide() end
        end

        -- Hide any remaining background textures/layers
        for _, region in ipairs({ btn:GetRegions() }) do
            if region:IsObjectType("Texture") then
                local tex = region:GetTexture()
                if tex and (strfind(tex, "UI%-Panel%-Button") or strfind(tex, "UI%-OptionsButton")) then
                    region:SetAlpha(0)
                end
            end
        end
    end

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })

    btn:SetBackdropColor(0.06, 0.06, 0.06, 1)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    btn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0, 0.5, 1, 1) -- Blue highlight
    end)

    btn:HookScript("OnLeave", function(self)
        self:SetBackdropColor(0.06, 0.06, 0.06, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
end

function GUI.ApplyCustomTexture(btn, texPath, alphaIdle, alphaHover)
    alphaIdle = alphaIdle or 0.85
    alphaHover = alphaHover or 1.0

    -- Limpiar skin ElvUI/Blizzard
    if btn.SetNormalTexture then btn:SetNormalTexture("") end
    if btn.SetPushedTexture then btn:SetPushedTexture("") end
    if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
    btn:SetBackdrop(nil)

    -- Textura custom en BACKGROUND (debajo del texto)
    local bgTex = btn:CreateTexture(nil, "BACKGROUND")
    bgTex:SetAllPoints(btn)
    bgTex:SetTexture(texPath)
    bgTex:SetAlpha(alphaIdle)
    btn.bgTex = bgTex -- guardar referencia para cambios futuros

    -- Hover
    btn:HookScript("OnEnter", function(self)
        bgTex:SetAlpha(alphaHover)
        bgTex:SetVertexColor(0.8, 0.9, 1) -- tinte azul suave ElvUI
    end)
    btn:HookScript("OnLeave", function(self)
        bgTex:SetAlpha(alphaIdle)
        bgTex:SetVertexColor(1, 1, 1)
    end)
end

function GUI.SkinDropDown(drop)
    if not drop then return end
    local name = drop:GetName()

    if _G[name .. "Left"] then _G[name .. "Left"]:SetAlpha(0) end
    if _G[name .. "Right"] then _G[name .. "Right"]:SetAlpha(0) end
    if _G[name .. "Middle"] then _G[name .. "Middle"]:SetAlpha(0) end

    local btn = _G[name .. "Button"]
    if btn then
        btn:ClearAllPoints()
        btn:SetPoint("RIGHT", drop, "RIGHT", -10, 3)
        btn:SetSize(20, 20)

        -- Quitamos el skin individual del botÃ³n para que parezca una sola pieza
        if btn.SetBackdrop then btn:SetBackdrop(nil) end

        local tex = btn:GetNormalTexture()
        if tex then
            tex:SetDesaturated(true)
            tex:SetVertexColor(0.4, 0.4, 0.4) -- Color oro
        end
    end

    -- Fondo Ãºnico para todo el dropdown (incluyendo el botÃ³n)
    local bg = drop.mskin or CreateFrame("Frame", nil, drop)
    bg:ClearAllPoints()
    bg:SetPoint("LEFT", 15, 3)
    bg:SetPoint("RIGHT", drop, "RIGHT", -10, 3)
    bg:SetHeight(20)
    bg:SetFrameLevel(drop:GetFrameLevel() - 1)

    bg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    bg:SetBackdropColor(0.06, 0.06, 0.06, 1)
    bg:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) -- Color oro
    drop.mskin = bg
end

function GUI.SkinEditBox(edit)
    if not edit then return end

    local name = edit:GetName()
    if name then
        if _G[name .. "Left"] then _G[name .. "Left"]:Hide() end
        if _G[name .. "Right"] then _G[name .. "Right"]:Hide() end
        if _G[name .. "Middle"] then _G[name .. "Middle"]:Hide() end
    end

    edit:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })

    edit:SetBackdropColor(0.06, 0.06, 0.06, 1)
    edit:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    edit:HookScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(0, 0.5, 1, 1)
    end)

    edit:HookScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)

    -- Text Insets
    edit:SetTextInsets(4, 4, 0, 0)
end

function GUI.CreateBox(parent, sizeX, sizeY, colorR, colorG, colorB)
    local box = CreateFrame("Frame", nil, parent)
    box:SetSize(sizeX, sizeY)
    box:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 14,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    box:SetBackdropColor(0.06, 0.06, 0.06, 1)
    box:SetBackdropBorderColor(colorR or 0.3, colorG or 0.3, colorB or 0.3, 1)
    return box
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "RaidStationMainFrame", UIParent)
    GUI.MainFrame = frame

    -- Registrar en UISpecialFrames para que ESC cierre la ventana
    -- (igual que la mochila o WeakAuras — no interfiere con el menú del juego)
    tinsert(UISpecialFrames, "RaidStationMainFrame")

    frame:SetSize(400, 530)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()

    function GUI.SaveWindowPosition()
        if not GUI.MainFrame then return end

        local point, _, relativePoint, xOfs, yOfs = GUI.MainFrame:GetPoint()
        if not point then return end

        RaidStationDB.windowPoint = point
        RaidStationDB.windowRelativePoint = relativePoint or point
        RaidStationDB.windowX = xOfs or 0
        RaidStationDB.windowY = yOfs or 0
    end

    function GUI.RestoreWindowPosition()
        local point = RaidStationDB.windowPoint or "CENTER"
        local relativePoint = RaidStationDB.windowRelativePoint or point
        local xOfs = tonumber(RaidStationDB.windowX) or 0
        local yOfs = tonumber(RaidStationDB.windowY) or 0

        frame:ClearAllPoints()
        frame:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
    end

    function GUI.ApplyWindowLock(locked)
        locked = locked and true or false
        RaidStationDB.windowLocked = locked
        frame:SetMovable(not locked)
    end

    frame:SetScript("OnDragStart", function(self)
        if RaidStationDB.windowLocked then return end
        self:StartMoving()
        self.isMoving = true
    end)
    frame:SetScript("OnDragStop", function(self)
        if not self.isMoving then return end
        self:StopMovingOrSizing()
        self.isMoving = nil
        GUI.SaveWindowPosition()
    end)

    --Always set a basic backdrop to prevent "invisible frame" bugs
    --ElvUI will skin over this if it's active.
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 32,
        edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.04, 0.04, 0.06, 0.7) -- negro azulado oscuro
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local clearBtn -- pre-declare for GUI.ApplyBackground

    -- Textura de fondo custom (layer BORDER, encima del backdrop)
    local bgTexture = frame:CreateTexture(nil, "BORDER")
    bgTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    bgTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    bgTexture:SetTexture(nil)
    bgTexture:Hide()
    bgTexture:SetAlpha(RaidStationDB.bgAlpha or 0.85)
    frame.bgTexture = bgTexture

    local BG_TEXTURES = {
        [1] = "Interface\\AddOns\\RaidStation\\Textures\\fondo1.blp",
        [2] = "Interface\\AddOns\\RaidStation\\Textures\\fondo2.blp",
        -- [3] = "Interface\\AddOns\\RaidStation\\Textures\\fondo3.blp",
        -- [4] = "Interface\\AddOns\\RaidStation\\Textures\\fondo4.blp",
        -- [5] = "Interface\\AddOns\\RaidStation\\Textures\\fondo5.blp",
        -- [6] = "Interface\\AddOns\\RaidStation\\Textures\\fondo6.blp",
    }

    function GUI.ApplyBackground(choiceIndex)
        choiceIndex = choiceIndex or 0
        RaidStationDB.bgChoice = choiceIndex

        -- Recrear bgTexture si fue destruida por SetBackdrop previo
        if not frame.bgTexture or not frame.bgTexture:IsObjectType("Texture") then
            local tex = frame:CreateTexture(nil, "BORDER")
            tex:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
            tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
            frame.bgTexture = tex
        end

        local tex = frame.bgTexture

        if choiceIndex == 0 then
            tex:SetTexture(nil)
            tex:Hide()
            return
        end

        local path = BG_TEXTURES[choiceIndex]
        if not path then
            tex:SetTexture(nil)
            tex:Hide()
            return
        end

        tex:SetTexture(path)
        local alpha = tonumber(RaidStationDB.bgAlpha) or 1.0
        if alpha <= 0 or alpha > 1 then alpha = 1.0 end
        tex:SetAlpha(alpha)
        tex:Show()
    end

    local RS_BACKDROP_BORDER = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    }
    local RS_BACKDROP_NOBORDER = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", -- textura sÃ³lida = borde invisible
        tile = true,
        tileSize = 32,
        edgeSize = 1,                              -- edgeSize=1 mÃ­nimo
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    }

    function GUI.ApplyBorder(show)
        if show == nil then show = (RaidStationDB.showBorder ~= false) end
        RaidStationDB.showBorder = show

        if show then
            frame:SetBackdrop(RS_BACKDROP_BORDER)
            frame:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
            frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        else
            frame:SetBackdrop(RS_BACKDROP_NOBORDER)
            frame:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
            frame:SetBackdropBorderColor(0, 0, 0, 0)
        end

        -- SIEMPRE re-aplicar el fondo despuÃ©s de SetBackdrop
        GUI.ApplyBackground(RaidStationDB.bgChoice or 0)
    end

    -- Aplicar al cargar
    GUI.ApplyBorder(RaidStationDB.showBorder)
    GUI.RestoreWindowPosition()
    GUI.ApplyWindowLock(RaidStationDB.windowLocked)

    -- Freeze Button
    local freezeBtn = CreateFrame("Button", nil, frame)
    freezeBtn:SetSize(24, 24)
    freezeBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -12)
    freezeBtn:SetNormalTexture("interface\\addons\\RaidStation\\Textures\\candados.blp")
    GUI.SkinButton(freezeBtn)
    freezeBtn:SetScript("OnClick", function()
        ns.Controller.isFrozen = not ns.Controller.isFrozen
        if ns.Controller.isFrozen then
            freezeBtn:SetAlpha(1)
        else
            freezeBtn:SetAlpha(0.4)
        end
    end)
    freezeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Congelar lista", 1, 0.82, 0)
        GameTooltip:AddLine("Pausa la actualizacion automatica de la lista.", 1, 1, 1, true)
        GameTooltip:AddLine("Util cuando quieres leer un anuncio sin que desaparezca.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    freezeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    freezeBtn:SetAlpha(0.4)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -17)
    title:SetText("RAID STATION")

    -- Li­nea decorativa dorada bajo el t
    --local titleLine = frame:CreateTexture(nil, "ARTWORK")
    --titleLine:SetSize(91, 1)
    --titleLine:SetPoint("TOP", frame, "TOP", 0, -26)
    --titleLine:SetTexture(0.9, 0.7, 0.2, 0.4)

    -- Clear Button (Header)
    clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearBtn:SetSize(56, 22)
    clearBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -52, -75)
    clearBtn:SetText("Limpiar")
    clearBtn:SetScript("OnClick", function()
        if ns.Advertiser and ns.AdvertiserUI then
            ns.Advertiser:ResetPatterns()
            ns.AdvertiserUI:RefreshAllInputs()
        end
    end)
    GUI.SkinButton(clearBtn, true)
    GUI.ApplyCustomTexture(clearBtn, "Interface\\AddOns\\RaidStation\\Textures\\nbutton1.blp")
    clearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Limpiar formulario", 1, 0.82, 0)
        GameTooltip:AddLine("Resetea todos los campos del anunciador de banda.", 1, 1, 1, true)
        GameTooltip:AddLine("No detiene el spam si estÃ¡ activo.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Close Button (Header)
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(15, 15)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
    closeBtn:SetText("")
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    GUI.SkinButton(closeBtn, true)
    GUI.ApplyCustomTexture(closeBtn, "Interface\\AddOns\\RaidStation\\Textures\\exis2.blp")

    local signature = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    signature:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 38)
    signature:SetText("Marfin-")
    signature:SetTextColor(1, 0.82, 0) -- dorado elegante
    signature:SetAlpha(0.8)

    -- Search EditBox
    local search = CreateFrame("EditBox", "RaidStationSearch", frame, "InputBoxTemplate")
    search:SetSize(340, 22)
    search:SetPoint("TOP", frame, "TOP", 0, -42)
    search:SetAutoFocus(false)
    GUI.SkinEditBox(search)
    -- 1. Definimos la forma y las texturas (esto es lo que reemplaza a tu cÃ³digo anterior)
    search:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background", -- Fondo del Tooltip
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",     -- Borde redondeado del Tooltip
        tile     = true,
        tileSize = 16,
        edgeSize = 14, -- Ajusta este nÃºmero: mÃ¡s alto = borde mÃ¡s grueso
        insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- 2. Aplicamos los colores
    -- Si el borde se ve muy oscuro, cambia estos valores (0 a 1)
    search:SetBackdropColor(0.06, 0.06, 0.06, 1)      -- Color de fondo
    search:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.7) -- Color del borde

    local searchHint = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", 5, 0)
    searchHint:SetText("Buscar (ej: 'icc 25h')...")
    search:SetScript("OnEditFocusGained", function() searchHint:Hide() end)
    search:SetScript("OnEditFocusLost", function(self) if self:GetText() == "" then searchHint:Show() end end)
    search:SetScript("OnTextChanged", function(self)
        GUI.searchPattern = self:GetText()
        GUI.UpdateList()
    end)
    search:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    -- Botón X para limpiar el campo de búsqueda
    local searchClearBtn = CreateFrame("Button", nil, frame)
    searchClearBtn:SetSize(18, 18)
    searchClearBtn:SetPoint("RIGHT", search, "RIGHT", -2, 0)
    searchClearBtn:SetAlpha(0) -- empieza invisible (sin texto)

    local clearBtnTex = searchClearBtn:CreateTexture(nil, "OVERLAY")
    clearBtnTex:SetAllPoints()
    clearBtnTex:SetTexture("Interface\\Buttons\\UI-StopButton")
    clearBtnTex:SetVertexColor(0.8, 0.2, 0.2)
    searchClearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")

    searchClearBtn:SetScript("OnClick", function()
        search:SetText("")
        search:ClearFocus()
        searchHint:Show()
    end)
    searchClearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("|cffff4444Limpiar búsqueda|r", 1, 1, 1)
        GameTooltip:Show()
    end)
    searchClearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Mostrar/ocultar el botón X según haya texto o no
    hooksecurefunc(search, "SetText", function(self, text)
        if text and text ~= "" then
            searchClearBtn:SetAlpha(1)
        else
            searchClearBtn:SetAlpha(0)
        end
    end)


    -- Filter Row
    local filterTooltips = {
        ALL   = "Mostrar todas las raids disponibles.",
        ICC   = "Filtrar: Icecrown Citadel (ICC).",
        SR    = "Filtrar: Sartharion / Ruby Sanctum (SR).",
        TOC   = "Filtrar: Trial of the Crusader (TOC).",
        ARCHA = "Filtrar: Archavon / Vault of Archavon (ARCHA).",
    }
    local filters = { "ALL", "ICC", "SR", "TOC", "ARCHA" }
    GUI.filterButtons = {}
    for i, name in ipairs(filters) do
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetSize(60, 20)
        if i == 1 then
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -65)
        else
            btn:SetPoint("LEFT", GUI.filterButtons[i - 1], "RIGHT", 5, 0)
        end
        btn:SetText(name)
        btn:SetNormalFontObject("GameFontNormalSmall")
        btn:SetHighlightFontObject("GameFontHighlightSmall")
        btn:SetScript("OnClick", function()
            GUI.activeFilter = name
            GUI.UpdateList()
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(name, 1, 0.82, 0)
            local tip = filterTooltips[name]
            if tip then GameTooltip:AddLine(tip, 1, 1, 1, true) end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- Remover skin ElvUI para estos botones especÃ­ficos
        if btn.SetNormalTexture then btn:SetNormalTexture("") end
        if btn.SetPushedTexture then btn:SetPushedTexture("") end
        if btn.SetHighlightTexture then btn:SetHighlightTexture("") end

        -- Ocultar piezas del template UIPanelButtonTemplate
        local bname = btn:GetName()
        if bname then
            if _G[bname .. "Left"] then _G[bname .. "Left"]:Hide() end
            if _G[bname .. "Right"] then _G[bname .. "Right"]:Hide() end
            if _G[bname .. "Middle"] then _G[bname .. "Middle"]:Hide() end
        end

        -- Textura de fondo custom (BACKGROUND layer = debajo del texto)
        local bgTex = btn:CreateTexture(nil, "BACKGROUND")
        bgTex:SetAllPoints(btn)
        bgTex:SetTexture("Interface\\AddOns\\RaidStation\\Textures\\nbutton1.blp")
        bgTex:SetAlpha(0.85)

        -- Textura hover: misma textura, mÃ¡s brillante al pasar el mouse
        btn:HookScript("OnEnter", function(self)
            bgTex:SetAlpha(1.0)
            bgTex:SetVertexColor(0, 0.6, 1) -- tinte azul ElvUI al hover
        end)
        btn:HookScript("OnLeave", function(self)
            bgTex:SetAlpha(0.85)
            bgTex:SetVertexColor(1, 1, 1) -- color normal
        end)

        -- Limpiar el backdrop que SkinButton o el Template aplicaron (tapa la textura custom)
        btn:SetBackdrop(nil)

        GUI.filterButtons[i] = btn
    end

    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "RaidStationScroll", frame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 35, -105)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 42)

    -- Skin the scrollbar for ElvUI/BugSack look
    local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
    scrollBar:SetWidth(10)

    -- Lo movemos 5 pÃ­xeles a la izquierda de su posiciÃ³n original en el borde (lado derecho)
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -10, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -10, 16)

    if not IsElvUI then
        scrollBar:GetChildren():Hide()
        scrollBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        scrollBar:SetBackdropColor(0, 0, 0, 0.5)
    end
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() GUI.UpdateList() end)
        ns.Controller.SetInteracting(true)
    end)

    -- Sort header row (encima del scrollFrame)
    local sortHeader = CreateFrame("Frame", nil, frame)
    sortHeader:SetSize(335, 16)
    sortHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 34, -87)

    local sortHeaderBg = sortHeader:CreateTexture(nil, "BACKGROUND")
    sortHeaderBg:SetAllPoints()
    sortHeaderBg:SetTexture(0, 0, 0, 0.7)

    local sortHeaderLine = sortHeader:CreateTexture(nil, "OVERLAY")
    sortHeaderLine:SetHeight(1)
    sortHeaderLine:SetPoint("BOTTOMLEFT", 0, 0)
    sortHeaderLine:SetPoint("BOTTOMRIGHT", 0, 0)
    sortHeaderLine:SetTexture(0.9, 0.7, 0.2, 0.3)

    -- Columna labels (estÃ¡ticos, solo decorativos)
    local lblNombre = sortHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblNombre:SetPoint("LEFT", sortHeader, "LEFT", 15, 0)
    lblNombre:SetText("Nombre")
    lblNombre:SetTextColor(0.9, 0.7, 0.2, 1)

    local lblBanda = sortHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblBanda:SetPoint("LEFT", sortHeader, "LEFT", 120, 0)
    lblBanda:SetText("Banda")
    lblBanda:SetTextColor(0.9, 0.7, 0.2, 1)

    local lblRol = sortHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblRol:SetPoint("LEFT", sortHeader, "LEFT", 220, 0)
    lblRol:SetText("Rol+")
    lblRol:SetTextColor(0.9, 0.7, 0.2, 1)

    GUI.sortHeader = sortHeader

    -- Row Creation
    for i = 1, ROWS_LIMIT do
        local row = ns.Rows.CreateRow(frame, i)
        if i == 1 then
            row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
        else
            row:SetPoint("TOPLEFT", GUI.rows[i - 1], "BOTTOMLEFT", 0, 0)
        end
        GUI.rows[i] = row
    end

    frame:SetScript("OnHide", function()
        if frame.isMoving then
            frame:StopMovingOrSizing()
            frame.isMoving = nil
            GUI.SaveWindowPosition()
        end
        ns.Controller.SetInteracting(false)
    end)
    frame:SetScript("OnShow", function() GUI.UpdateList() end)

    frame.scrollFrame = scrollFrame

    -- View Selection Logic
    GUI.selectedTab = 1

    -- Tab Bar (BOTTOM)
    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetSize(325, 22)
    tabBar:SetPoint("BOTTOM", frame, "BOTTOM", -1, 8)

    local tabBarBg = tabBar:CreateTexture(nil, "BACKGROUND")
    tabBarBg:SetAllPoints()
    tabBarBg:SetTexture(0, 0, 0, 0.4)

    --local tabBarLine = tabBar:CreateTexture(nil, "ARTWORK")
    --tabBarLine:SetSize(340, 3)
    --tabBarLine:SetPoint("TOP", tabBar, "TOP", 0, 0)
    --tabBarLine:SetTexture(0.9, 0.7, 0.2, 0.3)

    local tabDefs = {
        { label = "Buscar",     id = 1 },
        { label = "Anunciador", id = 3 },
        { label = "Config",     id = 2 },
    }

    local tabTooltips = {
        [1] = "Buscar raids activas en el canal general.",
        [2] = "Ajustes del addon: TTL, canales, apariencia.",
        [3] = "Anunciador de banda: configura y envia spam de reclutamiento.",
    }
    local tabWidth = 105
    local tabs = {}

    for i, def in ipairs(tabDefs) do
        local tab = CreateFrame("Button", nil, tabBar)
        tab:SetSize(tabWidth, 22)
        tab:SetPoint("LEFT", tabBar, "LEFT", (i - 1) * tabWidth + 4, 0)

        local tabBg = tab:CreateTexture(nil, "BACKGROUND")
        tabBg:SetAllPoints()
        tabBg:SetTexture(0, 0, 0, 0)
        tab.bg = tabBg

        local tabLabel = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tabLabel:SetAllPoints()
        tabLabel:SetJustifyH("CENTER")
        tabLabel:SetText(def.label)
        tabLabel:SetTextColor(0.7, 0.7, 0.7)
        tab.label = tabLabel

        tab:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

        tab.SetActive = function(self, active)
            if active then
                self.label:SetTextColor(0.9, 0.7, 0.2)
                self.bg:SetTexture(0.4, 0.4, 0.4, 0.25)
            else
                self.label:SetTextColor(0.7, 0.7, 0.7)
                self.bg:SetTexture(0, 0, 0, 0)
            end
        end

        tab:SetScript("OnClick", function()
            GUI.SelectTab(def.id)
        end)
        tab:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(def.label, 1, 0.82, 0)
            local tip = tabTooltips[def.id]
            if tip then GameTooltip:AddLine(tip, 1, 1, 1, true) end
            GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", function() GameTooltip:Hide() end)

        tabs[def.id] = tab
    end

    GUI.tabs = tabs

    function GUI.SelectTab(id)
        GUI.selectedTab = id

        if GUI.tabs then
            for k, t in pairs(GUI.tabs) do
                t:SetActive(k == id)
            end
        end

        -- freezeBtn solo visible en tab Buscar (id=1)
        if freezeBtn then
            if id == 1 then
                freezeBtn:Show()
            else
                freezeBtn:Hide()
            end
        end

        -- Clear button visibility (only in Advertiser tab)
        if clearBtn then
            if id == 3 then clearBtn:Show() else clearBtn:Hide() end
        end

        -- Firma solo en Config
        if signature then
            if id == 2 then
                signature:Show()
            else
                signature:Hide()
            end
        end

        if id == 1 then
            search:Show()
            if search:GetText() == "" then searchHint:Show() else searchHint:Hide() end
            for _, btn in ipairs(GUI.filterButtons) do btn:Show() end
            if GUI.sortHeader then GUI.sortHeader:Show() end
        else
            search:Hide()
            searchHint:Hide()
            for _, btn in ipairs(GUI.filterButtons) do btn:Hide() end
            if GUI.sortHeader then GUI.sortHeader:Hide() end
        end

        -- Explicitly handle panel visibility
        if ns.Settings and ns.Settings.Panel then
            if id == 2 then ns.Settings.Panel:Show() else ns.Settings.Panel:Hide() end
        end

        if ns.AdvertiserUI and ns.AdvertiserUI.Panel then
            if id == 3 then ns.AdvertiserUI.Panel:Show() else ns.AdvertiserUI.Panel:Hide() end
        end

        GUI.RefreshView()
    end

    GUI.SelectTab(1)

    return frame
end

function GUI.TokenizedSearch(data, pattern)
    if not pattern or pattern == "" then return true end
    local cleanPattern = ns.Parser.Normalize(pattern)
    local searchTokens = ns.Parser.Tokenize(cleanPattern)

    -- We'll check against tokens and metadata for better accuracy
    local messageTokens = data.parsed.tokens
    local senderLower = strlower(data.sender)

    for _, sToken in ipairs(searchTokens) do
        local found = false

        -- Check if it matches raid metadata specifically (10, 25, h, n, etc.)
        local sLower = strlower(sToken)
        local isMetaToken = false

        if sLower == "10" or sLower == "25" then
            isMetaToken = true
            if tostring(data.match.size) == sLower then found = true end
        elseif sLower == "h" or sLower == "hc" or sLower == "heroic" then
            isMetaToken = true
            if data.match.mode == 2 then found = true end
        elseif sLower == "n" or sLower == "nm" or sLower == "normal" then
            isMetaToken = true
            if data.match.mode == 1 then found = true end
        elseif sLower == "10h" or sLower == "10hc" then
            isMetaToken = true
            if data.match.size == 10 and data.match.mode == 2 then found = true end
        elseif sLower == "25h" or sLower == "25hc" then
            isMetaToken = true
            if data.match.size == 25 and data.match.mode == 2 then found = true end
        elseif sLower == "10n" or sLower == "10nm" then
            isMetaToken = true
            if data.match.size == 10 and data.match.mode == 1 then found = true end
        elseif sLower == "25n" or sLower == "25nm" then
            isMetaToken = true
            if data.match.size == 25 and data.match.mode == 1 then found = true end
        end

        -- Fallback to literal search in message tokens or sender name
        -- ONLY if it's not a strict meta-token that already failed to match metadata
        if not found and not isMetaToken then
            if strfind(senderLower, sToken, 1, true) then
                found = true
            else
                for _, mToken in ipairs(messageTokens) do
                    if strfind(mToken, sToken, 1, true) then
                        found = true
                        break
                    end
                end
            end
        end

        if not found then return false end
    end
    return true
end

function GUI.UpdateList()
    if not GUI.MainFrame or not GUI.MainFrame:IsShown() then return end
    if GUI.selectedTab ~= 1 then return end

    local search = GUI.searchPattern
    local cat = GUI.activeFilter

    local source = (cat == "ALL") and ns.Controller.messages or {}
    if cat ~= "ALL" then
        local catLower = strlower(cat)
        if ns.Controller.buckets[catLower] then
            for sender, _ in pairs(ns.Controller.buckets[catLower]) do
                source[sender] = ns.Controller.messages[sender]
            end
        else
            source = ns.Controller.messages
        end
    end

    local available = {}
    local locked = {}

    for sender, data in pairs(source) do
        local isHidden = ns.Controller.hiddenLeaders[sender]
        local catMatch = (cat == "ALL") or (data.match.raidId == strlower(cat))

        if catMatch and not isHidden and GUI.TokenizedSearch(data, search) then
            local isLocked = ns.Stats.RaidLockInfo(data.match.raidId, data.match.difficultyId)
            if isLocked then
                tinsert(locked, data)
            else
                tinsert(available, data)
            end
        end
    end

    local sortFunc = function(a, b)
        if a.match.priority ~= b.match.priority then
            return a.match.priority > b.match.priority
        end
        return a.lastSeenTimestamp > b.lastSeenTimestamp
    end

    tsort(available, sortFunc)
    tsort(locked, sortFunc)

    -- Build Final List with Separator
    local finalResults = {}
    for _, v in ipairs(available) do tinsert(finalResults, v) end
    if #available > 0 and #locked > 0 then
        tinsert(finalResults, { isSeparator = true })
    end
    for _, v in ipairs(locked) do tinsert(finalResults, v) end

    local numResults = #finalResults
    FauxScrollFrame_Update(GUI.MainFrame.scrollFrame, numResults, ROWS_LIMIT, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(GUI.MainFrame.scrollFrame)

    for i = 1, ROWS_LIMIT do
        local row = GUI.rows[i]
        local idx = i + offset
        if idx <= numResults then
            local data = finalResults[idx]

            if data.isSeparator then
                row.sender = nil
                row.data = nil
                row.name:SetText("")
                row.raid:SetText("")
                row.diff:SetText("")
                row.gs:SetText("")
                row.roleTank:Hide()
                row.roleHeal:Hide()
                row.roleDPS:Hide()
                row.noteBtn:SetAlpha(0)
                row.whisperBtn:Hide()
                row.deleteBtn:Hide()
                row.sepText:Show()
                row.bg:SetTexture(1, 1, 1, 0.09)
                row:SetAlpha(1)
            else
                row.sender = data.sender
                row.data = data
                row.sepText:Hide()
                row.roleTank:Show()
                row.roleHeal:Show()
                row.roleDPS:Show()
                row.whisperBtn:Show()
                row.deleteBtn:Show()

                local isLocked, _, lockId = ns.Stats.RaidLockInfo(data.match.raidId, data.match.difficultyId)
                local lockIcon = "|TInterface\\PetBattles\\BattleKings:12:12:0:0|t "

                -- Class Coloring / Red for Locked
                local classColor = RAID_CLASS_COLORS[data.class] or { r = 1, g = 0.8, b = 0 }
                local hasNote = ns.NoteFrame.HasNote(data.sender)
                if isLocked then
                    row:SetAlpha(0.6)                  -- Option B: Opacity
                    row.bg:SetTexture(0.5, 0, 0, 0.15) -- Option A: Red Background
                    row.name:SetText(lockIcon .. "|cffff0000" .. data.sender .. "|r")
                    row.raid:SetText("|cffff0000" .. data.match.raidName .. "|r")
                    row.diff:SetText("|cffff0000(" .. data.match.size .. (data.match.mode == 2 and "H" or "N") .. ")|r")
                    row.gs:SetText("")
                else
                    row:SetAlpha(1)
                    row.name:SetText(data.sender .. (data.guild and " |cff4cff4c(" .. data.guild .. ")|r" or ""))
                    row.name:SetTextColor(classColor.r, classColor.g, classColor.b)
                    row.raid:SetText(data.match.raidName)
                    row.diff:SetText("(" .. data.match.size .. (data.match.mode == 2 and "H" or "N") .. ")")
                    row.gs:SetText(data.match.gs or "")

                    -- Selection
                    if GUI.selectedSender == data.sender then
                        row.bg:SetTexture(1, 1, 1, 0.15)
                    else
                        if i % 2 == 0 then
                            row.bg:SetTexture(0, 0, 0, 0.55) -- fila par: oscura
                        else
                            row.bg:SetTexture(1, 1, 1, 0.03) -- fila impar: levemente clara
                        end
                    end
                end

                -- Role Icons
                row.roleTank:SetAlpha(data.match.roles.tank and 1 or 0.1)
                row.roleHeal:SetAlpha(data.match.roles.healer and 1 or 0.1)
                row.roleDPS:SetAlpha(data.match.roles.dps and 1 or 0.1)
                
                if hasNote then
                    row.noteBtn:SetAlpha(1.0)
                else
                    row.noteBtn:SetAlpha(0.12)
                end
            end
            row:Show()
        else
            row:Hide()
        end
    end
end

function GUI.RefreshView()
    if not GUI.MainFrame then return end
    local tab = GUI.selectedTab
    if tab == 1 then
        GUI.MainFrame.scrollFrame:Show()
        GUI.UpdateList()
    else
        GUI.MainFrame.scrollFrame:Hide()
        for i = 1, ROWS_LIMIT do GUI.rows[i]:Hide() end
        -- Show Settings
    end
end

function GUI.Initialize()
    if GUI.MainFrame then return end
    CreateMainFrame()
end

ns.GUI = GUI

-- Slash Command
SLASH_RAIDSTATION1 = "/rs"
SLASH_RAIDSTATION2 = "/raidstation"
SlashCmdList["RAIDSTATION"] = function()
    if GUI.MainFrame:IsShown() then GUI.MainFrame:Hide() else GUI.MainFrame:Show() end
end
