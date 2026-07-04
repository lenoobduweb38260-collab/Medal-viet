--[[
    Medal Garage — Outil de point de garage (staff).
    Clic gauche : ajoute un point de garage à ta position (spawn + ravitaillement).
    Clic droit  : efface tous les points de la map.
    Les points sont sauvegardés par map dans data/medal_garage/.
]]

AddCSLuaFile()

SWEP.PrintName = "Point de garage"
SWEP.Author = "Medal Vietnam"
SWEP.Instructions = "Clic gauche : ajouter un point • Clic droit : tout effacer"
SWEP.Category = "Medal Vietnam"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary = SWEP.Primary
SWEP.DrawAmmo = false

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.4)
    if CLIENT then return end
    net.Start("MedalGarage_PointAction") net.WriteString("add") net.SendToServer()
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.4)
    if CLIENT then return end
    net.Start("MedalGarage_PointAction") net.WriteString("clear") net.SendToServer()
end

if CLIENT then
    function SWEP:DrawHUD()
        draw.SimpleText("CLIC GAUCHE : ajouter un point de garage  •  CLIC DROIT : tout effacer",
            "DermaDefault", ScrW() / 2, ScrH() - 90, Color(232, 234, 222, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end
