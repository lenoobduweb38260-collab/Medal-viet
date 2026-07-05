--[[
    Medal Garage — Config IN-GAME façon WCD (serveur).
    - Découverte automatique de TOUS les véhicules installés (Workshop) :
      véhicules Source, simfphys, LFS, WAC, Glide, bases scriptées connues.
    - Le staff active/désactive chaque véhicule et règle niveau / HP / essence /
      catégorie depuis le panel CONFIG du garage. Sauvegarde JSON serveur.
    - Paramètres généraux (fond Dropbox du menu, etc.) modifiables in-game.
]]

MedalGarage = MedalGarage or {}
local cfg = MedalGarage.Config or {}

util.AddNetworkString("MedalGarage_AdminList")
util.AddNetworkString("MedalGarage_AdminSet")
util.AddNetworkString("MedalGarage_AdminSettings")
util.AddNetworkString("MedalGarage_DealerList")

local function isStaff(ply)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    local ranks = cfg.AdminRanks or {superadmin = true}
    return ranks[ply:GetUserGroup()] == true or ply:IsAdmin()
end

-- Anti-spam très simple par joueur/canal.
local rate = {}
local function rateOK(ply, key, delay)
    rate[ply] = rate[ply] or {}
    if (rate[ply][key] or 0) > CurTime() then return false end
    rate[ply][key] = CurTime() + (delay or 0.5)
    return true
end
hook.Add("PlayerDisconnected", "MedalGarage_RateCleanup", function(ply) rate[ply] = nil end)
MedalGarage.RateOK = rateOK
MedalGarage.IsStaff = isStaff

-- =========================
-- Stockage : overrides véhicules + paramètres généraux
-- =========================
local OVERRIDES_PATH = "medal_garage/vehicles.json"
local SETTINGS_PATH = "medal_garage/settings.json"

MedalGarage.Overrides = MedalGarage.Overrides or {}
MedalGarage.Settings = MedalGarage.Settings or {
    background = "",        -- lien Dropbox/Imgur (image ou vidéo) du fond du menu
    backgroundVolume = 0,   -- volume si vidéo
}

local function saveOverrides()
    file.CreateDir("medal_garage")
    file.Write(OVERRIDES_PATH, util.TableToJSON(MedalGarage.Overrides, true))
end

local function saveSettings()
    file.CreateDir("medal_garage")
    file.Write(SETTINGS_PATH, util.TableToJSON(MedalGarage.Settings, true))
end

local function loadStorage()
    local raw = file.Read(OVERRIDES_PATH, "DATA")
    if raw then MedalGarage.Overrides = util.JSONToTable(raw) or {} end
    raw = file.Read(SETTINGS_PATH, "DATA")
    if raw then
        for k, v in pairs(util.JSONToTable(raw) or {}) do MedalGarage.Settings[k] = v end
    end
end
hook.Add("Initialize", "MedalGarage_LoadStorage", loadStorage)
loadStorage()

-- =========================
-- Découverte automatique des véhicules (pattern WCD)
-- =========================
-- Bases scriptées connues : où trouver Model / Nom sur chacune.
local baseHelper = {
    ["lunasflightschool_basescript"] = {model = "MDL", name = "PrintName"},
    ["lunasflightschool_basescript_heli"] = {model = "MDL", name = "PrintName"},
    ["wac_hc_base"] = {model = "Model", name = "PrintName"},
    ["wac_pl_base"] = {model = "Model", name = "PrintName"},
    ["sent_sakarias_scar_base"] = {model = "CarModel", name = "PrintName"},
    ["glide_standard"] = {model = "Model", name = "PrintName"},
    ["base_glide"] = {model = "Model", name = "PrintName"},
}

function MedalGarage.DiscoverVehicles()
    local out = {}

    -- 1) Véhicules Source (menu Véhicules de GMod, packs Workshop type jeep/pod).
    for id, v in pairs(list.Get("Vehicles") or {}) do
        if v.Model and v.Class ~= "Airboat" then
            out[id] = {
                id = id,
                name = tostring(v.Name or id),
                class = tostring(v.Class or "prop_vehicle_jeep"),
                model = tostring(v.Model),
                script = v.KeyValues and tostring(v.KeyValues.vehiclescript or "") or "",
                source = "vehicles",
            }
        end
    end

    -- 2) simfphys.
    for id, v in pairs(list.Get("simfphys_vehicles") or {}) do
        out["simfphys_" .. id] = {
            id = "simfphys_" .. id,
            name = tostring(v.Name or id),
            class = "gmod_sent_vehicle_fphysics_base",
            model = tostring(v.Model or ""),
            simfphys = id,
            source = "simfphys",
        }
    end

    -- 3) Entités scriptées sur bases connues (LFS, WAC, SCars, Glide…).
    for class, v in pairs(scripted_ents.GetList() or {}) do
        if v.Base and baseHelper[v.Base] and istable(v.t) and not out[class] then
            local ref = baseHelper[v.Base]
            local model = v.t[ref.model]
            local name = v.t[ref.name]
            if model and name then
                out[class] = {
                    id = class,
                    name = tostring(name),
                    class = class,
                    model = tostring(model),
                    source = "entity",
                }
            end
        end
    end

    return out
end

-- Fusion : véhicule découvert + override staff -> entrée dealer finale.
function MedalGarage.GetDealerList()
    local discovered = MedalGarage.DiscoverVehicles()
    local final = {}

    -- Overrides in-game (façon WCD : seule source de vérité une fois configuré).
    for id, ov in pairs(MedalGarage.Overrides) do
        if ov.enabled then
            local disc = discovered[id]
            table.insert(final, {
                id = id,
                name = tostring(ov.name or (disc and disc.name) or id),
                class = disc and disc.class or tostring(ov.class or "prop_vehicle_jeep"),
                model = tostring(ov.model or (disc and disc.model) or ""),
                script = disc and disc.script or "",
                simfphys = disc and disc.simfphys or nil,
                source = disc and disc.source or "entity",
                category = tostring(ov.category or "TRANSPORT"),
                level = tonumber(ov.level) or 1,
                fuel = tonumber(ov.fuel) or 100,
                hp = tonumber(ov.hp) or 0, -- 0 = HP d'origine
                desc = tostring(ov.desc or ""),
            })
        end
    end

    -- Fallback : catalogue statique de la config si rien n'est activé in-game.
    if #final == 0 then
        for _, v in ipairs(cfg.Vehicles or {}) do
            table.insert(final, {
                id = v.name, name = v.name, class = v.class, model = v.model or "",
                script = "", source = "vehicles", category = v.category or "TRANSPORT",
                level = v.level or 1, fuel = v.fuel or 100, hp = v.hp or 0, desc = v.desc or "",
            })
        end
    end

    table.sort(final, function(a, b) return a.name < b.name end)
    return final
end

-- =========================
-- Envoi des listes (JSON compressé)
-- =========================
local function sendCompressed(netName, tbl, ply)
    local data = util.Compress(util.TableToJSON(tbl))
    net.Start(netName)
        net.WriteUInt(#data, 24)
        net.WriteData(data, #data)
    net.Send(ply)
end

function MedalGarage.SendDealerList(ply)
    sendCompressed("MedalGarage_DealerList", {
        vehicles = MedalGarage.GetDealerList(),
        settings = {
            background = tostring(MedalGarage.Settings.background or ""),
            backgroundVolume = tonumber(MedalGarage.Settings.backgroundVolume) or 0,
        },
    }, ply)
end

net.Receive("MedalGarage_AdminList", function(_, ply)
    if not isStaff(ply) then return end
    if not rateOK(ply, "adminlist", 1) then return end
    local discovered = MedalGarage.DiscoverVehicles()
    local rows = {}
    for id, d in pairs(discovered) do
        local ov = MedalGarage.Overrides[id] or {}
        table.insert(rows, {
            id = id, name = d.name, class = d.class, model = d.model, source = d.source,
            enabled = ov.enabled == true,
            category = ov.category or "TRANSPORT",
            level = tonumber(ov.level) or 1,
            fuel = tonumber(ov.fuel) or 100,
            hp = tonumber(ov.hp) or 0,
            customName = ov.name or "",
        })
    end
    table.sort(rows, function(a, b) return a.name < b.name end)
    sendCompressed("MedalGarage_AdminList", rows, ply)
end)

net.Receive("MedalGarage_AdminSet", function(_, ply)
    if not isStaff(ply) then return end
    if not rateOK(ply, "adminset", 0.1) then return end
    local len = net.ReadUInt(24)
    if len <= 0 or len > 32768 then return end
    local data = util.JSONToTable(util.Decompress(net.ReadData(len)) or "") or {}
    local id = tostring(data.id or "")
    if id == "" then return end

    MedalGarage.Overrides[id] = {
        enabled = data.enabled == true,
        name = string.sub(tostring(data.name or ""), 1, 48),
        category = string.sub(tostring(data.category or "TRANSPORT"), 1, 24),
        level = math.Clamp(tonumber(data.level) or 1, 1, 200),
        fuel = math.Clamp(tonumber(data.fuel) or 100, 10, 10000),
        hp = math.Clamp(tonumber(data.hp) or 0, 0, 100000),
        desc = string.sub(tostring(data.desc or ""), 1, 128),
    }
    saveOverrides()
    ply:ChatPrint("[Garage] Véhicule '" .. id .. "' sauvegardé.")
end)

net.Receive("MedalGarage_AdminSettings", function(_, ply)
    if not isStaff(ply) then return end
    if not rateOK(ply, "adminsettings", 0.5) then return end
    MedalGarage.Settings.background = string.sub(tostring(net.ReadString() or ""), 1, 512)
    MedalGarage.Settings.backgroundVolume = math.Clamp(net.ReadFloat() or 0, 0, 1)
    saveSettings()
    ply:ChatPrint("[Garage] Paramètres du garage sauvegardés.")
end)

-- =========================
-- Commandes chat "!" (alias "/") : !garage, !garageconfig (staff).
-- =========================
hook.Add("PlayerSay", "MedalGarage_ChatCommands", function(ply, text)
    if not IsValid(ply) then return end
    local said = string.lower(string.Trim(tostring(text or "")))
    local prefix = string.sub(said, 1, 1)
    if prefix ~= "!" and prefix ~= "/" then return end
    local word = string.sub(said, 2)

    if word == "garage" then
        if not rateOK(ply, "chatcmd", 0.5) then return "" end
        ply:ConCommand(tostring(cfg.Command or "medal_garage"))
        return ""
    elseif word == "garageconfig" then
        if not rateOK(ply, "chatcmd", 0.5) then return "" end
        if not isStaff(ply) then
            ply:ChatPrint("[Garage] Commande réservée au staff.")
            return ""
        end
        ply:ConCommand("medal_garage_config")
        return ""
    end
end)
