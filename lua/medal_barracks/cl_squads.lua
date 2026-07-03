--[[
    Medal Barracks — Escouades façon Hell Let Loose (client).
    - Menu des escouades de la faction (touche K par défaut, ou via le menu E).
    - HUD bas-gauche : nom de l'escouade + membres, comme sur HLL.
    - Invitations d'escouade envoyées par le chef via le menu E.
]]

if SERVER then return end

MedalBarracks = MedalBarracks or {}
local cfg = MedalBarracks.Config or {}

local function squadCfg()
    return cfg.Squads or {}
end

local function S(v)
    return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080))
end

surface.CreateFont("MedalSquad_Title", {font = "Roboto Condensed", size = 30, weight = 1000, extended = true})
surface.CreateFont("MedalSquad_Name", {font = "Roboto Condensed", size = 22, weight = 950, extended = true})
surface.CreateFont("MedalSquad_Row", {font = "Roboto Condensed", size = 17, weight = 700, extended = true})
surface.CreateFont("MedalSquad_Small", {font = "Roboto Condensed", size = 13, weight = 800, extended = true})
surface.CreateFont("MedalSquad_HUDName", {font = "Roboto Condensed", size = 20, weight = 950, extended = true})
surface.CreateFont("MedalSquad_HUDRow", {font = "Roboto Condensed", size = 16, weight = 700, extended = true})

local COL_OLIVE = Color(112, 126, 74)
local COL_KHAKI = Color(148, 156, 108)
local COL_WHITE = Color(232, 234, 222)
local COL_RED = Color(165, 48, 40)

-- Escouades synchronisées : {armyID = "...", list = {{name, members = {{sid, nick, leader, role}}}}}
MedalBarracks.ClientSquads = MedalBarracks.ClientSquads or {armyID = "", list = {}}

local function mySID()
    return IsValid(LocalPlayer()) and LocalPlayer():SteamID64() or ""
end

local function myArmy()
    return IsValid(LocalPlayer()) and LocalPlayer():GetNWString("MedalBarracks_ArmyChoice", "") or ""
end

local function mySquad()
    for _, squad in ipairs(MedalBarracks.ClientSquads.list or {}) do
        for _, m in ipairs(squad.members or {}) do
            if m.sid == mySID() then return squad, m end
        end
    end
end

local function squadAction(action, arg)
    net.Start("MedalSquads_Action")
        net.WriteString(action)
        net.WriteString(tostring(arg or ""))
    net.SendToServer()
end

MedalBarracks.SquadAction = squadAction

net.Receive("MedalSquads_Sync", function()
    local armyID = net.ReadString()
    local count = net.ReadUInt(8)
    local list = {}
    for i = 1, count do
        local squad = {name = net.ReadString(), members = {}}
        local mcount = net.ReadUInt(4)
        for j = 1, mcount do
            squad.members[j] = {
                sid = net.ReadString(),
                nick = net.ReadString(),
                leader = net.ReadBool(),
                role = net.ReadString(),
            }
        end
        list[i] = squad
    end
    if armyID == myArmy() or myArmy() == "" then
        MedalBarracks.ClientSquads = {armyID = armyID, list = list}
    end
    if IsValid(MedalBarracks.SquadFrame) and MedalBarracks.SquadFrame.Rebuild then MedalBarracks.SquadFrame:Rebuild() end
end)

-- =========================
-- Menu des escouades
-- =========================
function MedalBarracks.OpenSquadMenu()
    if squadCfg().Enabled == false then return end
    if IsValid(MedalBarracks.SquadFrame) then MedalBarracks.SquadFrame:Remove(); return end
    squadAction("request")

    local frame = vgui.Create("DFrame")
    MedalBarracks.SquadFrame = frame
    local fw, fh = S(680), S(720)
    frame:SetSize(fw, fh)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.12, 0)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 9, 240))
        draw.RoundedBox(0, 0, 0, S(5), h, COL_OLIVE)
        surface.SetDrawColor(214, 220, 196, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("ESCOUADES", "MedalSquad_Title", S(30), S(24), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local squad = mySquad()
        local info = squad and ("TON ESCOUADE : " .. squad.name) or "TU N'ES DANS AUCUNE ESCOUADE"
        draw.SimpleText(info, "MedalSquad_Small", S(31), S(58), Color(232, 234, 222, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(112, 126, 74, 200)
        surface.DrawRect(S(30), S(80), S(56), S(3))
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(S(30), S(100))
    scroll:SetSize(fw - S(60), fh - S(190))

    local function styledButton(parent, label, accent, onClick)
        local b = vgui.Create("DButton", parent)
        b:SetText("")
        b.Paint = function(self, w, h)
            self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
            draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 180 + self.hoverAnim * 55))
            draw.RoundedBox(0, 0, 0, S(3), h, accent)
            surface.SetDrawColor(214, 220, 196, 30 + self.hoverAnim * 80)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(label, "MedalSquad_Small", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = onClick
        return b
    end

    local function rebuild()
        if not IsValid(scroll) then return end
        scroll:Clear()
        local maxMembers = tonumber(squadCfg().MaxMembers) or 6
        local current, currentMember = mySquad()
        local amLeader = currentMember and currentMember.leader or false

        for _, squad in ipairs(MedalBarracks.ClientSquads.list or {}) do
            local memberCount = #(squad.members or {})
            local pnl = vgui.Create("DPanel", scroll)
            pnl:Dock(TOP)
            pnl:DockMargin(0, 0, 0, S(10))
            pnl:SetTall(S(52) + memberCount * S(30))
            local isMine = current and current.name == squad.name

            pnl.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 200))
                draw.RoundedBox(0, 0, 0, S(4), h, isMine and COL_KHAKI or COL_OLIVE)
                surface.SetDrawColor(214, 220, 196, isMine and 90 or 35)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText("ESCOUADE " .. squad.name, "MedalSquad_Name", S(18), S(12), isMine and COL_KHAKI or COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(memberCount .. " / " .. maxMembers, "MedalSquad_Row", w - S(120), S(15), Color(232, 234, 222, 170), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

                for i, m in ipairs(squad.members or {}) do
                    local y = S(46) + (i - 1) * S(30)
                    surface.SetDrawColor(214, 220, 196, 18)
                    surface.DrawRect(S(18), y - S(3), w - S(36), 1)
                    local icon = m.leader and (squadCfg().LeaderIcon or "★") or "•"
                    draw.SimpleText(icon, "MedalSquad_Row", S(28), y + S(10), m.leader and COL_KHAKI or Color(232, 234, 222, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(m.nick, "MedalSquad_Row", S(48), y + S(10), m.sid == mySID() and COL_KHAKI or COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    if m.role ~= "" then
                        draw.SimpleText(string.upper(m.role), "MedalSquad_Small", w - S(120), y + S(10), Color(232, 234, 222, 120), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                end
            end

            if not isMine and memberCount < maxMembers then
                local join = styledButton(pnl, "REJOINDRE", COL_OLIVE, function() squadAction("join", squad.name) end)
                pnl.PerformLayout = function(self, w, h)
                    join:SetSize(S(100), S(26))
                    join:SetPos(w - S(230), S(12))
                end
            elseif isMine and amLeader then
                -- Boutons d'exclusion pour le chef d'escouade, alignés sur chaque ligne membre.
                local kicks = {}
                for i, m in ipairs(squad.members or {}) do
                    if m.sid ~= mySID() then
                        table.insert(kicks, {btn = styledButton(pnl, "EXCLURE", COL_RED, function() squadAction("kick", m.sid) end), idx = i})
                    end
                end
                pnl.PerformLayout = function(self, w, h)
                    for _, k in ipairs(kicks) do
                        k.btn:SetSize(S(84), S(22))
                        k.btn:SetPos(w - S(230), S(40) + (k.idx - 1) * S(30))
                    end
                end
            end
        end
    end
    frame.Rebuild = rebuild
    rebuild()

    local create = vgui.Create("DButton", frame)
    create:SetText("")
    create:SetPos(S(30), fh - S(76))
    create:SetSize(S(250), S(46))
    create.Paint = function(self, w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
        draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 180 + self.hoverAnim * 55))
        draw.RoundedBox(0, 0, 0, S(4), h, COL_KHAKI)
        surface.SetDrawColor(214, 220, 196, 35 + self.hoverAnim * 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("CRÉER UNE ESCOUADE", "MedalSquad_Row", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    create.DoClick = function() squadAction("create") end

    local leave = vgui.Create("DButton", frame)
    leave:SetText("")
    leave:SetPos(S(296), fh - S(76))
    leave:SetSize(S(180), S(46))
    leave.Paint = function(self, w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
        draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 180 + self.hoverAnim * 55))
        draw.RoundedBox(0, 0, 0, S(4), h, COL_RED)
        surface.SetDrawColor(214, 220, 196, 35 + self.hoverAnim * 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("QUITTER", "MedalSquad_Row", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    leave.DoClick = function() squadAction("leave") end

    local close = vgui.Create("DButton", frame)
    close:SetText("")
    close:SetPos(fw - S(30) - S(160), fh - S(76))
    close:SetSize(S(160), S(46))
    close.Paint = function(self, w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
        draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 180 + self.hoverAnim * 55))
        draw.RoundedBox(0, 0, 0, S(4), h, Color(110, 110, 110))
        surface.SetDrawColor(214, 220, 196, 35 + self.hoverAnim * 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("FERMER", "MedalSquad_Row", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close.DoClick = function() frame:Remove() end

    frame.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then self:Remove() end
    end
end

concommand.Add("medal_squads", function() MedalBarracks.OpenSquadMenu() end)

-- =========================
-- Invitation reçue
-- =========================
net.Receive("MedalSquads_Invite", function()
    local squadName = net.ReadString()
    local fromNick = net.ReadString()

    if IsValid(MedalBarracks.SquadInvite) then MedalBarracks.SquadInvite:Remove() end
    local p = vgui.Create("DPanel")
    MedalBarracks.SquadInvite = p
    local pw, ph = S(380), S(112)
    p:SetSize(pw, ph)
    p:SetPos(ScrW() - pw - S(28), S(220))
    p:MakePopup()
    p:SetKeyboardInputEnabled(false)
    p.die = SysTime() + 15

    p.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 9, 235))
        draw.RoundedBox(0, 0, 0, S(4), h, COL_KHAKI)
        surface.SetDrawColor(214, 220, 196, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("INVITATION D'ESCOUADE", "MedalSquad_Small", S(16), S(10), COL_KHAKI, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(fromNick .. " t'invite dans l'escouade " .. squadName .. ".", "MedalSquad_Row", S(16), S(30), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local remain = math.max(0, self.die - SysTime())
        surface.SetDrawColor(148, 156, 108, 140)
        surface.DrawRect(0, h - S(3), w * (remain / 15), S(3))
    end
    p.Think = function(self)
        if SysTime() > self.die then self:Remove() end
    end

    local accept = vgui.Create("DButton", p)
    accept:SetText("")
    accept:SetPos(S(16), ph - S(46))
    accept:SetSize(S(150), S(32))
    accept.Paint = function(self, w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
        draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 190 + self.hoverAnim * 50))
        draw.RoundedBox(0, 0, 0, S(3), h, COL_OLIVE)
        draw.SimpleText("ACCEPTER", "MedalSquad_Small", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    accept.DoClick = function()
        squadAction("join", squadName)
        p:Remove()
    end

    local decline = vgui.Create("DButton", p)
    decline:SetText("")
    decline:SetPos(S(180), ph - S(46))
    decline:SetSize(S(150), S(32))
    decline.Paint = function(self, w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
        draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 190 + self.hoverAnim * 50))
        draw.RoundedBox(0, 0, 0, S(3), h, COL_RED)
        draw.SimpleText("REFUSER", "MedalSquad_Small", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    decline.DoClick = function() p:Remove() end
end)

-- =========================
-- HUD escouade bas-gauche façon HLL
-- =========================
hook.Add("HUDPaint", "MedalSquads_HUD", function()
    local sc = squadCfg()
    if sc.Enabled == false or (sc.HUD or {}).Enabled == false then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:GetNWBool("MedalBarracks_InMenu", false) then return end

    local squad = mySquad()
    if not squad then return end

    local x = S(tonumber((sc.HUD or {}).X) or 26)
    local rowH = S(22)
    local totalH = S(30) + #(squad.members or {}) * rowH
    local y = ScrH() - S(tonumber((sc.HUD or {}).BottomMargin) or 40) - totalH

    -- Nom de l'escouade, petite ligne olive, membres en dessous — comme HLL.
    draw.SimpleText(squad.name, "MedalSquad_HUDName", x, y, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    surface.SetDrawColor(112, 126, 74, 210)
    surface.DrawRect(x, y + S(24), S(120), S(2))

    for i, m in ipairs(squad.members or {}) do
        local ry = y + S(32) + (i - 1) * rowH
        local icon = m.leader and (sc.LeaderIcon or "★") or "•"
        local isMe = m.sid == mySID()
        draw.SimpleText(icon, "MedalSquad_HUDRow", x + S(6), ry + rowH / 2, m.leader and COL_KHAKI or Color(232, 234, 222, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(m.nick, "MedalSquad_HUDRow", x + S(20), ry + rowH / 2, isMe and COL_KHAKI or Color(232, 234, 222, 215), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end)

hook.Add("InitPostEntity", "MedalSquads_InitialSync", function()
    timer.Simple(3, function() squadAction("request") end)
end)
