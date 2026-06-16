-- Rendering. The track and 16-angle car sprites are the converted 1-bit
-- PySprint assets; HUD, finish line and countdown are drawn procedurally.
-- Logical coords are scaled by C.S and offset by C.OX/OY onto the screen.

local gfx <const> = playdate.graphics
local floor <const> = math.floor

Draw = {}

local function img(name)
    return assert(gfx.image.new(name), "missing image " .. name)
end

local trackImgs <const> = {}
for i = 1, 8 do trackImgs[i] = img("images/track" .. i) end
local titleImg <const> = gfx.image.new("images/title") -- optional
local playerSpr <const> = {}
local droneSpr <const> = {}
for a = 0, 15 do
    playerSpr[a] = img(string.format("images/car/p%02d", a))
    droneSpr[a] = img(string.format("images/car/d%02d", a))
end

local function sx(lx) return C.OX + lx * C.S end
local function sy(ly) return C.OY + ly * C.S end

local function spriteIndex(ang)
    local i = floor(ang + 0.5) % 16
    if i < 0 then i = i + 16 end
    return i
end

local function textC(s, x, y)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(s, x, y, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function textL(s, x, y)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(s, x, y)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- checkered start/finish bar, drawn from the logical finish rect
local function drawFinish()
    local r = Track.finishRect
    local x, y, w, h = sx(r[1]), sy(r[2]), r[3] * C.S, r[4] * C.S
    local step = 4
    gfx.setColor(gfx.kColorWhite)
    local row = 0
    local yy = y
    while yy < y + h do
        if row % 2 == 0 then
            gfx.fillRect(x, yy, math.max(2, w), step)
        end
        yy = yy + step
        row = row + 1
    end
end

local function drawCar(c)
    local spr = c.isPlayer and playerSpr or droneSpr
    spr[spriteIndex(c.ang)]:drawCentered(sx(c.x), sy(c.y))
end

-- little caret bobbing over the player so you never lose your car
local function drawPlayerMark()
    local p = G.player
    local x, y = sx(p.x), sy(p.y) - 13 - (G.frame % 20 < 10 and 0 or 1)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillTriangle(x, y + 4, x - 3, y, x + 3, y)
end

local function timeStr(t)
    if not t then return "--.--" end
    return string.format("%05.2f", t)
end

local function ordinal(n)
    return ({ "1st", "2nd", "3rd", "4th" })[n] or (n .. "th")
end

function Draw.field()
    gfx.clear(gfx.kColorBlack)
    trackImgs[G.trackSel]:draw(C.OX, C.OY)
end

local function drawCars()
    for i = #G.cars, 2, -1 do drawCar(G.cars[i]) end -- drones under player
    drawCar(G.player)
    drawPlayerMark()
end

local function drawHud()
    local lap = math.min(G.player.lap + 1, G.laps)
    textL(string.format("LAP %d/%d", lap, G.laps), 4, 4)
    textL(ordinal(G.place), 4, 24)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("BEST " .. timeStr(G.bestLap), C.SCREEN_W - 4, 4, kTextAlignment.right)
    gfx.drawTextAligned("LAP " .. timeStr(G.lastLap), C.SCREEN_W - 4, 24, kTextAlignment.right)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function Draw.play()
    Draw.field()
    drawFinish()
    drawCars()
    drawHud()

    if G.countdown > 0 then
        local n = math.ceil(G.countdown)
        textC(tostring(n), C.SCREEN_W / 2, C.SCREEN_H / 2 - 18)
    elseif G.goFlash > 0 then
        textC("*GO!*", C.SCREEN_W / 2, C.SCREEN_H / 2 - 18)
    end
end

function Draw.title()
    if titleImg then
        titleImg:draw(0, 0)
    else
        Draw.field()
    end
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 138, C.SCREEN_W, 102)
    textC("*SPRINT*", C.SCREEN_W / 2, 142)
    local name, diff = Track.meta(G.trackSel)
    textC(string.format("^ %s (%s) v", name, diff), C.SCREEN_W / 2, 166)
    textC("< " .. C.LAPS_OPTIONS[G.menuSel] .. " LAPS >", C.SCREEN_W / 2, 186)
    local best = G.records and G.records.best[tostring(G.trackSel)]
    textC("BEST LAP " .. timeStr(best), C.SCREEN_W / 2, 206)
    if G.frame % 30 < 20 then
        textC("PRESS A TO RACE", C.SCREEN_W / 2, 224)
    end
end

function Draw.over()
    Draw.field()
    drawFinish()
    drawCars()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(60, 70, C.SCREEN_W - 120, 100)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(60, 70, C.SCREEN_W - 120, 100)
    local msg = (G.place == 1) and "YOU WIN!" or ("YOU FINISHED " .. ordinal(G.place))
    textC("*" .. msg .. "*", C.SCREEN_W / 2, 88)
    textC("BEST LAP " .. timeStr(G.bestLap), C.SCREEN_W / 2, 116)
    if G.frame % 30 < 20 then
        textC("PRESS A TO RACE AGAIN", C.SCREEN_W / 2, 144)
    end
end
