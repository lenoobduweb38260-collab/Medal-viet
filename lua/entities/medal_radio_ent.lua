--[[
    Medal Barracks — Radio de campagne posée au sol.
    Props configurable dans cfg.Radio.PropModel.
    E dessus = menu de réglage de fréquence (animation de tuning côté client).
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Radio de campagne"
ENT.Category = "Medal Vietnam"
ENT.Spawnable = false

local function radioCfg()
    return (MedalBarracks and MedalBarracks.Config and MedalBarracks.Config.Radio) or {}
end

function ENT:Initialize()
    if SERVER then
        self:SetModel(tostring(radioCfg().PropModel or "models/props_lab/reciever01a.mdl"))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:EnableMotion(false) -- la radio reste en place une fois posée
        end
    end
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        net.Start("MedalRadio_OpenMenu")
            net.WriteEntity(self)
        net.Send(activator)
    end
end

if CLIENT then
    local function S(v)
        return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080))
    end

    surface.CreateFont("MedalRadio_3D2DTitle", {font = "Roboto Condensed", size = 46, weight = 1000, extended = true})
    surface.CreateFont("MedalRadio_3D2DSmall", {font = "Roboto Condensed", size = 30, weight = 800, extended = true})

    function ENT:Draw()
        self:DrawModel()

        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local dist = self:GetPos():Distance(ply:GetPos())
        if dist > 400 then return end
        local alpha = math.Clamp(255 * (1 - (dist - 220) / 180), 0, 255)

        local freqID = self:GetNWString("MedalRadio_Freq", "radioman")
        local freqName, freqMHz = "RÉSEAU RADIO", ""
        for _, f in ipairs(radioCfg().Frequencies or {}) do
            if tostring(f.id) == freqID then freqName = tostring(f.name or f.id); freqMHz = tostring(f.freq or "") break end
        end

        local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 9)
        local ang = Angle(0, (ply:GetPos() - pos):Angle().y + 90, 90)
        cam.Start3D2D(pos, ang, 0.045)
            draw.SimpleText(freqName, "MedalRadio_3D2DTitle", 0, -30, Color(232, 234, 222, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(freqMHz .. "  •  E POUR RÉGLER", "MedalRadio_3D2DSmall", 0, 12, Color(148, 156, 108, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(112, 126, 74, alpha)
            surface.DrawRect(-90, 38, 180, 3)
        cam.End3D2D()
    end
end
