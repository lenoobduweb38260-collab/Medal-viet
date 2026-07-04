--[[
    Medal Barracks — Caisse de ravitaillement (client).
    - Clic droit avec la caisse en main : aperçu fantôme (vert = valide, rouge = non).
    - Clic gauche : pose la caisse à l'emplacement prévisualisé.
    - Après la pose : logo de recharge au-dessus du weapon selector ; la caisse
      est insélectionnable tant que la recharge n'est pas à 100%.
]]

if SERVER then return end

MedalBarracks = MedalBarracks or {}
local cfg = MedalBarracks.Config or {}

local function supplyCfg()
    return cfg.Supply or {}
end

local function S(v)
    return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080))
end

surface.CreateFont("MedalSupply_Small", {font = "Roboto Condensed", size = 13, weight = 800, extended = true})
surface.CreateFont("MedalSupply_Pct", {font = "Roboto Condensed", size = 17, weight = 950, extended = true})

local COL_KHAKI = Color(148, 156, 108)
local COL_WHITE = Color(232, 234, 222)
local COL_RED = Color(165, 48, 40)

-- =========================
-- Blocage du weapon selector pendant la recharge (utilisé par cl_ui).
-- =========================
function MedalBarracks.WeaponSelectorBlocked(wep)
    if not IsValid(wep) or wep:GetClass() ~= "medal_supply_swep" then return false end
    local ply = LocalPlayer()
    return IsValid(ply) and ply:GetNWFloat("MedalSupply_ReadyAt", 0) > CurTime()
end

local function rechargeProgress()
    local ply = LocalPlayer()
    if not IsValid(ply) then return 1 end
    local readyAt = ply:GetNWFloat("MedalSupply_ReadyAt", 0)
    if readyAt <= CurTime() then return 1 end
    local total = math.max(ply:GetNWFloat("MedalSupply_RechargeTime", 60), 1)
    return math.Clamp(1 - (readyAt - CurTime()) / total, 0, 1)
end

-- =========================
-- Pose : fantôme + clic gauche
-- =========================
local placement = {active = false, ghost = nil, valid = false, pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}

local function holdingCrate()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return false end
    local wep = ply:GetActiveWeapon()
    return IsValid(wep) and wep:GetClass() == "medal_supply_swep"
end

local function removeGhost()
    if IsValid(placement.ghost) then placement.ghost:Remove() end
    placement.ghost = nil
    placement.active = false
end

local function updatePlacement()
    local ply = LocalPlayer()
    local sc = supplyCfg()
    local maxDist = tonumber(sc.MaxDeployDistance) or 95

    local eyePos = ply:EyePos()
    local aim = ply:GetAimVector()
    local tr = util.TraceLine({start = eyePos, endpos = eyePos + aim * maxDist, filter = ply})
    local base = tr.Hit and tr.HitPos or (eyePos + aim * maxDist)

    local ground = util.TraceLine({start = base + Vector(0, 0, 12), endpos = base - Vector(0, 0, 90), filter = ply})
    local valid = ground.Hit and ground.HitNormal.z >= 0.8
    local pos = ground.Hit and ground.HitPos or base

    if valid then
        local hull = util.TraceHull({
            start = pos + Vector(0, 0, 10),
            endpos = pos + Vector(0, 0, 10),
            mins = Vector(-14, -14, 0),
            maxs = Vector(14, 14, 20),
            filter = ply,
        })
        if hull.Hit or hull.StartSolid then valid = false end
    end
    if pos:Distance(ply:GetPos()) > maxDist * 1.5 then valid = false end

    placement.pos = pos
    placement.ang = Angle(0, ply:EyeAngles().y + 90, 0)
    placement.valid = valid

    if not IsValid(placement.ghost) then
        placement.ghost = ClientsideModel(tostring(sc.PropModel or "models/props_junk/wood_crate001a.mdl"), RENDERGROUP_TRANSLUCENT)
        if IsValid(placement.ghost) then placement.ghost:SetRenderMode(RENDERMODE_TRANSCOLOR) end
    end
    if IsValid(placement.ghost) then
        placement.ghost:SetPos(pos)
        placement.ghost:SetAngles(placement.ang)
        placement.ghost:SetColor(valid and Color(95, 200, 90, 165) or Color(210, 60, 50, 165))
    end
end

hook.Add("KeyPress", "MedalSupply_Keys", function(ply, key)
    if ply ~= LocalPlayer() or not IsFirstTimePredicted() then return end
    if not holdingCrate() or supplyCfg().Enabled == false then return end

    if key == IN_ATTACK2 then
        if placement.active then removeGhost() else placement.active = true end
    elseif key == IN_ATTACK and placement.active then
        if not placement.valid then
            notification.AddLegacy("Position invalide : vise un sol dégagé.", NOTIFY_ERROR, 2)
            return
        end
        if rechargeProgress() < 1 then
            notification.AddLegacy("La caisse n'est pas encore rechargée.", NOTIFY_ERROR, 2)
            return
        end
        net.Start("MedalSupply_Place")
            net.WriteVector(placement.pos)
            net.WriteAngle(placement.ang)
        net.SendToServer()
        removeGhost()
    end
end)

hook.Add("Think", "MedalSupply_PlacementThink", function()
    if not placement.active then return end
    if not holdingCrate() then removeGhost(); return end
    updatePlacement()
end)

hook.Add("HUDPaint", "MedalSupply_PlacementHUD", function()
    if not placement.active or not holdingCrate() then return end
    local cx, cy = ScrW() / 2, ScrH() / 2
    local hint = placement.valid and "CLIC GAUCHE : POSER LA CAISSE DE RAVITAILLEMENT" or "POSITION INVALIDE — VISE UN SOL DÉGAGÉ"
    draw.SimpleText(hint, "MedalSupply_Small", cx, cy + S(52), placement.valid and COL_WHITE or COL_RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText("CLIC DROIT : ANNULER", "MedalSupply_Small", cx, cy + S(70), Color(232, 234, 222, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)

-- =========================
-- Logo de recharge au-dessus du weapon selector.
-- =========================
local iconMat
hook.Add("HUDPaint", "MedalSupply_RechargeHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if not IsValid(ply:GetWeapon("medal_supply_swep")) then return end
    local prog = rechargeProgress()
    if prog >= 1 then return end

    local wc = cfg.WeaponSelector or {}
    local x = ScrW() - S(tonumber(wc.RightMargin) or 42) - S(64)
    local y = ScrH() - S(tonumber(wc.BottomMargin) or 118) - S(160)

    draw.RoundedBox(0, x - S(8), y - S(8), S(80), S(96), Color(10, 12, 9, 190))
    surface.SetDrawColor(214, 220, 196, 55)
    surface.DrawOutlinedRect(x - S(8), y - S(8), S(80), S(96), 1)

    iconMat = iconMat or Material(tostring(supplyCfg().Icon or "medal/loadouts/ammo.png"), "smooth")
    if iconMat and not iconMat:IsError() then
        surface.SetMaterial(iconMat)
        surface.SetDrawColor(235, 238, 226, 120 + prog * 120)
        surface.DrawTexturedRect(x, y, S(64), S(44))
    end

    -- Jauge de recharge sous le logo.
    surface.SetDrawColor(20, 24, 17, 220)
    surface.DrawRect(x, y + S(52), S(64), S(6))
    surface.SetDrawColor(COL_KHAKI.r, COL_KHAKI.g, COL_KHAKI.b, 235)
    surface.DrawRect(x, y + S(52), S(64) * prog, S(6))
    draw.SimpleText(math.floor(prog * 100) .. "%", "MedalSupply_Pct", x + S(32), y + S(72), prog < 1 and COL_KHAKI or COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
