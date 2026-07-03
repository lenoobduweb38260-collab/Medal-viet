--[[
    Medal Barracks — Radio portative du Radioman.
    Clic droit  : active/désactive l'aperçu de pose (fantôme vert = position valide).
    Clic gauche : maintenir pour poser la radio (jauge circulaire).
    La logique d'aperçu et de jauge est côté client dans cl_radio.lua.
]]

AddCSLuaFile()

SWEP.PrintName = "Radio portative"
SWEP.Category = "Medal Vietnam"
SWEP.Author = "Medal Vietnam"
SWEP.Instructions = "Clic droit : aperçu de pose. Maintenir clic gauche : déployer la radio."
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
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

-- Les clics sont interceptés côté client (aperçu + jauge dans cl_radio.lua).
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.1)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.3)
end

function SWEP:Deploy()
    return true
end

if CLIENT then
    function SWEP:DrawHUD()
        -- L'aperçu fantôme, la jauge circulaire et les instructions
        -- sont dessinés par cl_radio.lua (hooks HUDPaint / PostDrawTranslucentRenderables).
    end
end
