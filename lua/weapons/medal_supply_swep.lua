--[[
    Medal Barracks — Caisse de ravitaillement du Soutien.
    Le soutien porte la caisse en main :
      clic droit  : aperçu fantôme (vert = position valide, rouge = invalide),
      clic gauche : pose la caisse (50 de ravitaillement par défaut).
    Après la pose, la caisse se "recharge" : logo au-dessus du weapon selector,
    insélectionnable tant que la recharge n'est pas à 100% (cl_supply.lua).
]]

AddCSLuaFile()

SWEP.PrintName = "Caisse de ravitaillement"
SWEP.Category = "Medal Vietnam"
SWEP.Author = "Medal Vietnam"
SWEP.Instructions = "Clic droit : aperçu de pose. Clic gauche : poser la caisse."
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/props_junk/wood_crate001a.mdl"
SWEP.UseHands = true
SWEP.HoldType = "slam"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

-- Les clics sont interceptés côté client (aperçu + pose dans cl_supply.lua).
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.3)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.3)
end

function SWEP:Deploy()
    -- Caisse en recharge : on ne peut pas la prendre en main.
    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsPlayer() and owner:GetNWFloat("MedalSupply_ReadyAt", 0) > CurTime() then
        if SERVER then
            timer.Simple(0, function()
                if not IsValid(owner) or not IsValid(self) then return end
                if owner:GetActiveWeapon() ~= self then return end
                for _, wep in ipairs(owner:GetWeapons()) do
                    if IsValid(wep) and wep ~= self then
                        owner:SelectWeapon(wep:GetClass())
                        break
                    end
                end
            end)
        end
    end
    return true
end
