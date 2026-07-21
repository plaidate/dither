-- Prowl: the night simulation. The whole game is one rule --
--
--     seen  ==  Light.at(cat) > 0
--               and a guard is inside SIGHT of you
--               and you are inside his cone or his frontal arc
--               and not Light.blocked(guard, cat)
--
-- -- and everything else exists to make that rule interesting: cones
-- that sweep, crates that are collision volumes AND shadow casters,
-- lamps you can put out for good, noise that pulls a cone off you, and
-- a detection meter that fills while the rule is true and drains while
-- it is not, so a beam clipping you is survivable and standing in one
-- is not.

Game = {}

local clamp = Util.clamp
local floor, sqrt, abs = math.floor, math.sqrt, math.abs
local cos, sin, atan = math.cos, math.sin, math.atan
local PI2 <const> = math.pi * 2

-- ---- geometry ----------------------------------------------------------

-- shortest signed angle a, wrapped to (-pi, pi]
local function wrap(a)
    while a > math.pi do a = a - PI2 end
    while a < -math.pi do a = a + PI2 end
    return a
end

-- Is a circle of radius r at (x, y) inside a wall or off the floor?
-- The room bounds test the centre only (the cat's limits ARE the
-- bounds); boxes are inflated by r.
function Game.solid(x, y, r)
    if x < C.X0 or x > C.X1 or y < C.Y0 or y > C.Y1 then return true end
    local b = G.boxes
    for i = 1, #b do
        local q = b[i]
        if x > q.x - r and x < q.x + q.w + r
            and y > q.y - r and y < q.y + q.h + r then
            return true
        end
    end
    return false
end

-- nudge an authored point out of whatever it landed in (a typo in
-- heists.lua costs a pixel, never a soft lock)
function Game.freePoint(x, y, r)
    r = r or C.PRAD
    if not Game.solid(x, y, r) then return x, y end
    Harness.count("nudged")
    for step = 6, 60, 6 do
        for k = 0, 11 do
            local a = k * PI2 / 12
            local nx, ny = x + cos(a) * step, y + sin(a) * step
            if not Game.solid(nx, ny, r) then return nx, ny end
        end
    end
    return x, y
end

-- axis-separated slide: try the whole step, then each axis alone, so
-- an actor pressed into a crate runs along it instead of sticking
local function slideXY(x, y, dx, dy, r)
    if not Game.solid(x + dx, y + dy, r) then return x + dx, y + dy end
    local nx, ny = x, y
    if dx ~= 0 and not Game.solid(x + dx, y, r) then nx = x + dx end
    if dy ~= 0 and not Game.solid(nx, y + dy, r) then ny = y + dy end
    return nx, ny
end

local function slide(a, dx, dy, r)
    local x, y = slideXY(a.x, a.y, dx, dy, r)
    local moved = (x ~= a.x or y ~= a.y)
    a.x, a.y = x, y
    return moved
end

-- ---- routes ------------------------------------------------------------
-- A route is a flat {x, y, x, y, ...}; one waypoint means "stand here
-- and sweep", which is how the counting-house floorwalker works.

local function wpCount(rt) return #rt // 2 end

local function wpAt(rt, i)
    local n = wpCount(rt)
    i = (i - 1) % n + 1
    return rt[i * 2 - 1], rt[i * 2]
end

-- ---- stage construction ------------------------------------------------

-- flow-field grid, shared with the autopilot (input.lua reads
-- Game.GW/GH/cellOf/cellPos and G.walk)
local CELL <const> = C.AP_CELL
Game.GW = math.ceil((C.X1 - C.X0) / CELL)
Game.GH = math.ceil((C.Y1 - C.Y0) / CELL)

function Game.cellOf(x, y)
    local ci = clamp(floor((x - C.X0) / CELL), 0, Game.GW - 1)
    local ri = clamp(floor((y - C.Y0) / CELL), 0, Game.GH - 1)
    return ri * Game.GW + ci + 1
end

function Game.cellPos(idx)
    local i = idx - 1
    local ci, ri = i % Game.GW, i // Game.GW
    return C.X0 + ci * CELL + CELL / 2, C.Y0 + ri * CELL + CELL / 2
end

-- one boolean per cell; the boxes never move, so this is built once
-- per heist and read every frame by the bot's flow field
local function buildWalk()
    local n = Game.GW * Game.GH
    for i = 1, n do
        local x, y = Game.cellPos(i)
        G.walk[i] = not Game.solid(x, y, C.PRAD + 1)
    end
    for i = n + 1, #G.walk do G.walk[i] = nil end
end

-- A waypoint authored inside a crate is a soft lock: the walker slides
-- to the inflated edge and never "arrives", so it stands there forever
-- blocking the room. Sanitising the route once at load makes that a
-- non-event. (Learned the hard way -- see the README notes.)
local function sanitize(rt)
    for i = 1, wpCount(rt) do
        local x, y = Game.freePoint(rt[i * 2 - 1], rt[i * 2], 9)
        rt[i * 2 - 1], rt[i * 2] = x, y
    end
end

local function newGuard(spec)
    sanitize(spec.rt)
    local x, y = wpAt(spec.rt, 1)
    return {
        rt = spec.rt, x = x, y = y,
        wp = 1, pauseT = 0,
        state = "patrol", stT = 0,
        tx = x, ty = y,             -- what it is walking to
        base = 0, dir = 0,          -- heading, and heading + sweep
        sweep = math.random() * PI2,
        blockT = 0, bx = x, by = y,   -- anti-stick watchdog
        coneR = spec.cone or C.CONE_R,
        spread = spec.spread or C.CONE_SPREAD,
        spd = spec.spd or C.G_SPD,
        boss = spec.boss or false,
        bubble = 0,                 -- s the ?/! bubble stays up
    }
end

local function newWalker(spec, spd)
    sanitize(spec.rt)
    local x, y = wpAt(spec.rt, 1)
    return {
        rt = spec.rt, x = x, y = y, wp = 1, pauseT = 0,
        state = "patrol", stT = 0, tx = x, ty = y,
        dir = 0, spd = spd, wob = math.random() * PI2, bubble = 0,
        blockT = 0, bx = x, by = y,
    }
end

-- rebuild the room from heists.lua. Allocation happens HERE, once per
-- attempt -- update and draw touch none of it.
function Game.loadStage(n)
    local h = Heists.get(n)
    G.stage, G.heist = n, h
    Harness.count("rooms")   -- attempts, including retries after a collar
    G.boxes = {}
    for i = 1, #h.boxes do
        local b = h.boxes[i]
        G.boxes[i] = { x = b[1], y = b[2], w = b[3], h = b[4], k = b[5] }
    end
    buildWalk()
    G.lamps = {}
    for i = 1, #(h.lamps or {}) do
        local l = h.lamps[i]
        G.lamps[i] = {
            x = l[1], y = l[2], r = l[3] or C.LAMP_R,
            douse = l[4] and true or false, out = false, flick = 0,
        }
    end
    G.loot = {}
    for i = 1, #h.loot do
        local l = h.loot[i]
        local x, y = Game.freePoint(l[1], l[2])
        G.loot[i] = { x = x, y = y, k = l[3], taken = false, bob = i * 0.7 }
    end
    G.guards = {}
    for i = 1, #(h.guards or {}) do G.guards[i] = newGuard(h.guards[i]) end
    G.dogs = {}
    for i = 1, #(h.dogs or {}) do
        G.dogs[i] = newWalker(h.dogs[i], C.DOG_SPD)
    end
    G.drunks = {}
    for i = 1, #(h.drunks or {}) do
        G.drunks[i] = newWalker(h.drunks[i], C.DRUNK_SPD)
    end
    G.lootNeed = #G.loot
    h.sx, h.sy = Game.freePoint(h.sx, h.sy)
    h.ex, h.ey = Game.freePoint(h.ex, h.ey)
    G.enterStage()
end

-- ---- the light pass ----------------------------------------------------
-- Runs BEFORE the AI so Light.at/Light.blocked answer from this
-- frame's geometry. Occluders go in first, guard cones LAST: light.lua
-- carves each light's shadows right after its own shape, so the
-- shadow-casting light wants to be the last one added.

local function boxNear(q, x, y, r)
    local cx = clamp(x, q.x, q.x + q.w)
    local cy = clamp(y, q.y, q.y + q.h)
    local dx, dy = x - cx, y - cy
    return dx * dx + dy * dy < r * r
end

local function castLights()
    Light.begin(G.heist.amb or C.AMBIENT)
    -- Occluders: only the boxes near the cat. WALL_CULL > SIGHT, so
    -- every wall that could break a guard's line of sight is in;
    -- shadows further away simply are not drawn (see README notes).
    local n = 0
    for i = 1, #G.boxes do
        local q = G.boxes[i]
        if n < C.WALL_BOXES and boxNear(q, G.px, G.py, C.WALL_CULL) then
            Light.box(q.x, q.y, q.w, q.h)
            n = n + 1
        end
    end
    for i = 1, #G.lamps do
        local l = G.lamps[i]
        if not l.out then Light.add(l.x, l.y, l.r, 0.45) end
    end
    for i = 1, #G.drunks do
        local d = G.drunks[i]
        Light.add(d.x, d.y - 4, C.DRUNK_R, 0.5)
    end
    for i = 1, #G.guards do
        local g = G.guards[i]
        Light.cone(g.x, g.y, g.coneR, g.dir, g.spread, 0.5)
    end
end

-- ---- noise -------------------------------------------------------------

local function ping(x, y, r)
    if #G.pings < 8 then
        G.pings[#G.pings + 1] = { x = x, y = y, r = r, t = 0.5 }
    end
end

-- Start or re-aim a dog's chase. The cooldown and the un-refreshable
-- chase clock live HERE, in one place, because both the dog's own ears
-- and Game.noise feed it -- and a footfall that reset the clock every
-- 0.42s made the mastiff immortal (see the README notes).
function Game.dogAlert(d, x, y)
    if d.state ~= "chase" then
        if (d.cool or 0) > 0 then return end
        Sfx.bark()
        d.bubble = 1.6
        d.state, d.stT = "chase", C.DOG_LOSE
        Harness.count("barks")
    end
    d.tx, d.ty = x, y
end

-- a noise at (x, y) heard out to r: guards go and look, dogs come
-- running. This is the only lever that moves a cone off you.
function Game.noise(x, y, r, loud)
    ping(x, y, r)
    for i = 1, #G.guards do
        local g = G.guards[i]
        local dx, dy = x - g.x, y - g.y
        if dx * dx + dy * dy < r * r and g.state ~= "hunt" then
            g.state, g.tx, g.ty = "look", x, y
            g.stT = C.G_LOOK
            g.bubble = 1.4
            if loud then Harness.count("lured") end
        end
    end
    for i = 1, #G.dogs do
        local d = G.dogs[i]
        local dx, dy = x - d.x, y - d.y
        if dx * dx + dy * dy < r * r then Game.dogAlert(d, x, y) end
    end
end

-- ---- guards ------------------------------------------------------------

-- fill rate (per second) this guard puts on the meter for a target at
-- (x, y) whose light level is `lit`. 0 means he cannot see it at all.
local function seesAt(g, x, y, lit)
    if lit <= 0 then return 0 end
    local dx, dy = x - g.x, y - g.y
    local d2 = dx * dx + dy * dy
    local sight = g.boss and (g.coneR * 0.8) or C.SIGHT
    if d2 > sight * sight then return 0 end
    local d = sqrt(d2)
    local off = abs(wrap(atan(dy, dx) - g.dir))
    local inCone = off <= g.spread * 0.5 and d <= g.coneR
    if not inCone and off > C.VIEW_ARC then return 0 end
    if Light.blocked(g.x, g.y, x, y) then return 0 end
    local close = clamp(1 - d / sight, C.DET_NEAR, 1)
    local m = (lit >= 1) and 1 or C.DET_DIM
    return C.DET_FILL * m * close * (inCone and C.DET_CONE or 1)
end

Game.seesAt = seesAt

-- "would standing here cost me?" -- the query the whole game, the HUD
-- and the autopilot all ask, answered from the frame's real geometry
function Game.exposed(x, y)
    local lit = Light.at(x, y)
    if lit <= 0 then return false end
    for i = 1, #G.guards do
        if seesAt(G.guards[i], x, y, lit) > 0 then return true end
    end
    return false
end

-- walk one step toward (tx, ty); returns done, and the unit heading it
-- wanted (which is what the facing chases)
local function stepTo(a, tx, ty, spd, dt, r)
    local dx, dy = tx - a.x, ty - a.y
    local d = sqrt(dx * dx + dy * dy)
    if d < 1.5 then return true, 0, 0 end
    local ux, uy = dx / d, dy / d
    slide(a, ux * spd * dt, uy * spd * dt, r or 7)
    return false, ux, uy
end

local function faceToward(g, ux, uy, dt)
    if ux == 0 and uy == 0 then return end
    local want = atan(uy, ux)
    local diff = wrap(want - g.base)
    local maxd = C.TURN * dt
    g.base = g.base + clamp(diff, -maxd, maxd)
end

local function updateGuard(g, dt)
    g.bubble = math.max(0, g.bubble - dt)
    local boost = G.alarm and C.ALARM_SPD or 1
    local spd = g.spd * boost
    local ux, uy = 0, 0
    local done
    if g.state == "hunt" then
        done, ux, uy = stepTo(g, g.tx, g.ty, C.G_HUNT * boost, dt)
        g.stT = g.stT - dt
        if done or g.stT <= 0 then
            g.state, g.stT = "look", C.G_LOOK
        end
    elseif g.state == "look" then
        done, ux, uy = stepTo(g, g.tx, g.ty, C.G_SUS * boost, dt)
        g.stT = g.stT - dt
        if done then
            -- search the spot: sweep wide while the clock runs out
            g.sweep = g.sweep + dt * C.SWEEP_RATE * 2.2
            ux, uy = 0, 0
        end
        if g.stT <= 0 then g.state = "patrol" end
    else
        if wpCount(g.rt) == 1 then
            -- a one-waypoint guard is a floorwalker: he stands still and
            -- turns, so his cone eventually visits every corner and the
            -- room becomes a timing puzzle instead of a safe quadrant
            g.base = g.base + dt * C.STAND_SPIN
            g.sweep = g.sweep + dt * C.SWEEP_RATE * 0.6
        elseif g.pauseT > 0 then
            g.pauseT = g.pauseT - dt
        else
            local tx, ty = wpAt(g.rt, g.wp)
            done, ux, uy = stepTo(g, tx, ty, spd, dt)
            if done then
                g.wp = g.wp % wpCount(g.rt) + 1
                g.pauseT = C.G_PAUSE
            end
        end
    end
    -- belt and braces: any walker that has not actually moved for two
    -- seconds while trying to gives up on its target and moves on
    local mx, my = g.x - g.bx, g.y - g.by
    if (ux ~= 0 or uy ~= 0) and mx * mx + my * my < 0.4 then
        g.blockT = g.blockT + dt
        if g.blockT > 2 then
            g.blockT = 0
            if g.state == "patrol" then
                g.wp = g.wp % wpCount(g.rt) + 1
            else
                g.state, g.stT = "patrol", 0
            end
        end
    else
        g.blockT = 0
    end
    g.bx, g.by = g.x, g.y
    faceToward(g, ux, uy, dt)
    g.sweep = g.sweep + dt * C.SWEEP_RATE * (g.boss and 0.45 or 1)
    local amp = (g.state == "patrol") and C.SWEEP or C.SWEEP * 1.5
    if g.boss then amp = C.SWEEP * 1.2 end
    g.dir = g.base + sin(g.sweep) * amp
end

-- ---- the dog -----------------------------------------------------------
-- It never queries Light. Hearing is its whole world, which is exactly
-- why the level that introduces it is the one where darkness stops
-- being the answer.

local function updateDog(d, dt)
    d.bubble = math.max(0, d.bubble - dt)
    local dx, dy = G.px - d.x, G.py - d.y
    local dist = sqrt(dx * dx + dy * dy)
    local hear = G.creep and C.DOG_CREEP_HEAR or C.DOG_HEAR
    d.cool = math.max(0, (d.cool or 0) - dt)
    if dist < hear then
        local was = d.state
        Game.dogAlert(d, G.px, G.py)
        -- a barking dog is the loudest thing in the heist: every guard
        -- in earshot comes to see what it found
        if was ~= "chase" and d.state == "chase" then
            Game.noise(d.x, d.y, C.DOG_BARK)
        end
    end
    if d.state == "chase" then
        d.stT = d.stT - dt
        local done, ux, uy = stepTo(d, d.tx, d.ty, C.DOG_CHASE, dt)
        if ux then d.dir = atan(uy, ux) end
        if dist < C.DOG_TOUCH then
            Game.caught("The mastiff had you before you heard it.")
            return
        end
        if done or d.stT <= 0 then
            d.state = "patrol"
            d.cool = C.DOG_COOL
        end
    else
        if d.pauseT > 0 then
            d.pauseT = d.pauseT - dt
        else
            local tx, ty = wpAt(d.rt, d.wp)
            local done, ux, uy = stepTo(d, tx, ty, d.spd, dt)
            if ux then d.dir = atan(uy, ux) end
            if done then
                d.wp = d.wp % wpCount(d.rt) + 1
                d.pauseT = 0.8
            end
        end
    end
end

-- ---- the drunk ---------------------------------------------------------
-- Sees nothing, reports nothing, and ruins everything: his lantern is
-- a light that walks, so cover is only cover until he turns the corner.

local function updateDrunk(d, dt)
    d.wob = d.wob + dt * 2.4
    local tx, ty = wpAt(d.rt, d.wp)
    local done, ux, uy = stepTo(d, tx, ty, d.spd, dt)
    if ux then
        d.dir = atan(uy, ux)
        slide(d, -uy * sin(d.wob) * C.DRUNK_WOBBLE * dt,
            ux * sin(d.wob) * C.DRUNK_WOBBLE * dt, 6)
    end
    if done then d.wp = d.wp % wpCount(d.rt) + 1 end
end

-- ---- detection ---------------------------------------------------------

local function updateDetection(dt)
    local lit = Light.at(G.px, G.py)
    G.lit = lit
    -- the first moment over the wall is free: without it a heist whose
    -- start happens to sit on a patrol leg is unwinnable rather than hard
    if G.graceT > 0 then
        G.graceT = G.graceT - dt
        G.det = math.max(0, G.det - C.DET_DRAIN * dt)
        return
    end
    local rate, seer = 0, nil
    for i = 1, #G.guards do
        local g = G.guards[i]
        local r = seesAt(g, G.px, G.py, lit)
        if r > rate then rate, seer = r, g end
        -- only a guard who already KNOWS grabs you; one merely walking
        -- over to look at a noise has to actually see you first
        local dx, dy = G.px - g.x, G.py - g.y
        if g.state == "hunt" and dx * dx + dy * dy < C.TOUCH * C.TOUCH then
            Game.caught("A hand closed on your scruff.")
            return
        end
    end
    if rate > 0 then
        if G.seenT > 0.5 then
            Harness.count("sighted")
            Sfx.spot()
            if seer then seer.bubble = 1.6 end
        end
        G.seenT = 0
        G.det = math.min(1, G.det + rate * dt)
        G.detPeak = math.max(G.detPeak, G.det)
        if seer then
            if G.det >= C.DET_HUNT then
                seer.state, seer.tx, seer.ty = "hunt", G.px, G.py
                seer.stT = C.G_HUNT_T
                seer.bubble = 1.6
            elseif G.det >= C.DET_SUSPECT and seer.state == "patrol" then
                seer.state, seer.tx, seer.ty = "look", G.px, G.py
                seer.stT = C.G_LOOK
                seer.bubble = 1.4
            end
        end
        if G.det >= 1 then
            Game.caught("The lantern found you, and held.")
            return
        end
    else
        G.seenT = G.seenT + dt
        G.det = math.max(0, G.det - C.DET_DRAIN * dt)
        if G.det <= 0 and G.detPeak >= C.DET_EVADE then
            Harness.count("evaded")   -- a real near miss, back to black
            G.detPeak = 0
        end
    end
end

-- ---- the cat -----------------------------------------------------------

local function updateCat(dt)
    G.creep = Input.creep
    local sp = G.creep and C.CREEP or C.WALK
    local mx, my = Input.mx, Input.my
    if mx ~= 0 and my ~= 0 then
        mx, my = mx * 0.7071, my * 0.7071
    end
    if mx ~= 0 or my ~= 0 then
        G.fx, G.fy = mx, my
    end
    local wx, wy = mx * sp, my * sp
    G.vx = G.vx + clamp(wx - G.vx, -C.ACCEL * dt, C.ACCEL * dt)
    G.vy = G.vy + clamp(wy - G.vy, -C.ACCEL * dt, C.ACCEL * dt)
    G.px, G.py = slideXY(G.px, G.py, G.vx * dt, G.vy * dt, C.PRAD)
    -- padding is loud, creeping is not: that is the whole speed trade
    local moving = abs(G.vx) + abs(G.vy) > 8
    if moving and not G.creep then
        G.noiseT = G.noiseT - dt
        if G.noiseT <= 0 then
            G.noiseT = C.NOISE_EVERY
            Game.noise(G.px, G.py, C.NOISE_WALK)
            Sfx.pad()
        end
    else
        G.noiseT = 0
    end
end

-- ---- interaction -------------------------------------------------------

local function nearestLoot()
    local best, bd = nil, C.LOOT_R * C.LOOT_R
    for i = 1, #G.loot do
        local l = G.loot[i]
        if not l.taken then
            local dx, dy = l.x - G.px, l.y - G.py
            local d = dx * dx + dy * dy
            if d < bd then best, bd = l, d end
        end
    end
    return best
end

local function nearestLamp()
    local best, bd = nil, C.DOUSE_R * C.DOUSE_R
    for i = 1, #G.lamps do
        local l = G.lamps[i]
        if l.douse and not l.out then
            local dx, dy = l.x - G.px, l.y - G.py
            local d = dx * dx + dy * dy
            if d < bd then best, bd = l, d end
        end
    end
    return best
end

function Game.atExit()
    local dx, dy = G.heist.ex - G.px, G.heist.ey - G.py
    return dx * dx + dy * dy < C.EXIT_R * C.EXIT_R
end

local function takeLoot(l)
    l.taken = true
    G.lootN = G.lootN + 1
    G.totalLoot = G.totalLoot + 1
    Harness.count("loot")
    Sfx.grab()
    Music.sting{ 76, 81, 88 }
    Kit.burst(G.parts, l.x, l.y, 6, 70, 20)
    if G.lootN >= G.lootNeed and G.heist.escape and not G.alarm then
        G.alarm = true
        Harness.count("alarms")
        Sfx.alarm()
        Kit.shake(0.5)
        for i = 1, #G.guards do
            local g = G.guards[i]
            g.state, g.tx, g.ty = "hunt", G.px, G.py
            g.stT, g.bubble = 90, 3
        end
    end
end

local function douse(l)
    l.out = true
    G.douseT = C.DOUSE_T
    G.douseL = l
    G.totalDoused = G.totalDoused + 1
    Harness.count("doused")
    Sfx.douse()
    Music.sting{ 60, 55 }
    Kit.burst(G.parts, l.x, l.y - 6, 5, 40, 30)
end

local function throwPebble()
    if G.pebbles <= 0 or G.pebT > 0 or G.peb.live then return end
    G.pebbles = G.pebbles - 1
    G.pebT = C.PEBBLE_CD
    local p = G.peb
    p.live, p.t = true, 0
    p.x, p.y = G.px, G.py
    local ax, ay = G.fx, G.fy
    if Input.aimx ~= 0 or Input.aimy ~= 0 then
        ax, ay = Input.aimx, Input.aimy
    end
    p.tx = clamp(G.px + ax * G.throwR, C.X0, C.X1)
    p.ty = clamp(G.py + ay * G.throwR, C.Y0, C.Y1)
    Harness.count("pebbles")
    Sfx.pebble()
end

local function interact()
    if Game.atExit() and G.lootN >= G.lootNeed then
        Game.clearStage()
        return
    end
    local l = nearestLoot()
    if l then takeLoot(l) return end
    local m = nearestLamp()
    if m then douse(m) return end
    throwPebble()
end

-- ---- stage flow --------------------------------------------------------

function Game.caught(why)
    if Kit.mode ~= "play" then return end
    G.why = why
    G.totalCaught = G.totalCaught + 1
    Harness.count("caught")
    Sfx.caught()
    Music.sting{ 48, 45, 41 }
    Kit.shake(0.6)
    Kit.setMode("caught", C.CAUGHT_T)
end

function Game.clearStage()
    local n = G.stage
    local t = math.floor(G.stageT * 10) / 10
    local prev = Save.get("t" .. n, 0)
    G.newBest = (prev == 0 or t < prev)
    if G.newBest then Save.set("t" .. n, t) end
    Save.set("stage", math.min(Heists.count, n + 1))
    Save.unlock(n + 1)
    Save.set("loot", G.totalLoot)
    Save.meta.place = G.heist.name
    Save.meta.pct = math.floor(n * 100 / Heists.count)
    Save.commit()
    Harness.count("stagesCleared")
    Sfx.clear()
    Music.sting{ 72, 79, 84 }
    Kit.setMode("cleared", C.CLEAR_T)
end

-- start heist n: the interlude cutscene first if one is due
function Game.beginStage(n)
    G.stage = n
    if Tale.before(n) then return end
    Game.startRoom(n)
end

function Game.startRoom(n)
    Game.loadStage(n)
    Music.set(Sfx.bed(G.heist.song))
    Kit.setMode("brief", C.BRIEF_T)
end

function Game.retry()
    Game.loadStage(G.stage)
    Music.set(Sfx.bed(G.heist.song))
    Kit.setMode("brief", C.BRIEF_T)
end

function Game.finishCampaign()
    if G.doneOnce then return end
    G.doneOnce = true
    Save.set("won", true)
    Save.meta.pct = 100
    Save.meta.place = "Over the rooftops"
    Save.commit()
    Tale.ending()
end

function Game.markDone()
    Harness.count("done")
    Kit.setMode("done")
    Music.set(Sfx.TITLE)
end

-- ---- new game / continue -----------------------------------------------

function Game.newGame(slot)
    Save.use(slot)
    Save.reset{ name = "Whisker", place = Heists.get(1).name, pct = 0 }
    Save.commit()
    G.slot, G.totalLoot, G.doneOnce = slot, 0, false
    Game.beginStage(1)
end

function Game.continueGame(slot)
    Save.use(slot)
    Save.load(slot)
    G.slot = slot
    G.totalLoot = Save.get("loot", 0)
    G.doneOnce = false
    Game.beginStage(clamp(Save.get("stage", 1), 1, Heists.count))
end

-- ---- update ------------------------------------------------------------

local function updateWorld(dt, live)
    for i = 1, #G.guards do updateGuard(G.guards[i], dt) end
    for i = 1, #G.dogs do
        if live then updateDog(G.dogs[i], dt) end
    end
    for i = 1, #G.drunks do updateDrunk(G.drunks[i], dt) end
    for i = #G.pings, 1, -1 do
        local p = G.pings[i]
        p.t = p.t - dt
        if p.t <= 0 then table.remove(G.pings, i) end
    end
    for i = 1, #G.lamps do
        local l = G.lamps[i]
        l.flick = l.flick + dt
    end
    if live then
        local p = G.peb
        if p.live then
            p.t = p.t + dt * 3
            if p.t >= 1 then
                p.live = false
                Game.noise(p.tx, p.ty, C.PEBBLE_NOISE, true)
            end
        end
    end
end

-- the chase bed swaps in the moment somebody actually knows where you
-- are, and swaps back a beat after they stop knowing
local function updateMusic(dt)
    local hunting = false
    for i = 1, #G.guards do
        if G.guards[i].state == "hunt" then hunting = true end
    end
    for i = 1, #G.dogs do
        if G.dogs[i].state == "chase" then hunting = true end
    end
    G.chaseT = math.max(0, (G.chaseT or 0) - dt)
    if hunting then G.chaseT = 1.6 end
    if Kit.mode == "play" then
        Music.set(G.chaseT > 0 and Sfx.CHASE or Sfx.bed(G.heist.song))
    end
end

function Game.update(dt)
    G.frame = G.frame + 1
    Music.update(dt)
    Kit.updateShake(dt)
    Kit.updateParts(G.parts, dt, 120, nil)
    -- Story owns the frame while it runs; the field freezes but still
    -- lights and patrols behind the letterbox. The `wasActive` latch
    -- means the A press that closed a scene cannot also fall through
    -- and skip the stage card behind it.
    local wasActive = Story.active
    Story.update(dt, Input.aPress,
        (not Harness.enabled) and Input.bPress or false)
    if wasActive then
        castLights()
        updateWorld(dt, false)
        return
    end
    local m = Kit.mode
    if m == "play" then
        G.stageT = G.stageT + dt
        G.irisT = math.max(0, G.irisT - dt * 1.6)
        G.pebT = math.max(0, G.pebT - dt)
        G.douseT = math.max(0, G.douseT - dt)
        G.throwR = clamp(G.throwR + Input.crank * C.CRANK_GAIN,
            C.THROW_MIN, C.THROW_MAX)
        updateCat(dt)
        castLights()          -- after movement, before every query
        updateWorld(dt, true)
        updateDetection(dt)
        if Kit.mode == "play" and Input.aPress then interact() end
        updateMusic(dt)
        return
    end
    -- every other mode still runs the room, so the town is alive
    -- behind the title card and the stage brief
    castLights()
    updateWorld(dt, false)
    if m == "brief" then
        if Input.aPress or Kit.modeT <= 0 then Kit.setMode("play") end
    elseif m == "caught" then
        if Input.aPress and Kit.modeT <= 0 then Game.retry() end
    elseif m == "cleared" then
        if Input.aPress and Kit.modeT <= 0 then
            if G.stage >= Heists.count then
                Game.finishCampaign()
            else
                Game.beginStage(G.stage + 1)
            end
        end
    elseif m == "title" then
        if Input.aPress then
            G.sel = 1
            Kit.setMode("slots")
        end
    elseif m == "slots" then
        G.sel = clamp(G.sel + Input.step, 1, Save.SLOTS)
        if Input.bPress then Kit.setMode("title") end
        if Input.aPress then
            G.slot = G.sel
            if Save.exists(G.sel) then
                G.menuRows = { "CONTINUE", "NEW HEIST", "BACK" }
                G.sel = 1
                Kit.setMode("menu")
            else
                Game.newGame(G.slot)
            end
        end
    elseif m == "menu" then
        G.sel = clamp(G.sel + Input.step, 1, #G.menuRows)
        if Input.bPress then Kit.setMode("slots") end
        if Input.aPress then
            local pick = G.menuRows[G.sel]
            if pick == "CONTINUE" then
                Game.continueGame(G.slot)
            elseif pick == "NEW HEIST" then
                Game.newGame(G.slot)
            else
                G.sel = G.slot
                Kit.setMode("slots")
            end
        end
    elseif m == "done" then
        if Input.aPress then
            Kit.setMode("title")
            Music.set(Sfx.TITLE)
        end
    end
end
