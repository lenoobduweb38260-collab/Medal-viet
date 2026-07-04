--[[
    Medal Frontline — Capture de zones façon Hell Let Loose.
    Addon séparé, compatible avec medal_barracks_menu_vietnam (mêmes factions).
    Commande staff : medal_frontline_staff
]]

MedalFrontline = MedalFrontline or {}

if SERVER then
    AddCSLuaFile("medal_frontline/sh_config.lua")
    AddCSLuaFile("medal_frontline/cl_hud.lua")
    AddCSLuaFile("medal_frontline/cl_staff.lua")

    include("medal_frontline/sh_config.lua")
    include("medal_frontline/sv_core.lua")
else
    include("medal_frontline/sh_config.lua")
    include("medal_frontline/cl_hud.lua")
    include("medal_frontline/cl_staff.lua")
end
