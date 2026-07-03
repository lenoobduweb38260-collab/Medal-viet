--[[
    Medal Barracks Selection - Vietnam Main Menu Edition
    Menu principal -> JOUER -> choix de faction -> caserne/loadout.
    Chaque faction peut avoir 1 personnage maximum par joueur.
]]

MedalBarracks = MedalBarracks or {}
MedalBarracks.Config = MedalBarracks.Config or {}

local cfg = MedalBarracks.Config

-- Commandes client.
cfg.ConsoleCommand = "medal_caserne"      -- ouvre directement la caserne si une faction est choisie
cfg.MainMenuCommand = "medal_menu"        -- ouvre le menu principal

-- Touche d'ouverture de la caserne. Mets nil pour désactiver le bind automatique.
cfg.OpenKey = KEY_F6

-- Niveau du joueur lu via NWInt. Branche ton système XP en remplaçant cfg.GetPlayerLevel plus bas.
cfg.LevelNWInt = "medal_level"
cfg.XPNWInt = "medal_xp"
cfg.NextXPNWInt = "medal_next_xp"
cfg.DefaultNextXP = 44000

--[[
===============================================================================
CONFIG RAPIDE - RÔLES / ARMES / IMAGES / ICÔNES
===============================================================================

1) Où mettre les codes des armes ?
   Dans chaque loadout, dans la table "weapons" :

   L("standard", "MODÈLE STANDARD", 1, {
       "weapon_smg1",          -- code / class de l'arme GMod
       "weapon_pistol",        -- exemple vanilla
       "m9k_m16a4_acog",       -- exemple addon Workshop
       "cw_ak74",              -- exemple CW2 / ARC9 / TFA selon ton serveur
   }, {
       SMG1 = 180,               -- type de munition + quantité
       Pistol = 45,
   }, {
       "Radio", "Jumelles"   -- textes/icônes d'équipement affichés dans l'UI
   }, {
       image = "medal/loadouts/rifle.png",
       previewImage = "medal/loadouts/rifle_big.png"
   })

   Tu récupères le code d'une arme en jeu avec :
   lua_run_cl print(LocalPlayer():GetActiveWeapon():GetClass())

2) Où mettre les images de loadout ?
   Dans garrysmod/materials/medal/loadouts/ton_image.png
   Puis dans le loadout :
       image = "medal/loadouts/ton_image.png"
       previewImage = "medal/loadouts/ton_grand_preview.png"

3) Où mettre les icônes des rôles ?
   Dans garrysmod/materials/medal/roles/ton_role.png
   Puis soit dans cfg.RoleIconMaterials plus bas :
       cfg.RoleIconMaterials["fusilier"] = "medal/roles/fusilier.png"
   soit directement dans le Role(..., { iconMaterial = "medal/roles/fusilier.png" })

4) Où lier un rôle à un job DarkRP ?
   Dans le Role(...), remplace le 3e argument par le nom de la constante du job :
       Role("fusilier", "FUSILIER", "TEAM_MEDAL_US_FUSILIER", ... )

   Si ton job DarkRP n'a pas de constante globale, utilise jobName :
       Role("fusilier", "FUSILIER", "", "Fusilier US", ... )

===============================================================================
]]

-- Système XP intégré.
-- XP générale : donnée automatiquement toutes les X secondes.
-- XP de rôle : donnée à chaque kill, sur le rôle actuellement sélectionné.
cfg.XP = {
    Enabled = true,
    SaveInSQLite = true,
    SQLTable = "medal_barracks_xp",

    General = {
        Enabled = true,
        Interval = 300,          -- 300 secondes = 5 minutes
        Amount = 25,             -- petite quantité d'XP générale toutes les 5 minutes
        RequireRoleSelected = true, -- true = évite le farm AFK dans le menu, il faut avoir choisi un rôle
        MaxLevel = 100,
        BaseNextXP = 350,        -- XP requis du niveau 1 vers 2
        Growth = 1.16,           -- augmente progressivement la difficulté
        Notify = true,
    },

    Role = {
        Enabled = true,
        KillXP = 4,              -- très petite quantité d'XP de rôle par kill
        MaxLevel = 8,            -- correspond aux chiffres romains I à VIII dans le menu
        BaseNextXP = 60,         -- XP requis du niveau de rôle 1 vers 2
        Growth = 1.35,
        Notify = true,
        IgnoreTeamKills = true,
    },

    NotifyLevelUp = true,
}

-- Niveaux par rôle : les chiffres romains dans la liste des rôles affichent CE niveau-là.
-- Par défaut, l'addon lit un NWInt par rôle : medal_role_level_<army>_<role>
-- Exemple côté serveur : ply:SetNWInt("medal_role_level_americans_fusilier", 4)
cfg.RoleLevelNWIntPrefix = "medal_role_level_"
cfg.RoleXPNWIntPrefix = "medal_role_xp_"
cfg.RoleNextXPNWIntPrefix = "medal_role_next_xp_"
cfg.DefaultRoleLevel = 1
cfg.MaxRoleLevel = 8
cfg.UseRoleLevelForLoadoutUnlocks = true

-- Icônes de rôles globales. La clé = id du rôle dans Role("id", ...).
-- Tu peux aussi mettre l'icône directement dans le Role avec { iconMaterial = "..." }.
cfg.RoleIconMaterials = {
    -- Laisse vide si tu veux utiliser les symboles texte.
    -- Décommente / ajoute tes icônes quand les fichiers existent dans garrysmod/materials/medal/roles/.
    -- fusilier = "medal/roles/fusilier.png",
    -- medic = "medal/roles/medic.png",
    -- commandant = "medal/roles/commandant.png",
}

-- Materials configurables pour illustrer les armes/équipements lorsque tu n'as pas mis d'image directement dans le loadout.
-- À gauche : le code de l'arme donné par GetClass(). À droite : ton image dans garrysmod/materials/.
-- Exemple : ["m9k_m16a4_acog"] = "medal/loadouts/m16.png",
cfg.WeaponIconMaterials = {
    weapon_pistol = "medal/loadouts/pistol.png",
    weapon_357 = "medal/loadouts/pistol.png",
    weapon_smg1 = "medal/loadouts/rifle.png",
    weapon_ar2 = "medal/loadouts/rifle.png",
    weapon_frag = "medal/loadouts/grenade.png",
    med_kit = "medal/loadouts/medkit.png",
}

cfg.EquipmentIconMaterials = {
    ["Carte tactique"] = "medal/loadouts/map.png",
    ["Radio"] = "medal/loadouts/radio.png",
    ["Radio longue portée"] = "medal/loadouts/radio.png",
    ["Jumelles"] = "medal/loadouts/binoculars.png",
    ["Trousse médicale"] = "medal/loadouts/medkit.png",
    ["Bandages"] = "medal/loadouts/medkit.png",
    ["Outils"] = "medal/loadouts/tools.png",
    ["Caisse munitions"] = "medal/loadouts/ammo.png",
}


-- HUD de base GMod à masquer pour garder l'immersion Medal.
-- L'addon ne supprime pas tes HUD d'autres addons, il masque seulement les éléments listés ici.
cfg.HideDefaultHUD = {
    Enabled = true,
    Elements = {
        CHudHealth = true,
        CHudBattery = true,
        CHudAmmo = true,
        CHudSecondaryAmmo = true,
        CHudWeaponSelection = true,
        CHudCrosshair = true,
        CHudDamageIndicator = false,
        CHudChat = false,
    },
}

-- Weapon selector custom, bas droite, style HLL/Rising Storm.
-- Quand le joueur change d'arme, le menu se déroule puis disparaît automatiquement.
-- Mets tes images dans garrysmod/materials/medal/weapons/ et lie-les ici avec la class de l'arme.
cfg.WeaponSelector = {
    Enabled = true,
    HideDefault = true,
    HideDelay = 2.8,
    FadeTime = 0.35,
    MaxItems = 7,
    RightMargin = 42,
    BottomMargin = 118,
    ItemW = 330,
    ItemH = 54,
    Gap = 7,
    Padding = 16,
    PanelMaterial = "medal/ui/weapon_selector_panel.png",
    SlotMaterial = "medal/ui/weapon_selector_slot.png",

    -- Image par arme : clé = code d'arme GMod / class.
    WeaponIcons = {
        weapon_pistol = "medal/loadouts/pistol.png",
        weapon_357 = "medal/loadouts/pistol.png",
        weapon_smg1 = "medal/loadouts/rifle.png",
        weapon_ar2 = "medal/loadouts/rifle.png",
        weapon_frag = "medal/loadouts/grenade.png",
        med_kit = "medal/loadouts/medkit.png",
        weapon_crowbar = "medal/weapons/shovel.png",
        weapon_stunstick = "medal/weapons/shovel.png",
    },

    -- Nom affiché. Si absent, l'addon utilise le PrintName de l'arme puis son code.
    Names = {
        weapon_pistol = "Pistolet",
        weapon_smg1 = "Fusil / SMG",
        weapon_ar2 = "Fusil automatique",
        weapon_frag = "Grenade",
        med_kit = "Trousse médicale",
        weapon_crowbar = "Pelle",
        weapon_stunstick = "Pelle",
    },
}

cfg.UI = {
    FactionCardImageMode = "contain", -- contain = ne coupe jamais l'image ; cover = remplit en coupant
    FactionCardOverlayText = false,    -- false conseillé si tes images de card contiennent déjà le titre
    MainMenuRemoveWhiteLines = true,
}

-- DA globale demandée : mélange Hell Let Loose / Black Ops Cold War / Rising Storm.
-- Tous les boutons passent par cette direction artistique : panneau sombre, filet rouge, bordure fine, typo militaire.
cfg.DAStyle = {
    Enabled = true,
    ButtonMaterial = "medal/ui/button_hll_panel.png",
    PanelMaterial = "medal/ui/panel_hll_dark.png",
    TipMaterial = "medal/ui/tip_panel.png",
    LeftShadowMaterial = "medal/ui/shadow_left_gradient.png",

    ButtonAlpha = 150,
    ButtonHoverAlpha = 188,
    ButtonBorderAlpha = 58,
    ButtonHoverBorderAlpha = 135,
    RedStripeWidth = 4,
}


-- DarkRP / loadout.
cfg.RequireValidJob = false       -- true = refuse si le job DarkRP configuré n'existe pas
cfg.StripWeapons = true
cfg.ApplyModel = true
cfg.ApplyLoadout = true

-- Quand un rôle est choisi, l'addon change le joueur vers le job DarkRP du rôle.
-- En DarkRP, le spawn se fera donc à l'endroit configuré pour le job concerné.
cfg.DarkRPJobSpawn = {
    Enabled = true,
    ChangeTeam = true,
    SpawnAfterJobChange = true,
    ApplyKitAfterSpawn = true,
    SpawnDelay = 0.20,
    KitDelay = 0.45,
}

-- Fond utilisé par le menu principal, le choix de faction et la caserne.
-- Le fichier est fourni dans materials/medal/menu/bg_vietnam.png.
cfg.BackgroundMaterial = "medal/menu/bg_vietnam_da_reference.png"

cfg.MainMenu = {
    Enabled = true,
    OpenOnInitialSpawn = true,
    Title = "MEDAL VIETNAM",
    Subtitle = "BIENVENUE SUR",
    ServerLine = "GARRY'S MOD - SERVEUR VIETNAM WAR RP",
    PlayText = "JOUER",
    PlaySubText = "",
    OptionsText = "OPTION",
    QuitText = "QUITTER",
    CloseOnEscape = false,

    -- Liens affichés avec des materials en bas à droite.
    DiscordURL = "", -- exemple : "https://discord.gg/tonserveur"
    WebsiteURL = "", -- exemple : "https://medal-community.fr"
    DiscordIcon = "medal/ui/discord.png",
    WebsiteIcon = "medal/ui/globe.png",

    -- Le bouton QUITTER ouvre une confirmation avant le disconnect.
    QuitRequiresConfirmation = true,
}

-- DA menu principal : style inspiré du dernier visuel fourni.
-- La vidéo reste derrière, et cette couche crée le grand dégradé d'ombre à gauche.
cfg.MainMenuStyle = {
    TitleX = 132,
    TitleY = 275,
    ServerLineY = 405,
    ButtonX = 132,
    ButtonY = 500,
    ButtonW = 395,
    ButtonH = 74,
    ButtonGap = 26,
    LinkY = 988,

    -- Style de boutons inspiré de l'image de référence : pas de gros blocs brillants.
    ButtonTextInset = 34,
    ButtonSubInset = 42,
}

-- Effet sombre conservé au-dessus de la vidéo, mais derrière les boutons.
-- La vidéo est affichée en fond, puis cet overlay garde la DA sombre/cinématique côté menu.
cfg.MainMenuOverlay = {
    Enabled = true,
    FullscreenAlpha = 18,
}

-- Zone gauche du menu principal.
-- Mode "shadow" = grand dégradé noir comme sur la DA demandée :
-- sombre à gauche, fondu propre vers le centre, sans bloc coupé net.
-- Mode "video" reste disponible si tu veux remplacer la zone gauche par une vidéo cropée.
cfg.MainMenuLeftZone = {
    Enabled = true,
    Mode = "shadow", -- "shadow", "video", "fog", "none"

    Width = 1040,         -- largeur totale du fondu vers le centre
    SolidWidth = 520,     -- zone vraiment sombre avant le dégradé
    DarkAlpha = 255,
    FadeAlpha = 246,
    FadeWidth = 820,
    GradientPower = 1.78, -- plus bas = fondu large et cinématique comme l'image demandée
    TopVignetteAlpha = 88,
    BottomVignetteAlpha = 122,
    ShadowMaterial = "medal/ui/shadow_left_gradient.png",

    Fog = {
        Enabled = false,
        Alpha = 18,
        Bands = 8,
        Speed = 0.06,
        MinWidth = 140,
        MaxWidth = 420,
        Color = Color(70, 74, 78, 255),
        SoftLayer = true,
        SoftAlpha = 8,
        SoftBands = 4,
    },

    -- Active uniquement si Mode = "video".
    -- Le son est coupé par défaut pour éviter de doubler le son de la vidéo principale.
    Video = {
        Enabled = false,
        URL = "", -- exemple Dropbox .webm : "https://www.dropbox.com/scl/fi/xxx/left_zone.webm?rlkey=xxx&dl=0"
        Volume = 0,
        Muted = true,
        Loop = true,
        Opacity = 0.95,
        ObjectFit = "cover",

        -- Crop de la vidéo dans la zone gauche :
        -- X/Y = position du focus en pourcentage, Zoom = agrandissement.
        -- Exemple : X=30 garde plutôt la gauche de la vidéo, X=70 garde plutôt la droite.
        Crop = {
            X = 50,
            Y = 50,
            Zoom = 1.00,
        },

        Filter = "brightness(.52) contrast(1.18) saturate(.88)",
        DarkOverlayAlpha = 150,
    },
}

-- Conseils affichés aléatoirement en bas au milieu du menu.
-- Si le texte est trop long, l'UI le coupe automatiquement en plusieurs lignes dans son cadre.
cfg.Tips = {
    Enabled = true,
    Interval = 10,
    Width = 760,
    Prefix = "ASTUCE :",
    YOffset = 104,
    Material = "medal/ui/tip_panel.png",
    Texts = {
        "Crée ton personnage avant de choisir un rôle : aucun spawn n'est autorisé sans rôle.",
        "Les chiffres romains indiquent ton niveau dans le rôle sélectionné.",
        "Les factions sont équilibrées automatiquement : rejoins le camp qui a besoin de renforts.",
        "Présente-toi aux soldats inconnus pour débloquer leur identité RP.",
    }
}

-- Binds propres à l'addon. Ils sont sauvegardés côté client avec cookie.
-- Ce ne sont pas les paramètres GMod : l'UI récupère/modifie uniquement les touches utilisées par l'addon.
cfg.Keybinds = {
    {id = "main_menu", label = "Menu principal", description = "Ouvre le menu Medal Vietnam.", defaultKey = KEY_F6, action = "open_main_menu"},
    {id = "barracks", label = "Caserne", description = "Ouvre directement les rôles si le personnage existe.", defaultKey = KEY_F7, action = "open_barracks"},
    {id = "present", label = "Se présenter", description = "Présente ton personnage aux joueurs proches.", defaultKey = KEY_F3, action = "present"},
}

-- Binds GMod natifs affichés dans notre UI.
-- IMPORTANT : l'addon lit les touches actuelles avec input.LookupBinding(command),
-- mais ne modifie jamais directement les binds du joueur avec bind <touche> <commande>.
-- Tu peux ajouter/enlever des commandes GMod ici.
cfg.GModBinds = {
    {id = "forward", label = "Avancer", command = "+forward", defaultKeyName = "z"},
    {id = "back", label = "Reculer", command = "+back", defaultKeyName = "s"},
    {id = "moveleft", label = "Aller à gauche", command = "+moveleft", defaultKeyName = "q"},
    {id = "moveright", label = "Aller à droite", command = "+moveright", defaultKeyName = "d"},
    {id = "jump", label = "Sauter", command = "+jump", defaultKeyName = "space"},
    {id = "duck", label = "S'accroupir", command = "+duck", defaultKeyName = "ctrl"},
    {id = "speed", label = "Courir", command = "+speed", defaultKeyName = "shift"},
    {id = "walk", label = "Marcher", command = "+walk", defaultKeyName = "alt"},
    {id = "use", label = "Utiliser", command = "+use", defaultKeyName = "e"},
    {id = "attack", label = "Tirer", command = "+attack", defaultKeyName = "mouse1"},
    {id = "attack2", label = "Visée / tir secondaire", command = "+attack2", defaultKeyName = "mouse2"},
    {id = "reload", label = "Recharger", command = "+reload", defaultKeyName = "r"},
    {id = "flashlight", label = "Lampe torche", command = "impulse 100", defaultKeyName = "f"},
    {id = "voice", label = "Micro vocal", command = "+voicerecord", defaultKeyName = "x"},
    {id = "chat", label = "Chat général", command = "messagemode", defaultKeyName = "y"},
    {id = "teamchat", label = "Chat équipe", command = "messagemode2", defaultKeyName = "u"},
    {id = "context", label = "Menu contextuel", command = "+menu_context", defaultKeyName = "c"},
    {id = "spawnmenu", label = "Spawn menu", command = "+menu", defaultKeyName = "q"},
    {id = "scoreboard", label = "Scoreboard", command = "+showscores", defaultKeyName = "tab"},
    {id = "invnext", label = "Arme suivante", command = "invnext", defaultKeyName = "mwheelup"},
    {id = "invprev", label = "Arme précédente", command = "invprev", defaultKeyName = "mwheeldown"},
    {id = "slot1", label = "Slot arme 1", command = "slot1", defaultKeyName = "1"},
    {id = "slot2", label = "Slot arme 2", command = "slot2", defaultKeyName = "2"},
    {id = "slot3", label = "Slot arme 3", command = "slot3", defaultKeyName = "3"},
}

-- Adaptateur GMod -> Medal.
-- Le menu OPTIONS récupère les touches GMod du joueur en lecture seule.
-- Ces mappings permettent, si tu le souhaites, de copier une touche GMod dans un bind serveur/Medal,
-- sans jamais modifier les paramètres GMod du joueur.
-- Exemple : {addonBind = "present", fromCommand = "+use"} fera utiliser à /presenter la même touche que UTILISER.
cfg.GModBindAdapter = {
    Enabled = true,
    AutoUseMirroredKeys = false, -- false = les binds Medal gardent leurs touches propres ; true = ils suivent les commandes GMod ci-dessous
    Mappings = {
        -- {addonBind = "present", fromCommand = "+use"},
        -- {addonBind = "main_menu", fromCommand = "+menu_context"},
    },
}

-- Certaines convars sont bloquées par GMod avec RunConsoleCommand.
-- L'UI les affiche, mais ne tente pas de les appliquer si readOnly = true.
cfg.BlockedConVars = {
    fov_desired = true,
}

-- Paramètres graphiques client affichés dans le menu OPTION.
-- Ces réglages appliquent des convars côté joueur avec notre UI quand elles ne sont pas bloquées.
cfg.GraphicsSettings = {
    {id = "fps_max", label = "Limite FPS", type = "slider", convar = "fps_max", min = 30, max = 300, decimals = 0, default = 144},
    {id = "fov_desired", label = "Champ de vision", type = "slider", convar = "fov_desired", min = 75, max = 110, decimals = 0, default = 90, readOnly = true, blockedReason = "ConVar bloquée par GMod sur certains serveurs"},
    {id = "mat_queue_mode", label = "Multi-core rendering", type = "choice", convar = "mat_queue_mode", choices = {
        {name = "Auto", value = "-1"},
        {name = "Désactivé", value = "0"},
        {name = "Activé", value = "2"},
    }, default = "-1"},
    {id = "gmod_mcore_test", label = "Optimisation multi-core GMod", type = "bool", convar = "gmod_mcore_test", default = "1"},
    {id = "r_shadows", label = "Ombres dynamiques", type = "bool", convar = "r_shadows", default = "1"},
    {id = "r_3dsky", label = "Ciel 3D", type = "bool", convar = "r_3dsky", default = "1"},
    {id = "mat_specular", label = "Reflets spéculaires", type = "bool", convar = "mat_specular", default = "1"},
    {id = "mat_hdr_level", label = "HDR", type = "choice", convar = "mat_hdr_level", choices = {
        {name = "Désactivé", value = "0"},
        {name = "Simple", value = "1"},
        {name = "Complet", value = "2"},
    }, default = "2"},
    {id = "cl_detaildist", label = "Distance détails", type = "slider", convar = "cl_detaildist", min = 0, max = 2400, decimals = 0, default = 1200},
}

-- Menu staff de gestion des personnages.
cfg.StaffMenu = {
    Enabled = true,
    Command = "medal_staff_menu",
    MinAccess = "admin", -- admin ou superadmin
}

-- Système de relations RP : inconnus / présentation.
cfg.Relations = {
    Enabled = true,
    SQLTable = "medal_barracks_relations",
    UnknownName = "Inconnu",
    PresentCommand = "/presenter",
    PresentConsoleCommand = "medal_present",
    PresentDistance = 150,

    -- Dans une même escouade, tout le monde se connaît automatiquement.
    SquadNWString = "MedalBarracks_SquadID",
    AutoKnownSameSquad = true,

    -- Même faction uniquement : officiers/commandants connaissent automatiquement leurs soldats.
    -- Cette règle ne bypass jamais entre US et Vietcong.
    LeadershipBypassSameFaction = true,
    CommanderRoleIDs = {"commandant", "chef_section", "tank_commander"},
    OfficerRoleIDs = {"officier", "commissaire"},
}

-- Le choix de faction se fait uniquement après le clic sur JOUER.
cfg.CampSelection = {
    Enabled = true,
    OpenOnInitialSpawn = false,
    RequireCampBeforeBarracks = true,
    ShowOnlyChosenCampInBarracks = true,
    LockChoice = false,          -- false = le joueur peut choisir Américains ou Vietcong depuis le menu Jouer
    RememberWithPData = false,   -- sauvegarde seulement la dernière faction active si true
    OpenBarracksAfterChoice = false, -- maintenant : JOUER -> faction -> personnage -> rôles
    OpenBarracksDelay = 0.15,
}

-- Équilibrage du choix de faction.
-- Exemple : si Américains = 45/60 et Vietcong = 40/60, les Américains sont grisés.
-- Le joueur ne peut rejoindre une faction que si le choix ne crée pas un écart supérieur à Tolerance.
-- Page faction plein écran : chaque faction occupe une moitié complète de l'écran.
cfg.FactionPage = {
    SplitFullscreen = true,
    HeaderY = 42,
    InfoY = 88,
    BottomTitleY = 165,
    UseCoverImages = true, -- les 2 camps remplissent réellement tout l'écran
    DimAlpha = 82,
    HoverBright = 34,
}

-- Page personnage : style dossier de déploiement / préparation équipement.
cfg.CharacterMenuStyle = {
    CardX = 120,
    CardY = 210,
    CardW = 500,
    CardH = 680,
    InfoX = 675,
    InfoY = 230,
    InfoW = 900,
    InfoH = 520,
    Title = "DOSSIER DE DÉPLOIEMENT",
    Subtitle = "IDENTITÉ OPÉRATIONNELLE",
}

cfg.CampBalance = {
    Enabled = true,
    MaxPlayersPerFaction = 60,
    Tolerance = 2,

    -- true = prend en compte les joueurs dès qu'ils ont sélectionné une faction, même avant le spawn.
    CountPlayersWithSelectedCamp = true,

    -- true = bloque aussi si la faction atteint MaxPlayersPerFaction.
    BlockWhenFull = true,

    -- Affichage UI de la page choix de faction.
    ShowCountsOnCards = true,
    GreyBlockedCards = true,
    BlockedText = "ÉQUILIBRAGE EN COURS",
}

-- Limite de personnage par faction.
-- L'addon crée/retient 1 slot côté Américains et 1 slot côté Vietcong.
-- Le joueur peut donc avoir au maximum : 1 personnage américain + 1 personnage vietcong.
cfg.CharacterLimit = {
    Enabled = true,
    MaxPerArmy = 1,
    RememberWithPData = true,
    PDataKey = "MedalBarracks_Characters_Vietnam",
    AllowRoleChangeWithinFaction = true, -- true = le personnage existant peut changer de rôle/loadout
}


-- Création de personnage stockée dans la base SQLite du serveur.
-- 1 personnage maximum par faction. Nom/prénom verrouillés après création.
-- Tant que le joueur est dans le parcours menu/faction/personnage/rôle sans rôle validé,
-- il est retiré du jeu actif : invisible, bloqué, sans armes, et non considéré comme déployé.
cfg.SpawnGate = {
    Enabled = true,
    HidePlayerWhileInMenu = true,
    SpectateWhileInMenu = true,
    StripWeaponsWhileInMenu = true,
    GodWhileInMenu = true,
    PreventDeathRespawnWithoutRole = true,
}

cfg.CharacterCreation = {
    Enabled = true,
    UseServerSQL = true,
    SQLTable = "medal_barracks_characters",
    RequireCharacterBeforeRoles = true,
    PreventSpawnWithoutRole = true,
    FreezeUntilRoleSelected = true,
    OpenMainMenuIfNoRole = true,
    ForceSpawnAfterRoleSelection = false,

    MinNameLength = 2,
    MaxNameLength = 24,
    MinAge = 16,
    MaxAge = 80,

    AllowEditAfterCreation = true,
    AllowNameEditAfterCreation = false,
    AllowModelChoice = false,

    Fields = {
        age = true,
        nationality = true,
        description = true,
    },
}

-- Aperçu du modèle dans la carte personnage.
-- CamPos plus loin = modèle plus reculé. Le bas de la carte est réservé au nom/prénom.
cfg.CharacterPreview = {
    FOV = 30,
    CamPos = Vector(145, 18, 58),
    LookAt = Vector(0, 0, 42),
    PanelTop = 38,
    PanelBottomSpace = 190,
    EntityYaw = 24,
}

-- Animations et sons.
-- Les sons acceptent soit un chemin local GMod, soit une table avec URL directe HTTPS.
-- IMPORTANT : un lien YouTube ne fonctionne pas ici. Il faut un lien direct vers .mp3 / .ogg / .wav.
-- Exemple direct URL : {url = "https://cdn.ton-site.fr/medal/main_ambient.mp3", volume = 0.28, loop = true}
-- Exemple collection Workshop : "medal/ui/radio_open.wav" placé dans garrysmod/sound/medal/ui/radio_open.wav
cfg.Animations = {
    Enabled = true,
    TransitionDuration = 0.72,
    SlideDuration = 0.34,
    MenuZoom = true,
}

cfg.Sounds = {
    -- Sons de boutons totalement désactivés.
    -- Laisse vide pour éviter les bruitages GMod type "button14/button17".
    EnableButtonSounds = false,
    UIHover = "",
    UIClick = "",
    UIBack = "",

    -- Transitions : laisse vide si tu ne veux aucun son pendant les changements d'écran.
    -- Tu peux mettre plus tard un son radio/ambiance custom depuis ta collection ou un lien direct.
    RadioTransition = "",
    WarTransition = "",
    CharacterCreated = "",
    RoleSelected = "",

    -- Musique / ambiance du menu.
    -- Version URL directe, jouée côté client pour tous les joueurs :
    -- MainAmbient = {url = "https://cdn.ton-domaine.fr/medal/main_ambient.mp3", volume = 0.25, loop = true},
    -- Version collection Workshop/FastDL :
    -- MainAmbient = {path = "medal/ui/main_ambient.wav", volume = 0.22, loop = false},
    MainAmbient = "",
}

-- Sons locaux à envoyer aux joueurs quand ils sont dans ton addon / collection.
-- Ne mets PAS les URL ici. Mets seulement les chemins depuis garrysmod/sound/.
cfg.DownloadSounds = {
    -- "medal/ui/main_ambient.wav",
    -- "medal/ui/radio_open.wav",
}


-- Vidéos / cinématiques via Dropbox.
-- Tu peux coller des liens Dropbox partagés classiques, l'addon les convertit automatiquement.
-- Exemple accepté : https://www.dropbox.com/scl/fi/xxxx/menu_background.mp4?rlkey=xxxx&dl=0
-- L'addon le transforme côté client en lien lisible avec dl=1 / dl.dropboxusercontent.com.
-- Recommandé : héberge un manifest.json sur Dropbox, puis mets son lien partagé dans ManifestURL.
cfg.RemoteMedia = {
    -- Activé pour lire la vidéo Dropbox directement en fond du menu principal.
    Enabled = true,

    -- Tu peux laisser ManifestURL vide si tu veux seulement utiliser MainMenuDropboxVideo ci-dessous.
    -- Exemple Dropbox manifest : "https://www.dropbox.com/scl/fi/xxxx/manifest.json?rlkey=xxxx&dl=0"
    -- Exemple CDN direct : "https://cdn.ton-domaine.fr/medal_vietnam/manifest.json"
    ManifestURL = "",

    Dropbox = {
        Enabled = true,
        ForceRaw = true,
        PreferContentHost = true, -- remplace www.dropbox.com par dl.dropboxusercontent.com
        DirectMode = "dl", -- "dl" = dl=1, conseillé pour DHTML GMod ; "raw" = raw=1
    },

    -- false ici car on utilise directement la vidéo configurée plus bas, sans manifest obligatoire.
    -- Mets true uniquement si tu ajoutes un manifest.json Dropbox/CDN.
    ClientFetch = false,

    -- Recharge le manifest toutes les X secondes si ClientFetch = true.
    RefreshInterval = 300,

    -- Autorise les URLs http:// non sécurisées. Déconseillé.
    AllowInsecureHTTP = false,

    -- Si une vidéo de fond est utilisée, son opacité permet de garder l'UI lisible.
    BackgroundVideoAlpha = 0.72,

    -- Si un menu n'a pas encore d'URL vidéo dédiée, il garde automatiquement
    -- la vidéo du main menu derrière l'UI au lieu de repasser sur le fond statique.
    ReuseMainVideoWhenScreenEmpty = true,

    -- Vidéo de fond du menu principal configurée directement.
    -- Tu peux coller ici un lien Dropbox partagé en dl=0, l'addon le convertit tout seul.
    MainMenuDropboxVideo = {
        Enabled = true,
        URL = "https://www.dropbox.com/scl/fi/uwkm6t3htbdn28tl00z5b/California-Dreamin.webm?rlkey=z8pqdwouykd8vxlxd1akoq3bu&st=hk2u282r&dl=0",
        Volume = 0.35, -- 0 = muet, 0.25 = discret, 1 = volume max
        Muted = false,
        Loop = true,
        Opacity = 0.72,
        ObjectFit = "cover",
        Filter = "brightness(.62) contrast(1.12) saturate(.92)",
    },

    -- Vidéos directes par menu.
    -- Colle ici tes liens Dropbox .webm / .mp4 pour animer chaque écran.
    -- L'addon convertit automatiquement les liens Dropbox partagés dl=0 vers un lien lisible par DHTML.
    -- Laisse URL vide sur un écran pour réutiliser le fond principal ou le fond statique.
    ScreenVideos = {
        main_menu_background = {
            Enabled = true,
            URL = "https://www.dropbox.com/scl/fi/uwkm6t3htbdn28tl00z5b/California-Dreamin.webm?rlkey=z8pqdwouykd8vxlxd1akoq3bu&st=hk2u282r&dl=0",
            Volume = 0.35,
            Muted = false,
            Loop = true,
            Opacity = 0.72,
            ObjectFit = "cover",
            Filter = "brightness(.62) contrast(1.12) saturate(.92)",
        },

        faction_background = {
            Enabled = false,
            URL = "",
            Volume = 0,
            Muted = true,
            Loop = true,
            Opacity = 0.72,
            ObjectFit = "cover",
            Filter = "brightness(.62) contrast(1.12) saturate(.92)",
        },

        character_background = {
            Enabled = false,
            URL = "",
            Volume = 0,
            Muted = true,
            Loop = true,
            Opacity = 0.72,
            ObjectFit = "cover",
            Filter = "brightness(.62) contrast(1.12) saturate(.92)",
        },

        barracks_background = {
            Enabled = false,
            URL = "",
            Volume = 0,
            Muted = true,
            Loop = true,
            Opacity = 0.72,
            ObjectFit = "cover",
            Filter = "brightness(.58) contrast(1.15) saturate(.88)",
        },

        options_background = {
            Enabled = false,
            URL = "",
            Volume = 0,
            Muted = true,
            Loop = true,
            Opacity = 0.60,
            ObjectFit = "cover",
            Filter = "brightness(.52) contrast(1.2) saturate(.80)",
        },

        staff_background = {
            Enabled = false,
            URL = "",
            Volume = 0,
            Muted = true,
            Loop = true,
            Opacity = 0.60,
            ObjectFit = "cover",
            Filter = "brightness(.48) contrast(1.22) saturate(.75)",
        },
    },

    -- Médias utilisés par l'addon. Les valeurs correspondent aux clés du manifest JSON.
    Usage = {
        MainMenuBackground = "main_menu_background",
        FactionBackground = "faction_background",
        CharacterBackground = "character_background",
        BarracksBackground = "barracks_background",
        OptionsBackground = "options_background",
        StaffBackground = "staff_background",
        MainMenuAmbient = "main_menu_ambient",

        MainToFactionCinematic = "main_to_faction",
        FactionToCharacterCinematic = "faction_to_character",
        CharacterToRolesCinematic = "character_to_roles",
        SpawnCinematic = "spawn_cinematic",
    },

    -- Si aucun manifest n'est disponible, tu peux définir des médias ici.
    -- La vidéo du main menu est déjà renseignée via MainMenuDropboxVideo au-dessus.
    Fallbacks = {
        main_menu_background = {
            type = "video",
            url = "https://www.dropbox.com/scl/fi/uwkm6t3htbdn28tl00z5b/California-Dreamin.webm?rlkey=z8pqdwouykd8vxlxd1akoq3bu&st=hk2u282r&dl=0",
            loop = true,
            muted = false,
            volume = 0.35,
            opacity = 0.72,
            objectFit = "cover",
            filter = "brightness(.62) contrast(1.12) saturate(.92)",
        },
    },
}

cfg.Colors = {
    Accent = Color(198, 181, 94),
    AccentDark = Color(124, 113, 55),
    Red = Color(190, 28, 28),
    White = Color(235, 235, 235),
    Muted = Color(170, 170, 170),
    Dark = Color(12, 12, 15, 220),
    Dark2 = Color(25, 25, 29, 195),
    Locked = Color(12, 12, 12, 165),
    Line = Color(230, 230, 230, 80),
}

function cfg.GetPlayerLevel(ply)
    if not IsValid(ply) then return 1 end
    return ply:GetNWInt(cfg.LevelNWInt, 1)
end

function cfg.GetPlayerRoleLevel(ply, armyID, roleID, role)
    if not IsValid(ply) then return cfg.DefaultRoleLevel or 1 end
    local key = tostring(cfg.RoleLevelNWIntPrefix or "medal_role_level_") .. tostring(armyID or "") .. "_" .. tostring(roleID or "")
    return ply:GetNWInt(key, tonumber(role and role.defaultRoleLevel) or cfg.DefaultRoleLevel or 1)
end

function cfg.GetGeneralXPRequired(level)
    local xpc = cfg.XP and cfg.XP.General or {}
    level = math.max(tonumber(level) or 1, 1)
    return math.floor((tonumber(xpc.BaseNextXP) or 350) * ((tonumber(xpc.Growth) or 1.16) ^ (level - 1)))
end

function cfg.GetRoleXPRequired(level)
    local xpc = cfg.XP and cfg.XP.Role or {}
    level = math.max(tonumber(level) or 1, 1)
    return math.floor((tonumber(xpc.BaseNextXP) or 60) * ((tonumber(xpc.Growth) or 1.35) ^ (level - 1)))
end

-- Remplace ces modèles par tes vrais modèles US / Vietcong.
local US_MODEL = "models/player/Group03/male_07.mdl"
local US_MODEL_2 = "models/player/Group03/male_04.mdl"
local US_MODEL_MEDIC = "models/player/Group03m/male_07.mdl"
local VC_MODEL = "models/player/Group03m/male_06.mdl"
local VC_MODEL_2 = "models/player/Group03m/male_02.mdl"
local VC_MODEL_SCOUT = "models/player/Group03m/male_09.mdl"

local function mergeExtra(base, extra)
    if istable(extra) then
        for k, v in pairs(extra) do base[k] = v end
    end
    return base
end

--[[
Loadout : L(id, nom, niveau_de_role_requis, armes, munitions, équipements_affichés, options)

Exemple complet :
L("standard", "MODÈLE STANDARD", 1,
  {"weapon_smg1", "weapon_pistol"},       -- ICI tu mets les codes des armes
  {SMG1 = 180, Pistol = 45},                -- ICI les munitions
  {"Radio", "Carte tactique", "Jumelles"}, -- ICI l'affichage des petits équipements
  {
    image = "medal/loadouts/m16.png",       -- image dans la ligne loadout
    previewImage = "medal/loadouts/m16_big.png", -- grande image à droite
    preview = {type = "model", model = "models/weapons/w_rif_m4a1.mdl"}, -- alternative modèle 3D
    armor = 25,
    health = 100,
  }
)
]]
local function L(id, name, level, weapons, ammo, equipment, extra)
    return mergeExtra({
        id = id,
        name = name,
        level = level or 1, -- niveau requis DANS CE RÔLE pour débloquer ce loadout
        weapons = weapons or {},
        ammo = ammo or {},
        equipment = equipment or {},

        -- Options UI disponibles :
        -- image = "medal/loadouts/mon_image.png",              -- image de la ligne loadout
        -- previewImage = "medal/loadouts/mon_preview.png",     -- grande image du panneau équipement
        -- preview = {type = "model", model = "models/...mdl"}, -- ou aperçu en modèle 3D
    }, extra)
end

--[[
Rôle : Role(id, nom_affiché, job_darkrp, nom_job_fallback, niveau_général_requis, icône_texte, modèle, loadouts, options)

Exemple :
Role("fusilier", "FUSILIER", "TEAM_MEDAL_US_FUSILIER", "Fusilier US", 1, "✦", US_MODEL, {
    L(...),
}, {
    iconMaterial = "medal/roles/fusilier.png", -- icône personnalisée à gauche du rôle
    defaultRoleLevel = 1,
    maxLevel = 8,
})
]]
local function Role(id, name, job, jobName, level, icon, model, loadouts, extra)
    local base = {
        id = id,
        name = name,
        job = job,             -- ICI tu mets le job DarkRP : "TEAM_EXEMPLE" ou ID numérique du job
        jobName = jobName,     -- fallback par nom de job si la constante TEAM_ n'existe pas
        jobCommand = nil,      -- optionnel : commande DarkRP du job si tu préfères la résolution par command
        spawnAsJob = true,     -- true = le joueur passe dans ce job et spawn au spawn du job
        requiredLevel = level or 1, -- niveau général requis pour accéder au rôle
        defaultRoleLevel = 1,       -- niveau de rôle affiché si aucun XP n'existe encore
        maxLevel = cfg.MaxRoleLevel or 8,
        icon = icon or "•",
        model = model,         -- modèle joueur appliqué quand ce rôle est choisi
        loadouts = loadouts or {},
    }

    if cfg.RoleIconMaterials then
        base.iconMaterial = cfg.RoleIconMaterials[id] or cfg.RoleIconMaterials[tostring(job or "")] or cfg.RoleIconMaterials[tostring(name or "")]
    end

    return mergeExtra(base, extra)
end

cfg.Armies = {
    {
        id = "americans",
        name = "ARMÉE AMÉRICAINE",
        menuName = "AMÉRICAINS",
        cardName = "AMÉRICAINS",
        cardIcon = "★",
        cardDescription = "Puissance de feu, appui aérien et coordination. Un seul personnage maximum côté Américains.",
        cardImage = "medal/camps/americans.png",
        cardImageMode = "contain",
        cardOverlayText = false,
        accent = Color(220, 220, 220),
        characterModel = US_MODEL,
        characterModels = {US_MODEL, US_MODEL_2, US_MODEL_MEDIC},
        characterDescription = "Soldat américain engagé au Vietnam.",
        categories = {
            {
                id = "commandement",
                name = "COMMANDEMENT",
                icon = "✣",
                roles = {
                    Role("commandant", "COMMANDANT", "TEAM_MEDAL_US_COMMANDANT", "Commandant US", 8, "✣", US_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 60}, {"Carte tactique", "Radio", "Jumelles"}, {image = "medal/loadouts/pistol.png", preview = {type = "model", model = US_MODEL}}),
                        L("veteran", "VÉTÉRAN", 4, {"weapon_pistol", "weapon_smg1"}, {Pistol = 60, SMG1 = 90}, {"Radio longue portée", "Fumigène"}),
                    }),
                }
            },
            {
                id = "infanterie",
                name = "INFANTERIE",
                icon = "▰",
                roles = {
                    Role("officier", "OFFICIER", "TEAM_MEDAL_US_OFFICIER", "Officier US", 7, "▰", US_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 80}, {"Radio", "Pansement", "Grenade fumigène"}),
                        L("homme_de_pointe", "HOMME DE POINTE", 3, {"weapon_pistol", "weapon_smg1"}, {Pistol = 80, SMG1 = 120}, {"Radio", "Grenade"}),
                        L("sous_officier", "SOUS-OFFICIER", 6, {"weapon_357", "weapon_smg1"}, {["357"] = 24, SMG1 = 120}, {"Radio", "Carte tactique"}),
                    }),
                    Role("fusilier", "FUSILIER", "TEAM_MEDAL_US_FUSILIER", "Fusilier US", 1, "✦", US_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1"}, {SMG1 = 150}, {"Baïonnette", "Pansement"}, {image = "medal/loadouts/rifle.png", previewImage = "medal/loadouts/rifle.png"}),
                        L("veteran", "VÉTÉRAN", 3, {"weapon_smg1", "weapon_pistol"}, {SMG1 = 180, Pistol = 40}, {"Pelle", "Fumigène"}),
                        L("grenadier", "GRENADIER", 6, {"weapon_smg1", "weapon_frag"}, {SMG1 = 150}, {"Grenade", "Pansement"}),
                    }),
                    Role("assaut", "ASSAUT", "TEAM_MEDAL_US_ASSAUT", "Assaut US", 1, "⚔", US_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1"}, {SMG1 = 180}, {"Grenade", "Pansement"}),
                        L("veteran", "VÉTÉRAN", 3, {"weapon_smg1", "weapon_frag"}, {SMG1 = 180}, {"Grenade", "Fumigène"}),
                        L("commando", "COMMANDO", 8, {"weapon_ar2", "weapon_pistol"}, {AR2 = 90, Pistol = 40}, {"Charge explosive", "Fumigène"}),
                    }),
                    Role("auto_rifle", "FUSILIER AUTOMATIQUE", "TEAM_MEDAL_US_AUTO", "Fusilier Automatique US", 1, "⚡", US_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_ar2"}, {AR2 = 120}, {"Pansement", "Pelle"}),
                        L("veteran", "VÉTÉRAN", 3, {"weapon_ar2", "weapon_pistol"}, {AR2 = 150, Pistol = 40}, {"Pansement", "Fumigène"}),
                        L("parachutiste", "PARACHUTISTE", 6, {"weapon_ar2", "weapon_frag"}, {AR2 = 160}, {"Grenade", "Kit léger"}),
                    }),
                    Role("medic", "MÉDECIN", "TEAM_MEDAL_US_MEDIC", "Médecin US", 4, "✚", US_MODEL_MEDIC, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol", "med_kit"}, {Pistol = 50}, {"Trousse médicale", "Bandages"}),
                        L("medic_veteran", "COMBAT MEDIC", 3, {"weapon_pistol", "med_kit"}, {Pistol = 70}, {"Morphine", "Fumigène"}),
                    }),
                    Role("support", "SOUTIEN", "TEAM_MEDAL_US_SUPPORT", "Soutien US", 2, "✚", US_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1"}, {SMG1 = 220}, {"Munitions", "Pansement"}),
                        L("porte_munitions", "PORTE-MUNITIONS", 3, {"weapon_smg1"}, {SMG1 = 260}, {"Caisse munitions", "Outils"}),
                    }),
                    Role("mg", "MITRAILLEUR", "TEAM_MEDAL_US_MG", "Mitrailleur US", 2, "═", US_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_ar2"}, {AR2 = 220}, {"Bipied", "Pansement"}),
                        L("veteran", "VÉTÉRAN", 3, {"weapon_ar2", "weapon_pistol"}, {AR2 = 260, Pistol = 40}, {"Bipied", "Caisse munitions"}),
                    }),
                    Role("antitank", "ANTICHAR", "TEAM_MEDAL_US_AT", "Antichar US", 2, "☄", US_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1", "weapon_frag"}, {SMG1 = 120}, {"Roquette", "Pansement"}),
                        L("embuscade", "ÉQUIPAGE D'ARTILLERIE", 3, {"weapon_smg1"}, {SMG1 = 150}, {"Munitions AT", "Outils"}),
                    }),
                    Role("engineer", "INGÉNIEUR", "TEAM_MEDAL_US_ENGINEER", "Ingénieur US", 3, "▣", US_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1"}, {SMG1 = 140}, {"Outils", "Pansement"}),
                        L("pionnier", "PIONNIER", 3, {"weapon_smg1", "weapon_frag"}, {SMG1 = 150}, {"Outils", "Charge explosive"}),
                    }),
                }
            },
            {
                id = "blindes",
                name = "BLINDÉS",
                icon = "▣",
                roles = {
                    Role("tank_commander", "COMMANDANT DE CHAR", "TEAM_MEDAL_US_TANK_COMMANDER", "Commandant de Char US", 8, "▣", US_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 60}, {"Radio blindé", "Jumelles"}),
                    }),
                    Role("crewman", "ÉQUIPIER", "TEAM_MEDAL_US_CREWMAN", "Équipier US", 3, "◉", US_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 60}, {"Outils", "Réparation"}),
                    }),
                }
            },
            {
                id = "artillerie",
                name = "ARTILLERIE",
                icon = "☷",
                roles = {
                    Role("artillery_observer", "OBSERVATEUR DE L'ARTILLERIE", "TEAM_MEDAL_US_ARTY_OBSERVER", "Observateur Artillerie US", 3, "☷", US_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 60}, {"Jumelles", "Radio"}),
                    }),
                    Role("operator", "OPÉRATEUR", "TEAM_MEDAL_US_ARTY_OPERATOR", "Opérateur Artillerie US", 1, "☷", US_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 40}, {"Munitions", "Outils"}),
                    }),
                    Role("gunner", "ARTILLEUR", "TEAM_MEDAL_US_ARTILLEUR", "Artilleur US", 1, "☷", US_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 40}, {"Outils", "Caisse obus"}),
                    }),
                }
            },
        }
    },
    {
        id = "vietcong",
        name = "VIETCONG",
        menuName = "VIETCONG",
        cardName = "VIETCONG",
        cardIcon = "★",
        cardDescription = "Mobilité, embuscades et guerre de terrain. Un seul personnage maximum côté Vietcong.",
        cardImage = "medal/camps/vietcong.png",
        cardImageMode = "contain",
        cardOverlayText = false,
        accent = Color(190, 38, 38),
        characterModel = VC_MODEL,
        characterModels = {VC_MODEL, VC_MODEL_2, VC_MODEL_SCOUT},
        characterDescription = "Combattant Vietcong enraciné dans la jungle.",
        categories = {
            {
                id = "commandement",
                name = "COMMANDEMENT",
                icon = "✣",
                roles = {
                    Role("chef_section", "CHEF DE SECTION", "TEAM_MEDAL_VC_CHEF", "Chef de Section Vietcong", 8, "✣", VC_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 70}, {"Carte", "Radio", "Jumelles"}),
                        L("cadre_veteran", "CADRE VÉTÉRAN", 4, {"weapon_pistol", "weapon_smg1"}, {Pistol = 70, SMG1 = 110}, {"Radio", "Fumigène"}),
                    }),
                    Role("commissaire", "COMMISSAIRE POLITIQUE", "TEAM_MEDAL_VC_COMMISSAIRE", "Commissaire Politique Vietcong", 6, "✣", VC_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 60}, {"Carnet", "Radio"}),
                    }),
                }
            },
            {
                id = "infanterie",
                name = "INFANTERIE",
                icon = "▰",
                roles = {
                    Role("officier", "OFFICIER", "TEAM_MEDAL_VC_OFFICIER", "Officier Vietcong", 7, "▰", VC_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 80}, {"Radio", "Pansement"}),
                        L("veteran", "VÉTÉRAN", 3, {"weapon_pistol", "weapon_smg1"}, {Pistol = 80, SMG1 = 120}, {"Radio", "Grenade"}),
                    }),
                    Role("soldat", "SOLDAT", "TEAM_MEDAL_VC_SOLDAT", "Soldat Vietcong", 1, "✦", VC_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1"}, {SMG1 = 150}, {"Pansement", "Pelle"}),
                        L("veteran", "VÉTÉRAN", 3, {"weapon_smg1", "weapon_pistol"}, {SMG1 = 170, Pistol = 40}, {"Pansement", "Fumigène"}),
                        L("grenadier", "GRENADIER", 6, {"weapon_smg1", "weapon_frag"}, {SMG1 = 150}, {"Grenade", "Piège léger"}),
                    }),
                    Role("eclaireur", "ÉCLAIREUR", "TEAM_MEDAL_VC_ECLAIREUR", "Éclaireur Vietcong", 2, "◇", VC_MODEL_SCOUT, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1"}, {SMG1 = 140}, {"Jumelles", "Pansement"}),
                        L("embuscade", "EMBUSCADE", 4, {"weapon_smg1", "weapon_frag"}, {SMG1 = 150}, {"Piège", "Fumigène"}),
                    }),
                    Role("auto_rifle", "FUSILIER AUTOMATIQUE", "TEAM_MEDAL_VC_AUTO", "Fusilier Automatique Vietcong", 1, "⚡", VC_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_ar2"}, {AR2 = 120}, {"Munitions", "Pansement"}),
                        L("veteran", "VÉTÉRAN", 3, {"weapon_ar2", "weapon_pistol"}, {AR2 = 150, Pistol = 40}, {"Munitions", "Fumigène"}),
                    }),
                    Role("medic", "MÉDECIN", "TEAM_MEDAL_VC_MEDIC", "Médecin Vietcong", 4, "✚", VC_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol", "med_kit"}, {Pistol = 50}, {"Trousse médicale", "Bandages"}),
                        L("secouriste", "SECOURISTE", 3, {"weapon_pistol", "med_kit"}, {Pistol = 70}, {"Trousse médicale", "Morphine", "Fumigène"}),
                    }),
                    Role("soutien", "SOUTIEN", "TEAM_MEDAL_VC_SUPPORT", "Soutien Vietcong", 2, "✚", VC_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1"}, {SMG1 = 220}, {"Caisse munitions", "Pansement"}),
                        L("porte_munitions", "PORTE-MUNITIONS", 3, {"weapon_smg1"}, {SMG1 = 260}, {"Caisse munitions", "Outils"}),
                    }),
                    Role("mitrailleur", "MITRAILLEUR", "TEAM_MEDAL_VC_MG", "Mitrailleur Vietcong", 2, "═", VC_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_ar2"}, {AR2 = 220}, {"Bipied", "Pansement"}),
                        L("veteran", "VÉTÉRAN", 3, {"weapon_ar2", "weapon_pistol"}, {AR2 = 260, Pistol = 40}, {"Bipied", "Caisse munitions"}),
                    }),
                    Role("antichar", "ANTICHAR", "TEAM_MEDAL_VC_AT", "Antichar Vietcong", 2, "☄", VC_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1", "weapon_frag"}, {SMG1 = 120}, {"Roquette", "Pansement"}),
                        L("embuscade", "EMBUSCADE", 6, {"weapon_smg1", "weapon_frag"}, {SMG1 = 160}, {"Charge AT", "Piège"}),
                    }),
                    Role("sapeur", "SAPEUR", "TEAM_MEDAL_VC_SAPEUR", "Sapeur Vietcong", 3, "▣", VC_MODEL_SCOUT, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_smg1"}, {SMG1 = 140}, {"Outils", "Pansement"}),
                        L("saboteur", "SABOTEUR", 3, {"weapon_smg1", "weapon_frag"}, {SMG1 = 150}, {"Charge explosive", "Piège"}),
                    }),
                }
            },
            {
                id = "reconnaissance",
                name = "RECONNAISSANCE",
                icon = "⌖",
                roles = {
                    Role("sniper", "TIREUR D'ÉLITE", "TEAM_MEDAL_VC_SNIPER", "Tireur d'Élite Vietcong", 5, "⌖", VC_MODEL_SCOUT, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_crossbow", "weapon_pistol"}, {XBowBolt = 12, Pistol = 40}, {"Camouflage", "Jumelles"}),
                    }),
                    Role("spotter", "OBSERVATEUR", "TEAM_MEDAL_VC_SPOTTER", "Observateur Vietcong", 3, "⌖", VC_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 60}, {"Jumelles", "Radio"}),
                    }),
                }
            },
            {
                id = "artillerie",
                name = "ARTILLERIE",
                icon = "☷",
                roles = {
                    Role("operator", "OPÉRATEUR", "TEAM_MEDAL_VC_ARTY_OPERATOR", "Opérateur Artillerie Vietcong", 1, "☷", VC_MODEL, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 40}, {"Munitions", "Outils"}),
                    }),
                    Role("artilleur", "ARTILLEUR", "TEAM_MEDAL_VC_ARTILLEUR", "Artilleur Vietcong", 1, "☷", VC_MODEL_2, {
                        L("standard", "MODÈLE STANDARD", 1, {"weapon_pistol"}, {Pistol = 40}, {"Outils", "Caisse obus"}),
                    }),
                }
            },
        }
    }
}

function MedalBarracks.GetArmies()
    return cfg.Armies or {}
end

function MedalBarracks.GetArmy(id)
    for _, army in ipairs(MedalBarracks.GetArmies()) do
        if army.id == id then return army end
    end
end

function MedalBarracks.GetCategory(army, id)
    if not army then return end
    for _, category in ipairs(army.categories or {}) do
        if category.id == id then return category end
    end
end

function MedalBarracks.GetRole(armyId, categoryId, roleId)
    local army = MedalBarracks.GetArmy(armyId)
    local category = MedalBarracks.GetCategory(army, categoryId)
    if not category then return end
    for _, role in ipairs(category.roles or {}) do
        if role.id == roleId then return role, category, army end
    end
end

function MedalBarracks.GetLoadout(role, id)
    if not role then return end
    for _, loadout in ipairs(role.loadouts or {}) do
        if loadout.id == id then return loadout end
    end
    return role.loadouts and role.loadouts[1] or nil
end

function MedalBarracks.GetFirstRole(army)
    if not army then return end
    for _, category in ipairs(army.categories or {}) do
        if category.roles and category.roles[1] then
            return category.roles[1], category
        end
    end
end
