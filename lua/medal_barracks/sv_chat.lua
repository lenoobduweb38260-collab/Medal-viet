--[[
    Medal Barracks — Commandes chat "!" (l'alias "/" est accepté partout).
    Catalogue complet : COMMANDES_STAFF.md à la racine du dossier de l'addon.
]]

local cfg = MedalBarracks.Config

local function isStaff(ply)
    if not IsValid(ply) then return false end
    local sm = cfg.StaffMenu or {}
    if tostring(sm.MinAccess or "admin") == "superadmin" then return ply:IsSuperAdmin() end
    return ply:IsAdmin() or ply:IsSuperAdmin()
end

-- Chaque commande ouvre un menu côté client via sa concommand.
-- staff = true : réservée au staff (vérifiée ici ET côté net receivers).
local COMMANDS = {
    {cmd = "menu",      desc = "Ouvre le menu principal",              console = function() return cfg.MainMenuCommand or "medal_menu" end},
    {cmd = "caserne",   desc = "Ouvre la caserne (rôles/équipements)", console = function() return cfg.ConsoleCommand or "medal_caserne" end},
    {cmd = "escouades", desc = "Ouvre le menu des escouades",          console = function() return "medal_squads" end},
    {cmd = "musique",   desc = "Gestion de la musique (staff)",        console = function() return (cfg.Music and cfg.Music.Command) or "medal_music" end, staff = true},
    {cmd = "staffmenu", desc = "Menu staff des personnages",           console = function() return (cfg.StaffMenu and cfg.StaffMenu.Command) or "medal_staff_menu" end, staff = true},
}

-- Anti-spam : 0.5 s entre deux commandes chat par joueur.
local lastCmd = {}
local function rateOK(ply)
    local id = ply:SteamID64() or tostring(ply)
    local now = CurTime()
    if (lastCmd[id] or 0) > now then return false end
    lastCmd[id] = now + 0.5
    return true
end

hook.Add("PlayerDisconnected", "MedalBarracks_ChatRate", function(ply)
    lastCmd[ply:SteamID64() or tostring(ply)] = nil
end)

hook.Add("PlayerSay", "MedalBarracks_ChatCommands", function(ply, text)
    if not IsValid(ply) then return end
    local said = string.lower(string.Trim(tostring(text or "")))
    local prefix = string.sub(said, 1, 1)
    if prefix ~= "!" and prefix ~= "/" then return end
    local word = string.sub(said, 2)

    if word == "aide" or word == "commandes" or word == "help" then
        if not rateOK(ply) then return "" end
        ply:ChatPrint("[Medal] Commandes : !menu, !caserne, !escouades, !presenter, !sl <msg>, !radio <msg>" .. (isStaff(ply) and ", !musique, !staffmenu, !frontline, !garageconfig" or ""))
        return ""
    end

    for _, entry in ipairs(COMMANDS) do
        if word == entry.cmd then
            if not rateOK(ply) then return "" end
            if entry.staff and not isStaff(ply) then
                ply:ChatPrint("[Medal] Commande réservée au staff.")
                return ""
            end
            ply:ConCommand(tostring(entry.console()))
            return ""
        end
    end
end)
