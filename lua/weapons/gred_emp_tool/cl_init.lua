include("shared.lua")

local COLOR_GREEN		= Color(0,255,0,255)
local COLOR_GREEN_ALPHA = Color(0,255,0,122)
local COLOR_RED_ALPHA 	= Color(255,0,0,122)

function SWEP:PrimaryAttack()

end

function SWEP:SecondaryAttack()

end

function SWEP:Think()
	local EyeTrace = self.Owner:GetEyeTrace()
	local ang = EyeTrace.Normal:Angle()
	
	ang.p = 0
	ang.y = ang.y + self:GetAngOffset() * 90
	ang.r = 0
	
	if self.EmplacementParts then
		local pos = EyeTrace.HitPos + self.ModelOffset
		local color = self:SpawnPosValid(EyeTrace) and COLOR_GREEN_ALPHA or COLOR_RED_ALPHA
		
		if IsValid(self.EmplacementParts["Hull"]) then
			self.EmplacementParts["Hull"]:SetPos(pos)
			self.EmplacementParts["Hull"]:SetColor(color)
			self.EmplacementParts["Hull"]:SetAngles(ang)
			
			if IsValid(self.EmplacementParts["Yaw"]) then
				self.EmplacementParts["Yaw"]:SetAngles(ang)
				self.EmplacementParts["Yaw"]:SetColor(color)
				self.EmplacementParts["Yaw"]:SetPos(self.EmplacementParts["Hull"]:LocalToWorld(self.EntTable.YawPos))
				
				if IsValid(self.EmplacementParts["Turret"]) then
					self.EmplacementParts["Turret"]:SetPos(self.EmplacementParts["Yaw"]:LocalToWorld(self.EntTable.TurretPos))
					self.EmplacementParts["Turret"]:SetColor(color)
					self.EmplacementParts["Turret"]:SetAngles(ang)
				end
				
				if IsValid(self.EmplacementParts["AimSight"]) then
					self.EmplacementParts["AimSight"]:SetPos(self.EmplacementParts["Yaw"]:LocalToWorld(self.EntTable.AimSightPos))
					self.EmplacementParts["AimSight"]:SetColor(color)
					self.EmplacementParts["AimSight"]:SetAngles(ang)
				end
			else
				if IsValid(self.EmplacementParts["Turret"]) then
					self.EmplacementParts["Turret"]:SetPos(self.EmplacementParts["Hull"]:LocalToWorld(self.EntTable.TurretPos))
					self.EmplacementParts["Turret"]:SetColor(color)
					self.EmplacementParts["Turret"]:SetAngles(ang)
				end
			end
			
			if IsValid(self.EmplacementParts["Wheels"]) then
				self.EmplacementParts["Wheels"]:SetPos(self.EmplacementParts["Hull"]:LocalToWorld(self.EntTable.WheelsPos))
				self.EmplacementParts["Wheels"]:SetColor(color)
				self.EmplacementParts["Wheels"]:SetAngles(ang)
			end
			
			if IsValid(self.EmplacementParts["Wheels2"]) then
				self.EmplacementParts["Wheels2"]:SetPos(self.EmplacementParts["Hull"]:LocalToWorld(self.EntTable.WheelsPos2))
				self.EmplacementParts["Wheels2"]:SetColor(color)
				self.EmplacementParts["Wheels2"]:SetAngles(ang)
			end
		end
	elseif IsValid(EyeTrace.Entity) then
		local ent
		
		if EyeTrace.Entity.Base == "gred_emp_base" then
			ent = EyeTrace.Entity
		elseif EyeTrace.Entity.GetClass and EyeTrace.Entity:GetClass() == "gred_prop_emp" then
			ent = GetBaseEmplacement(EyeTrace.Entity)
		end
		
		if IsValid(ent) and ent:GetPos():DistToSqr(EyeTrace.StartPos) <= self.MaxSpawnDistanceSqr and ent:GetNWFloat("BuildPercentage",100) >= 100 then
			if not ent.ToolEntities then
				BuildToolEntitiesTable(ent,ent:GetHull())
			end
			
			halo.Add(ent.ToolEntities,COLOR_GREEN)
		end
	end
end


function SWEP:SelectedEmplacementChanged()
	if self.EmplacementParts then
		for k,v in pairs(self.EmplacementParts) do
			if IsValid(v) then v:Remove() end
		end
		
	end
	
	self.EmplacementParts = nil
	self.EntTable = nil
	
	if self.SelectedEmplacement then
		self.EmplacementParts = {}
		
		local EntTable = scripted_ents.Get(self.SelectedEmplacement)
		local EyeTrace = self.Owner:GetEyeTrace()
		local ang = EyeTrace.Normal:Angle()
		
		ang.p = 0
		ang.r = 0
		
		local ent = ents.CreateClientProp()
		
		if EntTable.Base != "gred_emp_base" then
			ent:SetModel(EntTable.Model or "models/error.mdl")
			
			self.ModelOffset = ent:GetModelBounds()
			self.ModelOffset = Vector(0,0,math.abs(math.min(self.ModelOffset.z,0)))
			self.EntTable = EntTable
			EyeTrace.HitPos = EyeTrace.HitPos + self.ModelOffset
			
			ent:SetPos(EyeTrace.HitPos)
			ent:SetAngles(ang)
			ent:Spawn()
			
			self.EmplacementParts["Hull"] = ent
		else
			ent:SetModel(EntTable.HullModel)
			
			self.ModelOffset = ent:GetModelBounds()
			self.ModelOffset = Vector(0,0,math.abs(math.min(self.ModelOffset.z,0)))
			self.EntTable = EntTable
			EyeTrace.HitPos = EyeTrace.HitPos + self.ModelOffset
			
			ent:SetPos(EyeTrace.HitPos)
			ent:SetAngles(ang)
			ent:Spawn()
			
			self.EmplacementParts["Hull"] = ent
			
			local ent = ents.CreateClientProp()
			ent:SetModel(EntTable.TurretModel)
			ent:SetAngles(ang)
			ent:Spawn()
			
			self.EmplacementParts["Turret"] = ent
			
			if EntTable.YawModel then
				local ent = ents.CreateClientProp()
				ent:SetModel(EntTable.YawModel)
				ent:SetAngles(ang)
				ent:SetPos(self.EmplacementParts["Hull"]:LocalToWorld(EntTable.YawPos))
				ent:Spawn()
				
				self.EmplacementParts["Yaw"] = ent
				
				self.EmplacementParts["Turret"]:SetPos(ent:LocalToWorld(EntTable.TurretPos))
			else
				self.EmplacementParts["Turret"]:SetPos(self.EmplacementParts["Hull"]:LocalToWorld(EntTable.TurretPos))
			end
			
			if EntTable.WheelsModel then
				local ent = ents.CreateClientProp()
				ent:SetModel(EntTable.WheelsModel)
				ent:SetAngles(ang)
				ent:SetPos(self.EmplacementParts["Hull"]:LocalToWorld(EntTable.WheelsPos))
				ent:Spawn()
				
				self.EmplacementParts["Wheels"] = ent
			end
			
			if EntTable.WheelsModel2 then
				local ent = ents.CreateClientProp()
				ent:SetModel(EntTable.WheelsModel2)
				ent:SetAngles(ang)
				ent:SetPos(self.EmplacementParts["Hull"]:LocalToWorld(EntTable.WheelsPos2))
				ent:Spawn()
				
				self.EmplacementParts["Wheels2"] = ent
			end
			
			if EntTable.AimsightModel then
				local ent = ents.CreateClientProp()
				ent:SetModel(EntTable.AimsightModel)
				ent:SetAngles(ang)
				ent:SetPos(self.EmplacementParts["Yaw"]:LocalToWorld(EntTable.AimSightPos))
				ent:Spawn()
				
				self.EmplacementParts["AimSight"] = ent
			end
		end
	end
end