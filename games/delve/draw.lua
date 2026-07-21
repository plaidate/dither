-- Delve rendering: all procedural, no image files. Shade builds the
-- rock, Para gives the shaft depth (its layer callbacks are fed the
-- CAMERA Y here rather than an x -- a vertical parallax out of a
-- horizontal API), Cast anchors the delver, Light composites the
-- darkness over the finished scene and Fade handles the iris in.
--
-- Palette rule, as everywhere in the fleet: the delver is white with a
-- black outline and never sinks into the dither; the things that live
-- down here are black shapes with a single white eye that only exists
-- while Light.at says they are lit.

Draw = {}

local gfx = playdate.graphics
local floor = math.floor
local abs = math.abs
local sin = math.sin

-- ---- parallax ---------------------------------------------------------

-- far bedding planes: the strata you are cutting through
local function strata(oy)
    for i = 0, 8 do
        local y = ((i * 46 + oy * 0.5) % 330) - 44
        gfx.fillRect(C.WALLX, y, C.W - 2 * C.WALLX, 3)
        gfx.fillRect(C.WALLX + 40, y + 18, 120, 2)
        gfx.fillRect(C.W - C.WALLX - 150, y + 30, 96, 2)
    end
end

-- abandoned timbering, closer in and darker
local function timbers(oy)
    for i = 0, 4 do
        local y = ((i * 92 + oy * 0.5) % 420) - 90
        gfx.fillRect(C.WALLX + 8, y, 7, 74)
        gfx.fillRect(C.W - C.WALLX - 15, y, 7, 74)
        gfx.fillRect(C.WALLX + 8, y, C.W - 2 * C.WALLX - 16, 6)
    end
end

function Draw.init()
    Para.clear()
    Para.layer(strata, 0.28, 10)
    Para.layer(timbers, 0.55, 7)
end

-- ---- rock -------------------------------------------------------------

local function slab(s, sy)
    local function band(x0, x1)
        if x1 - x0 < 1 then return end
        Shade.fill(x0, sy, x1 - x0, C.SLAB, 13)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x0, sy, x1 - x0, 1)          -- the walked surface
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(x0, sy + C.SLAB - 1, x1 - x0, 1)
        for x = x0 + 7, x1 - 6, 21 do             -- drill marks
            gfx.fillRect(x, sy + 3, 1, 4)
        end
    end
    if s.hx then
        band(C.WALLX, s.hx)
        band(s.hx + C.HOLE_W, C.W - C.WALLX)
        gfx.setColor(gfx.kColorWhite)             -- lipped hole edges
        gfx.fillRect(s.hx - 2, sy, 2, C.SLAB)
        gfx.fillRect(s.hx + C.HOLE_W, sy, 2, C.SLAB)
        gfx.setColor(gfx.kColorBlack)
    else
        band(C.WALLX, C.W - C.WALLX)
    end
end

local function rockwork(L, cy)
    Shade.fill(0, 0, C.W, C.H, 11, "noise")
    Para.draw(cy)
    -- side walls, solid to the edge of the screen
    Shade.fill(0, 0, C.WALLX, C.H, 14)
    Shade.fill(C.W - C.WALLX, 0, C.WALLX, C.H, 14)
    -- dead rock above the roof and below the sole
    local roofB = Level.top(0) + C.SLAB - cy
    if roofB > 0 then Shade.fill(0, 0, C.W, roofB, 14) end
    local soleT = Level.top(L.floors) + C.SLAB - cy
    if soleT < C.H then
        Shade.fill(0, soleT, C.W, C.H - soleT, 14)
    end
    for j = 0, L.floors do
        local sy = Level.top(j) - cy
        if sy > -C.SLAB - 2 and sy < C.H + 2 then slab(L.slabs[j], sy) end
    end
    -- fallen rock props
    for i = 1, #L.rocks do
        local r = L.rocks[i]
        local y = r.top - cy
        if y > -30 and y < C.H + 10 then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(r.x0 - 1, y - 1, r.x1 - r.x0 + 2,
                r.base - r.top + 2)
            Shade.fill(r.x0, y, r.x1 - r.x0, r.base - r.top, 9)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(r.x0, y, r.x1 - r.x0, 1)
            gfx.setColor(gfx.kColorBlack)
        end
    end
    -- standing water
    for i = 1, #L.pools do
        local p = L.pools[i]
        local y = p.y - cy
        if y > -20 and y < C.H + 20 then
            Shade.fill(p.x0, y - 5, p.x1 - p.x0, 6, 6, "noise")
            gfx.setColor(gfx.kColorWhite)
            for x = floor(p.x0), floor(p.x1) - 1, 4 do
                local w = 2 + floor(sin(x * 0.3 + G.frame * 0.08) + 1)
                gfx.fillRect(x, y - 5, w, 1)
            end
            gfx.setColor(gfx.kColorBlack)
        end
    end
    -- ropes
    for i = 1, #L.ropes do
        local r = L.ropes[i]
        local y0, y1 = r.y0 - cy, r.y1 - cy
        if y1 > -10 and y0 < C.H + 10 then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(r.x - 2, y0, 4, y1 - y0)
            gfx.setColor(gfx.kColorWhite)
            for y = floor(y0), floor(y1), 7 do
                gfx.fillRect(r.x - 1, y, 2, 4)
            end
            gfx.setColor(gfx.kColorBlack)
        end
    end
end

-- ---- fixtures ----------------------------------------------------------

local function glows(L, cy)
    gfx.setColor(gfx.kColorWhite)
    for i = 1, #L.glows do
        local g = L.glows[i]
        local y = g.y - cy
        if y > -8 and y < C.H + 8 then
            for k = 0, 4 do
                local a = g.ph + k * 1.3 + G.frame * 0.02
                gfx.fillRect(floor(g.x + sin(a) * 7),
                    floor(y + sin(a * 1.7) * 5), 2, 2)
            end
        end
    end
    gfx.setColor(gfx.kColorBlack)
end

local function lanterns(L, cy)
    for i = 1, #L.lanterns do
        local l = L.lanterns[i]
        local y = l.y - cy
        if y > -34 and y < C.H + 10 then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(l.x - 2, y - 26, 4, 26)      -- post
            gfx.fillRect(l.x - 8, y - 34, 16, 12)     -- housing
            if l.lit then
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(l.x - 6, y - 32, 12, 8)
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(l.x - 1, y - 30, 2, 4)
                gfx.setColor(gfx.kColorWhite)
                local n = 3 + floor(sin(G.frame * 0.14) + 1)
                for k = 0, n do
                    local a = k * 1.05
                    gfx.fillRect(floor(l.x + math.cos(a) * 13) - 1,
                        floor(y - 28 + sin(a) * 13) - 1, 2, 2)
                end
            else
                gfx.setColor(gfx.kColorWhite)
                gfx.drawRect(l.x - 7, y - 33, 14, 10)
            end
            gfx.setColor(gfx.kColorBlack)
        end
    end
end

local function crates(L, cy)
    for i = 1, #L.crates do
        local c = L.crates[i]
        local y = c.y - cy
        if y > -20 and y < C.H + 10 and c.t <= 0 then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(c.x - 9, y - 13, 18, 13)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRect(c.x - 8, y - 12, 16, 12)
            gfx.drawLine(c.x - 8, y - 12, c.x + 7, y - 1)
            gfx.drawLine(c.x + 7, y - 12, c.x - 8, y - 1)
            gfx.fillRect(c.x - 3, y - 17, 2, 5)   -- flares poking out
            gfx.fillRect(c.x + 1, y - 18, 2, 6)
            gfx.setColor(gfx.kColorBlack)
        end
    end
end

local function hatch(L, cy)
    if L.spec.boss then return end
    local y = L.exitY - cy
    if y < -40 or y > C.H + 10 then return end
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(L.exitX - 15, y - 34, 30, 34)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(L.exitX - 14, y - 33, 28, 33)
    for k = 0, 2 do
        local yy = y - 26 + k * 9 + floor((G.frame * 0.5) % 9)
        gfx.fillTriangle(L.exitX - 7, yy, L.exitX + 7, yy, L.exitX, yy + 6)
    end
    gfx.setColor(gfx.kColorBlack)
end

local function fallers(L, cy)
    for i = 1, #L.fallers do
        local f = L.fallers[i]
        if f.state == "warn" then
            gfx.setColor(gfx.kColorWhite)
            for k = 0, 3 do
                gfx.fillRect(floor(f.x - 4 + (G.frame * 3 + k * 13) % 9),
                    floor(f.ceil - cy + ((G.frame * 4 + k * 11) % 26)), 1, 2)
            end
            gfx.setColor(gfx.kColorBlack)
        elseif f.state == "fall" and f.y then
            local y = f.y - cy
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(f.x - 8, y - 7, 16, 14)
            Shade.fill(f.x - 7, y - 6, 14, 12, 8)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRect(f.x - 7, y - 6, 14, 12)
            gfx.setColor(gfx.kColorBlack)
        end
    end
end

-- ---- flares -------------------------------------------------------------

local function flares(cy)
    for i = 1, #G.flying do
        local f = G.flying[i]
        local y = f.y - cy
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(floor(f.x) - 2, floor(y) - 2, 4, 4)
        for k = 1, 3 do
            gfx.fillRect(floor(f.x - f.vx * k * 0.012),
                floor(y - f.vy * k * 0.012), 2, 2)
        end
        gfx.setColor(gfx.kColorBlack)
    end
    for i = 1, #G.burning do
        local b = G.burning[i]
        local y = b.y - cy
        if y > -20 and y < C.H + 20 then
            local k = math.min(1, b.t / C.FLARE_FADE)
            local r = 3 + floor(k * 3) + (G.frame % 3 == 0 and 1 or 0)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillCircleAtPoint(floor(b.x), floor(y), r + 2)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(floor(b.x), floor(y), r)
            for s = 0, 3 do        -- sparks
                local a = G.frame * 0.4 + s * 1.6
                gfx.fillRect(floor(b.x + math.cos(a) * (r + 4)),
                    floor(y + sin(a) * (r + 4)) - 1, 2, 2)
            end
            gfx.setColor(gfx.kColorBlack)
        end
    end
end

-- ---- the dark things -----------------------------------------------------

local function mobs(L, cy)
    for i = 1, #L.mobs do
        local m = L.mobs[i]
        local x, y = floor(m.x + 0.5), floor(m.y - cy + 0.5)
        if y > -30 and y < C.H + 20 then
            gfx.setColor(gfx.kColorBlack)
            if m.hang then
                gfx.fillRect(x - 1, y - 12, 2, 12)     -- thread
                gfx.fillEllipseInRect(x - 5, y - 4, 10, 13)
            else
                gfx.fillEllipseInRect(x - 9, y - 11, 18, 11)
                for k = -1, 1 do                        -- legs
                    local sw = floor(sin(m.step + k * 2) * 3)
                    gfx.fillRect(x + k * 6 - 1, y - 3, 2, 4)
                    gfx.fillRect(x + k * 6 - 1 + sw, y - 1, 2, 2)
                end
                gfx.fillTriangle(x + m.dir * 9, y - 6,
                    x + m.dir * 15, y - 9, x + m.dir * 9, y - 11)
            end
            if m.lit > 0 then      -- one white eye, only while lit
                gfx.setColor(gfx.kColorWhite)
                local ey = m.hang and (y + 2) or (y - 8)
                gfx.fillRect(x + m.dir * 3 - 1, ey, 2, 2)
                gfx.fillRect(x + m.dir * 3 + 2, ey, 2, 2)
            end
            gfx.setColor(gfx.kColorBlack)
        end
    end
end

local function warden(cy)
    local b = G.boss
    if not b or b.down then return end
    local x, y = floor(b.x), floor(b.y - cy)
    Cast.blob(x, y + 2, 46, 12)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(x - 22, y - 40, 44, 42)
    for k = -2, 2 do              -- limbs braced on the floor
        local a = k * 0.5 + sin(b.eye * 1.4 + k) * 0.16
        gfx.fillTriangle(x, y - 26,
            floor(x + math.cos(a + 1.57) * 34), y,
            floor(x + math.cos(a + 1.57) * 34) + 5, y)
    end
    Shade.over(9)
    gfx.fillEllipseInRect(x - 30, y - 46, 60, 50)
    gfx.setColor(gfx.kColorWhite)
    local blink = (sin(b.eye * 0.8) > -0.9)
    if blink then
        local sq = (b.lit > 0) and 1 or 3     -- it squints in the light
        gfx.fillRect(x - 12 + b.dir * 2, y - 30, 8, sq + 1)
        gfx.fillRect(x + 4 + b.dir * 2, y - 30, 8, sq + 1)
    end
    gfx.setColor(gfx.kColorBlack)
end

-- ---- the delver -----------------------------------------------------------

local function delver()
    local x, y = floor(G.px + 0.5), floor(G.py - G.camy + 0.5)
    if G.invuln > 0 and (G.frame % 6) < 3 then return end
    Cast.blob(x, y + 1, 16, 9)
    local f = G.face
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(x - 6, y - 14, 12, 15)      -- body outline
    gfx.fillCircleAtPoint(x, y - 16, 6)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillEllipseInRect(x - 5, y - 13, 10, 13)
    gfx.fillCircleAtPoint(x, y - 16, 5)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(x - 6, y - 21, 13, 3)                -- helmet brim
    gfx.fillCircleAtPoint(x, y - 21, 5)
    gfx.fillRect(x + f * 2 - 1, y - 16, 2, 2)         -- eye
    -- legs: a two-frame stride while moving on the ground
    local stride = (G.onGround and abs(G.vx) > 8)
        and floor(sin(G.frame * 0.5) * 3) or 0
    gfx.fillRect(x - 4 + stride, y - 2, 3, 3)
    gfx.fillRect(x + 1 - stride, y - 2, 3, 3)
    -- the lamp: a white eye on the helmet, dead when the oil is out.
    -- The two rim ticks are the only readable cue for where the crank
    -- has the beam pointed BEFORE the light lands on anything.
    if G.lamp and G.oil > 0 and G.beamDir then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x + f * 4 - 1, y - 24, 3, 3)
        local lx, ly = x + f * 4, y - 23
        for k = -1, 1, 2 do
            local a = G.beamDir + k * C.LAMP_SPREAD * 0.5
            gfx.drawLine(lx + math.cos(a) * 8, ly + sin(a) * 8,
                lx + math.cos(a) * 19, ly + sin(a) * 19)
        end
        gfx.setColor(gfx.kColorBlack)
    else
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x + f * 4 - 1, y - 24, 3, 3)
        gfx.setColor(gfx.kColorBlack)
    end
    -- flares on the belt
    gfx.setColor(gfx.kColorWhite)
    for i = 1, G.flares do
        gfx.fillRect(x - 5 + (i - 1) * 4, y - 6, 2, 4)
    end
    gfx.setColor(gfx.kColorBlack)
end

-- ---- HUD --------------------------------------------------------------------

local function pips(x, y, n, full)
    for i = 1, n do
        local px = x + (i - 1) * 9
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(px - 1, y - 1, 9, 10)
        gfx.setColor(gfx.kColorWhite)
        if i <= full then
            gfx.fillRect(px, y, 7, 8)
        else
            gfx.drawRect(px, y, 7, 8)
        end
    end
    gfx.setColor(gfx.kColorBlack)
end

-- One black board sized to its OWN string. Nothing here can be too
-- narrow for the text at a wider glyph width, and nothing can grow
-- past `maxw` into whatever sits to its right -- the string is
-- trimmed until it fits rather than the board being allowed to run.
local function labelBoard(x, y, text, maxw)
    local tw = gfx.getTextSize(text)
    while tw > maxw - 14 and #text > 4 do
        text = text:sub(1, #text - 1)
        tw = gfx.getTextSize(text)
    end
    Kit.panel(x, y, tw + 14, 20)
    Kit.text(text, x + 7, y + 3)
end

-- The gauge board: ONE solid black panel across the top holding every
-- readout. Fleet rule (glim/skimmer/beacon): HUD text sits on solid
-- black, NEVER on dither -- white-on-shaft-dither is unreadable, which
-- is exactly what this band used to be. Every slot in here is at a
-- FIXED x sized for the widest plausible glyph, and none of the
-- strings vary in length, so no two blocks can ever collide whatever
-- the depth or the font.
--
--   4 |OIL [======--]  FLARE ###  GRIT ###   LAMP OUT| 396
local BOARD_Y <const> = 1
local BOARD_H <const> = 20
local ROW_Y <const> = BOARD_Y + 3       -- text baseline inside the board
local PIP_Y <const> = BOARD_Y + 5

local function hud()
    local L = G.L
    -- the hurt wash goes UNDER the boards: a white speckle laid over
    -- the HUD would undo the contrast the boards exist to provide
    if G.hurtFlash > 0 then
        Shade.wash(10)
        gfx.fillRect(0, 0, C.W, C.H)
        gfx.setColor(gfx.kColorBlack)
    end

    Kit.panel(4, BOARD_Y, 392, BOARD_H)
    -- oil: the only light you did not have to place, and the only one
    -- that runs out on a clock
    Kit.text("OIL", 12, ROW_Y)
    Kit.meter(44, BOARD_Y + 6, 72, 8, G.oil / C.OIL_MAX,
        (G.oil > 25) and 0 or ((G.frame % 16 < 8) and 0 or 10))
    Kit.text("FLARE", 128, ROW_Y)
    pips(172, PIP_Y, C.FLARE_MAX, G.flares)
    Kit.text("GRIT", 212, ROW_Y)
    pips(250, PIP_Y, C.GRIT_MAX, G.grit)
    if not G.lamp then
        Kit.text("NO LAMP", 292, ROW_Y)
    elseif G.oil <= 0 and G.frame % 20 < 12 then
        Kit.text("LAMP OUT", 292, ROW_Y)
    end

    -- where you are, on its own board so it never sits on the rock.
    -- Capped at 226 so it cannot reach the Warden's board at 238.
    local prog = floor((G.pj - 1) / math.max(1, L.floors - 1) * 100 + 0.5)
    labelBoard(4, C.H - 22, "D" .. G.depth .. " " .. L.spec.name
        .. "  " .. prog .. "%", 226)
    -- the Warden's pressure gets its own two-row board: label over
    -- meter, so the label's length can never crowd the bar
    if G.boss and not G.boss.down then
        Kit.panel(238, C.H - 42, 158, 40)
        Kit.text("WARDEN " .. G.boss.phase .. "/" .. C.BOSS_PHASES,
            246, C.H - 39)
        Kit.meter(248, C.H - 19, 138, 9, G.boss.push / C.BOSS_PUSH, 0)
    end

    if Kit.modeT > 0 and Kit.mode == "play" then
        Kit.panel(8, 90, 384, 56)
        Kit.centered(L.spec.name, 98)
        Kit.centered(L.spec.blurb, 120)
    end
end

-- ---- screens ----------------------------------------------------------------

function Draw.menu()
    Shade.fill(0, 0, C.W, C.H, 12, "noise")
    Para.draw(G.frame * 0.4)
    Shade.fill(0, 0, C.WALLX, C.H, 14)
    Shade.fill(C.W - C.WALLX, 0, C.WALLX, C.H, 14)
    Shade.fill(0, 196, C.W, 44, 14)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 196, C.W, 1)
    gfx.setColor(gfx.kColorBlack)
    Light.finish()
    -- every block on both screens is on a Kit.panel: the backdrop is
    -- dither and nothing legible is allowed to touch it
    if Kit.mode == "title" then
        Kit.panel(90, 10, 220, 78)
        Kit.bigCentered("DELVE", 16, 3)
        Kit.centered("one lamp, three flares", 66)
        Kit.list("PIT HEAD", G.menu, G.menuSel, 118, 94, 164)
        Kit.panel(4, 214, 392, 22)
        Kit.text("BEST " .. Kit.best, 12, 217)
        local hint = "D-PAD  A  B   CRANK AIMS"
        Kit.text(hint, 388 - gfx.getTextSize(hint), 217)
    else
        Kit.slots(G.slotSel, 110, 46, 180)
        Kit.panel(4, 214, 392, 22)
        Kit.centered("A: take this slot     B: back", 217)
    end
end

-- Kit.over's panel is only 244 wide, which the stat lines overrun; the
-- end card draws its own wider board instead
local function doneScreen()
    Kit.panel(30, 56, 340, 134)
    Kit.bigCentered("PIT BOTTOM", 64, 2)
    Kit.centered("Depths delved " .. G.cleared .. "/" .. C.LAST, 102)
    Kit.centered("Lanterns lit " .. G.lanternsLit
        .. "   Flares spent " .. G.flaresSpent, 122)
    Kit.centered("Blackouts " .. G.deaths
        .. "   Time " .. floor(G.runT / 60) .. "m", 142)
    Kit.centered("A: back to the pit head", 166)
end

function Draw.frame()
    if Kit.mode == "title" or Kit.mode == "slots" then
        Draw.menu()
        return
    end
    local L, cy = G.L, G.camy
    Kit.applyShake()
    rockwork(L, cy)
    glows(L, cy)
    hatch(L, cy)
    lanterns(L, cy)
    crates(L, cy)
    fallers(L, cy)
    mobs(L, cy)
    warden(cy)
    flares(cy)
    delver()
    Light.finish()          -- darkness composites over the whole scene
    Kit.drawParts(G.parts)
    Kit.doneShake()
    if G.irisT > 0 then Fade.iris(G.px, G.py - cy, G.irisT) end
    if Kit.mode == "done" then
        Fade.dissolve(0.45)
        doneScreen()
    else
        hud()
    end
    Story.draw()            -- letterbox, dialogue, veil, iris: last
end
