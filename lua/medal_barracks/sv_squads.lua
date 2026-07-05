--[[
    Medal Barracks — Escouades façon Hell Let Loose (serveur).
    Chaque faction possède ses escouades nommées (ABLE, BAKER, CHARLIE…).
    Le créateur devient chef d'escouade (SL). 6 membres maximum par défaut.
]]

MedalBarracks = MedalBarracks or {}
local cfg = MedalBarracks.Config or {}

util.AddNetworkString("MedalSquads_Action")
util.AddNetworkString("MedalSquads_Sync")
util.AddNetworkString("MedalSquads_Invite")

-- Structure : MedalBarracks.Squads[armyID][squadName] = {name, leader = sid64, members = {sid64 = true}}
MedalBarracks.Squads = MedalBarracks.Squads or {}

local function squadCfg()
    return cfg.Squads or {}
end

local function maxMembers()
    return tonumber(squadCfg().MaxMembers) or 6
end

local function notify(ply, ok, msg)
    if not IsValid(ply) then return end
    ply:ChatPrint(msg)
end

local function armyOf(ply)
    if MedalBarracks.GetPlayerCamp then return MedalBarracks.GetPlayerCamp(ply) or "" end
    return ply:GetNWString("MedalBarracks_ArmyChoice", "")
end

local function armySquads(armyID)
    MedalBarracks.Squads[armyID] = MedalBarracks.Squads[armyID] or {}
    return MedalBarracks.Squads[armyID]
end

local function findPlayerBySID(sid)
    for _, p in ipairs(player.GetHumans()) do
        if p:SteamID64() == sid then return p end
    end
end

local function playerSquad(ply)
    local armyID = armyOf(ply)
    if armyID == "" then return nil, armyID end
    local sid = ply:SteamID64()
    for _, squad in pairs(armySquads(armyID)) do
        if squad.members[sid] then return squad, armyID end
    end
    return nil, armyID
end

MedalBarracks.GetPlayerSquad = playerSquad

function MedalBarracks.IsSquadLeader(ply)
    if not IsValid(ply) then return false end
    local squad = playerSquad(ply)
    return squad ~= nil and squad.leader == ply:SteamID64()
end

local function applyNW(ply)
    if not IsValid(ply) then return end
    local squad, armyID = playerSquad(ply)
    local key = (cfg.Relations and cfg.Relations.SquadNWString) or "MedalBarracks_SquadID"
    if squad then
        ply:SetNWString(key, tostring(armyID) .. "/" .. tostring(squad.name))
        ply:SetNWString("MedalBarracks_SquadName", tostring(squad.name))
        ply:SetNWBool("MedalBarracks_SquadLeader", squad.leader == ply:SteamID64())
    else
        ply:SetNWString(key, "")
        ply:SetNWString("MedalBarracks_SquadName", "")
        ply:SetNWBool("MedalBarracks_SquadLeader", false)
    end
end

-- Purge les membres déconnectés ou qui ont changé de faction, supprime les escouades vides.
local function cleanArmy(armyID)
    local squads = armySquads(armyID)
    for name, squad in pairs(squads) do
        for sid in pairs(squad.members) do
            local p = findPlayerBySID(sid)
            if not IsValid(p) or armyOf(p) ~= armyID then squad.members[sid] = nil end
        end
        if not squad.members[squad.leader] then
            -- Le SL est parti : promotion du premier membre restant.
            local newLeader = next(squad.members)
            if newLeader then
                squad.leader = newLeader
                local p = findPlayerBySID(newLeader)
                if IsValid(p) then notify(p, true, "[Escouade] Tu es maintenant chef de l'escouade " .. name .. ".") end
            end
        end
        if next(squad.members) == nil then squads[name] = nil end
    end
end

local function syncArmy(armyID)
    if armyID == "" then return end
    cleanArmy(armyID)
    local squads = armySquads(armyID)

    local list = {}
    for name, squad in pairs(squads) do
        local members = {}
        for sid in pairs(squad.members) do
            local p = findPlayerBySID(sid)
            table.insert(members, {
                sid = sid,
                nick = IsValid(p) and p:Nick() or "Déconnecté",
                leader = sid == squad.leader,
                role = IsValid(p) and p:GetNWString("MedalBarracks_Role", "") or "",
            })
        end
        table.sort(members, function(a, b)
            if a.leader ~= b.leader then return a.leader end
            return a.nick < b.nick
        end)
        table.insert(list, {name = name, members = members})
    end
    table.sort(list, function(a, b) return a.name < b.name end)

    net.Start("MedalSquads_Sync")
        net.WriteString(armyID)
        net.WriteUInt(#list, 8)
        for _, squad in ipairs(list) do
            net.WriteString(squad.name)
            net.WriteUInt(#squad.members, 4)
            for _, m in ipairs(squad.members) do
                net.WriteString(m.sid)
                net.WriteString(m.nick)
                net.WriteBool(m.leader)
                net.WriteString(m.role)
            end
        end
    net.Broadcast()

    for _, p in ipairs(player.GetHumans()) do
        if armyOf(p) == armyID then applyNW(p) end
    end
end

MedalBarracks.SyncSquads = syncArmy

local function nextFreeName(armyID)
    local squads = armySquads(armyID)
    for _, name in ipairs(squadCfg().Names or {"ABLE", "BAKER", "CHARLIE"}) do
        if not squads[name] then return name end
    end
    return nil
end

local function leaveSquad(ply, silent)
    local squad, armyID = playerSquad(ply)
    if not squad then return false end
    squad.members[ply:SteamID64()] = nil
    applyNW(ply)
    if not silent then notify(ply, true, "[Escouade] Tu as quitté l'escouade " .. squad.name .. ".") end
    syncArmy(armyID)
    return true
end

local function joinSquad(ply, name)
    local armyID = armyOf(ply)
    if armyID == "" then notify(ply, false, "[Escouade] Choisis d'abord une faction."); return end
    local squad = armySquads(armyID)[name]
    if not squad then notify(ply, false, "[Escouade] Cette escouade n'existe plus."); return end
    if table.Count(squad.members) >= maxMembers() then notify(ply, false, "[Escouade] L'escouade " .. name .. " est complète."); return end
    leaveSquad(ply, true)
    squad.members[ply:SteamID64()] = true
    notify(ply, true, "[Escouade] Tu as rejoint l'escouade " .. name .. ".")
    syncArmy(armyID)
end

local function createSquad(ply)
    local armyID = armyOf(ply)
    if armyID == "" then notify(ply, false, "[Escouade] Choisis d'abord une faction."); return end
    local existing = playerSquad(ply)
    if existing and existing.leader == ply:SteamID64() then
        notify(ply, false, "[Escouade] Tu diriges déjà l'escouade " .. existing.name .. ".")
        return
    end
    local name = nextFreeName(armyID)
    if not name then notify(ply, false, "[Escouade] Plus de nom d'escouade disponible."); return end
    leaveSquad(ply, true)
    armySquads(armyID)[name] = {name = name, leader = ply:SteamID64(), members = {[ply:SteamID64()] = true}}
    notify(ply, true, "[Escouade] Escouade " .. name .. " créée. Tu es le chef d'escouade.")
    syncArmy(armyID)
end

local function kickMember(ply, sid)
    local squad, armyID = playerSquad(ply)
    if not squad or squad.leader ~= ply:SteamID64() then notify(ply, false, "[Escouade] Seul le chef d'escouade peut exclure."); return end
    if sid == ply:SteamID64() then return end
    if not squad.members[sid] then return end
    squad.members[sid] = nil
    local target = findPlayerBySID(sid)
    if IsValid(target) then
        applyNW(target)
        notify(target, false, "[Escouade] Tu as été exclu de l'escouade " .. squad.name .. ".")
    end
    syncArmy(armyID)
end

local function invitePlayer(ply, target)
    local squad = playerSquad(ply)
    if not squad or squad.leader ~= ply:SteamID64() then notify(ply, false, "[Escouade] Seul le chef d'escouade peut inviter."); return end
    if not IsValid(target) or target == ply then return end
    if armyOf(target) ~= armyOf(ply) then notify(ply, false, "[Escouade] Ce joueur n'est pas dans ta faction."); return end
    if table.Count(squad.members) >= maxMembers() then notify(ply, false, "[Escouade] Ton escouade est complète."); return end
    net.Start("MedalSquads_Invite")
        net.WriteString(squad.name)
        net.WriteString(ply:Nick())
    net.Send(target)
    notify(ply, true, "[Escouade] Invitation envoyée à " .. target:Nick() .. ".")
end

net.Receive("MedalSquads_Action", function(_, ply)
    if not MedalBarracks.NetRateOK(ply, "squads", 0.3) then return end
    if squadCfg().Enabled == false then return end
    local action = net.ReadString()
    local arg = net.ReadString()

    if action == "create" then
        createSquad(ply)
    elseif action == "join" then
        joinSquad(ply, arg)
    elseif action == "leave" then
        if not leaveSquad(ply) then notify(ply, false, "[Escouade] Tu n'es dans aucune escouade.") end
    elseif action == "kick" then
        kickMember(ply, arg)
    elseif action == "invite" then
        local target = Entity(tonumber(arg) or 0)
        if IsValid(target) and target:IsPlayer() then invitePlayer(ply, target) end
    elseif action == "request" then
        syncArmy(armyOf(ply))
    end
end)

hook.Add("PlayerDisconnected", "MedalSquads_Disconnect", function(ply)
    local squad, armyID = playerSquad(ply)
    if squad then
        squad.members[ply:SteamID64()] = nil
        timer.Simple(0, function() syncArmy(armyID) end)
    end
end)
