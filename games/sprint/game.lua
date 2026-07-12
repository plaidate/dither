-- Core simulation: player physics, drone AI on the racing line, lap counting
-- and standings. All original logic; the angle model matches the converted
-- sprites (16 angles, 22.5 deg each: dir = (sin, -cos), 0=up, 4=right, going
-- clockwise). Logical 640x400 coordinates throughout.

Game = {}

local sin, cos, sqrt = math.sin, math.cos, math.sqrt
local atan = math.atan
local TAU8 <const> = math.pi / 8 -- one angle unit = 22.5 deg

-- direction vector for a (continuous) sprite angle
local function dirOf(ang)
    local r = ang * TAU8
    return sin(r), -cos(r)
end

-- sprite angle (continuous, 0..16) of a direction vector
function Game.angOf(dx, dy)
    local a = atan(dx, -dy) / TAU8
    a = a % 16
    if a < 0 then a = a + 16 end
    return a
end

local function newCar(isPlayer, lane, speed)
    return {
        isPlayer = isPlayer, lane = lane or 0, droneSpeed = speed or 0,
        x = 0, y = 0, ang = 0, speed = 0,
        s = 0, prevS = 0, lap = 0, finished = false, finishFrame = nil,
    }
end

function Game.reset(laps)
    Track.load(G.trackSel)
    G.bestLap = G.records and G.records.best[tostring(G.trackSel)] or nil
    G.laps = laps
    local st = Track.start
    G.cars = {}
    G.player = newCar(true, 0, 0)
    G.player.x, G.player.y, G.player.ang = st.x, st.y, st.ang
    local s0, _, cx0, cy0, ux0, uy0 = Track.project(st.x, st.y)
    G.player.s, G.player.prevS = s0, s0
    G.player.cx, G.player.cy, G.player.ux, G.player.uy = cx0, cy0, ux0, uy0
    G.cars[1] = G.player
    for d = 1, C.N_DRONES do
        local dr = newCar(false, C.DRONE_LANES[d], C.DRONE_SPEED[d])
        -- stagger drones just behind the player along the line
        dr.s = (G.player.s - 26 * d) % Track.L
        dr.prevS = dr.s
        Game.placeDrone(dr)
        G.cars[#G.cars + 1] = dr
    end
    G.countdown = C.COUNTDOWN
    G.goFlash = 0
    G.raceFrame = 0
    G.lapStartFrame = 0
    G.place = 1
    G.lastLap = nil
end

-- world position + facing of a drone from its arc-length and lane
function Game.placeDrone(dr)
    local x, y, ux, uy = Track.pointAt(dr.s)
    dr.x = x - uy * dr.lane -- left normal = (-uy, ux)
    dr.y = y + ux * dr.lane
    dr.ang = Game.angOf(ux, uy)
end

local function totalProg(c) return c.lap * Track.L + c.s end

local function advanceLap(c)
    -- forward seam wrap: s jumped from ~L back to ~0
    local d = c.s - c.prevS
    if d < -Track.L * 0.5 then
        c.lap = c.lap + 1
        if c.isPlayer then Game.onPlayerLap() end
        return true
    elseif d > Track.L * 0.5 then
        c.lap = c.lap - 1
        if c.lap < 0 then c.lap = 0 end
    end
    return false
end

function Game.onPlayerLap()
    local t = (G.raceFrame - G.lapStartFrame) * C.DT
    G.lapStartFrame = G.raceFrame
    G.lastLap = t
    if not G.bestLap or t < G.bestLap then
        G.bestLap = t
        Game.saveRecord()
    end
    Harness.count("laps")
    if G.tod ~= 1 then Harness.count("nightLaps") end
    Sfx.lap()
end

-- Collision tests the car centre only. A forward "nose" probe reads nicer in
-- the open but swings into walls on tight turns and wedges the car in the
-- hairpin; centre-only means the car can always rotate free of a wall.
local function carOnTrack(x, y, dx, dy)
    return Track.onTrack(x, y)
end

local bumpCooldown = 0
function Game.bump(p)
    p.speed = math.min(p.speed, C.BUMP_SPEED)
    if bumpCooldown <= 0 then
        Harness.count("bumps")
        Sfx.bump()
        bumpCooldown = 6
    end
end

local function updatePlayer(turn, accel, brake)
    local p = G.player
    if p.finished then return end

    p.ang = (p.ang + turn) % 16
    if p.ang < 0 then p.ang = p.ang + 16 end

    if accel then
        p.speed = math.min(C.MAX_SPEED, p.speed + C.ACCEL)
    elseif brake then
        p.speed = math.max(C.REVERSE_MAX, p.speed - C.BRAKE)
    else
        if p.speed > 0 then
            p.speed = math.max(0, p.speed - C.COAST)
        elseif p.speed < 0 then
            p.speed = math.min(0, p.speed + C.COAST)
        end
    end

    local dx, dy = dirOf(p.ang)
    local vx, vy = dx * p.speed, dy * p.speed
    local nx, ny = p.x + vx, p.y + vy

    if carOnTrack(nx, ny, dx, dy) then
        p.x, p.y = nx, ny
    elseif carOnTrack(nx, p.y, dx, dy) then
        p.x = nx; Game.bump(p)
    elseif carOnTrack(p.x, ny, dx, dy) then
        p.y = ny; Game.bump(p)
    else
        p.speed = C.BUMP_SPEED * 0.3; Game.bump(p)
    end
end

local function updateDrones()
    for i = 2, #G.cars do
        local dr = G.cars[i]
        if not dr.finished then
            dr.prevS = dr.s
            dr.s = (dr.s + dr.droneSpeed) % Track.L
            advanceLap(dr)
            if dr.lap >= G.laps then dr.finished = true; dr.finishFrame = G.raceFrame end
            Game.placeDrone(dr)
        end
    end
end

-- Light car-to-car shove (player is pushed clear; drones stay on their line).
-- This is NOT a wall bump: it must not cap the player to BUMP_SPEED, or a
-- drone sharing the racing line would pin the player at a crawl every frame.
-- A cooldown keeps a repeated overlap from becoming a continuous slowdown.
local carBumpCD = 0
local function carContacts()
    if carBumpCD > 0 then carBumpCD = carBumpCD - 1; return end
    local p = G.player
    for i = 2, #G.cars do
        local dr = G.cars[i]
        local dx, dy = p.x - dr.x, p.y - dr.y
        local d2 = dx * dx + dy * dy
        if d2 < C.CAR_HIT * C.CAR_HIT and d2 > 0.01 then
            local d = sqrt(d2)
            local ux, uy = dx / d, dy / d
            -- push fully clear of the overlap so the two separate
            local tx, ty = p.x + ux * (C.CAR_HIT - d + 1), p.y + uy * (C.CAR_HIT - d + 1)
            if Track.onTrack(tx, ty) then p.x, p.y = tx, ty end
            p.speed = p.speed * 0.85
            Harness.count("nudges")
            carBumpCD = 18
            return
        end
    end
end

local function standings()
    local p = G.player
    local mine = totalProg(p)
    local place = 1
    for i = 2, #G.cars do
        if totalProg(G.cars[i]) > mine then place = place + 1 end
    end
    G.place = place
end

-- one race step: turn, accel, brake from input; start skips the
-- countdown. (Kit.run's Game.update(dt) in main.lua dispatches here.)
function Game.race(turn, accel, brake, start)
    if bumpCooldown > 0 then bumpCooldown = bumpCooldown - 1 end

    if G.countdown > 0 then
        if start then G.countdown = 0 else G.countdown = G.countdown - C.DT end
        if G.countdown <= 0 then
            G.countdown = 0
            G.goFlash = 0.6
            G.lapStartFrame = G.raceFrame
            Sfx.go()
        end
        return
    end

    if G.goFlash > 0 then G.goFlash = math.max(0, G.goFlash - C.DT) end
    G.raceFrame = G.raceFrame + 1

    updateDrones()
    updatePlayer(turn, accel, brake)
    carContacts()

    -- player lap progress: windowed so it can't snap across the infield wall.
    -- Also captures the nearest point + tangent for the autopilot.
    local p = G.player
    p.prevS = p.s
    local s, _, cx, cy, ux, uy = Track.projectNear(p.x, p.y, p.prevS, 150)
    p.s = s
    p.cx, p.cy, p.ux, p.uy = cx, cy, ux, uy
    advanceLap(p)
    standings()

    if not p.finished and p.lap >= G.laps then
        p.finished = true
        p.finishFrame = G.raceFrame
        Harness.count("finishes")
        if G.place == 1 then Harness.count("wins") end
        Kit.setMode("finish", C.FADE_T)
        if G.place == 1 then Sfx.win() else Sfx.lose() end
    end
end

-- records persistence (best lap per track; string keys so the datastore's
-- JSON round-trips cleanly) -------------------------------------------------
function Game.loadRecords()
    G.records = playdate.datastore.read("records") or {}
    G.records.best = G.records.best or {}
end

function Game.saveRecord()
    G.records.best[tostring(G.trackSel)] = G.bestLap
    playdate.datastore.write(G.records, "records")
end
