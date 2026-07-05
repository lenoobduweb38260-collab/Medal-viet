--[[
    Medal Garage — Changement de siège façon Hell Let Loose (serveur).
    Détecte le groupe de sièges d'un véhicule (compatible multi-sièges GMod par
    parenté/proximité, et API Simfphys / LFS / Glide si présentes) et fait
    tourner le joueur d'un siège à l'autre.
]]

MedalGarage = MedalGarage or {}
local cfg = MedalGarage.Config or {}

util.AddNetworkString("MedalGarage_SwitchSeat")
util.AddNetworkString("MedalGarage_SeatInfo")

-- Renvoie la liste ordonnée des entités-siège d'un véhicule (véhicule inclus).
local function getSeatGroup(veh)
    if not IsValid(veh) then return {} end

    -- LFS (Luna's Flight School)
    if veh.GetPassengerSeats and isfunction(veh.GetPassengerSeats) then
        local ok, seats = pcall(function() return veh:GetPassengerSeats() end)
        if ok and istable(seats) then
            local out = {veh}
            for _, s in ipairs(seats) do if IsValid(s) then table.insert(out, s) end end
            if #out > 1 then return out end
        end
    end
    -- Glide
    if veh.GetSeat and veh.GetSeatCount and isfunction(veh.GetSeatCount) then
        local ok, n = pcall(function() return veh:GetSeatCount() end)
        if ok and tonumber(n) then
            local out = {}
            for i = 1, n do
                local s = veh:GetSeat(i)
                if IsValid(s) then table.insert(out, s) end
            end
            if #out > 1 then return out end
        end
    end

    -- Base d'un véhicule multi-siège : on remonte au parent racine puis on
    -- collecte tous les sièges (véhicules) enfants + proches partageant l'owner.
    local root = veh
    while IsValid(root:GetParent()) and root:GetParent():IsVehicle() do root = root:GetParent() end

    local group = {}
    local seen = {}
    local function add(e)
        if IsValid(e) and e:IsVehicle() and not seen[e] then seen[e] = true; table.insert(group, e) end
    end
    add(root)
    for _, e in ipairs(root:GetChildren()) do add(e) end
    -- Pods à proximité appartenant au même owner de garage.
    for _, e in ipairs(ents.FindInSphere(root:GetPos(), 400)) do
        if e:IsVehicle() and (e.MedalGarageOwner == root.MedalGarageOwner and root.MedalGarageOwner ~= nil) then add(e) end
    end

    -- Ordre stable par distance au conducteur pour un cyclage cohérent.
    table.sort(group, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return group
end
MedalGarage.GetSeatGroup = getSeatGroup

local function seatFree(seat)
    if not IsValid(seat) then return false end
    if seat.GetDriver then return not IsValid(seat:GetDriver()) end
    return true
end

local lastSwitch = {}

local function switchSeat(ply)
    if (cfg.Seats or {}).Enabled == false then return end
    local veh = ply:GetVehicle()
    if not IsValid(veh) then return end
    if (lastSwitch[ply] or 0) > CurTime() then return end
    lastSwitch[ply] = CurTime() + 0.6

    local group = getSeatGroup(veh)
    if #group <= 1 then ply:ChatPrint("[Véhicule] Ce véhicule n'a qu'un seul siège."); return end

    local idx = 1
    for i, s in ipairs(group) do if s == veh then idx = i break end end

    -- Cherche le prochain siège libre.
    for step = 1, #group - 1 do
        local target = group[((idx - 1 + step) % #group) + 1]
        if seatFree(target) then
            ply:ExitVehicle()
            timer.Simple(0.1, function()
                if IsValid(ply) and IsValid(target) and seatFree(target) then
                    ply:EnterVehicle(target)
                    local names = (cfg.Seats or {}).Names or {}
                    local newIdx = ((idx - 1 + step) % #group) + 1
                    ply:ChatPrint("[Véhicule] Siège : " .. (names[newIdx] or ("SIÈGE " .. newIdx)))
                end
            end)
            return
        end
    end
    ply:ChatPrint("[Véhicule] Aucun autre siège libre.")
end

net.Receive("MedalGarage_SwitchSeat", function(_, ply)
    if MedalGarage.RateOK and not MedalGarage.RateOK(ply, "seat", 0.25) then return end
    switchSeat(ply)
end)

-- Envoie au client la position dans le groupe de sièges (pour le HUD).
hook.Add("PlayerEnteredVehicle", "MedalGarage_SeatInfo", function(ply, veh)
    timer.Simple(0.05, function()
        if not IsValid(ply) or not IsValid(veh) then return end
        local group = getSeatGroup(veh)
        local idx, total = 1, #group
        for i, s in ipairs(group) do if s == veh then idx = i break end end
        net.Start("MedalGarage_SeatInfo")
            net.WriteUInt(idx, 6)
            net.WriteUInt(math.max(total, 1), 6)
        net.Send(ply)
    end)
end)
