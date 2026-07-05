--[[
    Medal Garage — Plateforme de spawn de véhicules.
    Les véhicules se matérialisent sur la plateforme (au lieu d'un simple rayon).
    Posée automatiquement à chaque point de garage.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Plateforme de garage"
ENT.Category = "Medal Vietnam"
ENT.Spawnable = false

local function gcfg()
    return (MedalGarage and MedalGarage.Config) or {}
end

function ENT:Initialize()
    if SERVER then
        self:SetModel(tostring(gcfg().PlatformModel or "models/props_phx/construct/metal_plate_curve4x2.mdl"))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
    end
end

if CLIENT then
    surface.CreateFont("MGaragePlat_Name", {font = "Roboto Condensed", size = 26, weight = 1000, extended = true})

    function ENT:Draw()
        self:DrawModel()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local d = self:GetPos():Distance(ply:GetPos())
        if d > 700 then return end
        local a = math.Clamp(255 * (1 - (d - 400) / 300), 0, 255)

        -- Hologramme "ZONE DE SPAWN" au-dessus de la plateforme.
        local t = CurTime() * 2
        local pos = self:GetPos() + Vector(0, 0, 30 + math.sin(t) * 4)
        local ang = (ply:GetPos() - pos); ang.z = 0; ang = ang:Angle()
        ang:RotateAroundAxis(ang:Up(), -90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        cam.Start3D2D(pos, ang, 0.2)
            draw.SimpleText("ZONE DE DÉPLOIEMENT", "MGaragePlat_Name", 0, 0, Color(148, 156, 108, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()

        -- Contour au sol.
        render.SetColorMaterial()
        local r = 120
        local prev
        for i = 0, 32 do
            local aa = math.rad(i / 32 * 360)
            local p = self:GetPos() + Vector(math.cos(aa) * r, math.sin(aa) * r, 6)
            if prev then render.DrawLine(prev, p, Color(112, 126, 74, a), false) end
            prev = p
        end
    end
end
