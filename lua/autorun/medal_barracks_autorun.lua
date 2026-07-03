MedalBarracks = MedalBarracks or {}

if SERVER then
    AddCSLuaFile("medal_barracks/sh_config.lua")
    AddCSLuaFile("medal_barracks/cl_ui.lua")
    AddCSLuaFile("medal_barracks/cl_squads.lua")
    AddCSLuaFile("medal_barracks/cl_radio.lua")

    include("medal_barracks/sh_config.lua")

    local function addMaterial(path)
        if not isstring(path) or path == "" then return end
        if string.StartWith(path, "http://") or string.StartWith(path, "https://") then return end
        local fullPath = "materials/" .. path
        if file.Exists(fullPath, "GAME") then resource.AddFile(fullPath) end
    end

    local function addSound(path)
        if not isstring(path) or path == "" then return end
        if string.StartWith(path, "http://") or string.StartWith(path, "https://") then return end
        local fullPath = "sound/" .. path
        if file.Exists(fullPath, "GAME") then resource.AddFile(fullPath) end
    end

    local function collectLoadoutMaterials(loadout)
        if not istable(loadout) then return end
        addMaterial(loadout.image)
        addMaterial(loadout.rowImage)
        addMaterial(loadout.iconMaterial)
        addMaterial(loadout.previewImage)
        addMaterial(loadout.previewModelImage)
        if istable(loadout.preview) then
            addMaterial(loadout.preview.path)
            addMaterial(loadout.preview.image)
            addMaterial(loadout.preview.material)
        end
    end

    local function addConfiguredMaterials()
        local c = MedalBarracks.Config or {}
        addMaterial(c.BackgroundMaterial)
        if c.MainMenu then
            addMaterial(c.MainMenu.DiscordIcon)
            addMaterial(c.MainMenu.WebsiteIcon)
        end

        for _, p in pairs(c.WeaponIconMaterials or {}) do addMaterial(p) end
        for _, p in pairs(c.EquipmentIconMaterials or {}) do addMaterial(p) end
        for _, p in pairs(c.RoleIconMaterials or {}) do addMaterial(p) end
        if c.WeaponSelector then
            addMaterial(c.WeaponSelector.PanelMaterial)
            addMaterial(c.WeaponSelector.SlotMaterial)
            for _, p in pairs(c.WeaponSelector.WeaponIcons or {}) do addMaterial(p) end
        end

        for _, army in ipairs(c.Armies or {}) do
            addMaterial(army.cardImage)
            addMaterial(army.characterCardImage)
            for _, category in ipairs(army.categories or {}) do
                addMaterial(category.iconMaterial)
                for _, role in ipairs(category.roles or {}) do
                    addMaterial(role.iconMaterial)
                    addMaterial(role.materialIcon)
                    addMaterial(role.iconImage)
                    for _, loadout in ipairs(role.loadouts or {}) do collectLoadoutMaterials(loadout) end
                end
            end
        end

        -- Fallbacks inclus dans le pack de base.
        addMaterial("medal/menu/bg_vietnam.png")
        addMaterial("medal/menu/bg_vietnam_clean.png")
        addMaterial("medal/camps/americans.png")
        addMaterial("medal/camps/vietcong.png")
        addMaterial("medal/loadouts/rifle.png")
        addMaterial("medal/loadouts/pistol.png")
        addMaterial("medal/loadouts/grenade.png")
        addMaterial("medal/loadouts/medkit.png")
        addMaterial("medal/loadouts/map.png")
        addMaterial("medal/loadouts/radio.png")
        addMaterial("medal/loadouts/binoculars.png")
        addMaterial("medal/loadouts/tools.png")
        addMaterial("medal/loadouts/ammo.png")
        addMaterial("medal/ui/discord.png")
        addMaterial("medal/ui/globe.png")
        addMaterial("medal/ui/weapon_selector_panel.png")
        addMaterial("medal/ui/weapon_selector_slot.png")
        addMaterial("medal/weapons/shovel.png")
    end

    addConfiguredMaterials()

    for _, snd in ipairs((MedalBarracks.Config and MedalBarracks.Config.DownloadSounds) or {}) do
        addSound(snd)
    end

    include("medal_barracks/sv_core.lua")
    include("medal_barracks/sv_squads.lua")
    include("medal_barracks/sv_radio.lua")
else
    include("medal_barracks/sh_config.lua")
    include("medal_barracks/cl_ui.lua")
    include("medal_barracks/cl_squads.lua")
    include("medal_barracks/cl_radio.lua")
end
