--[[
    Medal Barracks — Radio de campagne / Radioman (serveur).

    Canaux :
    - /radio : réseau des radiomen. Tous les radiomen de la faction l'entendent TOUJOURS.
    - /sl    : canal COMMANDEMENT (commandant, officiers, chefs d'escouade).
               Un radioman ne l'entend que via une radio posée réglée sur la fréquence SL.
    Les joueurs à HearRadiusMeters autour d'une radio posée entendent ce qui
    passe sur la fréquence de cette radio.
]]

MedalBarracks = MedalBarracks or {}
local cfg = MedalBarracks.Config or {}

util.AddNetworkString("MedalRadio_Place")
util.AddNetworkString("MedalRadio_SetFreq")
util.AddNetworkString("MedalRadio_Remove")
util.AddNetworkString("MedalRadio_OpenMenu")
util.AddNetworkString("MedalRadio_ChatMsg")

local function radioCfg()
    return cfg.Radio or {}
end

local function relCfg()
    return cfg.Relations or {}
end

local function armyOf(ply)
    if MedalBarracks.GetPlayerCamp then return MedalBarracks.GetPlayerCamp(ply) or "" end
    return ply:GetNWString("MedalBarracks_ArmyChoice", "")
end

local function roleOf(ply)
    return ply:GetNWString("MedalBarracks_Role", "")
end

local function listHas(list, value)
    for _, v in ipairs(list or {}) do
        if tostring(v) == tostring(value) then return true end
    end
    return false
end

local function isRadioman(ply)
    return IsValid(ply) and listHas(radioCfg().RadiomanRoleIDs or {"radioman"}, roleOf(ply))
end

MedalBarracks.IsRadioman = isRadioman

-- Commandant / officier / chef d'escouade = accès au canal COMMANDEMENT.
local function isCommand(ply)
    if not IsValid(ply) then return false end
    local role = roleOf(ply)
    if listHas(relCfg().CommanderRoleIDs, role) or listHas(relCfg().OfficerRoleIDs, role) then return true end
    if MedalBarracks.IsSquadLeader and MedalBarracks.IsSquadLeader(ply) then return true end
    return false
end

MedalBarracks.IsCommandRole = isCommand

local function hearRadiusUnits()
    return (tonumber(radioCfg().HearRadiusMeters) or 10) * (tonumber(radioCfg().MetersToUnits) or 39.37)
end

local function deployedRadios(armyID, freqID)
    local out = {}
    for _, ent in ipairs(ents.FindByClass("medal_radio_ent")) do
        if IsValid(ent)
            and (not armyID or ent:GetNWString("MedalRadio_Army", "") == armyID)
            and (not freqID or ent:GetNWString("MedalRadio_Freq", "") == freqID) then
            table.insert(out, ent)
        end
    end
    return out
end

MedalBarracks.GetDeployedRadios = deployedRadios

local function ownedRadio(ply)
    local sid = ply:SteamID64()
    for _, ent in ipairs(ents.FindByClass("medal_radio_ent")) do
        if IsValid(ent) and ent:GetNWString("MedalRadio_Owner", "") == sid then return ent end
    end
end

MedalBarracks.GetOwnedRadio = ownedRadio

-- =========================
-- Pose de la radio (validée serveur, jauge côté client)
-- =========================
net.Receive("MedalRadio_Place", function(_, ply)
    local rc = radioCfg()
    if rc.Enabled == false then return end
    if not isRadioman(ply) then ply:ChatPrint("[Radio] Seul un radioman peut déployer une radio."); return end
    local wep = ply:GetWeapon("medal_radio_swep")
    if not IsValid(wep) then ply:ChatPrint("[Radio] Il te faut ta radio portative."); return end

    local pos = net.ReadVector()
    local ang = net.ReadAngle()

    local maxDist = (tonumber(rc.MaxDeployDistance) or 95) * 1.6
    if pos:Distance(ply:GetPos()) > maxDist then return end

    -- Vérifie que l'emplacement est dégagé.
    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 8),
        endpos = pos + Vector(0, 0, 8),
        mins = Vector(-10, -10, 0),
        maxs = Vector(10, 10, 14),
        filter = ply,
    })
    if tr.Hit or tr.StartSolid then ply:ChatPrint("[Radio] Emplacement invalide."); return end

    -- Une seule radio par radioman : l'ancienne est remballée automatiquement.
    local maxRadios = tonumber(rc.MaxRadiosPerPlayer) or 1
    if maxRadios >= 1 then
        local old = ownedRadio(ply)
        if IsValid(old) then old:Remove() end
    end

    local ent = ents.Create("medal_radio_ent")
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(Angle(0, ang.y, 0))
    ent:Spawn()
    ent:SetNWString("MedalRadio_Owner", ply:SteamID64())
    ent:SetNWString("MedalRadio_OwnerName", ply:Nick())
    ent:SetNWString("MedalRadio_Army", armyOf(ply))
    ent:SetNWString("MedalRadio_Freq", tostring(rc.DefaultFrequency or "radioman"))

    ply:ChatPrint("[Radio] Radio déployée. Utilise E dessus pour régler la fréquence.")
end)

net.Receive("MedalRadio_SetFreq", function(_, ply)
    local ent = net.ReadEntity()
    local freqID = net.ReadString()
    if not IsValid(ent) or ent:GetClass() ~= "medal_radio_ent" then return end
    if not isRadioman(ply) then ply:ChatPrint("[Radio] Seul un radioman sait régler cette radio."); return end
    if ent:GetNWString("MedalRadio_Army", "") ~= armyOf(ply) then ply:ChatPrint("[Radio] Ce poste n'est pas de ta faction."); return end
    if ent:GetPos():Distance(ply:GetPos()) > 140 then return end

    local valid = false
    local freqName = ""
    for _, f in ipairs(radioCfg().Frequencies or {}) do
        if tostring(f.id) == freqID then valid = true; freqName = tostring(f.name or f.id) .. " (" .. tostring(f.freq or "") .. ")" break end
    end
    if not valid then return end

    ent:SetNWString("MedalRadio_Freq", freqID)
    ply:ChatPrint("[Radio] Fréquence réglée sur " .. freqName .. ".")
end)

net.Receive("MedalRadio_Remove", function(_, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "medal_radio_ent" then return end
    if ent:GetNWString("MedalRadio_Owner", "") ~= ply:SteamID64() then ply:ChatPrint("[Radio] Ce n'est pas ta radio."); return end
    if ent:GetPos():Distance(ply:GetPos()) > 140 then return end
    ent:Remove()
    ply:ChatPrint("[Radio] Radio remballée.")
end)

-- =========================
-- Routage des messages radio
-- =========================
local function freqLabel(freqID)
    for _, f in ipairs(radioCfg().Frequencies or {}) do
        if tostring(f.id) == freqID then return tostring(f.freq or f.name or freqID) end
    end
    return freqID
end

local function sendRadioMsg(recipients, channel, sender, msg)
    local seen = {}
    for _, p in ipairs(recipients) do
        if IsValid(p) and not seen[p] then
            seen[p] = true
            local name = sender:Nick()
            if MedalBarracks.GetDisplayNameForViewer then
                name = MedalBarracks.GetDisplayNameForViewer(p, sender)
            end
            net.Start("MedalRadio_ChatMsg")
                net.WriteString(channel)
                net.WriteString(name)
                net.WriteString(msg)
            net.Send(p)
        end
    end
end

-- Joueurs de la faction à portée d'une radio posée réglée sur freqID.
local function listenersNearRadios(armyID, freqID)
    local out = {}
    local radius = hearRadiusUnits()
    for _, ent in ipairs(deployedRadios(armyID, freqID)) do
        for _, p in ipairs(player.GetHumans()) do
            if p:GetPos():Distance(ent:GetPos()) <= radius then table.insert(out, p) end
        end
    end
    return out
end

local function slRecipients(armyID)
    local out = {}
    for _, p in ipairs(player.GetHumans()) do
        if armyOf(p) == armyID and isCommand(p) then table.insert(out, p) end
    end
    -- Radiomen (et joueurs proches) via les radios posées réglées sur la fréquence SL.
    for _, p in ipairs(listenersNearRadios(armyID, "sl")) do table.insert(out, p) end
    return out
end

local function radiomanRecipients(armyID)
    local out = {}
    -- Les radiomen entendent TOUJOURS le réseau radio, radio posée ou non.
    for _, p in ipairs(player.GetHumans()) do
        if armyOf(p) == armyID and isRadioman(p) then table.insert(out, p) end
    end
    for _, p in ipairs(listenersNearRadios(armyID, "radioman")) do table.insert(out, p) end
    return out
end

hook.Add("PlayerSay", "MedalRadio_ChatChannels", function(ply, text)
    if radioCfg().Enabled == false then return end
    text = tostring(text or "")
    local lower = string.lower(text)

    local slCmd = string.lower(tostring((cfg.Squads and cfg.Squads.SLChatCommand) or "/sl"))
    local radioCmd = string.lower(tostring(radioCfg().RadioChatCommand or "/radio"))

    -- Canal COMMANDEMENT : /sl <message>
    if string.sub(lower, 1, #slCmd + 1) == slCmd .. " " then
        local msg = string.Trim(string.sub(text, #slCmd + 2))
        if msg == "" then return "" end
        local armyID = armyOf(ply)

        local allowed = isCommand(ply)
        if not allowed and isRadioman(ply) then
            -- Le radioman transmet au commandement uniquement via SA radio posée sur la fréquence SL.
            local radio = ownedRadio(ply)
            allowed = IsValid(radio) and radio:GetNWString("MedalRadio_Freq", "") == "sl"
            if not allowed then
                ply:ChatPrint("[Radio] Pose ta radio et règle-la sur la fréquence COMMANDEMENT pour transmettre aux SL.")
                return ""
            end
        end
        if not allowed then
            ply:ChatPrint("[Radio] Canal réservé au commandant, aux chefs d'escouade et aux radiomen équipés.")
            return ""
        end

        local recipients = slRecipients(armyID)
        table.insert(recipients, ply)
        sendRadioMsg(recipients, "COMMANDEMENT " .. freqLabel("sl"), ply, msg)
        return ""
    end

    -- Réseau radio : /radio <message>
    if string.sub(lower, 1, #radioCmd + 1) == radioCmd .. " " then
        local msg = string.Trim(string.sub(text, #radioCmd + 2))
        if msg == "" then return "" end
        if not isRadioman(ply) then
            ply:ChatPrint("[Radio] Seuls les radiomen émettent sur le réseau radio.")
            return ""
        end
        local armyID = armyOf(ply)

        -- Si sa radio posée est réglée sur la fréquence SL, la transmission part au commandement.
        local radio = ownedRadio(ply)
        if IsValid(radio) and radio:GetNWString("MedalRadio_Freq", "") == "sl" then
            local recipients = slRecipients(armyID)
            table.insert(recipients, ply)
            sendRadioMsg(recipients, "COMMANDEMENT " .. freqLabel("sl"), ply, msg)
            return ""
        end

        local recipients = radiomanRecipients(armyID)
        table.insert(recipients, ply)
        sendRadioMsg(recipients, "RÉSEAU RADIO " .. freqLabel("radioman"), ply, msg)
        return ""
    end
end)
