-- Glim rendering, all procedural (no image files). Shade sky +
-- noise-textured floor, Para skyline (moon + hedges as fn layers),
-- palette-rule sprites (white keeper with dark outline; moths dark,
-- swallowed by darkness, one white eye when lit), Light compositing,
-- Fade transitions and the HUD.

Draw = {}

local gfx = playdate.graphics
local floor = math.floor

-- parallax skyline: far fn layer (moon + far hedge) at shade 4 reads
-- pale with distance; near hedge at shade 8 is darker. The camera is
-- static (camx 0) -- the layers are the atmospheric depth.
local function farLayer()
    gfx.fillCircleAtPoint(322, 38, 15) -- the moon
    gfx.fillRect(0, C.HORIZON - 14, 400, 14)
    for x = 0, 400, 34 do
        gfx.fillCircleAtPoint(x + 8, C.HORIZON - 15, 9)
    end
end

local function nearLayer()
    gfx.fillRect(0, C.HORIZON - 7, 400, 7)
    for x = 0, 400, 26 do
        gfx.fillCircleAtPoint(x + 14, C.HORIZON - 8, 8)
    end
end

function Draw.init()
    Para.clear()
    Para.layer(farLayer, 0.1, 4)
    Para.layer(nearLayer, 0.3, 8)
end

local function garden()
    Shade.vgrad(0, 0, 400, C.HORIZON, 13, 10) -- night sky
    Para.draw(0)
    Fade.haze(C.HORIZON - 16, C.HORIZON - 4, 3) -- mist on the hedge
    -- floor: soft noise texture with darker mossy patches
    Shade.fill(0, C.HORIZON, 400, 240 - C.HORIZON, 5, "noise")
    Shade.disc(120, 150, 26, 7, "noise")
    Shade.disc(300, 200, 30, 7, "noise")
    Shade.disc(210, 125, 18, 7, "noise")
    -- low garden walls
    Shade.fill(0, C.HORIZON, 8, 240 - C.HORIZON, 13)
    Shade.fill(392, C.HORIZON, 8, 240 - C.HORIZON, 13)
    Shade.fill(0, 232, 400, 8, 13)
    gfx.setColor(gfx.kColorBlack)
end

local function jar()
    local x, y = C.JARX, C.JARY
    Cast.blob(x, y + 8, 18, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(x - 7, y - 10, 14, 18) -- body outline
    gfx.fillRect(x - 4, y - 13, 8, 4)   -- neck
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(x - 6, y - 9, 12, 16)
    gfx.drawRect(x - 3, y - 12, 6, 2)
    local n = math.min(5, G.score)      -- jarred glimmer inside
    for i = 1, n do
        gfx.fillRect(x - 6 + i * 2, y + 2 - (i % 3) * 3, 2, 2)
    end
    gfx.setColor(gfx.kColorBlack)
end

local function flies()
    gfx.setColor(gfx.kColorWhite)
    for i = 1, #G.flies do
        local f = G.flies[i]
        if f.blink < 3.4 then -- brief dark blink every 4s
            gfx.fillRect(floor(f.x) - 1, floor(f.y) - 1, 2, 2)
        end
    end
    gfx.setColor(gfx.kColorBlack)
end

local function moths()
    for i = 1, #G.moths do
        local m = G.moths[i]
        local x, y = floor(m.x + 0.5), floor(m.y + 0.5)
        local w = (math.sin(m.flap) > 0) and 6 or 3 -- wingbeat
        gfx.setColor(gfx.kColorBlack)
        gfx.fillTriangle(x - w - 1, y - 4, x - 1, y + 1, x - 1, y - 5)
        gfx.fillTriangle(x + w + 1, y - 4, x + 1, y + 1, x + 1, y - 5)
        gfx.fillRect(x - 1, y - 3, 3, 7) -- body
        if Light.at(m.x, m.y) > 0 then   -- one lit eye
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(x, y - 2, 1, 1)
        end
    end
    gfx.setColor(gfx.kColorBlack)
end

local function keeper()
    local x, y = floor(G.px + 0.5), floor(G.py + 0.5)
    Cast.blob(x, y + 4, 16, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x, y - 14, 6)          -- head outline
    gfx.fillEllipseInRect(x - 6, y - 11, 12, 14) -- body outline
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(x, y - 14, 5)
    gfx.fillEllipseInRect(x - 5, y - 10, 10, 12)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(x - 3, y - 15, 2, 2)            -- eyes
    gfx.fillRect(x + 1, y - 15, 2, 2)
    gfx.fillRect(x + 5, y - 12, 2, 5)            -- lantern handle
    gfx.fillRect(x + 3, y - 8, 7, 9)             -- lantern frame
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(x + 4, y - 7, 5, 7)             -- glass
    gfx.setColor(gfx.kColorBlack)
end

local function hud()
    Kit.text("JARRED " .. G.score, 10, 4)
    Kit.text("WICK", 286, 4)
    local w = floor(60 * G.wick / C.WICK_MAX + 0.5)
    local show = G.wick >= C.WARN_AT or (G.frame % 20) < 12
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(326, 5, 64, 12)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(326, 5, 64, 12)
    if show and w > 0 then gfx.fillRect(328, 7, w, 8) end
    gfx.setColor(gfx.kColorBlack)
end

function Draw.frame()
    Kit.applyShake()
    garden()
    jar()
    flies()
    moths()
    keeper()
    Light.finish() -- darkness composites over the whole scene
    Kit.drawParts(G.parts)
    Kit.doneShake()
    if Kit.mode == "play" then
        if G.irisT > 0 then Fade.iris(G.px, G.py, G.irisT) end
        hud()
    elseif Kit.mode == "title" then
        Kit.title("GLIM", {
            "Jar the fireflies before the wick dies",
            "D-pad walk    Crank trim the wick",
            "B shoo moths    Bright burns fast",
            "BEST " .. Kit.best,
            "Press A to light the lantern",
        })
    else
        Fade.dissolve(G.dissT)
        Kit.over("NIGHT'S END", {
            "Fireflies jarred: " .. G.score,
            G.newBest and "NEW BEST" or ("BEST " .. Kit.best),
            "A: keep another night",
        })
    end
end
