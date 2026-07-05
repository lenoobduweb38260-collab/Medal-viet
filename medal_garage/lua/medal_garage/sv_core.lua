--[[
    Medal Garage — serveur.
    Spawn de véhicules par niveau, essence, points de garage par map.
]]

MedalGarage = MedalGarage or {}
local cfg = MedalGarage.Config or {}

util.AddNetworkString("MedalGarage_Open")
util.AddNetworkString("MedalGarage_Spawn")
util.AddNetworkString("MedalGarage_Points")
util.AddNetworkString("MedalGarage_PointAction")
util.AddNetworkString("MedalGarage_Refuel")
util.AddNetworkString("MedalGarage_OpenFromNPC")

MedalGarage.Points = MedalGarage.Points or {}
MedalGarage.PlayerVehicles = MedalGarage.PlayerVehicles or {}
MedalGarage.LastSpawn = MedalGarage.LastSpawn or {}

local function isStaff(ply)
    return IsValid(ply) and (ply:IsAdmin() or ply:IsSuperAdmin())
end

local function roleOf(ply)
    return ply:GetNWString("MedalBarracks_Role", "")
end

local function hasRole(ply, list)
    if not istable(list) or #list == 0 then return true end
    local r = roleOf(ply)
    for _, v in ipairs(list) do if tostring(v) == r then return true end end
    return false
end

local function canOpenGarage(ply)
    return hasRole(ply, cfg.AllowedRoleIDs)
end

-- =========================
-- Points de garage (data/medal_garage/<map>.json)
-- =========================
local function pointsPath()
    return "medal_garage/" .. game.GetMap() .. ".json"
end

local function savePoints()
    file.CreateDir("medal_garage")
    local out = {}
    for _, p in ipairs(MedalGarage.Points) do
        table.insert(out, {x = p.x, y = p.y, z = p.z})
    end
    file.Write(pointsPath(), util.TableToJSON(out, true))
end

-- Matérialise une plateforme physique à chaque point de garage.
local function spawnPlatforms()
    for _, e in ipairs(ents.FindByClass("medal_garage_platform")) do if IsValid(e) then e:Remove() end end
    for _, p in ipairs(MedalGarage.Points) do
        local plat = ents.Create("medal_garage_platform")
        if IsValid(plat) then
            plat:SetPos(p)
            plat:Spawn()
        end
    end
end
MedalGarage.SpawnPlatforms = spawnPlatforms

local function loadPoints()
    MedalGarage.Points = {}
    local raw = file.Read(pointsPath(), "DATA")
    if raw then
        for _, p in ipairs(util.JSONToTable(raw) or {}) do
            table.insert(MedalGarage.Points, Vector(tonumber(p.x) or 0, tonumber(p.y) or 0, tonumber(p.z) or 0))
        end
    end
    spawnPlatforms()
end
hook.Add("InitPostEntity", "MedalGarage_LoadPoints", loadPoints)

local function nearestGarage(pos)
    local best, bestDist
    for _, p in ipairs(MedalGarage.Points) do
        local d = p:DistToSqr(pos)
        if not bestDist or d < bestDist then best, bestDist = p, d end
    end
    return best, bestDist and math.sqrt(bestDist) or nil
end
MedalGarage.NearestGarage = nearestGarage

-- =========================
-- Spawn de véhicule
-- =========================
local function findVehicleDef(name)
    -- Liste dynamique (config in-game façon WCD), fallback catalogue statique.
    if MedalGarage.GetDealerList then
        for _, v in ipairs(MedalGarage.GetDealerList()) do
            if v.id == name or v.name == name then return v end
        end
    end
    for _, v in ipairs(cfg.Vehicles or {}) do
        if v.name == name then return v end
    end
end

local function countPlayerVehicles(ply)
    local n = 0
    for veh, owner in pairs(MedalGarage.PlayerVehicles) do
        if IsValid(veh) and owner == ply then n = n + 1 else MedalGarage.PlayerVehicles[veh] = nil end
    end
    return n
end

net.Receive("MedalGarage_Spawn", function(_, ply)
    if MedalGarage.RateOK and not MedalGarage.RateOK(ply, "spawn", 0.5) then return end
    if not canOpenGarage(ply) then ply:ChatPrint("[Garage] Accès réservé aux équipages."); return end
    local name = net.ReadString()
    local def = findVehicleDef(name)
    if not def then return end

    if MedalGarage.GetLevel(ply) < (tonumber(def.level) or 1) then
        ply:ChatPrint("[Garage] Niveau " .. def.level .. " requis pour " .. def.name .. ".")
        return
    end
    if not hasRole(ply, def.requireRole) then
        ply:ChatPrint("[Garage] Ton rôle ne permet pas de sortir ce véhicule.")
        return
    end

    local cd = tonumber(cfg.SpawnCooldown) or 30
    if (MedalGarage.LastSpawn[ply] or 0) > CurTime() then
        ply:ChatPrint("[Garage] Attends encore " .. math.ceil(MedalGarage.LastSpawn[ply] - CurTime()) .. " s.")
        return
    end
    if countPlayerVehicles(ply) >= (tonumber(cfg.MaxVehiclesPerPlayer) or 1) then
        ply:ChatPrint("[Garage] Tu as déjà un véhicule en service.")
        return
    end

    -- Position de spawn : sur la PLATEFORME de garage la plus proche.
    local spawnPos, spawnAng
    local garage, gdist = nearestGarage(ply:GetPos())
    if cfg.RequireGaragePoint then
        if not garage then
            ply:ChatPrint("[Garage] Aucune plateforme de garage sur cette map. (staff : medal_garage_point_add)")
            return
        end
        if gdist and gdist > (tonumber(cfg.GaragePointRadius) or 600) * 2 then
            ply:ChatPrint("[Garage] Approche-toi d'une plateforme de garage pour déployer un véhicule.")
            return
        end
        spawnPos = garage + Vector(0, 0, tonumber(cfg.PlatformSpawnHeight) or 20)
        spawnAng = Angle(0, ply:EyeAngles().y, 0)
    elseif garage and gdist and gdist <= (tonumber(cfg.GaragePointRadius) or 600) * 3 then
        spawnPos = garage + Vector(0, 0, tonumber(cfg.PlatformSpawnHeight) or 20)
        spawnAng = Angle(0, ply:EyeAngles().y, 0)
    else
        local fwd = ply:GetAimVector(); fwd.z = 0; fwd:Normalize()
        spawnPos = ply:GetPos() + fwd * 300 + Vector(0, 0, 30)
        spawnAng = Angle(0, ply:EyeAngles().y - 90, 0)
    end

    local veh
    if def.simfphys and simfphys and simfphys.SpawnVehicleSimple then
        -- Véhicule simfphys : API dédiée.
        veh = simfphys.SpawnVehicleSimple(def.simfphys, spawnPos, spawnAng)
    else
        veh = ents.Create(def.class)
        if not IsValid(veh) then ply:ChatPrint("[Garage] Classe de véhicule invalide : " .. tostring(def.class)); return end
        veh:SetPos(spawnPos)
        veh:SetAngles(spawnAng)
        if def.model and def.model ~= "" then veh:SetModel(def.model) end
        -- Script véhicule des jeeps Source (packs Workshop type prop_vehicle_jeep).
        if def.class == "prop_vehicle_jeep" or def.class == "prop_vehicle_airboat" then
            veh:SetKeyValue("vehiclescript", (def.script and def.script ~= "") and def.script or "scripts/vehicles/jeep_test.txt")
        end
        veh:Spawn()
        veh:Activate()
    end
    if not IsValid(veh) then ply:ChatPrint("[Garage] Impossible de créer ce véhicule."); return end

    -- Système d'HP configurable (0 = HP d'origine du véhicule).
    local hp = tonumber(def.hp) or 0
    if hp > 0 then
        veh:SetMaxHealth(hp)
        veh:SetHealth(hp)
        -- simfphys / LFS gèrent leur propre vie : on la règle aussi si l'API existe.
        if veh.SetCurHealth then pcall(function() veh:SetCurHealth(hp) end) end
        if veh.SetMaxHealth2 then pcall(function() veh:SetMaxHealth2(hp) end) end
        if veh.SetHP then pcall(function() veh:SetHP(hp) end) end
    end
    veh:SetNWString("MedalVehName", def.name or "")

    -- DarkRP : marque le propriétaire pour la protection/nettoyage.
    if veh.CPPISetOwner then veh:CPPISetOwner(ply) end
    veh.MedalGarageOwner = ply
    veh.MedalVehName = def.name

    -- Essence.
    if (cfg.Fuel or {}).Enabled ~= false then
        veh:SetNWFloat("MedalFuel", tonumber(def.fuel) or 100)
        veh:SetNWFloat("MedalFuelMax", tonumber(def.fuel) or 100)
    end

    MedalGarage.PlayerVehicles[veh] = ply
    MedalGarage.LastSpawn[ply] = CurTime() + cd
    ply:ChatPrint("[Garage] " .. def.name .. " livré.")
end)

net.Receive("MedalGarage_Open", function(_, ply)
    if MedalGarage.RateOK and not MedalGarage.RateOK(ply, "open", 0.8) then return end
    -- Liste des véhicules (config in-game) + paramètres (fond Dropbox).
    if MedalGarage.SendDealerList then MedalGarage.SendDealerList(ply) end
    -- Envoi des points (pour l'aperçu) au staff seulement.
    if isStaff(ply) then
        net.Start("MedalGarage_Points")
            net.WriteUInt(#MedalGarage.Points, 8)
            for _, p in ipairs(MedalGarage.Points) do net.WriteVector(p) end
        net.Send(ply)
    end
end)

net.Receive("MedalGarage_PointAction", function(_, ply)
    if not isStaff(ply) then return end
    if MedalGarage.RateOK and not MedalGarage.RateOK(ply, "points", 0.3) then return end
    local action = net.ReadString()
    if action == "add" then
        table.insert(MedalGarage.Points, ply:GetPos())
        savePoints()
        spawnPlatforms()
        ply:ChatPrint("[Garage] Plateforme de garage ajoutée (" .. #MedalGarage.Points .. ").")
    elseif action == "clear" then
        MedalGarage.Points = {}
        savePoints()
        spawnPlatforms()
        ply:ChatPrint("[Garage] Plateformes de garage effacées.")
    end
    net.Start("MedalGarage_Points")
        net.WriteUInt(#MedalGarage.Points, 8)
        for _, p in ipairs(MedalGarage.Points) do net.WriteVector(p) end
    net.Send(ply)
end)

concommand.Add("medal_garage_point_add", function(ply)
    if not isStaff(ply) then return end
    table.insert(MedalGarage.Points, ply:GetPos())
    savePoints()
    spawnPlatforms()
    ply:ChatPrint("[Garage] Plateforme de garage ajoutée (" .. #MedalGarage.Points .. ").")
end)

-- =========================
-- PNJ vendeur : pose/sauvegarde par map.
-- =========================
local function npcPath()
    return "medal_garage/npc_" .. game.GetMap() .. ".json"
end

local function saveNPCs()
    file.CreateDir("medal_garage")
    local out = {}
    for _, e in ipairs(ents.FindByClass("medal_garage_npc")) do
        if IsValid(e) then
            local p, a = e:GetPos(), e:GetAngles()
            table.insert(out, {x = p.x, y = p.y, z = p.z, yaw = a.y})
        end
    end
    file.Write(npcPath(), util.TableToJSON(out, true))
end

local function spawnNPC(pos, yaw)
    local npc = ents.Create("medal_garage_npc")
    if not IsValid(npc) then return end
    npc:SetPos(pos)
    npc:SetAngles(Angle(0, yaw or 0, 0))
    npc:Spawn()
    return npc
end

hook.Add("InitPostEntity", "MedalGarage_LoadNPCs", function()
    if (cfg.NPC or {}).Enabled == false then return end
    local raw = file.Read(npcPath(), "DATA")
    for _, n in ipairs(raw and util.JSONToTable(raw) or {}) do
        spawnNPC(Vector(tonumber(n.x) or 0, tonumber(n.y) or 0, tonumber(n.z) or 0), tonumber(n.yaw) or 0)
    end
end)

concommand.Add("medal_garage_npc_add", function(ply)
    if not isStaff(ply) then return end
    local tr = ply:GetEyeTrace()
    spawnNPC(tr.HitPos, ply:EyeAngles().y + 180)
    saveNPCs()
    ply:ChatPrint("[Garage] Vendeur posé. (medal_garage_npc_clear pour tout retirer)")
end)

concommand.Add("medal_garage_npc_clear", function(ply)
    if not isStaff(ply) then return end
    for _, e in ipairs(ents.FindByClass("medal_garage_npc")) do if IsValid(e) then e:Remove() end end
    saveNPCs()
    ply:ChatPrint("[Garage] Vendeurs retirés.")
end)

-- =========================
-- Système d'essence
-- =========================
local function vehicleSpeed(veh)
    local phys = veh:GetPhysicsObject()
    if IsValid(phys) then return phys:GetVelocity():Length() end
    return veh:GetVelocity():Length()
end

timer.Create("MedalGarage_Fuel", 1, 0, function()
    local fc = cfg.Fuel or {}
    if fc.Enabled == false then return end
    for veh, owner in pairs(MedalGarage.PlayerVehicles) do
        if IsValid(veh) then
            local fuel = veh:GetNWFloat("MedalFuel", -1)
            if fuel >= 0 then
                local occupied = false
                local driver = veh.GetDriver and veh:GetDriver() or nil
                if IsValid(driver) then occupied = true end
                local speed = vehicleSpeed(veh)

                if occupied then
                    local drain = tonumber(fc.DrainIdle) or 0.15
                    drain = drain + (tonumber(fc.DrainMoving) or 0.9) * math.Clamp(speed / 700, 0, 1)
                    fuel = math.max(fuel - drain, 0)
                    veh:SetNWFloat("MedalFuel", fuel)

                    -- Panne sèche : coupe le moteur.
                    if fuel <= 0 and fc.EmptyStalls ~= false then
                        if veh.GetDriver and IsValid(veh:GetDriver()) then
                            if veh.StartEngine then veh:StartEngine(false) end
                        end
                    end
                elseif fc.AutoRefuelAtGarage ~= false and speed < 30 then
                    -- Véhicule garé à l'arrêt près d'un garage : plein automatique.
                    local max = veh:GetNWFloat("MedalFuelMax", 100)
                    if fuel < max and #MedalGarage.Points > 0 then
                        local _, d = nearestGarage(veh:GetPos())
                        if d and d <= (tonumber(cfg.GaragePointRadius) or 600) then
                            veh:SetNWFloat("MedalFuel", math.min(fuel + (tonumber(fc.RefuelRate) or 12), max))
                        end
                    end
                end
            end
        else
            MedalGarage.PlayerVehicles[veh] = nil
        end
    end
end)

-- Ravitaillement en essence (maintien de E sur le véhicule près d'un garage).
net.Receive("MedalGarage_Refuel", function(_, ply)
    if MedalGarage.RateOK and not MedalGarage.RateOK(ply, "refuel", 0.2) then return end
    local fc = cfg.Fuel or {}
    if fc.Enabled == false then return end
    local veh = net.ReadEntity()
    if not IsValid(veh) or veh:GetNWFloat("MedalFuelMax", 0) <= 0 then return end
    if veh:GetPos():Distance(ply:GetPos()) > 260 then return end

    -- Doit être près d'un garage (ou pas, selon config).
    if fc.RefuelNearGarage ~= false and #MedalGarage.Points > 0 then
        local _, d = nearestGarage(veh:GetPos())
        if not d or d > (tonumber(cfg.GaragePointRadius) or 600) then
            ply:ChatPrint("[Garage] Ravitaillement possible seulement près d'un garage.")
            return
        end
    end

    local fuel = veh:GetNWFloat("MedalFuel", 0)
    local max = veh:GetNWFloat("MedalFuelMax", 100)
    if fuel >= max then return end

    local add = tonumber(fc.RefuelRate) or 12
    -- Consomme le ravitaillement des caisses de Soutien si dispo.
    if fc.UseSupplyCrates and MedalBarracks and MedalBarracks.ConsumeSupplies then
        local cost = math.ceil(add * (tonumber(fc.SupplyPerFuel) or 0.5))
        if not MedalBarracks.ConsumeSupplies(ply, cost, veh:GetPos()) then
            ply:ChatPrint("[Garage] Pas assez de ravitaillement à proximité pour faire le plein.")
            return
        end
    end
    veh:SetNWFloat("MedalFuel", math.min(fuel + add, max))
end)

hook.Add("PlayerDisconnected", "MedalGarage_Cleanup", function(ply)
    for veh, owner in pairs(MedalGarage.PlayerVehicles) do
        if owner == ply and IsValid(veh) then veh:Remove() end
        if not IsValid(veh) then MedalGarage.PlayerVehicles[veh] = nil end
    end
    MedalGarage.LastSpawn[ply] = nil
end)
