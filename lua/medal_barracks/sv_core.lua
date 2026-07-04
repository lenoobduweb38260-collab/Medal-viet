MedalBarracks = MedalBarracks or {}
MedalBarracks.Selected = MedalBarracks.Selected or {}
MedalBarracks.PlayerCamp = MedalBarracks.PlayerCamp or {}
MedalBarracks.PlayerCharacters = MedalBarracks.PlayerCharacters or {}
MedalBarracks.PlayerXP = MedalBarracks.PlayerXP or {}
MedalBarracks.InMenu = MedalBarracks.InMenu or {}

util.AddNetworkString("MedalBarracks_Select")
util.AddNetworkString("MedalBarracks_Result")
util.AddNetworkString("MedalBarracks_SelectCamp")
util.AddNetworkString("MedalBarracks_CampResult")
util.AddNetworkString("MedalBarracks_OpenCampSelection")
util.AddNetworkString("MedalBarracks_OpenBarracks")
util.AddNetworkString("MedalBarracks_OpenMainMenu")
util.AddNetworkString("MedalBarracks_OpenCharacterSelection")
util.AddNetworkString("MedalBarracks_RequestCharacters")
util.AddNetworkString("MedalBarracks_Characters")
util.AddNetworkString("MedalBarracks_CreateCharacter")
util.AddNetworkString("MedalBarracks_UpdateCharacter")
util.AddNetworkString("MedalBarracks_CharacterResult")
util.AddNetworkString("MedalBarracks_RemoteMediaReload")
util.AddNetworkString("MedalBarracks_XPNotify")
util.AddNetworkString("MedalBarracks_StaffRequestCharacters")
util.AddNetworkString("MedalBarracks_StaffCharacters")
util.AddNetworkString("MedalBarracks_StaffDeleteCharacter")
util.AddNetworkString("MedalBarracks_StaffSaveCharacter")

local cfg = MedalBarracks.Config

local function notify(ply, ok, msg)
    if not IsValid(ply) then return end
    net.Start("MedalBarracks_Result")
        net.WriteBool(ok)
        net.WriteString(msg or "")
    net.Send(ply)
end

local function notifyCamp(ply, ok, msg, armyID)
    if not IsValid(ply) then return end
    net.Start("MedalBarracks_CampResult")
        net.WriteBool(ok)
        net.WriteString(msg or "")
        net.WriteString(armyID or "")
    net.Send(ply)
end

local function notifyCharacter(ply, ok, msg, armyID)
    if not IsValid(ply) then return end
    net.Start("MedalBarracks_CharacterResult")
        net.WriteBool(ok)
        net.WriteString(msg or "")
        net.WriteString(armyID or "")
    net.Send(ply)
end

local function lower(str)
    return string.Trim(string.lower(tostring(str or "")))
end

local function campCfg()
    return cfg.CampSelection or {}
end

local function charCfg()
    return cfg.CharacterCreation or cfg.CharacterLimit or {}
end

local function xpCfg()
    return cfg.XP or {}
end

local function xpGeneralCfg()
    local xpc = xpCfg()
    return xpc.General or {}
end

local function xpRoleCfg()
    local xpc = xpCfg()
    return xpc.Role or {}
end

local function xpEnabled()
    local xpc = xpCfg()
    return xpc.Enabled ~= false
end

local function steamKey(ply)
    if not IsValid(ply) then return "" end
    local sid64 = ply:SteamID64()
    if sid64 and sid64 ~= "0" then return sid64 end
    return ply:SteamID()
end

local function spawnGateCfg()
    return cfg.SpawnGate or {}
end

local function hasSelectedRole(ply)
    return MedalBarracks.Selected[steamKey(ply)] ~= nil
end

function MedalBarracks.SetMenuState(ply, inMenu)
    if not IsValid(ply) then return end
    local gate = spawnGateCfg()
    if gate.Enabled == false then return end
    local key = steamKey(ply)
    MedalBarracks.InMenu[key] = inMenu == true or nil
    ply:SetNWBool("MedalBarracks_InMenu", inMenu == true)

    if inMenu == true then
        if hasSelectedRole(ply) then return end
        timer.Simple(0, function()
            if not IsValid(ply) or hasSelectedRole(ply) == true then return end
            if gate.StripWeaponsWhileInMenu ~= false then ply:StripWeapons() end
            ply:Freeze(true)
            if ply.Lock then ply:Lock() end
            if gate.GodWhileInMenu ~= false and ply.GodEnable then ply:GodEnable() end
            if gate.HidePlayerWhileInMenu ~= false then
                ply:SetNoDraw(true)
                ply:SetNotSolid(true)
            end
            if gate.SpectateWhileInMenu ~= false and ply.Spectate then
                ply:Spectate(OBS_MODE_ROAMING)
            end
        end)
    else
        if ply.UnSpectate then ply:UnSpectate() end
        ply:SetNoDraw(false)
        ply:SetNotSolid(false)
        ply:Freeze(false)
        if ply.UnLock then ply:UnLock() end
        if ply.GodDisable then ply:GodDisable() end
    end
end


local function isStaff(ply)
    if not IsValid(ply) then return true end
    local sm = cfg.StaffMenu or {}
    local min = tostring(sm.MinAccess or "admin")
    if min == "superadmin" then return ply:IsSuperAdmin() end
    return ply:IsAdmin() or ply:IsSuperAdmin()
end

local function clampText(str, maxLen)
    str = string.Trim(tostring(str or ""))
    maxLen = tonumber(maxLen) or 64
    if #str > maxLen then str = string.sub(str, 1, maxLen) end
    return str
end

local function sqlstr(v)
    return sql.SQLStr(tostring(v or ""))
end

function MedalBarracks.InitDB()
    local cc = charCfg()
    local tableName = cc.SQLTable or "medal_barracks_characters"
    sql.Query("CREATE TABLE IF NOT EXISTS " .. tableName .. " (steamid64 TEXT NOT NULL, steamid TEXT, army TEXT NOT NULL, first_name TEXT, last_name TEXT, age INTEGER, nationality TEXT, description TEXT, model TEXT, role TEXT, loadout TEXT, created INTEGER, updated INTEGER, PRIMARY KEY(steamid64, army))")
    -- Migration douce : colonnes taille (cm) et genre, ignorées si déjà présentes.
    sql.Query("ALTER TABLE " .. tableName .. " ADD COLUMN size INTEGER")
    sql.Query("ALTER TABLE " .. tableName .. " ADD COLUMN gender TEXT")

    local xpc = xpCfg()
    if xpc.Enabled ~= false and xpc.SaveInSQLite ~= false then
        local xpTable = xpc.SQLTable or "medal_barracks_xp"
        sql.Query("CREATE TABLE IF NOT EXISTS " .. xpTable .. " (steamid64 TEXT NOT NULL, steamid TEXT, xp_type TEXT NOT NULL, army TEXT NOT NULL, role TEXT NOT NULL, xp INTEGER, level INTEGER, updated INTEGER, PRIMARY KEY(steamid64, xp_type, army, role))")
    end

    local rel = cfg.Relations or {}
    if rel.Enabled ~= false then
        local relTable = rel.SQLTable or "medal_barracks_relations"
        sql.Query("CREATE TABLE IF NOT EXISTS " .. relTable .. " (a TEXT NOT NULL, b TEXT NOT NULL, created INTEGER, PRIMARY KEY(a, b))")
    end
end
hook.Add("Initialize", "MedalBarracks_InitDB", MedalBarracks.InitDB)
MedalBarracks.InitDB()


-- =========================
-- XP générale / XP de rôle
-- =========================
local function xpKey(armyID, roleID)
    return tostring(armyID or "") .. ":" .. tostring(roleID or "")
end

local function getXPData(ply)
    if not IsValid(ply) then return nil end
    local key = steamKey(ply)
    MedalBarracks.PlayerXP[key] = MedalBarracks.PlayerXP[key] or {general = {level = 1, xp = 0}, roles = {}}
    MedalBarracks.PlayerXP[key].general = MedalBarracks.PlayerXP[key].general or {level = 1, xp = 0}
    MedalBarracks.PlayerXP[key].roles = MedalBarracks.PlayerXP[key].roles or {}
    return MedalBarracks.PlayerXP[key]
end

local function generalNeed(level)
    if cfg.GetGeneralXPRequired then return math.max(1, tonumber(cfg.GetGeneralXPRequired(level)) or 1) end
    local g = xpGeneralCfg()
    return math.floor((tonumber(g.BaseNextXP) or 350) * ((tonumber(g.Growth) or 1.16) ^ ((tonumber(level) or 1) - 1)))
end

local function roleNeed(level)
    if cfg.GetRoleXPRequired then return math.max(1, tonumber(cfg.GetRoleXPRequired(level)) or 1) end
    local r = xpRoleCfg()
    return math.floor((tonumber(r.BaseNextXP) or 60) * ((tonumber(r.Growth) or 1.35) ^ ((tonumber(level) or 1) - 1)))
end

local function saveXPRow(ply, xpType, armyID, roleID, level, xp)
    if not IsValid(ply) or not xpEnabled() or xpCfg().SaveInSQLite == false then return end
    MedalBarracks.InitDB()
    local tableName = xpCfg().SQLTable or "medal_barracks_xp"
    local q = "INSERT OR REPLACE INTO " .. tableName .. " (steamid64, steamid, xp_type, army, role, xp, level, updated) VALUES (" ..
        sqlstr(steamKey(ply)) .. ", " ..
        sqlstr(ply:SteamID()) .. ", " ..
        sqlstr(xpType or "general") .. ", " ..
        sqlstr(armyID or "") .. ", " ..
        sqlstr(roleID or "") .. ", " ..
        tostring(math.max(tonumber(xp) or 0, 0)) .. ", " ..
        tostring(math.max(tonumber(level) or 1, 1)) .. ", " ..
        tostring(os.time()) .. ")"
    local res = sql.Query(q)
    if res == false then ErrorNoHalt("[MedalBarracks] SQL XP error: " .. tostring(sql.LastError()) .. "\n") end
end

function MedalBarracks.UpdateXPNW(ply)
    if not IsValid(ply) then return end
    local data = getXPData(ply)
    if not data then return end

    local g = data.general or {level = 1, xp = 0}
    ply:SetNWInt(cfg.LevelNWInt or "medal_level", tonumber(g.level) or 1)
    ply:SetNWInt(cfg.XPNWInt or "medal_xp", tonumber(g.xp) or 0)
    ply:SetNWInt(cfg.NextXPNWInt or "medal_next_xp", generalNeed(tonumber(g.level) or 1))

    local lvlPrefix = cfg.RoleLevelNWIntPrefix or "medal_role_level_"
    local xpPrefix = cfg.RoleXPNWIntPrefix or "medal_role_xp_"
    local nextPrefix = cfg.RoleNextXPNWIntPrefix or "medal_role_next_xp_"

    -- On pose d'abord les valeurs par défaut pour tous les rôles connus.
    -- Ça évite qu'un ancien NWInt reste affiché après un reset XP.
    for _, army in ipairs(MedalBarracks.GetArmies and MedalBarracks.GetArmies() or {}) do
        for _, cat in ipairs(army.categories or {}) do
            for _, role in ipairs(cat.roles or {}) do
                local nwSuffix = tostring(army.id or "") .. "_" .. tostring(role.id or "")
                local defaultLvl = tonumber(role.defaultRoleLevel) or cfg.DefaultRoleLevel or 1
                ply:SetNWInt(lvlPrefix .. nwSuffix, defaultLvl)
                ply:SetNWInt(xpPrefix .. nwSuffix, 0)
                ply:SetNWInt(nextPrefix .. nwSuffix, roleNeed(defaultLvl))
            end
        end
    end

    for key, r in pairs(data.roles or {}) do
        if r.army and r.role then
            local nwSuffix = tostring(r.army) .. "_" .. tostring(r.role)
            ply:SetNWInt(lvlPrefix .. nwSuffix, tonumber(r.level) or 1)
            ply:SetNWInt(xpPrefix .. nwSuffix, tonumber(r.xp) or 0)
            ply:SetNWInt(nextPrefix .. nwSuffix, roleNeed(tonumber(r.level) or 1))
        end
    end
end

function MedalBarracks.LoadXP(ply)
    if not IsValid(ply) then return end
    if not xpEnabled() then return end
    MedalBarracks.InitDB()
    local data = getXPData(ply)
    data.general = {level = 1, xp = 0}
    data.roles = {}

    if xpCfg().SaveInSQLite ~= false then
        local tableName = xpCfg().SQLTable or "medal_barracks_xp"
        local rows = sql.Query("SELECT * FROM " .. tableName .. " WHERE steamid64 = " .. sqlstr(steamKey(ply)))
        if istable(rows) then
            for _, row in ipairs(rows) do
                local kind = tostring(row.xp_type or "")
                local level = math.max(tonumber(row.level) or 1, 1)
                local xp = math.max(tonumber(row.xp) or 0, 0)
                if kind == "general" then
                    data.general = {level = level, xp = xp}
                elseif kind == "role" then
                    local armyID = tostring(row.army or "")
                    local roleID = tostring(row.role or "")
                    if armyID ~= "" and roleID ~= "" then
                        data.roles[xpKey(armyID, roleID)] = {army = armyID, role = roleID, level = level, xp = xp}
                    end
                end
            end
        end
    end

    MedalBarracks.UpdateXPNW(ply)
end

local function sendXPNotify(ply, kind, amount, oldLevel, newLevel, armyID, roleID, reason)
    if not IsValid(ply) then return end
    net.Start("MedalBarracks_XPNotify")
        net.WriteString(kind or "general")
        net.WriteInt(math.floor(tonumber(amount) or 0), 32)
        net.WriteUInt(math.max(tonumber(oldLevel) or 1, 1), 16)
        net.WriteUInt(math.max(tonumber(newLevel) or 1, 1), 16)
        net.WriteString(armyID or "")
        net.WriteString(roleID or "")
        net.WriteString(reason or "")
    net.Send(ply)
end

function MedalBarracks.AddGeneralXP(ply, amount, reason)
    if not IsValid(ply) or not xpEnabled() or xpGeneralCfg().Enabled == false then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local data = getXPData(ply)
    local g = data.general or {level = 1, xp = 0}
    local maxLevel = tonumber(xpGeneralCfg().MaxLevel) or 100
    local oldLevel = tonumber(g.level) or 1

    if oldLevel >= maxLevel then
        g.level = maxLevel
        g.xp = 0
        data.general = g
        MedalBarracks.UpdateXPNW(ply)
        return false
    end

    g.xp = (tonumber(g.xp) or 0) + amount
    g.level = oldLevel
    while g.level < maxLevel and g.xp >= generalNeed(g.level) do
        g.xp = g.xp - generalNeed(g.level)
        g.level = g.level + 1
    end

    data.general = g
    saveXPRow(ply, "general", "", "", g.level, g.xp)
    MedalBarracks.UpdateXPNW(ply)

    if xpGeneralCfg().Notify ~= false then
        sendXPNotify(ply, "general", amount, oldLevel, g.level, "", "", reason or "passive")
    end
    return true, g.level > oldLevel
end

function MedalBarracks.AddRoleXP(ply, armyID, roleID, amount, reason)
    if not IsValid(ply) or not xpEnabled() or xpRoleCfg().Enabled == false then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    armyID = tostring(armyID or "")
    roleID = tostring(roleID or "")
    if armyID == "" or roleID == "" then return false end

    local role = MedalBarracks.GetRole(armyID, "", roleID)
    -- GetRole demande une catégorie, donc on fait une recherche simple si nécessaire.
    if not role then
        local army = MedalBarracks.GetArmy(armyID)
        if army then
            for _, cat in ipairs(army.categories or {}) do
                for _, r in ipairs(cat.roles or {}) do
                    if r.id == roleID then
                        role = r
                        break
                    end
                end
                if role then break end
            end
        end
    end

    local data = getXPData(ply)
    local key = xpKey(armyID, roleID)
    local rdata = data.roles[key] or {army = armyID, role = roleID, level = tonumber(role and role.defaultRoleLevel) or cfg.DefaultRoleLevel or 1, xp = 0}
    local maxLevel = tonumber(role and role.maxLevel) or tonumber(xpRoleCfg().MaxLevel) or tonumber(cfg.MaxRoleLevel) or 8
    local oldLevel = tonumber(rdata.level) or 1

    if oldLevel >= maxLevel then
        rdata.level = maxLevel
        rdata.xp = 0
        data.roles[key] = rdata
        MedalBarracks.UpdateXPNW(ply)
        return false
    end

    rdata.xp = (tonumber(rdata.xp) or 0) + amount
    rdata.level = oldLevel
    while rdata.level < maxLevel and rdata.xp >= roleNeed(rdata.level) do
        rdata.xp = rdata.xp - roleNeed(rdata.level)
        rdata.level = rdata.level + 1
    end

    data.roles[key] = rdata
    saveXPRow(ply, "role", armyID, roleID, rdata.level, rdata.xp)
    MedalBarracks.UpdateXPNW(ply)

    if xpRoleCfg().Notify ~= false then
        sendXPNotify(ply, "role", amount, oldLevel, rdata.level, armyID, roleID, reason or "kill")
    end
    return true, rdata.level > oldLevel
end

function MedalBarracks.AddSelectedRoleXP(ply, amount, reason)
    if not IsValid(ply) then return false end
    local selected = MedalBarracks.Selected[steamKey(ply)]
    if not selected or not selected.army or not selected.role then return false end
    return MedalBarracks.AddRoleXP(ply, selected.army, selected.role, amount, reason)
end

local function startPassiveXPTimer()
    if not xpEnabled() or xpGeneralCfg().Enabled == false then return end
    local interval = math.max(tonumber(xpGeneralCfg().Interval) or 300, 60)
    timer.Remove("MedalBarracks_PassiveGeneralXP")
    timer.Create("MedalBarracks_PassiveGeneralXP", interval, 0, function()
        if not xpEnabled() or xpGeneralCfg().Enabled == false then return end
        local amount = tonumber(xpGeneralCfg().Amount) or 25
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                if xpGeneralCfg().RequireRoleSelected ~= true or MedalBarracks.Selected[steamKey(ply)] then
                    MedalBarracks.AddGeneralXP(ply, amount, "service")
                end
            end
        end
    end)
end
hook.Add("Initialize", "MedalBarracks_StartPassiveXP", function() timer.Simple(1, startPassiveXPTimer) end)
timer.Simple(1, startPassiveXPTimer)

function MedalBarracks.SendMainMenu(ply)
    if not IsValid(ply) then return end
    if not hasSelectedRole(ply) then MedalBarracks.SetMenuState(ply, true) end
    net.Start("MedalBarracks_OpenMainMenu")
    net.Send(ply)
end

function MedalBarracks.SendCampSelection(ply)
    if not IsValid(ply) then return end
    if not hasSelectedRole(ply) then MedalBarracks.SetMenuState(ply, true) end
    net.Start("MedalBarracks_OpenCampSelection")
    net.Send(ply)
end

function MedalBarracks.SendCharacterSelection(ply, armyID)
    if not IsValid(ply) then return end
    if not hasSelectedRole(ply) then MedalBarracks.SetMenuState(ply, true) end
    net.Start("MedalBarracks_OpenCharacterSelection")
        net.WriteString(armyID or MedalBarracks.GetPlayerCamp(ply) or "")
    net.Send(ply)
end

function MedalBarracks.SendBarracks(ply, armyID)
    if not IsValid(ply) then return end
    if not hasSelectedRole(ply) then MedalBarracks.SetMenuState(ply, true) end
    net.Start("MedalBarracks_OpenBarracks")
        net.WriteString(armyID or MedalBarracks.GetPlayerCamp(ply) or "")
    net.Send(ply)
end

function MedalBarracks.GetPlayerCamp(ply)
    if not IsValid(ply) then return "" end
    local key = steamKey(ply)
    return MedalBarracks.PlayerCamp[key] or ply:GetNWString("MedalBarracks_ArmyChoice", "")
end

function MedalBarracks.SetPlayerCamp(ply, armyID)
    if not IsValid(ply) then return end
    armyID = tostring(armyID or "")
    local key = steamKey(ply)
    MedalBarracks.PlayerCamp[key] = armyID
    ply:SetNWString("MedalBarracks_ArmyChoice", armyID)

    if campCfg().RememberWithPData then
        ply:SetPData("MedalBarracks_ArmyChoice", armyID)
    end

    timer.Simple(0, function() if MedalBarracks.BroadcastCampCounts then MedalBarracks.BroadcastCampCounts() end end)
end


local function campBalanceCfg()
    return cfg.CampBalance or {}
end

function MedalBarracks.GetCampCounts()
    local counts = {}
    for _, army in ipairs(MedalBarracks.GetArmies()) do counts[army.id] = 0 end

    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) then
            local armyID = MedalBarracks.GetPlayerCamp(ply)
            if counts[armyID] ~= nil then counts[armyID] = counts[armyID] + 1 end
        end
    end

    return counts
end

function MedalBarracks.BroadcastCampCounts()
    local b = campBalanceCfg()
    local max = tonumber(b.MaxPlayersPerFaction) or 60
    local tolerance = tonumber(b.Tolerance) or 2
    local counts = MedalBarracks.GetCampCounts()

    SetGlobalInt("MedalBarracks_MaxPlayersPerFaction", max)
    SetGlobalInt("MedalBarracks_CampTolerance", tolerance)

    for _, army in ipairs(MedalBarracks.GetArmies()) do
        SetGlobalInt("MedalBarracks_Count_" .. tostring(army.id), counts[army.id] or 0)
    end
end

function MedalBarracks.CanJoinCamp(ply, armyID)
    local b = campBalanceCfg()
    if b.Enabled == false then return true, "" end
    if not IsValid(ply) then return false, "Joueur invalide." end
    if not MedalBarracks.GetArmy(armyID) then return false, "Faction introuvable." end

    local current = MedalBarracks.GetPlayerCamp(ply)
    if current == armyID then return true, "" end

    local max = tonumber(b.MaxPlayersPerFaction) or 60
    local tolerance = tonumber(b.Tolerance) or 2
    local counts = MedalBarracks.GetCampCounts()

    if current ~= "" and counts[current] then counts[current] = math.max(0, counts[current] - 1) end
    counts[armyID] = (counts[armyID] or 0) + 1

    if b.BlockWhenFull ~= false and (counts[armyID] or 0) > max then
        return false, "Faction complète : " .. tostring(math.max(0, (counts[armyID] or 1) - 1)) .. "/" .. tostring(max) .. "."
    end

    local minOther
    for _, army in ipairs(MedalBarracks.GetArmies()) do
        if army.id ~= armyID then
            local c = counts[army.id] or 0
            minOther = minOther and math.min(minOther, c) or c
        end
    end

    if minOther and ((counts[armyID] or 0) - minOther) > tolerance then
        return false, "Équilibrage actif : écart maximum autorisé de " .. tostring(tolerance) .. " joueurs."
    end

    return true, ""
end

timer.Create("MedalBarracks_CampCountBroadcast", 5, 0, function()
    if MedalBarracks.BroadcastCampCounts then MedalBarracks.BroadcastCampCounts() end
end)
timer.Simple(1, function() if MedalBarracks.BroadcastCampCounts then MedalBarracks.BroadcastCampCounts() end end)

function MedalBarracks.ResetPlayerCamp(ply)
    if not IsValid(ply) then return end
    local key = steamKey(ply)
    MedalBarracks.PlayerCamp[key] = nil
    ply:SetNWString("MedalBarracks_ArmyChoice", "")
    ply:RemovePData("MedalBarracks_ArmyChoice")
    timer.Simple(0, function() if MedalBarracks.BroadcastCampCounts then MedalBarracks.BroadcastCampCounts() end end)
end

local function defaultCharacterModel(army)
    if not army then return "models/player/Group03/male_07.mdl" end
    if isstring(army.characterModel) and army.characterModel ~= "" then return army.characterModel end
    local role = MedalBarracks.GetFirstRole and MedalBarracks.GetFirstRole(army)
    if role and isstring(role.model) and role.model ~= "" then return role.model end
    return "models/player/Group03/male_07.mdl"
end

local function isAllowedCharacterModel(army, model)
    if not isstring(model) or model == "" then return false end
    if not util.IsValidModel(model) then return false end
    if not istable(army and army.characterModels) then return model == defaultCharacterModel(army) end
    for _, v in ipairs(army.characterModels) do
        if v == model then return true end
    end
    return false
end

function MedalBarracks.UpdateCharacterNW(ply)
    if not IsValid(ply) then return end
    local chars = MedalBarracks.GetCharacters(ply)
    for _, army in ipairs(MedalBarracks.GetArmies()) do
        local data = chars[army.id]
        ply:SetNWBool("MedalBarracks_Char_" .. army.id, data ~= nil)
        ply:SetNWString("MedalBarracks_CharFirst_" .. army.id, data and tostring(data.firstName or "") or "")
        ply:SetNWString("MedalBarracks_CharLast_" .. army.id, data and tostring(data.lastName or "") or "")
        ply:SetNWString("MedalBarracks_CharRole_" .. army.id, data and tostring(data.role or "") or "")
        ply:SetNWString("MedalBarracks_CharLoadout_" .. army.id, data and tostring(data.loadout or "") or "")
    end
end

function MedalBarracks.LoadCharacters(ply)
    if not IsValid(ply) then return end
    MedalBarracks.InitDB()
    local key = steamKey(ply)
    local chars = {}
    local cc = charCfg()
    local tableName = cc.SQLTable or "medal_barracks_characters"
    local rows = sql.Query("SELECT * FROM " .. tableName .. " WHERE steamid64 = " .. sqlstr(key))
    if istable(rows) then
        for _, row in ipairs(rows) do
            if row.army and row.army ~= "" then
                chars[row.army] = {
                    firstName = row.first_name or "",
                    lastName = row.last_name or "",
                    age = tonumber(row.age) or 18,
                    size = tonumber(row.size) or 175,
                    gender = row.gender or "male",
                    nationality = row.nationality or "",
                    description = row.description or "",
                    model = row.model or "",
                    role = row.role or "",
                    loadout = row.loadout or "",
                    created = tonumber(row.created) or 0,
                    updated = tonumber(row.updated) or 0,
                    steamid = row.steamid or ply:SteamID(),
                    steamid64 = key,
                }
            end
        end
    end
    MedalBarracks.PlayerCharacters[key] = chars
    MedalBarracks.UpdateCharacterNW(ply)
    MedalBarracks.SendCharacters(ply)
end

function MedalBarracks.GetCharacters(ply)
    if not IsValid(ply) then return {} end
    local key = steamKey(ply)
    MedalBarracks.PlayerCharacters[key] = MedalBarracks.PlayerCharacters[key] or {}
    return MedalBarracks.PlayerCharacters[key]
end

function MedalBarracks.SaveCharacterRow(ply, armyID, data)
    if not IsValid(ply) or not data then return false end
    MedalBarracks.InitDB()
    local cc = charCfg()
    local tableName = cc.SQLTable or "medal_barracks_characters"
    local key = steamKey(ply)
    local now = os.time()
    data.updated = now
    data.created = tonumber(data.created) or now
    data.steamid = ply:SteamID()
    data.steamid64 = key

    local q = "INSERT OR REPLACE INTO " .. tableName .. " (steamid64, steamid, army, first_name, last_name, age, size, gender, nationality, description, model, role, loadout, created, updated) VALUES (" ..
        sqlstr(key) .. ", " ..
        sqlstr(ply:SteamID()) .. ", " ..
        sqlstr(armyID) .. ", " ..
        sqlstr(data.firstName or "") .. ", " ..
        sqlstr(data.lastName or "") .. ", " ..
        tostring(tonumber(data.age) or 18) .. ", " ..
        tostring(tonumber(data.size) or 175) .. ", " ..
        sqlstr(data.gender or "male") .. ", " ..
        sqlstr(data.nationality or "") .. ", " ..
        sqlstr(data.description or "") .. ", " ..
        sqlstr(data.model or "") .. ", " ..
        sqlstr(data.role or "") .. ", " ..
        sqlstr(data.loadout or "") .. ", " ..
        tostring(tonumber(data.created) or now) .. ", " ..
        tostring(now) .. ")"
    local res = sql.Query(q)
    if res == false then
        ErrorNoHalt("[MedalBarracks] SQL error: " .. tostring(sql.LastError()) .. "\n")
        return false
    end
    return true
end

function MedalBarracks.DeleteCharacterRow(ply, armyID)
    if not IsValid(ply) then return end
    MedalBarracks.InitDB()
    local cc = charCfg()
    local tableName = cc.SQLTable or "medal_barracks_characters"
    if armyID == "all" then
        sql.Query("DELETE FROM " .. tableName .. " WHERE steamid64 = " .. sqlstr(steamKey(ply)))
    else
        sql.Query("DELETE FROM " .. tableName .. " WHERE steamid64 = " .. sqlstr(steamKey(ply)) .. " AND army = " .. sqlstr(armyID))
    end
end

function MedalBarracks.SendCharacters(ply)
    if not IsValid(ply) then return end
    local chars = MedalBarracks.GetCharacters(ply)
    net.Start("MedalBarracks_Characters")
        local armies = MedalBarracks.GetArmies()
        net.WriteUInt(#armies, 8)
        for _, army in ipairs(armies) do
            local data = chars[army.id]
            net.WriteString(army.id or "")
            net.WriteBool(data ~= nil)
            if data then
                net.WriteString(data.firstName or "")
                net.WriteString(data.lastName or "")
                net.WriteUInt(math.Clamp(tonumber(data.age) or 18, 0, 120), 8)
                net.WriteUInt(math.Clamp(tonumber(data.size) or 175, 0, 255), 8)
                net.WriteString(data.gender or "male")
                net.WriteString(data.nationality or "")
                net.WriteString(data.description or "")
                net.WriteString(data.model or defaultCharacterModel(army))
                net.WriteString(data.role or "")
                net.WriteString(data.loadout or "")
            end
        end
    net.Send(ply)
end


-- =========================
-- Menu staff personnages
-- =========================
local function onlineNameForSteam64(sid64)
    for _, v in ipairs(player.GetHumans()) do
        if IsValid(v) and steamKey(v) == sid64 then return v:Nick(), v end
    end
    return "Hors ligne", nil
end

function MedalBarracks.SendStaffCharacters(ply)
    if not isStaff(ply) then notify(ply, false, "Menu staff réservé au staff."); return end
    MedalBarracks.InitDB()
    local tableName = (charCfg().SQLTable or "medal_barracks_characters")
    local rows = sql.Query("SELECT * FROM " .. tableName .. " ORDER BY updated DESC") or {}
    if rows == false then rows = {} end

    net.Start("MedalBarracks_StaffCharacters")
        net.WriteUInt(math.min(#rows, 4095), 12)
        for i, row in ipairs(rows) do
            if i > 4095 then break end
            local nick = onlineNameForSteam64(tostring(row.steamid64 or ""))
            net.WriteString(tostring(row.steamid64 or ""))
            net.WriteString(tostring(row.steamid or ""))
            net.WriteString(tostring(nick or "Hors ligne"))
            net.WriteString(tostring(row.army or ""))
            net.WriteString(tostring(row.first_name or ""))
            net.WriteString(tostring(row.last_name or ""))
            net.WriteUInt(math.Clamp(tonumber(row.age) or 18, 0, 120), 8)
            net.WriteString(tostring(row.nationality or ""))
            net.WriteString(tostring(row.description or ""))
            net.WriteString(tostring(row.model or ""))
            net.WriteString(tostring(row.role or ""))
            net.WriteString(tostring(row.loadout or ""))
            net.WriteUInt(math.max(tonumber(row.updated) or 0, 0), 32)
        end
    net.Send(ply)
end

local function refreshOnlineCharacter(sid64)
    local _, target = onlineNameForSteam64(sid64)
    if IsValid(target) then
        MedalBarracks.LoadCharacters(target)
        MedalBarracks.SendMainMenu(target)
    end
end

function MedalBarracks.StaffDeleteCharacter(admin, sid64, armyID)
    if not isStaff(admin) then return false, "Commande réservée au staff." end
    sid64 = tostring(sid64 or "")
    armyID = tostring(armyID or "")
    if sid64 == "" or armyID == "" then return false, "Personnage invalide." end
    MedalBarracks.InitDB()
    local tableName = charCfg().SQLTable or "medal_barracks_characters"
    sql.Query("DELETE FROM " .. tableName .. " WHERE steamid64 = " .. sqlstr(sid64) .. " AND army = " .. sqlstr(armyID))
    refreshOnlineCharacter(sid64)
    MedalBarracks.SendStaffCharacters(admin)
    return true, "Personnage supprimé."
end

function MedalBarracks.StaffSaveCharacter(admin, data)
    if not isStaff(admin) then return false, "Commande réservée au staff." end
    data = data or {}
    local sid64 = tostring(data.steamid64 or "")
    local armyID = tostring(data.army or "")
    if sid64 == "" or armyID == "" then return false, "Personnage invalide." end
    local army = MedalBarracks.GetArmy(armyID)
    if not army then return false, "Faction introuvable." end

    data.firstName = clampText(data.firstName, 24)
    data.lastName = clampText(data.lastName, 24)
    data.nationality = clampText(data.nationality, 32)
    data.description = clampText(data.description, 450)
    data.age = math.Clamp(tonumber(data.age) or 18, 0, 120)
    data.model = isAllowedCharacterModel(army, data.model or "") and data.model or defaultCharacterModel(army)

    MedalBarracks.InitDB()
    local tableName = charCfg().SQLTable or "medal_barracks_characters"
    local now = os.time()
    local q = "UPDATE " .. tableName .. " SET first_name = " .. sqlstr(data.firstName) ..
        ", last_name = " .. sqlstr(data.lastName) ..
        ", age = " .. tostring(data.age) ..
        ", nationality = " .. sqlstr(data.nationality) ..
        ", description = " .. sqlstr(data.description) ..
        ", model = " .. sqlstr(data.model) ..
        ", role = " .. sqlstr(data.role or "") ..
        ", loadout = " .. sqlstr(data.loadout or "") ..
        ", updated = " .. tostring(now) ..
        " WHERE steamid64 = " .. sqlstr(sid64) .. " AND army = " .. sqlstr(armyID)
    local res = sql.Query(q)
    if res == false then return false, "Erreur SQL : " .. tostring(sql.LastError()) end
    refreshOnlineCharacter(sid64)
    MedalBarracks.SendStaffCharacters(admin)
    return true, "Personnage modifié."
end

local function validateCharacterInput(ply, armyID, data, editing)
    local cc = charCfg()
    local army = MedalBarracks.GetArmy(armyID)
    if cc.Enabled == false then return false, "La création de personnage est désactivée." end
    if not army then return false, "Faction introuvable." end

    data.firstName = clampText(data.firstName, cc.MaxNameLength or 24)
    data.lastName = clampText(data.lastName, cc.MaxNameLength or 24)
    data.nationality = clampText(data.nationality, 32)
    data.description = clampText(data.description, 450)
    data.age = math.Clamp(tonumber(data.age) or 18, tonumber(cc.MinAge) or 16, tonumber(cc.MaxAge) or 80)

    if not editing then
        if #data.firstName < (tonumber(cc.MinNameLength) or 2) then return false, "Prénom trop court." end
        if #data.lastName < (tonumber(cc.MinNameLength) or 2) then return false, "Nom trop court." end
    end

    if not isAllowedCharacterModel(army, data.model or "") then
        data.model = defaultCharacterModel(army)
    end

    return true, "OK", army
end

function MedalBarracks.CreateCharacter(ply, armyID, data)
    if not IsValid(ply) then return false, "Joueur invalide." end
    armyID = tostring(armyID or "")
    data = data or {}

    local chars = MedalBarracks.GetCharacters(ply)
    if chars[armyID] then
        return false, "Tu as déjà un personnage dans cette faction."
    end

    local ok, msg, army = validateCharacterInput(ply, armyID, data, false)
    if not ok then return false, msg end

    local now = os.time()
    local char = {
        firstName = data.firstName,
        lastName = data.lastName,
        age = data.age,
        size = tonumber(data.size) or 175,
        gender = data.gender or "male",
        nationality = data.nationality,
        description = data.description,
        model = data.model or defaultCharacterModel(army),
        role = "",
        loadout = "",
        created = now,
        updated = now,
    }

    chars[armyID] = char
    if not MedalBarracks.SaveCharacterRow(ply, armyID, char) then
        chars[armyID] = nil
        return false, "Erreur SQL pendant la création du personnage."
    end

    MedalBarracks.UpdateCharacterNW(ply)
    MedalBarracks.SendCharacters(ply)
    return true, "Personnage créé : " .. char.firstName .. " " .. char.lastName .. "."
end

function MedalBarracks.UpdateCharacter(ply, armyID, data)
    if not IsValid(ply) then return false, "Joueur invalide." end
    local cc = charCfg()
    if cc.AllowEditAfterCreation == false then return false, "Modification désactivée." end
    armyID = tostring(armyID or "")
    data = data or {}

    local chars = MedalBarracks.GetCharacters(ply)
    local existing = chars[armyID]
    if not existing then return false, "Tu dois créer ton personnage avant de le modifier." end

    data.firstName = existing.firstName
    data.lastName = existing.lastName
    if cc.AllowNameEditAfterCreation == true then
        data.firstName = clampText(data.newFirstName or data.firstName, cc.MaxNameLength or 24)
        data.lastName = clampText(data.newLastName or data.lastName, cc.MaxNameLength or 24)
    end

    local ok, msg, army = validateCharacterInput(ply, armyID, data, true)
    if not ok then return false, msg end

    existing.age = data.age
    existing.size = tonumber(data.size) or existing.size or 175
    existing.gender = data.gender or existing.gender or "male"
    existing.nationality = data.nationality
    existing.description = data.description
    if cc.AllowModelChoice == true then existing.model = data.model or defaultCharacterModel(army) end

    if not MedalBarracks.SaveCharacterRow(ply, armyID, existing) then
        return false, "Erreur SQL pendant la sauvegarde du personnage."
    end

    MedalBarracks.UpdateCharacterNW(ply)
    MedalBarracks.SendCharacters(ply)
    return true, "Personnage modifié. Nom et prénom restent verrouillés."
end

function MedalBarracks.SelectCamp(ply, armyID)
    if not IsValid(ply) then return false, "Joueur invalide." end
    local selection = campCfg()
    if selection.Enabled == false then return false, "La sélection de faction est désactivée." end

    local army = MedalBarracks.GetArmy(armyID)
    if not army then return false, "Faction introuvable." end

    local old = MedalBarracks.GetPlayerCamp(ply)
    local balanceOK, balanceMsg = MedalBarracks.CanJoinCamp(ply, armyID)
    if not balanceOK then return false, balanceMsg or "Faction bloquée par l'équilibrage." end

    if old ~= "" and old ~= armyID and selection.LockChoice then
        local oldArmy = MedalBarracks.GetArmy(old)
        return false, "Ta faction est déjà verrouillée : " .. ((oldArmy and (oldArmy.cardName or oldArmy.menuName or oldArmy.name)) or old) .. "."
    end

    MedalBarracks.SetPlayerCamp(ply, armyID)
    return true, "Faction sélectionnée : " .. (army.cardName or army.menuName or army.name or armyID) .. ".", armyID
end

function MedalBarracks.ResolveTeam(role)
    if not role then return nil end
    if isnumber(role.job) and team.Valid(role.job) then return role.job end
    if isstring(role.job) and role.job ~= "" then
        local fromGlobal = _G[role.job]
        if isnumber(fromGlobal) and team.Valid(fromGlobal) then return fromGlobal end
    end

    local wantedName = lower(role.jobName)
    local wantedCommand = lower(role.jobCommand or role.command)

    if RPExtraTeams then
        for teamID, data in pairs(RPExtraTeams) do
            if wantedName ~= "" and lower(data.name) == wantedName then return teamID end
            if wantedCommand ~= "" and lower(data.command) == wantedCommand then return teamID end
        end
    end

    if wantedName ~= "" then
        for teamID = 0, 256 do
            if team.Valid(teamID) and lower(team.GetName(teamID)) == wantedName then return teamID end
        end
    end

    return nil
end

function MedalBarracks.ApplyBodygroups(ply, data)
    if not data or not data.bodygroups then return end
    for group, value in pairs(data.bodygroups) do
        ply:SetBodygroup(tonumber(group) or group, tonumber(value) or 0)
    end
end

function MedalBarracks.ApplyKit(ply, role, loadout, armyID)
    if not IsValid(ply) or not role or not loadout then return end
    local chars = MedalBarracks.GetCharacters(ply)
    local char = chars[armyID or role._armyID or ""]

    if cfg.ApplyModel then
        local model = loadout.model or role.model or (char and char.model)
        if isstring(model) and model ~= "" and util.IsValidModel(model) then
            ply:SetModel(model)
        end
        MedalBarracks.ApplyBodygroups(ply, role)
        MedalBarracks.ApplyBodygroups(ply, loadout)
    end

    if cfg.ApplyLoadout then
        if cfg.StripWeapons then ply:StripWeapons() end
        for _, class in ipairs(loadout.weapons or {}) do
            if isstring(class) and class ~= "" then ply:Give(class) end
        end
        for ammoType, amount in pairs(loadout.ammo or {}) do
            if isnumber(amount) and amount > 0 then ply:GiveAmmo(amount, tostring(ammoType), true) end
        end
    end

    if isnumber(loadout.armor) then ply:SetArmor(loadout.armor) end
    if isnumber(loadout.health) then ply:SetHealth(math.Clamp(loadout.health, 1, ply:GetMaxHealth())) end

    ply:Freeze(false)
    if ply.UnLock then ply:UnLock() end
    if ply.GodDisable then ply:GodDisable() end

    ply:SetNWString("MedalBarracks_Army", tostring(armyID or role._armyID or ""))
    ply:SetNWString("MedalBarracks_Role", tostring(role.id or ""))
    ply:SetNWString("MedalBarracks_Loadout", tostring(loadout.id or ""))
end

function MedalBarracks.EnsureCharacterSlot(ply, armyID, roleID, loadoutID)
    if not IsValid(ply) then return false, "Joueur invalide." end
    local cc = charCfg()
    if cc.Enabled == false or cc.RequireCharacterBeforeRoles == false then return true end
    local chars = MedalBarracks.GetCharacters(ply)
    local existing = chars[armyID]
    if not existing then
        local army = MedalBarracks.GetArmy(armyID)
        return false, "Tu dois créer ton personnage côté " .. ((army and (army.cardName or army.menuName or army.name)) or armyID) .. " avant de choisir un rôle."
    end
    existing.role = tostring(roleID or "")
    existing.loadout = tostring(loadoutID or "")
    MedalBarracks.SaveCharacterRow(ply, armyID, existing)
    MedalBarracks.UpdateCharacterNW(ply)
    MedalBarracks.SendCharacters(ply)
    return true
end

function MedalBarracks.SelectLoadout(ply, armyID, categoryID, roleID, loadoutID)
    if not IsValid(ply) then return false, "Joueur invalide." end

    local selection = campCfg()
    local chosenCamp = MedalBarracks.GetPlayerCamp(ply)
    if selection.Enabled ~= false and selection.RequireCampBeforeBarracks and chosenCamp == "" then
        MedalBarracks.SendMainMenu(ply)
        return false, "Tu dois choisir ta faction depuis le bouton JOUER avant de choisir un rôle."
    end

    if selection.Enabled ~= false and selection.LockChoice and chosenCamp ~= "" and armyID ~= chosenCamp then
        return false, "Tu ne peux pas choisir un rôle d'une autre faction."
    end

    if selection.Enabled ~= false and chosenCamp ~= "" and armyID ~= chosenCamp then
        MedalBarracks.SetPlayerCamp(ply, armyID)
    end

    local role, category, army = MedalBarracks.GetRole(armyID, categoryID, roleID)
    if not role then return false, "Rôle introuvable." end
    local loadout = MedalBarracks.GetLoadout(role, loadoutID)
    if not loadout then return false, "Loadout introuvable." end

    local plyLevel = cfg.GetPlayerLevel(ply)
    local roleLevel = cfg.GetPlayerRoleLevel and cfg.GetPlayerRoleLevel(ply, armyID, roleID, role) or plyLevel
    local requiredGeneral = tonumber(role.requiredLevel) or 1
    local requiredRole = tonumber(loadout.level) or 1

    if plyLevel < requiredGeneral then return false, "Niveau général insuffisant. Niveau requis : " .. requiredGeneral .. "." end
    if (cfg.UseRoleLevelForLoadoutUnlocks ~= false) and roleLevel < requiredRole then
        return false, "Niveau insuffisant dans le rôle " .. tostring(role.name or roleID) .. ". Niveau requis : " .. requiredRole .. "."
    elseif (cfg.UseRoleLevelForLoadoutUnlocks == false) and plyLevel < requiredRole then
        return false, "Niveau insuffisant. Niveau requis : " .. requiredRole .. "."
    end

    local slotOK, slotMsg = MedalBarracks.EnsureCharacterSlot(ply, armyID, roleID, loadout.id)
    if not slotOK then return false, slotMsg end

    role._armyID = armyID
    local teamID = MedalBarracks.ResolveTeam(role)
    if cfg.RequireValidJob and not teamID then return false, "Job DarkRP introuvable pour ce rôle. Vérifie job/jobName dans sh_config.lua." end

    MedalBarracks.Selected[steamKey(ply)] = {army = armyID, category = categoryID, role = roleID, loadout = loadout.id}
    MedalBarracks.SetMenuState(ply, false)

    local spawnCfg = cfg.DarkRPJobSpawn or {}
    local changedTeam = false
    if teamID and team.Valid(teamID) and ply:Team() ~= teamID and role.spawnAsJob ~= false and spawnCfg.ChangeTeam ~= false then
        if DarkRP and ply.changeTeam then ply:changeTeam(teamID, true, true) else ply:SetTeam(teamID) end
        changedTeam = true
    end

    local function doSpawnAndKit()
        if not IsValid(ply) then return end
        if spawnCfg.Enabled ~= false and spawnCfg.SpawnAfterJobChange ~= false and ply.Spawn then
            -- Spawn après changement de job : le joueur arrive au spawn configuré du job DarkRP.
            ply:Spawn()
        end
        timer.Simple(tonumber(spawnCfg.KitDelay) or 0.45, function()
            if not IsValid(ply) then return end
            MedalBarracks.ApplyKit(ply, role, loadout, armyID)
            if (charCfg().ForceSpawnAfterRoleSelection == true) and spawnCfg.SpawnAfterJobChange == false and ply.Spawn then ply:Spawn() end
        end)
    end

    timer.Simple(tonumber(spawnCfg.SpawnDelay) or (changedTeam and 0.20 or 0.10), doSpawnAndKit)

    local armyName = army and (army.menuName or army.name) or armyID
    return true, armyName .. " / " .. (role.name or roleID) .. " / " .. (loadout.name or loadout.id) .. " sélectionné."
end

net.Receive("MedalBarracks_RequestCharacters", function(_, ply)
    MedalBarracks.LoadCharacters(ply)
end)

net.Receive("MedalBarracks_CreateCharacter", function(_, ply)
    local cc = charCfg()
    local armyID = net.ReadString()
    local data = {
        firstName = net.ReadString(),
        lastName = net.ReadString(),
        age = net.ReadUInt(8),
        size = math.Clamp(net.ReadUInt(8), tonumber(cc.MinSize) or 150, tonumber(cc.MaxSize) or 200),
        gender = net.ReadString() == "female" and "female" or "male",
        nationality = net.ReadString(),
        description = net.ReadString(),
        model = net.ReadString(),
    }
    local ok, msg = MedalBarracks.CreateCharacter(ply, armyID, data)
    notifyCharacter(ply, ok, msg, armyID)
end)

net.Receive("MedalBarracks_UpdateCharacter", function(_, ply)
    local cc = charCfg()
    local armyID = net.ReadString()
    local data = {
        age = net.ReadUInt(8),
        size = math.Clamp(net.ReadUInt(8), tonumber(cc.MinSize) or 150, tonumber(cc.MaxSize) or 200),
        gender = net.ReadString() == "female" and "female" or "male",
        nationality = net.ReadString(),
        description = net.ReadString(),
        model = net.ReadString(),
    }
    local ok, msg = MedalBarracks.UpdateCharacter(ply, armyID, data)
    notifyCharacter(ply, ok, msg, armyID)
end)

net.Receive("MedalBarracks_SelectCamp", function(_, ply)
    local armyID = net.ReadString()
    local ok, msg, selectedArmyID = MedalBarracks.SelectCamp(ply, armyID)
    notifyCamp(ply, ok, msg, selectedArmyID or armyID)
    if ok then
        MedalBarracks.SendCharacters(ply)
        timer.Simple(0.15, function()
            if IsValid(ply) then MedalBarracks.SendCharacterSelection(ply, selectedArmyID or armyID) end
        end)
    end
end)

net.Receive("MedalBarracks_Select", function(_, ply)
    local armyID = net.ReadString()
    local categoryID = net.ReadString()
    local roleID = net.ReadString()
    local loadoutID = net.ReadString()
    local ok, msg = MedalBarracks.SelectLoadout(ply, armyID, categoryID, roleID, loadoutID)
    notify(ply, ok, msg)
end)

hook.Add("PlayerInitialSpawn", "MedalBarracks_OpenMainOnJoin", function(ply)
    MedalBarracks.LoadCharacters(ply)
    MedalBarracks.LoadXP(ply)
    timer.Simple(1.8, function()
        if not IsValid(ply) then return end
        if campCfg().RememberWithPData then
            local saved = ply:GetPData("MedalBarracks_ArmyChoice", "")
            if saved ~= "" and MedalBarracks.GetArmy(saved) then MedalBarracks.SetPlayerCamp(ply, saved) end
        end
        local main = cfg.MainMenu or {}
        if main.Enabled ~= false and main.OpenOnInitialSpawn then
            MedalBarracks.SendMainMenu(ply)
            return
        end
        if campCfg().Enabled ~= false and campCfg().OpenOnInitialSpawn and MedalBarracks.GetPlayerCamp(ply) == "" then
            MedalBarracks.SendCampSelection(ply)
        end
    end)
end)

hook.Add("PlayerDisconnected", "MedalBarracks_Cleanup", function(ply)
    local key = steamKey(ply)
    MedalBarracks.PlayerCamp[key] = nil
    MedalBarracks.PlayerCharacters[key] = nil
    MedalBarracks.PlayerXP[key] = nil
    MedalBarracks.Selected[key] = nil
    MedalBarracks.InMenu[key] = nil
    timer.Simple(0, function() if MedalBarracks.BroadcastCampCounts then MedalBarracks.BroadcastCampCounts() end end)
end)

hook.Add("PlayerSpawn", "MedalBarracks_ReapplyOrBlockSpawn", function(ply)
    local key = steamKey(ply)
    local selected = MedalBarracks.Selected[key]
    local cc = charCfg()

    if (not selected and cc.PreventSpawnWithoutRole ~= false) or MedalBarracks.InMenu[key] then
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            if MedalBarracks.Selected[steamKey(ply)] then return end
            MedalBarracks.SetMenuState(ply, true)
            if cc.OpenMainMenuIfNoRole ~= false then MedalBarracks.SendMainMenu(ply) end
        end)
        return
    end

    if not selected then return end
    timer.Simple(0.15, function()
        if not IsValid(ply) then return end
        local role = MedalBarracks.GetRole(selected.army, selected.category, selected.role)
        local loadout = MedalBarracks.GetLoadout(role, selected.loadout)
        if role and loadout then
            role._armyID = selected.army
            MedalBarracks.ApplyKit(ply, role, loadout, selected.army)
        end
    end)
end)



hook.Add("PlayerDeathThink", "MedalBarracks_BlockRespawnWithoutRole", function(ply)
    local gate = spawnGateCfg()
    if gate.Enabled == false or gate.PreventDeathRespawnWithoutRole == false then return end
    if not MedalBarracks.Selected[steamKey(ply)] then
        MedalBarracks.SetMenuState(ply, true)
        return false
    end
end)

hook.Add("PlayerLoadout", "MedalBarracks_NoDefaultLoadoutInMenu", function(ply)
    local gate = spawnGateCfg()
    if gate.Enabled == false then return end
    if MedalBarracks.InMenu[steamKey(ply)] and not MedalBarracks.Selected[steamKey(ply)] then
        timer.Simple(0, function()
            if IsValid(ply) then ply:StripWeapons() end
        end)
        return true
    end
end)

hook.Add("PlayerDeath", "MedalBarracks_RoleKillXP", function(victim, inflictor, attacker)
    if not xpEnabled() or xpRoleCfg().Enabled == false then return end
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if IsValid(victim) and victim == attacker then return end

    local rxc = xpRoleCfg()
    if rxc.IgnoreTeamKills ~= false and IsValid(victim) and victim:IsPlayer() and attacker:Team() == victim:Team() then return end

    local amount = tonumber(rxc.KillXP) or 4
    MedalBarracks.AddSelectedRoleXP(attacker, amount, "kill")
end)

local function findTarget(ply, arg)
    if not arg or arg == "" then return ply end
    arg = string.lower(arg)
    for _, v in ipairs(player.GetAll()) do
        if string.lower(v:SteamID64()) == arg or string.lower(v:SteamID()) == arg or string.find(string.lower(v:Nick()), arg, 1, true) then return v end
    end
end

-- Recharge le manifest du serveur annexe côté clients.
-- Utilisation console serveur : medal_media_reload
concommand.Add("medal_media_reload", function(ply)
    if IsValid(ply) and not isStaff(ply) then notify(ply, false, "Commande réservée au staff."); return end
    net.Start("MedalBarracks_RemoteMediaReload")
    net.Broadcast()
    if IsValid(ply) then notify(ply, true, "Manifest média rechargé côté clients.") else print("[MedalBarracks] Manifest média rechargé côté clients.") end
end)

concommand.Add("medal_camp_reset", function(ply, _, args)
    if not isStaff(ply) then notifyCamp(ply, false, "Commande réservée au staff.", ""); return end
    local target = findTarget(ply, args and args[1])
    if not IsValid(target) then if IsValid(ply) then notifyCamp(ply, false, "Joueur introuvable.", "") end; return end
    MedalBarracks.ResetPlayerCamp(target)
    MedalBarracks.SendMainMenu(target)
    notifyCamp(target, true, "Ton choix de faction a été réinitialisé.", "")
end)

-- medal_character_reset <joueur> <americans|vietcong|all>
concommand.Add("medal_character_reset", function(ply, _, args)
    if not isStaff(ply) then notify(ply, false, "Commande réservée au staff."); return end
    local target = findTarget(ply, args and args[1])
    if not IsValid(target) then if IsValid(ply) then notify(ply, false, "Joueur introuvable.") end; return end

    local armyID = args and args[2] or "all"
    local chars = MedalBarracks.GetCharacters(target)
    if armyID == "all" or armyID == "" then
        table.Empty(chars)
        MedalBarracks.DeleteCharacterRow(target, "all")
    elseif MedalBarracks.GetArmy(armyID) then
        chars[armyID] = nil
        MedalBarracks.DeleteCharacterRow(target, armyID)
    else
        if IsValid(ply) then notify(ply, false, "Faction introuvable. Utilise americans, vietcong ou all.") end
        return
    end

    MedalBarracks.UpdateCharacterNW(target)
    MedalBarracks.SendCharacters(target)
    MedalBarracks.SendMainMenu(target)
    notify(target, true, "Ton personnage de faction a été réinitialisé.")
end)


-- medal_xp_give <joueur> <general|role> <montant> [americans] [role_id]
concommand.Add("medal_xp_give", function(ply, _, args)
    if not isStaff(ply) then notify(ply, false, "Commande réservée au staff."); return end
    local target = findTarget(ply, args and args[1])
    if not IsValid(target) then if IsValid(ply) then notify(ply, false, "Joueur introuvable.") end; return end

    local kind = string.lower(tostring(args and args[2] or "general"))
    local amount = tonumber(args and args[3]) or 0
    if amount <= 0 then if IsValid(ply) then notify(ply, false, "Montant invalide.") end; return end

    if kind == "general" then
        MedalBarracks.AddGeneralXP(target, amount, "admin")
        if IsValid(ply) then notify(ply, true, "XP générale ajoutée.") end
        return
    end

    if kind == "role" then
        local armyID = tostring(args and args[4] or "")
        local roleID = tostring(args and args[5] or "")
        if armyID == "" or roleID == "" then
            local selected = MedalBarracks.Selected[steamKey(target)]
            if selected then
                armyID = selected.army or ""
                roleID = selected.role or ""
            end
        end
        if armyID == "" or roleID == "" then if IsValid(ply) then notify(ply, false, "Précise la faction et le rôle, ou cible un joueur qui a déjà choisi un rôle.") end; return end
        MedalBarracks.AddRoleXP(target, armyID, roleID, amount, "admin")
        if IsValid(ply) then notify(ply, true, "XP de rôle ajoutée.") end
        return
    end

    if IsValid(ply) then notify(ply, false, "Type invalide. Utilise general ou role.") end
end)

concommand.Add("medal_xp_reset", function(ply, _, args)
    if not isStaff(ply) then notify(ply, false, "Commande réservée au staff."); return end
    local target = findTarget(ply, args and args[1])
    if not IsValid(target) then if IsValid(ply) then notify(ply, false, "Joueur introuvable.") end; return end
    local key = steamKey(target)
    MedalBarracks.PlayerXP[key] = {general = {level = 1, xp = 0}, roles = {}}
    if xpCfg().SaveInSQLite ~= false then
        local tableName = xpCfg().SQLTable or "medal_barracks_xp"
        sql.Query("DELETE FROM " .. tableName .. " WHERE steamid64 = " .. sqlstr(key))
    end
    MedalBarracks.UpdateXPNW(target)
    if IsValid(ply) then notify(ply, true, "XP réinitialisée.") end
    notify(target, true, "Ton XP a été réinitialisée.")
end)

net.Receive("MedalBarracks_StaffRequestCharacters", function(_, ply)
    MedalBarracks.SendStaffCharacters(ply)
end)

net.Receive("MedalBarracks_StaffDeleteCharacter", function(_, ply)
    local sid64 = net.ReadString()
    local armyID = net.ReadString()
    local ok, msg = MedalBarracks.StaffDeleteCharacter(ply, sid64, armyID)
    notify(ply, ok, msg)
end)

net.Receive("MedalBarracks_StaffSaveCharacter", function(_, ply)
    local data = {
        steamid64 = net.ReadString(),
        army = net.ReadString(),
        firstName = net.ReadString(),
        lastName = net.ReadString(),
        age = net.ReadUInt(8),
        nationality = net.ReadString(),
        description = net.ReadString(),
        model = net.ReadString(),
        role = net.ReadString(),
        loadout = net.ReadString(),
    }
    local ok, msg = MedalBarracks.StaffSaveCharacter(ply, data)
    notify(ply, ok, msg)
end)

-- =========================
-- Relations RP : inconnu / présentation
-- =========================
local function relCfg()
    return cfg.Relations or {}
end

local function relationEnabled()
    return relCfg().Enabled ~= false
end

local function activeCharKey(ply)
    if not IsValid(ply) then return "" end
    local armyID = MedalBarracks.GetPlayerCamp(ply)
    if armyID == "" then return "" end
    local chars = MedalBarracks.GetCharacters(ply)
    if not chars[armyID] then return "" end
    return steamKey(ply) .. "|" .. armyID
end

local function pairKeys(a, b)
    a, b = tostring(a or ""), tostring(b or "")
    if a == "" or b == "" then return nil, nil end
    if a < b then return a, b end
    return b, a
end

local function roleIDOf(ply)
    if not IsValid(ply) then return "" end
    local selected = MedalBarracks.Selected[steamKey(ply)]
    if selected and selected.role then return tostring(selected.role) end
    local armyID = MedalBarracks.GetPlayerCamp(ply)
    local chars = MedalBarracks.GetCharacters(ply)
    return tostring(chars[armyID] and chars[armyID].role or "")
end

local function listHas(t, id)
    id = tostring(id or "")
    for _, v in ipairs(t or {}) do if tostring(v) == id then return true end end
    return false
end

local function isLeaderRole(roleID)
    local r = relCfg()
    return listHas(r.CommanderRoleIDs, roleID) or listHas(r.OfficerRoleIDs, roleID)
end

function MedalBarracks.GetPlayerSquadID(ply)
    if not IsValid(ply) then return "" end
    return ply:GetNWString(relCfg().SquadNWString or "MedalBarracks_SquadID", "")
end

function MedalBarracks.StoreRelation(keyA, keyB)
    if not relationEnabled() then return false end
    local a, b = pairKeys(keyA, keyB)
    if not a or a == b then return false end
    MedalBarracks.InitDB()
    local tableName = relCfg().SQLTable or "medal_barracks_relations"
    sql.Query("INSERT OR REPLACE INTO " .. tableName .. " (a, b, created) VALUES (" .. sqlstr(a) .. ", " .. sqlstr(b) .. ", " .. tostring(os.time()) .. ")")
    return true
end

function MedalBarracks.RelationExists(keyA, keyB)
    if not relationEnabled() then return false end
    local a, b = pairKeys(keyA, keyB)
    if not a or a == b then return true end
    MedalBarracks.InitDB()
    local tableName = relCfg().SQLTable or "medal_barracks_relations"
    local row = sql.QueryRow("SELECT created FROM " .. tableName .. " WHERE a = " .. sqlstr(a) .. " AND b = " .. sqlstr(b) .. " LIMIT 1")
    return istable(row)
end

function MedalBarracks.CharactersKnow(viewer, target)
    if not relationEnabled() then return true end
    if not IsValid(viewer) or not IsValid(target) then return false end
    if viewer == target then return true end

    local viewerArmy = MedalBarracks.GetPlayerCamp(viewer)
    local targetArmy = MedalBarracks.GetPlayerCamp(target)
    local keyA = activeCharKey(viewer)
    local keyB = activeCharKey(target)
    if keyA == "" or keyB == "" then return false end

    -- Même escouade : tout le monde se connaît.
    if relCfg().AutoKnownSameSquad ~= false and viewerArmy ~= "" and viewerArmy == targetArmy then
        local s1 = MedalBarracks.GetPlayerSquadID(viewer)
        local s2 = MedalBarracks.GetPlayerSquadID(target)
        if s1 ~= "" and s1 == s2 then return true end
    end

    -- Officiers/commandants : bypass seulement dans la même faction.
    if relCfg().LeadershipBypassSameFaction ~= false and viewerArmy ~= "" and viewerArmy == targetArmy then
        if isLeaderRole(roleIDOf(viewer)) or isLeaderRole(roleIDOf(target)) then return true end
    end

    -- Entre US et Vietcong, aucun bypass : il faut une présentation déjà sauvegardée.
    return MedalBarracks.RelationExists(keyA, keyB)
end

function MedalBarracks.GetDisplayNameForViewer(viewer, target)
    if not IsValid(target) then return relCfg().UnknownName or "Inconnu" end
    local armyID = MedalBarracks.GetPlayerCamp(target)
    local chars = MedalBarracks.GetCharacters(target)
    local char = chars[armyID]
    if not char then return target:Nick() end
    if not MedalBarracks.CharactersKnow(viewer, target) then return relCfg().UnknownName or "Inconnu" end
    return string.Trim(tostring(char.firstName or "") .. " " .. tostring(char.lastName or ""))
end

function MedalBarracks.PresentCharacter(ply)
    if not IsValid(ply) or not relationEnabled() then return end
    local sourceKey = activeCharKey(ply)
    if sourceKey == "" then notify(ply, false, "Tu dois avoir un personnage actif pour te présenter."); return end
    local dist = tonumber(relCfg().PresentDistance) or 150
    local made = 0
    for _, target in ipairs(player.GetHumans()) do
        if target ~= ply and IsValid(target) and target:GetPos():DistToSqr(ply:GetPos()) <= dist * dist then
            local targetKey = activeCharKey(target)
            if targetKey ~= "" and MedalBarracks.StoreRelation(sourceKey, targetKey) then
                made = made + 1
                notify(target, true, MedalBarracks.GetDisplayNameForViewer(target, ply) .. " s'est présenté à toi.")
            end
        end
    end
    if made <= 0 then notify(ply, false, "Aucun personnage proche à qui te présenter.") else notify(ply, true, "Présentation faite à " .. tostring(made) .. " personne(s).") end
end

concommand.Add((cfg.Relations and cfg.Relations.PresentConsoleCommand) or "medal_present", function(ply)
    MedalBarracks.PresentCharacter(ply)
end)

hook.Add("PlayerSay", "MedalBarracks_PresentCommand", function(ply, text)
    local cmd = string.lower(tostring((relCfg().PresentCommand or "/presenter")))
    if string.lower(string.Trim(tostring(text or ""))) == cmd then
        MedalBarracks.PresentCharacter(ply)
        return ""
    end
end)


-- =========================
-- Suppression de personnage par le joueur (depuis l'écran de sélection).
-- =========================
util.AddNetworkString("MedalBarracks_DeleteCharacter")

net.Receive("MedalBarracks_DeleteCharacter", function(_, ply)
    local armyID = net.ReadString()
    local army = MedalBarracks.GetArmy(armyID)
    if not army then return end

    local chars = MedalBarracks.GetCharacters(ply)
    if not chars[armyID] then
        notify(ply, false, "Aucun personnage à supprimer pour cette faction.")
        return
    end

    MedalBarracks.DeleteCharacterRow(ply, armyID)
    chars[armyID] = nil
    MedalBarracks.UpdateCharacterNW(ply)

    -- Si c'était le personnage actif, on retire le rôle : retour au parcours menu.
    if MedalBarracks.GetPlayerCamp(ply) == armyID then
        ply:SetNWString("MedalBarracks_Role", "")
        ply:SetNWString("MedalBarracks_Loadout", "")
    end

    MedalBarracks.SendCharacters(ply)
    notify(ply, true, "Personnage supprimé. Tu peux en créer un nouveau.")
end)
