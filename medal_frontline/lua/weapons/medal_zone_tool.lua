--[[
    Medal Frontline — Outil de création de secteurs (staff).
    En main, toutes les zones existantes s'affichent EN SURBRILLANCE avec leur
    nom au-dessus (dôme + cercle au sol).
      Clic gauche : créer un secteur à l'endroit visé.
      Clic droit  : déplacer le secteur le plus proche à l'endroit visé.
      Recharge (R) : supprimer le secteur visé.
      Molette / +use : agrandir / réduire le rayon du secteur visé.
]]

AddCSLuaFile()

SWEP.PrintName = "Outil de secteur (Frontline)"
SWEP.Author = "Medal Vietnam"
SWEP.Instructions = "Clic gauche: créer • Clic droit: déplacer • R: supprimer • Molette: rayon"
SWEP.Category = "Medal Vietnam"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.UseHands = true
SWEP.HoldType = "revolver"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.DrawAmmo = false

local function tracePos(ply)
    local tr = ply:GetEyeTrace()
    return tr.HitPos
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.35)
    if CLIENT then return end
    net.Start("MedalFrontline_ZoneTool")
        net.WriteString("add")
        net.WriteVector(tracePos(self:GetOwner()))
    net.SendToServer()
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.35)
    if CLIENT then return end
    net.Start("MedalFrontline_ZoneTool")
        net.WriteString("move")
        net.WriteVector(tracePos(self:GetOwner()))
    net.SendToServer()
end

function SWEP:Reload()
    if (self.NextReload or 0) > CurTime() then return end
    self.NextReload = CurTime() + 0.5
    if CLIENT then return end
    net.Start("MedalFrontline_ZoneTool")
        net.WriteString("remove")
        net.WriteVector(tracePos(self:GetOwner()))
    net.SendToServer()
end

-- Molette : rayon du secteur visé.
function SWEP:Think()
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    local delta = 0
    if ply:KeyPressed(IN_INVNEXT) then delta = 60 elseif ply:KeyPressed(IN_INVPREV) then delta = -60 end
    if delta ~= 0 then
        net.Start("MedalFrontline_ZoneTool")
            net.WriteString("radius")
            net.WriteVector(tracePos(ply))
            net.WriteInt(delta, 16)
        net.SendToServer()
    end
end

if CLIENT then
    surface.CreateFont("MZoneTool_Name", {font = "Roboto Condensed", size = 40, weight = 1000, extended = true})
    surface.CreateFont("MZoneTool_Sub", {font = "Roboto Condensed", size = 26, weight = 800, extended = true})

    -- Surbrillance de toutes les zones quand le SWEP est en main.
    hook.Add("PostDrawTranslucentRenderables", "MedalZoneTool_Highlight", function(depth, sky)
        if sky then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "medal_zone_tool" then return end

        local st = MedalFrontline.State or {}
        local maxD = (MedalFrontline.Config.ZoneTool or {}).HighlightDistance or 8000
        for _, z in ipairs(st.zones or {}) do
            if z.pos and ply:GetPos():Distance(z.pos) <= maxD then
                local col = z.owner ~= "" and ((MedalFrontline.Config.FactionColors or {})[z.owner] or Color(150, 150, 150)) or Color(150, 160, 120)

                -- Cercle au sol + dôme translucide.
                render.SetColorMaterial()
                local segs, r = 40, z.radius or 900
                local prev
                for i = 0, segs do
                    local a = math.rad((i / segs) * 360)
                    local p = z.pos + Vector(math.cos(a) * r, math.sin(a) * r, 6)
                    if prev then
                        render.DrawLine(prev, p, Color(col.r, col.g, col.b, 255), false)
                    end
                    prev = p
                end
                render.DrawWireframeSphere(z.pos + Vector(0, 0, r * 0.4), r, 16, 12, Color(col.r, col.g, col.b, 60), true)

                -- Nom au-dessus de la zone.
                local top = z.pos + Vector(0, 0, (z.radius or 900) * 0.4 + 90)
                local ang = (ply:EyePos() - top); ang.z = 0; ang = ang:Angle()
                ang:RotateAroundAxis(ang:Up(), -90)
                ang:RotateAroundAxis(ang:Forward(), 90)
                cam.Start3D2D(top, ang, 0.7)
                    draw.SimpleText(z.name or "POINT", "MZoneTool_Name", 0, 0, Color(240, 242, 232), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText("rayon " .. math.Round(z.radius or 900), "MZoneTool_Sub", 0, 42, Color(col.r, col.g, col.b), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cam.End3D2D()
            end
        end
    end)

    function SWEP:DrawHUD()
        draw.SimpleText("CLIC G: créer  •  CLIC D: déplacer  •  R: supprimer  •  MOLETTE: rayon",
            "MZoneTool_Sub", ScrW() / 2, ScrH() - 80, Color(232, 234, 222, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- Petit réticule.
        surface.SetDrawColor(232, 234, 222, 220)
        surface.DrawRect(ScrW() / 2 - 1, ScrH() / 2 - 8, 2, 16)
        surface.DrawRect(ScrW() / 2 - 8, ScrH() / 2 - 1, 16, 2)
    end
end
