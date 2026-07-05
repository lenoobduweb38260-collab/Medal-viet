--[[
    Medal Garage — client.
    Menu garage (HLL), HUD véhicule (HLL) avec essence/vitesse/vie/siège,
    changement de siège et ravitaillement.
]]

MedalGarage = MedalGarage or {}
local cfg = MedalGarage.Config or {}

local function S(v) return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080)) end
local function C(name) return (cfg.Colors or {})[name] or color_white end

surface.CreateFont("MGarage_Title", {font = "Roboto Condensed", size = 34, weight = 1000, extended = true})
surface.CreateFont("MGarage_Tab", {font = "Roboto Condensed", size = 18, weight = 900, extended = true})
surface.CreateFont("MGarage_Row", {font = "Roboto Condensed", size = 20, weight = 900, extended = true})
surface.CreateFont("MGarage_Small", {font = "Roboto Condensed", size = 14, weight = 800, extended = true})
surface.CreateFont("MGarage_HUD", {font = "Roboto Condensed", size = 20, weight = 950, extended = true})
surface.CreateFont("MGarage_HUDBig", {font = "Roboto Condensed", size = 30, weight = 1000, extended = true})
surface.CreateFont("MGarage_HUDSmall", {font = "Roboto Condensed", size = 13, weight = 800, extended = true})

MedalGarage.SeatIdx = 1
MedalGarage.SeatTotal = 1
net.Receive("MedalGarage_SeatInfo", function()
    MedalGarage.SeatIdx = net.ReadUInt(6)
    MedalGarage.SeatTotal = net.ReadUInt(6)
end)

MedalGarage.StaffPoints = MedalGarage.StaffPoints or {}
net.Receive("MedalGarage_Points", function()
    local n = net.ReadUInt(8)
    MedalGarage.StaffPoints = {}
    for i = 1, n do MedalGarage.StaffPoints[i] = net.ReadVector() end
end)

-- =========================
-- Menu garage
-- =========================
function MedalGarage.OpenMenu()
    if IsValid(MedalGarage.Frame) then MedalGarage.Frame:Remove(); return end
    net.Start("MedalGarage_Open") net.SendToServer()

    local frame = vgui.Create("DFrame")
    MedalGarage.Frame = frame
    local fw, fh = S(1200), S(760)
    frame:SetSize(fw, fh)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.12, 0)

    local activeCat = (cfg.Categories or {"BLINDÉS"})[1]
    local selected = nil            -- véhicule sélectionné (aperçu)
    local list, previewModel

    -- Colonnes : liste à gauche (dealer), grand aperçu à droite (William's style).
    local leftW = S(440)
    local rightX = leftW + S(30)
    local rightW = fw - rightX - S(24)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, C("Panel"))
        draw.RoundedBox(0, 0, 0, S(5), h, C("Olive"))
        surface.SetDrawColor(214, 220, 196, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("CONCESSIONNAIRE MILITAIRE", "MGarage_Title", S(28), S(22), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("NIVEAU ACTUEL : " .. MedalGarage.GetLevel(LocalPlayer()), "MGarage_Small", S(29), S(62), C("Khaki"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(112, 126, 74, 200)
        surface.DrawRect(S(28), S(84), S(56), S(3))

        -- Cadre du panneau d'aperçu.
        draw.RoundedBox(0, rightX, S(150), rightW, fh - S(180), Color(9, 11, 8, 220))
        surface.SetDrawColor(214, 220, 196, 40)
        surface.DrawOutlinedRect(rightX, S(150), rightW, fh - S(180), 1)
    end

    -- Onglets de catégorie.
    local tabY = S(104)
    local tabX = S(28)
    for _, catName in ipairs(cfg.Categories or {}) do
        local b = vgui.Create("DButton", frame)
        b:SetText("")
        surface.SetFont("MGarage_Tab")
        local tw = surface.GetTextSize(catName) + S(30)
        b:SetPos(tabX, tabY)
        b:SetSize(tw, S(36))
        b.Paint = function(self, w, h)
            local sel = activeCat == catName
            draw.RoundedBox(0, 0, 0, w, h, sel and Color(112, 126, 74, 80) or Color(18, 21, 15, 190))
            draw.RoundedBox(0, 0, 0, S(3), h, sel and C("Khaki") or C("Olive"))
            surface.SetDrawColor(214, 220, 196, sel and 120 or 40)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(catName, "MGarage_Tab", w / 2, h / 2, sel and C("White") or Color(210, 214, 196), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function() activeCat = catName; if list and list.Rebuild then list:Rebuild() end end
        tabX = tabX + tw + S(6)
    end

    -- ===== Aperçu 3D rotatif (façon William's Car Dealer) =====
    previewModel = vgui.Create("DModelPanel", frame)
    previewModel:SetPos(rightX + S(10), S(160))
    previewModel:SetSize(rightW - S(20), fh - S(320))
    previewModel:SetFOV(50)
    previewModel:SetVisible(false)
    previewModel.LayoutEntity = function(self, ent)
        ent:SetAngles(Angle(0, RealTime() * 25 % 360, 0))
        return ent
    end
    local function setPreview(veh)
        selected = veh
        if not veh then previewModel:SetVisible(false); return end
        previewModel:SetVisible(true)
        previewModel:SetModel(veh.model ~= "" and veh.model or "models/props_vehicles/car001a_phy.mdl")
        -- Recadrage automatique sur le modèle.
        local ent = previewModel:GetEntity()
        if IsValid(ent) then
            local mn, mx = ent:GetRenderBounds()
            local size = mn:Distance(mx)
            local center = (mn + mx) * 0.5
            previewModel:SetLookAt(center)
            previewModel:SetCamPos(center + Vector(size * 0.9, size * 0.9, size * 0.55))
        end
    end

    -- Panneau d'infos + bouton SORTIR sous l'aperçu.
    local infoPanel = vgui.Create("DPanel", frame)
    infoPanel:SetPos(rightX + S(10), fh - S(158))
    infoPanel:SetSize(rightW - S(20), S(96))
    infoPanel.Paint = function(self, w, h)
        if not selected then
            draw.SimpleText("Sélectionne un véhicule à gauche.", "MGarage_Small", w / 2, h / 2, Color(210, 214, 196, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        draw.SimpleText(selected.name, "MGarage_Title", 0, 0, C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(selected.desc or "", "MGarage_Small", 0, S(38), Color(210, 214, 196, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("CATÉGORIE : " .. (selected.category or "") .. "     ESSENCE : " .. (selected.fuel or 100) .. "     NIVEAU REQUIS : " .. (selected.level or 1), "MGarage_Small", 0, S(60), C("Khaki"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local spawnBtn = vgui.Create("DButton", frame)
    spawnBtn:SetText("")
    spawnBtn:SetPos(rightX + rightW - S(230), fh - S(76))
    spawnBtn:SetSize(S(220), S(50))
    spawnBtn.Paint = function(self, w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
        local myLevel = MedalGarage.GetLevel(LocalPlayer())
        local ok = selected and myLevel >= (tonumber(selected.level) or 1)
        draw.RoundedBox(0, 0, 0, w, h, ok and Color(60, 74, 44, 230) or Color(40, 40, 40, 220))
        draw.RoundedBox(0, 0, 0, S(4), h, ok and C("Khaki") or C("Red"))
        surface.SetDrawColor(214, 220, 196, 60 + self.hoverAnim * 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local label = not selected and "SÉLECTIONNE UN VÉHICULE" or (ok and "SORTIR CE VÉHICULE" or ("NIVEAU " .. selected.level .. " REQUIS"))
        draw.SimpleText(label, "MGarage_Row", w / 2, h / 2, ok and C("White") or Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    spawnBtn.DoClick = function()
        if not selected then return end
        if MedalGarage.GetLevel(LocalPlayer()) < (tonumber(selected.level) or 1) then return end
        net.Start("MedalGarage_Spawn") net.WriteString(selected.name) net.SendToServer()
        frame:Remove()
    end

    -- ===== Liste des véhicules (gauche) =====
    list = vgui.Create("DScrollPanel", frame)
    list:SetPos(S(28), S(150))
    list:SetSize(leftW, fh - S(180))

    function list.Rebuild()
        list:Clear()
        local myLevel = MedalGarage.GetLevel(LocalPlayer())
        local first
        for _, veh in ipairs(cfg.Vehicles or {}) do
            if veh.category == activeCat then
                first = first or veh
                local unlocked = myLevel >= (tonumber(veh.level) or 1)
                local row = vgui.Create("DButton", list)
                row:Dock(TOP)
                row:DockMargin(0, 0, S(6), S(8))
                row:SetTall(S(72))
                row:SetText("")
                row.Paint = function(self, w, h)
                    self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
                    local sel = selected == veh
                    draw.RoundedBox(0, 0, 0, w, h, sel and Color(112, 126, 74, 70) or Color(16, 19, 14, 190 + self.hoverAnim * 45))
                    draw.RoundedBox(0, 0, 0, S(4), h, sel and C("Khaki") or (unlocked and C("Olive") or Color(80, 80, 80)))
                    surface.SetDrawColor(214, 220, 196, sel and 110 or (30 + self.hoverAnim * 60))
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    draw.SimpleText(veh.name, "MGarage_Row", S(16), S(12), unlocked and C("White") or Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText("ESSENCE " .. (veh.fuel or 100) .. "  •  NIV. " .. (veh.level or 1), "MGarage_Small", S(16), S(42), C("Khaki"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    if not unlocked then
                        draw.SimpleText("🔒 NIVEAU " .. veh.level, "MGarage_Small", w - S(14), h / 2, C("Red"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText("›", "MGarage_Title", w - S(16), h / 2, sel and C("Khaki") or Color(210, 214, 196, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                end
                row.DoClick = function() setPreview(veh) end
            end
        end
        -- Sélectionne le premier de la catégorie par défaut.
        if not selected or selected.category ~= activeCat then setPreview(first) end
    end
    list.Rebuild()

    local closeTop = vgui.Create("DButton", frame)
    closeTop:SetText("")
    closeTop:SetPos(fw - S(160), S(24))
    closeTop:SetSize(S(136), S(38))
    closeTop.Paint = function(self, w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
        draw.RoundedBox(0, 0, 0, w, h, Color(18, 21, 15, 200 + self.hoverAnim * 40))
        draw.RoundedBox(0, 0, 0, S(3), h, C("Red"))
        surface.SetDrawColor(214, 220, 196, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("FERMER", "MGarage_Row", w / 2, h / 2, C("White"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeTop.DoClick = function() frame:Remove() end

    frame.OnKeyCodePressed = function(self, key) if key == KEY_ESCAPE then self:Remove() end end
end

concommand.Add(cfg.Command or "medal_garage", MedalGarage.OpenMenu)

-- Ouverture depuis le PNJ vendeur.
net.Receive("MedalGarage_OpenFromNPC", function()
    MedalGarage.OpenMenu()
end)

if cfg.OpenKey then
    hook.Add("PlayerButtonDown", "MedalGarage_OpenKey", function(ply, key)
        if ply ~= LocalPlayer() then return end
        if key == cfg.OpenKey and not gui.IsGameUIVisible() and not IsValid(MedalGarage.Frame) then
            if not vgui.CursorVisible() then MedalGarage.OpenMenu() end
        end
    end)
end

-- =========================
-- Changement de siège + ravitaillement (touches)
-- =========================
hook.Add("PlayerButtonDown", "MedalGarage_SeatSwitch", function(ply, key)
    if ply ~= LocalPlayer() then return end
    local sc = cfg.Seats or {}
    if sc.Enabled ~= false and key == (sc.SwitchKey or KEY_R) and IsValid(ply:GetVehicle()) then
        net.Start("MedalGarage_SwitchSeat") net.SendToServer()
    end
end)

-- Ravitaillement : maintien de la touche près de son véhicule.
local refuelHeld = false
hook.Add("Think", "MedalGarage_RefuelThink", function()
    local fc = cfg.Fuel or {}
    if fc.Enabled == false then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or IsValid(ply:GetVehicle()) then return end
    if not input.IsKeyDown(fc.RefuelKey or KEY_G) then refuelHeld = false; return end

    -- Cherche le véhicule le plus proche devant/près.
    local tr = ply:GetEyeTrace()
    local veh = tr.Entity
    if not (IsValid(veh) and veh:IsVehicle()) then
        for _, e in ipairs(ents.FindInSphere(ply:GetPos(), 200)) do
            if e:IsVehicle() and e:GetNWFloat("MedalFuelMax", 0) > 0 then veh = e break end
        end
    end
    if not (IsValid(veh) and veh:IsVehicle() and veh:GetNWFloat("MedalFuelMax", 0) > 0) then return end
    if veh:GetPos():Distance(ply:GetPos()) > 240 then return end

    if (MedalGarage.NextRefuel or 0) < CurTime() then
        MedalGarage.NextRefuel = CurTime() + 0.5
        net.Start("MedalGarage_Refuel") net.WriteEntity(veh) net.SendToServer()
    end
end)

-- =========================
-- HUD véhicule façon HLL
-- =========================
local function drawBar(x, y, w, h, frac, col, bg)
    surface.SetDrawColor(bg or Color(10, 12, 9, 200))
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, w * math.Clamp(frac, 0, 1), h)
    surface.SetDrawColor(214, 220, 196, 60)
    surface.DrawOutlinedRect(x, y, w, h, 1)
end

-- Cadran circulaire façon Hell Let Loose (aiguille + graduations).
local function drawGauge(cx, cy, r, value, maxValue, label, unit)
    local segs = 48
    -- Fond du cadran.
    draw.NoTexture()
    surface.SetDrawColor(12, 14, 11, 210)
    local poly = {}
    for i = 0, segs do
        local a = math.rad((i / segs) * 360)
        poly[#poly + 1] = {x = cx + math.cos(a) * r, y = cy + math.sin(a) * r}
    end
    surface.DrawPoly(poly)
    surface.SetDrawColor(232, 234, 222, 235)
    -- Anneau.
    for i = 0, segs do
        local a1 = math.rad((i / segs) * 360)
        local a2 = math.rad(((i + 1) / segs) * 360)
        surface.DrawLine(cx + math.cos(a1) * r, cy + math.sin(a1) * r, cx + math.cos(a2) * r, cy + math.sin(a2) * r)
    end
    -- Graduations (cadran de 225° en bas comme un compteur auto).
    local startA, endA = 135, 135 + 270
    local ticks = 10
    for i = 0, ticks do
        local a = math.rad(startA + (endA - startA) * (i / ticks))
        local inner = r - (i % (ticks / 2) == 0 and S(14) or S(8))
        surface.SetDrawColor(232, 234, 222, i % 5 == 0 and 235 or 140)
        surface.DrawLine(cx + math.cos(a) * inner, cy + math.sin(a) * inner, cx + math.cos(a) * (r - S(3)), cy + math.sin(a) * (r - S(3)))
        if i % 2 == 0 then
            local lv = math.Round(maxValue * (i / ticks))
            draw.SimpleText(lv, "MGarage_HUDSmall", cx + math.cos(a) * (inner - S(12)), cy + math.sin(a) * (inner - S(12)), Color(232, 234, 222, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    -- Aiguille.
    local t = math.Clamp(value / math.max(maxValue, 1), 0, 1)
    local na = math.rad(startA + (endA - startA) * t)
    surface.SetDrawColor(210, 70, 55, 255)
    for off = -1, 1 do
        surface.DrawLine(cx + math.cos(na + math.rad(90)) * off, cy + math.sin(na + math.rad(90)) * off,
            cx + math.cos(na) * (r - S(16)), cy + math.sin(na) * (r - S(16)))
    end
    draw.NoTexture()
    surface.SetDrawColor(232, 234, 222, 255)
    local hub = {}
    for i = 0, 12 do local a = math.rad(i / 12 * 360); hub[#hub + 1] = {x = cx + math.cos(a) * S(5), y = cy + math.sin(a) * S(5)} end
    surface.DrawPoly(hub)
    -- Valeur numérique dans un cartouche (façon HLL).
    draw.RoundedBox(0, cx - S(24), cy + r * 0.38, S(48), S(20), Color(0, 0, 0, 200))
    draw.SimpleText(math.Round(value), "MGarage_HUD", cx, cy + r * 0.38 + S(10), Color(255, 210, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(unit, "MGarage_HUDSmall", cx, cy - r * 0.42, Color(232, 234, 222, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "MedalGarage_VehicleHUD", function()
    if (cfg.HUD or {}).Enabled == false then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local veh = ply:GetVehicle()
    if not IsValid(veh) then return end

    local phys = veh:GetPhysicsObject()
    local speed = IsValid(phys) and phys:GetVelocity():Length() or veh:GetVelocity():Length()
    local kmh = math.Round(speed * 0.06858)

    -- ===== Cadran de vitesse (bas droite, façon HLL) =====
    local gr = S(72)
    local gx = ScrW() - S(150)
    local gy = ScrH() - S(150)
    drawGauge(gx, gy, gr, kmh, 60, "VITESSE", "km/h")

    -- ===== Colonne de pastilles de sièges (à droite du cadran) =====
    local total = math.max(MedalGarage.SeatTotal, 1)
    local sx = ScrW() - S(60)
    local sy0 = gy - S(56)
    for i = 1, total do
        local col = i % 3
        local row = math.floor((i - 1) / 3)
        local dx = sx + col * S(24)
        local dy = sy0 + row * S(24)
        local occupied = i <= MedalGarage.SeatTotal
        local isMe = i == MedalGarage.SeatIdx
        draw.NoTexture()
        surface.SetDrawColor(isMe and 255 or 232, isMe and 210 or 234, isMe and 90 or 222, occupied and 235 or 90)
        local dot = {}
        for k = 0, 12 do local a = math.rad(k / 12 * 360); dot[#dot + 1] = {x = dx + math.cos(a) * S(7), y = dy + math.sin(a) * S(7)} end
        surface.DrawPoly(dot)
        surface.SetDrawColor(0, 0, 0, 200)
        local ring = {}
        for k = 0, 12 do local a = math.rad(k / 12 * 360); ring[#ring + 1] = {x = dx + math.cos(a) * S(3), y = dy + math.sin(a) * S(3)} end
        surface.DrawPoly(ring)
    end

    -- ===== Cartouche gauche : nom, siège, essence, vie =====
    local name = veh.MedalVehName or veh:GetNWString("MedalVehName", "VÉHICULE")
    if name == "" then name = "VÉHICULE" end
    local names = (cfg.Seats or {}).Names or {}
    local seatName = names[MedalGarage.SeatIdx] or ("SIÈGE " .. MedalGarage.SeatIdx)

    local bx, by = ScrW() - S(560), ScrH() - S(96)
    draw.SimpleText(string.upper(name) .. "  •  " .. seatName, "MGarage_HUDSmall", bx, by, C("Khaki"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local fuel = veh:GetNWFloat("MedalFuel", -1)
    local fuelMax = veh:GetNWFloat("MedalFuelMax", 0)
    if fuel >= 0 and fuelMax > 0 then
        local frac = fuel / fuelMax
        local col = frac > 0.25 and C("Khaki") or C("Red")
        draw.SimpleText("ESSENCE", "MGarage_HUDSmall", bx, by + S(22), Color(210, 214, 196, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        drawBar(bx + S(72), by + S(24), S(150), S(10), frac, col)
        draw.SimpleText(math.Round(fuel) .. "/" .. math.Round(fuelMax), "MGarage_HUDSmall", bx + S(230), by + S(22), col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    local hp, maxhp = veh:Health(), veh:GetMaxHealth()
    if hp and maxhp and maxhp > 0 then
        draw.SimpleText("BLINDAGE", "MGarage_HUDSmall", bx, by + S(40), Color(210, 214, 196, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        drawBar(bx + S(72), by + S(42), S(150), S(10), hp / maxhp, Color(160, 90, 70))
    end

    -- ===== Prompt moteur + changement de place (façon HLL) =====
    if MedalGarage.SeatTotal > 1 then
        draw.SimpleText("○ [" .. string.upper(input.GetKeyName((cfg.Seats or {}).SwitchKey or KEY_R) or "R") .. "] CHANGER DE PLACE", "MGarage_HUDSmall", ScrW() - S(30), ScrH() - S(30), Color(232, 234, 222, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    end
    if fuel and fuel <= 0 and fuelMax > 0 then
        draw.SimpleText("PANNE SÈCHE — RAVITAILLE AU GARAGE", "MGarage_HUD", ScrW() / 2, ScrH() - S(120), C("Red"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end
end)

-- Points de garage visibles pour le staff (aide au placement).
hook.Add("PostDrawTranslucentRenderables", "MedalGarage_PointsPreview", function(depth, sky)
    if sky then return end
    if not LocalPlayer():IsAdmin() then return end
    for _, p in ipairs(MedalGarage.StaffPoints or {}) do
        render.SetColorMaterial()
        render.DrawWireframeSphere(p, (cfg.GaragePointRadius or 600), 12, 10, Color(112, 126, 74, 60), true)
    end
end)
