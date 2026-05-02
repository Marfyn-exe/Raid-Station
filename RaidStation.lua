-------------------------------------------------------------------------------
-- RaidStation
-- Raid browser and advertiser addon for WotLK 3.3.5a (Build 12340)
--
-- Original Author : Marfyn- (characters: Joana / WowAcademy)
-- Server          : UltimoWow (wotlk.ultimowow.com)
-- Created         : 2026
-- License         : MIT — redistribution requires author credit
--
-- If you received this addon without this header intact, it has been
-- modified without authorization. Original repository:
-- https://github.com/Marfyn-exe/RaidStation
-------------------------------------------------------------------------------

local addonName, ns = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize SavedVariables
        if not RaidStationDB then
            RaidStationDB = {}
        end
        if RaidStationDB.reactiveSync == nil then
            RaidStationDB.reactiveSync = true
        end
        if RaidStationDB.bgChoice == nil then
            RaidStationDB.bgChoice = 0   -- 0 = sin fondo (default), 1-6 = índice de fondo
        end
        if RaidStationDB.bgAlpha == nil then
            RaidStationDB.bgAlpha = 1.0   -- 100% por defecto
        end
        if RaidStationDB.showBorder == nil then
            RaidStationDB.showBorder = true  -- mostrar borde del frame principal
        end
        if RaidStationDB.playerNotes == nil then
            RaidStationDB.playerNotes = {}   -- notas manuales por jugador
        end
        -- Default settings merge
        for k, v in pairs(ns.Config.DEFAULTS) do
            if RaidStationDB[k] == nil then
                RaidStationDB[k] = v
            end
        end
        -- Sync config with DB
        for k, v in pairs(RaidStationDB) do
            ns.Config.DEFAULTS[k] = v
        end

        -- Migracion: asignaciones antiguas por nombre -> lista lineal
        if type(RaidStationDB.paladinAssignments) == "table" and next(RaidStationDB.paladinAssignments)
            and (not RaidStationDB.paladinAssignmentList or #RaidStationDB.paladinAssignmentList == 0) then
            RaidStationDB.paladinAssignmentList = {}
            for pname, rows in pairs(RaidStationDB.paladinAssignments) do
                if type(rows) == "table" then
                    for _, row in ipairs(rows) do
                        if type(row) == "table" and row.spellID then
                            table.insert(RaidStationDB.paladinAssignmentList, {
                                paladin = pname,
                                spellID = row.spellID,
                                clases = row.clases or row.classes or { "ALL" },
                            })
                        end
                    end
                end
            end
        end

        if type(RaidStationDB.buffTab_alerts) ~= "table" then
            RaidStationDB.buffTab_alerts = {}
        end
        for i = 1, 2 do
            if type(RaidStationDB.buffTab_alerts[i]) ~= "table" then
                RaidStationDB.buffTab_alerts[i] = { shortName = "", message = "", channel = "DEFAULT" }
            end
        end

        if RaidStationDB.buffTab_alertToRaidWarning == nil then
            RaidStationDB.buffTab_alertToRaidWarning = true
        end
        if RaidStationDB.buffTab_alertToRaid == nil then
            RaidStationDB.buffTab_alertToRaid = false
        end
        if RaidStationDB.buffTab_checkConsumables == nil then
            RaidStationDB.buffTab_checkConsumables = RaidStationDB.buffTab_checkConsume == true
        end
        if RaidStationDB.buffTab_checkConsume == nil then
            RaidStationDB.buffTab_checkConsume = RaidStationDB.buffTab_checkConsumables == true
        end
        
        ns.GUI.Initialize()
        ns.BuffScanner.Initialize()
        ns.Settings.Initialize()
        ns.BuffTab.Initialize()
        ns.AdvertiserUI.Initialize()
        ns.Minimap.Initialize()
        
    elseif event == "PLAYER_LOGIN" then
        -- Obtener referencia a LibWho-2.0 para queries asíncronas de jugadores
        local ok, lib = pcall(function() return LibStub:GetLibrary("LibWho-2.0") end)
        if ok and lib then
            ns.WhoLib = lib
        else
            ns.WhoLib = nil
            print("|cff00ffffRaid Station|r: LibWho-2.0 no disponible. El lookup de guild/raza no funcionará.")
        end

        ns.Stats.RequestRaidLockouts()

        if ns.BuffData and ns.BuffData.BuildIconCache then
            ns.BuffData.BuildIconCache()
        end

        if ns.BuffScanner and ns.BuffScanner.StartWatching then
            ns.BuffScanner.StartWatching()
        end
        
        -- Register Chat Events
        local chatFrame = CreateFrame("Frame")
        chatFrame:RegisterEvent("CHAT_MSG_CHANNEL")
        chatFrame:RegisterEvent("CHAT_MSG_YELL")
        chatFrame:SetScript("OnEvent", function(_, _, message, sender, ...)
            -- In 3.3.5a, guid is the 12th argument for CHAT_MSG_CHANNEL
            -- arg1=message, arg2=sender, arg3=... index 1. So arg12 is index 10.
            local guid = select(10, ...) 
            ns.Controller.AddMessage(sender, message, guid)
        end)
        
        print("|cff00ffffRaid Station|r cargado! Escribe |cffffff00/rs|r para abrir.")
    end
end)
