
surface.CreateFont("EmplacementToolBuildPercentage",{
	font 		= "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended 	= false,
	size 		= (ScrW()*0.01 + ScrH()*0.01) * 3,
	weight 		= 500,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= true,
	underline 	= false,
	italic 		= false,
	strikeout 	= false,
	symbol 		= false,
	rotary 		= false,
	shadow 		= true,
	additive 	= false,
	outline 	= false,
})

local function UpdateEntityColors(ent,newval)
	if not ent.ToolEntities then return end
	
	local val = math.Clamp(newval,0,100) / 100
	local color = Color(255,255*val,255*val,255*val)
	
	for k,v in pairs(ent.ToolEntities) do
		if IsValid(v) then
			v:SetColor(color)
		end
	end
end

net.Receive("gred_net_emplacementtool_emplacementspawned",function()
	local ent = net.ReadEntity()
	
	if !IsValid(ent) then return end
	
	ent.ToolEntities = {}
	
	local HookName = "gred_HUDPaint_"..tostring(ent)
	local MaxDistSqr = 500^2
	local pos
	local ply = LocalPlayer()
	
	hook.Add("HUDPaint",HookName,function()
		if not IsValid(ent) then hook.Remove("HUDPaint",HookName) return end
		pos = ent:GetPos()
		
		if ply:GetPos():DistToSqr(pos) > MaxDistSqr then return end
		
		pos = pos:ToScreen()
		
		surface.SetTextColor(255,255,255,255)
		surface.SetFont("EmplacementToolBuildPercentage")
		surface.SetTextPos(pos.x,pos.y)
		surface.DrawText(math.Round(ent:GetNWFloat("BuildPercentage",0),2).."%")
		
	end)
	
	ent:SetNWVarProxy("BuildPercentage",function(ent,name,oldval,newval)
		UpdateEntityColors(ent,newval)
		
		if newval >= 100 then
			hook.Remove("HUDPaint",HookName)
		end
	end)
	
	
	timer.Simple(0.1,function()
		if !IsValid(ent) then return end
		
		if ent.GetHull then
			local hull = ent:GetHull()
			
			if IsValid(hull) then
				BuildToolEntitiesTable(ent,hull)
			end
			
			-- for k,v in pairs(ent.ToolEntities) do
				-- v.DrawTranslucent = function(v)
					-- v:DrawModel()
				-- end
			-- end
		else
			ent.ToolEntities = {ent}
		end
		
		UpdateEntityColors(ent,ent:GetNWFloat("BuildPercentage",0))
	end)
end)

net.Receive("gred_net_emplacementtool_selectedemplacement",function()
	local Weapon = LocalPlayer():GetActiveWeapon()
	
	if not IsValid(Weapon) or not Weapon.GetClass or Weapon:GetClass() != "gred_emp_tool" then return end
	
	if not Weapon.LastSelectedEmplacement then
		Weapon.SelectedEmplacement = nil
		Weapon.LastSelectedEmplacement = nil
		
		net.Start("gred_net_emplacementtool_clearselectedemplacement")
		net.SendToServer()
	else
		Weapon.SelectedEmplacement = Weapon.LastSelectedEmplacement
	end
	
	Weapon:SelectedEmplacementChanged()
end)

net.Receive("gred_net_emplacementtool_spawnemplacement",function()
	local Weapon = LocalPlayer():GetActiveWeapon()
	
	if not IsValid(Weapon) or not Weapon.GetClass or Weapon:GetClass() != "gred_emp_tool" then return end
	
	Weapon.SelectedEmplacement = nil
	Weapon.LastSelectedEmplacement = nil
	
	Weapon:SelectedEmplacementChanged()
end)

net.Receive("gred_net_emplacementtool_menu",function()
	local Weapon = LocalPlayer():GetActiveWeapon()
	
	if not IsValid(Weapon) or not Weapon.GetClass or Weapon:GetClass() != "gred_emp_tool" then return end
	
	local X,Y = ScrW()*0.3,ScrH()*0.8
	local EmplacementList = gred.GetEmplacementList()
	local Team = LocalPlayer():Team()
	
	local DFrame = vgui.Create("DFrame")
	DFrame:SetSize(X,Y)
	DFrame:Center()
	DFrame:MakePopup()
	DFrame:SetTitle("Éléments constructibles")
	
	local DCategoryList = vgui.Create("DCategoryList",DFrame)
	DCategoryList:Dock(FILL)
	
	for k,v in SortedPairsByMemberValue(EmplacementList,"Name") do
		if #v.Tab < 1 then continue end
		
		local DCollapsibleCategory = DCategoryList:Add(v.Name)
		
		for EmplacementID,EmplacementTab in SortedPairsByMemberValue(v.Tab,"Name") do
			if gred.EmplacementTool.TeamWhiteList and (not gred.EmplacementTool.TeamWhiteList[Team] or not gred.EmplacementTool.TeamWhiteList[Team][EmplacementTab.ClassName]) then continue end
			if gred.EmplacementTool.TeamBlackList and gred.EmplacementTool.TeamBlackList[Team] and gred.EmplacementTool.TeamBlackList[Team][EmplacementTab.ClassName] then continue end
			
			local DButton = DCollapsibleCategory:Add(EmplacementTab.Name)
			
			DButton.DoClick = function()
				net.Start("gred_net_emplacementtool_selectemplacement")
					net.WriteUInt(k,3)
					net.WriteUInt(EmplacementID,5)
				net.SendToServer()
				
				Weapon.LastSelectedEmplacement = EmplacementTab.ClassName
				
				DFrame:Remove()
			end
		end
		
		if #DCollapsibleCategory:GetChildren() <= 1 then
			DCollapsibleCategory:Remove()
		end
	end
end)

net.Receive("gred_net_emplacementtool_edit",function()
	local Weapon = LocalPlayer():GetActiveWeapon()
	
	if not IsValid(Weapon) or not Weapon.GetClass or Weapon:GetClass() != "gred_emp_tool" then return end
	
	local EyeTrace = LocalPlayer():GetEyeTrace()
	
	if not IsValid(EyeTrace.Entity) then return end
	
	local ent
	
	if EyeTrace.Entity.Base == "gred_emp_base" then
		ent = EyeTrace.Entity
	elseif EyeTrace.Entity.GetClass and EyeTrace.Entity:GetClass() == "gred_prop_emp" then
		ent = GetBaseEmplacement(EyeTrace.Entity)
	end
	
	if not IsValid(ent) or ent:GetPos():DistToSqr(EyeTrace.StartPos) > Weapon.MaxSpawnDistanceSqr or ent:GetNWFloat("BuildPercentage",100) < 100 then return end
	
	local phys = ent:GetHull():GetPhysicsObject()
	
	local X,Y = 250,150
	local DFrame = vgui.Create("DFrame")
	DFrame:SetSize(X,Y)
	DFrame:Center()
	DFrame:SetTitle("Modifier "..GetFormatedEmplacementName(ent))
	DFrame:MakePopup()
	
	local DScrollPanel = vgui.Create("DScrollPanel",DFrame)
	DScrollPanel:Dock(FILL)
	
	local DButton = DScrollPanel:Add("DButton")
	DButton:Dock(TOP)
	DButton:DockMargin(0,0,0,5)
	DButton:SetText(IsValid(phys) and (phys:IsMotionEnabled() and "Geler" or "Dégeler") or "Geler / Dégeler")
	DButton.DoClick = function()
		DFrame:Remove()
		
		net.Start("gred_net_emplacementtool_togglemotion")
		net.SendToServer()
	end
	
	local DButton = DScrollPanel:Add("DButton")
	DButton:Dock(TOP)
	DButton:DockMargin(0,0,0,5)
	DButton:SetText("Retirer")
	DButton.DoClick = function()
		DFrame:Remove()
		
		net.Start("gred_net_emplacementtool_remove")
		net.SendToServer()
	end
end)