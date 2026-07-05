--[[
    Medal Barracks — Gestionnaire de musiques STAFF (serveur).
    La liste des musiques vient d'un dossier Dropbox et se met à jour toute
    seule (timer RefreshInterval) :
      - mode API Dropbox : listing réel du dossier (files/list_folder) et liens
        temporaires (files/get_temporary_link) — tout fichier ajouté au dossier
        apparaît automatiquement ;
      - mode manifest : musics.json hébergé sur Dropbox.
    Le staff lance/arrête une musique pour TOUT le serveur (sound.PlayURL client).
]]

MedalBarracks = MedalBarracks or {}
local cfg = MedalBarracks.Config or {}

util.AddNetworkString("MedalMusic_List")
util.AddNetworkString("MedalMusic_Request")
util.AddNetworkString("MedalMusic_Play")
util.AddNetworkString("MedalMusic_Stop")
util.AddNetworkString("MedalMusic_PlayClient")
util.AddNetworkString("MedalMusic_StopClient")

local function musicCfg()
    return cfg.Music or {}
end

local function isMusicStaff(ply)
    if not IsValid(ply) then return false end
    local access = tostring(musicCfg().MinAccess or "admin")
    if access == "superadmin" then return ply:IsSuperAdmin() end
    return ply:IsAdmin() or ply:IsSuperAdmin()
end

-- {name = "...", url = "...", path = "..." (mode API), temp = "..." (lien temporaire)}
MedalBarracks.MusicList = MedalBarracks.MusicList or {}
MedalBarracks.MusicPlaying = MedalBarracks.MusicPlaying or nil

local function hasAudioExtension(name)
    local ext = string.lower(string.match(tostring(name or ""), "%.([%w]+)$") or "")
    local allowed = musicCfg().Extensions or {mp3 = true, ogg = true, wav = true}
    return allowed[ext] == true
end

local function sendListTo(target)
    local payload = {}
    for i, track in ipairs(MedalBarracks.MusicList) do
        payload[i] = {name = track.name}
    end
    net.Start("MedalMusic_List")
        net.WriteUInt(#payload, 10)
        for _, t in ipairs(payload) do net.WriteString(t.name) end
        net.WriteString(MedalBarracks.MusicPlaying and MedalBarracks.MusicPlaying.name or "")
    if target then net.Send(target) else
        for _, p in ipairs(player.GetHumans()) do
            if isMusicStaff(p) then net.Send(p) end
        end
    end
end

-- =========================
-- Listing du dossier Dropbox
-- =========================
local function refreshFromAPI()
    local db = musicCfg().Dropbox or {}
    local token = tostring(db.AccessToken or "")
    if token == "" then return false end

    HTTP({
        method = "POST",
        url = "https://api.dropboxapi.com/2/files/list_folder",
        headers = {
            ["Authorization"] = "Bearer " .. token,
            ["Content-Type"] = "application/json",
        },
        body = util.TableToJSON({path = tostring(db.FolderPath or "/musiques"), recursive = false}),
        type = "application/json",
        success = function(code, body)
            local data = util.JSONToTable(body or "")
            if not istable(data) or not istable(data.entries) then
                MsgC(Color(220, 80, 80), "[MedalMusic] Réponse Dropbox invalide (code " .. tostring(code) .. ").\n")
                return
            end
            local list = {}
            for _, entry in ipairs(data.entries) do
                if entry[".tag"] == "file" and hasAudioExtension(entry.name) then
                    table.insert(list, {
                        name = string.gsub(tostring(entry.name), "%.%w+$", ""),
                        path = tostring(entry.path_lower or entry.path_display or ""),
                    })
                end
            end
            table.sort(list, function(a, b) return a.name < b.name end)
            MedalBarracks.MusicList = list
            sendListTo(nil)
            MsgC(Color(148, 156, 108), "[MedalMusic] " .. #list .. " musique(s) listée(s) depuis le dossier Dropbox.\n")
        end,
        failed = function(err)
            MsgC(Color(220, 80, 80), "[MedalMusic] Listing Dropbox impossible : " .. tostring(err) .. "\n")
        end,
    })
    return true
end

local function refreshFromManifest()
    local url = tostring(musicCfg().ManifestURL or "")
    if url == "" then return false end
    if MedalBarracks.NormalizeMediaURL then url = MedalBarracks.NormalizeMediaURL(url) end
    -- Normalisation Dropbox minimale côté serveur.
    url = string.gsub(url, "^https://www%.dropbox%.com/", "https://dl.dropboxusercontent.com/")
    if not string.find(url, "dl=1", 1, true) and string.find(url, "dropboxusercontent", 1, true) then
        url = url .. (string.find(url, "?", 1, true) and "&dl=1" or "?dl=1")
    end

    http.Fetch(url, function(body)
        local data = util.JSONToTable(body or "")
        local musics = istable(data) and (data.musics or data.tracks or data) or nil
        if not istable(musics) then
            MsgC(Color(220, 80, 80), "[MedalMusic] Manifest musique invalide.\n")
            return
        end
        local list = {}
        for _, m in ipairs(musics) do
            if istable(m) and isstring(m.url) and m.url ~= "" then
                table.insert(list, {name = tostring(m.name or m.title or m.url), url = m.url})
            end
        end
        table.sort(list, function(a, b) return a.name < b.name end)
        MedalBarracks.MusicList = list
        sendListTo(nil)
        MsgC(Color(148, 156, 108), "[MedalMusic] " .. #list .. " musique(s) chargée(s) depuis le manifest.\n")
    end, function(err)
        MsgC(Color(220, 80, 80), "[MedalMusic] Manifest musique inaccessible : " .. tostring(err) .. "\n")
    end)
    return true
end

local function refreshMusicList()
    if musicCfg().Enabled == false then return end
    if not refreshFromAPI() then refreshFromManifest() end
end

-- Mise à jour automatique du dossier.
local function startMusicTimer()
    local interval = math.max(tonumber(musicCfg().RefreshInterval) or 180, 30)
    timer.Remove("MedalMusic_AutoRefresh")
    timer.Create("MedalMusic_AutoRefresh", interval, 0, refreshMusicList)
    timer.Simple(5, refreshMusicList)
end
hook.Add("Initialize", "MedalMusic_Start", startMusicTimer)
startMusicTimer()

-- =========================
-- Lecture / arrêt
-- =========================
local function broadcastPlay(track, volume)
    MedalBarracks.MusicPlaying = track
    net.Start("MedalMusic_PlayClient")
        net.WriteString(track.name)
        net.WriteString(track.temp or track.url or "")
        net.WriteFloat(math.Clamp(volume, 0, 1))
    net.Broadcast()
    sendListTo(nil)
end

local function playTrack(ply, index, volume)
    local track = MedalBarracks.MusicList[index]
    if not track then ply:ChatPrint("[Musique] Piste introuvable — actualise la liste."); return end
    volume = math.Clamp(tonumber(volume) or tonumber(musicCfg().DefaultVolume) or 0.5, 0, 1)

    if track.url and track.url ~= "" then
        broadcastPlay(track, volume)
        return
    end

    -- Mode API : lien temporaire Dropbox (valable ~4h), mis en cache 3h.
    if track.temp and (track.tempUntil or 0) > CurTime() then
        broadcastPlay(track, volume)
        return
    end
    local token = tostring((musicCfg().Dropbox or {}).AccessToken or "")
    if token == "" or not track.path then ply:ChatPrint("[Musique] Configuration Dropbox incomplète."); return end
    HTTP({
        method = "POST",
        url = "https://api.dropboxapi.com/2/files/get_temporary_link",
        headers = {
            ["Authorization"] = "Bearer " .. token,
            ["Content-Type"] = "application/json",
        },
        body = util.TableToJSON({path = track.path}),
        type = "application/json",
        success = function(code, body)
            local data = util.JSONToTable(body or "")
            if istable(data) and isstring(data.link) then
                track.temp = data.link
                track.tempUntil = CurTime() + 3 * 3600
                broadcastPlay(track, volume)
            else
                if IsValid(ply) then ply:ChatPrint("[Musique] Lien temporaire Dropbox refusé (code " .. tostring(code) .. ").") end
            end
        end,
        failed = function(err)
            if IsValid(ply) then ply:ChatPrint("[Musique] Erreur Dropbox : " .. tostring(err)) end
        end,
    })
end

net.Receive("MedalMusic_Request", function(_, ply)
    if not isMusicStaff(ply) then return end
    if not MedalBarracks.NetRateOK(ply, "music", 0.5) then return end
    local force = net.ReadBool()
    if force then refreshMusicList() end
    sendListTo(ply)
end)

net.Receive("MedalMusic_Play", function(_, ply)
    if not MedalBarracks.NetRateOK(ply, "music", 0.5) then return end
    if not isMusicStaff(ply) then ply:ChatPrint("[Musique] Réservé au staff."); return end
    local index = net.ReadUInt(10)
    local volume = net.ReadFloat()
    playTrack(ply, index, volume)
end)

net.Receive("MedalMusic_Stop", function(_, ply)
    if not isMusicStaff(ply) then return end
    if not MedalBarracks.NetRateOK(ply, "music", 0.5) then return end
    MedalBarracks.MusicPlaying = nil
    net.Start("MedalMusic_StopClient")
    net.Broadcast()
    sendListTo(nil)
end)

-- Un joueur qui arrive pendant une musique la reçoit aussi.
hook.Add("PlayerInitialSpawn", "MedalMusic_LateJoin", function(ply)
    timer.Simple(8, function()
        local track = MedalBarracks.MusicPlaying
        if not IsValid(ply) or not track then return end
        net.Start("MedalMusic_PlayClient")
            net.WriteString(track.name)
            net.WriteString(track.temp or track.url or "")
            net.WriteFloat(math.Clamp(tonumber(musicCfg().DefaultVolume) or 0.5, 0, 1))
        net.Send(ply)
    end)
end)
