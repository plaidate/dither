-- Beacon rendering, all procedural (no image files). The order is the
-- whole trick: sky, sea, Para swell, reefs, hulls and the wreckers all
-- go down FIRST and get composited into the dark by Light.finish, so a
-- hull you have not found is a rumour in the dither. Only then do the
-- things that make their own light get drawn -- stars, riding lights,
-- the tower, the fog that hangs between you and all of it -- followed
-- by the traverse board, the meters and the story furniture.

Draw = {}

local gfx = playdate.graphics
local floor, cos, sin, pi = math.floor, math.cos, math.sin, math.pi
local abs, min, max = math.abs, math.min, math.max

local STARS = {}          -- {x, y, big} built once at init
local poly = {}           -- pooled hull polygon coordinates

-- ---- parallax swell -------------------------------------------------------
-- Three fn layers of wave dashes. Distance reads as tone AND as size:
-- the far rows are short, pale and slow, the near rows long and dark.

local function swell(y0, rows, gap, step, len, hgt, phase)
    return function(ox)
        for i = 0, rows - 1 do
            local y = y0 + i * gap
            local o = (ox * (1 + i * 0.28) + i * 37 + phase) % step
            local x = -step + o
            while x < 400 do
                gfx.fillRect(x, y, len, hgt)
                x = x + step
            end
        end
    end
end

function Draw.init()
    Para.clear()
    Para.layer(swell(C.HORIZON + 5, 4, 9, 46, 13, 1, 0), 0.30, 5)
    Para.layer(swell(C.HORIZON + 44, 4, 13, 58, 19, 1, 11), 0.55, 8)
    Para.layer(swell(C.HORIZON + 100, 4, 19, 74, 27, 2, 23), 0.85, 11)
    for i = 1, 46 do
        STARS[i] = {
            x = math.random(2, 398),
            y = math.random(2, C.HORIZON - 3),
            big = math.random() < 0.18,
        }
    end
end

-- ---- the world (drawn BEFORE the light composite) --------------------------

local function seaAndSky()
    Shade.vgrad(0, 0, 400, C.HORIZON, 15, 12)
    -- open water: a pale noise base, so anything your beam reaches
    -- comes up bright out of the dark
    Shade.fill(0, C.HORIZON, 400, 240 - C.HORIZON, 3, "noise")
    Para.draw(G.t and (G.t * 7) or (G.frame * 0.2))
    gfx.setColor(gfx.kColorBlack)
end

local function reefs()
    for i = 1, G.nRocks do
        local r = G.rocks[i]
        gfx.setColor(gfx.kColorWhite)      -- broken water round the foot
        gfx.drawEllipseInRect(floor(r.x - r.r - 5), floor(r.y - 4),
            floor((r.r + 5) * 2), 13)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(floor(r.x), floor(r.y), floor(r.r * 0.7))
        for k = 0, 4 do                    -- teeth, from the reef's seed
            local a = k * 1.2566 + r.seed * 0.017
            local rr = r.r * (0.75 + 0.5 * ((r.seed * (k + 3)) % 7) / 7)
            gfx.fillTriangle(
                floor(r.x + cos(a) * rr), floor(r.y + sin(a) * rr * 0.7),
                floor(r.x + cos(a + 1.0) * r.r * 0.6),
                floor(r.y + sin(a + 1.0) * r.r * 0.45),
                floor(r.x), floor(r.y))
        end
    end
end

local function land()
    Shade.set(14, "noise")
    gfx.fillPolygon(table.unpack(Game.landPoly, 1, Game.landN))
    gfx.setColor(gfx.kColorWhite)          -- the surf line
    for i = 0, 49 do
        gfx.drawLine(i * 8, Game.shoreY(i * 8), (i + 1) * 8,
            Game.shoreY((i + 1) * 8))
    end
    gfx.setColor(gfx.kColorBlack)
    -- the harbour: two moles and a slip
    gfx.fillRect(C.HARB_X - 26, C.HARB_Y + 4, 9, 20)
    gfx.fillRect(C.HARB_X + 16, C.HARB_Y + 2, 9, 22)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(C.HARB_X - 26, C.HARB_Y + 4, 9, 20)
    gfx.drawRect(C.HARB_X + 16, C.HARB_Y + 2, 9, 22)
    gfx.setColor(gfx.kColorBlack)
end

-- a hull: white body, black outline, so she reads the instant the beam
-- crosses her and vanishes into the dither the instant it leaves
local function hull(s)
    local c, sn = cos(s.hd), sin(s.hd)
    local l, w = s.len * 0.52, s.len * 0.24
    local function shape(el, ew, colour)
        local bx, by = s.x + c * (l + el), s.y + sn * (l + el)
        local ax, ay = s.x - c * (l * 0.86 + el), s.y - sn * (l * 0.86 + el)
        local px, py = -sn * (w + ew), c * (w + ew)
        poly[1], poly[2] = bx, by
        poly[3], poly[4] = s.x + px * 0.9, s.y + py * 0.9
        poly[5], poly[6] = ax + px * 0.7, ay + py * 0.7
        poly[7], poly[8] = ax - px * 0.7, ay - py * 0.7
        poly[9], poly[10] = s.x - px * 0.9, s.y - py * 0.9
        gfx.setColor(colour)
        gfx.fillPolygon(table.unpack(poly, 1, 10))
    end
    shape(1.6, 1.6, gfx.kColorBlack)
    shape(0, 0, gfx.kColorWhite)
    gfx.setColor(gfx.kColorBlack)
    local k = s.kind
    if k == "steamer" then                       -- funnel and a smudge
        gfx.fillRect(floor(s.x - 2), floor(s.y - 3), 4, 6)
        Shade.over(9)
        gfx.fillCircleAtPoint(floor(s.x - c * 9), floor(s.y - sn * 9), 4)
        gfx.setColor(gfx.kColorBlack)
    elseif k == "lifeboat" then                  -- oars
        gfx.drawLine(floor(s.x - sn * 6), floor(s.y + c * 6),
            floor(s.x + sn * 6), floor(s.y - c * 6))
    else                                          -- masts and a yard
        local n = (k == "smack") and 1 or 2
        for i = 1, n do
            local o = (i - 1) * 5 - (n - 1) * 2.5
            local mx, my = s.x + c * o, s.y + sn * o
            gfx.drawLine(floor(mx - sn * 5), floor(my + c * 5),
                floor(mx + sn * 5), floor(my - c * 5))
        end
    end
end

local function ships()
    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.used then hull(s) end
    end
end

local function wreckers()
    for i = 1, 2 do
        local w = G.wreckers[i]
        if w.used then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(floor(w.x - 2), floor(w.y - 12), 5, 12)  -- the man
            gfx.fillCircleAtPoint(floor(w.x), floor(w.y - 14), 3)
            local sw = sin(w.flick * 2.2) * 5                     -- the arm
            gfx.drawLine(floor(w.x), floor(w.y - 9),
                floor(w.x + sw), floor(w.y - 14))
        end
    end
end

-- the casualty the lifeboat is sent to: a half-drowned hull, listing
local function casualty()
    local out = false
    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.used and s.kind == "lifeboat" and s.mode ~= "home" then
            out = true
        end
    end
    if not out then return end
    local x, y = G.lbx, G.lby
    gfx.setColor(gfx.kColorBlack)
    gfx.fillTriangle(x - 8, y + 2, x + 8, y + 2, x + 3, y - 9)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(x + 3, y - 9, x + 9, y - 14)
end

-- ---- things that make their own light (drawn AFTER the composite) ----------

local function stars()
    gfx.setColor(gfx.kColorWhite)
    for i = 1, #STARS do
        local s = STARS[i]
        if not s.big then
            gfx.drawPixel(s.x, s.y)
        elseif (G.frame + i * 7) % 90 > 12 then
            gfx.fillRect(s.x, s.y, 2, 2)
        end
    end
    gfx.setColor(gfx.kColorBlack)
end

-- every hull carries a riding light: a spark you can see in the black
-- long before you can see HER. Finding it with the beam is the game.
local function ridingLights()
    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.used then
            local x, y = floor(s.x), floor(s.y)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(x - 2, y - 8, 5, 5)
            gfx.setColor(gfx.kColorWhite)
            if s.warned then
                gfx.fillRect(x - 1, y - 7, 3, 3)     -- steady: she answers
            elseif (G.frame + s.seq * 11) % 30 < 20 then
                gfx.fillRect(x - 1, y - 7, 2, 2)     -- guttering
            end
            gfx.setColor(gfx.kColorBlack)
        end
    end
end

local function falseLights()
    for i = 1, 2 do
        local w = G.wreckers[i]
        if w.used and not w.out then
            -- a swung lantern: bright, low, and lying about where the
            -- channel is. It flickers; yours does not.
            local f = 3 + sin(w.flick * 5.1) * 1.4
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(floor(w.x + sin(w.flick * 2.2) * 5),
                floor(w.y - 14), floor(f))
            if w.t > 0 then                     -- how close it is to out
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(floor(w.x) - 11, floor(w.y) + 3, 22, 4)
                gfx.setColor(gfx.kColorWhite)
                gfx.drawRect(floor(w.x) - 11, floor(w.y) + 3, 22, 4)
                gfx.fillRect(floor(w.x) - 10, floor(w.y) + 4,
                    floor(20 * min(1, w.t / C.DOUSE_T)), 2)
            end
            gfx.setColor(gfx.kColorBlack)
        end
    end
end

-- the tower itself, always legible: it is the one thing on this screen
-- that is never in doubt
local function tower()
    local x, y = C.LX, C.LY
    gfx.setColor(gfx.kColorBlack)
    gfx.fillTriangle(x - 15, 240, x + 15, 240, x, y - 4)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillTriangle(x - 12, 238, x + 12, 238, x, y - 1)
    gfx.setColor(gfx.kColorBlack)
    for i = 0, 3 do                             -- banded paint
        gfx.fillRect(x - 11 + i, y + 6 + i * 8, 22 - i * 2, 3)
    end
    gfx.fillRect(x - 9, y - 12, 18, 12)         -- the lantern room
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(x - 9, y - 12, 18, 12)
    gfx.fillRect(x - 12, y - 2, 24, 2)          -- the gallery
    if not G.lampOut then
        gfx.fillCircleAtPoint(x, y - 6, 4)      -- the lens, alight
        -- the near throat of the beam, so the aim reads at a glance
        local a = G.dir - G.spread * 0.5
        local b = G.dir + G.spread * 0.5
        gfx.drawLine(x, y - 6, x + cos(a) * 30, y - 6 + sin(a) * 30)
        gfx.drawLine(x, y - 6, x + cos(b) * 30, y - 6 + sin(b) * 30)
    else
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(x, y - 6, 4)
    end
    gfx.setColor(gfx.kColorBlack)
end

local function fog()
    if G.fog <= 0.01 then return end
    -- banks first: white speckle, so fog LIGHTENS the night instead of
    -- darkening it, which is what fog actually does to a beam
    for i = 1, C.FOG_BANKS do
        local b = G.banks[i]
        Shade.wash(floor(2 + G.fog * 8))
        gfx.fillEllipseInRect(floor(b.x - b.w / 2), floor(b.y - b.h / 2),
            floor(b.w), floor(b.h))
    end
    Fade.haze(C.HORIZON, C.HORIZON + 20, 2 + G.fog * 7)
    if G.fog > 0.45 then
        Fade.haze(C.HORIZON, 240, (G.fog - 0.45) * 9)
    end
    gfx.setColor(gfx.kColorBlack)
end

local function hornRing()
    if G.hornT <= 0 then return end
    local u = 1 - G.hornT / 0.7
    gfx.setColor(gfx.kColorWhite)
    gfx.drawCircleAtPoint(C.LX, C.LY - 6, floor(u * C.HORN_R))
    gfx.drawCircleAtPoint(C.LX, C.LY - 6, floor(u * C.HORN_R * 0.72))
    gfx.setColor(gfx.kColorBlack)
end

-- ---- the cabinet -----------------------------------------------------------

-- The HUD board: ONE solid black panel, white-bordered, holding BOTH
-- rows -- the night's tally on top, the traverse compass under it.
-- Fleet rule (glim/skimmer): HUD text sits on solid black, NEVER on
-- dither, and nothing else is allowed to draw into the board's rows.
-- It is exactly as tall as the sky band, so its bottom edge lands on
-- the horizon instead of cutting the sea in half.
local BOARD_H <const> = C.HORIZON       -- rows 1..34
local TICK_Y <const> = 30               -- the compass baseline
local ROW_Y <const> = 2                 -- the text row (ink ~4..16,
                                        -- box bottom ~20, clear of the rule)

-- the traverse board: bearings laid flat. The caret is where the lamp
-- points and how wide it is; the pips are every hull afloat. In a fog
-- this strip is how you aim.
local function traverse()
    local x0, w = 10, 380
    for i = 0, 8 do
        gfx.fillRect(x0 + floor(w * i / 8), TICK_Y, 1, 3)
    end
    local function bx(b)
        return x0 + floor(w * Util.clamp((b + pi) / pi, 0, 1))
    end
    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.used then
            local px = bx(math.atan(s.y - C.LY, s.x - C.LX))
            if s.warned then
                gfx.fillRect(px - 1, 24, 3, 3)
            elseif (G.frame + s.seq * 9) % 24 < 16 then
                gfx.fillRect(px, 23, 2, 5)
            end
        end
    end
    for i = 1, 2 do
        local w2 = G.wreckers[i]
        if w2.used and not w2.out and (G.frame + i * 13) % 18 < 9 then
            local px = bx(math.atan(w2.y - C.LY, w2.x - C.LX))
            gfx.fillRect(px - 2, 24, 5, 2)
        end
    end
    -- the lamp's own caret and its width
    local a = bx(G.dir)
    local l = bx(G.dir - G.spread * 0.5)
    local r = bx(G.dir + G.spread * 0.5)
    gfx.fillRect(l, 27, max(1, r - l), 2)
    gfx.fillTriangle(a - 4, TICK_Y + 2, a + 4, TICK_Y + 2, a, 25)
    gfx.setColor(gfx.kColorBlack)
end

-- night, tally and compass, all inside the one black board
local function topBoard()
    local spec = G.spec
    Kit.panel(4, 1, 392, BOARD_H)
    -- both strings are capped at 18 characters by the longest night
    -- name and the biggest tally, so at any plausible glyph width the
    -- left block ends well before the right block starts
    Kit.text("N" .. G.night .. " " .. spec.name, 12, ROW_Y)
    local tally = "SAFE " .. G.saved .. "/" .. Nights.quota(spec)
        .. "  LOST " .. G.lost .. "/" .. (spec.allow or 1)
    Kit.text(tally, 388 - gfx.getTextSize(tally), ROW_Y)
    gfx.setColor(gfx.kColorWhite)      -- the rule between the two rows
    gfx.fillRect(10, 21, 380, 1)
    traverse()
end

local function hud()
    topBoard()
    -- the two gauges, each on its own solid backing so the labels are
    -- never white-on-dither either. They sit either side of the tower.
    Kit.panel(8, 205, 138, 22)
    Kit.text("OIL", 14, 207)
    Kit.meter(46, 210, 92, 9, G.oil / C.OIL_CAP, G.oil < 20 and 6 or 0)
    Kit.panel(254, 205, 138, 22)
    Kit.text("FOG", 260, 207)
    Kit.meter(292, 210, 92, 9, G.fog, 8)
    if G.lampOut then
        Kit.panel(100, 146, 200, 58)
        Kit.centered("PRIME THE LAMP - CRANK", 150)
        Kit.meter(150, 168, 100, 8, G.prime, 0)
        if G.prime >= 1 and (G.frame % 20) < 13 then
            Kit.centered("A: STRIKE", 182)
        end
    end
    -- a chevron over anything about to be on the rocks: readability
    -- beats atmosphere, always. Clamped clear of the board -- a marker
    -- allowed into those rows is what chewed the status text before.
    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.used and not s.warned and s.kind ~= "lifeboat" then
            local vy = sin(s.hd) * s.spd
            if vy > 1 and (Game.shoreY(s.x) - s.y) / vy < 3.2 then
                Kit.marker(s.x, max(s.y - 12, C.HORIZON + 12),
                    G.frame * C.DT)
            end
        end
    end
end

local function titleScreen()
    Kit.panel(46, 16, 308, 208)
    Kit.bigCentered("BEACON", 20, 3)
    Kit.centered("keeper of Vesper Rock    BEST " .. Kit.best, 72)
    Kit.centered("Crank turns the beam    Up/Down the shutter", 92)
    Kit.centered("A lens surge    B fog horn", 108)
    Kit.centered("A hull steers only while your light is on her", 124)
    Kit.list("", G.menu, G.sel, 130, 142, 140)
end

local function briefScreen()
    local spec = G.spec or Nights.get(G.night)
    Kit.panel(34, 44, 332, 158)
    Kit.text("NIGHT " .. G.night .. " OF " .. Nights.COUNT, 48, 50)
    Kit.bigCentered(spec.name, 64, 2)
    Kit.centered(spec.line, 100)
    Kit.centered("Hulls expected " .. spec.ships
        .. "     Wrecks allowed " .. (spec.allow or 1), 122)
    Kit.centered("Oil in the can " .. spec.oil
        .. "     Fog to " .. floor(spec.fog1 * 100) .. "%", 140)
    local extra = spec.wreckers and "FALSE LIGHTS ON THE HEADLAND"
        or spec.lifeboat and "THE LIFEBOAT GOES OUT TONIGHT"
        or spec.wind and "A SQUALL WILL FIGHT YOUR HAND"
        or ""
    Kit.centered(extra, 158)
    Kit.centered("A: light the lamp", 178)
end

local function resultScreen()
    local why = (G.result == "clear") and "NIGHT CLEAR"
        or (G.result == "dry") and "THE OIL IS OUT" or "WRECKED"
    Kit.over(why, {
        "Stood off " .. G.saved .. "     Lost " .. G.lost,
        "Oil left " .. floor(G.oil + 0.5)
            .. "     Fog " .. floor(G.fog * 100) .. "%",
        (G.result == "clear") and "A: the next night"
            or "A: stand this watch again",
    })
end

local function doneScreen()
    Kit.panel(40, 30, 320, 180)
    Kit.bigCentered("DAWN", 34, 3)
    Kit.centered("Ten nights on Vesper Rock", 90)
    Kit.centered("Hulls stood off  " .. G.totalSaved
        .. "     Hulls lost  " .. G.totalLost, 112)
    Kit.centered("False lights doused  " .. G.totalDoused
        .. "     Rescues  " .. G.totalRescues, 130)
    Kit.centered("BEST " .. Kit.best, 148)
    Kit.centered("A: hand over the watch", 182)
end

-- ---- the frame ---------------------------------------------------------------

function Draw.frame()
    Kit.applyShake()
    seaAndSky()
    reefs()
    land()
    casualty()
    wreckers()
    ships()
    Light.finish()          -- the night falls on everything above
    stars()
    ridingLights()
    falseLights()
    hornRing()
    tower()
    Kit.drawParts(G.parts)
    fog()
    Kit.doneShake()

    local m = Kit.mode
    if m == "play" then
        hud()
        if G.irisT > 0 then Fade.iris(C.LX, C.LY - 6, G.irisT) end
    elseif m == "title" then
        titleScreen()
    elseif m == "slots" then
        Kit.slots(G.slotSel, 110, 52, 180)
        Kit.centered("A: take this slot     B: back", 176)
    elseif m == "brief" then
        briefScreen()
    elseif m == "result" then
        resultScreen()
    elseif m == "done" then
        doneScreen()
    end
    Story.draw()            -- letterbox, dialogue, veil, iris, flash
end
