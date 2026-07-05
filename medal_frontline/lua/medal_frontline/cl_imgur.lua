--[[
    Medal Frontline — Chargement d'images Imgur en materials (client).
    GMod ne charge pas une URL directement en material : on télécharge l'image
    (http.Fetch) une fois, on la met en cache dans data/medal_frontline/logos/,
    puis on la charge avec Material("data/...").
    Utilisation : MedalFrontline.GetImgur(url) -> IMaterial (ou nil en attendant).
]]

if SERVER then return end

MedalFrontline = MedalFrontline or {}
MedalFrontline._imgurCache = MedalFrontline._imgurCache or {}
MedalFrontline._imgurPending = MedalFrontline._imgurPending or {}

local DIR = "medal_frontline/logos"

-- Normalise un lien Imgur en URL directe .png.
local function directURL(url)
    url = tostring(url or "")
    if url == "" then return "" end
    -- imgur.com/xxxx -> i.imgur.com/xxxx.png
    if not string.find(url, "i.imgur.com", 1, true) and string.find(url, "imgur.com", 1, true) then
        local id = url:match("imgur%.com/([%w]+)")
        if id then url = "https://i.imgur.com/" .. id .. ".png" end
    end
    -- Ajoute une extension si absente.
    if string.find(url, "i.imgur.com", 1, true) and not url:match("%.%a+$") then
        url = url .. ".png"
    end
    return url
end

local function hashName(url)
    return DIR .. "/" .. util.CRC(url) .. ".png"
end

function MedalFrontline.GetImgur(url)
    url = directURL(url)
    if url == "" then return nil end
    if MedalFrontline._imgurCache[url] then return MedalFrontline._imgurCache[url] end

    local path = hashName(url)
    -- Déjà téléchargé : on le charge depuis data/.
    if file.Exists(path, "DATA") then
        local mat = Material("../data/" .. path, "noclamp smooth")
        if mat and not mat:IsError() then
            MedalFrontline._imgurCache[url] = mat
            return mat
        end
    end

    -- Téléchargement (une seule fois par URL).
    if not MedalFrontline._imgurPending[url] then
        MedalFrontline._imgurPending[url] = true
        file.CreateDir(DIR)
        http.Fetch(url, function(body, size, headers, code)
            if code ~= 200 or not body or #body < 64 then
                MsgC(Color(220, 80, 80), "[MedalFrontline] Logo Imgur illisible : " .. url .. " (code " .. tostring(code) .. ")\n")
                return
            end
            file.Write(path, body)
            timer.Simple(0.2, function()
                local mat = Material("../data/" .. path, "noclamp smooth")
                if mat and not mat:IsError() then MedalFrontline._imgurCache[url] = mat end
            end)
        end, function(err)
            MsgC(Color(220, 80, 80), "[MedalFrontline] Téléchargement Imgur échoué : " .. tostring(err) .. "\n")
        end)
    end
    return nil
end

-- Précharge les logos de faction au démarrage.
hook.Add("InitPostEntity", "MedalFrontline_PreloadLogos", function()
    timer.Simple(2, function()
        for _, u in pairs((MedalFrontline.Config or {}).FactionLogos or {}) do
            if u ~= "" then MedalFrontline.GetImgur(u) end
        end
    end)
end)
