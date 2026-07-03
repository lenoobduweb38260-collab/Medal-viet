--[[
    Medal Barracks — Radio de campagne (client).
    - Aperçu fantôme de pose : clic droit avec la radio portative en main.
      Vert = position valide, rouge = invalide.
    - Maintenir clic gauche : jauge circulaire, la radio se pose à 100%.
    - Menu de fréquence (E sur la radio posée) : animation de tuning
      façon poste de campagne, puis choix de la fréquence.
]]

if SERVER then return end

MedalBarracks = MedalBarracks or {}
local cfg = MedalBarracks.Config or {}

local function radioCfg()
    return cfg.Radio or {}
end

local function S(v)
    return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080))
end

surface.CreateFont("MedalRadio_Title", {font = "Roboto Condensed", size = 30, weight = 1000, extended = true})
surface.CreateFont("MedalRadio_Row", {font = "Roboto Condensed", size = 17, weight = 700, extended = true})
surface.CreateFont("MedalRadio_Small", {font = "Roboto Condensed", size = 13, weight = 800, extended = true})
surface.CreateFont("MedalRadio_Freq", {font = "Courier New", size = 26, weight = 800, extended = true})

local COL_OLIVE = Color(112, 126, 74)
local COL_KHAKI = Color(148, 156, 108)
local COL_WHITE = Color(232, 234, 222)
local COL_RED = Color(165, 48, 40)

-- =========================
-- Pose : fantôme + jauge
-- =========================
local placement = {
    active = false,
    ghost = nil,
    valid = false,
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0),
    progress = 0,
}

local function holdingRadioSwep()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return false end
    local wep = ply:GetActiveWeapon()
    return IsValid(wep) and wep:GetClass() == "medal_radio_swep"
end

local function removeGhost()
    if IsValid(placement.ghost) then placement.ghost:Remove() end
    placement.ghost = nil
    placement.active = false
    placement.progress = 0
end

local function ensureGhost()
    if IsValid(placement.ghost) then return placement.ghost end
    local mdl = tostring(radioCfg().PropModel or "models/props_lab/reciever01a.mdl")
    local ghost = ClientsideModel(mdl, RENDERGROUP_TRANSLUCENT)
    if not IsValid(ghost) then return nil end
    ghost:SetNoDraw(false)
    ghost:SetRenderMode(RENDERMODE_TRANSCOLOR)
    placement.ghost = ghost
    return ghost
end

local function updatePlacement()
    local ply = LocalPlayer()
    local rc = radioCfg()
    local maxDist = tonumber(rc.MaxDeployDistance) or 95

    local eyePos = ply:EyePos()
    local aim = ply:GetAimVector()
    local tr = util.TraceLine({start = eyePos, endpos = eyePos + aim * maxDist, filter = ply})
    local base = tr.Hit and tr.HitPos or (eyePos + aim * maxDist)

    -- Descend au sol pour poser la radio à plat.
    local ground = util.TraceLine({start = base + Vector(0, 0, 12), endpos = base - Vector(0, 0, 90), filter = ply})
    local valid = ground.Hit and ground.HitNormal.z >= 0.8

    local pos = ground.Hit and ground.HitPos or base
    if valid then
        local hull = util.TraceHull({
            start = pos + Vector(0, 0, 8),
            endpos = pos + Vector(0, 0, 8),
            mins = Vector(-10, -10, 0),
            maxs = Vector(10, 10, 14),
            filter = ply,
        })
        if hull.Hit or hull.StartSolid then valid = false end
    end
    if pos:Distance(ply:GetPos()) > maxDist * 1.5 then valid = false end

    placement.pos = pos
    placement.ang = Angle(0, ply:EyeAngles().y + 180, 0)
    placement.valid = valid

    local ghost = ensureGhost()
    if IsValid(ghost) then
        ghost:SetPos(pos)
        ghost:SetAngles(placement.ang)
        -- Vert si valide, rouge sinon — comme demandé.
        ghost:SetColor(valid and Color(95, 200, 90, 165) or Color(210, 60, 50, 165))
    end
end

hook.Add("KeyPress", "MedalRadio_TogglePlacement", function(ply, key)
    if ply ~= LocalPlayer() or not IsFirstTimePredicted() then return end
    if key ~= IN_ATTACK2 then return end
    if not holdingRadioSwep() then return end
    if radioCfg().Enabled == false then return end
    if placement.active then
        removeGhost()
    else
        placement.active = true
        placement.progress = 0
    end
end)

hook.Add("Think", "MedalRadio_PlacementThink", function()
    if not placement.active then return end
    if not holdingRadioSwep() then removeGhost(); return end

    updatePlacement()

    local ply = LocalPlayer()
    if ply:KeyDown(IN_ATTACK) and placement.valid then
        -- Jauge circulaire : la radio se pose au bout de DeployTime secondes.
        local dur = math.max(tonumber(radioCfg().DeployTime) or 1.6, 0.2)
        placement.progress = math.min(placement.progress + FrameTime() / dur, 1)
        if placement.progress >= 1 then
            net.Start("MedalRadio_Place")
                net.WriteVector(placement.pos)
                net.WriteAngle(placement.ang)
            net.SendToServer()
            removeGhost()
        end
    else
        placement.progress = math.max(placement.progress - FrameTime() * 2.5, 0)
    end
end)

hook.Add("PlayerSwitchWeapon", "MedalRadio_CancelOnSwitch", function(ply)
    if ply == LocalPlayer() and placement.active then removeGhost() end
end)

-- Jauge circulaire au centre de l'écran.
local function drawArc(cx, cy, radius, thickness, startAng, endAng, col)
    local segs = 48
    draw.NoTexture()
    surface.SetDrawColor(col)
    for i = 0, segs - 1 do
        local t1 = startAng + (endAng - startAng) * (i / segs)
        local t2 = startAng + (endAng - startAng) * ((i + 1) / segs)
        local a1, a2 = math.rad(t1), math.rad(t2)
        surface.DrawPoly({
            {x = cx + math.cos(a1) * radius, y = cy + math.sin(a1) * radius},
            {x = cx + math.cos(a2) * radius, y = cy + math.sin(a2) * radius},
            {x = cx + math.cos(a2) * (radius - thickness), y = cy + math.sin(a2) * (radius - thickness)},
            {x = cx + math.cos(a1) * (radius - thickness), y = cy + math.sin(a1) * (radius - thickness)},
        })
    end
end

hook.Add("HUDPaint", "MedalRadio_PlacementHUD", function()
    if not placement.active or not holdingRadioSwep() then return end
    local cx, cy = ScrW() / 2, ScrH() / 2

    -- Anneau de fond + progression (la "roue" de pose).
    drawArc(cx, cy, S(34), S(5), -90, 270, Color(10, 12, 9, 160))
    if placement.progress > 0 then
        drawArc(cx, cy, S(34), S(5), -90, -90 + 360 * placement.progress, placement.valid and COL_KHAKI or COL_RED)
    end

    local hint = placement.valid and "MAINTIENS LE CLIC GAUCHE POUR POSER LA RADIO" or "POSITION INVALIDE — VISE UN SOL DÉGAGÉ"
    draw.SimpleText(hint, "MedalRadio_Small", cx, cy + S(58), placement.valid and COL_WHITE or COL_RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText("CLIC DROIT : ANNULER", "MedalRadio_Small", cx, cy + S(76), Color(232, 234, 222, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)

-- =========================
-- Menu de fréquence (E sur la radio posée)
-- =========================
local function openRadioMenu(ent)
    if IsValid(MedalBarracks.RadioMenu) then MedalBarracks.RadioMenu:Remove() end
    if not IsValid(ent) then return end
    local rc = radioCfg()

    local frame = vgui.Create("DFrame")
    MedalBarracks.RadioMenu = frame
    local fw, fh = S(560), S(470)
    frame:SetSize(fw, fh)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.12, 0)
    frame.tuneStart = SysTime()
    frame.tuneTime = math.max(tonumber(rc.TuneTime) or 1.4, 0.3)

    local freqs = rc.Frequencies or {}
    local currentFreq = ent:GetNWString("MedalRadio_Freq", "radioman")

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 9, 242))
        draw.RoundedBox(0, 0, 0, S(5), h, COL_OLIVE)
        surface.SetDrawColor(214, 220, 196, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        draw.SimpleText("POSTE RADIO DE CAMPAGNE", "MedalRadio_Title", S(30), S(24), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("OPÉRATEUR : " .. ent:GetNWString("MedalRadio_OwnerName", "?"), "MedalRadio_Small", S(31), S(58), Color(232, 234, 222, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(112, 126, 74, 200)
        surface.DrawRect(S(30), S(80), S(56), S(3))

        -- Bande de fréquences avec aiguille : animation de recherche puis position stable.
        local bandX, bandY, bandW, bandH = S(30), S(102), w - S(60), S(74)
        draw.RoundedBox(0, bandX, bandY, bandW, bandH, Color(16, 19, 14, 235))
        surface.SetDrawColor(214, 220, 196, 45)
        surface.DrawOutlinedRect(bandX, bandY, bandW, bandH, 1)
        for i = 0, 20 do
            local x = bandX + S(14) + (bandW - S(28)) * (i / 20)
            local tall = (i % 5 == 0) and S(18) or S(9)
            surface.SetDrawColor(148, 156, 108, i % 5 == 0 and 160 or 80)
            surface.DrawRect(x, bandY + bandH - tall - S(8), S(1), tall)
            if i % 5 == 0 then
                draw.SimpleText(tostring(28 + i), "MedalRadio_Small", x, bandY + S(8), Color(148, 156, 108, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end

        -- Position cible de l'aiguille selon la fréquence sélectionnée.
        local targetT = 0.3
        for idx, f in ipairs(freqs) do
            if tostring(f.id) == currentFreq then targetT = idx / (#freqs + 1) end
        end
        local elapsed = SysTime() - self.tuneStart
        local tuning = elapsed < self.tuneTime
        local t
        if tuning then
            -- L'aiguille balaie la bande comme si on cherchait la fréquence.
            local sweep = elapsed / self.tuneTime
            t = 0.5 + 0.48 * math.sin(elapsed * 14 * (1.05 - sweep)) * (1 - sweep)
            t = math.Clamp(t * (1 - sweep) + targetT * sweep, 0.02, 0.98)
        else
            t = targetT + math.sin(SysTime() * 2.2) * 0.004 -- micro-oscillation réaliste
        end
        local nx = bandX + S(14) + (bandW - S(28)) * t
        surface.SetDrawColor(COL_RED)
        surface.DrawRect(nx, bandY + S(6), S(2), bandH - S(12))

        -- Affichage "cadran" de la fréquence.
        local shown = ""
        for _, f in ipairs(freqs) do if tostring(f.id) == currentFreq then shown = tostring(f.freq or "") end end
        if tuning then shown = string.format("%05.2f MHz", 28 + t * 20 + math.Rand(-0.35, 0.35)) end
        draw.SimpleText(shown, "MedalRadio_Freq", w / 2, bandY + bandH + S(22), tuning and Color(232, 234, 222, 150 + math.random(0, 90)) or COL_KHAKI, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if tuning then
            draw.SimpleText("RECHERCHE DE LA FRÉQUENCE…", "MedalRadio_Small", w / 2, bandY + bandH + S(44), Color(232, 234, 222, 120 + math.random(0, 60)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end

    -- Boutons de fréquence : n'apparaissent qu'après l'animation de tuning.
    local btnY = S(250)
    for _, f in ipairs(freqs) do
        local b = vgui.Create("DButton", frame)
        b:SetText("")
        b:SetPos(S(30), btnY)
        b:SetSize(fw - S(60), S(56))
        b:SetVisible(false)
        b.freq = f
        b.Paint = function(self, w, h)
            self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
            local selected = tostring(f.id) == currentFreq
            draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 180 + self.hoverAnim * 50))
            draw.RoundedBox(0, 0, 0, S(4), h, selected and COL_KHAKI or COL_OLIVE)
            surface.SetDrawColor(214, 220, 196, selected and 120 or (35 + self.hoverAnim * 70))
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(tostring(f.name or f.id), "MedalRadio_Row", S(18), S(9), selected and COL_KHAKI or COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(f.desc or ""), "MedalRadio_Small", S(18), S(32), Color(232, 234, 222, 140), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(f.freq or ""), "MedalRadio_Freq", w - S(18), h / 2, selected and COL_KHAKI or Color(232, 234, 222, 170), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            currentFreq = tostring(f.id)
            frame.tuneStart = SysTime() -- nouvelle recherche de fréquence à chaque réglage
            net.Start("MedalRadio_SetFreq")
                net.WriteEntity(ent)
                net.WriteString(currentFreq)
            net.SendToServer()
        end
        btnY = btnY + S(64)
    end

    local isOwner = IsValid(LocalPlayer()) and ent:GetNWString("MedalRadio_Owner", "") == LocalPlayer():SteamID64()
    if isOwner then
        local pack = vgui.Create("DButton", frame)
        pack:SetText("")
        pack:SetPos(S(30), fh - S(76))
        pack:SetSize(S(230), S(46))
        pack:SetVisible(false)
        pack.isAction = true
        pack.Paint = function(self, w, h)
            self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
            draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 180 + self.hoverAnim * 50))
            draw.RoundedBox(0, 0, 0, S(4), h, COL_RED)
            surface.SetDrawColor(214, 220, 196, 35 + self.hoverAnim * 80)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText("REMBALLER LA RADIO", "MedalRadio_Row", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        pack.DoClick = function()
            net.Start("MedalRadio_Remove")
                net.WriteEntity(ent)
            net.SendToServer()
            frame:Remove()
        end
    end

    local close = vgui.Create("DButton", frame)
    close:SetText("")
    close:SetPos(fw - S(30) - S(160), fh - S(76))
    close:SetSize(S(160), S(46))
    close.Paint = function(self, w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
        draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 180 + self.hoverAnim * 50))
        draw.RoundedBox(0, 0, 0, S(4), h, Color(110, 110, 110))
        surface.SetDrawColor(214, 220, 196, 35 + self.hoverAnim * 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("FERMER", "MedalRadio_Row", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close.DoClick = function() frame:Remove() end

    -- Révèle les boutons quand l'aiguille s'est stabilisée.
    frame.Think = function(self)
        if not IsValid(ent) then self:Remove(); return end
        if ent:GetPos():Distance(LocalPlayer():GetPos()) > 170 then self:Remove(); return end
        local ready = (SysTime() - self.tuneStart) >= self.tuneTime
        for _, child in ipairs(self:GetChildren()) do
            if child.freq or child.isAction then child:SetVisible(ready) end
        end
    end
    frame.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then self:Remove() end
    end
end

net.Receive("MedalRadio_OpenMenu", function()
    openRadioMenu(net.ReadEntity())
end)

-- =========================
-- Réception des messages radio
-- =========================
net.Receive("MedalRadio_ChatMsg", function()
    local channel = net.ReadString()
    local name = net.ReadString()
    local msg = net.ReadString()
    chat.AddText(COL_OLIVE, "[" .. channel .. "] ", COL_KHAKI, name, COL_WHITE, " : " .. msg)
    local snd = tostring(radioCfg().MsgSound or "npc/combine_soldier/vo/on1.wav")
    if snd ~= "" then surface.PlaySound(snd) end
end)
