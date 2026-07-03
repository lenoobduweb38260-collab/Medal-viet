if SERVER then return end

MedalBarracks = MedalBarracks or {}
MedalBarracks.ClientCharacters = MedalBarracks.ClientCharacters or {}

local cfg = MedalBarracks.Config or {}
local cols = cfg.Colors or {}
local blur = Material("pp/blurscreen")

surface.CreateFont("MedalBarracks_MenuTitle", {font = "Roboto Condensed", size = 68, weight = 1000, extended = true})
surface.CreateFont("MedalBarracks_MenuSubtitle", {font = "Roboto Condensed", size = 18, weight = 900, extended = true})
surface.CreateFont("MedalBarracks_H1", {font = "Roboto Condensed", size = 32, weight = 950, extended = true})
surface.CreateFont("MedalBarracks_H2", {font = "Roboto Condensed", size = 20, weight = 850, extended = true})
surface.CreateFont("MedalBarracks_Row", {font = "Roboto Condensed", size = 17, weight = 650, extended = true})
surface.CreateFont("MedalBarracks_RowSmall", {font = "Roboto Condensed", size = 12, weight = 650, extended = true})
surface.CreateFont("MedalBarracks_Level", {font = "Roboto Condensed", size = 34, weight = 950, extended = true})
surface.CreateFont("MedalBarracks_Icon", {font = "Arial", size = 26, weight = 900, extended = true})
surface.CreateFont("MedalBarracks_CardTitle", {font = "Roboto Condensed", size = 31, weight = 1000, extended = true})
surface.CreateFont("MedalBarracks_CardBody", {font = "Roboto Condensed", size = 15, weight = 650, extended = true})
surface.CreateFont("MedalBarracks_CardPlus", {font = "Roboto Condensed", size = 96, weight = 800, extended = true})
surface.CreateFont("MedalBarracks_InputLabel", {font = "Roboto Condensed", size = 15, weight = 850, extended = true})
-- Alias/compléments utilisés par les nouveaux écrans.
-- Les alias évitent les erreurs du type "MedalBarracks_Title isn't a valid font"
-- si une partie de l'UI appelle un ancien nom de police.
surface.CreateFont("MedalBarracks_Title", {font = "Roboto Condensed", size = 44, weight = 1000, extended = true})
surface.CreateFont("MedalBarracks_BigTitle", {font = "Roboto Condensed", size = 72, weight = 1000, extended = true})
surface.CreateFont("MedalBarracks_WepName", {font = "Roboto Condensed", size = 18, weight = 900, extended = true})
surface.CreateFont("MedalBarracks_WepSmall", {font = "Roboto Condensed", size = 11, weight = 800, extended = true})
-- Polices dédiées à la DA Hell Let Loose : en-têtes, onglets et hints de touches.
surface.CreateFont("MedalBarracks_HLLHeader", {font = "Roboto Condensed", size = 42, weight = 1000, extended = true})
surface.CreateFont("MedalBarracks_HLLTab", {font = "Roboto Condensed", size = 17, weight = 900, extended = true})
surface.CreateFont("MedalBarracks_HLLKey", {font = "Roboto Condensed", size = 14, weight = 900, extended = true})

local function S(v)
    return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080))
end

local function C(name, fallback)
    return cols[name] or fallback or color_white
end

-- =========================
-- Typographie Hell Let Loose : majuscules avec lettrage espacé.
-- =========================
local function spacedTextWidth(text, font, spacing)
    surface.SetFont(font)
    local total = 0
    for _, code in utf8.codes(tostring(text or "")) do
        total = total + surface.GetTextSize(utf8.char(code)) + spacing
    end
    return math.max(0, total - spacing)
end

local function drawSpacedText(text, font, x, y, col, spacing, alignX, alignY)
    text = string.upper(tostring(text or ""))
    if text == "" then return 0, 0 end
    spacing = spacing or S(3)
    surface.SetFont(font)
    local totalW = spacedTextWidth(text, font, spacing)
    local _, th = surface.GetTextSize("W")
    if alignX == TEXT_ALIGN_CENTER then x = x - totalW / 2 elseif alignX == TEXT_ALIGN_RIGHT then x = x - totalW end
    if alignY == TEXT_ALIGN_CENTER then y = y - th / 2 elseif alignY == TEXT_ALIGN_BOTTOM then y = y - th end
    surface.SetTextColor(col.r, col.g, col.b, col.a or 255)
    local cx = x
    for _, code in utf8.codes(text) do
        local ch = utf8.char(code)
        surface.SetTextPos(cx, y)
        surface.DrawText(ch)
        cx = cx + surface.GetTextSize(ch) + spacing
    end
    return totalW, th
end

-- En-tête d'écran HLL : fil d'Ariane, grand titre espacé, filet fin sur toute la largeur.
local function drawHLLHeader(w, crumb, title, subtitle, accent)
    accent = accent or C("Red", Color(190, 28, 28))
    local x = S(72)
    drawSpacedText(crumb or "MEDAL VIETNAM", "MedalBarracks_HLLTab", x + S(2), S(34), Color(235, 235, 235, 115), S(5))
    drawSpacedText(title or "", "MedalBarracks_HLLHeader", x, S(58), Color(245, 245, 245, 240), S(6))
    draw.RoundedBox(0, x + S(2), S(108), S(56), S(3), accent)
    surface.SetDrawColor(255, 255, 255, 26)
    surface.DrawRect(x + S(70), S(109), w - x * 2 - S(70), 1)
    if subtitle and subtitle ~= "" then
        drawSpacedText(subtitle, "MedalBarracks_HLLTab", x + S(2), S(122), Color(235, 235, 235, 150), S(3))
    end
end

-- Version centrée pour les écrans plein cadre (factions, options).
local function drawHLLHeaderCentered(w, title, subtitle, accent)
    accent = accent or C("Red", Color(190, 28, 28))
    drawSpacedText(title or "", "MedalBarracks_HLLHeader", w / 2, S(34), Color(245, 245, 245, 240), S(8), TEXT_ALIGN_CENTER)
    draw.RoundedBox(0, w / 2 - S(28), S(88), S(56), S(3), accent)
    if subtitle and subtitle ~= "" then
        drawSpacedText(subtitle, "MedalBarracks_HLLTab", w / 2, S(104), Color(235, 235, 235, 165), S(2), TEXT_ALIGN_CENTER)
    end
end

-- Barre d'action basse HLL : filet fin + hint de touche ÉCHAP à gauche.
local function drawHLLFooter(w, h, escLabel)
    local y = h - S(118)
    surface.SetDrawColor(255, 255, 255, 26)
    surface.DrawRect(S(72), y, w - S(144), 1)
    if escLabel and escLabel ~= "" then
        local keyW = S(64)
        local keyY = h - S(36)
        draw.RoundedBox(0, S(72), keyY, keyW, S(24), Color(235, 235, 235, 20))
        surface.SetDrawColor(255, 255, 255, 70)
        surface.DrawOutlinedRect(S(72), keyY, keyW, S(24), 1)
        draw.SimpleText("ÉCHAP", "MedalBarracks_HLLKey", S(72) + keyW / 2, keyY + S(12), Color(235, 235, 235, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        drawSpacedText(escLabel, "MedalBarracks_HLLKey", S(72) + keyW + S(14), keyY + S(12), Color(235, 235, 235, 130), S(2), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

local activeAudio = {}

local function isAudioURL(v)
    v = tostring(v or "")
    return string.StartWith(v, "http://") or string.StartWith(v, "https://")
end

local function normalizeMediaURL(url)
    url = tostring(url or "")
    if url == "" then return "" end

    local rm = cfg.RemoteMedia or {}
    local dropbox = rm.Dropbox or {}
    if dropbox.Enabled ~= false and string.find(url, "dropbox.com", 1, true) then
        url = string.gsub(url, "^https://www%.dropbox%.com/", "https://dl.dropboxusercontent.com/")
        url = string.gsub(url, "^http://www%.dropbox%.com/", "https://dl.dropboxusercontent.com/")
        url = string.gsub(url, "^https://dropbox%.com/", "https://dl.dropboxusercontent.com/")
        url = string.gsub(url, "^http://dropbox%.com/", "https://dl.dropboxusercontent.com/")

        if dropbox.ForceRaw ~= false then
            -- Dropbox : les liens partagés finissent souvent par dl=0.
            -- Pour DHTML/GMod, le mode dl=1 sur dl.dropboxusercontent.com est le plus fiable.
            url = string.gsub(url, "([%?&])dl=%d", "%1")
            url = string.gsub(url, "([%?&])raw=%d", "%1")
            url = string.gsub(url, "%?&", "?")
            url = string.gsub(url, "&&+", "&")
            url = string.gsub(url, "[?&]$", "")
            local mode = tostring(dropbox.DirectMode or "dl")
            local suffix = mode == "raw" and "raw=1" or "dl=1"
            if string.find(url, "?", 1, true) then
                url = url .. "&" .. suffix
            else
                url = url .. "?" .. suffix
            end
        end
    end

    return url
end

MedalBarracks.NormalizeMediaURL = normalizeMediaURL

local function stopAudioChannel(name)
    if not name then return end
    local ch = activeAudio[name]
    if ch and ch.Stop then pcall(function() ch:Stop() end) end
    activeAudio[name] = nil
end

local function playSound(source, channelName)
    if not source or source == "" then return end

    local url, path, volume, loop, flags
    if istable(source) then
        url = source.url or source.URL or source.link
        path = source.path or source.sound or source.file
        volume = tonumber(source.volume) or 1
        loop = source.loop == true
        flags = source.flags or "noplay noblock"
    elseif isstring(source) then
        if isAudioURL(source) then url = source else path = source end
        volume = 1
        loop = false
        flags = "noplay noblock"
    end

    if isstring(url) and url ~= "" then
        url = normalizeMediaURL(url)
        local chanName = channelName or url
        stopAudioChannel(chanName)
        sound.PlayURL(url, flags, function(chan, errID, errName)
            if not chan then
                MsgC(Color(220, 80, 80), "[MedalBarracks] Audio URL impossible à lire : " .. tostring(url) .. " | " .. tostring(errName or errID) .. "\n")
                return
            end
            activeAudio[chanName] = chan
            if chan.SetVolume then chan:SetVolume(math.Clamp(volume or 1, 0, 1)) end
            if loop and chan.EnableLooping then chan:EnableLooping(true) end
            if chan.Play then chan:Play() end
        end)
        return
    end

    if isstring(path) and path ~= "" then
        -- Pour les sons locaux, GMod exige que le fichier existe côté client :
        -- garrysmod/sound/<path> ou fichier inclus dans la collection Workshop/FastDL.
        surface.PlaySound(path)
    end
end

local function playButtonSound(source)
    local snd = cfg.Sounds or {}
    if snd.EnableButtonSounds == false then return end
    playSound(source)
end

function MedalBarracks.StopMenuAmbient()
    stopAudioChannel("main_ambient")
end

function MedalBarracks.StartMenuAmbient()
    if MedalBarracks.FetchRemoteManifest then MedalBarracks.FetchRemoteManifest(false) end
    local snd = cfg.Sounds or {}
    if activeAudio["main_ambient"] then return end
    if snd.MainAmbient and snd.MainAmbient ~= "" then
        playSound(snd.MainAmbient, "main_ambient")
        return
    end
    local rm = cfg.RemoteMedia or {}
    local key = rm.Usage and rm.Usage.MainMenuAmbient or "main_menu_ambient"
    local media = MedalBarracks.GetRemoteMedia and MedalBarracks.GetRemoteMedia(key)
    if istable(media) then
        local url = media.url or media.URL or media.link
        local path = media.path or media.sound or media.file
        if url or path then playSound({url = url, path = path, volume = tonumber(media.volume) or 0.25, loop = media.loop ~= false}, "main_ambient") end
    end
end

local function scheduleMenuAmbientStop()
    timer.Simple(0.25, function()
        if IsValid(MedalBarracks.MainFrame) or IsValid(MedalBarracks.CharacterFrame) or IsValid(MedalBarracks.Frame) then return end
        MedalBarracks.StopMenuAmbient()
    end)
end


-- =========================
-- Médias distants / serveur annexe
-- =========================
MedalBarracks.RemoteMediaManifest = MedalBarracks.RemoteMediaManifest or nil
MedalBarracks.RemoteMediaLastFetch = MedalBarracks.RemoteMediaLastFetch or 0
MedalBarracks.ActiveCinematic = MedalBarracks.ActiveCinematic or nil

local function remoteCfg()
    return cfg.RemoteMedia or {}
end

local function isSecureURL(url)
    url = normalizeMediaURL(url)
    if url == "" then return false end
    if string.StartWith(url, "https://") then return true end
    if string.StartWith(url, "http://") then return remoteCfg().AllowInsecureHTTP == true end
    return false
end

local function htmlEscape(str)
    str = tostring(str or "")
    str = string.Replace(str, "&", "&amp;")
    str = string.Replace(str, "<", "&lt;")
    str = string.Replace(str, ">", "&gt;")
    str = string.Replace(str, '"', "&quot;")
    str = string.Replace(str, "'", "&#39;")
    return str
end

local function mediaFromTable(key)
    local rm = remoteCfg()

    -- Vidéos directes configurables par écran : main_menu_background, faction_background,
    -- character_background, barracks_background, options_background, staff_background, etc.
    -- Compatible Dropbox : l'URL est normalisée plus loin par mediaURL()/normalizeMediaURL().
    local screenVideos = rm.ScreenVideos or rm.DirectVideos or rm.MenuVideos
    local directScreen = istable(screenVideos) and screenVideos[key] or nil
    if istable(directScreen) and directScreen.Enabled ~= false then
        local url = directScreen.URL or directScreen.url or directScreen.Link or directScreen.link
        if isstring(url) and url ~= "" then
            return {
                type = directScreen.Type or directScreen.type or "video",
                url = url,
                loop = directScreen.Loop ~= false,
                muted = directScreen.Muted == true or (tonumber(directScreen.Volume) or 0) <= 0,
                volume = math.Clamp(tonumber(directScreen.Volume) or 0, 0, 1),
                opacity = tonumber(directScreen.Opacity) or tonumber(rm.BackgroundVideoAlpha) or 0.72,
                objectFit = directScreen.ObjectFit or directScreen.objectFit or "cover",
                objectPosition = directScreen.ObjectPosition or directScreen.objectPosition,
                crop = directScreen.Crop or directScreen.crop,
                zoom = directScreen.Zoom or directScreen.zoom,
                filter = directScreen.Filter or directScreen.filter,
            }
        end
    end

    -- Raccourci de config demandé : vidéo Dropbox du menu principal, avec volume configurable.
    -- Cela évite de devoir créer un manifest.json juste pour le fond du main menu.
    local usage = rm.Usage or {}
    if key == "main_menu_background" or key == usage.MainMenuBackground then
        local direct = rm.MainMenuDropboxVideo
        if istable(direct) and direct.Enabled ~= false and isstring(direct.URL) and direct.URL ~= "" then
            return {
                type = "video",
                url = direct.URL,
                loop = direct.Loop ~= false,
                muted = direct.Muted == true or (tonumber(direct.Volume) or 0) <= 0,
                volume = math.Clamp(tonumber(direct.Volume) or 0.35, 0, 1),
                opacity = tonumber(direct.Opacity) or tonumber(rm.BackgroundVideoAlpha) or 0.72,
                objectFit = direct.ObjectFit or "cover",
                objectPosition = direct.ObjectPosition,
                crop = direct.Crop,
                zoom = direct.Zoom,
                filter = direct.Filter,
            }
        end
    end

    local manifest = MedalBarracks.RemoteMediaManifest
    if istable(manifest) then
        if istable(manifest.media) and istable(manifest.media[key]) then return table.Copy(manifest.media[key]) end
        if istable(manifest.assets) and istable(manifest.assets[key]) then return table.Copy(manifest.assets[key]) end
        if istable(manifest[key]) then return table.Copy(manifest[key]) end
    end
    if istable(rm.Fallbacks) and istable(rm.Fallbacks[key]) then return table.Copy(rm.Fallbacks[key]) end
    return nil
end

function MedalBarracks.GetRemoteMedia(key)
    if not key or key == "" then return nil end
    local rm = remoteCfg()
    if rm.Enabled == false then return mediaFromTable(key) end
    return mediaFromTable(key)
end

function MedalBarracks.FetchRemoteManifest(force, callback)
    local rm = remoteCfg()
    if rm.Enabled == false or rm.ClientFetch == false then if callback then callback(false) end return end
    local url = normalizeMediaURL(rm.ManifestURL or "")
    if url == "" or not isSecureURL(url) then if callback then callback(false) end return end

    local refresh = tonumber(rm.RefreshInterval) or 300
    if not force and MedalBarracks.RemoteMediaManifest and refresh > 0 and (CurTime() - (MedalBarracks.RemoteMediaLastFetch or 0)) < refresh then
        if callback then callback(true) end
        return
    end

    http.Fetch(url, function(body)
        local data = util.JSONToTable(body or "")
        if not istable(data) then
            MsgC(Color(220,80,80), "[MedalBarracks] Manifest média invalide : " .. url .. "\n")
            if callback then callback(false) end
            return
        end
        MedalBarracks.RemoteMediaManifest = data
        MedalBarracks.RemoteMediaLastFetch = CurTime()
        MsgC(Color(198,181,94), "[MedalBarracks] Manifest média chargé depuis le serveur annexe.\n")
        if callback then callback(true) end
    end, function(err)
        MsgC(Color(220,80,80), "[MedalBarracks] Impossible de récupérer le manifest média : " .. tostring(err) .. "\n")
        if callback then callback(false) end
    end)
end

local function mediaURL(media)
    if not istable(media) then return "" end
    return normalizeMediaURL(media.url or media.URL or media.link or media.src or "")
end

local function youtubeEmbed(url)
    url = tostring(url or "")
    local id = url:match("youtu%.be/([%w_%-]+)") or url:match("v=([%w_%-]+)") or url:match("embed/([%w_%-]+)")
    if not id or id == "" then return url end
    return "https://www.youtube.com/embed/" .. id .. "?autoplay=1&controls=0&modestbranding=1&rel=0&loop=1&playlist=" .. id
end

local function buildVideoHTML(media, mode)
    local url = mediaURL(media)
    local mtype = tostring(media.type or media.kind or "video")
    local muted = media.muted ~= false
    local loop = media.loop == true or mode == "background"
    local opacity = tonumber(media.opacity) or (mode == "background" and (tonumber(remoteCfg().BackgroundVideoAlpha) or 0.62) or 1)
    local volume = math.Clamp(tonumber(media.volume) or (muted and 0 or 0.55), 0, 1)
    local objectFit = tostring(media.objectFit or media.fit or "cover")
    local crop = istable(media.crop) and media.crop or {}
    local posX = tonumber(media.objectPositionX or media.positionX or crop.X or crop.x) or 50
    local posY = tonumber(media.objectPositionY or media.positionY or crop.Y or crop.y) or 50
    local objectPosition = tostring(media.objectPosition or media.position or (tostring(posX) .. "% " .. tostring(posY) .. "%"))
    local zoom = math.max(tonumber(media.zoom or media.scale or crop.Zoom or crop.zoom) or 1, 1)
    local filter = tostring(media.filter or (mode == "background" and "brightness(.72) contrast(1.08) saturate(.95)" or "brightness(.95) contrast(1.05)"))

    if mtype == "youtube" or string.find(url, "youtube.com", 1, true) or string.find(url, "youtu.be", 1, true) then
        local embed = htmlEscape(youtubeEmbed(url))
        return [[<!doctype html><html><head><meta charset="utf-8"><style>
            html,body{margin:0;padding:0;overflow:hidden;background:transparent;width:100%;height:100%;}
            iframe{position:fixed;left:0;top:0;width:100%;height:100%;border:0;opacity:]] .. tostring(opacity) .. [[;filter:]] .. htmlEscape(filter) .. [[;pointer-events:none;transform:scale(]] .. tostring(zoom) .. [[);transform-origin:]] .. htmlEscape(objectPosition) .. [[;}
        </style></head><body><iframe allow="autoplay; fullscreen" src="]] .. embed .. [["></iframe></body></html>]]
    end

    local mime = string.find(string.lower(url), ".webm", 1, true) and "video/webm" or "video/mp4"
    return [[<!doctype html><html><head><meta charset="utf-8"><style>
        html,body{margin:0;padding:0;overflow:hidden;background:transparent;width:100%;height:100%;}
        video{position:fixed;left:0;top:0;width:100%;height:100%;object-fit:]] .. htmlEscape(objectFit) .. [[;object-position:]] .. htmlEscape(objectPosition) .. [[;opacity:]] .. tostring(opacity) .. [[;filter:]] .. htmlEscape(filter) .. [[;pointer-events:none;background:transparent;transform:scale(]] .. tostring(zoom) .. [[);transform-origin:]] .. htmlEscape(objectPosition) .. [[;}
    </style></head><body>
        <video id="v" autoplay playsinline webkit-playsinline ]] .. (loop and "loop " or "") .. (muted and "muted " or "") .. [[preload="auto">
            <source src="]] .. htmlEscape(url) .. [[" type="]] .. mime .. [[">
        </video>
        <script>
            var v=document.getElementById('v');
            v.volume=]] .. tostring(volume) .. [[;
            v.muted=]] .. (muted and "true" or "false") .. [[;
            function tryPlay(){ var p=v.play(); if(p && p.catch){ p.catch(function(){ setTimeout(function(){v.muted=true; v.play().catch(function(){});}, 250); }); } }
            document.addEventListener('click', tryPlay);
            setTimeout(tryPlay, 80);
            setTimeout(tryPlay, 650);
        </script>
    </body></html>]]
end

function MedalBarracks.AttachBackgroundVideo(parent, usageKey)
    local rm = remoteCfg()
    if rm.Enabled == false or not IsValid(parent) then return nil end
    local media = MedalBarracks.GetRemoteMedia(usageKey)
    if not media then return nil end
    local url = mediaURL(media)
    if url == "" or not isSecureURL(url) then return nil end

    -- Vidéo principale : toujours derrière toute l'UI.
    local html = vgui.Create("DHTML", parent)
    html:SetPos(0, 0)
    html:SetSize(parent:GetWide(), parent:GetTall())
    html:SetMouseInputEnabled(false)
    html:SetKeyboardInputEnabled(false)
    html:SetZPos(-10000)
    html:SetHTML(buildVideoHTML(media, "background"))

    -- Vidéo optionnelle uniquement dans la zone gauche, utilisable pour cropper une autre source.
    local leftVideo
    local lz = cfg.MainMenuLeftZone or {}
    local lv = istable(lz.Video) and lz.Video or {}
    local leftMode = tostring(lz.Mode or "fog")
    local leftW = S(tonumber(lz.Width) or tonumber((cfg.MainMenuOverlay or {}).LeftWidth) or 620)
    if lz.Enabled ~= false and leftMode == "video" and (not parent.state or parent.state == "main") and lv.Enabled ~= false and isstring(lv.URL) and lv.URL ~= "" then
        local leftMedia = {
            type = "video",
            url = lv.URL,
            loop = lv.Loop ~= false,
            muted = lv.Muted ~= false or (tonumber(lv.Volume) or 0) <= 0,
            volume = math.Clamp(tonumber(lv.Volume) or 0, 0, 1),
            opacity = tonumber(lv.Opacity) or 0.95,
            objectFit = lv.ObjectFit or "cover",
            objectPosition = lv.ObjectPosition,
            crop = lv.Crop,
            zoom = lv.Zoom,
            filter = lv.Filter or "brightness(.52) contrast(1.18) saturate(.88)",
        }
        local lurl = mediaURL(leftMedia)
        if lurl ~= "" and isSecureURL(lurl) then
            leftVideo = vgui.Create("DHTML", parent)
            leftVideo:SetPos(0, 0)
            leftVideo:SetSize(leftW, parent:GetTall())
            leftVideo:SetMouseInputEnabled(false)
            leftVideo:SetKeyboardInputEnabled(false)
            leftVideo:SetZPos(-9500)
            leftVideo:SetHTML(buildVideoHTML(leftMedia, "background"))
        end
    end

    -- Overlay sombre / brume : derrière les boutons, au-dessus de la vidéo.
    local overlay = vgui.Create("DPanel", parent)
    overlay:SetPos(0, 0)
    overlay:SetSize(parent:GetWide(), parent:GetTall())
    overlay:SetMouseInputEnabled(false)
    overlay:SetKeyboardInputEnabled(false)
    overlay:SetZPos(-9000)
    overlay.Paint = function(_, w, h)
        local oc = cfg.MainMenuOverlay or {}
        if oc.Enabled == false then return end
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, tonumber(oc.FullscreenAlpha) or 18))

        -- L'effet très sombre à gauche ne s'applique que sur la page principale.
        -- Sur les pages faction/options/personnage, on garde seulement un voile léger en fond.
        if parent.state and parent.state ~= "main" then return end

        local zone = cfg.MainMenuLeftZone or {}
        if zone.Enabled == false or tostring(zone.Mode or "shadow") == "none" then return end

        local mode = tostring(zone.Mode or "shadow")
        local leftW = S(tonumber(zone.Width) or 880)
        local solidW = S(tonumber(zone.SolidWidth) or math.min(leftW * 0.55, 500))
        local leftA = tonumber(zone.DarkAlpha) or 248
        local fadeW = S(tonumber(zone.FadeWidth) or math.max(leftW - solidW, 240))
        local fadeA = tonumber(zone.FadeAlpha) or 238

        if mode == "shadow" or mode == "gradient" or mode == "cinematic" then
            draw.RoundedBox(0, 0, 0, solidW, h, Color(0, 0, 0, leftA))

            local steps = math.max(18, math.floor(fadeW / S(12)))
            local stepW = math.max(S(2), math.ceil(fadeW / steps))
            local power = tonumber(zone.GradientPower) or 2.15
            for i = 0, steps do
                local t = i / steps
                local a = math.Clamp(fadeA * ((1 - t) ^ power), 0, 255)
                draw.RoundedBox(0, solidW + i * stepW, 0, stepW + S(2), h, Color(0, 0, 0, a))
            end

            -- Vignette haut/bas pour obtenir le côté cinématique du visuel de référence.
            local topA = tonumber(zone.TopVignetteAlpha) or 78
            local botA = tonumber(zone.BottomVignetteAlpha) or 108
            local vSteps = 18
            for i = 0, vSteps do
                local t = i / vSteps
                local aTop = topA * ((1 - t) ^ 1.7)
                local aBot = botA * ((1 - t) ^ 1.45)
                local rh = S(18)
                draw.RoundedBox(0, 0, i * rh, w, rh + 1, Color(0, 0, 0, aTop))
                draw.RoundedBox(0, 0, h - (i + 1) * rh, w, rh + 1, Color(0, 0, 0, aBot))
            end
            return
        end

        -- Ancien mode vidéo cropée : on garde le fondu pour ne pas avoir de séparation nette.
        local videoDark = 0
        if mode == "video" then videoDark = tonumber((zone.Video or {}).DarkOverlayAlpha) or 150 end
        draw.RoundedBox(0, 0, 0, solidW, h, Color(0, 0, 0, math.max(leftA, videoDark)))

        local steps = math.max(18, math.floor(fadeW / S(12)))
        local stepW = math.max(S(2), math.ceil(fadeW / steps))
        for i = 0, steps do
            local t = i / steps
            draw.RoundedBox(0, solidW + i * stepW, 0, stepW + S(2), h, Color(0, 0, 0, math.max(0, fadeA * ((1 - t) ^ 1.8))))
        end

        -- Ancien mode brume si tu le réactives dans la config.
        if mode == "fog" then
            local fog = zone.Fog or {}
            if fog.Enabled ~= false then
                local fogCol = fog.Color or Color(150, 155, 160, 255)
                local bands = math.max(0, math.floor(tonumber(fog.Bands) or 8))
                local fogA = tonumber(fog.Alpha) or 18
                local speed = tonumber(fog.Speed) or 0.10
                local minW = S(tonumber(fog.MinWidth) or 160)
                local maxW = S(tonumber(fog.MaxWidth) or 360)
                local t = CurTime() * speed * 120
                for i = 1, bands do
                    local bw = minW + ((i * 43) % math.max(maxW - minW, 1))
                    local x = ((i * S(173) + t) % (solidW + bw + S(120))) - bw
                    local a = fogA * (0.45 + 0.55 * math.abs(math.sin(CurTime() * speed + i)))
                    draw.RoundedBox(0, x, 0, bw, h, Color(fogCol.r, fogCol.g, fogCol.b, a))
                end
            end
        end
    end

    parent._remoteVideoActive = true
    parent._remoteVideoPanel = html
    parent._remoteLeftVideoPanel = leftVideo
    parent._remoteVideoOverlay = overlay
    parent.OnSizeChanged = function(_, w, h)
        if IsValid(html) then html:SetSize(w, h) end
        if IsValid(leftVideo) then
            local zone = cfg.MainMenuLeftZone or {}
            local leftW = S(tonumber(zone.Width) or tonumber((cfg.MainMenuOverlay or {}).LeftWidth) or 620)
            leftVideo:SetSize(leftW, h)
        end
        if IsValid(overlay) then overlay:SetSize(w, h) end
    end
    return html
end


function MedalBarracks.ClearBackgroundVideo(parent)
    if not IsValid(parent) then return end
    if IsValid(parent._remoteVideoPanel) then parent._remoteVideoPanel:Remove() end
    if IsValid(parent._remoteLeftVideoPanel) then parent._remoteLeftVideoPanel:Remove() end
    if IsValid(parent._remoteVideoOverlay) then parent._remoteVideoOverlay:Remove() end
    parent._remoteVideoPanel = nil
    parent._remoteLeftVideoPanel = nil
    parent._remoteVideoOverlay = nil
    parent._remoteVideoActive = false
end

function MedalBarracks.SetBackgroundVideo(parent, usageKey)
    if not IsValid(parent) then return nil end
    MedalBarracks.ClearBackgroundVideo(parent)
    if not usageKey or usageKey == "" then return nil end

    local panel = MedalBarracks.AttachBackgroundVideo(parent, usageKey)

    -- Confort : si le menu demandé n'a pas de vidéo dédiée, on garde la vidéo du main menu.
    -- Ça évite un écran noir/fond statique quand tu n'as pas encore renseigné toutes les URLs Dropbox.
    local rm = cfg.RemoteMedia or {}
    local mainKey = rm.Usage and rm.Usage.MainMenuBackground
    if not panel and rm.ReuseMainVideoWhenScreenEmpty ~= false and mainKey and mainKey ~= usageKey then
        panel = MedalBarracks.AttachBackgroundVideo(parent, mainKey)
    end

    if not panel and MedalBarracks.FetchRemoteManifest then
        MedalBarracks.FetchRemoteManifest(false, function()
            if not IsValid(parent) or IsValid(parent._remoteVideoPanel) then return end
            local p = MedalBarracks.AttachBackgroundVideo(parent, usageKey)
            if not p and rm.ReuseMainVideoWhenScreenEmpty ~= false and mainKey and mainKey ~= usageKey then
                MedalBarracks.AttachBackgroundVideo(parent, mainKey)
            end
        end)
    end
    return panel
end

function MedalBarracks.PlayRemoteCinematic(usageKey, callback, fallbackTitle, fallbackSubtitle, fallbackSound)
    local rm = remoteCfg()
    if rm.Enabled == false then if callback then callback() end return false end
    local media = MedalBarracks.GetRemoteMedia(usageKey)
    if not media then if callback then callback() end return false end
    local url = mediaURL(media)
    if url == "" or not isSecureURL(url) then if callback then callback() end return false end

    if IsValid(MedalBarracks.ActiveCinematic) then MedalBarracks.ActiveCinematic:Remove() end

    local dur = tonumber(media.duration) or tonumber(media.length) or 4.5
    local skippable = media.skippable ~= false
    local fade = tonumber(media.fade) or 0.2

    local frame = vgui.Create("DFrame")
    MedalBarracks.ActiveCinematic = frame
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, fade, 0)
    frame.started = SysTime()
    frame.done = false

    local html = vgui.Create("DHTML", frame)
    html:SetPos(0, 0)
    html:SetSize(ScrW(), ScrH())
    html:SetMouseInputEnabled(false)
    html:SetKeyboardInputEnabled(false)
    html:SetHTML(buildVideoHTML(media, "cinematic"))

    if media.audio or media.audioURL then
        playSound({url = media.audio or media.audioURL, volume = tonumber(media.audioVolume) or tonumber(media.volume) or 0.65, loop = false}, "cinematic_audio")
    elseif media.sound or media.soundPath then
        playSound(media.sound or media.soundPath)
    end

    local function finish()
        if frame.done then return end
        frame.done = true
        stopAudioChannel("cinematic_audio")
        frame:AlphaTo(0, fade, 0, function(_, pnl) if IsValid(pnl) then pnl:Remove() end end)
        timer.Simple(fade + 0.02, function() if callback then callback() end end)
    end

    frame.PaintOver = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 35))
        local remain = math.max(0, dur - (SysTime() - self.started))
        draw.RoundedBox(0, S(70), h - S(78), (w - S(140)) * (1 - remain / math.max(dur, 0.1)), S(3), C("Red", Color(190,28,28)))
        if fallbackTitle and fallbackTitle ~= "" then draw.SimpleText(fallbackTitle, "MedalBarracks_CardTitle", S(72), h - S(138), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) end
        if skippable then draw.SimpleText("ESPACE pour passer", "MedalBarracks_RowSmall", w - S(72), h - S(88), Color(235,235,235,150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP) end
    end
    frame.OnKeyCodePressed = function(_, key)
        if skippable and (key == KEY_SPACE or key == KEY_ENTER or key == KEY_ESCAPE) then finish() end
    end

    playSound(fallbackSound)
    timer.Simple(dur, function() if IsValid(frame) then finish() end end)
    return true
end

local function mat(path)
    if not isstring(path) or path == "" then return nil end
    local m = Material(path, "smooth")
    if not m or m:IsError() then return nil end
    return m
end

local function drawBlurPanel(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    surface.SetMaterial(blur)
    surface.SetDrawColor(255, 255, 255, 255)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end
end

local function drawMatFit(m, x, y, w, h, mode)
    if not m then return end
    local iw, ih = m:Width(), m:Height()
    surface.SetMaterial(m)
    surface.SetDrawColor(255, 255, 255, 255)
    if iw <= 0 or ih <= 0 then surface.DrawTexturedRect(x, y, w, h); return end
    local ir, br = iw / ih, w / h
    if mode == "cover" then
        local u0, v0, u1, v1 = 0, 0, 1, 1
        if ir > br then
            local visibleW = br / ir
            u0 = (1 - visibleW) / 2
            u1 = u0 + visibleW
        else
            local visibleH = ir / br
            v0 = (1 - visibleH) / 2
            v1 = v0 + visibleH
        end
        surface.DrawTexturedRectUV(x, y, w, h, u0, v0, u1, v1)
    else
        local dw, dh = w, h
        if ir > br then dh = w / ir else dw = h * ir end
        surface.DrawTexturedRect(x + (w - dw) / 2, y + (h - dh) / 2, dw, dh)
    end
end

local function drawBackground(panel, w, h)
    local bg = mat(cfg.BackgroundMaterial or "")
    if bg then
        drawMatFit(bg, 0, 0, w, h, "cover")
    else
        drawBlurPanel(panel, 7)
        draw.RoundedBox(0, 0, 0, w, h, Color(14, 14, 16, 245))
    end
    draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 78))
    for i = 0, 18 do
        draw.RoundedBox(0, 0, 0, S(450) + i * S(22), h, Color(0, 0, 0, math.max(0, 155 - i * 8)))
    end
end

local function drawFrameBackground(panel, w, h)
    -- Si une vidéo distante est attachée, elle est le vrai fond.
    -- On garde seulement un voile léger ; le gros dégradé gauche est dessiné par l'overlay dédié.
    if IsValid(panel and panel._remoteVideoPanel) then
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 22))
        return
    end
    drawBackground(panel, w, h)
end

local function roman(num)
    local r = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"}
    return r[tonumber(num) or 1] or tostring(num or 1)
end

local function drawWeaponSilhouette(x, y, w, h, weaponClass, alpha)
    alpha = alpha or 225
    local col = Color(245, 245, 245, alpha)
    local class = tostring(weaponClass or "")
    surface.SetDrawColor(col)
    if string.find(class, "pistol", 1, true) or string.find(class, "357", 1, true) then
        draw.RoundedBox(0, x + w * 0.24, y + h * 0.36, w * 0.34, h * 0.12, col)
        draw.RoundedBox(0, x + w * 0.55, y + h * 0.31, w * 0.10, h * 0.18, col)
        draw.RoundedBox(0, x + w * 0.38, y + h * 0.47, w * 0.12, h * 0.25, col)
    elseif string.find(class, "med", 1, true) then
        draw.RoundedBox(0, x + w * 0.25, y + h * 0.22, w * 0.50, h * 0.50, col)
        draw.RoundedBox(0, x + w * 0.46, y + h * 0.30, w * 0.08, h * 0.34, Color(20, 20, 20, alpha))
        draw.RoundedBox(0, x + w * 0.35, y + h * 0.43, w * 0.30, h * 0.08, Color(20, 20, 20, alpha))
    elseif string.find(class, "frag", 1, true) then
        draw.RoundedBox(8, x + w * 0.43, y + h * 0.30, w * 0.18, h * 0.30, col)
        draw.RoundedBox(0, x + w * 0.47, y + h * 0.21, w * 0.12, h * 0.10, col)
    else
        draw.RoundedBox(0, x + w * 0.17, y + h * 0.45, w * 0.60, h * 0.08, col)
        draw.RoundedBox(0, x + w * 0.68, y + h * 0.38, w * 0.16, h * 0.13, col)
        draw.RoundedBox(0, x + w * 0.31, y + h * 0.54, w * 0.10, h * 0.23, col)
        draw.RoundedBox(0, x + w * 0.10, y + h * 0.49, w * 0.12, h * 0.06, col)
    end
end

local function niceWeaponName(class)
    class = tostring(class or "")
    class = string.Replace(class, "weapon_", "")
    class = string.Replace(class, "med_kit", "medkit")
    class = string.Replace(class, "_", " ")
    return string.upper(class)
end

local function itemMaterial(item)
    if istable(item) then
        return mat(item.image or item.material or item.iconMaterial), item.name or item.label or item.class or ""
    end
    local s = tostring(item or "")
    local p = (cfg.WeaponIconMaterials and cfg.WeaponIconMaterials[s]) or (cfg.EquipmentIconMaterials and cfg.EquipmentIconMaterials[s])
    return mat(p), s
end

local function loadoutImage(loadout)
    if not loadout then return nil end
    local p = loadout.image or loadout.rowImage or loadout.iconMaterial
    if p then return mat(p) end
    local main = loadout.weapons and loadout.weapons[1]
    if main and cfg.WeaponIconMaterials then return mat(cfg.WeaponIconMaterials[main]) end
    return nil
end

local function loadoutPreviewImage(loadout)
    if not loadout then return nil end
    if loadout.previewImage then return mat(loadout.previewImage) end
    if istable(loadout.preview) and loadout.preview.type == "material" then
        return mat(loadout.preview.path or loadout.preview.image or loadout.preview.material)
    end
    return loadoutImage(loadout)
end

local function loadoutPreviewModel(loadout, role)
    if not loadout then return nil end
    if istable(loadout.preview) and loadout.preview.type == "model" then return loadout.preview.model or loadout.model or (role and role.model) end
    if loadout.previewModel then return loadout.previewModel end
    if loadout.previewUseModel then return loadout.model or (role and role.model) end
    return nil
end

local function roleLevel(armyID, role)
    local ply = LocalPlayer()
    if cfg.GetPlayerRoleLevel then return cfg.GetPlayerRoleLevel(ply, armyID, role and role.id, role) end
    return tonumber(role and role.defaultRoleLevel) or 1
end

local function levelOK(armyID, role, loadout)
    local ply = LocalPlayer()
    local general = cfg.GetPlayerLevel and cfg.GetPlayerLevel(ply) or 1
    if general < (tonumber(role and role.requiredLevel) or 1) then return false end
    local req = tonumber(loadout and loadout.level) or 1
    if cfg.UseRoleLevelForLoadoutUnlocks ~= false then return roleLevel(armyID, role) >= req end
    return general >= req
end

local function drawWrappedText(text, font, x, y, maxW, col, align)
    surface.SetFont(font)
    local words = string.Explode(" ", tostring(text or ""))
    local line, yy = "", y
    for _, word in ipairs(words) do
        local test = line == "" and word or (line .. " " .. word)
        local tw = surface.GetTextSize(test)
        if tw > maxW and line ~= "" then
            draw.SimpleText(line, font, x, yy, col, align or TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            yy = yy + S(18)
            line = word
        else
            line = test
        end
    end
    if line ~= "" then draw.SimpleText(line, font, x, yy, col, align or TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP) end
end

local function wrapTextLines(text, font, maxW)
    surface.SetFont(font)
    local words = string.Explode(" ", tostring(text or ""))
    local lines = {}
    local line = ""
    for _, word in ipairs(words) do
        local test = line == "" and word or (line .. " " .. word)
        local tw = surface.GetTextSize(test)
        if tw > maxW and line ~= "" then
            table.insert(lines, line)
            line = word
        else
            line = test
        end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

local function drawTipBox(frame, w, h)
    local tips = cfg.Tips or {}
    if tips.Enabled == false then return end
    local list = tips.Texts or {}
    if #list <= 0 then return end
    local interval = math.max(tonumber(tips.Interval) or 10, 3)
    if not frame._tipText or not frame._tipNext or CurTime() >= frame._tipNext then
        frame._tipText = table.Random(list) or list[1]
        frame._tipNext = CurTime() + interval
    end

    local maxW = math.min(S(tonumber(tips.Width) or 760), w - S(120))
    local prefix = tostring(tips.Prefix or "ASTUCE :")
    surface.SetFont("MedalBarracks_Row")
    local prefixW = surface.GetTextSize(prefix) + S(12)
    local lines = wrapTextLines(frame._tipText or "", "MedalBarracks_Row", maxW - S(96) - prefixW)
    local lineH = S(21)
    local boxH = S(28) + math.max(1, #lines) * lineH
    local x = w / 2 - maxW / 2
    local y = h - S(tonumber(tips.YOffset) or 104) - boxH / 2

    local tipMat = mat(tips.Material or (cfg.DAStyle and cfg.DAStyle.TipMaterial) or "")
    if tipMat then
        surface.SetMaterial(tipMat)
        surface.SetDrawColor(255,255,255,210)
        surface.DrawTexturedRect(x, y, maxW, boxH)
    else
        draw.RoundedBox(0, x, y, maxW, boxH, Color(5, 5, 7, 142))
        surface.SetDrawColor(255,255,255,42)
        surface.DrawOutlinedRect(x, y, maxW, boxH, 1)
        draw.RoundedBox(0, x, y, S(3), boxH, C("Red", Color(190, 28, 28)))
    end

    local starX = x + S(34)
    local textX = x + S(74)
    draw.SimpleText("✦", "MedalBarracks_Icon", starX, y + boxH / 2, C("Red", Color(190, 28, 28)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(prefix, "MedalBarracks_Row", textX, y + S(14), C("Red", Color(190, 28, 28)), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    for i, line in ipairs(lines) do
        draw.SimpleText(line, "MedalBarracks_Row", textX + prefixW, y + S(14) + (i - 1) * lineH, Color(235,235,235,210), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end

local keyPrefix = "MedalBarracks_Key_"
local editingBind = nil

local function keyName(key)
    key = tonumber(key) or 0
    if key <= 0 then return "AUCUNE" end
    local n = input.GetKeyName(key)
    return string.upper(n or tostring(key))
end

local function keyNameToCode(name)
    name = string.lower(tostring(name or ""))
    if name == "" then return 0 end
    if input.GetKeyCode then
        local ok, code = pcall(input.GetKeyCode, name)
        if ok and tonumber(code) and tonumber(code) > 0 then return tonumber(code) end
    end
    for k = KEY_FIRST or 0, KEY_LAST or 200 do
        local n = input.GetKeyName(k)
        if n and string.lower(n) == name then return k end
    end
    -- Boutons souris courants.
    local mouseAliases = {mouse1 = MOUSE_LEFT, mouse2 = MOUSE_RIGHT, mouse3 = MOUSE_MIDDLE, mwheelup = MOUSE_WHEEL_UP, mwheeldown = MOUSE_WHEEL_DOWN}
    return tonumber(mouseAliases[name] or 0) or 0
end

local function commandToKeyCode(command)
    command = tostring(command or "")
    if command == "" then return 0 end
    local binding = input.LookupBinding(command)
    if not binding or binding == "" then return 0 end
    return keyNameToCode(binding)
end

local function bindMirrorCommand(bind)
    if not istable(bind) then return nil end
    if bind.gmodCommand and bind.gmodCommand ~= "" then return bind.gmodCommand end
    local ba = cfg.GModBindAdapter or cfg.BindAdapter or {}
    if ba.Enabled == false then return nil end
    for _, map in ipairs(ba.Mappings or {}) do
        if tostring(map.addonBind or map.medalBind or map.id or "") == tostring(bind.id or "") then
            return tostring(map.fromCommand or map.gmodCommand or map.command or "")
        end
    end
end

local function getBindKey(bind)
    if not istable(bind) then return 0 end
    local ba = cfg.GModBindAdapter or cfg.BindAdapter or {}
    local mirrorCmd = ba.Enabled ~= false and bindMirrorCommand(bind) or nil
    if mirrorCmd and mirrorCmd ~= "" and ba.AutoUseMirroredKeys ~= false then
        local mirrored = commandToKeyCode(mirrorCmd)
        if mirrored and mirrored > 0 then return mirrored end
    end
    local default = tonumber(bind.defaultKey) or 0
    return tonumber(cookie.GetNumber(keyPrefix .. tostring(bind.id or ""), default)) or default
end

local function setBindKey(bind, key)
    if not istable(bind) then return end
    cookie.Set(keyPrefix .. tostring(bind.id or ""), tostring(tonumber(key) or 0))
end

local function keyCodeToBindName(key)
    key = tonumber(key) or 0
    if key <= 0 then return nil end
    local n = input.GetKeyName(key)
    if not n or n == "" then return nil end
    return string.lower(n)
end

local function getGModBindName(bind)
    if not istable(bind) then return "AUCUNE" end
    local cmd = tostring(bind.command or "")
    if cmd == "" then return "AUCUNE" end
    local current = input.LookupBinding(cmd)
    if current and current ~= "" then return string.upper(current) end
    return "AUCUNE"
end

-- IMPORTANT : l'addon ne modifie plus les touches GMod du joueur.
-- Cette fonction ne fait qu'importer une touche GMod dans un bind Medal configurable.
local function importGModBindIntoMedal(gmodBind)
    if not istable(gmodBind) then return false end
    local targetID = tostring(gmodBind.serverBindID or gmodBind.medalBindID or gmodBind.mirrorTo or "")
    if targetID == "" then return false end
    local key = commandToKeyCode(gmodBind.command or "")
    if not key or key <= 0 then return false end
    for _, b in ipairs(cfg.Keybinds or {}) do
        if tostring(b.id or "") == targetID then
            setBindKey(b, key)
            if notification and notification.AddLegacy then notification.AddLegacy("Bind GMod importé dans Medal : " .. tostring(b.label or b.id), NOTIFY_GENERIC, 3) end
            return true
        end
    end
    return false
end

local function setGModBind(bind, key)
    -- Sécurité : ne jamais lancer bind <touche> <commande> depuis cette UI.
    if notification and notification.AddLegacy then notification.AddLegacy("Les binds GMod sont en lecture seule ici. Utilise Importer si tu veux copier cette touche dans un bind Medal.", NOTIFY_HINT, 4) end
    return false
end

local function resetGModBind(bind)
    return false
end

local function getConVarStringSafe(name, default)
    local cv = GetConVar(tostring(name or ""))
    if not cv then return tostring(default or "") end
    return cv:GetString()
end

local function setConVarSafe(name, value, setting)
    name = tostring(name or "")
    if name == "" then return false end

    local blocked = (setting and setting.readOnly) or (cfg.BlockedConVars and cfg.BlockedConVars[name])
    if blocked then
        local reason = (setting and setting.blockedReason) or "Ce réglage est bloqué par GMod sur ce serveur."
        if notification and notification.AddLegacy then notification.AddLegacy(reason, NOTIFY_ERROR, 3) end
        return false
    end

    -- Méthode la plus sûre : modifier la ConVar client directement lorsque c'est possible,
    -- au lieu de passer par RunConsoleCommand, qui déclenche "Command is blocked" sur certaines convars.
    local cv = GetConVar(name)
    if cv and cv.SetString then
        local ok = pcall(function() cv:SetString(tostring(value)) end)
        if ok then return true end
    end

    local ok = pcall(function() RunConsoleCommand(name, tostring(value)) end)
    if not ok then
        if notification and notification.AddLegacy then notification.AddLegacy("Impossible d'appliquer le réglage : " .. name, NOTIFY_ERROR, 3) end
        return false
    end
    return true
end

local function runBindAction(bind)
    if not istable(bind) then return end
    local action = tostring(bind.action or bind.id or "")
    if action == "open_main_menu" then
        MedalBarracks.OpenMainMenu("main", false)
    elseif action == "open_barracks" then
        MedalBarracks.Open()
    elseif action == "present" then
        RunConsoleCommand((cfg.Relations and cfg.Relations.PresentConsoleCommand) or "medal_present")
    elseif action ~= "" and isstring(bind.command) and bind.command ~= "" then
        RunConsoleCommand(bind.command)
    end
end

local function paintIconMaterial(path, x, y, w, h, fallbackText)
    local m = mat(path or "")
    if m then
        surface.SetMaterial(m)
        surface.SetDrawColor(255,255,255,230)
        surface.DrawTexturedRect(x, y, w, h)
    else
        draw.SimpleText(fallbackText or "◎", "MedalBarracks_Icon", x + w / 2, y + h / 2, C("White"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function drawHLLButton(self, w, h, text, sub, selected, accent, leftAlign)
    self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim or 0, (self:IsHovered() or selected) and 1 or 0)
    accent = accent or C("Red", Color(190, 28, 28))
    local hov = self.hoverAnim

    local da = cfg.DAStyle or {}
    local baseA = (tonumber(da.ButtonAlpha) or 150) + hov * ((tonumber(da.ButtonHoverAlpha) or 188) - (tonumber(da.ButtonAlpha) or 150))

    -- Panneau sombre translucide façon HLL, éclairci au survol.
    surface.SetDrawColor(7, 8, 10, baseA)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(16, 17, 20, 85 + hov * 45)
    surface.DrawRect(0, 0, w, h)

    -- Liseré rouge toujours visible, légèrement épaissi au survol.
    local stripe = S(tonumber(da.RedStripeWidth) or 4) + math.Round(hov * S(2))
    draw.RoundedBox(0, 0, 0, stripe, h, Color(accent.r, accent.g, accent.b, selected and 255 or math.min(215 + hov * 40, 255)))

    -- Filets fins, pas de gros bouton brillant.
    surface.SetDrawColor(255, 255, 255, selected and 135 or ((tonumber(da.ButtonBorderAlpha) or 58) + hov * 70))
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    surface.SetDrawColor(255, 255, 255, 8 + hov * 20)
    surface.DrawRect(stripe, 0, w - stripe, 1)
    surface.SetDrawColor(0, 0, 0, 120)
    surface.DrawRect(stripe, h - 1, w - stripe, 1)

    -- Balayage lumineux discret au survol.
    if hov > 0.02 then
        surface.SetDrawColor(255, 255, 255, 11 * hov)
        surface.DrawRect(stripe, 0, (w - stripe) * hov, h)
    end

    local hasSub = sub and sub ~= ""
    local textCol = Color(245, 245, 245, math.min(225 + hov * 30, 255))
    if leftAlign == false then
        drawSpacedText(text, "MedalBarracks_H1", w / 2, hasSub and S(12) or h / 2, textCol, S(3), TEXT_ALIGN_CENTER, hasSub and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
        if hasSub then drawSpacedText(sub, "MedalBarracks_Row", w / 2, S(43), Color(235, 235, 235, 150 + hov * 60), S(2), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP) end
    else
        -- Texte qui glisse légèrement vers la droite au survol + chevron, comme sur HLL.
        local x = S((cfg.MainMenuStyle and cfg.MainMenuStyle.ButtonTextInset) or 34) + math.Round(hov * S(6))
        drawSpacedText(text, "MedalBarracks_H1", x, hasSub and S(12) or h / 2, textCol, S(3), TEXT_ALIGN_LEFT, hasSub and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
        if hasSub then drawSpacedText(sub, "MedalBarracks_Row", x + S(2), S(43), Color(235, 235, 235, 150 + hov * 60), S(2), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) end
        if hov > 0.05 and (not isstring(text) or text ~= "") then
            draw.SimpleText("›", "MedalBarracks_H1", w - S(26) + math.Round(hov * S(5)), h / 2, Color(accent.r, accent.g, accent.b, 210 * hov), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

local function createButton(parent, text, sub, x, y, w, h, selectedFn, onClick, accentFn)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetPos(x, y)
    b:SetSize(w, h)
    b.Paint = function(self, pw, ph)
        drawHLLButton(self, pw, ph, text, sub, selectedFn and selectedFn() or false, accentFn and accentFn() or C("Red", Color(190,30,30)))
    end
    b.DoClick = function()
        playButtonSound((cfg.Sounds or {}).UIClick)
        if onClick then onClick(b) end
    end
    return b
end

function MedalBarracks.RequestCharacters()
    net.Start("MedalBarracks_RequestCharacters")
    net.SendToServer()
end

function MedalBarracks.MakeTransition(title, subtitle, callback, soundKind, mediaKey)
    if mediaKey and MedalBarracks.PlayRemoteCinematic and MedalBarracks.PlayRemoteCinematic(mediaKey, function()
        MedalBarracks.MakeTransition(title, subtitle, callback, soundKind, nil)
    end, title, subtitle, nil) then
        return
    end

    local anim = cfg.Animations or {}
    local dur = anim.Enabled == false and 0.05 or (tonumber(anim.TransitionDuration) or 0.7)
    local p = vgui.Create("DPanel")
    p:SetSize(ScrW(), ScrH())
    p:SetPos(0, 0)
    p:SetMouseInputEnabled(false)
    p:SetKeyboardInputEnabled(false)
    p:SetAlpha(0)
    p:AlphaTo(255, dur * 0.35, 0)
    p.start = SysTime()
    p.Paint = function(self, w, h)
        local t = math.Clamp((SysTime() - self.start) / dur, 0, 1)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 170 + 65 * math.sin(t * math.pi)))
        for i = 1, 7 do
            local off = (t * ScrW() * 1.35 + i * S(190)) % (ScrW() + S(220))
            draw.RoundedBox(0, off - S(120), 0, S(7), h, Color(190, 28, 28, 70))
        end
        draw.RoundedBox(0, 0, h * 0.48, w * t, S(2), C("Red", Color(190,28,28)))
        draw.SimpleText(title or "TRANSMISSION", "MedalBarracks_CardTitle", w / 2, h / 2 - S(25), C("White"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if subtitle and subtitle ~= "" then draw.SimpleText(subtitle, "MedalBarracks_Row", w / 2, h / 2 + S(18), Color(235,235,235,180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
    end
    local sounds = cfg.Sounds or {}
    playSound(soundKind == "war" and sounds.WarTransition or sounds.RadioTransition)
    timer.Simple(dur, function()
        if IsValid(p) then p:AlphaTo(0, dur * 0.25, 0, function(_, pnl) if IsValid(pnl) then pnl:Remove() end end) end
        if callback then callback() end
    end)
end

local function characterFor(armyID)
    return MedalBarracks.ClientCharacters and MedalBarracks.ClientCharacters[armyID]
end

local function defaultCharModel(army)
    if not army then return "models/player/Group03/male_07.mdl" end
    return army.characterModel or (army.characterModels and army.characterModels[1]) or "models/player/Group03/male_07.mdl"
end

local function drawTitleLeft(menuCfg)
    local style = cfg.MainMenuStyle or {}
    local x = S(tonumber(style.TitleX) or 132)
    local y = S(tonumber(style.TitleY) or 275)
    -- "BIENVENUE SUR" très espacé, comme sur l'image de référence.
    drawSpacedText(menuCfg.Subtitle or "BIENVENUE SUR", "MedalBarracks_MenuSubtitle", x + S(3), y, Color(235, 235, 235, 175), S(8))
    draw.SimpleText(string.upper(menuCfg.Title or "MEDAL VIETNAM"), "MedalBarracks_MenuTitle", x, y + S(26), Color(245, 245, 245, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.RoundedBox(0, x + S(3), y + S(100), S(340), S(2), C("Red", Color(190, 28, 28)))
    local serverLine = menuCfg.ServerLine or "GARRY'S MOD - SERVEUR VIETNAM WAR RP"
    if serverLine and serverLine ~= "" then
        drawSpacedText(serverLine, "MedalBarracks_MenuSubtitle", x + S(3), S(tonumber(style.ServerLineY) or 405), Color(235, 235, 235, 140), S(3))
    end
end

function MedalBarracks.OpenCharacterEditor(armyID, editing)
    local army = MedalBarracks.GetArmy(armyID)
    if not army then return end
    local existing = characterFor(armyID)
    local frame = vgui.Create("DFrame")
    frame:SetSize(S(560), S(620))
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.14, 0)

    local function label(txt, y)
        local l = vgui.Create("DLabel", frame)
        l:SetPos(S(38), y)
        l:SetSize(S(480), S(20))
        l:SetFont("MedalBarracks_InputLabel")
        l:SetTextColor(Color(235,235,235,220))
        l:SetText(txt)
        return l
    end

    local function entry(y, value, editable, tall)
        local e = vgui.Create("DTextEntry", frame)
        e:SetPos(S(38), y)
        e:SetSize(S(485), tall or S(34))
        e:SetFont("MedalBarracks_Row")
        e:SetText(value or "")
        e:SetEditable(editable ~= false)
        e:SetUpdateOnType(true)
        if tall then e:SetMultiline(true) end
        return e
    end

    frame.Paint = function(self, w, h)
        drawBlurPanel(self, 6)
        draw.RoundedBox(0, 0, 0, w, h, Color(8,8,10,238))
        draw.RoundedBox(0, 0, 0, S(6), h, army.accent or C("Accent"))
        surface.SetDrawColor(255,255,255,60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(editing and "MODIFIER LE PERSONNAGE" or "CRÉER LE PERSONNAGE", "MedalBarracks_CardTitle", S(38), S(28), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        if editing then draw.SimpleText("Nom et prénom verrouillés après création.", "MedalBarracks_Row", S(38), S(67), Color(235,235,235,160), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) end
    end

    label("PRÉNOM", S(112))
    local first = entry(S(136), existing and existing.firstName or "", not editing)
    label("NOM", S(180))
    local last = entry(S(204), existing and existing.lastName or "", not editing)
    label("ÂGE", S(248))
    local age = entry(S(272), existing and tostring(existing.age or 18) or "18", true)
    label("NATIONALITÉ / ORIGINE", S(316))
    local nat = entry(S(340), existing and existing.nationality or (armyID == "americans" and "Américaine" or "Vietnamienne"), true)
    label("DESCRIPTION", S(384))
    local desc = entry(S(408), existing and existing.description or "", true, S(94))

    local model = existing and existing.model or defaultCharModel(army)
    if (cfg.CharacterCreation or {}).AllowModelChoice == true and istable(army.characterModels) then
        label("MODÈLE", S(512))
        local combo = vgui.Create("DComboBox", frame)
        combo:SetPos(S(38), S(536))
        combo:SetSize(S(485), S(32))
        for _, mdl in ipairs(army.characterModels) do combo:AddChoice(mdl, mdl, mdl == model) end
        combo.OnSelect = function(_, _, _, data) model = data end
    end

    local cancel = vgui.Create("DButton", frame)
    cancel:SetText("")
    cancel:SetPos(S(38), S(552))
    cancel:SetSize(S(170), S(46))
    cancel.Paint = function(self, w, h) drawHLLButton(self, w, h, "RETOUR", "", false, C("Red", Color(190,30,30)), false) end
    cancel.DoClick = function() playButtonSound((cfg.Sounds or {}).UIBack); frame:Remove() end

    local save = vgui.Create("DButton", frame)
    save:SetText("")
    save:SetPos(S(225), S(552))
    save:SetSize(S(298), S(46))
    save.Paint = function(self, w, h) drawHLLButton(self, w, h, editing and "ENREGISTRER" or "CRÉER", "", false, army.accent or C("Accent"), false) end
    save.DoClick = function()
        local a = math.Clamp(tonumber(age:GetText()) or 18, 0, 120)
        if editing then
            net.Start("MedalBarracks_UpdateCharacter")
                net.WriteString(armyID)
                net.WriteUInt(a, 8)
                net.WriteString(nat:GetText() or "")
                net.WriteString(desc:GetText() or "")
                net.WriteString(model or defaultCharModel(army))
            net.SendToServer()
        else
            net.Start("MedalBarracks_CreateCharacter")
                net.WriteString(armyID)
                net.WriteString(first:GetText() or "")
                net.WriteString(last:GetText() or "")
                net.WriteUInt(a, 8)
                net.WriteString(nat:GetText() or "")
                net.WriteString(desc:GetText() or "")
                net.WriteString(model or defaultCharModel(army))
            net.SendToServer()
        end
        frame:Remove()
    end
end

function MedalBarracks.OpenCharacterSelection(armyID, slide)
    MedalBarracks.StartMenuAmbient()
    if IsValid(MedalBarracks.CharacterFrame) then MedalBarracks.CharacterFrame:Remove() end
    if IsValid(MedalBarracks.MainFrame) then MedalBarracks.MainFrame:Remove() end
    if IsValid(MedalBarracks.Frame) then MedalBarracks.Frame:Remove() end

    local army = MedalBarracks.GetArmy(armyID)
    if not army then MedalBarracks.OpenMainMenu("factions", true); return end

    local frame = vgui.Create("DFrame")
    MedalBarracks.CharacterFrame = frame
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(slide and ScrW() or 0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame.OnRemove = scheduleMenuAmbientStop
    frame.state = "character"
    frame:SetAlpha(255)
    if slide then frame:MoveTo(0, 0, (cfg.Animations and cfg.Animations.SlideDuration) or 0.34, 0, -1) end

    do
        local rm = cfg.RemoteMedia or {}
        local bgKey = rm.Usage and rm.Usage.CharacterBackground
        if bgKey and MedalBarracks.SetBackgroundVideo then MedalBarracks.SetBackgroundVideo(frame, bgKey) end
    end

    local st = cfg.CharacterMenuStyle or {}
    local cardX = S(tonumber(st.CardX) or 120)
    local cardY = S(tonumber(st.CardY) or 210)
    local cardW = S(tonumber(st.CardW) or 500)
    local cardH = math.min(S(tonumber(st.CardH) or 680), ScrH() - cardY - S(145))
    local infoX = S(tonumber(st.InfoX) or 675)
    local infoY = S(tonumber(st.InfoY) or 230)
    local infoW = math.min(S(tonumber(st.InfoW) or 900), ScrW() - infoX - S(110))
    local infoH = S(tonumber(st.InfoH) or 520)
    local charModelPanel

    local function refreshModel()
        local existing = characterFor(armyID)
        if IsValid(charModelPanel) then charModelPanel:Remove() end
        if not existing then return end
        charModelPanel = vgui.Create("DModelPanel", frame)
        local cp = cfg.CharacterPreview or {}
        local topPad = S(tonumber(cp.PanelTop) or 38)
        local bottomSpace = S(tonumber(cp.PanelBottomSpace) or 190)
        charModelPanel:SetPos(cardX + S(22), cardY + topPad)
        charModelPanel:SetSize(cardW - S(44), math.max(S(320), cardH - topPad - bottomSpace))
        charModelPanel:SetModel(existing.model or defaultCharModel(army))
        charModelPanel:SetFOV(tonumber(cp.FOV) or 30)
        charModelPanel:SetCamPos(cp.CamPos or Vector(145, 18, 58))
        charModelPanel:SetLookAt(cp.LookAt or Vector(0, 0, 42))
        charModelPanel:SetMouseInputEnabled(false)
        charModelPanel:SetZPos(60)
        charModelPanel.LayoutEntity = function(self, ent)
            ent:SetAngles(Angle(0, (tonumber(cp.EntityYaw) or 24) + math.sin(CurTime() * 0.25) * 4, 0))
            self:RunAnimation()
        end
    end

    frame.Refresh = refreshModel
    refreshModel()

    frame.Paint = function(self, w, h)
        drawFrameBackground(self, w, h)
        -- Overlay lourd à gauche et léger sur toute la page, pour garder la DA du menu principal.
        draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,92))
        for i = 0, 24 do
            local t = i / 24
            draw.RoundedBox(0, i * S(34), 0, S(36), h, Color(0,0,0, math.max(0, 238 * ((1 - t) ^ 1.8))))
        end

        local accent = army.accent or C("Accent")
        drawHLLHeader(w, "MEDAL VIETNAM // " .. string.upper(army.cardName or army.menuName or army.name or armyID),
            tostring(st.Title or "DOSSIER DE DÉPLOIEMENT"),
            tostring(st.Subtitle or "IDENTITÉ OPÉRATIONNELLE"), accent)
        drawHLLFooter(w, h, "RETOUR AU CHOIX DE FACTION")

        local existing = characterFor(armyID)
        -- Carte personnage façon carte d'équipement avant départ.
        draw.RoundedBox(0, cardX, cardY, cardW, cardH, Color(5,5,7,218))
        surface.SetDrawColor(existing and Color(235,235,235,185) or Color(235,235,235,78))
        surface.DrawOutlinedRect(cardX, cardY, cardW, cardH, existing and S(2) or 1)
        surface.SetDrawColor(255,255,255,28)
        surface.DrawOutlinedRect(cardX + S(10), cardY + S(10), cardW - S(20), cardH - S(20), 1)
        draw.RoundedBox(0, cardX, cardY, S(5), cardH, Color(accent.r, accent.g, accent.b, 220))
        for i = 0, 18 do draw.RoundedBox(0, cardX, cardY + cardH - S(210) + i * S(13), cardW, S(14), Color(0,0,0, math.Clamp(45 + i * 13, 0, 240))) end

        if not existing then
            draw.SimpleText("+", "MedalBarracks_CardPlus", cardX + cardW / 2, cardY + cardH / 2 - S(55), Color(245,245,245,210), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("NOUVEL OPÉRATEUR", "MedalBarracks_CardTitle", cardX + cardW / 2, cardY + cardH - S(145), C("White"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            drawWrappedText("Clique sur la carte pour créer ton personnage avant le déploiement.", "MedalBarracks_CardBody", cardX + cardW / 2, cardY + cardH - S(96), cardW - S(70), Color(235,235,235,170), TEXT_ALIGN_CENTER)
        else
            local fullname = string.upper((existing.firstName or "") .. " " .. (existing.lastName or ""))
            draw.SimpleText(fullname, "MedalBarracks_CardTitle", cardX + cardW / 2, cardY + cardH - S(150), C("White"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText("ÂGE " .. tostring(existing.age or "?") .. "  •  " .. tostring(existing.nationality or ""), "MedalBarracks_Row", cardX + cardW / 2, cardY + cardH - S(108), Color(235,235,235,168), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText("PRÊT POUR DÉPLOIEMENT", "MedalBarracks_RowSmall", cardX + cardW / 2, cardY + S(18), Color(accent.r, accent.g, accent.b, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        -- Panneau de briefing / consignes.
        draw.RoundedBox(0, infoX, infoY, infoW, infoH, Color(5, 5, 7, 178))
        surface.SetDrawColor(255,255,255,45)
        surface.DrawOutlinedRect(infoX, infoY, infoW, infoH, 1)
        draw.RoundedBox(0, infoX, infoY, S(5), infoH, Color(accent.r, accent.g, accent.b, 220))
        draw.SimpleText("PRÉPARATION AU FRONT", "MedalBarracks_CardTitle", infoX + S(34), infoY + S(32), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("DOSSIER PERSONNEL", "MedalBarracks_Row", infoX + S(36), infoY + S(82), Color(235,235,235,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if not existing then
            drawWrappedText("Aucun personnage n'a encore été créé pour ce camp. Tu dois créer une identité avant de pouvoir accéder aux rôles et au spawn.", "MedalBarracks_Row", infoX + S(36), infoY + S(130), infoW - S(80), Color(235,235,235,190), TEXT_ALIGN_LEFT)
            draw.SimpleText("STATUT : EN ATTENTE DE CRÉATION", "MedalBarracks_H2", infoX + S(36), infoY + infoH - S(92), Color(230, 90, 90, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        else
            draw.SimpleText("Nom complet", "MedalBarracks_RowSmall", infoX + S(36), infoY + S(130), Color(235,235,235,120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(string.upper((existing.firstName or "") .. " " .. (existing.lastName or "")), "MedalBarracks_H2", infoX + S(36), infoY + S(154), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Origine / nationalité", "MedalBarracks_RowSmall", infoX + S(36), infoY + S(208), Color(235,235,235,120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(existing.nationality or "Non renseigné"), "MedalBarracks_Row", infoX + S(36), infoY + S(232), Color(235,235,235,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Description", "MedalBarracks_RowSmall", infoX + S(36), infoY + S(288), Color(235,235,235,120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            drawWrappedText(tostring(existing.description or "Aucune description."), "MedalBarracks_Row", infoX + S(36), infoY + S(316), infoW - S(80), Color(235,235,235,180), TEXT_ALIGN_LEFT)
            draw.SimpleText("STATUT : JOUER ET MODIFIER DÉBLOQUÉS", "MedalBarracks_H2", infoX + S(36), infoY + infoH - S(92), Color(accent.r, accent.g, accent.b, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Nom et prénom verrouillés après création.", "MedalBarracks_RowSmall", infoX + S(36), infoY + infoH - S(54), Color(235,235,235,130), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    local hit = vgui.Create("DButton", frame)
    hit:SetText("")
    hit:SetPos(cardX, cardY)
    hit:SetSize(cardW, cardH)
    hit.Paint = function() end
    hit.DoClick = function()
        if not characterFor(armyID) then MedalBarracks.OpenCharacterEditor(armyID, false) end
    end

    -- Barre d'action HLL : RETOUR à gauche, actions principales à droite.
    local bottomY = ScrH() - S(100)
    local back = createButton(frame, "RETOUR", "", S(72), bottomY, S(230), S(56), nil, function()
        MedalBarracks.OpenMainMenu("factions", false)
    end)
    local edit = createButton(frame, "MODIFIER", "Dossier", ScrW() - S(72) - S(300) - S(232), bottomY, S(210), S(56), nil, function()
        if characterFor(armyID) then MedalBarracks.OpenCharacterEditor(armyID, true) end
    end, function() return army.accent or C("Accent") end)
    local play = createButton(frame, "DÉPLOYER", "Choisir un rôle", ScrW() - S(72) - S(300), bottomY, S(300), S(56), nil, function()
        if not characterFor(armyID) then
            notification.AddLegacy("Crée ton personnage avant de jouer.", NOTIFY_ERROR, 4)
            return
        end
        local rm = cfg.RemoteMedia or {}
        MedalBarracks.MakeTransition("DÉPLOIEMENT", "Briefing radio en cours", function()
            MedalBarracks.Open(armyID, true)
        end, "war", rm.Usage and rm.Usage.CharacterToRolesCinematic)
    end, function() return army.accent or C("Accent") end)

    edit.Paint = function(self, w, h)
        local ok = characterFor(armyID) ~= nil
        drawHLLButton(self, w, h, "MODIFIER", "Dossier", false, ok and (army.accent or C("Accent")) or Color(80,80,80), false)
        if not ok then draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,130)) end
    end
    play.Paint = function(self, w, h)
        local ok = characterFor(armyID) ~= nil
        drawHLLButton(self, w, h, "DÉPLOYER", "Choisir un rôle", false, ok and (army.accent or C("Accent")) or Color(80,80,80), false)
        if not ok then draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,130)) end
    end
end


local function campBalanceCfg()
    return cfg.CampBalance or {}
end

local function campMaxPlayers()
    return tonumber(campBalanceCfg().MaxPlayersPerFaction) or 60
end

local function campCount(armyID)
    return GetGlobalInt("MedalBarracks_Count_" .. tostring(armyID or ""), 0)
end

local function projectedCampCounts(targetArmyID)
    local counts = {}
    for _, army in ipairs(MedalBarracks.GetArmies()) do
        counts[army.id] = campCount(army.id)
    end

    local current = LocalPlayer():GetNWString("MedalBarracks_ArmyChoice", "")
    if current ~= "" and counts[current] then counts[current] = math.max(0, counts[current] - 1) end
    if targetArmyID and targetArmyID ~= "" then counts[targetArmyID] = (counts[targetArmyID] or 0) + 1 end
    return counts
end

local function canJoinCampClient(armyID)
    local b = campBalanceCfg()
    if b.Enabled == false then return true, "", campCount(armyID), campMaxPlayers() end

    local max = campMaxPlayers()
    local counts = projectedCampCounts(armyID)
    local targetCount = counts[armyID] or 0

    if b.BlockWhenFull ~= false and targetCount > max then
        return false, "Faction complète", targetCount - 1, max
    end

    local minOther
    for _, army in ipairs(MedalBarracks.GetArmies()) do
        if army.id ~= armyID then
            local c = counts[army.id] or 0
            minOther = minOther and math.min(minOther, c) or c
        end
    end

    if minOther and (targetCount - minOther) > (tonumber(b.Tolerance) or 2) then
        return false, b.BlockedText or "ÉQUILIBRAGE EN COURS", targetCount - 1, max
    end

    return true, "", targetCount - 1, max
end

local function notifyLocal(msg, isError)
    if notification and notification.AddLegacy then
        notification.AddLegacy(tostring(msg or ""), isError and NOTIFY_ERROR or NOTIFY_GENERIC, 3)
    end
end

function MedalBarracks.OpenMainMenu(initialState, force)
    MedalBarracks.StartMenuAmbient()
    if IsValid(MedalBarracks.MainFrame) then MedalBarracks.MainFrame:Remove() end
    if IsValid(MedalBarracks.Frame) then MedalBarracks.Frame:Remove() end
    if IsValid(MedalBarracks.CharacterFrame) then MedalBarracks.CharacterFrame:Remove() end

    MedalBarracks.RequestCharacters()

    local menuCfg = cfg.MainMenu or {}
    local frame = vgui.Create("DFrame")
    MedalBarracks.MainFrame = frame
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame.OnRemove = scheduleMenuAmbientStop
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.20, 0)
    frame.state = initialState or "main"
    frame.content = {}
    frame.mainButtons = {}
    frame.linkButtons = {}

    do
        local rm = cfg.RemoteMedia or {}
        local bgKey = rm.Usage and rm.Usage.MainMenuBackground
        if bgKey and MedalBarracks.SetBackgroundVideo then MedalBarracks.SetBackgroundVideo(frame, bgKey) end
    end

    local function clearContent()
        for _, p in ipairs(frame.content) do if IsValid(p) then p:Remove() end end
        frame.content = {}
        editingBind = nil
    end
    local function addContent(p) table.insert(frame.content, p); return p end

    local function setMainVisible(visible)
        for _, b in ipairs(frame.mainButtons or {}) do if IsValid(b) then b:SetVisible(visible) end end
        for _, b in ipairs(frame.linkButtons or {}) do if IsValid(b) then b:SetVisible(visible) end end
    end

    local function backToMain()
        clearContent()
        frame.state = "main"
        local rm = cfg.RemoteMedia or {}
        if MedalBarracks.SetBackgroundVideo and rm.Usage and rm.Usage.MainMenuBackground then MedalBarracks.SetBackgroundVideo(frame, rm.Usage.MainMenuBackground) end
        setMainVisible(true)
    end

    local function createLinkButton(iconPath, url, x, y, tooltip, fallback, label)
        local b = vgui.Create("DButton", frame)
        b:SetText("")
        local bw = label and S(142) or S(42)
        b:SetPos(x, y)
        b:SetSize(bw, S(42))
        b:SetTooltip(tooltip or "")
        b.Paint = function(self, w, h)
            self.hoverAnim = Lerp(FrameTime() * 8, self.hoverAnim or 0, self:IsHovered() and 1 or 0)
            draw.RoundedBox(0, 0, 0, w, h, Color(5,5,7,55 + self.hoverAnim * 70))
            if self:IsHovered() then
                surface.SetDrawColor(255,255,255,32 + self.hoverAnim * 72)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            paintIconMaterial(iconPath, S(8), S(8), S(26), S(26), fallback)
            if label then
                drawSpacedText(label, "MedalBarracks_Row", S(42), h / 2, Color(235, 235, 235, 160 + self.hoverAnim * 70), S(2), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
        b.DoClick = function()
            if url and url ~= "" then gui.OpenURL(url) end
        end
        table.insert(frame.linkButtons, b)
        return b
    end

    local function showQuitConfirm()
        local overlay = addContent(vgui.Create("DPanel", frame))
        overlay:SetSize(ScrW(), ScrH())
        overlay:SetPos(0, 0)
        overlay:SetZPos(600)
        overlay:SetAlpha(0)
        overlay:AlphaTo(255, 0.12, 0)
        overlay.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,195))
            local bw, bh = S(560), S(230)
            local x, y = w / 2 - bw / 2, h / 2 - bh / 2
            draw.RoundedBox(0, x, y, bw, bh, Color(8,8,10,240))
            draw.RoundedBox(0, x, y, S(6), bh, C("Red", Color(190,30,30)))
            surface.SetDrawColor(255,255,255,70)
            surface.DrawOutlinedRect(x, y, bw, bh, 1)
            drawSpacedText("QUITTER LE SERVEUR ?", "MedalBarracks_CardTitle", w / 2, y + S(34), C("White"), S(3), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            drawWrappedText("Tu vas être déconnecté du serveur. Confirmer l'action ?", "MedalBarracks_Row", w / 2, y + S(88), bw - S(70), Color(235,235,235,180), TEXT_ALIGN_CENTER)
        end
        local bw, bh = S(560), S(230)
        local x, y = ScrW() / 2 - bw / 2, ScrH() / 2 - bh / 2
        createButton(overlay, "ANNULER", "", x + S(48), y + S(155), S(210), S(52), nil, function() overlay:Remove() end, function() return Color(130,130,130) end)
        createButton(overlay, "CONFIRMER", "", x + S(300), y + S(155), S(210), S(52), nil, function() RunConsoleCommand("disconnect") end, function() return C("Red", Color(190,30,30)) end)
    end

    local function showOptions()
        clearContent()
        frame.state = "options"
        do
            local rm = cfg.RemoteMedia or {}
            if MedalBarracks.SetBackgroundVideo and rm.Usage and rm.Usage.OptionsBackground then MedalBarracks.SetBackgroundVideo(frame, rm.Usage.OptionsBackground) end
        end
        setMainVisible(false)

        local page = addContent(vgui.Create("DPanel", frame))
        page:SetSize(ScrW(), ScrH())
        page:SetPos(0, ScrH())
        page:SetZPos(120)
        page:MoveTo(0, 0, (cfg.Animations and cfg.Animations.SlideDuration) or 0.34, 0, -1)

        local activeTab = "medal"
        local list
        local tabs = {
            {id = "medal", label = "BINDS MEDAL"},
            {id = "gmod", label = "BINDS GMOD"},
            {id = "graphics", label = "GRAPHIQUES"},
        }

        page.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,92))
            for i = 0, 10 do draw.RoundedBox(0, 0, 0, w, S(80) + i * S(18), Color(0,0,0,math.max(0,115 - i * 9))) end
            drawHLLHeaderCentered(w, "OPTIONS", nil)
            drawHLLFooter(w, h, "RETOUR AU MENU PRINCIPAL")
            local help = ""
            if editingBind then
                help = "Appuie sur une touche pour remplacer le bind sélectionné. ÉCHAP pour annuler."
            elseif activeTab == "gmod" then
                help = "Binds GMod natifs récupérés depuis tes paramètres actuels. Lecture seule : l'addon ne modifie jamais tes touches GMod."
            elseif activeTab == "graphics" then
                help = "Paramètres graphiques client appliqués via convars GMod. Certains peuvent nécessiter un reconnect/changement de map."
            else
                help = "Binds propres à l'addon Medal Vietnam."
            end
            draw.SimpleText(help, "MedalBarracks_Row", w / 2, S(100), Color(235,235,235,185), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        local tabY = S(126)
        local tabW, tabH = S(250), S(54)
        local totalTabW = #tabs * tabW + (#tabs - 1) * S(12)
        local tabStart = ScrW() / 2 - totalTabW / 2

        local function rebuild()
            if not IsValid(list) then return end
            list:Clear()

            if activeTab == "medal" then
                for _, bind in ipairs(cfg.Keybinds or {}) do
                    local row = vgui.Create("DButton", list)
                    row:Dock(TOP)
                    row:DockMargin(0, 0, 0, S(10))
                    row:SetTall(S(76))
                    row:SetText("")
                    row.Paint = function(self, w, h)
                        local selected = editingBind == bind
                        drawHLLButton(self, w, h, "", "", selected, selected and C("Accent") or C("Red", Color(190,30,30)))
                        draw.SimpleText(string.upper(bind.label or bind.id or "BIND"), "MedalBarracks_H2", S(26), S(13), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText(bind.description or "", "MedalBarracks_RowSmall", S(26), S(43), Color(235,235,235,160), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        local key = getBindKey(bind)
                        local boxW = S(190)
                        draw.RoundedBox(0, w - boxW - S(18), S(15), boxW, h - S(30), selected and Color(198,181,94,190) or Color(8,8,10,210))
                        surface.SetDrawColor(255,255,255, selected and 150 or 60)
                        surface.DrawOutlinedRect(w - boxW - S(18), S(15), boxW, h - S(30), 1)
                        draw.SimpleText(selected and "..." or keyName(key), "MedalBarracks_H2", w - boxW / 2 - S(18), h / 2, C("White"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    row.DoClick = function()
                        editingBind = bind
                        rebuild()
                    end
                end
            elseif activeTab == "gmod" then
                for _, bind in ipairs(cfg.GModBinds or {}) do
                    local row = vgui.Create("DButton", list)
                    row:Dock(TOP)
                    row:DockMargin(0, 0, 0, S(10))
                    row:SetTall(S(76))
                    row:SetText("")
                    row.Paint = function(self, w, h)
                        local selected = istable(editingBind) and editingBind.__gmod == true and editingBind.command == bind.command
                        drawHLLButton(self, w, h, "", "", selected, selected and C("Accent") or C("Red", Color(190,30,30)))
                        draw.SimpleText(string.upper(bind.label or bind.id or bind.command or "BIND GMOD"), "MedalBarracks_H2", S(26), S(13), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText("Commande : " .. tostring(bind.command or ""), "MedalBarracks_RowSmall", S(26), S(43), Color(235,235,235,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        local boxW = S(210)
                        draw.RoundedBox(0, w - boxW - S(18), S(15), boxW, h - S(30), selected and Color(198,181,94,190) or Color(8,8,10,210))
                        surface.SetDrawColor(255,255,255, selected and 150 or 60)
                        surface.DrawOutlinedRect(w - boxW - S(18), S(15), boxW, h - S(30), 1)
                        draw.SimpleText(selected and "..." or getGModBindName(bind), "MedalBarracks_H2", w - boxW / 2 - S(18), h / 2, C("White"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    row.DoClick = function()
                        if not importGModBindIntoMedal(bind) then
                            if notification and notification.AddLegacy then
                                notification.AddLegacy("Lecture seule : l'addon récupère tes binds GMod, mais ne modifie pas tes touches.", NOTIFY_HINT, 4)
                            end
                        end
                        rebuild()
                    end
                end
            else
                for _, setting in ipairs(cfg.GraphicsSettings or {}) do
                    local pnl = vgui.Create("DPanel", list)
                    pnl:Dock(TOP)
                    pnl:DockMargin(0, 0, 0, S(10))
                    pnl:SetTall(S(92))
                    pnl.Paint = function(self, w, h)
                        draw.RoundedBox(0, 0, 0, w, h, Color(9, 9, 11, 185))
                        draw.RoundedBox(0, 0, 0, S(5), h, C("Red", Color(190,30,30)))
                        surface.SetDrawColor(255,255,255,45)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                        draw.SimpleText(string.upper(setting.label or setting.id or setting.convar or "RÉGLAGE"), "MedalBarracks_H2", S(26), S(14), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                        draw.SimpleText("ConVar : " .. tostring(setting.convar or ""), "MedalBarracks_RowSmall", S(26), S(48), Color(235,235,235,135), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    end

                    local isBlockedSetting = setting.readOnly == true or (cfg.BlockedConVars and setting.convar and cfg.BlockedConVars[setting.convar])
                    if isBlockedSetting then
                        local btn = vgui.Create("DButton", pnl)
                        btn:SetText("")
                        btn:SetPos(S(620), S(20))
                        btn:SetSize(S(300), S(52))
                        btn.Paint = function(self, w, h)
                            drawHLLButton(self, w, h, "BLOQUÉ", "par GMod", false, Color(105,105,105), false)
                        end
                        btn.DoClick = function()
                            if notification and notification.AddLegacy then notification.AddLegacy(tostring(setting.blockedReason or "Ce réglage est bloqué par GMod."), NOTIFY_ERROR, 4) end
                        end
                    elseif setting.type == "bool" then
                        local btn = vgui.Create("DButton", pnl)
                        btn:SetText("")
                        btn:SetPos(S(660), S(20))
                        btn:SetSize(S(240), S(52))
                        btn.Paint = function(self, w, h)
                            local cur = getConVarStringSafe(setting.convar, setting.default) ~= "0"
                            drawHLLButton(self, w, h, cur and "ACTIVÉ" or "DÉSACTIVÉ", "", false, cur and C("Accent") or Color(105,105,105), false)
                        end
                        btn.DoClick = function()
                            local cur = getConVarStringSafe(setting.convar, setting.default) ~= "0"
                            setConVarSafe(setting.convar, cur and "0" or "1", setting)
                        end
                    elseif setting.type == "choice" then
                        local combo = vgui.Create("DComboBox", pnl)
                        combo:SetPos(S(660), S(28))
                        combo:SetSize(S(240), S(36))
                        combo:SetFont("MedalBarracks_Row")
                        local current = getConVarStringSafe(setting.convar, setting.default)
                        for _, choice in ipairs(setting.choices or {}) do
                            combo:AddChoice(choice.name or choice.value, tostring(choice.value), tostring(choice.value) == tostring(current))
                        end
                        combo.OnSelect = function(_, _, _, data)
                            setConVarSafe(setting.convar, data, setting)
                        end
                    else
                        local slider = vgui.Create("DNumSlider", pnl)
                        slider:SetPos(S(530), S(22))
                        slider:SetSize(S(390), S(48))
                        slider:SetText("")
                        slider:SetMin(tonumber(setting.min) or 0)
                        slider:SetMax(tonumber(setting.max) or 1)
                        slider:SetDecimals(tonumber(setting.decimals) or 0)
                        slider:SetValue(tonumber(getConVarStringSafe(setting.convar, setting.default)) or tonumber(setting.default) or 0)
                        slider.OnValueChanged = function(_, val)
                            local dec = tonumber(setting.decimals) or 0
                            local fmt = dec <= 0 and "%d" or ("%." .. dec .. "f")
                            setConVarSafe(setting.convar, string.format(fmt, val), setting)
                        end
                    end
                end
            end
        end

        for i, tab in ipairs(tabs) do
            local b = createButton(page, tab.label, "", tabStart + (i - 1) * (tabW + S(12)), tabY, tabW, tabH, function() return activeTab == tab.id end, function()
                activeTab = tab.id
                editingBind = nil
                rebuild()
            end, function() return activeTab == tab.id and C("Accent") or C("Red", Color(190,30,30)) end)
            b:SetZPos(180)
        end

        list = vgui.Create("DScrollPanel", page)
        list:SetPos(ScrW() / 2 - S(470), S(205))
        list:SetSize(S(940), ScrH() - S(345))
        frame.rebuildOptions = rebuild
        rebuild()

        local reset = createButton(page, "RÉINITIALISER", "Onglet actuel", ScrW() - S(72) - S(280), ScrH() - S(100), S(280), S(56), nil, function()
            if activeTab == "medal" then
                for _, bind in ipairs(cfg.Keybinds or {}) do setBindKey(bind, tonumber(bind.defaultKey) or 0) end
            elseif activeTab == "gmod" then
                for _, bind in ipairs(cfg.GModBinds or {}) do resetGModBind(bind) end
            elseif activeTab == "graphics" then
                for _, setting in ipairs(cfg.GraphicsSettings or {}) do if setting.convar and setting.default ~= nil then setConVarSafe(setting.convar, setting.default, setting) end end
            end
            editingBind = nil
            rebuild()
        end, function() return Color(120,120,120) end)
        reset:SetZPos(200)

        local back = createButton(page, "RETOUR", "", S(72), ScrH() - S(100), S(230), S(56), nil, backToMain)
        back:SetZPos(200)
    end

    local function showFactions()
        clearContent()
        frame.state = "factions"
        do
            local rm = cfg.RemoteMedia or {}
            if MedalBarracks.SetBackgroundVideo and rm.Usage and rm.Usage.FactionBackground then MedalBarracks.SetBackgroundVideo(frame, rm.Usage.FactionBackground) end
        end
        setMainVisible(false)

        local page = addContent(vgui.Create("DPanel", frame))
        page:SetSize(ScrW(), ScrH())
        page:SetPos(0, ScrH())
        page:SetZPos(100)
        page:SetAlpha(255)
        page:MoveTo(0, 0, (cfg.Animations and cfg.Animations.SlideDuration) or 0.34, 0, -1)

        local armies = MedalBarracks.GetArmies()
        local fcfg = cfg.FactionPage or {}
        local halfW = ScrW() / math.max(#armies, 1)

        page.Paint = function(self, w, h)
            -- La vidéo reste derrière. Ce voile façon menu de jeu garde la lecture du texte.
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 86))
            for i = 0, 16 do
                draw.RoundedBox(0, 0, i * S(15), w, S(18), Color(0, 0, 0, math.max(0, 120 - i * 7)))
                draw.RoundedBox(0, 0, h - (i + 1) * S(16), w, S(18), Color(0, 0, 0, math.max(0, 130 - i * 7)))
            end
        end

        -- En-tête et barre d'action dessinés AU-DESSUS des cartes faction plein écran.
        page.PaintOver = function(self, w, h)
            drawHLLHeaderCentered(w, "CHOISISSEZ VOTRE FACTION", nil)

            local b = campBalanceCfg()
            local info = "1 personnage maximum par faction"
            if b.Enabled ~= false then
                info = info .. "  •  maximum " .. tostring(campMaxPlayers()) .. " joueurs par camp  •  tolérance : " .. tostring(tonumber(b.Tolerance) or 2)
            end
            draw.SimpleText(info, "MedalBarracks_Row", w / 2, S(104), Color(235,235,235,182), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            drawHLLFooter(w, h, "RETOUR AU MENU PRINCIPAL")
        end

        for i, army in ipairs(armies) do
            local card = vgui.Create("DButton", page)
            card:SetText("")
            card:SetPos((i - 1) * halfW, 0)
            card:SetSize(halfW, ScrH())
            card.cardMat = mat(army.cardImage)
            card.Paint = function(self, w, h)
                local allowed, reason, count, max = canJoinCampClient(army.id)
                local blocked = not allowed
                self.hoverAnim = Lerp(FrameTime() * 8, self.hoverAnim or 0, (self:IsHovered() and not blocked) and 1 or 0)
                local a = army.accent or C("Accent")
                local hasChar = characterFor(army.id) ~= nil or LocalPlayer():GetNWBool("MedalBarracks_Char_" .. army.id, false)

                draw.RoundedBox(0, 0, 0, w, h, Color(5, 5, 6, 255))
                if self.cardMat then
                    drawMatFit(self.cardMat, 0, 0, w, h, fcfg.UseCoverImages == false and "contain" or "cover")
                end

                -- Vignette militaire : lisibilité en bas, style Rising Storm / Cold War.
                draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, (tonumber(fcfg.DimAlpha) or 82) + (blocked and 82 or 0)))
                for step = 0, 18 do
                    local t = step / 18
                    draw.RoundedBox(0, 0, h - S(420) + step * S(22), w, S(24), Color(0,0,0, math.Clamp(22 + t * 220, 0, 245)))
                end
                for step = 0, 10 do
                    draw.RoundedBox(0, 0, step * S(20), w, S(22), Color(0,0,0, math.max(0, 105 - step * 10)))
                end

                if self.hoverAnim > 0.02 and not blocked then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255,255,255, self.hoverAnim * (tonumber(fcfg.HoverBright) or 34)))
                end

                surface.SetDrawColor(255,255,255, blocked and 35 or (self:IsHovered() and 210 or 70))
                surface.DrawOutlinedRect(S(26), S(126), w - S(52), h - S(190), self:IsHovered() and not blocked and S(2) or 1)
                surface.SetDrawColor(i == 1 and Color(255,255,255,22) or Color(0,0,0,120))
                surface.DrawLine(0, 0, 0, h)

                local titleY = h - S(205)
                draw.SimpleText(string.upper(army.cardName or army.menuName or army.name or army.id), "MedalBarracks_CardTitle", w / 2, titleY, blocked and Color(150,150,150,220) or C("White"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.RoundedBox(0, w/2 - S(146), titleY + S(49), S(96), S(2), Color(a.r, a.g, a.b, blocked and 80 or 220))
                draw.RoundedBox(0, w/2 + S(50), titleY + S(49), S(96), S(2), Color(a.r, a.g, a.b, blocked and 80 or 220))

                if (campBalanceCfg().ShowCountsOnCards ~= false) then
                    draw.SimpleText(tostring(count or 0) .. " / " .. tostring(max or 60) .. " JOUEURS", "MedalBarracks_H2", w / 2, titleY + S(68), blocked and Color(170,170,170,170) or Color(a.r,a.g,a.b,235), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
                draw.SimpleText(hasChar and "PERSONNAGE EXISTANT 1/1" or "EMPLACEMENT DISPONIBLE 0/1", "MedalBarracks_Row", w / 2, titleY + S(108), hasChar and Color(235,235,235,205) or Color(a.r,a.g,a.b,215), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                if blocked then
                    draw.SimpleText(reason or "BLOQUÉ", "MedalBarracks_Row", w / 2, titleY + S(138), Color(230, 90, 90, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                else
                    draw.SimpleText("CLIQUER POUR CONTINUER", "MedalBarracks_RowSmall", w / 2, titleY + S(140), Color(235,235,235,150), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            end
            card.DoClick = function()
                local allowed, reason = canJoinCampClient(army.id)
                if not allowed then notifyLocal(reason or "Cette faction est bloquée par l'équilibrage.", true); return end
                local rm = cfg.RemoteMedia or {}
                MedalBarracks.MakeTransition("OUVERTURE DU CANAL", army.cardName or army.name, function()
                    net.Start("MedalBarracks_SelectCamp")
                        net.WriteString(army.id)
                    net.SendToServer()
                end, "radio", rm.Usage and rm.Usage.FactionToCharacterCinematic)
            end
        end

        local back = createButton(page, "RETOUR", "", S(72), ScrH() - S(100), S(230), S(56), nil, backToMain)
        back:SetZPos(200)
    end

    frame.Paint = function(self, w, h)
        -- Fond statique de secours. Si une vidéo DHTML est active, elle reste derrière les panels UI.
        drawFrameBackground(self, w, h)
    end
    frame.PaintOver = function(self, w, h)
        -- Dessiné après la vidéo pour que le titre et les conseils restent visibles.
        if self.state == "main" then
            drawTitleLeft(menuCfg)
            drawTipBox(self, w, h)
        end
    end
    frame.OnKeyCodePressed = function(self, key)
        if editingBind then
            if key ~= KEY_ESCAPE then
                if istable(editingBind) and editingBind.__gmod == true then
                    setGModBind(editingBind, key)
                else
                    setBindKey(editingBind, key)
                end
            end
            editingBind = nil
            if self.rebuildOptions then self.rebuildOptions() end
            return
        end
        if key == KEY_ESCAPE or key == KEY_BACKSPACE then
            if self.state ~= "main" then backToMain(); return end
            if force and not (menuCfg.CloseOnEscape == true) then return end
            self:Remove()
        end
    end

    local style = cfg.MainMenuStyle or {}
    local bx = S(tonumber(style.ButtonX) or 132)
    local by = S(tonumber(style.ButtonY) or 500)
    local bw = S(tonumber(style.ButtonW) or 395)
    local bh = S(tonumber(style.ButtonH) or 74)
    local bgap = S(tonumber(style.ButtonGap) or 26)

    local play = createButton(frame, menuCfg.PlayText or "JOUER", menuCfg.PlaySubText or "", bx, by, bw, bh, function() return false end, function()
        local rm = cfg.RemoteMedia or {}
        MedalBarracks.MakeTransition("ASPIRATION AU FRONT", "Transmission radio reçue", showFactions, "war", rm.Usage and rm.Usage.MainToFactionCinematic)
    end)
    local opt = createButton(frame, menuCfg.OptionsText or "OPTION", "", bx, by + bh + bgap, bw, bh, function() return false end, showOptions)
    local quit = createButton(frame, menuCfg.QuitText or "QUITTER", "", bx, by + (bh + bgap) * 2, bw, bh, nil, function()
        if menuCfg.QuitRequiresConfirmation ~= false then showQuitConfirm() else RunConsoleCommand("disconnect") end
    end)
    table.insert(frame.mainButtons, play)
    table.insert(frame.mainButtons, opt)
    table.insert(frame.mainButtons, quit)

    local linkY = S(tonumber(style.LinkY) or 988)
    createLinkButton(menuCfg.DiscordIcon or "medal/ui/discord.png", menuCfg.DiscordURL or "", ScrW() - S(315), linkY, "Discord", "☊", "DISCORD")
    createLinkButton(menuCfg.WebsiteIcon or "medal/ui/globe.png", menuCfg.WebsiteURL or "", ScrW() - S(170), linkY, "Site web", "◎", "SITE WEB")

    if initialState == "factions" then showFactions() elseif initialState == "options" then showOptions() end
end

function MedalBarracks.OpenCampSelection(force)
    MedalBarracks.OpenMainMenu("factions", force)
end

function MedalBarracks.Open(preferredArmyID, slide)
    MedalBarracks.StartMenuAmbient()
    if IsValid(MedalBarracks.Frame) then MedalBarracks.Frame:Remove() end
    if IsValid(MedalBarracks.MainFrame) then MedalBarracks.MainFrame:Remove() end
    if IsValid(MedalBarracks.CharacterFrame) then MedalBarracks.CharacterFrame:Remove() end

    local chosenArmyID = preferredArmyID or LocalPlayer():GetNWString("MedalBarracks_ArmyChoice", "")
    local armyObj = MedalBarracks.GetArmy(chosenArmyID)
    if not armyObj then MedalBarracks.OpenMainMenu("factions", true); return end
    if (cfg.CharacterCreation or {}).RequireCharacterBeforeRoles ~= false and not characterFor(chosenArmyID) and not LocalPlayer():GetNWBool("MedalBarracks_Char_" .. chosenArmyID, false) then
        MedalBarracks.OpenCharacterSelection(chosenArmyID, true)
        return
    end

    local armies = {armyObj}
    local frame = vgui.Create("DFrame")
    MedalBarracks.Frame = frame
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(slide and ScrW() or 0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame.OnRemove = scheduleMenuAmbientStop
    frame.state = "barracks"
    if slide then frame:MoveTo(0, 0, (cfg.Animations and cfg.Animations.SlideDuration) or 0.34, 0, -1) end

    do
        local rm = cfg.RemoteMedia or {}
        local bgKey = rm.Usage and rm.Usage.BarracksBackground
        if bgKey and MedalBarracks.AttachBackgroundVideo then
            MedalBarracks.SetBackgroundVideo(frame, bgKey)
        end
    end

    frame.selectedRole = nil
    frame.selectedCategory = nil
    frame.selectedLoadout = nil

    local function army() return armies[1] end
    local function accent() return army().accent or C("Accent") end

    local function selectFirst()
        local role, cat = MedalBarracks.GetFirstRole(army())
        frame.selectedRole = role
        frame.selectedCategory = cat
        frame.selectedLoadout = role and role.loadouts and role.loadouts[1] or nil
        if role then
            for _, l in ipairs(role.loadouts or {}) do if levelOK(army().id, role, l) then frame.selectedLoadout = l; break end end
        end
    end
    selectFirst()

    frame.Paint = function(self, w, h)
        drawFrameBackground(self, w, h)
        -- Voile sombre latéral pour la lisibilité des colonnes, comme l'écran de déploiement HLL.
        for i = 0, 20 do
            local t = i / 20
            draw.RoundedBox(0, i * S(32), 0, S(34), h, Color(0, 0, 0, math.max(0, 205 * ((1 - t) ^ 1.9))))
            draw.RoundedBox(0, w - (i + 1) * S(32), 0, S(34), h, Color(0, 0, 0, math.max(0, 185 * ((1 - t) ^ 1.9))))
        end
        drawHLLHeader(w, "MEDAL VIETNAM // " .. string.upper(army().menuName or army().name or ""), "CASERNE", "SÉLECTION DU RÔLE ET DE L'ÉQUIPEMENT", accent())
        drawHLLFooter(w, h, "RETOUR AU DOSSIER")

        local lvl = cfg.GetPlayerLevel and cfg.GetPlayerLevel(LocalPlayer()) or 1
        local xp = LocalPlayer():GetNWInt(cfg.XPNWInt or "medal_xp", 0)
        local nextXP = LocalPlayer():GetNWInt(cfg.NextXPNWInt or "medal_next_xp", cfg.DefaultNextXP or 44000)
        -- Bandeau de progression façon HLL, au-dessus du modèle.
        local barW = S(420)
        draw.RoundedBox(0, w / 2 - barW / 2, S(118), barW, S(58), Color(5, 5, 7, 165))
        surface.SetDrawColor(255, 255, 255, 32)
        surface.DrawOutlinedRect(w / 2 - barW / 2, S(118), barW, S(58), 1)
        drawSpacedText("NIVEAU GÉNÉRAL", "MedalBarracks_RowSmall", w / 2, S(126), Color(235, 235, 235, 150), S(2), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(tostring(lvl), "MedalBarracks_Level", w / 2 - S(52), S(146), accent(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(xp) .. " / " .. tostring(nextXP), "MedalBarracks_RowSmall", w / 2 + S(58), S(149), Color(235, 235, 235, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local prog = math.Clamp(xp / math.max(nextXP, 1), 0, 1)
        draw.RoundedBox(0, w / 2 - barW / 2, S(118) + S(58) - S(3), barW * prog, S(3), accent())
    end

    local roleScroll = vgui.Create("DScrollPanel", frame)
    frame.roleScroll = roleScroll
    roleScroll:SetPos(S(70), S(195))
    roleScroll:SetSize(S(510), ScrH() - S(320))

    local loadoutScroll = vgui.Create("DScrollPanel", frame)
    frame.loadoutScroll = loadoutScroll
    loadoutScroll:SetPos(ScrW() - S(580), S(150))
    loadoutScroll:SetSize(S(510), S(300))

    local playerModel = vgui.Create("DModelPanel", frame)
    playerModel:SetPos(ScrW() / 2 - S(230), S(180))
    playerModel:SetSize(S(460), ScrH() - S(255))
    playerModel:SetFOV(35)
    playerModel:SetCamPos(Vector(58, 12, 60))
    playerModel:SetLookAt(Vector(0, 0, 42))
    playerModel:SetMouseInputEnabled(false)
    playerModel.LayoutEntity = function(self, ent)
        ent:SetAngles(Angle(0, 25 + math.sin(CurTime() * 0.33) * 4, 0))
        self:RunAnimation()
    end

    local previewModel = vgui.Create("DModelPanel", frame)
    previewModel:SetPos(ScrW() - S(545), ScrH() - S(355))
    previewModel:SetSize(S(470), S(110))
    previewModel:SetMouseInputEnabled(false)
    previewModel:SetVisible(false)
    previewModel:SetFOV(32)
    previewModel:SetCamPos(Vector(48, 10, 48))
    previewModel:SetLookAt(Vector(0,0,34))
    previewModel.LayoutEntity = function(self, ent)
        ent:SetAngles(Angle(0, 35 + math.sin(CurTime() * 0.4) * 4, 0))
        self:RunAnimation()
    end

    local function updatePlayerModel()
        local role = frame.selectedRole
        local loadout = frame.selectedLoadout
        local mdl = (loadout and loadout.model) or (role and role.model) or defaultCharModel(army())
        if isstring(mdl) and mdl ~= "" then playerModel:SetModel(mdl) end
    end

    local function updatePreviewModel()
        local mdl = loadoutPreviewModel(frame.selectedLoadout, frame.selectedRole)
        if mdl and mdl ~= "" then
            previewModel:SetVisible(true)
            previewModel:SetModel(mdl)
        else
            previewModel:SetVisible(false)
        end
    end

    local preview = vgui.Create("DPanel", frame)
    preview:SetPos(ScrW() - S(580), ScrH() - S(390))
    preview:SetSize(S(510), S(225))
    preview.Paint = function(self, w, h)
        local loadout = frame.selectedLoadout
        if not loadout then return end
        drawBlurPanel(self, 4)
        draw.RoundedBox(0, 0, 0, w, h, Color(8,8,10,200))
        surface.SetDrawColor(255,255,255,40)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local main = loadout.weapons and loadout.weapons[1] or ""
        if not previewModel:IsVisible() then
            local pm = loadoutPreviewImage(loadout)
            if pm then drawMatFit(pm, S(30), S(14), w - S(60), S(95), "contain") else drawWeaponSilhouette(S(30), S(14), w - S(60), S(95), main, 235) end
        end
        draw.SimpleText(niceWeaponName(main), "MedalBarracks_RowSmall", w - S(18), S(18), Color(255,255,255,112), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        local slotW = (w - S(20)) / 5
        local items = {}
        for _, wep in ipairs(loadout.weapons or {}) do table.insert(items, wep) end
        for _, eq in ipairs(loadout.equipment or {}) do table.insert(items, eq) end
        for i = 1, 5 do
            local x = S(10) + (i - 1) * slotW
            local y = S(132)
            draw.RoundedBox(0, x, y, slotW - S(5), S(72), Color(18,18,22,205))
            surface.SetDrawColor(255,255,255,42)
            surface.DrawOutlinedRect(x, y, slotW - S(5), S(72), 1)
            local item = items[i]
            if item then
                local im, label = itemMaterial(item)
                if im then drawMatFit(im, x + S(10), y + S(8), slotW - S(25), S(42), "contain") else drawWeaponSilhouette(x + S(7), y + S(8), slotW - S(19), S(42), tostring(label or item), 230) end
                if not string.find(tostring(label or item), "weapon", 1, true) and not string.find(tostring(label or item), "med_kit", 1, true) then
                    draw.SimpleText(string.upper(tostring(label or item)), "MedalBarracks_RowSmall", x + (slotW - S(5)) / 2, y + S(62), Color(255,255,255,118), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                end
            end
        end
    end

    local function rebuildLoadouts()
        loadoutScroll:Clear()
        local role = frame.selectedRole
        if not role then return end
        for _, loadout in ipairs(role.loadouts or {}) do
            local row = vgui.Create("DButton", loadoutScroll)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, S(8))
            row:SetTall(S(70))
            row:SetText("")
            row.Paint = function(self, w, h)
                local selected = frame.selectedLoadout == loadout
                local ok = levelOK(army().id, role, loadout)
                drawHLLButton(self, w, h, "", "", selected, selected and accent() or C("Red", Color(190,30,30)))
                draw.RoundedBox(0, 0, 0, S(116), h, Color(5,5,7,190))
                local im = loadoutImage(loadout)
                if im then drawMatFit(im, S(10), S(7), S(96), h - S(14), "contain") else drawWeaponSilhouette(S(10), S(7), S(95), h - S(14), loadout.weapons and loadout.weapons[1], ok and 225 or 90) end
                draw.SimpleText(loadout.name or loadout.id, "MedalBarracks_H2", S(132), S(13), ok and (selected and accent() or C("White")) or Color(125,125,125), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText("Déverrouillé au niveau de " .. (role.name or "Rôle") .. " " .. tostring(loadout.level or 1), "MedalBarracks_RowSmall", S(132), S(41), ok and Color(230,230,230,190) or Color(125,125,125), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                if not ok then draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,95)); draw.SimpleText("🔒", "MedalBarracks_H1", S(90), h / 2, Color(255,255,255,180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
            end
            row.DoClick = function()
                if not levelOK(army().id, role, loadout) then playButtonSound((cfg.Sounds or {}).UIBack); return end
                frame.selectedLoadout = loadout
                updatePlayerModel()
                updatePreviewModel()
                playButtonSound((cfg.Sounds or {}).UIClick)
            end
        end
    end

    local function rebuildRoles()
        roleScroll:Clear()
        for _, category in ipairs(army().categories or {}) do
            local header = vgui.Create("DPanel", roleScroll)
            header:Dock(TOP)
            header:DockMargin(0, S(4), S(12), S(5))
            header:SetTall(S(28))
            header.Paint = function(self, w, h)
                -- Intitulé de catégorie HLL : petites majuscules espacées + filet fin.
                local a = accent()
                draw.RoundedBox(0, 0, h / 2 - S(1), S(14), S(2), Color(a.r, a.g, a.b, 220))
                local tw = drawSpacedText(category.name, "MedalBarracks_RowSmall", S(22), h / 2, Color(235, 235, 235, 170), S(3), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(255, 255, 255, 24)
                surface.DrawRect(S(30) + tw, h / 2, w - S(34) - tw, 1)
            end
            for _, role in ipairs(category.roles or {}) do
                local row = vgui.Create("DButton", roleScroll)
                row:Dock(TOP)
                row:DockMargin(0, 0, S(12), S(7))
                row:SetTall(S(42))
                row:SetText("")
                local roleIcon = mat(role.iconMaterial or role.materialIcon or role.iconImage)
                row.Paint = function(self, w, h)
                    local selected = frame.selectedRole == role
                    drawHLLButton(self, w, h, "", "", selected, selected and accent() or C("Red", Color(190,30,30)))
                    local txtCol = selected and C("White") or Color(235,235,235,220)
                    if roleIcon then drawMatFit(roleIcon, S(12), S(7), S(28), h - S(14), "contain") else draw.SimpleText(role.icon or "•", "MedalBarracks_Row", S(26), h / 2, txtCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
                    drawSpacedText(role.name, "MedalBarracks_Row", S(54), h / 2, txtCol, S(2), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    -- Niveau de rôle en chiffres romains, dans une case sombre façon HLL.
                    local a = accent()
                    draw.RoundedBox(0, w - S(44), 0, S(44), h, selected and Color(a.r, a.g, a.b, 130) or Color(20, 21, 24, 200))
                    surface.SetDrawColor(255, 255, 255, selected and 90 or 30)
                    surface.DrawOutlinedRect(w - S(44), 0, S(44), h, 1)
                    local rLvl = roleLevel(army().id, role)
                    draw.SimpleText(roman(rLvl), "MedalBarracks_Row", w - S(22), h / 2, txtCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    local maxLvl = math.max(tonumber(role.maxLevel) or cfg.MaxRoleLevel or 8, 1)
                    draw.RoundedBox(0, S(54), h - S(4), (w - S(108)) * math.Clamp((tonumber(rLvl) or 1) / maxLvl, 0.03, 1), S(2), accent())
                end
                row.DoClick = function()
                    frame.selectedRole = role
                    frame.selectedCategory = category
                    frame.selectedLoadout = role.loadouts and role.loadouts[1] or nil
                    for _, l in ipairs(role.loadouts or {}) do if levelOK(army().id, role, l) then frame.selectedLoadout = l; break end end
                    rebuildLoadouts()
                    updatePlayerModel()
                    updatePreviewModel()
                    playButtonSound((cfg.Sounds or {}).UIClick)
                end
            end
        end
    end

    -- Barre d'action HLL : RETOUR à gauche, DÉPLOIEMENT à droite.
    local back = createButton(frame, "RETOUR", "", S(72), ScrH() - S(100), S(230), S(56), nil, function()
        MedalBarracks.OpenCharacterSelection(army().id, false)
    end)
    local select = createButton(frame, "DÉPLOYER", "Rôle obligatoire pour spawn", ScrW() - S(72) - S(320), ScrH() - S(100), S(320), S(56), nil, function()
        if not frame.selectedRole or not frame.selectedCategory or not frame.selectedLoadout then
            notification.AddLegacy("Tu dois choisir un rôle avant de spawn.", NOTIFY_ERROR, 4)
            playButtonSound((cfg.Sounds or {}).UIBack)
            return
        end
        if not levelOK(army().id, frame.selectedRole, frame.selectedLoadout) then
            notification.AddLegacy("Niveau insuffisant pour ce loadout.", NOTIFY_ERROR, 4)
            playButtonSound((cfg.Sounds or {}).UIBack)
            return
        end
        local rm = cfg.RemoteMedia or {}
        MedalBarracks.MakeTransition("INSERTION", "Synchronisation du loadout", function()
            net.Start("MedalBarracks_Select")
                net.WriteString(army().id)
                net.WriteString(frame.selectedCategory.id)
                net.WriteString(frame.selectedRole.id)
                net.WriteString(frame.selectedLoadout.id)
            net.SendToServer()
        end, "radio", rm.Usage and rm.Usage.SpawnCinematic)
    end, accent)

    rebuildRoles()
    rebuildLoadouts()
    updatePlayerModel()
    updatePreviewModel()
end


-- =========================
-- Menu staff personnages
-- =========================
MedalBarracks.StaffCharacters = MedalBarracks.StaffCharacters or {}

local function openStaffEditor(row)
    if not istable(row) then return end
    local f = vgui.Create("DFrame")
    f:SetSize(S(560), S(620))
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetDraggable(false)
    f:MakePopup()

    local function label(txt, y)
        local l = vgui.Create("DLabel", f)
        l:SetPos(S(38), y)
        l:SetSize(S(485), S(20))
        l:SetFont("MedalBarracks_InputLabel")
        l:SetTextColor(Color(235,235,235,220))
        l:SetText(txt)
    end
    local function entry(y, value, tall)
        local e = vgui.Create("DTextEntry", f)
        e:SetPos(S(38), y)
        e:SetSize(S(485), tall or S(34))
        e:SetFont("MedalBarracks_Row")
        e:SetText(value or "")
        if tall then e:SetMultiline(true) end
        return e
    end

    f.Paint = function(self, w, h)
        drawBlurPanel(self, 6)
        draw.RoundedBox(0, 0, 0, w, h, Color(8,8,10,242))
        draw.RoundedBox(0, 0, 0, S(6), h, C("Red", Color(190,30,30)))
        surface.SetDrawColor(255,255,255,65)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("STAFF — MODIFIER PERSONNAGE", "MedalBarracks_CardTitle", S(38), S(28), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText((row.nick or "Hors ligne") .. "  •  " .. (row.army or ""), "MedalBarracks_Row", S(38), S(67), Color(235,235,235,160), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    label("PRÉNOM", S(104)); local first = entry(S(128), row.firstName or "")
    label("NOM", S(170)); local last = entry(S(194), row.lastName or "")
    label("ÂGE", S(236)); local age = entry(S(260), tostring(row.age or 18))
    label("NATIONALITÉ", S(302)); local nat = entry(S(326), row.nationality or "")
    label("MODÈLE", S(368)); local mdl = entry(S(392), row.model or "")
    label("DESCRIPTION", S(434)); local desc = entry(S(458), row.description or "", S(78))

    local cancel = createButton(f, "ANNULER", "", S(38), S(552), S(170), S(46), nil, function() f:Remove() end, function() return Color(110,110,110) end)
    local save = createButton(f, "SAUVEGARDER", "", S(225), S(552), S(298), S(46), nil, function()
        net.Start("MedalBarracks_StaffSaveCharacter")
            net.WriteString(row.steamid64 or "")
            net.WriteString(row.army or "")
            net.WriteString(first:GetText() or "")
            net.WriteString(last:GetText() or "")
            net.WriteUInt(math.Clamp(tonumber(age:GetText()) or 18, 0, 120), 8)
            net.WriteString(nat:GetText() or "")
            net.WriteString(desc:GetText() or "")
            net.WriteString(mdl:GetText() or "")
            net.WriteString(row.role or "")
            net.WriteString(row.loadout or "")
        net.SendToServer()
        f:Remove()
    end, function() return C("Accent") end)
end

function MedalBarracks.OpenStaffMenu()
    if IsValid(MedalBarracks.StaffFrame) then MedalBarracks.StaffFrame:Remove() end
    local frame = vgui.Create("DFrame")
    MedalBarracks.StaffFrame = frame
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame.state = "staff"
    frame.rows = {}

    do
        local rm = cfg.RemoteMedia or {}
        local bgKey = rm.Usage and rm.Usage.StaffBackground
        if bgKey and MedalBarracks.SetBackgroundVideo then MedalBarracks.SetBackgroundVideo(frame, bgKey) end
    end

    net.Start("MedalBarracks_StaffRequestCharacters")
    net.SendToServer()

    local list = vgui.Create("DScrollPanel", frame)
    list:SetPos(S(70), S(140))
    list:SetSize(ScrW() - S(140), ScrH() - S(250))

    local function rebuild()
        list:Clear()
        for _, row in ipairs(MedalBarracks.StaffCharacters or {}) do
            local pnl = vgui.Create("DPanel", list)
            pnl:Dock(TOP)
            pnl:DockMargin(0, 0, 0, S(8))
            pnl:SetTall(S(84))
            pnl.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(8,8,10,210))
                draw.RoundedBox(0, 0, 0, S(5), h, C("Red", Color(190,30,30)))
                surface.SetDrawColor(255,255,255,45)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                draw.SimpleText(string.upper((row.firstName or "") .. " " .. (row.lastName or "")), "MedalBarracks_H2", S(24), S(12), C("White"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText((row.nick or "Hors ligne") .. "  •  " .. (row.steamid or row.steamid64 or "") .. "  •  " .. string.upper(row.army or ""), "MedalBarracks_RowSmall", S(24), S(43), Color(235,235,235,150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText("Rôle : " .. tostring(row.role or "aucun") .. "  |  Loadout : " .. tostring(row.loadout or "aucun"), "MedalBarracks_RowSmall", S(24), S(61), Color(235,235,235,130), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            local rowW = ScrW() - S(140)
            local edit = createButton(pnl, "MODIFIER", "", rowW - S(360), S(18), S(160), S(48), nil, function() openStaffEditor(row) end, function() return C("Accent") end)
            local del = createButton(pnl, "SUPPRIMER", "", rowW - S(185), S(18), S(170), S(48), nil, function()
                Derma_Query("Supprimer ce personnage ?", "Medal Vietnam", "Supprimer", function()
                    net.Start("MedalBarracks_StaffDeleteCharacter")
                        net.WriteString(row.steamid64 or "")
                        net.WriteString(row.army or "")
                    net.SendToServer()
                end, "Annuler")
            end, function() return C("Red", Color(190,30,30)) end)
        end
    end
    frame.Rebuild = rebuild

    frame.Paint = function(self, w, h)
        drawFrameBackground(self, w, h)
        drawHLLHeader(w, "MEDAL VIETNAM // ADMINISTRATION", "MENU STAFF", "GESTION DES PERSONNAGES SAUVEGARDÉS EN BASE SQLITE")
        drawHLLFooter(w, h, "FERMER")
    end
    frame.OnKeyCodePressed = function(_, key) if key == KEY_ESCAPE or key == KEY_BACKSPACE then frame:Remove() end end
    createButton(frame, "RETOUR", "", S(72), ScrH() - S(100), S(230), S(56), nil, function() frame:Remove() end, function() return Color(110,110,110) end)
    createButton(frame, "ACTUALISER", "", ScrW() - S(72) - S(240), ScrH() - S(100), S(240), S(56), nil, function() net.Start("MedalBarracks_StaffRequestCharacters"); net.SendToServer() end, function() return C("Accent") end)
end

net.Receive("MedalBarracks_StaffCharacters", function()
    local count = net.ReadUInt(12)
    local rows = {}
    for i = 1, count do
        rows[i] = {
            steamid64 = net.ReadString(),
            steamid = net.ReadString(),
            nick = net.ReadString(),
            army = net.ReadString(),
            firstName = net.ReadString(),
            lastName = net.ReadString(),
            age = net.ReadUInt(8),
            nationality = net.ReadString(),
            description = net.ReadString(),
            model = net.ReadString(),
            role = net.ReadString(),
            loadout = net.ReadString(),
            updated = net.ReadUInt(32),
        }
    end
    MedalBarracks.StaffCharacters = rows
    if IsValid(MedalBarracks.StaffFrame) and MedalBarracks.StaffFrame.Rebuild then MedalBarracks.StaffFrame:Rebuild() end
end)

concommand.Add((cfg.StaffMenu and cfg.StaffMenu.Command) or "medal_staff_menu", function() MedalBarracks.OpenStaffMenu() end)

concommand.Add(cfg.MainMenuCommand or "medal_menu", function() MedalBarracks.OpenMainMenu("main", false) end)
concommand.Add(cfg.ConsoleCommand or "medal_caserne", function() MedalBarracks.Open() end)

hook.Add("PlayerButtonDown", "MedalBarracks_Keybinds", function(ply, button)
    if ply ~= LocalPlayer() then return end
    if gui.IsGameUIVisible() then return end
    if editingBind then return end

    -- Ancien bind rapide conservé si cfg.Keybinds est vide.
    if (not cfg.Keybinds or #cfg.Keybinds <= 0) and cfg.OpenKey and button == cfg.OpenKey then
        if IsValid(MedalBarracks.Frame) then return end
        MedalBarracks.OpenMainMenu("main", false)
        return
    end

    for _, bind in ipairs(cfg.Keybinds or {}) do
        if button == getBindKey(bind) then
            runBindAction(bind)
            return
        end
    end
end)

net.Receive("MedalBarracks_Characters", function()
    local count = net.ReadUInt(8)
    local chars = {}
    for i = 1, count do
        local armyID = net.ReadString()
        local exists = net.ReadBool()
        if exists then
            chars[armyID] = {
                firstName = net.ReadString(),
                lastName = net.ReadString(),
                age = net.ReadUInt(8),
                nationality = net.ReadString(),
                description = net.ReadString(),
                model = net.ReadString(),
                role = net.ReadString(),
                loadout = net.ReadString(),
            }
        end
    end
    MedalBarracks.ClientCharacters = chars
    if IsValid(MedalBarracks.CharacterFrame) and MedalBarracks.CharacterFrame.Refresh then MedalBarracks.CharacterFrame:Refresh() end
end)

net.Receive("MedalBarracks_OpenMainMenu", function() MedalBarracks.OpenMainMenu("main", true) end)
net.Receive("MedalBarracks_OpenCampSelection", function() MedalBarracks.OpenMainMenu("factions", true) end)
net.Receive("MedalBarracks_OpenCharacterSelection", function()
    local armyID = net.ReadString()
    MedalBarracks.OpenCharacterSelection(armyID, true)
end)
net.Receive("MedalBarracks_OpenBarracks", function()
    local armyID = net.ReadString()
    MedalBarracks.Open(armyID, true)
end)

net.Receive("MedalBarracks_CampResult", function()
    local ok = net.ReadBool()
    local msg = net.ReadString()
    local armyID = net.ReadString()
    notification.AddLegacy(msg, ok and NOTIFY_GENERIC or NOTIFY_ERROR, 4)
    chat.AddText(ok and Color(198,181,94) or Color(220,70,70), "[Camp] ", color_white, msg)
    playSound(ok and ((cfg.Sounds or {}).UIClick) or ((cfg.Sounds or {}).UIBack))
    if ok and IsValid(MedalBarracks.MainFrame) then MedalBarracks.MainFrame:AlphaTo(0, 0.12, 0, function(_, p) if IsValid(p) then p:Remove() end end) end
end)

net.Receive("MedalBarracks_CharacterResult", function()
    local ok = net.ReadBool()
    local msg = net.ReadString()
    local armyID = net.ReadString()
    notification.AddLegacy(msg, ok and NOTIFY_GENERIC or NOTIFY_ERROR, 4)
    chat.AddText(ok and Color(198,181,94) or Color(220,70,70), "[Personnage] ", color_white, msg)
    playSound(ok and ((cfg.Sounds or {}).CharacterCreated) or ((cfg.Sounds or {}).UIBack))
    if ok then
        MedalBarracks.RequestCharacters()
        timer.Simple(0.12, function() if armyID and armyID ~= "" then MedalBarracks.OpenCharacterSelection(armyID, false) end end)
    end
end)

net.Receive("MedalBarracks_Result", function()
    local ok = net.ReadBool()
    local msg = net.ReadString()
    notification.AddLegacy(msg, ok and NOTIFY_GENERIC or NOTIFY_ERROR, 4)
    chat.AddText(ok and Color(198,181,94) or Color(220,70,70), "[Caserne] ", color_white, msg)
    playSound(ok and ((cfg.Sounds or {}).RoleSelected) or ((cfg.Sounds or {}).UIBack))
    if ok then MedalBarracks.StopMenuAmbient() end
    if ok and IsValid(MedalBarracks.Frame) then MedalBarracks.Frame:AlphaTo(0, 0.16, 0, function(_, p) if IsValid(p) then p:Remove() end end) end
end)



-- =========================
-- HUD / Weapon selector Medal
-- =========================
local weaponSelectorUntil = 0
local lastActiveWeaponClass = ""

local function hudCfg()
    return cfg.HideDefaultHUD or {}
end

hook.Add("HUDShouldDraw", "MedalBarracks_HideDefaultHUD", function(name)
    local hc = hudCfg()
    if hc.Enabled == false then return end
    local blocked = hc.Elements or {}
    if blocked[name] then return false end
end)

local function wsCfg()
    return cfg.WeaponSelector or {}
end

local function showWeaponSelector()
    local wc = wsCfg()
    if wc.Enabled == false then return end
    weaponSelectorUntil = CurTime() + (tonumber(wc.HideDelay) or 2.8)
end

local function weaponDisplayName(wep)
    if not IsValid(wep) then return "ARME" end
    local class = wep:GetClass()
    local wc = wsCfg()
    if wc.Names and wc.Names[class] then return string.upper(tostring(wc.Names[class])) end
    if wep.GetPrintName then
        local pn = tostring(wep:GetPrintName() or "")
        if pn ~= "" and pn ~= "#HL2_" and pn ~= class then return string.upper(language.GetPhrase(pn)) end
    end
    return niceWeaponName(class)
end

local function weaponIconMaterial(wep)
    if not IsValid(wep) then return nil end
    local class = wep:GetClass()
    local wc = wsCfg()
    local path = (wc.WeaponIcons and wc.WeaponIcons[class]) or (cfg.WeaponIconMaterials and cfg.WeaponIconMaterials[class])
    return mat(path), path
end

hook.Add("PlayerBindPress", "MedalBarracks_ShowWeaponSelectorOnBind", function(ply, bind, pressed)
    if ply ~= LocalPlayer() or not pressed then return end
    local b = string.lower(tostring(bind or ""))
    if string.find(b, "invnext", 1, true) or string.find(b, "invprev", 1, true) or string.find(b, "slot", 1, true) or string.find(b, "+attack", 1, true) then
        showWeaponSelector()
    end
end)

hook.Add("Think", "MedalBarracks_WeaponSelectorActiveCheck", function()
    local wc = wsCfg()
    if wc.Enabled == false then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    local class = IsValid(wep) and wep:GetClass() or ""
    if class ~= lastActiveWeaponClass then
        lastActiveWeaponClass = class
        if class ~= "" then showWeaponSelector() end
    end
end)

hook.Add("HUDPaint", "MedalBarracks_WeaponSelectorPaint", function()
    local wc = wsCfg()
    if wc.Enabled == false then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local weps = ply:GetWeapons()
    if #weps <= 0 then return end
    local active = ply:GetActiveWeapon()
    if not IsValid(active) then return end

    local remaining = weaponSelectorUntil - CurTime()
    if remaining <= 0 then return end
    local fadeTime = tonumber(wc.FadeTime) or 0.35
    local alpha = math.Clamp(remaining / math.max(fadeTime, 0.01), 0, 1)
    alpha = math.Clamp(alpha * 255, 0, 255)

    local maxItems = tonumber(wc.MaxItems) or 7
    local itemH = S(tonumber(wc.ItemH) or 48)
    local itemW = S(tonumber(wc.ItemW) or 300)
    local gap = S(tonumber(wc.Gap) or 7)
    local pad = S(tonumber(wc.Padding) or 18)
    local x = ScrW() - itemW - S(tonumber(wc.RightMargin) or 42)
    local y = ScrH() - S(tonumber(wc.BottomMargin) or 128)
    local activeIndex = 1
    for i, wep in ipairs(weps) do if wep == active then activeIndex = i break end end
    local first = math.max(1, math.min(activeIndex - math.floor(maxItems / 2), math.max(1, #weps - maxItems + 1)))
    local last = math.min(#weps, first + maxItems - 1)
    local count = last - first + 1
    y = y - (count - 1) * (itemH + gap)

    local panelMat = mat(wc.PanelMaterial or "")
    local slotMat = mat(wc.SlotMaterial or "")
    for idx = first, last do
        local wep = weps[idx]
        local selected = wep == active
        local rowY = y + (idx - first) * (itemH + gap)
        local rowAlpha = selected and alpha or alpha * 0.66
        local rowX = x + (selected and 0 or S(34))
        local rowW = selected and itemW or itemW - S(46)
        if panelMat then
            surface.SetMaterial(panelMat)
            surface.SetDrawColor(255,255,255,rowAlpha)
            surface.DrawTexturedRect(rowX, rowY, rowW, itemH)
        else
            draw.RoundedBox(0, rowX, rowY, rowW, itemH, Color(5,5,7, rowAlpha * 0.72))
            surface.SetDrawColor(255,255,255, selected and rowAlpha * 0.48 or rowAlpha * 0.16)
            surface.DrawOutlinedRect(rowX, rowY, rowW, itemH, 1)
        end
        if selected then draw.RoundedBox(0, rowX, rowY, S(4), itemH, C("Red", Color(190,28,28, rowAlpha))) end
        local iconM = weaponIconMaterial(wep)
        if iconM then
            drawMatFit(iconM, rowX + pad, rowY + S(7), S(78), itemH - S(14), "contain")
        else
            drawWeaponSilhouette(rowX + pad, rowY + S(7), S(78), itemH - S(14), wep:GetClass(), rowAlpha)
        end
        if selected then
            draw.SimpleText("CURRENT WEAPON", "MedalBarracks_WepSmall", rowX + S(112), rowY + S(8), Color(235,235,235,rowAlpha * 0.58), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(weaponDisplayName(wep), "MedalBarracks_WepName", rowX + S(112), rowY + S(22), Color(245,245,245,rowAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        else
            draw.SimpleText(weaponDisplayName(wep), "MedalBarracks_WepSmall", rowX + S(112), rowY + itemH / 2, Color(235,235,235,rowAlpha * 0.72), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end)

net.Receive("MedalBarracks_XPNotify", function()
    local kind = net.ReadString()
    local amount = net.ReadInt(32)
    local oldLevel = net.ReadUInt(16)
    local newLevel = net.ReadUInt(16)
    local armyID = net.ReadString()
    local roleID = net.ReadString()
    local reason = net.ReadString()

    local label = "XP"
    local prefix = "[XP] "
    if kind == "general" then
        label = "XP générale"
    elseif kind == "role" then
        local roleName = roleID
        local army = MedalBarracks.GetArmy and MedalBarracks.GetArmy(armyID)
        if army then
            for _, cat in ipairs(army.categories or {}) do
                for _, r in ipairs(cat.roles or {}) do
                    if r.id == roleID then
                        roleName = r.name or roleID
                        break
                    end
                end
                if roleName ~= roleID then break end
            end
        end
        label = "XP de rôle - " .. tostring(roleName or roleID)
    end

    local msg = "+" .. tostring(amount) .. " " .. label
    if newLevel > oldLevel then msg = msg .. " | Niveau " .. tostring(newLevel) .. " atteint" end

    notification.AddLegacy(msg, NOTIFY_GENERIC, 3)
    chat.AddText(Color(198,181,94), prefix, color_white, msg)
end)

concommand.Add("medal_media_reload", function()
    if MedalBarracks.FetchRemoteManifest then
        MedalBarracks.FetchRemoteManifest(true, function(ok)
            notification.AddLegacy(ok and "Manifest média rechargé." or "Impossible de recharger le manifest média.", ok and NOTIFY_GENERIC or NOTIFY_ERROR, 4)
        end)
    end
end)

net.Receive("MedalBarracks_RemoteMediaReload", function()
    if MedalBarracks.FetchRemoteManifest then MedalBarracks.FetchRemoteManifest(true) end
end)
