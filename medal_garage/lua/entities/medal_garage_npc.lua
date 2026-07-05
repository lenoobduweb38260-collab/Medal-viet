--[[
    Medal Garage — PNJ vendeur.
    Appuie sur E dessus pour ouvrir le menu du garage.
    Pose-le avec medal_garage_npc_add (staff), sauvegardé par map.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Vendeur du garage"
ENT.Category = "Medal Vietnam"
ENT.Spawnable = false

local function npcCfg()
    return (MedalGarage and MedalGarage.Config and MedalGarage.Config.NPC) or {}
end

function ENT:Initialize()
    if SERVER then
        self:SetModel(tostring(npcCfg().Model or "models/player/soldier_stripped.mdl"))
        self:SetupPhysicsFromModel()
        self:SetUseType(SIMPLE_USE)
        self:SetSolid(SOLID_BBOX)
        self:PhysicsInit(SOLID_BBOX)
        self:SetMoveType(MOVETYPE_NONE)
        self:DrawShadow(true)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        -- Animation idle.
        self:ResetSequence(self:LookupSequence("idle_all_01") or self:LookupSequence("idle") or 0)
    end
end

function ENT:SetupPhysicsFromModel()
    self:PhysicsInitBox(Vector(-16, -16, 0), Vector(16, 16, 72))
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if (self.NextUse or 0) > CurTime() then return end
        self.NextUse = CurTime() + 0.5
        net.Start("MedalGarage_OpenFromNPC")
        net.Send(activator)
    end

    function ENT:Think()
        self:NextThink(CurTime() + 0.5)
        return true
    end
end

if CLIENT then
    surface.CreateFont("MGarageNPC_Name", {font = "Roboto Condensed", size = 30, weight = 1000, extended = true})
    surface.CreateFont("MGarageNPC_Sub", {font = "Roboto Condensed", size = 22, weight = 800, extended = true})

    function ENT:Draw()
        self:DrawModel()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local d = self:GetPos():Distance(ply:GetPos())
        if d > 300 then return end
        local a = math.Clamp(255 * (1 - (d - 150) / 150), 0, 255)
        local pos = self:GetPos() + Vector(0, 0, 82)
        local ang = (ply:GetPos() - pos); ang.z = 0; ang = ang:Angle()
        ang:RotateAroundAxis(ang:Up(), -90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        cam.Start3D2D(pos, ang, 0.1)
            draw.RoundedBox(0, -150, -46, 300, 74, Color(10, 12, 9, a * 0.75))
            surface.SetDrawColor(112, 126, 74, a)
            surface.DrawOutlinedRect(-150, -46, 300, 74, 2)
            draw.SimpleText(npcCfg().Name or "GARAGE", "MGarageNPC_Name", 0, -28, Color(240, 242, 232, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("[E] " .. (npcCfg().UseText or "Ouvrir le garage"), "MGarageNPC_Sub", 0, 6, Color(148, 156, 108, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
