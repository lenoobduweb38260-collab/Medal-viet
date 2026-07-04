--[[
    Medal Frontline — HUD (client).
    Barre de secteurs en haut de l'écran façon Hell Let Loose : segments en
    ruban inclinés, cadenas sur les secteurs verrouillés, remplissage de
    progression sur les secteurs actifs, timer au centre, et compteur des
    joueurs ACTIFS des deux camps (AFK > 5 min exclus, calcul serveur).
]]

if SERVER then return end

MedalFrontline = MedalFrontline or {}
local cfg = MedalFrontline.Config or {}

local function S(v)
    return math.Round(v * math.min(ScrW() / 1920, ScrH() / 1080))
end

surface.CreateFont("MFront_Timer", {font = "Roboto Condensed", size = 26, weight = 1000, extended = true})
surface.CreateFont("MFront_Small", {font = "Roboto Condensed", size = 13, weight = 800, extended = true})
surface.CreateFont("MFront_Zone", {font = "Roboto Condensed", size = 16, weight = 900, extended = true})
surface.CreateFont("MFront_Count", {font = "Roboto Condensed", size = 18, weight = 950, extended = true})

local COL_NEUTRAL = Color(120, 122, 112)
local COL_WHITE = Color(232, 234, 222)

local FAC1 = (cfg.Factions or {})[1] or "americans"
local FAC2 = (cfg.Factions or {})[2] or "vietcong"

-- État synchronisé par le serveur.
MedalFrontline.State = MedalFrontline.State or {mode = "warfare", active = false, attacker = FAC1, zones = {}, tickets = {}, endTime = 0}
local state = MedalFrontline.State

net.Receive("MedalFrontline_Sync", function()
    state.mode = net.ReadString()
    state.active = net.ReadBool()
    state.attacker = net.ReadString()
    state.endTime = net.ReadFloat()
    state.tickets = {[FAC1] = net.ReadInt(16), [FAC2] = net.ReadInt(16)}
    local count = net.ReadUInt(4)
    state.zones = {}
    for i = 1, count do
        state.zones[i] = {
            name = net.ReadString(),
            owner = net.ReadString(),
            progress = net.ReadInt(8),
            locked = net.ReadBool(),
            contested = net.ReadBool(),
            pos = net.ReadVector(),
            radius = net.ReadFloat(),
        }
    end
    MedalFrontline.State = state
    if IsValid(MedalFrontline.StaffFrame) and MedalFrontline.StaffFrame.Rebuild then MedalFrontline.StaffFrame:Rebuild() end
end)

local function facColor(fac)
    return (cfg.FactionColors or {})[fac] or COL_NEUTRAL
end

local function facName(fac)
    return (cfg.FactionNames or {})[fac] or string.upper(tostring(fac))
end

-- Segment en ruban incliné façon HLL.
local function drawSegment(x, y, w, h, skew, col, alpha)
    draw.NoTexture()
    surface.SetDrawColor(col.r, col.g, col.b, alpha)
    surface.DrawPoly({
        {x = x + skew, y = y},
        {x = x + w, y = y},
        {x = x + w - skew, y = y + h},
        {x = x, y = y + h},
    })
end

hook.Add("HUDPaint", "MedalFrontline_HUD", function()
    local hc = cfg.HUD or {}
    if hc.Enabled == false then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if ply:GetNWBool("MedalBarracks_InMenu", false) then return end

    local zones = {}
    for _, z in ipairs(state.zones or {}) do
        if not z.hidden then table.insert(zones, z) end
    end
    if state.mode == "skirmish" then
        -- Escarmouche : seul le point central est affiché.
        local visible = {}
        for _, z in ipairs(zones) do
            if not z.locked or z.contested or z.owner ~= "" then table.insert(visible, z) end
        end
        if #visible > 0 then zones = visible end
    end
    if #zones == 0 then return end

    local segW = S(tonumber(hc.SegmentW) or 96)
    local segH = S(tonumber(hc.SegmentH) or 26)
    local gap = S(tonumber(hc.SegmentGap) or 6)
    local skew = S(tonumber(hc.Skew) or 10)
    local totalW = #zones * segW + (#zones - 1) * gap
    local x0 = ScrW() / 2 - totalW / 2
    local y = S(tonumber(hc.Y) or 14)

    -- Timer centré au-dessus de la barre.
    if hc.ShowTimer ~= false and state.active then
        local remain = math.max(0, state.endTime - CurTime())
        local txt = string.format("%d:%02d:%02d", math.floor(remain / 3600), math.floor(remain / 60) % 60, math.floor(remain) % 60)
        draw.SimpleText(txt, "MFront_Timer", ScrW() / 2, y, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        y = y + S(30)
    end

    -- Ordre de capture au-dessus de la barre (s'adapte au nombre de zones).
    -- Warfare : flèches depuis chaque camp vers le centre.
    -- Offensive : flèches dans le sens d'attaque, numéros d'ordre 1..N.
    if hc.ShowOrder ~= false and #zones > 1 and state.mode ~= "skirmish" then
        local oy = y - S(15)
        for i = 1, #zones - 1 do
            local ax = x0 + (i - 1) * (segW + gap) + segW + gap / 2
            local dir, acol = 1, COL_NEUTRAL
            if state.mode == "offensive" then
                dir = state.attacker == FAC2 and -1 or 1
                acol = facColor(state.attacker)
            else
                -- Warfare : moitié gauche pousse à droite, moitié droite à gauche.
                dir = i < #zones / 2 and 1 or -1
                acol = facColor(dir == 1 and FAC1 or FAC2)
            end
            local cx = ax
            local aw = S(8)
            surface.SetDrawColor(acol.r, acol.g, acol.b, 200)
            -- Petite flèche triangulaire.
            draw.NoTexture()
            if dir == 1 then
                surface.DrawPoly({{x = cx - aw, y = oy - aw}, {x = cx + aw, y = oy}, {x = cx - aw, y = oy + aw}})
            else
                surface.DrawPoly({{x = cx + aw, y = oy - aw}, {x = cx - aw, y = oy}, {x = cx + aw, y = oy + aw}})
            end
        end
        if state.mode == "offensive" then
            -- Numéro d'ordre de capture sur chaque secteur (1 = premier à prendre).
            local order = {}
            local defender = state.attacker == FAC1 and FAC2 or FAC1
            local seq = 1
            local rng = state.attacker == FAC1 and 1 or #zones
            local step = state.attacker == FAC1 and 1 or -1
            for k = 0, #zones - 1 do
                local idx = rng + step * k
                if zones[idx] and zones[idx].owner == defender then order[idx] = seq; seq = seq + 1 end
            end
            for idx, num in pairs(order) do
                local nx = x0 + (idx - 1) * (segW + gap) + segW / 2
                draw.SimpleText("#" .. num, "MFront_Small", nx, oy - S(16), facColor(state.attacker), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end
        end
    end

    for i, z in ipairs(zones) do
        local x = x0 + (i - 1) * (segW + gap)
        local col = z.owner ~= "" and facColor(z.owner) or COL_NEUTRAL
        local alpha = z.locked and 120 or 215

        drawSegment(x, y, segW, segH, skew, Color(10, 12, 9), 170)
        drawSegment(x + S(2), y + S(2), segW - S(4), segH - S(4), skew, col, alpha)

        -- Progression de capture sur les secteurs actifs (remplissage blanc).
        if not z.locked and z.progress ~= 0 and math.abs(z.progress) < 100 then
            local t = math.abs(z.progress) / 100
            local fillCol = facColor(z.progress > 0 and FAC1 or FAC2)
            drawSegment(x + S(2), y + segH - S(6), (segW - S(4)) * t, S(4), skew * 0.2, Color(fillCol.r, fillCol.g, fillCol.b), 255)
        end

        -- Contesté : liseré blanc qui pulse.
        if z.contested then
            local pulse = 120 + math.abs(math.sin(CurTime() * 3.5)) * 120
            drawSegment(x, y, segW, S(2), skew, COL_WHITE, pulse)
            drawSegment(x, y + segH - S(2), segW, S(2), skew, COL_WHITE, pulse)
        end

        -- Cadenas sur les secteurs verrouillés.
        if z.locked then
            draw.SimpleText("🔒", "MFront_Small", x + segW / 2, y + segH / 2, Color(232, 234, 222, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Escarmouche : tickets des deux camps autour de la barre.
    if state.mode == "skirmish" and state.active then
        draw.SimpleText(math.Round(state.tickets[FAC1] or 0), "MFront_Count", x0 - S(24), y + segH / 2, facColor(FAC1), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(state.tickets[FAC2] or 0), "MFront_Count", x0 + totalW + S(24), y + segH / 2, facColor(FAC2), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- "Tab" des joueurs ACTIFS des deux camps (AFK > 5 min exclus côté serveur).
    if hc.ShowActiveCounts ~= false then
        local c1 = GetGlobalInt("MedalFrontline_Active_" .. FAC1, 0)
        local c2 = GetGlobalInt("MedalFrontline_Active_" .. FAC2, 0)
        local cy = y + segH + S(8)
        draw.SimpleText(facName(FAC1) .. "  " .. c1, "MFront_Count", ScrW() / 2 - S(30), cy, facColor(FAC1), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText("ACTIFS", "MFront_Small", ScrW() / 2, cy + S(3), Color(232, 234, 222, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(c2 .. "  " .. facName(FAC2), "MFront_Count", ScrW() / 2 + S(30), cy, facColor(FAC2), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- Indicateur de capture quand le joueur est dans un secteur actif.
    if state.active and ply:Alive() then
        for _, z in ipairs(zones) do
            if not z.locked and ply:GetPos():Distance(z.pos) <= (z.radius or 900) then
                local cy = y + segH + S(34)
                local label = z.contested and "SECTEUR CONTESTÉ" or "CAPTURE EN COURS"
                draw.SimpleText(label .. " — " .. z.name, "MFront_Zone", ScrW() / 2, cy, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                local bw = S(260)
                surface.SetDrawColor(10, 12, 9, 180)
                surface.DrawRect(ScrW() / 2 - bw / 2, cy + S(22), bw, S(5))
                local t = (z.progress + 100) / 200
                surface.SetDrawColor(facColor(FAC1))
                surface.DrawRect(ScrW() / 2 - bw / 2, cy + S(22), bw * t, S(5))
                surface.SetDrawColor(facColor(FAC2))
                surface.DrawRect(ScrW() / 2 - bw / 2 + bw * t, cy + S(22), bw * (1 - t), S(5))
                break
            end
        end
    end
end)
