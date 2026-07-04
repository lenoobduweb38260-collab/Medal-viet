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
    local fw, fh = S(1080), S(720)
    frame:SetSize(fw, fh)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.12, 0)

    local activeCat = (cfg.Categories or {"BLINDÉS"})[1]
    local list

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, C("Panel"))
        draw.RoundedBox(0, 0, 0, S(5), h, C("Olive"))
        surface.SetDrawColor(214, 220, 196, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("GARAGE — PARC DE VÉHICULES", "MGarage_Title", S(30), S(24), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("NIVEAU ACTUEL : " .. MedalGarage.GetLevel(LocalPlayer()), "MGarage_Small", S(31), S(64), C("Khaki"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(112, 126, 74, 200)
        surface.DrawRect(S(30), S(86), S(56), S(3))
    end

    -- Onglets de catégorie.
    local tabY = S(104)
    local tabX = S(30)
    for _, catName in ipairs(cfg.Categories or {}) do
        local b = vgui.Create("DButton", frame)
        b:SetText("")
        surface.SetFont("MGarage_Tab")
        local tw = surface.GetTextSize(catName) + S(36)
        b:SetPos(tabX, tabY)
        b:SetSize(tw, S(40))
        b.Paint = function(self, w, h)
            local sel = activeCat == catName
            draw.RoundedBox(0, 0, 0, w, h, sel and Color(112, 126, 74, 80) or Color(18, 21, 15, 190))
            draw.RoundedBox(0, 0, 0, S(3), h, sel and C("Khaki") or C("Olive"))
            surface.SetDrawColor(214, 220, 196, sel and 120 or 40)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(catName, "MGarage_Tab", w / 2, h / 2, sel and C("White") or Color(210, 214, 196), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function() activeCat = catName; if list and list.Rebuild then list:Rebuild() end end
        tabX = tabX + tw + S(8)
    end

    list = vgui.Create("DScrollPanel", frame)
    list:SetPos(S(30), S(156))
    list:SetSize(fw - S(60), fh - S(240))

    function list.Rebuild()
        list:Clear()
        local myLevel = MedalGarage.GetLevel(LocalPlayer())
        for _, veh in ipairs(cfg.Vehicles or {}) do
            if veh.category == activeCat then
                local unlocked = myLevel >= (tonumber(veh.level) or 1)
                local row = vgui.Create("DButton", list)
                row:Dock(TOP)
                row:DockMargin(0, 0, 0, S(10))
                row:SetTall(S(84))
                row:SetText("")
                row.Paint = function(self, w, h)
                    self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, (self:IsHovered() and unlocked) and 1 or 0)
                    draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 190 + self.hoverAnim * 50))
                    draw.RoundedBox(0, 0, 0, S(4), h, unlocked and C("Olive") or Color(80, 80, 80))
                    surface.SetDrawColor(214, 220, 196, unlocked and (35 + self.hoverAnim * 70) or 25)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    draw.SimpleText(veh.name, "MGarage_Row", S(20), S(14), unlocked and C("White") or Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText(veh.desc or "", "MGarage_Small", S(20), S(44), Color(210, 214, 196, unlocked and 180 or 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText("ESSENCE " .. (veh.fuel or 100), "MGarage_Small", S(20), S(62), C("Khaki"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    if unlocked then
                        draw.SimpleText("SORTIR ›", "MGarage_Row", w - S(20), h / 2, C("Khaki"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText("NIVEAU " .. veh.level, "MGarage_Row", w - S(20), h / 2, C("Red"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        draw.SimpleText("🔒", "MGarage_Row", w - S(20), S(16), Color(200, 200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                    end
                end
                row.DoClick = function()
                    if not unlocked then return end
                    net.Start("MedalGarage_Spawn") net.WriteString(veh.name) net.SendToServer()
                    frame:Remove()
                end
            end
        end
    end
    list.Rebuild()

    local close = vgui.Create("DButton", frame)
    close:SetText("")
    close:SetPos(fw - S(30) - S(160), fh - S(74))
    close:SetSize(S(160), S(46))
    close.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 200))
        draw.RoundedBox(0, 0, 0, S(4), h, Color(110, 110, 110))
        draw.SimpleText("FERMER", "MGarage_Row", w / 2, h / 2, C("White"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close.DoClick = function() frame:Remove() end

    frame.OnKeyCodePressed = function(self, key) if key == KEY_ESCAPE then self:Remove() end end
end

concommand.Add(cfg.Command or "medal_garage", MedalGarage.OpenMenu)

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

hook.Add("HUDPaint", "MedalGarage_VehicleHUD", function()
    if (cfg.HUD or {}).Enabled == false then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local veh = ply:GetVehicle()
    if not IsValid(veh) then return end

    local w, h = S(420), S(120)
    local x = ScrW() / 2 - w / 2
    local y = ScrH() - h - S(30)

    -- Panneau HLL.
    draw.RoundedBox(0, x, y, w, h, Color(8, 10, 8, 200))
    draw.RoundedBox(0, x, y, S(4), h, C("Olive"))
    surface.SetDrawColor(214, 220, 196, 55)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    local name = veh.MedalVehName or veh:GetNWString("MedalVehName", "")
    if name == "" then name = "VÉHICULE" end
    draw.SimpleText(string.upper(name), "MGarage_HUD", x + S(18), y + S(12), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Siège actuel façon HLL.
    local names = (cfg.Seats or {}).Names or {}
    local seatName = names[MedalGarage.SeatIdx] or ("SIÈGE " .. MedalGarage.SeatIdx)
    draw.SimpleText(seatName .. "  (" .. MedalGarage.SeatIdx .. "/" .. MedalGarage.SeatTotal .. ")", "MGarage_HUDSmall", x + w - S(18), y + S(16), C("Khaki"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    if MedalGarage.SeatTotal > 1 then
        draw.SimpleText("[" .. string.upper(input.GetKeyName((cfg.Seats or {}).SwitchKey or KEY_R) or "R") .. "] CHANGER DE PLACE", "MGarage_HUDSmall", x + w - S(18), y + S(34), Color(210, 214, 196, 160), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    -- Vitesse.
    local phys = veh:GetPhysicsObject()
    local speed = IsValid(phys) and phys:GetVelocity():Length() or veh:GetVelocity():Length()
    local kmh = math.Round(speed * 0.06858)
    draw.SimpleText(kmh .. " KM/H", "MGarage_HUDBig", x + S(18), y + S(40), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Essence.
    local fuel = veh:GetNWFloat("MedalFuel", -1)
    local fuelMax = veh:GetNWFloat("MedalFuelMax", 0)
    if fuel >= 0 and fuelMax > 0 then
        local frac = fuel / fuelMax
        local col = frac > 0.25 and C("Khaki") or C("Red")
        draw.SimpleText("ESSENCE", "MGarage_HUDSmall", x + S(18), y + h - S(34), Color(210, 214, 196, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        drawBar(x + S(90), y + h - S(32), S(150), S(12), frac, col)
        draw.SimpleText(math.Round(fuel) .. " / " .. math.Round(fuelMax), "MGarage_HUDSmall", x + S(250), y + h - S(34), col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        if fuel <= 0 then
            draw.SimpleText("PANNE SÈCHE", "MGarage_HUDSmall", x + w - S(18), y + h - S(34), C("Red"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
    end

    -- Vie du véhicule (si dispo).
    local hp = veh:Health()
    local maxhp = veh:GetMaxHealth()
    if hp and maxhp and maxhp > 0 then
        drawBar(x + w - S(160), y + S(40), S(140), S(10), hp / maxhp, Color(160, 90, 70))
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
