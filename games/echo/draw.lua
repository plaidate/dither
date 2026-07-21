-- Echo rendering, all procedural (no image files). Ambient is 0, so
-- the palette is inverted from the rest of the fleet: rock and wings
-- are WHITE with black outlines, because a black sprite in a black
-- cave is nothing at all.
--
-- Frame order:
--   clear to black -> tunnel cross-sections (near to far, each
--   clipped to the previous opening, shaded by distance AND memory)
--   -> Para dust -> the ping front -> Scaler depth queue -> the bat
--   and its floor shadow -> the owl -> Light pass -> Fade/HUD/Story.
--
-- The tunnel is drawn as nested cross-section rectangles rather than
-- with Scaler.floor: floor() only paints BELOW the horizon, and a
-- cave needs a ceiling, two walls and a floor from the same
-- projection. Each ring is clipped to the previous (nearer) opening,
-- which is exactly the occlusion a tube has, and costs 22 pattern
-- fills a frame -- about a third of what Scaler.floor's band loop
-- costs. Everything else on the Super Scaler road is stock:
-- Scaler.project, ladders built once in Draw.init, the depth queue,
-- and Scaler.linearHaze (installed over Game.tone below).

Draw = {}

local gfx = playdate.graphics
local floor, min, max, abs = math.floor, math.min, math.max, math.abs
local clamp = Util.clamp

local LAD = {}   -- kind (+ size) -> mip ladder
local BAT = {}   -- two wing-beat frames, near plane
local W <const>, H <const> = 400, 240

-- ---- boot-time art ------------------------------------------------------

-- a stalactite: base at the ceiling (image top), tip at the bottom, so
-- Scaler's centred-bottom anchor puts the tip exactly on its world y
local function titeFn(w, h)
    local hw = w // 2
    gfx.setColor(gfx.kColorBlack)
    gfx.fillTriangle(0, 0, w, 0, hw, h)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillTriangle(2, 1, w - 2, 1, hw, h - 5)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(hw, 2, hw, h - 8)
    gfx.drawLine(hw - w // 4, 2, hw - 1, h // 2)
    gfx.drawLine(hw + w // 4, 2, hw + 1, h // 2)
end

-- a stalagmite: base on the floor (image bottom), tip at the top
local function miteFn(w, h)
    local hw = w // 2
    gfx.setColor(gfx.kColorBlack)
    gfx.fillTriangle(0, h, w, h, hw, 0)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillTriangle(2, h - 1, w - 2, h - 1, hw, 5)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(hw, 6, hw, h - 2)
    gfx.drawLine(hw - w // 4, h - 2, hw - 1, h // 2)
end

local function pillarFn(w, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, w, h)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(2, 0, w - 4, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(w // 2, 0, w // 2, h)
    gfx.drawLine(2, h // 3, w - 3, h // 3 + 2)
    gfx.drawLine(2, 2 * h // 3, w - 3, 2 * h // 3 - 2)
end

local function mothFn(w, h)
    local cx, cy = w // 2, h // 2
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(0, 1, w, h - 2)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillEllipseInRect(1, 2, cx - 1, h - 4)
    gfx.fillEllipseInRect(cx, 2, cx - 1, h - 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(cx - 1, 2, 2, h - 4)
end

-- a bat seen from behind: white membrane, black outline and face
local function batImg(up, w, h)
    local img = gfx.image.new(w, h)
    local cx = w // 2
    local wy = up and 1 or (h // 2)
    gfx.pushContext(img)
    for pass = 1, 2 do
        local g = pass - 1
        gfx.setColor(pass == 1 and gfx.kColorBlack or gfx.kColorWhite)
        gfx.fillTriangle(1 + g, h - 5 - g, cx, wy + g, cx, h - 4 - g)
        gfx.fillTriangle(w - 1 - g, h - 5 - g, cx, wy + g, cx, h - 4 - g)
        gfx.fillEllipseInRect(cx - 3 + g, h // 3 + g,
            6 - 2 * g, h // 2 - 2 * g)
    end
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(cx, h // 3, 3)
    gfx.fillTriangle(cx - 4, h // 3 - 1, cx - 3, h // 3 - 5, cx - 1, h // 3 - 1)
    gfx.fillTriangle(cx + 4, h // 3 - 1, cx + 3, h // 3 - 5, cx + 1, h // 3 - 1)
    gfx.popContext()
    return img
end

-- ---- Para: the air between you and the rock -------------------------------
-- Not a skyline -- dust and falling water, close to the lens. It is
-- the only thing on screen that moves when you strafe without a
-- glimpse, so it is how the cave tells you the wind is winning.

local DUST = { 30, 44, 96, 18, 150, 200, 210, 70, 268, 132, 322, 36,
    358, 178, 78, 152, 190, 96, 244, 214 }

local function dustFar(ox)
    local o = floor(ox) % 200
    for i = 1, #DUST, 2 do
        local x = (DUST[i] + o) % 400
        gfx.fillRect(x, DUST[i + 1], 2, 2)
    end
end

local function dustNear(ox)
    local o = floor(ox * 1.9) % 200
    for i = 1, #DUST, 4 do
        local x = (DUST[i + 1] * 2 + o) % 400
        gfx.fillRect(x, (DUST[i] + 40) % 236, 2, 3)
    end
end

function Draw.init()
    for i = 1, #C.LEN do
        local len = C.LEN[i]
        local w = 16 + i * 4
        LAD["tite" .. i] = Scaler.ladderFromFn(titeFn, w, len, 10, 2)
        LAD["mite" .. i] = Scaler.ladderFromFn(miteFn, w + 2, len, 10, 2)
    end
    LAD.pillar = Scaler.ladderFromFn(pillarFn, 26, C.CAVEH, 10, 2)
    LAD.moth = Scaler.ladderFromFn(mothFn, 16, 12, 8, 2)
    LAD.rival = Scaler.ladder(batImg(false, 26, 16), 8, 2)
    BAT[1] = batImg(false, 34, 22)
    BAT[2] = batImg(true, 34, 22)
    -- the core's own depth-haze mapper, installed over game.lua's
    -- stand-in: distance reads as tone through exactly one function
    Game.tone = Scaler.linearHaze(C.TONE_Z0, C.TONE_Z1, C.TONE_MAX)
    Para.clear()
    Para.layer(dustFar, 0.9, 12)
    Para.layer(dustNear, 2.2, 8)
end

-- ---- the tunnel ------------------------------------------------------------

-- one cross-section rectangle at world z, already clipped to the
-- previous (nearer) opening. Returns the clipped rect, or nil once
-- the opening has closed to nothing.
local RX0, RY0, RX1, RY1 = 0, 0, W, H

local function tunnel(memFix)
    local cam = Scaler.cam
    local f, hy, cx = Scaler.f, Scaler.horizon, Scaler.cx
    local size = C.RING_SIZE
    local base = floor(cam.z / size)
    local pz = cam.z + C.PZ
    local rock = G.cav.wet and 3 or 5
    gfx.clear(gfx.kColorBlack)
    RX0, RY0, RX1, RY1 = 0, 0, W, H
    for k = 1, C.RINGS do
        local wz = (base + k) * size
        local dz = wz - cam.z
        if dz >= 12 then
            local s = f / dz
            local c, hw = Cave.centerAt(wz), Cave.halfAt(wz)
            local x0 = floor(cx + (c - hw - cam.x) * s)
            local x1 = floor(cx + (c + hw - cam.x) * s)
            local y1 = floor(hy + cam.y * s)
            local y0 = floor(hy + (cam.y - C.CAVEH) * s)
            if x0 < RX0 then x0 = RX0 end
            if x1 > RX1 then x1 = RX1 end
            if y0 < RY0 then y0 = RY0 end
            if y1 > RY1 then y1 = RY1 end
            if x1 <= x0 or y1 <= y0 then break end
            local dzp = wz - pz
            if dzp < 0 then dzp = 0 end
            local m = memFix or Game.memAt(wz, dzp)
            local band = ((base + k) % 2 == 0) and 0 or 2
            local lvl = rock + band + Game.tone(dzp) + (1 - m) * C.FOG
            Shade.set(lvl)
            gfx.fillRect(x0, y0, x1 - x0, y1 - y0)
            if lvl < 10 and k % C.OUTLINE_EVERY == 0 then
                gfx.setColor(gfx.kColorWhite)
                gfx.drawRect(x0, y0, x1 - x0, y1 - y0)
            end
            RX0, RY0, RX1, RY1 = x0, y0, x1, y1
        end
    end
    gfx.setColor(gfx.kColorBlack)
end

-- the sound itself: the cross-section the front has just reached,
-- drawn as a bright ring racing away toward the vanishing point
local function frontRing(dz, bright)
    local cam = Scaler.cam
    local wz = cam.z + C.PZ + dz
    local ddz = wz - cam.z
    if ddz < 20 then return end
    local s = Scaler.f / ddz
    local c, hw = Cave.centerAt(wz), Cave.halfAt(wz)
    local x0 = floor(Scaler.cx + (c - hw - cam.x) * s)
    local x1 = floor(Scaler.cx + (c + hw - cam.x) * s)
    local y1 = floor(Scaler.horizon + cam.y * s)
    local y0 = floor(Scaler.horizon + (cam.y - C.CAVEH) * s)
    if x1 - x0 < 3 or y1 - y0 < 3 then return end
    if bright then
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x0, y0, x1 - x0, y1 - y0)
        gfx.drawRect(x0 + 1, y0 + 1, x1 - x0 - 2, y1 - y0 - 2)
    else
        Shade.wash(9)
        gfx.drawRect(x0, y0, x1 - x0, y1 - y0)
        gfx.setColor(gfx.kColorBlack)
    end
end

-- ---- the depth queue --------------------------------------------------------

-- one queued obstacle. Shade comes from Game.shadeOf, so a thing you
-- have not heard is literally not drawn -- the depth queue is the
-- memory made visible.
function Draw.obj(sx, sy, s, _, o)
    local dz = o.z - Game.playerZ()
    local sh = Game.shadeOf(Game.memOf(o), dz)
    if sh >= 16 then return end
    local k = o.kind
    local l = (k == "tite" or k == "mite") and LAD[k .. o.size] or LAD[k]
    local hw = l.w0 * s * 0.5
    if sx + hw < 0 or sx - hw > W then return end
    Scaler.draw(l, sx, sy, s, sh)
end

-- Vesper: lit by her own call, invisible between them
function Draw.rival(sx, sy, s, _, r)
    local dz = r.z - Game.playerZ()
    local m = r.callT > 0 and 1 or (r.window > 0 and 0.5 or 0.18)
    local sh = Game.shadeOf(m, dz)
    if sh >= 16 then return end
    Scaler.draw(LAD.rival, sx, sy, s, sh)
end

local function actors()
    Scaler.clear()
    local obs = G.obs
    for i = 1, #obs do
        local o = obs[i]
        local k = o.kind
        if k == "moth" then
            Scaler.queue(Draw.obj, Cave.obsX(o), Cave.obsY(o) - 6, o.z, o)
        elseif k == "tite" then
            Scaler.queue(Draw.obj, o.x, Cave.tipY(o), o.z, o)
        else
            Scaler.queue(Draw.obj, o.x, 0, o.z, o)
        end
    end
    local r = G.rival
    if r.on then
        Scaler.queue(Draw.rival, r.x, r.y - 8, r.z, r)
    end
    Scaler.flush()
end

-- ---- the near plane ----------------------------------------------------------

local function bat()
    local pz = Game.playerZ()
    local sx, sy = Scaler.project(G.px, G.py, pz)
    if not sx then return end
    local _, fy = Scaler.project(G.px, 0, pz)
    G.sx, G.sy = sx, sy
    -- the floor shadow is the altimeter: wide and soft up high, tight
    -- and dark when you are about to clip a stalagmite
    local a = G.py / C.CAVEH
    Cast.blob(sx, fy, 26 - a * 14, 11 - a * 6)
    if G.invulnT > 0 and G.frame % 4 < 2 then return end
    BAT[(G.frame // 3) % 2 + 1]:draw(floor(sx) - 17, floor(sy) - 11)
end

-- the owl is BEHIND you: it has no z to project, so it looms up out
-- of the bottom of the frame as its distance closes
local function owl()
    local o = G.owl
    if not o.on then return end
    local u = 1 - clamp(o.d / C.OWL_MAX, 0, 1)
    if u < 0.06 then return end
    local w = floor(70 + u * u * 460)
    local cy = floor(300 - u * 140) + (o.hitT > 0 and math.random(-4, 4) or 0)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(200 - w // 2, cy - w // 3, w, w)
    Shade.set(clamp(13 - u * 8, 2, 14))
    gfx.fillEllipseInRect(200 - w // 2 + 3, cy - w // 3 + 3, w - 6, w - 6)
    gfx.setColor(gfx.kColorBlack)
    -- the eyes: two pale discs that always read, whatever the dither
    local ex = floor(w * 0.19)
    local er = max(2, floor(w * 0.075))
    local ey = cy - floor(w * 0.14)
    for s = -1, 1, 2 do
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(200 + s * ex, ey, er)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(200 + s * ex, ey, max(1, er // 2))
    end
    -- beak
    gfx.setColor(gfx.kColorWhite)
    gfx.fillTriangle(200 - er, ey + er, 200 + er, ey + er,
        200, ey + er * 3)
    gfx.setColor(gfx.kColorBlack)
end

-- ---- the light pass ------------------------------------------------------------

local function lightPass()
    Light.begin(0) -- there is no ambient light under the hill. None.
    if G.pingT > 0 then
        local u = 1 - G.pingT / C.PING_LIFE
        local r = C.PING_R0 + (G.pingR1 - C.PING_R0) * u
        local f = C.PING_F0 + (C.PING_F1 - C.PING_F0) * u
        Light.add(G.sx, G.sy, r, f)
    end
    if G.wetT > 0 then
        local u = 1 - G.wetT / C.WET_LIFE
        Light.add(G.sx, G.sy + 30, C.WET_R * (0.5 + u * 0.5), C.WET_F)
    end
    -- moth glows: the only thing in the cave that shines on its own,
    -- capped so the light budget stays at four sources worst case
    local n = 0
    local obs = G.obs
    local pz = Game.playerZ()
    for i = 1, #obs do
        if n >= C.MOTH_LIGHTS then break end
        local o = obs[i]
        if o.kind == "moth" then
            local dz = o.z - pz
            if dz > 10 and dz < C.MOTH_LIGHT_Z then
                local sx, sy, s = Scaler.project(Cave.obsX(o),
                    Cave.obsY(o), o.z)
                if sx and sx > -40 and sx < W + 40 then
                    Light.add(sx, sy, C.MOTH_R * min(1.2, s + 0.25), 0.35)
                    n = n + 1
                end
            end
        end
    end
    local r = G.rival
    if r.on and r.callT > 0 then
        local sx, sy = Scaler.project(r.x, r.y, r.z)
        if sx then
            local u = 1 - r.callT / C.RIVAL_LIFE
            Light.add(sx, sy, C.RIVAL_R * (0.4 + u * 0.6), 0.3)
        end
    end
    -- the last frame's answer to "is my own light on me?" -- the owl
    -- reads this, so seeing and being seen are the same query
    G.lit = Light.at(G.sx, G.sy)
    Light.finish()
end

-- ---- HUD ---------------------------------------------------------------------

local function hud()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, W, 16)
    Kit.text(G.cavI .. ". " .. G.cav.name, 6, 1)
    Kit.text("MOTHS " .. G.moths, 250, 1)
    for i = 1, (G.cav.lives or C.LIVES) do
        local x = 396 - i * 12
        gfx.setColor(gfx.kColorWhite)
        if i <= G.lives then gfx.fillCircleAtPoint(x, 8, 4) end
        gfx.drawCircleAtPoint(x, 8, 4)
    end
    gfx.setColor(gfx.kColorBlack)
    -- breath (stamina) and progress
    gfx.fillRect(0, H - 18, W, 18)
    Kit.text("BREATH", 6, H - 16)
    Kit.meter(60, H - 14, 96, 9, G.stam / C.STAM_MAX,
        G.stam < C.PING_COST and 8 or 0)
    Kit.text("DEPTH", 176, H - 16)
    Kit.meter(224, H - 14, 96, 9, clamp(G.dist / G.cav.len, 0, 1), 4)
    if G.owl.on then
        local u = 1 - clamp(G.owl.d / C.OWL_MAX, 0, 1)
        if u > 0.55 and G.frame % 20 < 12 then
            Kit.text("BEHIND YOU", 330, H - 16)
        else
            Kit.text(string.format("OWL %d", floor(G.owl.d)), 330, H - 16)
        end
    elseif G.whisper and G.pingT > 0 then
        Kit.text("whisper", 336, H - 16)
    end
end

-- ---- screens -------------------------------------------------------------------

local function scene()
    tunnel()
    Para.draw(Scaler.cam.x * 2 + G.time * 8)
    if G.pingT > 0 then
        frontRing(G.front, not G.whisper)
        if G.front > 150 then frontRing(G.front * 0.62, false) end
    end
    if G.wetT > 0 then
        frontRing(C.PING_REACH * C.WET_REACH * (1 - G.wetT / C.WET_LIFE),
            false)
    end
    actors()
    bat()
    owl()
    Kit.drawParts(G.parts)
    lightPass()
    -- readability beats atmosphere: after the darkness is composited,
    -- one white pip says "you are here" whatever the dither did
    if Kit.mode == "play" and not (G.invulnT > 0 and G.frame % 4 < 2) then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(floor(G.sx) - 2, floor(G.sy) - 2, 4, 4)
        gfx.setColor(gfx.kColorBlack)
    end
end

-- Menus and cutscenes run over a slow drift through the SELECTED
-- cavern, half-remembered: the same tunnel renderer at a fixed memory
-- level, with a slow pulse of light wandering across it. No actors --
-- the obstacle list still holds the last flight's rock, and drawing
-- it at a camera that has nothing to do with that flight would be a
-- lie the player can see.
local function backdrop()
    local cam = Scaler.cam
    cam.z = G.time * 62
    cam.x = math.sin(G.time * 0.3) * 14
    cam.y = C.MID
    tunnel(0.42)
    Para.draw(cam.x * 2 + G.time * 8)
    local u = (G.time * 0.55) % 1
    frontRing(60 + u * 620, false)
    Light.begin(0)
    Light.add(200 + math.sin(G.time * 0.41) * 90,
        120 + math.sin(G.time * 0.63) * 40,
        120 + math.sin(G.time * 1.7) * 26, 0.35)
    Light.finish()
end

local function titleScreen()
    Kit.title("ECHO", {
        "A bat under a hill with no light in it",
        "A: call    D-pad: fly    Crank: throttle",
        "You fly on a map that is going out",
        "Press A",
    })
end

local function mapScreen()
    local sel = G.mapSel - G.mapTop + 1
    Kit.list("CAVERNS", G.mapRows, sel, 62, 34, 276)
    local cv = C.CAVERNS[G.mapSel]
    Kit.panel(62, 176, 276, 46)
    if G.mapSel > Game.unlocked() then
        Kit.centered("-- not yet heard --", 190)
    else
        Kit.centered(cv.brief, 182)
        local t = Save.get("t" .. G.mapSel, 0)
        Kit.centered(t > 0 and string.format("best %.1fs", t)
            or "A to fly    B to change slot", 200)
    end
end

local function clearScreen()
    Fade.dissolve(G.dissT)
    Kit.over("CLEAR", {
        G.cav.name,
        string.format("%.1fs    %d moths", G.runT, G.moths),
        "A to go on",
    })
end

local function failScreen()
    Fade.dissolve(G.dissT)
    Kit.over("GROUNDED", {
        G.cav.name .. "  --  " .. floor(G.dist) .. " of " .. G.cav.len,
        "A: fly it again    B: the map",
    })
end

local function endScreen()
    Fade.dissolve(0.5)
    local moths, best = 0, 0
    for i = 1, C.NCAV do
        moths = moths + max(0, Save.get("m" .. i, 0))
        best = best + max(0, Save.get("t" .. i, 0))
    end
    Kit.panel(40, 22, 320, 198)
    Kit.bigCentered("THE ROOST", 28, 2)
    Kit.centered("Pip flew ten caverns blind", 66)
    Kit.centered("and brought the roost through", 84)
    Kit.centered(C.NCAV .. " caverns    " .. moths .. " moths", 112)
    Kit.centered(string.format("%.1fs of best flights", best), 130)
    Kit.centered("pings drawn with core/light.lua", 158)
    Kit.centered("cave drawn with core/scaler.lua", 174)
    Kit.centered("A", 198)
end

function Draw.frame()
    Kit.applyShake()
    local m = Kit.mode
    if m == "play" or m == "clear" or m == "fail" then
        scene()
    else
        backdrop()
    end
    Kit.doneShake()
    if m == "play" then
        if G.wipeT > 0 then Fade.wipe("right", G.wipeT) end
        hud()
    elseif m == "title" then
        titleScreen()
    elseif m == "slots" then
        Kit.slots(G.slotSel, 110, 56, 180)
        Kit.centered("A: take this roost    B: back", 214)
    elseif m == "map" then
        mapScreen()
    elseif m == "clear" then
        clearScreen()
    elseif m == "fail" then
        failScreen()
    elseif m == "end" then
        endScreen()
    end
    Story.draw()
end
