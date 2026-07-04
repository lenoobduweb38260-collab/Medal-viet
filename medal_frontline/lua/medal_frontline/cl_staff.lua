--[[
    Medal Frontline — Panneau staff (client).
    Choix du mode (Warfare / Offensive / Escarmouche), camp attaquant,
    lancement/arrêt/réinitialisation, définition des secteurs à sa position,
    et rappel des joueurs actifs par camp.
]]

if SERVER then return end

MedalFrontline = MedalFrontline or {}
local cfg = MedalFrontline.Config or {}

local function S(v)
    return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080))
end

surface.CreateFont("MFrontStaff_Title", {font = "Roboto Condensed", size = 30, weight = 1000, extended = true})
surface.CreateFont("MFrontStaff_Row", {font = "Roboto Condensed", size = 17, weight = 800, extended = true})
surface.CreateFont("MFrontStaff_Small", {font = "Roboto Condensed", size = 13, weight = 800, extended = true})

local COL_OLIVE = Color(112, 126, 74)
local COL_KHAKI = Color(148, 156, 108)
local COL_WHITE = Color(232, 234, 222)
local COL_RED = Color(165, 48, 40)

local FAC1 = (cfg.Factions or {})[1] or "americans"
local FAC2 = (cfg.Factions or {})[2] or "vietcong"

local function staffAction(action, arg)
    net.Start("MedalFrontline_Staff")
        net.WriteString(action)
        net.WriteString(tostring(arg or ""))
    net.SendToServer()
end

local function facName(fac)
    return (cfg.FactionNames or {})[fac] or string.upper(tostring(fac))
end

function MedalFrontline.OpenStaffMenu()
    if IsValid(MedalFrontline.StaffFrame) then MedalFrontline.StaffFrame:Remove(); return end

    local frame = vgui.Create("DFrame")
    MedalFrontline.StaffFrame = frame
    local fw, fh = S(760), S(820)
    frame:SetSize(fw, fh)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.12, 0)

    frame.Paint = function(self, w, h)
        local state = MedalFrontline.State or {}
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 9, 244))
        draw.RoundedBox(0, 0, 0, S(5), h, COL_OLIVE)
        surface.SetDrawColor(214, 220, 196, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        draw.SimpleText("MEDAL FRONTLINE — PANNEAU STAFF", "MFrontStaff_Title", S(30), S(24), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local modeName = ((cfg.Modes or {})[state.mode or ""] or {}).name or "?"
        local status = state.active and ("OPÉRATION EN COURS — " .. modeName) or ("EN ATTENTE — mode " .. modeName)
        draw.SimpleText(status, "MFrontStaff_Small", S(31), S(58), state.active and COL_KHAKI or Color(232, 234, 222, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(112, 126, 74, 200)
        surface.DrawRect(S(30), S(80), S(56), S(3))

        -- Joueurs actifs (AFK > 5 min exclus).
        local c1 = GetGlobalInt("MedalFrontline_Active_" .. FAC1, 0)
        local c2 = GetGlobalInt("MedalFrontline_Active_" .. FAC2, 0)
        draw.SimpleText("ACTIFS : " .. facName(FAC1) .. " " .. c1 .. "   •   " .. facName(FAC2) .. " " .. c2, "MFrontStaff_Small", w - S(30), S(60), Color(232, 234, 222, 165), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    local function styledButton(label, x, y, w, h, accent, onClick, selectedFn)
        local b = vgui.Create("DButton", frame)
        b:SetText("")
        b:SetPos(x, y)
        b:SetSize(w, h)
        b.Paint = function(self, bw, bh)
            self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
            local sel = selectedFn and selectedFn() or false
            draw.RoundedBox(0, 0, 0, bw, bh, sel and Color(accent.r, accent.g, accent.b, 55) or Color(16, 19, 14, 180 + self.hoverAnim * 55))
            draw.RoundedBox(0, 0, 0, S(3), bh, sel and accent or Color(60, 66, 52, 200))
            surface.SetDrawColor(214, 220, 196, sel and 120 or (30 + self.hoverAnim * 75))
            surface.DrawOutlinedRect(0, 0, bw, bh, 1)
            draw.SimpleText(label, "MFrontStaff_Row", bw / 2, bh / 2, sel and COL_KHAKI or COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = onClick
        return b
    end

    -- ===== Choix du mode =====
    local modeY = S(100)
    local modeOrder = {"warfare", "offensive", "skirmish"}
    for i, modeID in ipairs(modeOrder) do
        local mode = (cfg.Modes or {})[modeID] or {}
        local b = vgui.Create("DButton", frame)
        b:SetText("")
        b:SetPos(S(30), modeY + (i - 1) * S(74))
        b:SetSize(fw - S(60), S(66))
        b.Paint = function(self, bw, bh)
            self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
            local sel = (MedalFrontline.State or {}).mode == modeID
            draw.RoundedBox(0, 0, 0, bw, bh, sel and Color(COL_OLIVE.r, COL_OLIVE.g, COL_OLIVE.b, 55) or Color(16, 19, 14, 180 + self.hoverAnim * 55))
            draw.RoundedBox(0, 0, 0, S(4), bh, sel and COL_KHAKI or COL_OLIVE)
            surface.SetDrawColor(214, 220, 196, sel and 120 or (30 + self.hoverAnim * 75))
            surface.DrawOutlinedRect(0, 0, bw, bh, 1)
            draw.SimpleText(tostring(mode.name or modeID), "MFrontStaff_Row", S(18), S(10), sel and COL_KHAKI or COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(mode.desc or ""), "MFrontStaff_Small", S(18), S(34), Color(232, 234, 222, 140), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            if sel then draw.SimpleText("MODE ACTUEL", "MFrontStaff_Small", bw - S(16), S(12), COL_KHAKI, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP) end
        end
        b.DoClick = function() staffAction("mode", modeID) end
    end

    -- ===== Camp attaquant (Offensive) =====
    local atkY = modeY + 3 * S(74) + S(8)
    local atkLabel = vgui.Create("DPanel", frame)
    atkLabel:SetPos(S(30), atkY)
    atkLabel:SetSize(fw - S(60), S(18))
    atkLabel.Paint = function(self, w, h)
        draw.SimpleText("CAMP ATTAQUANT (MODE OFFENSIVE)", "MFrontStaff_Small", 0, 0, Color(232, 234, 222, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    local halfW = math.floor((fw - S(60) - S(12)) / 2)
    styledButton(facName(FAC1), S(30), atkY + S(22), halfW, S(40), (cfg.FactionColors or {})[FAC1] or COL_KHAKI, function()
        staffAction("attacker", FAC1)
    end, function() return (MedalFrontline.State or {}).attacker == FAC1 end)
    styledButton(facName(FAC2), S(30) + halfW + S(12), atkY + S(22), halfW, S(40), (cfg.FactionColors or {})[FAC2] or COL_RED, function()
        staffAction("attacker", FAC2)
    end, function() return (MedalFrontline.State or {}).attacker == FAC2 end)

    -- ===== Secteurs =====
    local zoneY = atkY + S(76)
    local zoneLabel = vgui.Create("DPanel", frame)
    zoneLabel:SetPos(S(30), zoneY)
    zoneLabel:SetSize(fw - S(60), S(18))
    zoneLabel.Paint = function(self, w, h)
        draw.SimpleText("SECTEURS — place-toi au centre du secteur puis clique DÉFINIR ICI (sauvegarde automatique par map)", "MFrontStaff_Small", 0, 0, Color(232, 234, 222, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local zoneScroll = vgui.Create("DScrollPanel", frame)
    zoneScroll:SetPos(S(30), zoneY + S(22))
    zoneScroll:SetSize(fw - S(60), fh - zoneY - S(120))

    local function rebuild()
        if not IsValid(zoneScroll) then return end
        zoneScroll:Clear()
        local zones = (MedalFrontline.State or {}).zones or {}
        local total = math.max(#zones, tonumber(cfg.DefaultZoneCount) or 5)
        for i = 1, total do
            local z = zones[i]
            local row = vgui.Create("DPanel", zoneScroll)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, S(6))
            row:SetTall(S(40))
            row.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 190))
                draw.RoundedBox(0, 0, 0, S(3), h, z and COL_OLIVE or Color(60, 66, 52, 200))
                surface.SetDrawColor(214, 220, 196, 30)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                local name = z and z.name or ((cfg.ZoneNames or {})[i] or ("POINT " .. i))
                local info = z and string.format("x %d  y %d  •  rayon %d", z.pos.x, z.pos.y, z.radius or 900) or "NON DÉFINI"
                draw.SimpleText(name, "MFrontStaff_Row", S(14), h / 2, z and COL_WHITE or Color(232, 234, 222, 110), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(info, "MFrontStaff_Small", S(190), h / 2, Color(232, 234, 222, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            local setBtn = vgui.Create("DButton", row)
            setBtn:SetText("")
            setBtn.Paint = function(self, w, h)
                self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
                draw.RoundedBox(0, 0, 0, w, h, Color(20, 24, 17, 200 + self.hoverAnim * 40))
                draw.RoundedBox(0, 0, 0, S(2), h, COL_KHAKI)
                draw.SimpleText("DÉFINIR ICI", "MFrontStaff_Small", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            setBtn.DoClick = function() staffAction("setzone", i) end
            row.PerformLayout = function(self, w, h)
                setBtn:SetSize(S(110), S(26))
                setBtn:SetPos(w - S(122), S(7))
            end
        end
    end
    frame.Rebuild = rebuild
    rebuild()

    -- ===== Contrôle de la partie =====
    styledButton("LANCER", S(30), fh - S(76), S(180), S(46), COL_KHAKI, function() staffAction("start") end)
    styledButton("ARRÊTER", S(224), fh - S(76), S(160), S(46), COL_RED, function() staffAction("stop") end)
    styledButton("RÉINITIALISER", S(398), fh - S(76), S(180), S(46), Color(120, 120, 120), function() staffAction("reset") end)
    styledButton("FERMER", fw - S(30) - S(130), fh - S(76), S(130), S(46), Color(90, 90, 90), function() frame:Remove() end)

    frame.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then self:Remove() end
    end
end

concommand.Add(tostring(cfg.StaffCommand or "medal_frontline_staff"), function()
    MedalFrontline.OpenStaffMenu()
end)
