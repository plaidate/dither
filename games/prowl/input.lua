-- Prowl controls: the d-pad pads the cat about, B held creeps (half
-- speed, no footfalls), A takes whatever is in reach -- loot, a lamp
-- wick, the drainpipe -- or throws a pebble when nothing is, and the
-- crank dials how far that pebble goes.
--
-- The smoke autopilot is a burglar, not a survivor. It latches ONE
-- objective at a time -- nearest first, with a discount on dousable
-- lamps because a doused lamp is a permanent improvement to the level
-- -- then the drainpipe once the loot is up. It walks a BFS flow field
-- through the same walkability the cat collides with, and gates every
-- step on Game.exposed(): if the next cell is lit AND a guard can see
-- it, it slides sideways into cover, or holds until the cone sweeps
-- past. Past its patience it throws a pebble behind itself to walk the
-- cone off; past AP_DESPERATE it stops respecting light; past
-- AP_RECKLESS it just walks the field, because a bounded attempt that
-- ends in a collar beats an unbounded wait that ends the run.

Input = {
    mx = 0, my = 0, crank = 0,
    creep = false,
    aPress = false, bPress = false,
    step = 0,           -- menu cursor delta this frame (edge, not held)
    aimx = 0, aimy = 0, -- pebble heading override (autopilot only); a
                        -- human aims with the direction the cat faces
}

local pd = playdate
local clamp = Util.clamp
local floor, sqrt, abs = math.floor, math.sqrt, math.abs

-- ---- the flow field ----------------------------------------------------
-- One BFS over the cell grid, from the objective outward; the bot then
-- always steps to the neighbour with the lower number. Rebuilt only
-- when the objective changes (or every AP_REPATH frames as insurance),
-- because a plan that is re-decided every frame oscillates and
-- finishes nothing.

local dist, queue = {}, {}

local function buildField(goal)
    local GW, GH = Game.GW, Game.GH
    local n = GW * GH
    for i = 1, n do dist[i] = -1 end
    dist[goal] = 0
    queue[1] = goal
    local head, tail = 1, 2
    while head < tail do
        local c = queue[head]
        head = head + 1
        local d = dist[c] + 1
        local ci = (c - 1) % GW
        -- 4-connected: diagonals would cut corners through crates
        if ci > 0 and dist[c - 1] < 0 and G.walk[c - 1] then
            dist[c - 1] = d
            queue[tail] = c - 1
            tail = tail + 1
        end
        if ci < GW - 1 and dist[c + 1] < 0 and G.walk[c + 1] then
            dist[c + 1] = d
            queue[tail] = c + 1
            tail = tail + 1
        end
        if c > GW and dist[c - GW] < 0 and G.walk[c - GW] then
            dist[c - GW] = d
            queue[tail] = c - GW
            tail = tail + 1
        end
        if c + GW <= n and dist[c + GW] < 0 and G.walk[c + GW] then
            dist[c + GW] = d
            queue[tail] = c + GW
            tail = tail + 1
        end
    end
end

-- ---- autopilot state ---------------------------------------------------

local AP = {
    kind = nil,      -- "lamp" | "loot" | "exit"
    idx = 0,
    gx = 0, gy = 0,
    goalCell = -1,
    age = 0,         -- s spent on this objective
    waitT = 0,       -- s spent holding in cover
    stuckT = 0,
    lastX = 0, lastY = 0,
    jig = 0, jx = 0, jy = 0,
    stage = -1, lastT = -1,
    skip = {},       -- objectives given up on this attempt
    aHold = 0,       -- frames since the last A press (menus)
}

-- exposed so the heartbeat (and a probe) can see what the bot thinks
Input.ap = AP

local function resetPlan()
    AP.kind, AP.idx, AP.goalCell, AP.age = nil, 0, -1, 0
    AP.waitT, AP.stuckT, AP.jig = 0, 0, 0
    for k in pairs(AP.skip) do AP.skip[k] = nil end
end

-- Objectives are scored nearest-first across BOTH classes, with a
-- discount on lamps: a doused lamp is a permanent improvement to the
-- level, so it is worth a detour -- but only a detour. Sorting lamps
-- strictly ahead of loot sent the bot across the whole map through
-- three cones for one wick, which is how a heist runs out of night.
local LAMP_BONUS <const> = 0.62

local function scan()
    local kind, bi, bx, by, bs = nil, 0, 0, 0, 1e9
    for i = 1, #G.lamps do
        local l = G.lamps[i]
        if l.douse and not l.out and not AP.skip["lamp" .. i] then
            local dx, dy = l.x - G.px, l.y - G.py
            local s = sqrt(dx * dx + dy * dy) * LAMP_BONUS
            if s < bs then kind, bi, bx, by, bs = "lamp", i, l.x, l.y, s end
        end
    end
    for i = 1, #G.loot do
        local l = G.loot[i]
        if not l.taken and not AP.skip["loot" .. i] then
            local dx, dy = l.x - G.px, l.y - G.py
            local s = sqrt(dx * dx + dy * dy)
            if s < bs then kind, bi, bx, by, bs = "loot", i, l.x, l.y, s end
        end
    end
    return kind, bi, bx, by
end

local function pickGoal()
    if G.lootN < G.lootNeed then
        local kind, bi, bx, by = scan()
        if kind then return kind, bi, bx, by end
        -- Everything on the list has been given up on. Forgive the lot
        -- and go round again: the drainpipe does not open without the
        -- loot, so "head for the exit anyway" is a deadlock, not a plan.
        for k in pairs(AP.skip) do AP.skip[k] = nil end
        Harness.count("forgave")
        kind, bi, bx, by = scan()
        if kind then return kind, bi, bx, by end
    end
    return "exit", 0, G.heist.ex, G.heist.ey
end

-- the goal is still valid, or it is not: loot that got taken, a lamp
-- that got doused, or an objective this attempt has given up on
local function goalStale()
    if not AP.kind then return true end
    if AP.kind == "lamp" then
        local l = G.lamps[AP.idx]
        return (not l) or l.out
    elseif AP.kind == "loot" then
        local l = G.loot[AP.idx]
        return (not l) or l.taken
    end
    return G.lootN < G.lootNeed   -- headed for the exit too early
end

-- ---- movement ----------------------------------------------------------

local function stepToward(tx, ty)
    local dx, dy = tx - G.px, ty - G.py
    Input.mx = (dx > 2.5) and 1 or (dx < -2.5) and -1 or 0
    Input.my = (dy > 2.5) and 1 or (dy < -2.5) and -1 or 0
end

-- the four neighbours of a cell, written into a pooled array rather
-- than visited by a closure: this runs every frame and the house rule
-- is zero allocation in update
local nb = { 0, 0, 0, 0 }

local function neighbours(cur)
    local GW = Game.GW
    local n = GW * Game.GH
    local ci = (cur - 1) % GW
    nb[1] = (ci > 0) and (cur - 1) or 0
    nb[2] = (ci < GW - 1) and (cur + 1) or 0
    nb[3] = (cur > GW) and (cur - GW) or 0
    nb[4] = (cur + GW <= n) and (cur + GW) or 0
end

-- the next cell along the field, as a world point
local function nextPoint()
    local cur = Game.cellOf(G.px, G.py)
    local bd = dist[cur]
    if not bd or bd <= 0 then return AP.gx, AP.gy end
    neighbours(cur)
    local best = nil
    for i = 1, 4 do
        local c = nb[i]
        if c > 0 then
            local d = dist[c]
            if d and d >= 0 and d < bd then best, bd = c, d end
        end
    end
    if not best then return AP.gx, AP.gy end
    return Game.cellPos(best)
end

-- A neighbour that is dark AND does not walk backwards. Following the
-- flow field literally sends the cat down the middle of a corridor,
-- which is exactly where a keeper's lantern points; this lets it slide
-- sideways into the crate shadow and keep going instead of stopping.
local function sideStep(hz)
    local cur = Game.cellOf(G.px, G.py)
    local d0 = dist[cur]
    if not d0 or d0 < 0 then return nil end
    neighbours(cur)
    local best, bd = nil, 1e9
    for i = 1, 4 do
        local c = nb[i]
        if c > 0 then
            local d = dist[c]
            if d and d >= 0 and d <= d0 and d < bd then
                local x, y = Game.cellPos(c)
                if hz(x, y) == 0 then best, bd = c, d end
            end
        end
    end
    if not best then return nil end
    return Game.cellPos(best)
end

-- How bad is standing at (x, y) this frame?
--   2  a guard or a dog is close enough to simply take you
--   1  lit, and somebody with eyes has an unblocked line to it
--   0  the shadow, which is the floor
-- Level 1 is Game.exposed, i.e. the exact rule the guards use -- the
-- bot is not cheating, it is asking the same question the game asks.
local function hazard(x, y)
    for i = 1, #G.guards do
        local g = G.guards[i]
        local dx, dy = x - g.x, y - g.y
        if dx * dx + dy * dy < C.AP_KEEP * C.AP_KEEP then return 2 end
    end
    for i = 1, #G.dogs do
        local d = G.dogs[i]
        local dx, dy = x - d.x, y - d.y
        if dx * dx + dy * dy < C.AP_DOGKEEP * C.AP_DOGKEEP then return 2 end
    end
    if Game.exposed(x, y) then return 1 end
    return 0
end

-- somewhere near here that is dark, walkable, and not in anyone's lap;
-- two rings out, then a straight run away from whoever is nearest
local OFF <const> = {
    0, -16, 16, 0, 0, 16, -16, 0,
    12, -12, 12, 12, -12, 12, -12, -12,
    0, -30, 30, 0, 0, 30, -30, 0,
    21, -21, 21, 21, -21, 21, -21, -21,
}

-- whoever is nearest and can do something about it
local function nearestThreat()
    local best, bd = nil, 1e9
    for i = 1, #G.guards do
        local g = G.guards[i]
        local dx, dy = g.x - G.px, g.y - G.py
        local d = dx * dx + dy * dy
        if d < bd then best, bd = g, d end
    end
    for i = 1, #G.dogs do
        local g = G.dogs[i]
        local dx, dy = g.x - G.px, g.y - G.py
        local d = dx * dx + dy * dy
        if d < bd then best, bd = g, d end
    end
    return best, sqrt(bd)
end

-- Back off. Candidates are scored hazard-first, then by distance from
-- whoever is nearest -- scoring rather than first-match is what stops
-- the bot reversing straight into a corner and waiting to be collared.
local function retreat()
    local th = nearestThreat()
    local bx, by, bs = nil, nil, 1e9
    for i = 1, #OFF, 2 do
        local nx = clamp(G.px + OFF[i], C.X0, C.X1)
        local ny = clamp(G.py + OFF[i + 1], C.Y0, C.Y1)
        if not Game.solid(nx, ny, C.PRAD + 1) then
            local s = hazard(nx, ny) * 1000
            if th then
                local dx, dy = nx - th.x, ny - th.y
                s = s - sqrt(dx * dx + dy * dy)
            end
            -- corners are traps: pay heavily for hugging the bounds,
            -- or a long retreat walks the cat into one and parks it
            if nx < C.X0 + 30 or nx > C.X1 - 30 then s = s + 75 end
            if ny < C.Y0 + 30 or ny > C.Y1 - 30 then s = s + 75 end
            if s < bs then bx, by, bs = nx, ny, s end
        end
    end
    if bx then
        stepToward(bx, by)
    elseif th then
        stepToward(G.px * 2 - th.x, G.py * 2 - th.y)
    end
end

-- A pebble thrown behind us walks a cone off the route -- but never
-- near a dog, because a pebble is noise and noise is the one thing a
-- mastiff is genuinely good at.
local function maybePebble(dgx, dgy, bolt)
    if bolt then return end
    for i = 1, #G.dogs do
        local d = G.dogs[i]
        local dx, dy = d.x - G.px, d.y - G.py
        if dx * dx + dy * dy < 170 * 170 then return end
    end
    if AP.waitT > 1.5 and G.pebbles > 0 and G.pebT <= 0
        and not G.peb.live then
        Input.aimx = (dgx > 0) and -1 or 1
        Input.aimy = (dgy > 0) and -1 or 1
        Input.aPress = true
    end
end

-- ---- the pilot ---------------------------------------------------------

local function menuPilot()
    AP.aHold = AP.aHold + 1
    local m = Kit.mode
    if m == "done" then return end          -- sit on the credits
    if m == "slots" then
        -- always take slot 1; a fresh datastore means a new campaign
        if G.sel > 1 then Input.step = -1 return end
        if AP.aHold % 14 == 0 then Input.aPress = true end
        return
    end
    if m == "menu" then
        -- by LABEL, never by index: the menu grows
        local want = 1
        for i = 1, #G.menuRows do
            if G.menuRows[i] == "CONTINUE" then want = i end
        end
        if G.sel < want then Input.step = 1 return end
        if G.sel > want then Input.step = -1 return end
        if AP.aHold % 14 == 0 then Input.aPress = true end
        return
    end
    if AP.aHold % 12 == 0 then Input.aPress = true end
end

local function pilot(dt)
    -- a new attempt (stage change or a restart after a collar) wipes
    -- the plan, the give-up list and the stuck timers
    if G.stage ~= AP.stage or G.stageT < AP.lastT then
        AP.stage = G.stage
        resetPlan()
    end
    AP.lastT = G.stageT

    -- keep the pebble dialled long: the point of a decoy is distance
    Input.crank = clamp((C.THROW_MAX - 10 - G.throwR) / C.CRANK_GAIN,
        -30, 30)

    if goalStale() or AP.goalCell < 0 then
        AP.kind, AP.idx, AP.gx, AP.gy = pickGoal()
        AP.gx, AP.gy = Game.freePoint(AP.gx, AP.gy)
        AP.goalCell = Game.cellOf(AP.gx, AP.gy)
        buildField(AP.goalCell)
        AP.age, AP.waitT = 0, 0
    elseif G.frame % C.AP_REPATH == 0 then
        local c = Game.cellOf(AP.gx, AP.gy)
        if c ~= AP.goalCell then
            AP.goalCell = c
            buildField(c)
        end
    end
    AP.age = AP.age + dt

    -- give up on an objective that is costing too much and take the
    -- next one; the exit is never given up on
    if AP.age > 26 and AP.kind ~= "exit" then
        AP.skip[AP.kind .. AP.idx] = true
        AP.kind = nil
        return
    end

    local dgx, dgy = AP.gx - G.px, AP.gy - G.py
    local gd = sqrt(dgx * dgx + dgy * dgy)

    -- in reach? take it. (Game.interact resolves exit > loot > lamp,
    -- and falls through to a pebble when nothing is in range.)
    if AP.kind == "loot" and gd < C.LOOT_R - 3 then
        Input.aPress = true
        return
    elseif AP.kind == "lamp" and gd < C.DOUSE_R - 4 then
        Input.aPress = true
        return
    elseif AP.kind == "exit" and gd < C.EXIT_R - 4
        and G.lootN >= G.lootNeed then
        Input.aPress = true
        return
    end

    -- creep whenever anything that can hear or see is close: the cost
    -- is speed, and speed is the only thing this game charges for.
    -- Once the meter is past half the cover story is over -- run.
    -- A footfall carries NOISE_WALK px, so past that a guard simply
    -- cannot hear the cat pad: creeping out there buys nothing and
    -- costs half the speed, which is how a bot runs out of night.
    local hearR = C.NOISE_WALK + 10
    local near = false
    for i = 1, #G.guards do
        local g = G.guards[i]
        local dx, dy = g.x - G.px, g.y - G.py
        if dx * dx + dy * dy < hearR * hearR then near = true end
    end
    local bolt = false
    for i = 1, #G.dogs do
        local d = G.dogs[i]
        local dx, dy = d.x - G.px, d.y - G.py
        local q = dx * dx + dy * dy
        if q < (C.DOG_HEAR + 46) ^ 2 then near = true end
        -- already heard: creeping now just gets you caught, RUN
        if d.state == "chase" and q < 130 * 130 then bolt = true end
    end
    Input.creep = (near or G.det > 0.05) and G.det < 0.5 and not bolt

    -- Jiggle out of a corner the flow field cannot see (an actor
    -- standing in the doorway, a slide that keeps failing). Only counts
    -- while we were actually TRYING to move -- a deliberate wait in
    -- cover is not being stuck.
    local mvx, mvy = G.px - AP.lastX, G.py - AP.lastY
    if AP.wasMoving and mvx * mvx + mvy * mvy < 1.2 then
        AP.stuckT = AP.stuckT + dt
    else
        AP.stuckT = 0
    end
    AP.lastX, AP.lastY = G.px, G.py
    if AP.stuckT > C.AP_STUCK then
        AP.stuckT = 0
        AP.jig = 0.55
        AP.jx = (math.random() < 0.5) and -1 or 1
        AP.jy = (math.random() < 0.5) and -1 or 1
    end
    if AP.jig > 0 then
        AP.jig = AP.jig - dt
        Input.mx, Input.my = AP.jx, AP.jy
        return
    end

    -- Last resort. Well past par the bot stops asking permission and
    -- simply walks the flow field: no waiting, no retreating, no
    -- keep-out. It either gets there or gets collared, and a collar
    -- costs one banner and a fresh set of sweep phases. A stealth bot
    -- with no floor on its patience can stand in a doorway all night,
    -- and that is the one failure mode a headless run cannot survive.
    if G.stageT > C.AP_RECKLESS then
        Harness.count("reckless")
        Input.creep = false
        stepToward(nextPoint())
        return
    end

    -- a dog on your heels is not a lighting problem: put ground
    -- between you and it and let its chase clock run out
    if bolt then
        AP.push, AP.waitT = 0, 0
        retreat()
        return
    end

    AP.push = math.max(0, (AP.push or 0) - dt)
    -- past par the bot stops being careful. A collar costs one banner
    -- and a fresh set of guard sweep phases, which is strictly better
    -- than standing in a doorway for the rest of the night.
    if G.stageT > C.AP_DESPERATE then
        AP.push = math.max(AP.push, 0.5)
        if next(AP.skip) then
            for k in pairs(AP.skip) do AP.skip[k] = nil end
        end
        Harness.count("desperate")
    end

    -- blown: stop burgling and get back into the dark
    if G.det > C.AP_RISK_STOP then
        AP.push, AP.waitT = 0, 0
        retreat()
        return
    end

    local tx, ty = nextPoint()

    if AP.push > 0 then
        -- committed: light no longer stops us, arms still do
        if hazard(tx, ty) >= 2 then
            AP.push = 0
            retreat()
            return
        end
        stepToward(tx, ty)
    elseif hazard(G.px, G.py) > 0 then
        -- standing somewhere bad: leave it before anything else
        AP.waitT = AP.waitT + dt
        maybePebble(dgx, dgy, bolt)
        if AP.waitT >= C.AP_PATIENCE then
            AP.push, AP.waitT = C.AP_PUSH, 0
        end
        retreat()
        return
    elseif hazard(tx, ty) == 1 and gd < C.AP_LUNGE then
        -- close enough to touch it: a second of light costs less than
        -- a wait, because the meter drains almost as fast as it fills
        stepToward(tx, ty)
    elseif hazard(tx, ty) > 0 then
        local sx, sy = sideStep(hazard)
        if sx then
            AP.waitT = 0
            stepToward(sx, sy)
            return
        end
        -- the next cell is lit and watched: hold in cover and let the
        -- cone sweep past. This wait IS the game.
        AP.waitT = AP.waitT + dt
        maybePebble(dgx, dgy, bolt)
        if AP.waitT >= C.AP_PATIENCE then
            AP.push, AP.waitT = C.AP_PUSH, 0
        end
    else
        AP.waitT = 0
        stepToward(tx, ty)
    end
end

local function autopilot()
    Input.mx, Input.my, Input.crank, Input.step = 0, 0, 0, 0
    Input.aimx, Input.aimy = 0, 0
    Input.aPress, Input.bPress, Input.creep = false, false, false
    if Story.active then
        -- dstory auto-advances lines in smoke builds; nothing to do
        return
    end
    if Kit.mode ~= "play" then
        menuPilot()
        return
    end
    AP.aHold = 0
    pilot(C.DT)
    -- remembered for next frame's stuck test: a bot that jiggles out of
    -- a deliberate wait can never sit still long enough to be missed
    AP.wasMoving = (Input.mx ~= 0 or Input.my ~= 0)
end

-- ---- the real thing ----------------------------------------------------

function Input.poll()
    if Harness.enabled then
        autopilot()
        return
    end
    local mx, my = 0, 0
    if pd.buttonIsPressed(pd.kButtonLeft) then mx = -1 end
    if pd.buttonIsPressed(pd.kButtonRight) then mx = 1 end
    if pd.buttonIsPressed(pd.kButtonUp) then my = -1 end
    if pd.buttonIsPressed(pd.kButtonDown) then my = 1 end
    Input.mx, Input.my = mx, my
    Input.step = (pd.buttonJustPressed(pd.kButtonDown) and 1 or 0)
        - (pd.buttonJustPressed(pd.kButtonUp) and 1 or 0)
    Input.aimx, Input.aimy = 0, 0
    Input.creep = pd.buttonIsPressed(pd.kButtonB)
    Input.crank = pd.getCrankChange()
    Input.aPress = pd.buttonJustPressed(pd.kButtonA)
    Input.bPress = pd.buttonJustPressed(pd.kButtonB)
end
