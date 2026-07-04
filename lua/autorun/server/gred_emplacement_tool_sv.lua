
util.AddNetworkString("gred_net_emplacementtool_menu")
util.AddNetworkString("gred_net_emplacementtool_selectemplacement")
util.AddNetworkString("gred_net_emplacementtool_selectedemplacement")
util.AddNetworkString("gred_net_emplacementtool_clearselectedemplacement")
util.AddNetworkString("gred_net_emplacementtool_spawnemplacement")
util.AddNetworkString("gred_net_emplacementtool_emplacementspawned")
util.AddNetworkString("gred_net_emplacementtool_edit")
util.AddNetworkString("gred_net_emplacementtool_togglemotion")
util.AddNetworkString("gred_net_emplacementtool_remove")

net.Receive("gred_net_emplacementtool_selectemplacement",function(len,ply)
	local EmplacementType = net.ReadUInt(3)
	local EmplacementID = net.ReadUInt(5)
	
	local Weapon = ply:GetActiveWeapon()
	
	if not IsValid(Weapon) or not Weapon.GetClass or Weapon:GetClass() != "gred_emp_tool" then return end
	
	local EmplacementList = gred.GetEmplacementList()
	
	if not EmplacementList or not EmplacementList or not EmplacementList[EmplacementType].Tab or not EmplacementList[EmplacementType].Tab[EmplacementID] or not EmplacementList[EmplacementType].Tab[EmplacementID].ClassName then return end
	
	local Team = ply:Team()
	
	if gred.EmplacementTool.TeamWhiteList and gred.EmplacementTool.TeamWhiteList[Team] and not gred.EmplacementTool.TeamWhiteList[Team][EmplacementList[EmplacementType].Tab[EmplacementID].ClassName] then return end
	if gred.EmplacementTool.TeamBlackList and gred.EmplacementTool.TeamBlackList[Team] and gred.EmplacementTool.TeamBlackList[Team][EmplacementList[EmplacementType].Tab[EmplacementID].ClassName] then return end
	
	Weapon.SelectedEmplacement = EmplacementList[EmplacementType].Tab[EmplacementID].ClassName
	
	net.Start("gred_net_emplacementtool_selectedemplacement")
		-- net.WriteUInt(EmplacementType,3) -- idk if we really need this
		-- net.WriteUInt(EmplacementID,5)
	net.Send(Weapon.Owner)
end)

net.Receive("gred_net_emplacementtool_clearselectedemplacement",function(len,ply)
	local Weapon = ply:GetActiveWeapon()
	
	if not IsValid(Weapon) or not Weapon.GetClass or Weapon:GetClass() != "gred_emp_tool" then return end
	
	Weapon.SelectedEmplacement = nil
end)

net.Receive("gred_net_emplacementtool_togglemotion",function(len,ply)
	local Weapon = ply:GetActiveWeapon()
	
	if not IsValid(Weapon) or not Weapon.GetClass or Weapon:GetClass() != "gred_emp_tool" then return end
	
	local EyeTrace = ply:GetEyeTrace()
	
	if not IsValid(EyeTrace.Entity) then return end
	
	local ent
	
	if EyeTrace.Entity.Base == "gred_emp_base" then
		ent = EyeTrace.Entity
	elseif EyeTrace.Entity.GetClass and EyeTrace.Entity:GetClass() == "gred_prop_emp" then
		ent = GetBaseEmplacement(EyeTrace.Entity)
	end
	
	if not IsValid(ent) or ent:GetPos():DistToSqr(EyeTrace.StartPos) > Weapon.MaxSpawnDistanceSqr or ent:GetNWFloat("BuildPercentage",100) < 100 then return end
	
	local phys = ent:GetHull():GetPhysicsObject()
	
	if not IsValid(phys) then return end
	
	phys:EnableMotion(not phys:IsMotionEnabled())
	phys:Wake()
end)

net.Receive("gred_net_emplacementtool_remove",function(len,ply)
	local Weapon = ply:GetActiveWeapon()
	
	if not IsValid(Weapon) or not Weapon.GetClass or Weapon:GetClass() != "gred_emp_tool" then return end
	
	local EyeTrace = ply:GetEyeTrace()
	
	if not IsValid(EyeTrace.Entity) then return end
	
	local ent
	
	if EyeTrace.Entity.Base == "gred_emp_base" then
		ent = EyeTrace.Entity
	elseif EyeTrace.Entity.GetClass and EyeTrace.Entity:GetClass() == "gred_prop_emp" then
		ent = GetBaseEmplacement(EyeTrace.Entity)
	end
	
	if not IsValid(ent) or ent:GetPos():DistToSqr(EyeTrace.StartPos) > Weapon.MaxSpawnDistanceSqr or ent:GetNWFloat("BuildPercentage",100) < 100 then return end
	
	ent:EmitSound("garrysmod/balloon_pop_cute.wav")
	ent:Remove()
end)