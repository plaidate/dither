-- Skimmer rendering, all procedural (no image files). Frame order is
-- the Scaler contract: sky vgrad + sun -> Para treelines + haze ->
-- Scaler.floor (the rippling water) -> depth queue flush -> shadow +
-- dragonfly (near plane, never scales) -> Light pass -> fades / HUD.
-- Obstacle art is mip ladders built once at boot via ladderFromFn.

Draw = {}

local gfx = playdate.graphics
local floor = math.floor

local LAD = {}  -- kind -> mip ladder
local DFLY = {} -- two wing-shimmer frames
local HAZE      -- depth-shade closure for Scaler.flush

-- ---- boot-time art --------------------------------------------------
-- reeds silhouette dark against the light water bands
local function reedFn(w, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(w // 2 - 2, 8, 4, h - 8)        -- stem
    gfx.fillEllipseInRect(w // 2 - 5, 0, 10, 16) -- seed head
end

local function lilyFn(w, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(0, 0, w, h)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawEllipseInRect(3, 2, w - 6, h - 4)    -- pale inner rim
    gfx.fillTriangle(w // 2, h // 2, w, 0, w, h // 2) -- the notch
end

local MDOTS = { 2, 4, 6, 1, 10, 6, 13, 2, 5, 8, 11, 9, 8, 4 }
local function midgeFn()
    gfx.setColor(gfx.kColorBlack)
    for i = 1, #MDOTS, 2 do
        gfx.fillRect(MDOTS[i], MDOTS[i + 1], 2, 2)
    end
end

-- the dragonfly from behind: white body, dark wing outlines
local function dflyImg(up)
    local img = gfx.image.new(28, 18)
    gfx.pushContext(img)
    gfx.setColor(gfx.kColorBlack)
    local wy = up and 1 or 4
    gfx.drawEllipseInRect(0, wy, 12, 6)      -- fore wings
    gfx.drawEllipseInRect(16, wy, 12, 6)
    gfx.drawEllipseInRect(2, wy + 5, 10, 4)  -- hind wings
    gfx.drawEllipseInRect(16, wy + 5, 10, 4)
    gfx.fillRect(12, 8, 4, 10)               -- tail outline
    gfx.fillEllipseInRect(10, 3, 8, 9)       -- thorax outline
    gfx.fillCircleAtPoint(14, 3, 4)          -- head outline
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(13, 9, 2, 8)                -- white body inside
    gfx.fillEllipseInRect(11, 4, 6, 7)
    gfx.fillCircleAtPoint(14, 3, 2)
    gfx.popContext()
    return img
end

-- ---- parallax treelines (fn layers, pattern preset by Para) ---------
local function farTrees(ox)
    local o = floor(ox) % 48 - 48
    gfx.fillRect(0, C.HORIZON - 12, 400, 12)
    for x = o, 400, 48 do
        gfx.fillCircleAtPoint(x + 20, C.HORIZON - 12, 10)
    end
end

local function nearTrees(ox)
    local o = floor(ox) % 30 - 30
    gfx.fillRect(0, C.HORIZON - 6, 400, 6)
    for x = o, 400, 30 do
        gfx.fillCircleAtPoint(x + 12, C.HORIZON - 6, 7)
    end
end

function Draw.init()
    LAD.reed = Scaler.ladderFromFn(reedFn, 14, 48, 10, 2)
    LAD.lily = Scaler.ladderFromFn(lilyFn, 36, 10, 8, 2)
    LAD.midge = Scaler.ladderFromFn(midgeFn, 16, 12, 6, 2)
    DFLY[1], DFLY[2] = dflyImg(false), dflyImg(true)
    HAZE = Scaler.linearHaze(C.HAZE_Z0, C.HAZE_Z1, C.HAZE_MAX)
    Para.clear()
    Para.layer(farTrees, 0.05, 5)
    Para.layer(nearTrees, 0.12, 9)
end

-- depth-queue drawer: root each sprite on the meandering water (the
-- floor's bend at its row) and x-cull (fn entries skip Scaler's own)
function Draw.obj(sx, sy, s, k, o)
    local l = LAD[o.kind]
    sx = sx + Scaler.bendAt(floor(sy))
    local hw = l.w0 * s * 0.5
    if sx + hw < 0 or sx - hw > 400 then return end
    Scaler.draw(l, sx, sy, s, k)
end

-- two low shade levels; size tuned so the bands stream as ripples
local FLOOR = { stripes = { 2, 5 }, size = 34, band = 2, curve = 0 }

local function pond()
    if G.tod == 2 then -- dusk: dark zenith, glow on the horizon
        Shade.vgrad(0, 0, 400, C.HORIZON, 9, 2)
    else
        Shade.vgrad(0, 0, 400, C.HORIZON, 3, 0)
    end
    local sx = floor(C.SUN_X - Scaler.cam.x * 0.03)
    local sy, r = C.SUN_Y[G.tod], C.SUN_R[G.tod]
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(sx, sy, r)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(sx, sy, r)
    Para.draw(Scaler.cam.x)
    Fade.haze(C.HORIZON - 14, C.HORIZON, 4)
    FLOOR.curve = G.curve
    Scaler.floor(FLOOR)
end

local function actors()
    Scaler.clear()
    for i = 1, #G.obs do
        local o = G.obs[i]
        Scaler.queue(Draw.obj, Game.obsX(o), o.y, o.z, o)
    end
    Scaler.flush(HAZE)
end

-- near plane: the shadow is the height cue -- small and pale when
-- high, wide and dark skimming the lilies
local function dragonfly()
    local pz = Scaler.cam.z + C.PZ
    local sx, sy = Scaler.project(G.px, G.py, pz)
    local _, wy = Scaler.project(G.px, 0, pz)
    local a = G.py / C.PY_HI
    Cast.blob(sx, wy + 1, 20 - a * 12, 9 - a * 5)
    if G.invulnT > 0 and G.frame % 4 < 2 then return sx, sy end
    DFLY[(G.frame // 3) % 2 + 1]:draw(floor(sx) - 14, floor(sy) - 10)
    return sx, sy
end

local function lightPass(sx, sy)
    Light.begin(G.ambient) -- ambient 1 (day) is an exact no-op
    if G.ambient < 1 then Light.add(sx, sy, C.GLOW_R, 0.5) end
    Light.finish()
end

local function hud()
    gfx.fillRect(0, 0, 400, 18) -- ink bar: white HUD text needs it
    Kit.text("SCORE " .. G.score, 8, 4)
    Kit.text(string.format("AIR x%.1f", G.trim), 172, 4)
    for i = 1, C.LIVES do
        local x = 398 - i * 14
        gfx.setColor(gfx.kColorWhite)
        if i <= G.lives then gfx.fillCircleAtPoint(x, 10, 4) end
        gfx.drawCircleAtPoint(x, 10, 4)
    end
    gfx.setColor(gfx.kColorBlack)
end

function Draw.frame()
    Kit.applyShake()
    pond()
    actors()
    local sx, sy = dragonfly()
    Kit.drawParts(G.parts)
    lightPass(sx, sy)
    Kit.doneShake()
    if Kit.mode == "play" then
        if G.wipeT > 0 then Fade.wipe("right", G.wipeT) end
        hud()
    elseif Kit.mode == "title" then
        Kit.title("SKIMMER", {
            "Skim the pond: dodge reeds, eat midges",
            "Lily pads only bite when you fly low",
            "D-pad fly    Crank trim the throttle",
            "B: " .. C.TOD_NAMES[G.tod] .. "    BEST " .. Kit.best,
            "Press A to fly",
        })
    else
        Fade.dissolve(G.dissT)
        Kit.over("DUNKED", {
            "Score: " .. G.score,
            G.newBest and "NEW BEST" or ("BEST " .. Kit.best),
            "A: fly again",
        })
    end
end
