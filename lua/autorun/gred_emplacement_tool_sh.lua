gred = gred or {}
gred.EmplacementTool = gred.EmplacementTool or {}

function GetFormatedEmplacementNameInternal(NameToPrint,PrintName)
	return NameToPrint or string.Replace(PrintName,"[EMP]","")
end

function GetFormatedEmplacementName(ent)
	return GetFormatedEmplacementNameInternal(ent.NameToPrint,ent.PrintName)
end

function GetBaseEmplacement(ent,CheckedEntities)
	CheckedEntities = CheckedEntities or {}
	
	if CheckedEntities[ent] then return nil end
	CheckedEntities[ent] = true
	
	if ent.GetClass and ent:GetClass() == "gred_prop_emp" then
		for k,v in pairs(ent:GetChildren()) do
			if not CheckedEntities[v] then
				if v.Base == "gred_emp_base" then
					return v
				elseif v.GetClass and v:GetClass() == "gred_prop_emp" then
					local Child = GetBaseEmplacement(v,CheckedEntities)
					
					if IsValid(Child) then
						return Child
					end
				end
			end
		end
	end
	local parent = ent:GetParent()
	
	if IsValid(parent) and not CheckedEntities[parent] then
		if parent.Base == "gred_emp_base" then
			return parent
		elseif parent.GetClass and parent:GetClass() == "gred_prop_emp" then
			return GetBaseEmplacement(parent,CheckedEntities)
		end
	end
	
	return nil
end

function BuildToolEntitiesTable(BaseEnt,ent)
	BaseEnt.ToolEntities = BaseEnt.ToolEntities or {}
	
	table.insert(BaseEnt.ToolEntities,ent)
	
	for k,v in pairs(ent:GetChildren()) do
		if IsValid(v) and (v:GetClass() == "gred_prop_emp" or v.Base == "gred_emp_base") then
			BuildToolEntitiesTable(BaseEnt,v)
		end
	end
end

local LowCaliber = {
	["wac_base_7mm"] = true,
	["wac_base_12mm"] = true,
}

local BlacklistedClasses = {
	["gred_emp_base"] = true,
	["gred_emp_m61"] = true,
}

gred.GetEmplacementList = function() -- this sorting is necessary so the server and clients get the same IDs
	local OutList = {
		[1] = {
			Name = "Machineguns",
			Tab = {},
		},
		[2] = {
			Name = "Autocannons / AAA",
			Tab = {},
		},
		[3] = {
			Name = "Cannons",
			Tab = {},
		},
		[4] = {
			Name = "Mortars",
			Tab = {},
		},
		[5] = {
			Name = "Others",
			Tab = {},
		},
	}
	
	local EmplacementType
	local EmplacementList = {}

	for k,v in pairs(scripted_ents.GetList()) do
		if v.Base == "gred_emp_base" and v.t.ClassName and not BlacklistedClasses[v.t.ClassName] then
			EmplacementList[v.t.ClassName] = v.t
		elseif gred.EmplacementTool.AdditionalEntities[v.t.ClassName] then
			local tab = {}
			tab.ClassName = v.t.ClassName
			tab.Name = gred.EmplacementTool.AdditionalEntities[v.t.ClassName]
			
			table.insert(OutList[5].Tab,tab)
		end
	end
	
	for k,v in SortedPairs(EmplacementList) do
		if v.EmplacementType == "MG" then
			if v.AmmunitionTypes and LowCaliber[v.AmmunitionTypes[1][2]] or LowCaliber[v.AmmunitionType or ""] then
				EmplacementType = 1
			else
				EmplacementType = 2
			end
		elseif v.EmplacementType == "Cannon" then
			EmplacementType = 3
		elseif v.EmplacementType == "Mortar" then
			EmplacementType = 4
		else
			EmplacementType = 5
		end
		
		local tab = {}
		tab.ClassName = v.ClassName
		tab.Name = GetFormatedEmplacementNameInternal(v.NameToPrint,v.PrintName)
		
		table.insert(OutList[EmplacementType].Tab,tab)
	end
	
	return OutList
end

-- gred.GetEmplacementList()