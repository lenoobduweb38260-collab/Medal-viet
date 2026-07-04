--[[
    Medal Barracks — Caisse de ravitaillement posée au sol.
    Contient un stock de ravitaillement (NWInt MedalSupply_Amount) que les
    ingénieurs consomment pour construire les emplacements (canons, MG…).
    Props configurable dans cfg.Supply.PropModel.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Caisse de ravitaillement"
ENT.Category = "Medal Vietnam"
ENT.Spawnable = false

local function supplyCfg()
    return (MedalBarracks and MedalBarracks.Config and MedalBarracks.Config.Supply) or {}
end

function ENT:Initialize()
    if SERVER then
        self:SetModel(tostring(supplyCfg().PropModel or "models/props_junk/wood_crate001a.mdl"))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:EnableMotion(false) -- la caisse reste où on l'a posée
        end
    end
end

if CLIENT then
    surface.CreateFont("MedalSupply_3D2DTitle", {font = "Roboto Condensed", size = 42, weight = 1000, extended = true})
    surface.CreateFont("MedalSupply_3D2DSmall", {font = "Roboto Condensed", size = 28, weight = 800, extended = true})

    function ENT:Draw()
        self:DrawModel()

        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local dist = self:GetPos():Distance(ply:GetPos())
        if dist > 380 then return end
        local alpha = math.Clamp(255 * (1 - (dist - 210) / 170), 0, 255)

        local amount = self:GetNWInt("MedalSupply_Amount", 0)
        local max = tonumber(supplyCfg().SupplyAmount) or 50

        local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 8)
        local ang = Angle(0, (ply:GetPos() - pos):Angle().y + 90, 90)
        cam.Start3D2D(pos, ang, 0.045)
            draw.SimpleText("RAVITAILLEMENT", "MedalSupply_3D2DTitle", 0, -26, Color(232, 234, 222, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(amount .. " / " .. max, "MedalSupply_3D2DSmall", 0, 12, Color(148, 156, 108, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            local barW = 160
            surface.SetDrawColor(20, 24, 17, alpha * 0.7)
            surface.DrawRect(-barW / 2, 34, barW, 8)
            surface.SetDrawColor(112, 126, 74, alpha)
            surface.DrawRect(-barW / 2, 34, barW * math.Clamp(amount / math.max(max, 1), 0, 1), 8)
        cam.End3D2D()
    end
end
