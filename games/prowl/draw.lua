-- Prowl rendering, entirely procedural (no image files). The scene is
-- drawn flat and bright, and then Light.finish() lays the night over
-- it: crates become silhouettes, the guard's wedge becomes the only
-- thing you can read, and the cat in a doorway shadow is genuinely
-- hard to see -- which is the point, so the two white eye pixels and
-- the HUD's HIDDEN/SEEN word are drawn AFTER the composite and never
-- get dithered away.

Draw = {}

local gfx = playdate.graphics
local floor, sin, cos = math.floor, math.sin, math.cos

local HUD_H <const> = 22

function Draw.init() end

-- ---- the floor ---------------------------------------------------------

local function ground()
    -- cobbles: blue-noise mid gray with a few darker puddles
    Shade.fill(0, HUD_H, 400, 240 - HUD_H, 5, "noise")
    Shade.disc(120, 90, 40, 7, "noise")
    Shade.disc(300, 170, 46, 7, "noise")
    Shade.disc(210, 210, 34, 7, "noise")
    -- the stone band that bounds the room; every heist is one screen
    local b = C.BORDER
    Shade.fill(0, C.Y0 - b, 400, b, 13)
    Shade.fill(0, C.Y1, 400, 240 - C.Y1, 13)
    Shade.fill(C.X0 - b, C.Y0 - b, b, C.Y1 - C.Y0 + 2 * b, 13)
    Shade.fill(C.X1, C.Y0 - b, b, C.Y1 - C.Y0 + 2 * b, 13)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(C.X0 - 1, C.Y0 - 1, C.X1 - C.X0 + 2, C.Y1 - C.Y0 + 2)
    gfx.setColor(gfx.kColorBlack)
end

-- ---- occluders ---------------------------------------------------------
-- Black body, white outline: the palette rule that keeps the town
-- legible once two bands of darkness are sitting on top of it.

local function box(q)
    local x, y, w, h, k = q.x, q.y, q.w, q.h, q.k
    Cast.blob(x + w / 2, y + h + 3, w, 9)
    gfx.setColor(gfx.kColorBlack)
    if k == "barrel" then
        gfx.fillEllipseInRect(x, y, w, h)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawEllipseInRect(x, y, w, h)
        gfx.drawLine(x + 2, y + h * 0.35, x + w - 2, y + h * 0.35)
        gfx.drawLine(x + 2, y + h * 0.7, x + w - 2, y + h * 0.7)
    elseif k == "pillar" then
        gfx.fillEllipseInRect(x - 2, y - 2, w + 4, h + 4)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawEllipseInRect(x - 2, y - 2, w + 4, h + 4)
        gfx.drawEllipseInRect(x + 2, y + 2, w - 4, h - 4)
    elseif k == "wall" or k == "tower" then
        Shade.fill(x, y, w, h, 15)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x, y, w, h)
        -- courses of stone
        local n = floor(h / 12)
        for i = 1, n - 1 do
            gfx.drawLine(x + 1, y + i * 12, x + w - 1, y + i * 12)
        end
        if k == "tower" then
            gfx.drawRect(x + 12, y + 10, w - 24, h - 26)
            gfx.fillTriangle(x + w / 2 - 8, y + h - 12,
                x + w / 2 + 8, y + h - 12, x + w / 2, y + h - 26)
        end
    elseif k == "cart" then
        gfx.fillRect(x, y, w, h)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x, y, w, h)
        gfx.drawLine(x + 4, y, x + 4, y + h)
        gfx.drawLine(x + w - 4, y, x + w - 4, y + h)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(x + 8, y + h, 5)
        gfx.fillCircleAtPoint(x + w - 8, y + h, 5)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(x + 8, y + h, 5)
        gfx.drawCircleAtPoint(x + w - 8, y + h, 5)
    elseif k == "tomb" or k == "plinth" then
        gfx.fillRect(x, y, w, h)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x, y, w, h)
        gfx.fillRect(x + 2, y + 2, w - 4, 3)      -- lit top slab
        gfx.drawLine(x + w / 2, y + 6, x + w / 2, y + h - 3)
    else -- crate
        gfx.fillRect(x, y, w, h)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x, y, w, h)
        gfx.drawLine(x, y, x + w, y + h)
        gfx.drawLine(x + w, y, x, y + h)
    end
    gfx.setColor(gfx.kColorBlack)
end

-- ---- lamps -------------------------------------------------------------

local function lamp(l)
    local x, y = floor(l.x), floor(l.y)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(x - 2, y, 4, 14)                 -- post
    gfx.fillRect(x - 6, y - 12, 12, 12)           -- housing
    if l.out then
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x - 6, y - 12, 12, 12)
        gfx.drawLine(x - 4, y - 10, x + 4, y - 2) -- a dead X
        gfx.drawLine(x + 4, y - 10, x - 4, y - 2)
    else
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x - 5, y - 11, 10, 10)
        gfx.setColor(gfx.kColorBlack)
        local f = (sin(l.flick * 7) > 0.6) and 1 or 0
        gfx.fillRect(x - 2, y - 8 + f, 4, 5)      -- the flame's shadow
        gfx.setColor(gfx.kColorWhite)
    end
    if l.douse and not l.out then                 -- a pinchable wick
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(x - 8, y - 15, x - 5, y - 15)
        gfx.drawLine(x + 5, y - 15, x + 8, y - 15)
    end
    gfx.setColor(gfx.kColorBlack)
end

-- ---- loot --------------------------------------------------------------

local function lootIcon(k, x, y)
    gfx.setColor(gfx.kColorBlack)
    if k == "coin" then
        gfx.fillCircleAtPoint(x, y, 6)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(x, y, 5)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(x, y, 3)
    elseif k == "fish" then
        gfx.fillEllipseInRect(x - 8, y - 5, 13, 10)
        gfx.fillTriangle(x + 4, y, x + 9, y - 5, x + 9, y + 5)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillEllipseInRect(x - 7, y - 4, 11, 8)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(x - 4, y - 2, 2, 2)
    elseif k == "cup" then
        gfx.fillRect(x - 6, y - 7, 12, 9)
        gfx.fillRect(x - 2, y + 2, 4, 4)
        gfx.fillRect(x - 5, y + 5, 10, 3)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x - 5, y - 6, 10, 7)
        gfx.fillRect(x - 4, y + 6, 8, 1)
    elseif k == "candle" then
        gfx.fillRect(x - 3, y - 4, 6, 11)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x - 2, y - 3, 4, 9)
        gfx.fillTriangle(x - 2, y - 4, x + 2, y - 4, x, y - 9)
    elseif k == "key" then
        gfx.fillCircleAtPoint(x - 4, y, 5)
        gfx.fillRect(x - 4, y - 2, 12, 4)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(x - 4, y, 3)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(x - 4, y, 1)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x + 3, y - 4, 2, 4)
    elseif k == "bell" then
        gfx.fillTriangle(x - 7, y + 5, x + 7, y + 5, x, y - 7)
        gfx.fillRect(x - 7, y + 5, 14, 3)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(x - 5, y + 4, x + 5, y + 4, x, y - 5)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(x - 1, y + 5, 2, 3)
    else -- crown
        gfx.fillRect(x - 9, y, 18, 7)
        gfx.fillTriangle(x - 9, y + 1, x - 4, y + 1, x - 7, y - 8)
        gfx.fillTriangle(x - 3, y + 1, x + 3, y + 1, x, y - 10)
        gfx.fillTriangle(x + 4, y + 1, x + 9, y + 1, x + 7, y - 8)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x - 7, y + 1, 14, 4)
        gfx.fillRect(x - 1, y - 6, 2, 4)
    end
    gfx.setColor(gfx.kColorBlack)
end

local function loots()
    for i = 1, #G.loot do
        local l = G.loot[i]
        if not l.taken then
            local by = floor(sin(G.frame * 0.06 + l.bob) * 1.5)
            Cast.blob(l.x, l.y + 8, 14, 9)
            lootIcon(l.k, floor(l.x), floor(l.y) + by)
        end
    end
end

local function exitMark()
    local h = G.heist
    local x, y = floor(h.ex), floor(h.ey)
    local ready = G.lootN >= G.lootNeed
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(x - 8, y - 12, 16, 26)           -- the drainpipe
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(x - 8, y - 12, 16, 26)
    for i = 0, 3 do
        gfx.drawLine(x - 8, y - 12 + i * 7, x + 8, y - 12 + i * 7)
    end
    if ready then
        gfx.fillTriangle(x - 6, y - 16, x + 6, y - 16, x, y - 24)
    end
    gfx.setColor(gfx.kColorBlack)
end

-- ---- people ------------------------------------------------------------

local function bubble(a)
    if a.bubble <= 0 then return end
    local x, y = floor(a.x), floor(a.y) - 22
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(x - 5, y - 10, 10, 12)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(x - 5, y - 10, 10, 12)
    local mark = (a.state == "hunt" or a.state == "chase") and "!" or "?"
    gfx.drawText(mark, x - 2, y - 10)
    gfx.setColor(gfx.kColorBlack)
end

local function guard(g)
    local x, y = floor(g.x), floor(g.y)
    Cast.blob(x, y + 7, 18, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x, y - 14, 6)                  -- head
    gfx.fillRect(x - 8, y - 9, 16, 17)                   -- greatcoat
    if g.boss then
        gfx.fillRect(x - 11, y - 22, 22, 5)              -- wide hat
        gfx.fillCircleAtPoint(x, y - 20, 7)
    end
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(x - 8, y - 9, 16, 17)
    gfx.fillRect(x - 5, y - 9, 10, 3)                    -- collar
    gfx.drawCircleAtPoint(x, y - 14, 6)
    if g.boss then
        gfx.drawRect(x - 11, y - 22, 22, 5)
    end
    -- the lantern, on the side he is facing
    local lx = floor(x + cos(g.dir) * 11)
    local ly = floor(y + sin(g.dir) * 11) - 2
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(lx - 4, ly - 4, 8, 9)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(lx - 3, ly - 3, 6, 7)
    gfx.setColor(gfx.kColorBlack)
    bubble(g)
end

local function dog(d)
    local x, y = floor(d.x), floor(d.y)
    Cast.blob(x, y + 5, 20, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(x - 11, y - 6, 22, 12)         -- body
    gfx.fillCircleAtPoint(x + 9, y - 6, 6)               -- head
    gfx.fillTriangle(x - 11, y - 4, x - 18, y - 10, x - 12, y + 1)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawEllipseInRect(x - 11, y - 6, 22, 12)
    gfx.fillRect(x + 10, y - 8, 2, 2)                    -- eye
    gfx.setColor(gfx.kColorBlack)
    bubble(d)
end

local function drunk(d)
    local x, y = floor(d.x), floor(d.y)
    Cast.blob(x, y + 7, 18, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x, y - 15, 6)
    gfx.fillRect(x - 7, y - 10, 14, 18)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(x - 7, y - 10, 14, 18)
    gfx.drawCircleAtPoint(x, y - 15, 6)
    local sw = floor(sin(d.wob) * 6)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(x + 6 + sw, y - 8, 8, 9)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(x + 7 + sw, y - 7, 6, 7)
    gfx.setColor(gfx.kColorBlack)
end

local function cat()
    local x, y = floor(G.px), floor(G.py)
    local crouch = G.creep and 2 or 0
    Cast.blob(x, y + 5, 16, 9)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(x - 9, y - 8 + crouch, 18, 12)     -- body
    gfx.fillCircleAtPoint(x + 6, y - 11 + crouch, 5)         -- head
    gfx.fillTriangle(x + 2, y - 13 + crouch, x + 5, y - 20 + crouch,
        x + 7, y - 13 + crouch)
    gfx.fillTriangle(x + 7, y - 13 + crouch, x + 10, y - 20 + crouch,
        x + 11, y - 13 + crouch)
    local t = sin(G.frame * 0.12) * 5
    gfx.fillTriangle(x - 8, y - 6 + crouch, x - 16, y - 10 + crouch + t,
        x - 8, y - 2 + crouch)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawEllipseInRect(x - 9, y - 8 + crouch, 18, 12)
    gfx.drawCircleAtPoint(x + 6, y - 11 + crouch, 5)
end

-- the cat's eyes, drawn AFTER the light composite so a cat sitting in
-- a doorway shadow is dim but never actually lost
local function catEyes()
    local x, y = floor(G.px), floor(G.py)
    local crouch = G.creep and 2 or 0
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(x + 5, y - 13 + crouch, 2, 2)
    gfx.fillRect(x + 9, y - 13 + crouch, 2, 2)
    gfx.setColor(gfx.kColorBlack)
end

-- ---- noise and pebbles -------------------------------------------------

local function pings()
    gfx.setColor(gfx.kColorWhite)
    -- the paw on the wick, for as long as it takes to pinch it out
    if G.douseT > 0 and G.douseL then
        local l = G.douseL
        gfx.drawCircleAtPoint(floor(l.x), floor(l.y) - 6,
            floor(4 + (C.DOUSE_T - G.douseT) * 30))
    end
    for i = 1, #G.pings do
        local p = G.pings[i]
        local u = 1 - p.t / 0.5
        gfx.drawCircleAtPoint(floor(p.x), floor(p.y), floor(p.r * u))
    end
    local p = G.peb
    if p.live then
        local u = p.t
        local x = p.x + (p.tx - p.x) * u
        local y = p.y + (p.ty - p.y) * u - math.sin(u * math.pi) * 12
        gfx.fillRect(floor(x) - 1, floor(y) - 1, 3, 3)
    end
    gfx.setColor(gfx.kColorBlack)
end

-- ---- HUD ---------------------------------------------------------------

local function pips(x, y)
    for i = 1, G.lootNeed do
        local px = x + (i - 1) * 11
        gfx.setColor(gfx.kColorWhite)
        if i <= G.lootN then
            gfx.fillRect(px, y, 8, 8)
        else
            gfx.drawRect(px, y, 8, 8)
        end
    end
    gfx.setColor(gfx.kColorBlack)
end

local function hud()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, HUD_H)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(0, HUD_H, 400, HUD_H)
    Kit.text(G.stage .. ". " .. G.heist.name, 6, 3)
    pips(196, 7)
    -- pebbles left
    for i = 1, G.pebbles do
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(244 + i * 8, 11, 2)
    end
    gfx.setColor(gfx.kColorBlack)
    Kit.meter(322, 6, 60, 10, G.det, floor(6 - 6 * G.det))
    local hidden = not Game.exposed(G.px, G.py)
    Kit.text(hidden and "HID" or "SEEN", 286, 3)
    if G.alarm and (G.frame % 20) < 12 then
        Kit.text("ALARM", 128, 3)
    end
end

-- ---- cards -------------------------------------------------------------

local function timeStr(t)
    return string.format("%d:%02d", floor(t / 60), floor(t) % 60)
end

local function cards()
    local m = Kit.mode
    if m == "title" then
        Kit.title("PROWL", {
            "A cat burgles a sleeping town",
            "D-pad move   B creep (silent)",
            "A take / douse / throw   Crank aim",
            "Darkness is cover. Lanterns are not.",
            "Press A",
        })
    elseif m == "slots" then
        Kit.slots(G.sel, 110, 54, 190)
        Kit.centered("A choose    B back", 208)
    elseif m == "menu" then
        Kit.list("SLOT " .. G.slot, G.menuRows, G.sel, 120, 66, 170)
    elseif m == "brief" then
        local h = G.heist
        Kit.panel(40, 66, 320, 108)
        Kit.bigCentered("HEIST " .. G.stage, 74, 2)
        Kit.centered(h.name, 106)
        Kit.centered(h.sub, 126)
        Kit.centered("Take " .. G.lootNeed .. "   then the drainpipe", 148)
        local b = Save.get("t" .. G.stage, 0)
        if b > 0 then Kit.centered("BEST " .. timeStr(b), 166) end
    elseif m == "caught" then
        Kit.over("COLLARED", {
            G.why or "Somebody saw you.",
            "Collars: " .. G.totalCaught,
            "A: back over the wall",
        })
    elseif m == "cleared" then
        Kit.over("CLEAN AWAY", {
            G.heist.name .. "  " .. timeStr(G.stageT),
            G.newBest and "NEW BEST TIME" or ("Loot taken: " .. G.totalLoot),
            "A: onward",
        })
    elseif m == "done" then
        Kit.panel(28, 34, 344, 176)
        Kit.bigCentered("THE ASH CROWN", 40, 2)
        Kit.centered("Ten heists. One town. No witnesses.", 72)
        Kit.centered("Loot lifted      " .. G.totalLoot, 96)
        Kit.centered("Collars          " .. G.totalCaught, 114)
        Kit.centered("Lamps pinched    " .. G.totalDoused, 132)
        Kit.centered("- PROWL -", 158)
        Kit.centered("Whisker, the Magpie, and the Night Watchman", 176)
        Kit.centered("A: the town again", 194)
    end
end

-- ---- the frame ---------------------------------------------------------

function Draw.frame()
    Kit.applyShake()
    ground()
    for i = 1, #G.boxes do box(G.boxes[i]) end
    for i = 1, #G.lamps do lamp(G.lamps[i]) end
    loots()
    exitMark()
    for i = 1, #G.drunks do drunk(G.drunks[i]) end
    for i = 1, #G.dogs do dog(G.dogs[i]) end
    for i = 1, #G.guards do guard(G.guards[i]) end
    cat()
    Light.finish()          -- the night lands on everything above
    catEyes()
    pings()
    Kit.drawParts(G.parts)
    if G.lootN >= G.lootNeed and Kit.mode == "play" then
        Kit.marker(G.heist.ex, G.heist.ey - 26, G.frame * C.DT)
    end
    Kit.doneShake()
    if Story.active then
        -- a scene owns the screen furniture; no cards, no HUD
    elseif Kit.mode == "play" then
        if G.irisT > 0 then Fade.iris(G.px, G.py, G.irisT) end
        hud()
    else
        Fade.dissolve(0.35)
        cards()
    end
    Story.draw()            -- letterbox, text box, veil, iris: LAST
end
