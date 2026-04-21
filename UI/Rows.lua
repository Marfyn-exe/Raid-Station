local addonName, ns = ...
local Rows = {}

local ROW_HEIGHT = 18

-- Cache de datos de jugadores obtenidos via LibWho (por sesión)
Rows.playerCache = {}
-- El sender del row que tiene el mouse encima actualmente
Rows.currentHoverSender = nil

local RAID_CLASS_COLORS = _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS

-- Construye y muestra el tooltip para una fila. whoInfo puede ser nil (primera vez)
-- o una tabla con datos de LibWho (una vez que llegó el callback).
function Rows.BuildTooltip(self, whoInfo)
    if not self.data then return end
    local data = self.data
    local match = data.match

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    local classColor = RAID_CLASS_COLORS[data.class] or {r=1, g=0.8, b=0}

    -- Header: Race Class <Guild>  (combina datos del anuncio + LibWho si disponible)
    local race    = (whoInfo and whoInfo.Race)  or data.race    or ""
    local locCls  = (whoInfo and whoInfo.Class) or data.locClass or ""
    local guildText = ""
    if whoInfo then
        -- LibWho result
        if whoInfo.Guild and whoInfo.Guild ~= "" then
            guildText = "|cff00ff00<" .. whoInfo.Guild .. ">|r"
        end
    elseif data.guild and data.guild ~= "" then
        guildText = "|cff00ff00<" .. data.guild .. ">|r"
    end

    local header = ""
    if race ~= "" then header = header .. race .. " " end
    if locCls ~= "" then header = header .. locCls .. " " end
    header = header .. guildText

    -- Si aún no tenemos datos de LibWho, indicamos que se está buscando
    if not whoInfo and not Rows.playerCache[data.sender] then
        if header ~= "" then header = header .. " " end
        header = header .. "|cff888888(buscando...)|r"
    end

    GameTooltip:AddDoubleLine(data.sender, header, classColor.r, classColor.g, classColor.b, 1, 1, 1)
    GameTooltip:AddLine(" ")

    GameTooltip:AddLine(data.message, 1, 1, 1, true)

    if data.match.gs and data.match.gs ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("GearScore:", "|cff00ff00" .. data.match.gs .. "|r")
    end

    if match then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Banda:",      "|cff00ffff" .. match.raidName .. "|r")
        GameTooltip:AddDoubleLine("Tamaño:",     match.size)
        GameTooltip:AddDoubleLine("Dificultad:", (match.mode == 2) and "Heroica" or "Normal")

        local isLocked, reset, lockId = ns.Stats.RaidLockInfo(match.raidId, match.difficultyId)
        if isLocked then
            GameTooltip:AddLine("\n|cffff0000GUARDADO|r ID: |cffffff00" .. (lockId or "???") .. "|r")
            GameTooltip:AddLine("Expira: " .. (reset and SecondsToTime(reset) or "desconocido"))
        else
            GameTooltip:AddLine("\n|cff00ff00DISPONIBLE|r (No guardado)")
        end
    end

    -- Nota del jugador (si existe)
    local note = RaidStationDB.playerNotes and RaidStationDB.playerNotes[data.sender]
    if note and note ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|TInterface\\ICONS\\INV_Misc_Note_02:14:14:0:0|t |cffffd700Nota:|r |cffdddddd" .. note .. "|r", 1, 1, 1, true)
    end

    GameTooltip:Show()
end

function Rows.OnRowEnter(self)
    if not self.data then return end
    local data = self.data
    local sender = data.sender

    Rows.currentHoverSender = sender

    -- Si ya tenemos datos en cache, úsalos directamente
    local cached = Rows.playerCache[sender]
    Rows.BuildTooltip(self, cached)

    -- Si no tenemos cache Y tenemos LibWho disponible, lanzar query asíncrona
    if not cached then
        local WhoLib = ns.WhoLib
        if WhoLib then
            WhoLib:UserInfo(sender, {
                queue   = WhoLib.WHOLIB_QUEUE_QUIET,
                timeout = 0,
                callback = function(result)
                    -- Guardar en cache (incluso si offline, para no repetir)
                    Rows.playerCache[sender] = result or false

                    -- Si el mouse sigue sobre este sender, refrescar tooltip
                    if Rows.currentHoverSender == sender and GameTooltip:IsShown() then
                        -- Necesitamos la referencia al frame. La buscamos por sender.
                        if result and result.Online then
                            Rows.BuildTooltip(self, result)
                        end
                    end
                end,
            })
        end
    end
end

function Rows.OnRowClick(self)
    ns.GUI.selectedSender = self.sender
    ns.GUI.UpdateList()
end

function Rows.OnRowDoubleClick(self)
    if not self.sender then return end
    -- Open chat but don't send any message
    ChatFrame_OpenChat("/w " .. self.sender .. " ")
end

function Rows.CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(335, ROW_HEIGHT)
    
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(0, 0, 0, 0.4)

    -- Hover overlay (HIGHLIGHT layer, separado del bg)
    row.hoverBg = row:CreateTexture(nil, "HIGHLIGHT")
    row.hoverBg:SetAllPoints()
    row.hoverBg:SetTexture(0, 0.47, 0.78, 0.15)  -- azul ElvUI suave
    row.hoverBg:Hide()
    
    -- Scaled Horizontal Layout
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", 8, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWidth(100)

    -- Separador vertical de columna
    row.colSep = row:CreateTexture(nil, "BORDER")
    row.colSep:SetSize(1, 10)
    row.colSep:SetPoint("LEFT", row.name, "RIGHT", 2, 0)
    row.colSep:SetTexture(0.9, 0.7, 0.2, 0.4)
    
    row.raid = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.raid:SetPoint("LEFT", row.name, "RIGHT", 5, 0)
    row.raid:SetJustifyH("LEFT")
    row.raid:SetWidth(52)
    row.raid:SetTextColor(0.6, 0.6, 0.6)
    
    row.diff = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.diff:SetPoint("LEFT", row.raid, "RIGHT", 5, 0)
    row.diff:SetJustifyH("LEFT")
    row.diff:SetWidth(40)
    row.diff:SetTextColor(0.6, 0.6, 0.6)
    
    row.gs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.gs:SetPoint("RIGHT", -55, 0)
    row.gs:SetTextColor(0, 1, 0)
    
    -- Role Icons (Smaller and Ultra-Compact)
    row.roleTank = row:CreateTexture(nil, "OVERLAY")
    row.roleTank:SetSize(14, 14)
    row.roleTank:SetTexture("Interface\\ICONS\\Spell_Holy_DevotionAura")
    row.roleTank:SetPoint("RIGHT", -40, 0)
    row.roleTank:Hide()
    
    -- Icono de nota: siempre visible, dimmed sin nota, brillante con nota
    local noteBtn = CreateFrame("Button", nil, row)
    noteBtn:SetSize(14, 14)
    noteBtn:SetPoint("RIGHT", row.roleTank, "RIGHT", 18, 0)
    local noteTex = noteBtn:CreateTexture(nil, "OVERLAY")
    noteTex:SetAllPoints()
    noteTex:SetTexture("Interface\\ICONS\\INV_Misc_Note_02")
    noteTex:SetVertexColor(1, 1, 1)
    noteBtn.tex = noteTex
    noteBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Nota del jugador", 1, 0.82, 0)
        GameTooltip:AddLine("Click derecho sobre el nombre", 1, 1, 1, true)
        GameTooltip:AddLine("para agregar/editar una nota.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    noteBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    noteBtn:SetScript("OnClick", function(self)
        if row.sender then
            ns.NoteFrame.Open(row.sender, row)
        end
    end)
    noteBtn:SetAlpha(0.12)  -- dimmed por defecto (sin nota)
    row.noteBtn = noteBtn
    
    row.roleHeal = row:CreateTexture(nil, "OVERLAY")
    row.roleHeal:SetSize(14, 14)
    row.roleHeal:SetTexture("Interface\\ICONS\\Spell_Holy_Heal02")
    row.roleHeal:SetPoint("RIGHT", row.roleTank, "LEFT", -2, 0)
    row.roleHeal:Hide()
    
    row.roleDPS = row:CreateTexture(nil, "OVERLAY")
    row.roleDPS:SetSize(14, 14)
    row.roleDPS:SetTexture("Interface\\ICONS\\Ability_DualWield")
    row.roleDPS:SetPoint("RIGHT", row.roleHeal, "LEFT", -2, 0)
    row.roleDPS:Hide()

    -- Separator Text (Centered)
    row.sepText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.sepText:SetPoint("CENTER", 0, 0)
    row.sepText:SetText("--Saved Raids--")
    row.sepText:SetTextColor(1, 0.3, 0.3)
    row.sepText:Hide()

    -- Delete/Hide Button (Compact)
    local delete = CreateFrame("Button", nil, row)
    delete:SetSize(16, 16)
    delete:SetPoint("RIGHT", row.roleDPS, "LEFT", 1, 0)
    delete:Hide()
    delete:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    delete:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    delete:SetScript("OnClick", function()
        if row.sender then
            ns.Controller.HideLeader(row.sender)
        end
    end)
    delete:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Ocultar anuncio", 1, 0, 0)
        GameTooltip:AddLine("Elimina a este lider de la lista actual.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    delete:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ns.GUI.SkinButton(delete)
    row.deleteBtn = delete

    -- Whisper Button (Discreet)
    local whisper = CreateFrame("Button", nil, row)
    whisper:SetSize(16, 16)
    whisper:SetPoint("RIGHT", delete, "LEFT", 1, 0)
    whisper:Hide()
    whisper:SetNormalTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    whisper:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    whisper:SetScript("OnClick", function()
        Rows.OnRowDoubleClick(row)
    end)
    ns.GUI.SkinButton(whisper)
    row.whisperBtn = whisper

    row:SetScript("OnEnter", function(self)
        self.hoverBg:Show()
        Rows.OnRowEnter(self)
    end)
    row:SetScript("OnLeave", function(self)
        self.hoverBg:Hide()
        GameTooltip:Hide()
    end)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if self.sender then
                ns.NoteFrame.Open(self.sender, self)
            end
        else
            Rows.OnRowClick(self)
        end
    end)
    row:SetScript("OnDoubleClick", Rows.OnRowDoubleClick)
    
    -- Minimalist thin border
    row.border = row:CreateTexture(nil, "OVERLAY")
    row.border:SetHeight(1)
    row.border:SetPoint("BOTTOMLEFT", 0, 0)
    row.border:SetPoint("BOTTOMRIGHT", 0, 0)
    row.border:SetTexture(1, 1, 1, 0.05)

    row:Hide()
    return row
end

ns.Rows = Rows
