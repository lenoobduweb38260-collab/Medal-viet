--[[
    Medal Barracks — Suivi d'activité / AFK (serveur).
    Expose des fonctions GLOBALES réutilisées par les autres addons Medal
    (ex : Medal Frontline pour le compteur de joueurs actifs) :

        MedalAFK_LastActivity(ply)      -> CurTime() de la dernière activité
        MedalAFK_IsAFK(ply, seconds)    -> true si inactif depuis `seconds`
        MedalAFK_Seconds(ply)           -> secondes d'inactivité

    L'activité = mouvement, rotation de la caméra, touche pressée ou chat.
]]

if MedalAFK_Tracker then return end -- déjà chargé par un autre addon Medal
MedalAFK_Tracker = true

local activity = {}

local function markActive(ply)
    if not IsValid(ply) then return end
    activity[ply] = CurTime()
    -- NWFloat throttlé : lisible côté client si besoin (HUD, scoreboard...).
    if (ply.MedalAFK_NextNW or 0) < CurTime() then
        ply.MedalAFK_NextNW = CurTime() + 5
        ply:SetNWFloat("MedalAFK_Last", CurTime())
    end
end

function MedalAFK_LastActivity(ply)
    return activity[ply] or 0
end

function MedalAFK_Seconds(ply)
    if not IsValid(ply) then return 0 end
    local last = activity[ply]
    if not last then
        activity[ply] = CurTime() -- premier passage : considéré actif
        return 0
    end
    return CurTime() - last
end

function MedalAFK_IsAFK(ply, seconds)
    return MedalAFK_Seconds(ply) >= (tonumber(seconds) or 180)
end

-- Détection : position / angles de vue comparés toutes les 2 secondes.
timer.Create("MedalAFK_Watch", 2, 0, function()
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) then
            local pos = ply:GetPos()
            local ang = ply:EyeAngles()
            local last = ply.MedalAFK_Snapshot
            if not last
                or last.pos:DistToSqr(pos) > 4
                or math.abs(math.AngleDifference(last.ang.y, ang.y)) > 0.5
                or math.abs(math.AngleDifference(last.ang.p, ang.p)) > 0.5 then
                markActive(ply)
            end
            ply.MedalAFK_Snapshot = {pos = pos, ang = ang}
        end
    end
end)

hook.Add("KeyPress", "MedalAFK_KeyPress", function(ply)
    markActive(ply)
end)

hook.Add("PlayerSay", "MedalAFK_Chat", function(ply)
    markActive(ply)
end)

hook.Add("PlayerInitialSpawn", "MedalAFK_Join", function(ply)
    markActive(ply)
end)

hook.Add("PlayerDisconnected", "MedalAFK_Leave", function(ply)
    activity[ply] = nil
end)
