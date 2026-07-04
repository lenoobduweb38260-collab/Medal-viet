--[[
    Medal Vietnam — Configuration de l'Emplacement Tool (gred_emp_tool).
    Adaptée aux jobs DarkRP Vietnam de l'addon medal_barracks :
    ingénieurs / sapeurs construisent MG et mortiers, artilleurs les canons.

    IMPORTANT :
    - La POSE d'un emplacement consomme du ravitaillement des caisses de
      Soutien proches (cfg.Supply.EmplacementCost dans sh_config.lua).
    - La CONSTRUCTION se fait en tapant l'emplacement avec une arme de la
      WeaponWhiteList ci-dessous (la pelle par défaut).
    - Remplace les classes gred_emp_* d'exemple par celles de ton pack
      d'emplacements Vietnam.
]]

local function Config()
    gred = gred or {}
    gred.EmplacementTool = gred.EmplacementTool or {}

    gred.EmplacementTool.BuildRate = 2.5

    gred.EmplacementTool.TeamBlackList = false
    gred.EmplacementTool.TeamWhiteList = {}

    -- Ajoute une team seulement si la constante DarkRP existe.
    local function addTeam(constName, list)
        local teamID = _G[constName]
        if teamID ~= nil then
            gred.EmplacementTool.TeamWhiteList[teamID] = list
        end
    end

    -- Emplacements constructibles par les INGÉNIEURS US.
    -- Remplace ces classes par tes emplacements Vietnam (M60, M2, mortier M29...).
    local usEngineer = {
        ["gred_emp_m2_low"] = true,
        ["gred_emp_m1919"] = true,
        ["gred_emp_m1mortar"] = true,
        ["gred_ammobox"] = true,
    }
    -- Emplacements constructibles par les SAPEURS Vietcong (DShK, mortier 82mm...).
    local vcSapeur = {
        ["gred_emp_mg42_alt"] = true,
        ["gred_emp_mg34_alt"] = true,
        ["gred_emp_grw34"] = true,
        ["gred_ammobox"] = true,
    }
    -- Canons pour les ARTILLEURS.
    local usArty = {
        ["gred_emp_m2a1"] = true,
        ["gred_emp_m5"] = true,
        ["gred_ammobox"] = true,
    }
    local vcArty = {
        ["gred_emp_pak40"] = true,
        ["gred_emp_lefh18"] = true,
        ["gred_ammobox"] = true,
    }

    addTeam("TEAM_MEDAL_US_ENGINEER", usEngineer)
    addTeam("TEAM_MEDAL_VC_SAPEUR", vcSapeur)
    addTeam("TEAM_MEDAL_US_ARTILLEUR", usArty)
    addTeam("TEAM_MEDAL_US_ARTY_OPERATOR", usArty)
    addTeam("TEAM_MEDAL_VC_ARTILLEUR", vcArty)
    addTeam("TEAM_MEDAL_VC_ARTY_OPERATOR", vcArty)

    -- Armes qui CONSTRUISENT les emplacements en les frappant.
    -- La pelle Medal (weapon_crowbar/stunstick par défaut) + pelles CW si installées.
    gred.EmplacementTool.WeaponWhiteList = {
        ["weapon_crowbar"] = true,
        ["weapon_stunstick"] = true,
        ["cw_kk_ins2_doi_mel_shovel_us"] = true,
        ["cw_kk_ins2_doi_mel_shovel_de"] = true,
    }

    gred.EmplacementTool.AdditionalEntities = {
        ["cw_ammo_kit_regular"] = "Boîte de munitions",
    }
end

if DarkRP then
    Config()
end

hook.Add("PostGamemodeLoaded", "medal_emplacementtool_config", Config)
