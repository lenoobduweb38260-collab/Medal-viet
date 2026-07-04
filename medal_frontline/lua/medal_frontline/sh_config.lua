--[[
    Medal Frontline — Capture de zones façon Hell Let Loose (addon séparé).
    Trois modes de jeu, choisis depuis le panneau staff (medal_frontline_staff) :
      - WARFARE     : 5 secteurs en ligne, chaque camp part avec 2 secteurs,
                      seule la ligne de front est capturable.
      - OFFENSIVE   : un camp attaquant doit capturer les secteurs dans l'ordre,
                      chaque capture ajoute du temps ; les défenseurs tiennent.
      - ESCARMOUCHE : un unique point central ; le tenir rapporte des tickets,
                      premier camp au quota gagne.
]]

MedalFrontline = MedalFrontline or {}
MedalFrontline.Config = MedalFrontline.Config or {}
local cfg = MedalFrontline.Config

cfg.StaffCommand = "medal_frontline_staff"
cfg.MinAccess = "admin" -- admin ou superadmin

-- Les factions correspondent aux camps de l'addon medal_barracks
-- (NWString MedalBarracks_ArmyChoice). L'index 1 est le camp "gauche" du HUD.
cfg.Factions = {"americans", "vietcong"}
cfg.FactionNames = {
    americans = "AMÉRICAINS",
    vietcong = "VIETCONG",
}
cfg.FactionColors = {
    americans = Color(118, 148, 178),
    vietcong = Color(182, 84, 58),
}

cfg.DefaultMode = "warfare"
cfg.Modes = {
    warfare = {
        name = "WARFARE",
        desc = "5 secteurs en ligne. Chaque camp démarre avec 2 secteurs, le centre est neutre. Seule la ligne de front est capturable. Victoire : tous les secteurs, ou majorité à la fin du temps.",
        time = 1800, -- durée de la partie (secondes)
    },
    offensive = {
        name = "OFFENSIVE",
        desc = "Un camp ATTAQUE, l'autre DÉFEND. Les secteurs se capturent dans l'ordre, chaque capture ajoute du temps. Victoire attaquant : tout capturer. Victoire défenseur : tenir jusqu'à la fin.",
        time = 900,
        timePerCap = 240, -- secondes ajoutées à chaque secteur capturé
    },
    skirmish = {
        name = "ESCARMOUCHE",
        desc = "Un unique point central. Le camp qui le tient accumule des tickets. Premier camp au quota de tickets gagne.",
        time = 1200,
        targetTickets = 300,
        ticketRate = 1, -- tickets par seconde de contrôle
    },
}

-- Mécanique de capture.
cfg.TickInterval = 1        -- fréquence de calcul (secondes)
cfg.CaptureRate = 3         -- % de capture par seconde et par joueur d'écart
cfg.MaxCapPlayers = 5       -- écart de joueurs maximum pris en compte
cfg.DecayRate = 2           -- % par seconde de retour vers le propriétaire quand la zone est vide
cfg.DefaultZoneRadius = 900 -- rayon d'un secteur (unités)
cfg.DefaultZoneCount = 5    -- nombre de secteurs (Warfare / Offensive)

-- Compteur de joueurs ACTIFS par camp (affiché sous la barre de secteurs et
-- dans le panneau staff). Les joueurs AFK depuis plus de ActiveAFKSeconds
-- ne sont PAS comptés.
cfg.ActiveAFKSeconds = 300  -- 5 minutes
cfg.ActiveCountInterval = 5

cfg.HUD = {
    Enabled = true,
    Y = 14,                 -- distance du haut de l'écran
    SegmentW = 96,
    SegmentH = 26,
    SegmentGap = 6,
    Skew = 10,              -- inclinaison des segments façon ruban HLL
    ShowTimer = true,
    ShowActiveCounts = true, -- "tab" des joueurs actifs des deux camps
    ShowOrder = true,        -- flèches d'ordre de capture au-dessus de la barre
}

-- SWEP de création de zones (staff) : place-toi et clique pour créer/déplacer.
cfg.ZoneTool = {
    SWEP = "medal_zone_tool",
    HighlightDistance = 8000, -- distance max d'affichage des zones en surbrillance
}

-- Carte tactique (SWEP) : marqueurs visibles UNIQUEMENT par les SL / Commandants.
-- Le rendu "vue de dessus" utilise render.RenderView depuis le ciel de la map.
cfg.Map = {
    SWEP = "medal_map",
    MaxMarkers = 24,          -- marqueurs simultanés par faction
    -- Hauteur de la caméra top-down au-dessus du centre de la map.
    CameraHeight = 12000,
    -- Rôles medal_barracks considérés comme "commandement" (voient/posent les
    -- marqueurs). Les chefs d'escouade (NWBool MedalBarracks_SquadLeader) le sont
    -- aussi automatiquement.
    LeaderRoleIDs = {"commandant", "officier", "chef_section", "commissaire", "tank_commander"},
    MarkerTypes = {
        {id = "attack",  name = "ATTAQUE",   color = Color(200, 70, 55)},
        {id = "defend",  name = "DÉFENSE",   color = Color(90, 130, 190)},
        {id = "move",    name = "MOUVEMENT", color = Color(198, 181, 94)},
        {id = "enemy",   name = "ENNEMI",    color = Color(210, 60, 60)},
        {id = "objective", name = "OBJECTIF", color = Color(120, 200, 110)},
    },
}

-- Zones par map (optionnel : le staff peut aussi les définir en jeu avec le
-- panneau staff, elles sont alors sauvegardées dans data/medal_frontline/).
-- Exemple :
-- cfg.Zones = {
--     ["rp_stardestroyer"] = {
--         {name = "POINT ALPHA",   pos = Vector(-4200, 0, 64), radius = 900},
--         {name = "POINT BRAVO",   pos = Vector(-2100, 0, 64), radius = 900},
--         {name = "POINT CHARLIE", pos = Vector(0, 0, 64),     radius = 900},
--         {name = "POINT DELTA",   pos = Vector(2100, 0, 64),  radius = 900},
--         {name = "POINT ECHO",    pos = Vector(4200, 0, 64),  radius = 900},
--     },
-- }
cfg.Zones = {}

cfg.ZoneNames = {"POINT ALPHA", "POINT BRAVO", "POINT CHARLIE", "POINT DELTA", "POINT ECHO", "POINT FOX", "POINT GOLF"}
