--[[
    Medal Barracks — Ravitaillement (serveur).
    - Le Soutien pose des caisses de ravitaillement (50 par défaut).
    - Après la pose, sa caisse se recharge (NWFloat MedalSupply_ReadyAt) :
      insélectionnable dans le weapon selector tant que < 100%.
    - Les ingénieurs consomment le ravitaillement des caisses proches pour
      construire les emplacements de l'Emplacement Tool (gred_emp_tool).
]]

MedalBarracks = MedalBarracks or {}
local cfg = MedalBarracks.Config or {}

util.AddNetworkString("MedalSupply_Place")

local function supplyCfg()
    return cfg.Supply or {}
end

local function armyOf(ply)
    if MedalBarracks.GetPlayerCamp then return MedalBarracks.GetPlayerCamp(ply) or "" end
    return ply:GetNWString("MedalBarracks_ArmyChoice", "")
end

local function listHas(list, value)
    for _, v in ipairs(list or {}) do
        if tostring(v) == tostring(value) then return true end
    end
    return false
end

local function isSupport(ply)
    return IsValid(ply) and listHas(supplyCfg().SupportRoleIDs or {"support", "soutien"}, ply:GetNWString("MedalBarracks_Role", ""))
end

local function useRadiusUnits()
    return (tonumber(supplyCfg().UseRadiusMeters) or 15) * (tonumber((cfg.Radio or {}).MetersToUnits) or 39.37)
end

local function ownedCrates(ply)
    local out = {}
    local sid = ply:SteamID64()
    for _, ent in ipairs(ents.FindByClass("medal_supply_crate")) do
        if IsValid(ent) and ent:GetNWString("MedalSupply_Owner", "") == sid then table.insert(out, ent) end
    end
    return out
end

-- =========================
-- Pose de la caisse
-- =========================
net.Receive("MedalSupply_Place", function(_, ply)
    local sc = supplyCfg()
    if sc.Enabled == false then return end
    if not isSupport(ply) then ply:ChatPrint("[Ravitaillement] Seul un Soutien peut poser une caisse."); return end
    local wep = ply:GetWeapon("medal_supply_swep")
    if not IsValid(wep) then ply:ChatPrint("[Ravitaillement] Il te faut ta caisse de ravitaillement."); return end
    if ply:GetNWFloat("MedalSupply_ReadyAt", 0) > CurTime() then
        ply:ChatPrint("[Ravitaillement] Ta caisse n'est pas encore rechargée.")
        return
    end

    local pos = net.ReadVector()
    local ang = net.ReadAngle()

    local maxDist = (tonumber(sc.MaxDeployDistance) or 95) * 1.6
    if pos:Distance(ply:GetPos()) > maxDist then return end

    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 10),
        endpos = pos + Vector(0, 0, 10),
        mins = Vector(-14, -14, 0),
        maxs = Vector(14, 14, 20),
        filter = ply,
    })
    if tr.Hit or tr.StartSolid then ply:ChatPrint("[Ravitaillement] Emplacement invalide."); return end

    -- Limite de caisses simultanées : la plus ancienne saute.
    local maxCrates = tonumber(sc.MaxCratesPerPlayer) or 2
    local crates = ownedCrates(ply)
    while #crates >= maxCrates and maxCrates > 0 do
        local oldest = table.remove(crates, 1)
        if IsValid(oldest) then oldest:Remove() end
    end

    local ent = ents.Create("medal_supply_crate")
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(Angle(0, ang.y, 0))
    ent:Spawn()
    ent:SetNWString("MedalSupply_Owner", ply:SteamID64())
    ent:SetNWString("MedalSupply_Army", armyOf(ply))
    ent:SetNWInt("MedalSupply_Amount", tonumber(sc.SupplyAmount) or 50)
    ent:EmitSound("physics/wood/wood_crate_impact_hard2.wav")

    -- Lance la recharge : le logo au-dessus du weapon selector suit ce NWFloat.
    local recharge = math.max(tonumber(sc.RechargeTime) or 60, 1)
    ply:SetNWFloat("MedalSupply_ReadyAt", CurTime() + recharge)
    ply:SetNWFloat("MedalSupply_RechargeTime", recharge)

    -- On force le passage sur une autre arme le temps de la recharge.
    for _, w in ipairs(ply:GetWeapons()) do
        if IsValid(w) and w:GetClass() ~= "medal_supply_swep" then
            ply:SelectWeapon(w:GetClass())
            break
        end
    end

    ply:ChatPrint("[Ravitaillement] Caisse posée (" .. tostring(sc.SupplyAmount or 50) .. " de ravitaillement). Recharge en cours…")
end)

-- =========================
-- Consommation de ravitaillement (ingénieurs / emplacements)
-- =========================
-- Consomme "amount" de ravitaillement dans les caisses de la faction du joueur
-- autour de "pos" (par défaut : position du joueur). Retourne true si payé.
function MedalBarracks.ConsumeSupplies(ply, amount, pos)
    amount = math.max(tonumber(amount) or 0, 0)
    if amount <= 0 then return true end
    if not IsValid(ply) then return false end
    pos = pos or ply:GetPos()
    local armyID = armyOf(ply)
    local radius = useRadiusUnits()

    -- Caisses de la faction triées de la plus proche à la plus lointaine.
    local crates = {}
    for _, ent in ipairs(ents.FindByClass("medal_supply_crate")) do
        if IsValid(ent) and ent:GetNWString("MedalSupply_Army", "") == armyID and ent:GetPos():Distance(pos) <= radius then
            table.insert(crates, ent)
        end
    end
    table.sort(crates, function(a, b) return a:GetPos():DistToSqr(pos) < b:GetPos():DistToSqr(pos) end)

    local available = 0
    for _, ent in ipairs(crates) do available = available + ent:GetNWInt("MedalSupply_Amount", 0) end
    if available < amount then return false, available end

    local remaining = amount
    for _, ent in ipairs(crates) do
        if remaining <= 0 then break end
        local stock = ent:GetNWInt("MedalSupply_Amount", 0)
        local take = math.min(stock, remaining)
        remaining = remaining - take
        if stock - take <= 0 then
            ent:EmitSound("physics/wood/wood_crate_break3.wav")
            ent:Remove() -- caisse vidée
        else
            ent:SetNWInt("MedalSupply_Amount", stock - take)
        end
    end
    return true
end

-- =========================
-- Intégration Emplacement Tool (gred_emp_tool) : la pose d'un emplacement
-- consomme du ravitaillement de Soutien. Aucun fichier du tool n'est modifié :
-- on enveloppe CreateEntity au chargement.
-- =========================
hook.Add("InitPostEntity", "MedalSupply_WrapEmplacementTool", function()
    local stored = weapons.GetStored("gred_emp_tool")
    if not stored or stored.MedalSupplyWrapped then return end
    stored.MedalSupplyWrapped = true

    local oldCreate = stored.CreateEntity
    if not isfunction(oldCreate) then return end

    stored.CreateEntity = function(swep, EyeTrace)
        local sc = supplyCfg()
        local cost = tonumber(sc.EmplacementCost) or 25
        local owner = swep.Owner or (swep.GetOwner and swep:GetOwner())
        if sc.Enabled ~= false and cost > 0 and IsValid(owner) and owner:IsPlayer() then
            local buildPos = EyeTrace and EyeTrace.HitPos or owner:GetPos()
            local ok, available = MedalBarracks.ConsumeSupplies(owner, cost, buildPos)
            if not ok then
                owner:ChatPrint("[Ravitaillement] Pas assez de ravitaillement à proximité : " .. tostring(available or 0) .. " / " .. cost .. " requis. Demande une caisse à un Soutien.")
                return
            end
            owner:ChatPrint("[Ravitaillement] " .. cost .. " de ravitaillement consommé pour la construction.")
        end
        return oldCreate(swep, EyeTrace)
    end

    print("[MedalBarracks] Emplacement Tool détecté : coût en ravitaillement activé.")
end)
