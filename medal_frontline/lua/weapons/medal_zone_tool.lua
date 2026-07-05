--[[
    Medal Frontline — Outil de création de secteurs (staff).
    En main, toutes les zones existantes s'affichent EN SURBRILLANCE avec leur
    nom au-dessus (dôme + cercle au sol).
      Clic gauche : créer un secteur à l'endroit visé.
      Clic droit  : déplacer le secteur le plus proche à l'endroit visé.
      Recharge (R) : supprimer le secteur visé.
      Molette : agrandir / réduire le rayon du secteur visé.
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

-- Envoi d'une action au serveur (uniquement depuis le client).
local function sendAction(ply, action, extra)
    if not CLIENT then return end
    net.Start("MedalFrontline_ZoneTool")
        net.WriteString(action)
        net.WriteVector(ply:GetEyeTrace().HitPos)
        if extra then net.WriteInt(extra, 16) end
    net.SendToServer()
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.35)
    if not IsFirstTimePredicted() then return end
    sendAction(self:GetOwner(), "add")
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.35)
    if not IsFirstTimePredicted() then return end
    sendAction(self:GetOwner(), "move")
end

function SWEP:Reload()
    if not IsFirstTimePredicted() then return end
    if (self.NextReload or 0) > CurTime() then return end
    self.NextReload = CurTime() + 0.5
    sendAction(self:GetOwner(), "remove")
end

if CLIENT then
    surface.CreateFont("MZoneTool_Name", {font = "Roboto Condensed", size = 40, weight = 1000, extended = true})
    surface.CreateFont("MZoneTool_Sub", {font = "Roboto Condensed", size = 26, weight = 800, extended = true})

    -- Molette : ajuste le rayon du secteur visé (invnext/invprev fonctionnent
    -- côté client via PlayerBindPress).
    hook.Add("PlayerBindPress", "MedalZoneTool_Scroll", function(ply, bind, pressed)
        if not pressed then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "medal_zone_tool" then return end
        local d = 0
        if string.find(bind, "invnext", 1, true) then d = 60
        elseif string.find(bind, "invprev", 1, true) then d = -60 end
        if d ~= 0 then
            net.Start("MedalFrontline_ZoneTool")
                net.WriteString("radius")
                net.WriteVector(ply:GetEyeTrace().HitPos)
                net.WriteInt(d, 16)
            net.SendToServer()
            return true
        end
    end)

    -- Surbrillance de toutes les zones quand le SWEP est en main.
    hook.Add("PostDrawTranslucentRenderables", "MedalZoneTool_Highlight", function(depth, sky)
        if sky then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "medal_zone_tool" then return end

        local st = MedalFrontline.State or {}
        local maxD = ((MedalFrontline.Config or {}).ZoneTool or {}).HighlightDistance or 8000
        for _, z in ipairs(st.zones or {}) do
            if z.pos and ply:GetPos():Distance(z.pos) <= maxD then
                local col = z.owner ~= "" and ((MedalFrontline.Config.FactionColors or {})[z.owner] or Color(150, 150, 150)) or Color(150, 160, 120)

                render.SetColorMaterial()
                local segs, r = 40, z.radius or 900
                local prev
                for i = 0, segs do
                    local a = math.rad((i / segs) * 360)
                    local p = z.pos + Vector(math.cos(a) * r, math.sin(a) * r, 6)
                    if prev then render.DrawLine(prev, p, Color(col.r, col.g, col.b, 255), false) end
                    prev = p
                end
                render.DrawWireframeSphere(z.pos + Vector(0, 0, r * 0.4), r, 16, 12, Color(col.r, col.g, col.b, 60), true)

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

    -- Renommer le secteur visé (touche F) : petit champ de saisie.
    hook.Add("PlayerButtonDown", "MedalZoneTool_Rename", function(ply, key)
        if ply ~= LocalPlayer() then return end
        if key ~= KEY_F then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "medal_zone_tool" then return end
        if IsValid(MedalFrontline.RenameFrame) then MedalFrontline.RenameFrame:Remove() end
        local pos = ply:GetEyeTrace().HitPos

        -- Responsive : mise à l'échelle par rapport à un écran 1920x1080.
        local function S(v) return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080)) end

        local f = vgui.Create("DFrame")
        MedalFrontline.RenameFrame = f
        f:SetSize(S(420), S(150))
        f:Center()
        f:SetTitle("")
        f:ShowCloseButton(false)
        f:MakePopup()
        f.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(12, 14, 11, 245))
            draw.RoundedBox(0, 0, 0, S(4), h, Color(112, 126, 74))
            surface.SetDrawColor(214, 220, 196, 60)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText("NOM DU SECTEUR VISÉ", "MZoneTool_Sub", S(18), S(14), Color(232, 234, 222), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        local entry = vgui.Create("DTextEntry", f)
        entry:SetPos(S(18), S(56))
        entry:SetSize(f:GetWide() - S(36), S(36))
        entry:SetFont("DermaLarge")
        entry:RequestFocus()
        entry.OnEnter = function(self)
            net.Start("MedalFrontline_ZoneTool")
                net.WriteString("rename")
                net.WriteVector(pos)
                net.WriteString(self:GetValue() or "")
            net.SendToServer()
            f:Remove()
        end
        local ok = vgui.Create("DButton", f)
        ok:SetText("")
        ok:SetPos(S(18), S(102))
        ok:SetSize(f:GetWide() - S(36), S(32))
        ok.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(60, 74, 44, 230))
            draw.SimpleText("RENOMMER (ENTRÉE)", "MZoneTool_Sub", w / 2, h / 2, Color(240, 242, 232), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        ok.DoClick = function() entry:OnEnter() end
        f.OnKeyCodePressed = function(self, k) if k == KEY_ESCAPE then self:Remove() end end
    end)

    function SWEP:DrawHUD()
        draw.SimpleText("CLIC G: créer  •  CLIC D: déplacer  •  R: supprimer  •  MOLETTE: rayon  •  F: renommer",
            "MZoneTool_Sub", ScrW() / 2, ScrH() - 80, Color(232, 234, 222, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(232, 234, 222, 220)
        surface.DrawRect(ScrW() / 2 - 1, ScrH() / 2 - 8, 2, 16)
        surface.DrawRect(ScrW() / 2 - 8, ScrH() / 2 - 1, 16, 2)
    end
end
