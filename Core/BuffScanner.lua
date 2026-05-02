-- RaidStation :: Core/BuffScanner.lua
-- Escaneo de buffs de banda con UnitBuff + GetSpellInfo (build 12340 sin spellId en UnitBuff).
-- Throttle 2s, eventos de raid y UNIT_AURA. Anuncios por ChatThrottleLib.
local addonName, ns = ...

local BuffData = ns.BuffData
local SCAN_INTERVAL = 2.0
local ANNOUNCE_COOLDOWN = 2.0
local CHAT_PREFIX = "RSBuff"

local BuffScanner = {
    eventFrame = nil,
    watching = false,
    dirty = true,
    lastFullScan = 0,
    lastAnnounceTime = {},   -- per-category throttle: { [key] = timestamp }
    cachedState = nil,
}

local tinsert = table.insert
local strformat = string.format
local floor = math.floor

local function sysMsg(msg)
    print("|cFF00FFFF[Buffs]|r : " .. tostring(msg))
end

local function strtrim(s)
    if not s then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function dbgPrint(msg)
    if RaidStationDB and RaidStationDB.debug then
        print("[Buffs] : " .. tostring(msg))
    end
end

local function sendChatLine(text, channelOverride)
    local ch = channelOverride or (RaidStationDB and RaidStationDB.buffTab_channel) or "RAID"
    text = tostring(text or "")
    text = text:gsub("|", "/")
    if ch == "SOLO" or ch == "" or ch == nil then
        print("[Buffs] : " .. text)
        return
    end
    local ok, err = pcall(function()
        SendChatMessage(text, ch)
    end)
    if not ok then
        print("[Buffs] : No se pudo enviar al canal " .. tostring(ch) .. ". " .. tostring(err))
    end
end

local function collectUnitAuras(unit)
    local byName = {}
    local i = 1
    while true do
        local name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff(unit, i)
        if not name then break end
        duration = duration or 0
        expirationTime = expirationTime or 0
        local prev = byName[name]
        if not prev or expirationTime > prev.expirationTime then
            byName[name] = {
                duration = duration,
                expirationTime = expirationTime,
            }
        end
        i = i + 1
    end
    return byName
end

local function auraMatchesDefinition(def, byName)
    for _, sid in ipairs(def.spellIDs) do
        local spellName = select(1, GetSpellInfo(sid))
        if spellName and spellName ~= "" and byName[spellName] then
            return true, sid, byName[spellName]
        end
    end
    return false, nil, nil
end

local function paladinAssignmentRows()
    local list = RaidStationDB and RaidStationDB.paladinAssignmentList
    if type(list) == "table" then
        return list
    end
    local flat = {}
    local t = RaidStationDB and RaidStationDB.paladinAssignments
    if type(t) == "table" then
        for pname, rows in pairs(t) do
            if type(rows) == "table" then
                for _, row in ipairs(rows) do
                    if type(row) == "table" and row.spellID then
                        tinsert(flat, {
                            paladin = pname,
                            spellID = row.spellID,
                            clases = row.clases or row.classes or { "ALL" },
                        })
                    end
                end
            end
        end
    end
    return flat
end

local function findAssignedPaladinName(classToken, def)
    if def.tipo ~= "paladin" or not def.paladinFamily then return nil end
    for _, row in ipairs(paladinAssignmentRows()) do
        if type(row) == "table" and row.spellID and strtrim(row.paladin or "") ~= "" then
            local fam = BuffData.SpellIdToPaladinFamily(row.spellID)
            if fam == def.paladinFamily then
                local cl = row.clases or row.classes or {}
                local ok = false
                for _, c in ipairs(cl) do
                    if c == "ALL" or c == classToken then
                        ok = true
                        break
                    end
                end
                if ok then
                    return row.paladin
                end
            end
        end
    end
    return nil
end

local function isEligible(def, classToken)
    if not def.neverFor then return true end
    for _, c in ipairs(def.neverFor) do
        if c == classToken then return false end
    end
    return true
end

local function evaluateBuffForPlayer(def, byName, classToken)
    if not isEligible(def, classToken) then
        return { skip = true, present = false, urgent = false }
    end
    local threshold = tonumber(RaidStationDB and RaidStationDB.buffTab_threshold) or 600
    local present, matchedSid, auraInfo = auraMatchesDefinition(def, byName)
    local assignedPaladin = findAssignedPaladinName(classToken, def)

    if not present then
        local resp
        if def.tipo == "paladin" and assignedPaladin then
            resp = strformat("Responsable: %s — FALTA", assignedPaladin)
        elseif def.tipo == "paladin" then
            resp = def.responsableLinea .. " — sin asignacion en Ajustes"
        else
            resp = def.responsableLinea
        end
        return {
            present = false,
            quality = nil,
            urgent = false,
            remaining = nil,
            expirationTime = nil,
            matchedSpellId = nil,
            assignedPaladin = assignedPaladin,
            responsableTooltip = resp,
        }
    end

    local quality = "minor"
    if type(def.superiorSpellID) == "table" then
        for _, id in ipairs(def.superiorSpellID) do
            if matchedSid == id then
                quality = "superior"
                break
            end
        end
    elseif matchedSid == def.superiorSpellID then
        quality = "superior"
    end
    local exp = auraInfo.expirationTime or 0
    local now = GetTime()
    local remaining = (exp > 0) and (exp - now) or nil
    local urgent = false
    if exp > 0 and remaining and remaining > 0 and remaining < threshold then
        urgent = true
    end

    -- Detectar si el buff (paladin) fue dado por alguien diferente al asignado
    local wrongCaster = false
    if def.tipo == "paladin" and assignedPaladin then
        local assignedInRaid = false
        for i = 1, GetNumRaidMembers() do
            local rname = GetRaidRosterInfo(i)
            if rname and rname == assignedPaladin then
                assignedInRaid = true
                break
            end
        end
        if not assignedInRaid then
            wrongCaster = true
        end
    end

    local resp
    if def.tipo == "paladin" and assignedPaladin then
        resp = strformat("Responsable: %s (Paladin)", assignedPaladin)
    else
        resp = def.responsableLinea
    end

    return {
        present = true,
        quality = quality,
        urgent = urgent,
        remaining = remaining,
        expirationTime = exp,
        matchedSpellId = matchedSid,
        assignedPaladin = assignedPaladin,
        responsableTooltip = resp,
        wrongCaster = wrongCaster,
    }
end

function BuffScanner.PerformFullScan()
    local state = {
        inRaid = false,
        groups = {},
        timestamp = GetTime(),
    }

    local nRaid = GetNumRaidMembers()
    if nRaid == 0 then
        state.inRaid = false
        BuffScanner.cachedState = state
        return state
    end

    state.inRaid = true

    for i = 1, math.min(nRaid, 25) do
        local name, rank, subgroup, level, localizedClass, fileName, zone, online, isDead = GetRaidRosterInfo(i)
        if not name or name == "" then
            -- vacio
        else
            local skip = false
            if online == false or online == 0 then skip = true end
            if isDead == true or isDead == 1 then skip = true end
            if (subgroup or 0) < 1 or (subgroup or 0) > 5 then skip = true end
            if not skip then
                local unit = "raid" .. i
                if UnitExists(unit) then
                    subgroup = subgroup or 1
                    if not state.groups[subgroup] then
                        state.groups[subgroup] = { players = {} }
                    end
                    local classToken = select(2, UnitClass(unit)) or fileName or "UNKNOWN"
                    local byName = collectUnitAuras(unit)
                    local playerEntry = {
                        name = name,
                        unit = unit,
                        classToken = classToken,
                        subgroup = subgroup,
                        buffs = {},
                    }
                    for _, def in ipairs(BuffData.DEFINITIONS) do
                        playerEntry.buffs[def.id] = evaluateBuffForPlayer(def, byName, classToken)
                    end
                    tinsert(state.groups[subgroup].players, playerEntry)
                end
            end
        end
    end

    BuffScanner.cachedState = state
    return state
end

function BuffScanner.RequestScan(force)
    BuffScanner.dirty = true
    if force then
        BuffScanner.lastFullScan = 0
    end
end

function BuffScanner.Tick()
    if not BuffScanner.watching then return end
    local now = GetTime()
    if BuffScanner.dirty or (now - BuffScanner.lastFullScan >= SCAN_INTERVAL) then
        BuffScanner.PerformFullScan()
        BuffScanner.lastFullScan = now
        BuffScanner.dirty = false
        if ns.BuffTab and ns.BuffTab.OnScannerUpdated then
            ns.BuffTab.OnScannerUpdated()
        end
    end
end

function BuffScanner.GetRaidBuffState()
    if not BuffScanner.cachedState then
        BuffScanner.PerformFullScan()
    end
    return BuffScanner.cachedState
end

function BuffScanner.AnnounceMissingForCategories(includeRaid, includePaladin, includeConsume)
    local now = GetTime()
    -- Per-category throttle key based on selected filters
    local throttleKey = (includeRaid and "R" or "") .. (includePaladin and "P" or "") .. (includeConsume and "C" or "")
    if now - (BuffScanner.lastAnnounceTime[throttleKey] or 0) < ANNOUNCE_COOLDOWN then
        sysMsg("Espera unos segundos antes de volver a anunciar faltantes.")
        return
    end
    -- Set throttle timestamp at the START, before sending
    BuffScanner.lastAnnounceTime[throttleKey] = now
    local state = BuffScanner.GetRaidBuffState()
    if not state.inRaid then
        sysMsg("No estas en una banda de raid.")
        return
    end

    -- Contar cuántos jugadores elegibles faltan cada buff
    local buffCount = {}   -- defId -> count
    local buffJerga = {}   -- defId -> jerga

    for _, def in ipairs(BuffData.DEFINITIONS) do
        local use = false
        if def.tipo == "raid" and includeRaid then use = true end
        if def.tipo == "paladin" and includePaladin then use = true end
        if def.tipo == "consumible" and includeConsume then use = true end
        if use then
            buffCount[def.id] = 0
            buffJerga[def.id] = def.jerga or def.nombre
        end
    end

    -- Build a map of defs by ID for quick lookup
    local defsById = {}
    for _, def in ipairs(BuffData.DEFINITIONS) do
        if buffCount[def.id] then
            defsById[def.id] = def
        end
    end

    for sg, gdata in pairs(state.groups) do
        for _, p in ipairs(gdata.players) do
            for defId, _ in pairs(buffCount) do
                local def = defsById[defId]
                -- Respetar neverFor: si el buff no aplica a esta clase, no contar como faltante
                if def and isEligible(def, p.classToken) then
                    local st = p.buffs[defId]
                    if st and not st.present then
                        buffCount[defId] = buffCount[defId] + 1
                    end
                end
            end
        end
    end

    -- Agrupar rezos de sacerdote si todos faltan
    local raidDefs = { "raid_fort", "raid_spirit", "raid_shadow" }
    local allRezosMissing = true
    for _, id in ipairs(raidDefs) do
        if buffCount[id] and buffCount[id] == 0 then
            allRezosMissing = false
        end
    end

    local parts = {}
    local skipIds = {}

    if allRezosMissing and includeRaid
        and buffCount["raid_fort"] and buffCount["raid_spirit"] and buffCount["raid_shadow"] then
        -- Tomar el mayor de los tres como representativo
        local maxCount = math.max(
            buffCount["raid_fort"] or 0,
            buffCount["raid_spirit"] or 0,
            buffCount["raid_shadow"] or 0
        )
        tinsert(parts, "Rezos:" .. maxCount)
        skipIds["raid_fort"] = true
        skipIds["raid_spirit"] = true
        skipIds["raid_shadow"] = true
    end

    -- Resto de buffs ordenados por defID para consistencia
    local orderedIds = {}
    for defId, count in pairs(buffCount) do
        if not skipIds[defId] and count > 0 then
            tinsert(orderedIds, defId)
        end
    end
    table.sort(orderedIds)

    for _, defId in ipairs(orderedIds) do
        tinsert(parts, buffJerga[defId] .. ":" .. buffCount[defId])
    end

    if #parts == 0 then
        sysMsg("No hay faltantes visibles con los filtros actuales.")
        return
    end

    local msg = "[Buffs] :Faltan " .. table.concat(parts, " · ")
    if msg:len() > 255 then
        msg = msg:sub(1, 252) .. "..."
    end
    sendChatLine(msg, nil)
end

local function describeAssignmentRow(palaName, rows)
    local chunks = {}
    local jergaMap = {
        ["Don de lo salvaje"] = "Patita",
        ["Luminosidad arcana"] = "Intelecto",
        ["Bendicion de reyes"] = "Reyes",
        ["Bendicion de salvaguardia"] = "Salva",
        ["Bendicion de sabiduria"] = "Sabiduria",
        ["Bendicion de poderio"] = "Poderio",
    }
    for _, row in ipairs(rows) do
        if type(row) == "table" and row.spellID then
            local defId = BuffData.SpellIdToDefinitionId(row.spellID)
            local def = defId and BuffData.GetDefinitionById(defId)
            local bname = def and def.nombre or ("ID " .. tostring(row.spellID))
            if jergaMap[bname] then bname = jergaMap[bname] end
            tinsert(chunks, bname)
        end
    end
    return "[" .. palaName .. ": " .. table.concat(chunks, ", ") .. "]"
end

function BuffScanner.AnnouncePaladinAssignments()
    local rows = paladinAssignmentRows()
    if #rows == 0 then
        sysMsg("No hay asignaciones de paladines guardadas.")
        return
    end
    local byPala = {}
    for _, row in ipairs(rows) do
        local pname = strtrim(row.paladin or "")
        if pname ~= "" then
            if not byPala[pname] then byPala[pname] = {} end
            tinsert(byPala[pname], row)
        end
    end
    local segments = {}
    local seen = {}
    for palaName, prows in pairs(byPala) do
        if #prows > 0 then
            local seg = describeAssignmentRow(palaName, prows)
            if not seen[seg] then
                seen[seg] = true
                tinsert(segments, seg)
            end
        end
    end
    if #segments == 0 then
        sysMsg("No hay filas de asignacion validas.")
        return
    end
    local joined = table.concat(segments, " ")
    if joined:len() <= 180 then
        sendChatLine("Buffs de Palas: " .. joined, nil)
        return
    end
    for _, seg in ipairs(segments) do
        sendChatLine("Buffs de Palas: " .. seg, nil)
    end
end

function BuffScanner.SendPredefinedAlert(slotIndex)
    local alerts = RaidStationDB and RaidStationDB.buffTab_alerts
    if type(alerts) ~= "table" then return end
    local slot = alerts[slotIndex]
    if type(slot) ~= "table" then return end
    local msg = slot.message or slot.msg or ""
    if msg == "" then
        sysMsg("Ese slot de alerta esta vacio. Configuralo en Ajustes.")
        return
    end
    local toRW = RaidStationDB and RaidStationDB.buffTab_alertToRaidWarning
    local toRaid = RaidStationDB and RaidStationDB.buffTab_alertToRaid
    if toRW then
        sendChatLine(msg, "RAID_WARNING")
    elseif toRaid then
        sendChatLine(msg, "RAID")
    else
        sysMsg("No hay canal seleccionado para alertas rapidas. Activa /rw o /raid en Ajustes.")
    end
end

function BuffScanner.Initialize()
    if BuffScanner.eventFrame then return end
    local f = CreateFrame("Frame", "RaidStationBuffScannerEventFrame", UIParent)
    BuffScanner.eventFrame = f
    f:SetSize(1, 1)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    f:Hide()
    f:SetScript("OnUpdate", function(self, elapsed)
        self._acc = (self._acc or 0) + elapsed
        if self._acc >= 0.25 then
            self._acc = 0
            BuffScanner.Tick()
        end
    end)
end

function BuffScanner.StartWatching()
    if BuffScanner.watching then return end
    BuffScanner.watching = true
    local f = BuffScanner.eventFrame
    if not f then BuffScanner.Initialize(); f = BuffScanner.eventFrame end
    f:RegisterEvent("RAID_ROSTER_UPDATE")
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self, event, unit)
        if event == "RAID_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            BuffScanner.dirty = true
        elseif event == "UNIT_AURA" then
            if unit and (unit == "player" or unit:match("^raid%d+") or unit:match("^party%d+")) then
                BuffScanner.dirty = true
            end
        end
    end)
    f:Show()
    BuffScanner.dirty = true
    dbgPrint("Monitoreo de buffs activo.")
    BuffScanner.Tick()
end

-- Export isEligible for use in other modules
BuffScanner.isEligible = isEligible

ns.BuffScanner = BuffScanner
