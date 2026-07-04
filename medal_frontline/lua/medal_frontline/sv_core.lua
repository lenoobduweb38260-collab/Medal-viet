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
                if round.mode == "offensive" and round.attacker == FAC1 then
                    round.endTime = round.endTime + (tonumber((cfg.Modes.offensive or {}).timePerCap) or 240)
                end
            elseif z.progress <= -100 and z.owner ~= FAC2 then
                z.owner = FAC2
                announce(facName(FAC2) .. " ont capturé " .. z.name .. " !")
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
net.Receive("MedalFrontline_Staff", function(_, ply)
    if not isStaff(ply) then ply:ChatPrint("[Frontline] Panneau réservé au staff."); return end
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
    end
    syncAll()
end)
