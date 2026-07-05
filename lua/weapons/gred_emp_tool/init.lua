
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include		("shared.lua")

function SWEP:CreateEntity(EyeTrace)
	if not self:SpawnPosValid(EyeTrace) then return end
	
	net.Start("gred_net_emplacementtool_spawnemplacement")
	net.Send(self.Owner)
	
	local BaseClass
	local ang = EyeTrace.Normal:Angle()
	local pos = EyeTrace.HitPos
	
	ang.p = 0
	ang.y = ang.y + self:GetAngOffset() * 90
	ang.r = 0
	
	local ent = ents.Create(self.SelectedEmplacement)
	ent:SetAngles(ang)
	ent:SetPos(pos)
	ent:Spawn()
	ent:Activate()
	
	if gred.EmplacementTool.AdditionalEntities[self.SelectedEmplacement] then
		local phys = ent:GetPhysicsObject()
		
		if IsValid(phys) then
			phys:EnableMotion(false)
		end
		
		local Mins,Maxs = ent:GetModelBounds()
		pos = pos + Vector(0,0,math.abs(math.min(Mins.z,0)))
		Mins,Maxs = Mins:Length(),Maxs:Length()
		ent:SetPos(pos)
		
		if istable(ent.Entities) then
			table.insert(ent.Entities,ent)
		else
			ent.Entities = {ent}
		end
		
		local OldOnTakeDamage = ent.OnTakeDamage
		ent.OldOnTakeDamage = OldOnTakeDamage
		
		ent.OnTakeDamage = function(ent,dmg)
			local attacker = dmg:GetAttacker()
			
			if attacker and attacker.GetActiveWeapon then
				local wep = attacker:GetActiveWeapon()
				
				if IsValid(wep) and gred.EmplacementTool.WeaponWhiteList[wep:GetClass()] then
					local NewVal = ent:GetNWFloat("BuildPercentage",0) + (math.random(10.1,20.1) * (25 / (Maxs + Mins))) * gred.EmplacementTool.BuildRate
					ent:SetNWFloat("BuildPercentage",NewVal)
				end
			end
		end
		
		BaseClass = baseclass.Get(self.SelectedEmplacement)
	else
		BaseClass = baseclass.Get("gred_emp_base")
		local HPMul = math.min(100 / ent.HP,1)
		local hull = ent.GetHull and ent:GetHull() or nil
		
		if IsValid(hull) then
			local phys = hull:GetPhysicsObject()
			
			if IsValid(phys) then
				phys:EnableMotion(false)
			end
			
			local ModelOffset = hull:GetModelBounds()
			pos = pos + Vector(0,0,math.abs(math.min(ModelOffset.z,0)))
			hull:SetPos(pos)
			
			local yaw = ent.GetYaw and ent:GetYaw() or nil
			
			if IsValid(yaw) then
				yaw:SetPos(ent.YawPos)
				ent:SetPos(ent.TurretPos)
				
				local aimsight = ent.GetAimSight and ent:GetAimSight() or nil
				
				if IsValid(aimsight) then
					aimsight:SetPos(ent.AimSightPos)
				end
			else
				ent:SetPos(ent.TurretPos)
			end
		end
		
		for k,v in pairs(ent.Entities) do
			if IsValid(v) then
				local OldOnTakeDamage = v.OnTakeDamage
				v.OldOnTakeDamage = OldOnTakeDamage
				
				v.OnTakeDamage = function(v,dmg)
					local attacker = dmg:GetAttacker()
					
					if attacker and attacker.GetActiveWeapon then
						local wep = attacker:GetActiveWeapon()
						
						if IsValid(wep) and gred.EmplacementTool.WeaponWhiteList[wep:GetClass()] then
							local NewVal = ent:GetNWFloat("BuildPercentage",0) + (math.random(10.1,20.1) * HPMul) * gred.EmplacementTool.BuildRate
							ent:SetNWFloat("BuildPercentage",NewVal)
						end
					end
				end
			end
		end
	end
	
	ent.Use = function() end
	ent:SetNWFloat("BuildPercentage",0)
	ent:EmitSound("phx/epicmetal_hard"..math.random(1,7)..".wav")
	ent:SetNWVarProxy("BuildPercentage",function(ent,name,oldval,newval)
		if newval >= 100 then
			for k,v in pairs(ent.Entities) do
				if IsValid(v) and v.OldOnTakeDamage then
					v.OnTakeDamage = v.OldOnTakeDamage
				end
			end
			
			ent.Use = BaseClass.Use
		end
	end)
	
	timer.Simple(0.5,function() -- FIXME : make it so emplacements can predict this and use NWInts to do that. Right now this is super stupid
		if !IsValid(ent) then return end
		
		net.Start("gred_net_emplacementtool_emplacementspawned")
			net.WriteEntity(ent)
		net.Broadcast()
	end)
	
	self.SelectedEmplacement = nil
	self.LastSelectedEmplacement = nil
end

function SWEP:EditEmplacement(EyeTrace)
	if not IsValid(EyeTrace.Entity) then return end
	
	local ent
	
	if EyeTrace.Entity.Base == "gred_emp_base" then
		ent = EyeTrace.Entity
	elseif EyeTrace.Entity.GetClass and EyeTrace.Entity:GetClass() == "gred_prop_emp" then
		ent = GetBaseEmplacement(EyeTrace.Entity)
	end
	
	if not IsValid(ent) or ent:GetPos():DistToSqr(EyeTrace.StartPos) > self.MaxSpawnDistanceSqr or ent:GetNWFloat("BuildPercentage",100) < 100 then return end
	
	if not ent.ToolEntities then
		ent.ToolEntities = {}
		BuildToolEntitiesTable(ent,ent:GetHull())
	end
	
	net.Start("gred_net_emplacementtool_edit")
	net.Send(self.Owner)
	
	return true
end

function SWEP:PrimaryAttack()
	local EyeTrace = self.Owner:GetEyeTrace()
	
	if self.SelectedEmplacement then
		self:CreateEntity(EyeTrace)
	-- else
		-- self:EditEmplacement(EyeTrace)
	end
end

function SWEP:SecondaryAttack()
	local EyeTrace = self.Owner:GetEyeTrace()
	
	if self:EditEmplacement(EyeTrace) != nil then return end
	
	net.Start("gred_net_emplacementtool_menu")
	net.Send(self.Owner)
end

function SWEP:Reload()
	if not self.SelectedEmplacement then return end
	
	local ct = CurTime()
	if self.NextReload > ct then return end
	
	local OldAngOffset = self:GetAngOffset()
	self:SetAngOffset(OldAngOffset >= 3 and 0 or OldAngOffset + 1)
	
	self.NextReload = ct + self.ReloadDelay
end


function SWEP:SelectedEmplacementChanged()
	self:SetAngOffset(0)
end