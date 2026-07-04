--[[
    Medal Barracks — Gestionnaire de musiques STAFF (client).
    Menu HLL : liste des musiques du dossier Dropbox (mise à jour automatique),
    lecture pour tout le serveur, arrêt, volume, actualisation manuelle.
    Les joueurs reçoivent la musique via sound.PlayURL + petit toast HUD.
]]

if SERVER then return end

MedalBarracks = MedalBarracks or {}
local cfg = MedalBarracks.Config or {}

local function musicCfg()
    return cfg.Music or {}
end

local function S(v)
    return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080))
end

surface.CreateFont("MedalMusic_Title", {font = "Roboto Condensed", size = 30, weight = 1000, extended = true})
surface.CreateFont("MedalMusic_Row", {font = "Roboto Condensed", size = 17, weight = 700, extended = true})
surface.CreateFont("MedalMusic_Small", {font = "Roboto Condensed", size = 13, weight = 800, extended = true})

local COL_OLIVE = Color(112, 126, 74)
local COL_KHAKI = Color(148, 156, 108)
local COL_WHITE = Color(232, 234, 222)
local COL_RED = Color(165, 48, 40)

local musicList = {}
local nowPlaying = ""
local musicChannel = nil

-- =========================
-- Lecture côté joueur
-- =========================
local function stopLocalMusic()
    if musicChannel and musicChannel.Stop then pcall(function() musicChannel:Stop() end) end
    musicChannel = nil
    nowPlaying = ""
end

net.Receive("MedalMusic_PlayClient", function()
    local name = net.ReadString()
    local url = net.ReadString()
    local volume = net.ReadFloat()
    if url == "" then return end
    if MedalBarracks.NormalizeMediaURL then url = MedalBarracks.NormalizeMediaURL(url) end

    stopLocalMusic()
    sound.PlayURL(url, "noplay noblock", function(chan, errID, errName)
        if not chan then
            MsgC(Color(220, 80, 80), "[MedalMusic] Lecture impossible : " .. tostring(errName or errID) .. "\n")
            return
        end
        musicChannel = chan
        nowPlaying = name
        chan:SetVolume(math.Clamp(volume, 0, 1))
        chan:Play()
    end)

    -- Toast "en cours de lecture".
    MedalBarracks.MusicToastUntil = SysTime() + 6
    MedalBarracks.MusicToastName = name
end)

net.Receive("MedalMusic_StopClient", function()
    stopLocalMusic()
end)

hook.Add("HUDPaint", "MedalMusic_Toast", function()
    if (MedalBarracks.MusicToastUntil or 0) < SysTime() then return end
    local a = math.Clamp((MedalBarracks.MusicToastUntil - SysTime()) / 0.5, 0, 1) * 255
    local w, h = S(380), S(52)
    local x, y = ScrW() / 2 - w / 2, S(86)
    draw.RoundedBox(0, x, y, w, h, Color(10, 12, 9, math.min(a, 205)))
    draw.RoundedBox(0, x, y, S(4), h, Color(COL_KHAKI.r, COL_KHAKI.g, COL_KHAKI.b, a))
    draw.SimpleText("♪  " .. tostring(MedalBarracks.MusicToastName or ""), "MedalMusic_Row", x + S(18), y + S(10), Color(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Diffusion du commandement", "MedalMusic_Small", x + S(18), y + S(31), Color(232, 234, 222, a * 0.55), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)

-- =========================
-- Menu staff
-- =========================
net.Receive("MedalMusic_List", function()
    local count = net.ReadUInt(10)
    musicList = {}
    for i = 1, count do musicList[i] = {name = net.ReadString()} end
    local playing = net.ReadString()
    MedalBarracks.MusicServerPlaying = playing
    if IsValid(MedalBarracks.MusicFrame) and MedalBarracks.MusicFrame.Rebuild then MedalBarracks.MusicFrame:Rebuild() end
end)

function MedalBarracks.OpenMusicMenu()
    if IsValid(MedalBarracks.MusicFrame) then MedalBarracks.MusicFrame:Remove(); return end

    net.Start("MedalMusic_Request")
        net.WriteBool(false)
    net.SendToServer()

    local frame = vgui.Create("DFrame")
    MedalBarracks.MusicFrame = frame
    local fw, fh = S(640), S(720)
    frame:SetSize(fw, fh)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.12, 0)
    frame.volume = tonumber(musicCfg().DefaultVolume) or 0.5

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 9, 242))
        draw.RoundedBox(0, 0, 0, S(5), h, COL_OLIVE)
        surface.SetDrawColor(214, 220, 196, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("MUSIQUES DU SERVEUR", "MedalMusic_Title", S(30), S(24), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local sub = "Dossier Dropbox synchronisé automatiquement"
        local playing = MedalBarracks.MusicServerPlaying or ""
        if playing ~= "" then sub = "EN LECTURE : " .. playing end
        draw.SimpleText(sub, "MedalMusic_Small", S(31), S(58), playing ~= "" and COL_KHAKI or Color(232, 234, 222, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(112, 126, 74, 200)
        surface.DrawRect(S(30), S(80), S(56), S(3))

        -- Volume de diffusion.
        draw.SimpleText("VOLUME DE DIFFUSION : " .. math.floor(self.volume * 100) .. "%", "MedalMusic_Small", S(30), S(96), Color(232, 234, 222, 165), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- Slider de volume.
    local vol = vgui.Create("DButton", frame)
    vol:SetText("")
    vol:SetPos(S(30), S(116))
    vol:SetSize(fw - S(60), S(24))
    local function volFromCursor()
        local cx = vol:CursorPos()
        frame.volume = math.Clamp(cx / vol:GetWide(), 0, 1)
    end
    vol.OnMousePressed = function() vol.dragging = true; volFromCursor() end
    vol.OnMouseReleased = function() vol.dragging = false end
    vol.Think = function()
        if vol.dragging then
            if input.IsMouseDown(MOUSE_LEFT) then volFromCursor() else vol.dragging = false end
        end
    end
    vol.Paint = function(self, w, h)
        surface.SetDrawColor(60, 66, 52, 220)
        surface.DrawRect(0, h / 2 - S(1), w, S(2))
        surface.SetDrawColor(COL_KHAKI)
        surface.DrawRect(0, h / 2 - S(1), w * frame.volume, S(2))
        draw.RoundedBox(S(6), w * frame.volume - S(6), h / 2 - S(6), S(12), S(12), COL_WHITE)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(S(30), S(154))
    scroll:SetSize(fw - S(60), fh - S(250))

    local function rebuild()
        if not IsValid(scroll) then return end
        scroll:Clear()
        if #musicList == 0 then
            local empty = vgui.Create("DPanel", scroll)
            empty:Dock(TOP)
            empty:SetTall(S(80))
            empty.Paint = function(self, w, h)
                draw.SimpleText("Aucune musique trouvée.", "MedalMusic_Row", w / 2, S(16), Color(232, 234, 222, 160), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.SimpleText("Configure cfg.Music (token Dropbox ou ManifestURL) puis ACTUALISER.", "MedalMusic_Small", w / 2, S(42), Color(232, 234, 222, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
            return
        end
        for i, track in ipairs(musicList) do
            local row = vgui.Create("DButton", scroll)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, S(8))
            row:SetTall(S(46))
            row:SetText("")
            row.Paint = function(self, w, h)
                self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
                local playing = (MedalBarracks.MusicServerPlaying or "") == track.name
                draw.RoundedBox(0, 0, 0, w, h, Color(16, 19, 14, 180 + self.hoverAnim * 55))
                draw.RoundedBox(0, 0, 0, S(3), h, playing and COL_KHAKI or COL_OLIVE)
                surface.SetDrawColor(214, 220, 196, playing and 110 or (30 + self.hoverAnim * 75))
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText((playing and "♪  " or "") .. track.name, "MedalMusic_Row", S(16), h / 2, playing and COL_KHAKI or COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(playing and "EN LECTURE" or "JOUER  ›", "MedalMusic_Small", w - S(16), h / 2, playing and COL_KHAKI or Color(232, 234, 222, 120 + self.hoverAnim * 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            row.DoClick = function()
                net.Start("MedalMusic_Play")
                    net.WriteUInt(i, 10)
                    net.WriteFloat(frame.volume)
                net.SendToServer()
            end
        end
    end
    frame.Rebuild = rebuild
    rebuild()

    local function actionButton(label, x, w, accent, onClick)
        local b = vgui.Create("DButton", frame)
        b:SetText("")
        b:SetPos(x, fh - S(76))
        b:SetSize(w, S(46))
        b.Paint = function(self, bw, bh)
            self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
            draw.RoundedBox(0, 0, 0, bw, bh, Color(16, 19, 14, 180 + self.hoverAnim * 55))
            draw.RoundedBox(0, 0, 0, S(4), bh, accent)
            surface.SetDrawColor(214, 220, 196, 35 + self.hoverAnim * 80)
            surface.DrawOutlinedRect(0, 0, bw, bh, 1)
            draw.SimpleText(label, "MedalMusic_Row", bw / 2, bh / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = onClick
        return b
    end

    actionButton("ACTUALISER", S(30), S(170), COL_KHAKI, function()
        net.Start("MedalMusic_Request")
            net.WriteBool(true)
        net.SendToServer()
    end)
    actionButton("STOP", S(216), S(150), COL_RED, function()
        net.Start("MedalMusic_Stop")
        net.SendToServer()
    end)
    actionButton("FERMER", fw - S(30) - S(160), S(160), Color(110, 110, 110), function()
        frame:Remove()
    end)

    frame.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE then self:Remove() end
    end
end

concommand.Add((cfg.Music and cfg.Music.Command) or "medal_music", function()
    MedalBarracks.OpenMusicMenu()
end)
