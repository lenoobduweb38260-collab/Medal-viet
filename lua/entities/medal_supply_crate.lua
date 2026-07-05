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
        self:SetUseType(CONTINUOUS_USE) -- E maintenu = démontage par l'ennemi
        self.DismantleProgress = 0
        self.LastDismantleUse = 0
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:EnableMotion(false) -- la caisse reste où on l'a posée
        end
    end
end

if SERVER then
    -- Sabotage : un joueur de la faction ENNEMIE maintient E pour démonter la caisse.
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        local dc = supplyCfg().Dismantle or {}
        if dc.Enabled == false then return end

        local plyArmy = MedalBarracks.GetPlayerCamp and MedalBarracks.GetPlayerCamp(activator) or activator:GetNWString("MedalBarracks_ArmyChoice", "")
        local crateArmy = self:GetNWString("MedalSupply_Army", "")
        if plyArmy == "" or crateArmy == "" or plyArmy == crateArmy then return end

        -- Cooldown configurable entre deux démontages.
        if activator:GetNWFloat("MedalSupply_DismantleCD", 0) > CurTime() then
            if (self.NextCDNotice or 0) < CurTime() then
                self.NextCDNotice = CurTime() + 2
                local remain = math.ceil(activator:GetNWFloat("MedalSupply_DismantleCD", 0) - CurTime())
                activator:ChatPrint("[Sabotage] Attends encore " .. remain .. " s avant de démonter une autre caisse.")
            end
            return
        end

        local now = CurTime()
        local delta = now - (self.LastDismantleUse or 0)
        if delta > 0.5 then delta = 0.05 end -- reprise du maintien
        self.LastDismantleUse = now
        self.DismantleProgress = (self.DismantleProgress or 0) + delta

        local needed = math.max(tonumber(dc.Time) or 4, 0.5)
        self:SetNWFloat("MedalSupply_Dismantle", math.Clamp(self.DismantleProgress / needed, 0, 1))
        self:NextThink(CurTime() + 0.1)

        if self.DismantleProgress >= needed then
            activator:SetNWFloat("MedalSupply_DismantleCD", CurTime() + math.max(tonumber(dc.Cooldown) or 30, 0))
            activator:ChatPrint("[Sabotage] Caisse de ravitaillement ennemie démontée !")
            local owner64 = self:GetNWString("MedalSupply_Owner", "")
            for _, p in ipairs(player.GetHumans()) do
                if p:SteamID64() == owner64 then p:ChatPrint("[Ravitaillement] Une de tes caisses a été démontée par l'ennemi !") break end
            end
            self:EmitSound("physics/wood/wood_crate_break" .. math.random(1, 5) .. ".wav")
            self:Remove()
        end
    end

    -- La progression retombe si le saboteur relâche E.
    function ENT:Think()
        if (self.DismantleProgress or 0) > 0 and CurTime() - (self.LastDismantleUse or 0) > 0.6 then
            local needed = math.max(tonumber((supplyCfg().Dismantle or {}).Time) or 4, 0.5)
            self.DismantleProgress = math.max(self.DismantleProgress - 0.35, 0)
            self:SetNWFloat("MedalSupply_Dismantle", math.Clamp(self.DismantleProgress / needed, 0, 1))
        end
        self:NextThink(CurTime() + 0.25)
        return true
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

        local myArmy = ply:GetNWString("MedalBarracks_ArmyChoice", "")
        local crateArmy = self:GetNWString("MedalSupply_Army", "")
        local isEnemy = myArmy ~= "" and crateArmy ~= "" and myArmy ~= crateArmy
        local dismantle = self:GetNWFloat("MedalSupply_Dismantle", 0)

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

            -- Sabotage en cours : barre rouge de démontage.
            if dismantle > 0 then
                surface.SetDrawColor(20, 24, 17, alpha * 0.7)
                surface.DrawRect(-barW / 2, 48, barW, 8)
                surface.SetDrawColor(200, 60, 48, alpha)
                surface.DrawRect(-barW / 2, 48, barW * dismantle, 8)
                draw.SimpleText("DÉMONTAGE EN COURS !", "MedalSupply_3D2DSmall", 0, 72, Color(210, 80, 64, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif isEnemy and (supplyCfg().Dismantle or {}).Enabled ~= false and dist < 160 then
                draw.SimpleText("MAINTIENS E POUR DÉMONTER", "MedalSupply_3D2DSmall", 0, 48, Color(210, 80, 64, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        cam.End3D2D()
    end
end
