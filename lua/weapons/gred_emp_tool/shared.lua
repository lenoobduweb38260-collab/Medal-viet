SWEP.Base 						= "weapon_base"

SWEP.Spawnable					= true
SWEP.AdminSpawnable				= true

SWEP.Category					= "Gredwitch's SWEPs"
SWEP.Author						= "Gredwitch"
SWEP.Contact					= ""
SWEP.Purpose					= ""
SWEP.Instructions				= ""
SWEP.PrintName					= "Emplacement Tool"


SWEP.WorldModel					= "models/weapons/c_arms.mdl"
SWEP.ViewModel 					= "models/weapons/gredwitch/v_hammer.mdl"
SWEP.ViewModel 					= "models/mm1/box.mdl"
SWEP.UseHands					= true

SWEP.Primary					= {
								Ammo 		= "None",
								ClipSize 	= -1,
								DefaultClip = -1,
								Automatic 	= false,
								
								---------------------
								
								NextShot	= 0,
								FireRate	= 0.3
}
SWEP.Secondary					= SWEP.Primary
SWEP.DrawAmmo					= false

SWEP.NextReload					= 0
SWEP.ReloadDelay				= 0.3

SWEP.ModelOffset				= Vector()
SWEP.MaxSpawnDistance			= 800
SWEP.MaxSpawnDistanceSqr		= SWEP.MaxSpawnDistance*SWEP.MaxSpawnDistance

function SWEP:SetupDataTables()
	self:NetworkVar("Int",0,"AngOffset")
end


function SWEP:Holster(wep)
	self.SelectedEmplacement = nil
	self.LastSelectedEmplacement = nil
	
	self:SelectedEmplacementChanged()
	
	return true
end

function SWEP:SpawnPosValid(EyeTrace)
	return not (EyeTrace.HitSky or not EyeTrace.Hit) and self.MaxSpawnDistanceSqr >= EyeTrace.StartPos:DistToSqr(EyeTrace.HitPos)
end