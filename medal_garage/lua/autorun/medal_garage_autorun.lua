--[[
    Medal Garage — Garage de véhicules par niveau, essence, HUD HLL, sièges.
    Addon séparé, compatible avec medal_barracks_menu_vietnam (niveau + rôles +
    ravitaillement Soutien) mais fonctionnel seul.
    Staff : outil "Point de garage" (medal_garage_point) pour placer les garages.
]]

MedalGarage = MedalGarage or {}

if SERVER then
    AddCSLuaFile("medal_garage/sh_config.lua")
    AddCSLuaFile("medal_garage/cl_core.lua")

    include("medal_garage/sh_config.lua")
    include("medal_garage/sv_core.lua")
    include("medal_garage/sv_admin.lua")
    include("medal_garage/sv_seats.lua")
else
    include("medal_garage/sh_config.lua")
    include("medal_garage/cl_core.lua")
end
