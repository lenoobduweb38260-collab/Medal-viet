--[[
    Medal Garage — Garage de véhicules (config partagée).
    - Menu garage : spawn de véhicules débloqués par NIVEAU (compatible avec
      n'importe quel véhicule Workshop, on spawn par class).
    - Système d'ESSENCE par-dessus les véhicules.
    - HUD façon Hell Let Loose quand on est dans un véhicule.
    - Changement de siège façon HLL.
]]

MedalGarage = MedalGarage or {}
MedalGarage.Config = MedalGarage.Config or {}
local cfg = MedalGarage.Config

cfg.Command = "medal_garage"          -- ouvre le garage
cfg.OpenKey = KEY_F4                   -- touche d'ouverture (nil pour désactiver)

-- Niveau du joueur : par défaut on lit le niveau général de medal_barracks.
-- Remplace GetLevel si tu as un autre système.
cfg.LevelNWInt = "medal_level"

-- Rôles autorisés à ouvrir le garage (id de Role dans medal_barracks).
-- Laisse vide {} pour autoriser tout le monde.
cfg.AllowedRoleIDs = {"tank_commander", "crewman", "engineer", "operator", "gunner", "artilleur", "commandant", "chef_section"}

-- Cooldown de spawn (secondes) et limite de véhicules vivants par joueur.
cfg.SpawnCooldown = 30
cfg.MaxVehiclesPerPlayer = 1

-- PLATEFORMES de spawn : les véhicules apparaissent sur une plateforme posée par
-- le staff (outil medal_garage_point) au lieu d'un simple rayon. Le staff place
-- une plateforme, sauvegardée par map ; le véhicule se matérialise dessus.
cfg.RequireGaragePoint = true       -- true = spawn uniquement sur une plateforme
cfg.GaragePointRadius = 600         -- rayon d'action autour de la plateforme (refuel)
cfg.PlatformModel = "models/props_phx/construct/metal_plate_curve4x2.mdl"
cfg.PlatformSpawnHeight = 20        -- hauteur d'apparition du véhicule au-dessus de la plateforme

-- PNJ vendeur : ouvre le garage quand un joueur appuie sur E dessus.
-- Pose-le avec la commande medal_garage_npc_add (staff), sauvegardé par map.
cfg.NPC = {
    Enabled = true,
    Model = "models/player/soldier_stripped.mdl", -- remplace par ton modèle de vendeur
    Name = "MÉCANO DU GARAGE",
    UseText = "Ouvrir le garage",
}

-- =========================
-- Essence
-- =========================
cfg.Fuel = {
    Enabled = true,
    DrainIdle = 0.15,      -- essence/s moteur allumé à l'arrêt
    DrainMoving = 0.9,     -- essence/s à pleine vitesse
    RefuelRate = 12,       -- essence/s en ravitaillement (près d'un garage / bidon)
    RefuelNearGarage = true,
    RefuelKey = KEY_G,     -- maintenir près de ton véhicule pour faire le plein via ravitaillement Soutien
    AutoRefuelAtGarage = true, -- plein automatique quand le véhicule est garé, à l'arrêt, près d'un garage
    -- Consomme aussi le ravitaillement des caisses de Soutien (medal_barracks)
    -- si disponible : 1 essence = SupplyPerFuel de ravitaillement.
    UseSupplyCrates = true,
    SupplyPerFuel = 0.5,
    EmptyStalls = true,    -- true = plus d'essence -> le moteur cale
}

-- =========================
-- Sièges façon HLL (changement de place).
-- Touche pour changer de siège, et noms affichés.
-- Le changement fonctionne pour les véhicules multi-sièges GMod (pods enfants)
-- et, si présents, les API Simfphys / LFS / Glide (détectées automatiquement).
-- =========================
cfg.Seats = {
    Enabled = true,
    SwitchKey = KEY_R,        -- change de siège (comme HLL)
    NextSeatKey = KEY_R,
    Names = {"PILOTE", "MITRAILLEUR", "COMMANDANT", "PASSAGER 1", "PASSAGER 2", "PASSAGER 3"},
}

cfg.HUD = {
    Enabled = true,
    -- HUD façon HLL affiché en bas quand on est dans un véhicule.
    Corner = "bottom",
}

-- =========================
-- Catalogue des véhicules.
-- class = classe GMod du véhicule Workshop (spawn par ents.Create/DarkRP).
-- level = niveau requis, category = onglet, fuel = capacité d'essence.
-- REMPLACE ces exemples par tes véhicules Vietnam (M48 Patton, T-54, M113, UH-1…).
-- =========================
cfg.Categories = {"BLINDÉS", "TRANSPORT", "AÉRIEN", "LOGISTIQUE"}

cfg.Vehicles = {
    {
        name = "JEEP M151",
        class = "prop_vehicle_jeep",         -- exemple vanilla ; mets ta class Workshop
        model = "models/buggy.mdl",
        category = "TRANSPORT",
        level = 1,
        fuel = 100,
        desc = "Véhicule de reconnaissance rapide, 2 places.",
        icon = "",                            -- material optionnel
    },
    {
        name = "CAMION DE RAVITAILLEMENT",
        class = "prop_vehicle_jeep",
        model = "models/buggy.mdl",
        category = "LOGISTIQUE",
        level = 3,
        fuel = 160,
        desc = "Transport de troupes et de matériel.",
    },
    {
        name = "CHAR MOYEN",
        class = "prop_vehicle_jeep",
        model = "models/buggy.mdl",
        category = "BLINDÉS",
        level = 6,
        fuel = 220,
        desc = "Char d'assaut. Réservé aux équipages de char.",
        requireRole = {"tank_commander", "crewman"},
    },
    {
        name = "HÉLICOPTÈRE UH-1",
        class = "prop_vehicle_jeep",
        model = "models/buggy.mdl",
        category = "AÉRIEN",
        level = 10,
        fuel = 200,
        desc = "Appui aérien et évacuation.",
    },
}

cfg.Colors = {
    Olive = Color(112, 126, 74),
    Khaki = Color(148, 156, 108),
    White = Color(232, 234, 222),
    Red = Color(165, 48, 40),
    Panel = Color(12, 14, 11, 244),
}

function MedalGarage.GetLevel(ply)
    if not IsValid(ply) then return 1 end
    return ply:GetNWInt(cfg.LevelNWInt or "medal_level", 1)
end
