--[[
    Medal Frontline — Capture de zones (serveur).
    Modes Warfare / Offensive / Escarmouche, panneau staff, compteur de
    joueurs actifs (AFK > 5 min exclus), sauvegarde des zones par map.
]]

MedalFrontline = MedalFrontline or {}
local cfg = MedalFrontline.Config or {}

util.AddNetworkString("MedalFrontline_Sync")
util.AddNetworkString("MedalFrontline_Staff")

-- =========================
-- Fallback AFK : si l'addon medal_barracks (MedalAFK) n'est pas présent,
-- Medal Frontline embarque son propre suivi d'activité.
-- =========================
if not MedalAFK_Tracker then
    MedalAFK_Tracker = true
    local activity = {}
    function MedalAFK_LastActivity(ply) return activity[ply] or 0 end
    function MedalAFK_Seconds(ply)
        if not IsValid(ply) then return 0 end
        if not activity[ply] then activity[ply] = CurTime(); return 0 end
        return CurTime() - activity[ply]
    end
    function MedalAFK_IsAFK(ply, seconds)
        return MedalAFK_Seconds(ply) >= (tonumber(seconds) or 180)
    end
    timer.Create("MedalAFK_Watch", 2, 0, function()
        for _, ply in ipairs(player.GetHumans()) do
            if IsValid(ply) then
                local pos, ang = ply:GetPos(), ply:EyeAngles()
                local last = ply.MedalAFK_Snapshot
                if not last or last.pos:DistToSqr(pos) > 4
                    or math.abs(math.AngleDifference(last.ang.y, ang.y)) > 0.5
                    or math.abs(math.AngleDifference(last.ang.p, ang.p)) > 0.5 then
                    activity[ply] = CurTime()
                end
                ply.MedalAFK_Snapshot = {pos = pos, ang = ang}
            end
        end
    end)
    hook.Add("KeyPress", "MedalAFK_KeyPress", function(ply) activity[ply] = CurTime() end)
    hook.Add("PlayerInitialSpawn", "MedalAFK_Join", function(ply) activity[ply] = CurTime() end)
    hook.Add("PlayerDisconnected", "MedalAFK_Leave", function(ply) activity[ply] = nil end)
end

-- =========================
-- État de la partie
-- =========================
MedalFrontline.Round = MedalFrontline.Round or {
    mode = tostring(cfg.DefaultMode or "warfare"),
    active = false,
    attacker = (cfg.Factions or {})[1] or "americans",
    zones = {},
    tickets = {},
    endTime = 0,
}
local round = MedalFrontline.Round

local FAC1 = (cfg.Factions or {})[1] or "americans"
local FAC2 = (cfg.Factions or {})[2] or "vietcong"

local function facName(fac)
    return (cfg.FactionNames or {})[fac] or string.upper(tostring(fac))
end

local function armyOf(ply)
    return ply:GetNWString("MedalBarracks_ArmyChoice", "")
end

local function isStaff(ply)
    if not IsValid(ply) then return false end
    if tostring(cfg.MinAccess or "admin") == "superadmin" then return ply:IsSuperAdmin() end
    return ply:IsAdmin() or ply:IsSuperAdmin()
end

-- =========================
-- Paramètres serveur (récompenses de capture, façon MG CTF) — modifiables in-game.
-- =========================
MedalFrontline.Settings = MedalFrontline.Settings or {captureXP = 50, captureMoney = 150}

local function saveSettings()
    file.CreateDir("medal_frontline")
    file.Write("medal_frontline/settings.json", util.TableToJSON(MedalFrontline.Settings, true))
end

do
    local raw = file.Read("medal_frontline/settings.json", "DATA")
    if raw then
        for k, v in pairs(util.JSONToTable(raw) or {}) do MedalFrontline.Settings[k] = v end
    end
end

-- Récompense les joueurs du camp qui vient de capturer un secteur.
local function rewardCapture(fac, zone)
    local xp = tonumber(MedalFrontline.Settings.captureXP) or 0
    local money = tonumber(MedalFrontline.Settings.captureMoney) or 0
    if xp <= 0 and money <= 0 then return end
    for _, ply in ipairs(player.GetHumans()) do
        if armyOf(ply) == fac and ply:Alive() and ply:GetPos():Distance(zone.pos) <= (zone.radius or 900) then
            if xp > 0 and MedalBarracks and MedalBarracks.AddGeneralXP then
                MedalBarracks.AddGeneralXP(ply, xp, "capture de " .. zone.name)
            end
            if money > 0 and ply.addMoney then -- DarkRP
                ply:addMoney(money)
                ply:ChatPrint("[Frontline] +" .. money .. "$ pour la capture de " .. zone.name .. " !")
            end
        end
    end
end

-- =========================
-- Zones : config -> data/medal_frontline/<map>.json
-- =========================
local function dataPath()
    return "medal_frontline/" .. game.GetMap() .. ".json"
end

local function saveZones()
    file.CreateDir("medal_frontline")
    local out = {}
    for _, z in ipairs(round.zones) do
        table.insert(out, {name = z.name, x = z.pos.x, y = z.pos.y, z = z.pos.z, radius = z.radius})
    end
    file.Write(dataPath(), util.TableToJSON(out, true))
end
MedalFrontline.SaveZones = saveZones

local function loadZones()
    round.zones = {}
    local raw = file.Read(dataPath(), "DATA")
    if raw then
        for _, z in ipairs(util.JSONToTable(raw) or {}) do
            table.insert(round.zones, {
                name = tostring(z.name or "POINT"),
                pos = Vector(tonumber(z.x) or 0, tonumber(z.y) or 0, tonumber(z.z) or 0),
                radius = tonumber(z.radius) or cfg.DefaultZoneRadius or 900,
                owner = "", progress = 0, locked = true, contested = false,
            })
        end
    end
    if #round.zones == 0 then
        for _, z in ipairs((cfg.Zones or {})[game.GetMap()] or {}) do
            table.insert(round.zones, {
                name = tostring(z.name or "POINT"),
                pos = z.pos or Vector(0, 0, 0),
                radius = tonumber(z.radius) or cfg.DefaultZoneRadius or 900,
                owner = "", progress = 0, locked = true, contested = false,
            })
        end
    end
end
hook.Add("Initialize", "MedalFrontline_LoadZones", loadZones)
loadZones()

-- =========================
-- Synchronisation client
-- =========================
local function syncAll(target)
    net.Start("MedalFrontline_Sync")
        net.WriteString(round.mode)
        net.WriteBool(round.active)
        net.WriteString(round.attacker)
        net.WriteFloat(round.endTime)
        net.WriteInt(math.Round(round.tickets[FAC1] or 0), 16)
        net.WriteInt(math.Round(round.tickets[FAC2] or 0), 16)
        net.WriteInt(math.Round(tonumber(MedalFrontline.Settings.captureXP) or 0), 16)
        net.WriteInt(math.Round(tonumber(MedalFrontline.Settings.captureMoney) or 0), 24)
        net.WriteUInt(#round.zones, 4)
        for _, z in ipairs(round.zones) do
            net.WriteString(z.name)
            net.WriteString(z.owner)
            net.WriteInt(math.Round(z.progress), 8)
            net.WriteBool(z.locked)
            net.WriteBool(z.contested)
            net.WriteVector(z.pos)
            net.WriteFloat(z.radius)
        end
    if target then net.Send(target) else net.Broadcast() end
end
MedalFrontline.Sync = syncAll
MedalFrontline.IsStaff = isStaff

hook.Add("PlayerInitialSpawn", "MedalFrontline_SyncJoin", function(ply)
    timer.Simple(6, function() if IsValid(ply) then syncAll(ply) end end)
end)

-- =========================
-- Mise en place des modes
-- =========================
local function announce(msg)
    for _, p in ipairs(player.GetHumans()) do
        p:ChatPrint("[Frontline] " .. msg)
    end
end

local function setupRound()
    round.tickets = {[FAC1] = 0, [FAC2] = 0}
    local n = #round.zones
    for i, z in ipairs(round.zones) do
        z.owner = ""
        z.progress = 0
        z.locked = true
        z.contested = false
        z.hidden = false
    end

    if round.mode == "warfare" then
        -- Chaque camp part avec 2 secteurs, le centre est neutre.
        local half = math.floor(n / 2)
        for i = 1, half do
            round.zones[i].owner = FAC1
            round.zones[i].progress = 100
        end
        for i = n - half + 1, n do
            round.zones[i].owner = FAC2
            round.zones[i].progress = -100
        end
        round.endTime = CurTime() + (tonumber((cfg.Modes.warfare or {}).time) or 1800)
    elseif round.mode == "offensive" then
        -- Tous les secteurs au défenseur, l'attaquant capture dans l'ordre.
        local defender = round.attacker == FAC1 and FAC2 or FAC1
        for _, z in ipairs(round.zones) do
            z.owner = defender
            z.progress = defender == FAC1 and 100 or -100
        end
        round.endTime = CurTime() + (tonumber((cfg.Modes.offensive or {}).time) or 900)
    else -- skirmish
        -- Un seul point : le secteur central. Les autres sont masqués.
        local mid = math.max(math.ceil(n / 2), 1)
        for i, z in ipairs(round.zones) do
            z.hidden = i ~= mid
        end
        round.endTime = CurTime() + (tonumber((cfg.Modes.skirmish or {}).time) or 1200)
    end
end

-- Secteurs capturables selon le mode.
local function refreshLocks()
    local n = #round.zones
    for _, z in ipairs(round.zones) do z.locked = true end

    if round.mode == "warfare" then
        local k = 0
        while k < n and round.zones[k + 1].owner == FAC1 do k = k + 1 end
        local m = n + 1
        while m > 1 and round.zones[m - 1].owner == FAC2 do m = m - 1 end
        if k + 1 <= n then round.zones[k + 1].locked = false end
        if m - 1 >= 1 then round.zones[m - 1].locked = false end
    elseif round.mode == "offensive" then
        local defender = round.attacker == FAC1 and FAC2 or FAC1
        if round.attacker == FAC1 then
            for i = 1, n do
                if round.zones[i].owner == defender then round.zones[i].locked = false break end
            end
        else
            for i = n, 1, -1 do
                if round.zones[i].owner == defender then round.zones[i].locked = false break end
            end
        end
    else
        for _, z in ipairs(round.zones) do
            if not z.hidden then z.locked = false end
        end
    end
end

local function endRound(winner, reason)
    round.active = false
    if winner and winner ~= "" then
        announce("VICTOIRE DES " .. facName(winner) .. " ! " .. (reason or ""))
    else
        announce("Fin de l'opération : égalité. " .. (reason or ""))
    end
    syncAll()
end

local function countOwned(fac)
    local c = 0
    for _, z in ipairs(round.zones) do
        if z.owner == fac then c = c + 1 end
    end
    return c
end

-- =========================
-- Tick de capture
-- =========================
local function captureTick()
    if not round.active then return end
    local n = #round.zones
    if n == 0 then return end

    -- Fin du temps.
    if CurTime() >= round.endTime then
        if round.mode == "warfare" then
            local c1, c2 = countOwned(FAC1), countOwned(FAC2)
            endRound(c1 > c2 and FAC1 or (c2 > c1 and FAC2 or nil), "Temps écoulé (" .. c1 .. " - " .. c2 .. " secteurs).")
        elseif round.mode == "offensive" then
            endRound(round.attacker == FAC1 and FAC2 or FAC1, "Les défenseurs ont tenu la ligne.")
        else
            local t1, t2 = round.tickets[FAC1] or 0, round.tickets[FAC2] or 0
            endRound(t1 > t2 and FAC1 or (t2 > t1 and FAC2 or nil), "Temps écoulé (" .. math.Round(t1) .. " - " .. math.Round(t2) .. " tickets).")
        end
        return
    end

    refreshLocks()
    local rate = tonumber(cfg.CaptureRate) or 3
    local decay = tonumber(cfg.DecayRate) or 2
    local maxDiff = tonumber(cfg.MaxCapPlayers) or 5

    for _, z in ipairs(round.zones) do
        if not z.locked and not z.hidden then
            local c1, c2 = 0, 0
            for _, ply in ipairs(player.GetHumans()) do
                if IsValid(ply) and ply:Alive() and not ply:GetNWBool("MedalBarracks_InMenu", false) then
                    local fac = armyOf(ply)
                    if (fac == FAC1 or fac == FAC2) and ply:GetPos():Distance(z.pos) <= z.radius then
                        if fac == FAC1 then c1 = c1 + 1 else c2 = c2 + 1 end
                    end
                end
            end
            z.contested = c1 > 0 and c2 > 0

            local diff = math.Clamp(c1 - c2, -maxDiff, maxDiff)
            if diff ~= 0 then
                z.progress = math.Clamp(z.progress + diff * rate, -100, 100)
            elseif c1 == 0 and c2 == 0 then
                -- Zone vide : la progression retourne doucement vers le propriétaire.
                local target = z.owner == FAC1 and 100 or (z.owner == FAC2 and -100 or 0)
                z.progress = math.Approach(z.progress, target, decay)
            end

            -- Bascule de propriétaire aux pôles.
            if z.progress >= 100 and z.owner ~= FAC1 then
                z.owner = FAC1
                announce(facName(FAC1) .. " ont capturé " .. z.name .. " !")
                rewardCapture(FAC1, z)
                if round.mode == "offensive" and round.attacker == FAC1 then
                    round.endTime = round.endTime + (tonumber((cfg.Modes.offensive or {}).timePerCap) or 240)
                end
            elseif z.progress <= -100 and z.owner ~= FAC2 then
                z.owner = FAC2
                announce(facName(FAC2) .. " ont capturé " .. z.name .. " !")
                rewardCapture(FAC2, z)
                if round.mode == "offensive" and round.attacker == FAC2 then
                    round.endTime = round.endTime + (tonumber((cfg.Modes.offensive or {}).timePerCap) or 240)
                end
            end

            -- Tickets d'escarmouche.
            if round.mode == "skirmish" and z.owner ~= "" and not z.contested then
                local tr = tonumber((cfg.Modes.skirmish or {}).ticketRate) or 1
                round.tickets[z.owner] = (round.tickets[z.owner] or 0) + tr * (tonumber(cfg.TickInterval) or 1)
            end
        end
    end

    -- Conditions de victoire.
    if round.mode == "warfare" then
        if countOwned(FAC1) == n then endRound(FAC1, "Tous les secteurs sont tombés.") return end
        if countOwned(FAC2) == n then endRound(FAC2, "Tous les secteurs sont tombés.") return end
    elseif round.mode == "offensive" then
        if countOwned(round.attacker) == n then endRound(round.attacker, "Offensive victorieuse !") return end
    else
        local target = tonumber((cfg.Modes.skirmish or {}).targetTickets) or 300
        for _, fac in ipairs({FAC1, FAC2}) do
            if (round.tickets[fac] or 0) >= target then endRound(fac, "Quota de tickets atteint.") return end
        end
    end
end

timer.Create("MedalFrontline_Tick", math.max(tonumber(cfg.TickInterval) or 1, 0.5), 0, captureTick)
timer.Create("MedalFrontline_SyncTimer", 2, 0, function() syncAll() end)

-- =========================
-- Compteur de joueurs ACTIFS (AFK > 5 min exclus)
-- =========================
timer.Create("MedalFrontline_ActiveCount", math.max(tonumber(cfg.ActiveCountInterval) or 5, 2), 0, function()
    local afkSeconds = tonumber(cfg.ActiveAFKSeconds) or 300
    local counts = {[FAC1] = 0, [FAC2] = 0}
    for _, ply in ipairs(player.GetHumans()) do
        local fac = armyOf(ply)
        if counts[fac] ~= nil and not (MedalAFK_IsAFK and MedalAFK_IsAFK(ply, afkSeconds)) then
            counts[fac] = counts[fac] + 1
        end
    end
    SetGlobalInt("MedalFrontline_Active_" .. FAC1, counts[FAC1])
    SetGlobalInt("MedalFrontline_Active_" .. FAC2, counts[FAC2])
end)

-- =========================
-- Actions staff
-- =========================
local staffRate = {}
local markerRate = {}
hook.Add("PlayerDisconnected", "MedalFrontline_RateCleanup", function(ply) staffRate[ply] = nil; markerRate[ply] = nil end)

net.Receive("MedalFrontline_Staff", function(_, ply)
    if not isStaff(ply) then ply:ChatPrint("[Frontline] Panneau réservé au staff."); return end
    if (staffRate[ply] or 0) > CurTime() then return end
    staffRate[ply] = CurTime() + 0.15
    local action = net.ReadString()
    local arg = net.ReadString()

    if action == "mode" then
        if not (cfg.Modes or {})[arg] then return end
        round.mode = arg
        round.active = false
        setupRound()
        announce("Mode réglé sur " .. ((cfg.Modes[arg] or {}).name or arg) .. " par le staff.")
    elseif action == "attacker" then
        if arg ~= FAC1 and arg ~= FAC2 then return end
        round.attacker = arg
        if round.mode == "offensive" then setupRound() end
        announce("Camp attaquant : " .. facName(arg) .. ".")
    elseif action == "start" then
        if #round.zones == 0 then ply:ChatPrint("[Frontline] Définis d'abord les secteurs (DÉFINIR ICI)."); return end
        setupRound()
        round.active = true
        announce("OPÉRATION LANCÉE — mode " .. ((cfg.Modes[round.mode] or {}).name or round.mode) .. " !")
    elseif action == "stop" then
        round.active = false
        announce("Opération arrêtée par le staff.")
    elseif action == "reset" then
        round.active = false
        setupRound()
        announce("Opération réinitialisée.")
    elseif action == "setzone" then
        local idx = math.Clamp(tonumber(arg) or 0, 1, 12)
        if idx == 0 then return end
        -- Crée les secteurs manquants jusqu'à l'index demandé.
        while #round.zones < idx do
            local i = #round.zones + 1
            table.insert(round.zones, {
                name = (cfg.ZoneNames or {})[i] or ("POINT " .. i),
                pos = ply:GetPos(),
                radius = tonumber(cfg.DefaultZoneRadius) or 900,
                owner = "", progress = 0, locked = true, contested = false,
            })
        end
        round.zones[idx].pos = ply:GetPos()
        saveZones()
        ply:ChatPrint("[Frontline] Secteur " .. round.zones[idx].name .. " défini à ta position (sauvegardé pour " .. game.GetMap() .. ").")
    elseif action == "removezone" then
        local idx = tonumber(arg) or 0
        if round.zones[idx] then
            table.remove(round.zones, idx)
            saveZones()
            ply:ChatPrint("[Frontline] Secteur supprimé.")
        end
    elseif action == "renameidx" then
        -- arg = "idx|nouveau nom"
        local idx, name = string.match(arg, "^(%d+)|(.+)$")
        idx = tonumber(idx)
        if idx and round.zones[idx] and name then
            round.zones[idx].name = string.upper(string.sub(string.Trim(name), 1, 28))
            saveZones()
        end
    elseif action == "radiusidx" then
        -- arg = "idx|rayon"
        local idx, radius = string.match(arg, "^(%d+)|(%d+)$")
        idx, radius = tonumber(idx), tonumber(radius)
        if idx and round.zones[idx] and radius then
            round.zones[idx].radius = math.Clamp(radius, 150, 4000)
            saveZones()
        end
    elseif action == "goto" then
        local idx = tonumber(arg)
        if idx and round.zones[idx] then
            ply:SetPos(round.zones[idx].pos + Vector(0, 0, 40))
            ply:ChatPrint("[Frontline] Téléporté au secteur " .. round.zones[idx].name .. ".")
        end
    elseif action == "rewards" then
        -- arg = "xp|argent"
        local xp, money = string.match(arg, "^(%d+)|(%d+)$")
        if xp and money then
            MedalFrontline.Settings.captureXP = math.Clamp(tonumber(xp) or 0, 0, 100000)
            MedalFrontline.Settings.captureMoney = math.Clamp(tonumber(money) or 0, 0, 10000000)
            saveSettings()
            ply:ChatPrint("[Frontline] Récompenses de capture sauvegardées.")
        end
    end
    syncAll()
end)

-- =========================
-- SWEP de création de zones (staff) : ajout/déplacement/suppression au regard.
-- =========================
util.AddNetworkString("MedalFrontline_ZoneTool")

net.Receive("MedalFrontline_ZoneTool", function(_, ply)
    if not isStaff(ply) then ply:ChatPrint("[Frontline] Outil réservé au staff."); return end
    if (staffRate[ply] or 0) > CurTime() then return end
    staffRate[ply] = CurTime() + 0.15
    local action = net.ReadString()

    if action == "add" then
        local pos = net.ReadVector()
        if #round.zones >= 12 then ply:ChatPrint("[Frontline] Maximum 12 secteurs."); return end
        local i = #round.zones + 1
        table.insert(round.zones, {
            name = (cfg.ZoneNames or {})[i] or ("POINT " .. i),
            pos = pos,
            radius = tonumber(cfg.DefaultZoneRadius) or 900,
            owner = "", progress = 0, locked = true, contested = false,
        })
        MedalFrontline.SaveZones()
        ply:ChatPrint("[Frontline] Secteur " .. round.zones[i].name .. " créé.")
    elseif action == "move" then
        local pos = net.ReadVector()
        -- Déplace le secteur le plus proche du point visé.
        local best, bestDist
        for idx, z in ipairs(round.zones) do
            local d = z.pos:DistToSqr(pos)
            if not bestDist or d < bestDist then best, bestDist = idx, d end
        end
        if best then
            round.zones[best].pos = pos
            MedalFrontline.SaveZones()
            ply:ChatPrint("[Frontline] Secteur " .. round.zones[best].name .. " déplacé.")
        end
    elseif action == "remove" then
        local pos = net.ReadVector()
        local best, bestDist
        for idx, z in ipairs(round.zones) do
            local d = z.pos:DistToSqr(pos)
            if not bestDist or d < bestDist then best, bestDist = idx, d end
        end
        if best and bestDist and bestDist <= (round.zones[best].radius * round.zones[best].radius) then
            local name = round.zones[best].name
            table.remove(round.zones, best)
            -- Renumérote les noms par défaut.
            for idx, z in ipairs(round.zones) do
                if string.match(z.name, "^POINT ") or string.find((cfg.ZoneNames or {})[idx] or "", z.name, 1, true) then
                    z.name = (cfg.ZoneNames or {})[idx] or ("POINT " .. idx)
                end
            end
            MedalFrontline.SaveZones()
            ply:ChatPrint("[Frontline] Secteur " .. name .. " supprimé.")
        end
    elseif action == "radius" then
        local pos = net.ReadVector()
        local delta = net.ReadInt(16)
        local best, bestDist
        for idx, z in ipairs(round.zones) do
            local d = z.pos:DistToSqr(pos)
            if not bestDist or d < bestDist then best, bestDist = idx, d end
        end
        if best then
            round.zones[best].radius = math.Clamp(round.zones[best].radius + delta, 150, 4000)
            MedalFrontline.SaveZones()
        end
    elseif action == "rename" then
        local pos = net.ReadVector()
        local newName = string.upper(string.sub(net.ReadString(), 1, 28))
        if newName ~= "" then
            local best, bestDist
            for idx, z in ipairs(round.zones) do
                local d = z.pos:DistToSqr(pos)
                if not bestDist or d < bestDist then best, bestDist = idx, d end
            end
            if best then
                round.zones[best].name = newName
                MedalFrontline.SaveZones()
                ply:ChatPrint("[Frontline] Secteur renommé : " .. newName)
            end
        end
    end
    syncAll()
end)

-- =========================
-- Carte tactique : marqueurs SL / Commandant.
-- Les marqueurs sont partagés par faction, envoyés uniquement aux joueurs
-- "commandement" de la même faction.
-- =========================
util.AddNetworkString("MedalFrontline_Markers")
util.AddNetworkString("MedalFrontline_MarkerAction")

MedalFrontline.Markers = MedalFrontline.Markers or {} -- [faction] = { {id, x,y,z, type, label, author} }

local function isLeader(ply)
    if not IsValid(ply) then return false end
    if ply:GetNWBool("MedalBarracks_SquadLeader", false) then return true end
    local role = ply:GetNWString("MedalBarracks_Role", "")
    for _, r in ipairs((cfg.Map or {}).LeaderRoleIDs or {}) do
        if tostring(r) == role then return true end
    end
    return ply:IsAdmin() -- le staff voit tout aussi
end
MedalFrontline.IsLeader = isLeader

local function sendMarkers(fac, target)
    local list = MedalFrontline.Markers[fac] or {}
    net.Start("MedalFrontline_Markers")
        net.WriteString(fac)
        net.WriteUInt(#list, 8)
        for _, m in ipairs(list) do
            net.WriteVector(m.pos)
            net.WriteString(m.type)
            net.WriteString(m.label)
            net.WriteString(m.author)
        end
    if target then net.Send(target) else
        for _, p in ipairs(player.GetHumans()) do
            if armyOf(p) == fac and isLeader(p) then net.Send(p) end
        end
    end
end
MedalFrontline.SendMarkers = sendMarkers

net.Receive("MedalFrontline_MarkerAction", function(_, ply)
    local mapCfg = cfg.Map or {}
    if (markerRate[ply] or 0) > CurTime() then return end
    markerRate[ply] = CurTime() + 0.2
    if not isLeader(ply) then ply:ChatPrint("[Carte] Réservé aux chefs d'escouade et au commandement."); return end
    local fac = armyOf(ply)
    if fac == "" then return end
    MedalFrontline.Markers[fac] = MedalFrontline.Markers[fac] or {}
    local list = MedalFrontline.Markers[fac]

    local action = net.ReadString()
    if action == "add" then
        local pos = net.ReadVector()
        local mtype = net.ReadString()
        local label = string.sub(net.ReadString(), 1, 40)
        if #list >= (tonumber(mapCfg.MaxMarkers) or 24) then table.remove(list, 1) end
        table.insert(list, {pos = pos, type = mtype, label = label, author = ply:Nick()})
    elseif action == "remove" then
        local pos = net.ReadVector()
        local best, bestDist
        for idx, m in ipairs(list) do
            local d = m.pos:DistToSqr(pos)
            if not bestDist or d < bestDist then best, bestDist = idx, d end
        end
        if best then table.remove(list, best) end
    elseif action == "clear" then
        MedalFrontline.Markers[fac] = {}
    end
    sendMarkers(fac)
end)

-- Un chef qui vient de prendre son rôle reçoit les marqueurs actuels.
hook.Add("PlayerInitialSpawn", "MedalFrontline_MarkersJoin", function(ply)
    timer.Simple(7, function()
        if IsValid(ply) and isLeader(ply) then sendMarkers(armyOf(ply), ply) end
    end)
end)

-- Renvoi périodique (le statut de leader peut changer après un choix de rôle).
timer.Create("MedalFrontline_MarkersRefresh", 8, 0, function()
    for _, ply in ipairs(player.GetHumans()) do
        if isLeader(ply) then sendMarkers(armyOf(ply), ply) end
    end
end)

-- =========================
-- Commande chat "!frontline" (alias "/frontline") : panneau staff.
-- =========================
local chatRate = {}
hook.Add("PlayerDisconnected", "MedalFrontline_ChatRateCleanup", function(ply) chatRate[ply] = nil end)

hook.Add("PlayerSay", "MedalFrontline_ChatCommands", function(ply, text)
    if not IsValid(ply) then return end
    local said = string.lower(string.Trim(tostring(text or "")))
    local prefix = string.sub(said, 1, 1)
    if prefix ~= "!" and prefix ~= "/" then return end
    if string.sub(said, 2) ~= "frontline" then return end

    if (chatRate[ply] or 0) > CurTime() then return "" end
    chatRate[ply] = CurTime() + 0.5
    if not isStaff(ply) then
        ply:ChatPrint("[Frontline] Commande réservée au staff.")
        return ""
    end
    ply:ConCommand(tostring(cfg.StaffCommand or "medal_frontline_staff"))
    return ""
end)
