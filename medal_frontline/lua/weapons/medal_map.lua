--[[
    Medal Frontline — Carte tactique (SWEP).
    Clic gauche : ouvre/ferme la carte plein écran (vue de dessus de la map).
    Sur la carte, les CHEFS D'ESCOUADE et le COMMANDEMENT peuvent poser des
    marqueurs visibles UNIQUEMENT par les autres chefs/commandement de leur camp.
      - Sélection du type de marqueur en haut.
      - Clic gauche : poser • Clic droit : retirer le plus proche.
    Les autres joueurs voient la carte mais pas les marqueurs.
]]

AddCSLuaFile()

SWEP.PrintName = "Carte tactique"
SWEP.Author = "Medal Vietnam"
SWEP.Instructions = "Clic gauche : ouvrir la carte."
SWEP.Category = "Medal Vietnam"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/props_junk/cardboard_box004a.mdl"
SWEP.UseHands = true
SWEP.HoldType = "slam"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.DrawAmmo = false

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.4)
    if CLIENT and MedalFrontline.ToggleMap then MedalFrontline.ToggleMap() end
end

function SWEP:SecondaryAttack() end

function SWEP:Holster()
    if CLIENT and MedalFrontline.CloseMap then MedalFrontline.CloseMap() end
    return true
end

if not CLIENT then return end

MedalFrontline = MedalFrontline or {}
-- La config peut ne pas être encore chargée quand le SWEP est enregistré.
if not MedalFrontline.Config then pcall(include, "medal_frontline/sh_config.lua") end
local cfg = MedalFrontline.Config or {}

local function S(v) return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080)) end

surface.CreateFont("MMap_Title", {font = "Roboto Condensed", size = 30, weight = 1000, extended = true})
surface.CreateFont("MMap_Small", {font = "Roboto Condensed", size = 14, weight = 800, extended = true})
surface.CreateFont("MMap_Marker", {font = "Roboto Condensed", size = 15, weight = 900, extended = true})

-- Marqueurs reçus du serveur : MedalFrontline.MyMarkers = {faction, list={{pos,type,label,author}}}
MedalFrontline.MyMarkers = MedalFrontline.MyMarkers or {faction = "", list = {}}

net.Receive("MedalFrontline_Markers", function()
    local fac = net.ReadString()
    local count = net.ReadUInt(8)
    local list = {}
    for i = 1, count do
        list[i] = {pos = net.ReadVector(), type = net.ReadString(), label = net.ReadString(), author = net.ReadString()}
    end
    MedalFrontline.MyMarkers = {faction = fac, list = list}
end)

-- Bornes de la vue top-down. La caméra regarde droit vers le bas depuis le
-- centre de la map ; la couverture au sol est linéaire (donc monde<->carte
-- est un simple mapping affine).
local mapRT = GetRenderTargetEx("MedalFrontlineMapRT", 1024, 1024, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, 0, 0, IMAGE_FORMAT_RGBA8888)
local mapMat = CreateMaterial("MedalFrontlineMapMat", "UnlitGeneric", {["$basetexture"] = mapRT:GetName(), ["$nolod"] = 1})

local function mapView()
    -- Centre + couverture calculés depuis les limites du monde.
    local mc = cfg.Map or {}
    local mins, maxs = game.GetWorld():GetModelBounds()
    -- GetModelBounds du world renvoie souvent tout ; fallback sur des bornes larges.
    if not mins or mins:Length() < 1 then mins = Vector(-16000, -16000, -8000) end
    if not maxs or maxs:Length() < 1 then maxs = Vector(16000, 16000, 8000) end
    local center = (mins + maxs) / 2
    center.z = maxs.z + 200
    local height = tonumber(mc.CameraHeight) or 12000
    local span = math.max(maxs.x - mins.x, maxs.y - mins.y) * 0.55
    return center, height, span
end

local function captureMap()
    local center, height, span = mapView()
    local eye = Vector(center.x, center.y, center.z + height)
    render.PushRenderTarget(mapRT)
        render.Clear(15, 17, 13, 255, true, true)
        cam.Start2D()
            render.RenderView({
                origin = eye,
                angles = Angle(90, 0, 0),
                x = 0, y = 0, w = 1024, h = 1024,
                drawviewmodel = false,
                drawhud = false,
                fov = 90,
                ortho = {left = -span, right = span, top = -span, bottom = span},
            })
        cam.End2D()
    render.PopRenderTarget()
    MedalFrontline.MapCenter = center
    MedalFrontline.MapSpan = span
end

-- Monde -> position sur le panneau carte (px, py sont le coin + taille du panneau).
local function worldToMap(pos, px, py, pw, ph)
    local c = MedalFrontline.MapCenter or Vector(0, 0, 0)
    local span = MedalFrontline.MapSpan or 10000
    local u = (pos.x - c.x) / span * 0.5 + 0.5
    local v = (pos.y - c.y) / span * 0.5 + 0.5
    if (cfg.Map or {}).InvertX then u = 1 - u end
    if (cfg.Map or {}).InvertY == false then else v = 1 - v end
    return px + u * pw, py + v * ph
end

local function mapToWorld(mx, my, px, py, pw, ph)
    local c = MedalFrontline.MapCenter or Vector(0, 0, 0)
    local span = MedalFrontline.MapSpan or 10000
    local u = (mx - px) / pw
    local v = (my - py) / ph
    if (cfg.Map or {}).InvertX then u = 1 - u end
    if (cfg.Map or {}).InvertY == false then else v = 1 - v end
    return Vector(c.x + (u - 0.5) * 2 * span, c.y + (v - 0.5) * 2 * span, c.z)
end

local selectedType = 1

function MedalFrontline.CloseMap()
    if IsValid(MedalFrontline.MapFrame) then MedalFrontline.MapFrame:Remove() end
end

function MedalFrontline.ToggleMap()
    if IsValid(MedalFrontline.MapFrame) then MedalFrontline.MapFrame:Remove(); return end
    captureMap()

    local isLeader = LocalPlayer():GetNWBool("MedalBarracks_SquadLeader", false)
    do
        local role = LocalPlayer():GetNWString("MedalBarracks_Role", "")
        for _, r in ipairs((cfg.Map or {}).LeaderRoleIDs or {}) do
            if tostring(r) == role then isLeader = true end
        end
    end
    if LocalPlayer():IsAdmin() then isLeader = true end

    local frame = vgui.Create("DFrame")
    MedalFrontline.MapFrame = frame
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()

    local mapSize = math.min(ScrH() - S(160), ScrW() - S(200))
    local mx0 = ScrW() / 2 - mapSize / 2
    local my0 = S(120)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(6, 8, 6, 238))
        draw.SimpleText("CARTE TACTIQUE", "MMap_Title", ScrW() / 2, S(48), Color(232, 234, 222), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(isLeader and "CLIC GAUCHE : POSER UN MARQUEUR  •  CLIC DROIT : RETIRER  •  ÉCHAP : FERMER"
            or "Marqueurs réservés aux chefs d'escouade et au commandement", "MMap_Small", ScrW() / 2, S(78), Color(200, 205, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Fond : rendu vue de dessus.
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(mapMat)
        surface.DrawTexturedRect(mx0, my0, mapSize, mapSize)
        surface.SetDrawColor(90, 100, 74, 150)
        surface.DrawOutlinedRect(mx0, my0, mapSize, mapSize, 2)

        -- Grille légère.
        surface.SetDrawColor(120, 130, 100, 30)
        for i = 1, 7 do
            surface.DrawLine(mx0 + mapSize / 8 * i, my0, mx0 + mapSize / 8 * i, my0 + mapSize)
            surface.DrawLine(mx0, my0 + mapSize / 8 * i, mx0 + mapSize, my0 + mapSize / 8 * i)
        end

        -- Secteurs de la frontline.
        for _, z in ipairs((MedalFrontline.State or {}).zones or {}) do
            if z.pos and not z.hidden then
                local zx, zy = worldToMap(z.pos, mx0, my0, mapSize, mapSize)
                local col = z.owner ~= "" and ((cfg.FactionColors or {})[z.owner] or Color(150, 150, 150)) or Color(150, 160, 120)
                surface.SetDrawColor(col.r, col.g, col.b, 60)
                local rr = math.max(z.radius / (MedalFrontline.MapSpan * 2) * mapSize, 6)
                draw.NoTexture()
                surface.DrawRect(zx - rr, zy - rr, rr * 2, rr * 2)
                surface.SetDrawColor(col.r, col.g, col.b, 220)
                surface.DrawOutlinedRect(zx - rr, zy - rr, rr * 2, rr * 2, 2)
                draw.SimpleText(z.name or "", "MMap_Small", zx, zy - rr - S(10), Color(232, 234, 222, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        -- Marqueur "toi".
        local me = LocalPlayer()
        if IsValid(me) then
            local mxp, myp = worldToMap(me:GetPos(), mx0, my0, mapSize, mapSize)
            surface.SetDrawColor(255, 255, 255, 255)
            draw.NoTexture()
            surface.DrawPoly({{x = mxp, y = myp - S(7)}, {x = mxp + S(5), y = myp + S(5)}, {x = mxp - S(5), y = myp + S(5)}})
        end

        -- Marqueurs de commandement (chefs / commandement uniquement).
        if isLeader then
            for _, m in ipairs((MedalFrontline.MyMarkers or {}).list or {}) do
                local mxp, myp = worldToMap(m.pos, mx0, my0, mapSize, mapSize)
                local mt
                for _, t in ipairs((cfg.Map or {}).MarkerTypes or {}) do if t.id == m.type then mt = t end end
                local col = mt and mt.color or Color(220, 220, 220)
                surface.SetDrawColor(col.r, col.g, col.b, 255)
                draw.NoTexture()
                surface.DrawRect(mxp - S(6), myp - S(6), S(12), S(12))
                surface.SetDrawColor(0, 0, 0, 200)
                surface.DrawOutlinedRect(mxp - S(6), myp - S(6), S(12), S(12), 1)
                draw.SimpleText((mt and mt.name or m.type) .. (m.label ~= "" and (" — " .. m.label) or ""), "MMap_Marker", mxp, myp - S(16), col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    -- Sélecteur de type de marqueur (chefs uniquement).
    if isLeader then
        local types = (cfg.Map or {}).MarkerTypes or {}
        local btnW = S(150)
        local totalW = #types * (btnW + S(8))
        local sx = ScrW() / 2 - totalW / 2
        for i, t in ipairs(types) do
            local b = vgui.Create("DButton", frame)
            b:SetText("")
            b:SetPos(sx + (i - 1) * (btnW + S(8)), my0 + mapSize + S(14))
            b:SetSize(btnW, S(38))
            b.Paint = function(self, w, h)
                local sel = selectedType == i
                draw.RoundedBox(0, 0, 0, w, h, sel and Color(t.color.r, t.color.g, t.color.b, 90) or Color(18, 21, 15, 200))
                draw.RoundedBox(0, 0, 0, S(3), h, t.color)
                surface.SetDrawColor(214, 220, 196, sel and 120 or 40)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText(t.name, "MMap_Small", w / 2, h / 2, sel and Color(240, 242, 232) or Color(210, 214, 196), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            b.DoClick = function() selectedType = i end
        end

        local clear = vgui.Create("DButton", frame)
        clear:SetText("")
        clear:SetPos(ScrW() / 2 - S(90), my0 + mapSize + S(60))
        clear:SetSize(S(180), S(34))
        clear.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(18, 21, 15, 200))
            draw.RoundedBox(0, 0, 0, S(3), h, Color(165, 48, 40))
            draw.SimpleText("EFFACER MES MARQUEURS", "MMap_Small", w / 2, h / 2, Color(232, 234, 222), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        clear.DoClick = function()
            net.Start("MedalFrontline_MarkerAction")
                net.WriteString("clear")
            net.SendToServer()
        end
    end

    -- Zone cliquable de la carte.
    local hit = vgui.Create("DButton", frame)
    hit:SetText("")
    hit:SetPos(mx0, my0)
    hit:SetSize(mapSize, mapSize)
    hit.Paint = function() end
    hit.DoClick = function()
        if not isLeader then return end
        local mx, my = hit:CursorPos()
        local world = mapToWorld(mx + mx0, my + my0, mx0, my0, mapSize, mapSize)
        local t = ((cfg.Map or {}).MarkerTypes or {})[selectedType]
        net.Start("MedalFrontline_MarkerAction")
            net.WriteString("add")
            net.WriteVector(world)
            net.WriteString(t and t.id or "move")
            net.WriteString("")
        net.SendToServer()
    end
    hit.DoRightClick = function()
        if not isLeader then return end
        local mx, my = hit:CursorPos()
        local world = mapToWorld(mx + mx0, my + my0, mx0, my0, mapSize, mapSize)
        net.Start("MedalFrontline_MarkerAction")
            net.WriteString("remove")
            net.WriteVector(world)
        net.SendToServer()
    end

    frame.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then self:Remove() end
    end
end
