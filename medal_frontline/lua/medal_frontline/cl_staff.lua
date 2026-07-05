--[[
    Medal Frontline — Panneau staff (client), éditeur façon MG CTF.
    Trois onglets :
      OPÉRATION  : mode (Warfare/Offensive/Escarmouche), camp attaquant,
                   lancer / arrêter / réinitialiser, joueurs actifs.
      SECTEURS   : liste éditable — nom (champ), rayon (slider), DÉFINIR ICI,
                   téléportation, suppression. Sauvegarde auto par map.
      RÉCOMPENSES: XP + argent DarkRP versés à la capture d'un secteur.
]]

if SERVER then return end

MedalFrontline = MedalFrontline or {}
local cfg = MedalFrontline.Config or {}

local function S(v)
    return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080))
end

surface.CreateFont("MFrontStaff_Title", {font = "Roboto Condensed", size = 30, weight = 1000, extended = true})
surface.CreateFont("MFrontStaff_Tab", {font = "Roboto Condensed", size = 18, weight = 900, extended = true})
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

local function styledButton(parent, label, accent, onClick, selectedFn)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Paint = function(self, w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
        local sel = selectedFn and selectedFn() or false
        draw.RoundedBox(0, 0, 0, w, h, sel and Color(accent.r, accent.g, accent.b, 60) or Color(16, 19, 14, 185 + self.hoverAnim * 50))
        draw.RoundedBox(0, 0, 0, S(3), h, sel and accent or Color(60, 66, 52, 200))
        surface.SetDrawColor(214, 220, 196, sel and 120 or (28 + self.hoverAnim * 70))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(isfunction(label) and label() or label, "MFrontStaff_Row", w / 2, h / 2, sel and COL_KHAKI or COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = onClick
    return b
end

function MedalFrontline.OpenStaffMenu()
    if IsValid(MedalFrontline.StaffFrame) then MedalFrontline.StaffFrame:Remove(); return end
    staffAction("noop") -- force un sync frais

    local frame = vgui.Create("DFrame")
    MedalFrontline.StaffFrame = frame
    local fw, fh = S(860), S(840)
    frame:SetSize(fw, fh)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.12, 0)

    local activeTab = "operation"
    local content

    frame.Paint = function(self, w, h)
        local state = MedalFrontline.State or {}
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 9, 246))
        draw.RoundedBox(0, 0, 0, S(5), h, COL_OLIVE)
        surface.SetDrawColor(214, 220, 196, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        draw.SimpleText("MEDAL FRONTLINE — ÉDITEUR", "MFrontStaff_Title", S(28), S(20), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local modeName = ((cfg.Modes or {})[state.mode or ""] or {}).name or "?"
        local status = state.active and ("OPÉRATION EN COURS — " .. modeName) or ("EN ATTENTE — mode " .. modeName)
        draw.SimpleText(status, "MFrontStaff_Small", S(29), S(56), state.active and COL_KHAKI or Color(232, 234, 222, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local c1 = GetGlobalInt("MedalFrontline_Active_" .. FAC1, 0)
        local c2 = GetGlobalInt("MedalFrontline_Active_" .. FAC2, 0)
        draw.SimpleText("ACTIFS : " .. facName(FAC1) .. " " .. c1 .. "  •  " .. facName(FAC2) .. " " .. c2, "MFrontStaff_Small", w - S(28), S(56), Color(232, 234, 222, 165), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(112, 126, 74, 200)
        surface.DrawRect(S(28), S(78), S(56), S(3))
    end

    -- ===== Onglets =====
    local tabs = {
        {id = "operation", label = "OPÉRATION"},
        {id = "zones", label = "SECTEURS"},
        {id = "rewards", label = "RÉCOMPENSES"},
    }
    local tabX = S(28)
    for _, tab in ipairs(tabs) do
        local b = styledButton(frame, tab.label, COL_KHAKI, function()
            activeTab = tab.id
            frame.Rebuild()
        end, function() return activeTab == tab.id end)
        surface.SetFont("MFrontStaff_Tab")
        local tw = surface.GetTextSize(tab.label) + S(44)
        b:SetPos(tabX, S(94))
        b:SetSize(tw, S(38))
        tabX = tabX + tw + S(8)
    end

    content = vgui.Create("DScrollPanel", frame)
    content:SetPos(S(28), S(146))
    content:SetSize(fw - S(56), fh - S(216))

    -- ===== Contenus d'onglets =====
    local function buildOperation()
        local state = MedalFrontline.State or {}
        for _, modeID in ipairs({"warfare", "offensive", "skirmish"}) do
            local mode = (cfg.Modes or {})[modeID] or {}
            local row = vgui.Create("DButton", content)
            row:Dock(TOP)
            row:DockMargin(0, 0, S(6), S(8))
            row:SetTall(S(64))
            row:SetText("")
            row.Paint = function(self, w, h)
                self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
                local sel = (MedalFrontline.State or {}).mode == modeID
                draw.RoundedBox(0, 0, 0, w, h, sel and Color(112, 126, 74, 55) or Color(16, 19, 14, 185 + self.hoverAnim * 50))
                draw.RoundedBox(0, 0, 0, S(4), h, sel and COL_KHAKI or COL_OLIVE)
                surface.SetDrawColor(214, 220, 196, sel and 120 or 28)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText(tostring(mode.name or modeID), "MFrontStaff_Row", S(16), S(9), sel and COL_KHAKI or COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(tostring(mode.desc or ""), "MFrontStaff_Small", S(16), S(32), Color(232, 234, 222, 140), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                if sel then draw.SimpleText("MODE ACTUEL", "MFrontStaff_Small", w - S(14), S(10), COL_KHAKI, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP) end
            end
            row.DoClick = function() staffAction("mode", modeID) end
        end

        -- Camp attaquant.
        local atk = vgui.Create("DPanel", content)
        atk:Dock(TOP)
        atk:DockMargin(0, S(6), S(6), S(8))
        atk:SetTall(S(66))
        atk.Paint = function(self, w, h)
            draw.SimpleText("CAMP ATTAQUANT (MODE OFFENSIVE)", "MFrontStaff_Small", 0, 0, Color(232, 234, 222, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        local half = math.floor((fw - S(56) - S(18)) / 2)
        local b1 = styledButton(atk, facName(FAC1), (cfg.FactionColors or {})[FAC1] or COL_KHAKI, function() staffAction("attacker", FAC1) end, function() return (MedalFrontline.State or {}).attacker == FAC1 end)
        b1:SetPos(0, S(20)); b1:SetSize(half, S(40))
        local b2 = styledButton(atk, facName(FAC2), (cfg.FactionColors or {})[FAC2] or COL_RED, function() staffAction("attacker", FAC2) end, function() return (MedalFrontline.State or {}).attacker == FAC2 end)
        b2:SetPos(half + S(12), S(20)); b2:SetSize(half, S(40))

        -- Contrôles.
        local ctl = vgui.Create("DPanel", content)
        ctl:Dock(TOP)
        ctl:DockMargin(0, S(6), S(6), S(8))
        ctl:SetTall(S(50))
        ctl.Paint = function() end
        local bStart = styledButton(ctl, "LANCER L'OPÉRATION", COL_KHAKI, function() staffAction("start") end)
        bStart:SetPos(0, 0); bStart:SetSize(S(240), S(44))
        local bStop = styledButton(ctl, "ARRÊTER", COL_RED, function() staffAction("stop") end)
        bStop:SetPos(S(252), 0); bStop:SetSize(S(150), S(44))
        local bReset = styledButton(ctl, "RÉINITIALISER", Color(120, 120, 120), function() staffAction("reset") end)
        bReset:SetPos(S(414), 0); bReset:SetSize(S(180), S(44))
    end

    local function buildZones()
        local zones = (MedalFrontline.State or {}).zones or {}
        local total = math.max(#zones, 1)
        for i = 1, total do
            local z = zones[i]
            local row = vgui.Create("DPanel", content)
            row:Dock(TOP)
            row:DockMargin(0, 0, S(6), S(8))
            row:SetTall(S(96))
            row.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 195))
                draw.RoundedBox(0, 0, 0, S(4), h, z and COL_OLIVE or Color(60, 66, 52, 200))
                surface.SetDrawColor(214, 220, 196, 28)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText("#" .. i, "MFrontStaff_Title", S(16), h / 2, z and COL_KHAKI or Color(120, 120, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if z then
                    draw.SimpleText(string.format("x %d  y %d", z.pos.x, z.pos.y), "MFrontStaff_Small", S(64), S(66), Color(232, 234, 222, 110), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                else
                    draw.SimpleText("NON DÉFINI — place-toi et clique DÉFINIR ICI", "MFrontStaff_Small", S(64), h / 2, Color(232, 234, 222, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end

            if z then
                -- Nom (champ éditable façon MG CTF).
                local nameEntry = vgui.Create("DTextEntry", row)
                nameEntry:SetPos(S(64), S(10))
                nameEntry:SetSize(S(220), S(28))
                nameEntry:SetText(z.name or "")
                nameEntry.OnEnter = function(self)
                    staffAction("renameidx", i .. "|" .. (self:GetValue() or ""))
                end

                -- Rayon (slider).
                local slider = vgui.Create("DNumSlider", row)
                slider:SetPos(S(300), S(6))
                slider:SetSize(S(300), S(34))
                slider:SetText("Rayon")
                slider:SetMin(150)
                slider:SetMax(4000)
                slider:SetDecimals(0)
                slider:SetValue(z.radius or 900)
                slider.OnValueChanged = function(self, val)
                    self.pending = math.Round(val)
                end
                slider.Think = function(self)
                    -- N'envoie qu'au relâchement (anti-spam réseau).
                    if self.pending and not input.IsMouseDown(MOUSE_LEFT) then
                        staffAction("radiusidx", i .. "|" .. self.pending)
                        self.pending = nil
                    end
                end

                local tp = styledButton(row, "TP", COL_KHAKI, function() staffAction("goto", i) end)
                tp:SetPos(S(64), S(42)); tp:SetSize(S(60), S(24))
                local here = styledButton(row, "DÉFINIR ICI", COL_OLIVE, function() staffAction("setzone", i) end)
                here:SetPos(S(132), S(42)); here:SetSize(S(120), S(24))
                local del = styledButton(row, "SUPPRIMER", COL_RED, function() staffAction("removezone", i) end)
                del:SetPos(S(260), S(42)); del:SetSize(S(110), S(24))
            else
                local here = styledButton(row, "DÉFINIR ICI", COL_OLIVE, function() staffAction("setzone", i) end)
                here:SetPos(S(64), S(10)); here:SetSize(S(140), S(28))
            end
        end

        -- Bouton ajouter un secteur.
        local addRow = vgui.Create("DPanel", content)
        addRow:Dock(TOP)
        addRow:DockMargin(0, S(4), S(6), S(8))
        addRow:SetTall(S(44))
        addRow.Paint = function() end
        local add = styledButton(addRow, "+ AJOUTER UN SECTEUR À MA POSITION", COL_KHAKI, function()
            staffAction("setzone", #zones + 1)
        end)
        add:SetPos(0, 0); add:SetSize(S(360), S(40))
    end

    local function buildRewards()
        local state = MedalFrontline.State or {}
        local info = vgui.Create("DPanel", content)
        info:Dock(TOP)
        info:DockMargin(0, 0, S(6), S(10))
        info:SetTall(S(46))
        info.Paint = function(self, w, h)
            draw.SimpleText("Récompenses versées aux joueurs du camp présent dans le secteur au moment de la capture.", "MFrontStaff_Small", 0, S(4), Color(232, 234, 222, 160), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("XP = XP générale medal_barracks  •  ARGENT = DarkRP (ignoré si non installé)", "MFrontStaff_Small", 0, S(22), Color(232, 234, 222, 110), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local xpRow = vgui.Create("DPanel", content)
        xpRow:Dock(TOP)
        xpRow:DockMargin(0, 0, S(6), S(8))
        xpRow:SetTall(S(50))
        xpRow.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 195))
            draw.RoundedBox(0, 0, 0, S(4), h, COL_OLIVE)
            draw.SimpleText("XP PAR CAPTURE", "MFrontStaff_Row", S(16), h / 2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local xpEntry = vgui.Create("DTextEntry", xpRow)
        xpEntry:SetPos(S(240), S(11))
        xpEntry:SetSize(S(120), S(28))
        xpEntry:SetNumeric(true)
        xpEntry:SetText(tostring(state.captureXP or 50))

        local moneyRow = vgui.Create("DPanel", content)
        moneyRow:Dock(TOP)
        moneyRow:DockMargin(0, 0, S(6), S(8))
        moneyRow:SetTall(S(50))
        moneyRow.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 195))
            draw.RoundedBox(0, 0, 0, S(4), h, COL_KHAKI)
            draw.SimpleText("ARGENT PAR CAPTURE ($)", "MFrontStaff_Row", S(16), h / 2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local moneyEntry = vgui.Create("DTextEntry", moneyRow)
        moneyEntry:SetPos(S(240), S(11))
        moneyEntry:SetSize(S(120), S(28))
        moneyEntry:SetNumeric(true)
        moneyEntry:SetText(tostring(state.captureMoney or 150))

        local saveRow = vgui.Create("DPanel", content)
        saveRow:Dock(TOP)
        saveRow:DockMargin(0, S(4), S(6), S(8))
        saveRow:SetTall(S(46))
        saveRow.Paint = function() end
        local save = styledButton(saveRow, "SAUVEGARDER LES RÉCOMPENSES", COL_KHAKI, function()
            staffAction("rewards", (tonumber(xpEntry:GetValue()) or 0) .. "|" .. (tonumber(moneyEntry:GetValue()) or 0))
        end)
        save:SetPos(0, 0); save:SetSize(S(320), S(42))
    end

    function frame.Rebuild()
        if not IsValid(content) then return end
        content:Clear()
        if activeTab == "operation" then buildOperation()
        elseif activeTab == "zones" then buildZones()
        else buildRewards() end
    end
    frame.Rebuild()

    local close = styledButton(frame, "FERMER", Color(110, 110, 110), function() frame:Remove() end)
    close:SetPos(fw - S(28) - S(150), fh - S(58))
    close:SetSize(S(150), S(42))

    frame.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then self:Remove() end
    end
end

concommand.Add(tostring(cfg.StaffCommand or "medal_frontline_staff"), function()
    MedalFrontline.OpenStaffMenu()
end)
