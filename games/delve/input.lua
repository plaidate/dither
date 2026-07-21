-- Delve controls: d-pad walks and climbs, A jumps, B throws a flare,
-- the crank tilts the helmet beam up and down. Menus take A/B/up/down.
--
-- The autopilot below plays the whole campaign. A platformer bot only
-- works if it can LATCH: it follows L.route, an ordered list of
-- waypoints the generator emitted (light this lantern, loot this
-- crate, leave by this hole), and only ever advances the index when
-- the current waypoint is satisfied or is on a floor it has already
-- passed. Nothing here re-decides the plan frame to frame -- the only
-- reactive layers on top are "hop that rock", "jump that hole", "put a
-- flare on the thing coming out of the dark" and, in the last gallery,
-- "hold the beam on the Warden and give ground".

Input = {
    mx = 0, my = 0, jump = false, flare = false, crank = 0,
    aEdge = false, bEdge = false, upEdge = false, downEdge = false,
    wp = 1, stuck = 0, lastX = 0, throwT = 0,
}

local pd = playdate
local clamp = Util.clamp
local abs = math.abs

function Input.reset()
    Input.wp = 1
    Input.stuck = 0
    Input.lastX = G.px or 0
    Input.throwT = 0
end

local function clear()
    Input.mx, Input.my, Input.crank = 0, 0, 0
    Input.jump, Input.flare = false, false
    Input.aEdge, Input.bEdge = false, false
    Input.upEdge, Input.downEdge = false, false
end

-- ---- aiming helpers ----------------------------------------------------

-- crank the beam onto a world point (pitch is measured from the facing
-- direction, so only the vertical part of the offset matters)
local function aimAt(wx, wy)
    local dx = abs(wx - G.px)
    local dy = wy - (G.py - C.LAMP_Y)
    local want = clamp(math.atan(dy, (dx < 2) and 2 or dx),
        C.PITCH_MIN, C.PITCH_MAX)
    Input.crank = clamp((want - G.pitch) / C.CRANK_PITCH, -70, 70)
end

-- pitch the throw so the flare lands about `R` px ahead: the arc is
-- vx = FLARE_VX, vy = FLARE_VY + sin(pitch) * FLARE_AIM, so the range
-- inverts straight out of the ballistics
local function aimThrow(R)
    R = clamp(R, 14, 132)
    local vy = -(R * C.FLARE_G) / (2 * C.FLARE_VX)
    local s = clamp((vy - C.FLARE_VY) / C.FLARE_AIM, -0.95, 0.95)
    local want = clamp(math.asin(s), C.PITCH_MIN, C.PITCH_MAX)
    Input.crank = clamp((want - G.pitch) / C.CRANK_PITCH, -70, 70)
    return abs(want - G.pitch) < 0.14
end

-- ---- plan queries ------------------------------------------------------

local function wpDone(w)
    if w.kind == "lantern" then return w.ref.lit end
    if w.kind == "crate" then
        return G.flares >= C.FLARE_MAX or w.ref.t > 0
    end
    return false
end

local function nearestMob(L, pj)
    local best, bd = nil, 1e9
    for i = 1, #L.mobs do
        local m = L.mobs[i]
        if m.j == pj and not m.hang then
            local d = abs(m.x - G.px)
            if d < bd then best, bd = m, d end
        end
    end
    return best, bd
end

local function nearestCrate(L, pj)
    for i = 1, #L.crates do
        local c = L.crates[i]
        if c.j == pj and c.t <= 0 then return c end
    end
    return nil
end

-- ---- menus (by LABEL, never by index -- menus grow) --------------------

local function menuBot()
    if Kit.mode == "title" then
        local want, idx = "NEW DELVE", 1
        for i = 1, #G.menu do
            if G.menu[i] == want then idx = i end
        end
        if G.menuSel < idx then Input.downEdge = true
        elseif G.menuSel > idx then Input.upEdge = true
        elseif G.frame % 8 == 0 then Input.aEdge = true end
    else
        if G.slotSel ~= 1 then Input.upEdge = true
        elseif G.frame % 8 == 0 then Input.aEdge = true end
    end
end

-- ---- the Warden ---------------------------------------------------------

-- reflexes that apply whatever the plan is: hop the rock prop in front,
-- and hop anyway if we have not actually moved for a while (a wedged
-- bot is the classic way a platformer autopilot stops finishing)
local function unwedge(L, pj)
    if Input.mx ~= 0 and G.onGround then
        local rl = L.rocksBy[pj]
        if rl then
            for i = 1, #rl do
                local r = rl[i]
                local near = (Input.mx > 0) and r.x0 or r.x1
                local ahead = (near - G.px) * Input.mx
                if ahead > -3 and ahead < 24 and r.top < G.py - 3 then
                    Input.jump = true
                end
            end
        end
    end
    if abs(G.px - Input.lastX) < 0.4 and Input.mx ~= 0 and G.onGround then
        Input.stuck = Input.stuck + C.DT
        if Input.stuck > 0.5 then
            Input.jump = true
            if Input.stuck > 1.6 then
                Input.mx = -Input.mx      -- back off and come again
                Input.stuck = 0
            end
        end
    else
        Input.stuck = 0
    end
    Input.lastX = G.px
end

local function fightBoss(b, L, pj)
    local d = b.x - G.px
    local ad = abs(d)
    local sgn = (d > 0) and 1 or -1
    -- hold station inside the lamp's reach but outside its arms
    if ad > 84 then Input.mx = sgn
    elseif ad < 46 then Input.mx = -sgn
    elseif G.face ~= sgn then Input.mx = sgn
    else Input.mx = 0 end
    -- backed into a wall: barge straight past it and take the hit
    if G.px < C.WALLX + 44 then Input.mx = 1
    elseif G.px > C.W - C.WALLX - 44 then Input.mx = -1 end
    -- out of flares: fetch a crate, they restock on a timer
    if G.flares == 0 then
        local c = nearestCrate(L, pj)
        if c then
            local cd = c.x - G.px
            Input.mx = (cd > 4) and 1 or (cd < -4) and -1 or 0
        end
    end
    Input.throwT = math.max(0, Input.throwT - C.DT)
    if G.flares > 1 and Input.throwT <= 0 and ad < 112 and G.face == sgn then
        if aimThrow(ad) then
            Input.flare = true
            Input.throwT = 2.4
        end
    else
        aimAt(b.x, b.y - 16)
    end
end

-- ---- the shaft -----------------------------------------------------------

local function field()
    local L, pj = G.L, G.pj
    local route = L.route

    -- latch the plan forward: a waypoint is left behind when we are
    -- already below its floor, or when it has been satisfied
    while Input.wp < #route do
        local w = route[Input.wp]
        if w.j < pj or wpDone(w) then
            Input.wp = Input.wp + 1
        else
            break
        end
    end
    -- woke up at a checkpoint above the plan: rewind to the first
    -- waypoint at or below this floor
    if route[Input.wp].j > pj then
        for i = 1, #route do
            if route[i].j >= pj then Input.wp = i break end
        end
    end
    local w = route[Input.wp]
    local tx = w.x
    -- Watchdog. If the plan has not advanced in ten seconds the
    -- waypoint is unreachable from here for some reason nobody
    -- foresaw; abandon it and make for the way down, which is the only
    -- target that always exists. Progress beats completeness.
    if Input.wp == Input.lastWp and w.j == Input.lastPj then
        Input.idle = (Input.idle or 0) + C.DT
    else
        Input.idle, Input.lastWp, Input.lastPj = 0, Input.wp, w.j
    end
    if (Input.idle or 0) > 10 and w.kind ~= "hole" and w.kind ~= "exit" then
        local s = L.slabs[pj]
        if s and s.hx then
            tx = s.hx + C.HOLE_W / 2
            Harness.count("botBailouts")
        end
    end
    -- landed on a floor the route skips (a missed rope, a knock into
    -- the wrong hole): the plan is below us, so make for THIS floor's
    -- own hole and rejoin the route underneath
    if w.j > pj then
        local s = L.slabs[pj]
        if s and s.hx then tx = s.hx + C.HOLE_W / 2 end
    end

    if G.onRope then
        Input.my = 1
        aimAt(G.px, G.py + 40)
        return
    end

    local b = G.boss
    if b and not b.down and b.j == pj and b.recoil <= 0 then
        fightBoss(b, L, pj)
        unwedge(L, pj)
        return
    end

    -- out of flares with a crate to hand: restock before pressing on.
    -- Crates restock on a timer, so this is always eventually possible
    -- and a depth can never dead-end for want of light.
    if G.flares == 0 then
        local c = nearestCrate(L, pj)
        if c then tx = c.x end
    end

    local dx = tx - G.px
    if dx > 3 then Input.mx = 1 elseif dx < -3 then Input.mx = -1 end

    -- the target is on the far side of this floor's hole: jump it
    local s = L.slabs[pj]
    if s and s.hx and G.onGround and w.kind ~= "hole" and w.kind ~= "rope" then
        local h0, h1 = s.hx, s.hx + C.HOLE_W
        if G.px < h0 + 5 and tx > h1 and G.px > h0 - 9 then
            Input.jump = true
        elseif G.px > h1 - 5 and tx < h0 and G.px < h1 + 9 then
            Input.jump = true
        end
    end
    unwedge(L, pj)

    -- the whole point of the game: spend light to hold something back
    Input.throwT = math.max(0, Input.throwT - C.DT)
    local m, md = nearestMob(L, pj)
    -- a dark thing standing between us and the waypoint, and nothing
    -- left to buy it off with: hop clean over it. The bite test only
    -- reaches 22px up, so the apex of a jump clears one.
    if m and G.onGround and m.lit <= 0 and Input.mx ~= 0
        and (m.x - G.px) * Input.mx > 0 and md < 40 then
        if G.flares == 0 or md < 20 then Input.jump = true end
    end
    local aimed = false
    if Input.throwT <= 0 and G.flares > 0 then
        if m and md < 78 and m.lit <= 0
            and (G.flares > 1 or md < 56 or not G.lamp) then
            Input.mx = (m.x > G.px) and 1 or -1
            if aimThrow(md) then
                Input.flare = true
                Input.throwT = 1.5
            end
            aimed = true
        elseif L.spec.dark and G.flares > 1 and G.onGround
            and (w.kind == "hole" or w.kind == "rope")
            and abs(dx) < 54 then
            -- a depth with no glowworm seams: throw ahead into the
            -- hole and read the route off what lights up
            if aimThrow(math.max(18, abs(dx))) then
                Input.flare = true
                Input.throwT = 2.2
                Harness.count("scoutFlares")
            end
            aimed = true
        end
    end
    if not aimed then
        if m and md < 120 then
            aimAt(m.x, m.y - 6)
        elseif w.kind == "hole" or w.kind == "rope" then
            aimAt(tx, Level.top(pj) + 34)
        else
            aimAt(tx, G.py - 8)
        end
    end
end

-- ---- entry point ---------------------------------------------------------

local function autopilot()
    clear()
    if Kit.mode == "done" then return end
    if Story.active then
        -- A advances a line; smoke builds also auto-advance after 1.6s,
        -- but tapping keeps a seven-scene campaign inside the budget
        Input.aEdge = (G.frame % 4 == 0)
        return
    end
    if Kit.mode == "title" or Kit.mode == "slots" then
        menuBot()
        return
    end
    if not G.L then return end
    field()
end

function Input.poll()
    if Harness.enabled then
        autopilot()
        return
    end
    Input.mx, Input.my = 0, 0
    if pd.buttonIsPressed(pd.kButtonLeft) then Input.mx = -1 end
    if pd.buttonIsPressed(pd.kButtonRight) then Input.mx = 1 end
    if pd.buttonIsPressed(pd.kButtonUp) then Input.my = -1 end
    if pd.buttonIsPressed(pd.kButtonDown) then Input.my = 1 end
    Input.aEdge = pd.buttonJustPressed(pd.kButtonA)
    Input.bEdge = pd.buttonJustPressed(pd.kButtonB)
    Input.upEdge = pd.buttonJustPressed(pd.kButtonUp)
    Input.downEdge = pd.buttonJustPressed(pd.kButtonDown)
    Input.jump = Input.aEdge
    Input.flare = Input.bEdge
    Input.crank = pd.getCrankChange()
end
