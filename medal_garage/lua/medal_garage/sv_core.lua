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

local function loadPoints()
    MedalGarage.Points = {}
    local raw = file.Read(pointsPath(), "DATA")
    if raw then
        for _, p in ipairs(util.JSONToTable(raw) or {}) do
            table.insert(MedalGarage.Points, Vector(tonumber(p.x) or 0, tonumber(p.y) or 0, tonumber(p.z) or 0))
        end
    end
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

    -- Position de spawn : point de garage le plus proche, sinon devant le joueur.
    local spawnPos, spawnAng
    local garage = nearestGarage(ply:GetPos())
    if cfg.RequireGaragePoint and not garage then
        ply:ChatPrint("[Garage] Aucun point de garage défini sur cette map.")
        return
    end
    if garage and ply:GetPos():Distance(garage) <= (tonumber(cfg.GaragePointRadius) or 600) * 3 then
        spawnPos = garage + Vector(0, 0, 20)
        spawnAng = Angle(0, ply:EyeAngles().y, 0)
    else
        local fwd = ply:GetAimVector(); fwd.z = 0; fwd:Normalize()
        spawnPos = ply:GetPos() + fwd * 300 + Vector(0, 0, 30)
        spawnAng = Angle(0, ply:EyeAngles().y - 90, 0)
    end

    local veh = ents.Create(def.class)
    if not IsValid(veh) then ply:ChatPrint("[Garage] Classe de véhicule invalide : " .. tostring(def.class)); return end
    veh:SetPos(spawnPos)
    veh:SetAngles(spawnAng)
    if def.model and def.model ~= "" then veh:SetModel(def.model) end
    -- KeyValue standard des véhicules jeep GMod ; ignoré par les autres bases.
    if def.class == "prop_vehicle_jeep" then
        veh:SetKeyValue("vehiclescript", "scripts/vehicles/jeep_test.txt")
    end
    veh:Spawn()
    veh:Activate()

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
    local action = net.ReadString()
    if action == "add" then
        table.insert(MedalGarage.Points, ply:GetPos())
        savePoints()
        ply:ChatPrint("[Garage] Point de garage ajouté (" .. #MedalGarage.Points .. ").")
    elseif action == "clear" then
        MedalGarage.Points = {}
        savePoints()
        ply:ChatPrint("[Garage] Points de garage effacés.")
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
    ply:ChatPrint("[Garage] Point de garage ajouté (" .. #MedalGarage.Points .. ").")
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
