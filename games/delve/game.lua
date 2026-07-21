-- Delve: the simulation. Platforming, the lamp's oil, thrown flares,
-- the things that only move in the dark, the Warden, and the
-- title/slots/play/done machine.
--
-- The one rule the whole game hangs off: Light.at is the AI's input.
-- A crawler outside every light advances on you; a crawler standing in
-- light backs out of it. So a thrown flare is a wall you build out of
-- light and a spent flare is a wall that falls down -- and because the
-- slab you are standing on is registered with Light.wall, you cannot
-- see the floor below until you drop a flare through the hole.

Game = {}

local clamp = Util.clamp
local abs = math.abs
local floor = math.floor

-- ---- light pass -------------------------------------------------------
-- Runs once per frame AFTER movement and BEFORE any Light.at query, so
-- pixels and logic are answering from the same sources.

-- record a source in world space for Game.illum / mob retreat. Cones
-- count out to their full reach (a beam is already directional); point
-- lights only count their lit core.
local function src(x, y, rad, dir, half)
    local n = G.nsrc + 1
    G.nsrc = n
    local s = G.srcs[n]
    if not s then s = {} G.srcs[n] = s end
    s.x, s.y, s.rad, s.dir, s.half = x, y, rad, dir, half
    return s
end

function Game.castLights()
    local L, cy = G.L, G.camy
    Light.begin(C.AMBIENT)
    G.nsrc = 0
    Level.castWalls(L, G.pj, cy)
    -- glowworm seams (nearest few on screen)
    local ng = 0
    for i = 1, #L.glows do
        local g = L.glows[i]
        local sy = g.y - cy
        if sy > -30 and sy < C.H + 30 then
            if ng < C.GLOW_MAX then
                ng = ng + 1
                local r = C.GLOW_R * (0.85 + 0.15 * math.sin(g.ph + G.frame * 0.05))
                Light.add(g.x, sy, r, C.GLOW_FALL)
                src(g.x, g.y, r * C.GLOW_FALL)
            end
        end
    end
    -- lanterns you have lit stay lit for the rest of the depth
    for i = 1, #L.lanterns do
        local l = L.lanterns[i]
        if l.lit then
            local sy = l.y - 20 - cy
            if sy > -90 and sy < C.H + 90 then
                Light.add(l.x, sy, C.LANT_R, C.LANT_FALL)
                src(l.x, l.y - 20, C.LANT_R * C.LANT_FALL)
            end
        end
    end
    -- burning flares: the light you spent, sitting where it landed
    for i = 1, #G.burning do
        local b = G.burning[i]
        local r = C.FLARE_R * math.min(1, b.t / C.FLARE_FADE)
        local sy = b.y - cy
        if r > 4 and sy > -90 and sy < C.H + 90 then
            Light.add(b.x, sy, r, C.FLARE_FALL)
            src(b.x, b.y, r * C.FLARE_FALL)
        end
    end
    -- the helmet lamp goes LAST: light.lua carves each light's shadows
    -- in add order, so the caster that matters most is added last
    if G.lamp and G.oil > 0 then
        local dir = (G.face > 0) and G.pitch or (math.pi - G.pitch)
        local lx, ly = G.px, G.py - C.LAMP_Y
        Light.cone(lx, ly - cy, C.LAMP_R, dir, C.LAMP_SPREAD, C.LAMP_FALL)
        src(lx, ly, C.LAMP_R, dir, C.LAMP_SPREAD * 0.5)
        G.beamDir = dir
    else
        G.beamDir = nil
    end
end

-- how many lit sources cover a world point (the Warden's pressure)
function Game.illum(x, y)
    local n = 0
    for i = 1, G.nsrc do
        local s = G.srcs[i]
        local dx, dy = x - s.x, y - s.y
        if dx * dx + dy * dy <= s.rad * s.rad then
            if s.dir then
                local a = math.atan(dy, dx) - s.dir
                while a > math.pi do a = a - 2 * math.pi end
                while a < -math.pi do a = a + 2 * math.pi end
                if abs(a) <= s.half then n = n + 1 end
            else
                n = n + 1
            end
        end
    end
    return n
end

-- the source a lit creature is backing away from
local function nearestSrc(x, y)
    local bx, bd = nil, 1e9
    for i = 1, G.nsrc do
        local s = G.srcs[i]
        local dx, dy = x - s.x, y - s.y
        local d = dx * dx + dy * dy
        if d < bd then bx, bd = s.x, d end
    end
    return bx
end

-- ---- the delver -------------------------------------------------------

local function onLand(drop)
    Sfx.land()
    if drop > C.FALL_HURT then
        Game.hurt(1, nil)
        Harness.count("fallHurts")
    end
end

local function tryRope(dt)
    local L = G.L
    -- only a FALLING delver catches a rope. Without this a jump taken
    -- alongside a rope re-grabs it at the top of the arc, and the bot
    -- spends the rest of the level riding up and down the same line.
    if G.onRope or (G.ropeCd or 0) > 0 or Input.jump or G.vy < 30 then
        return
    end
    -- a generous catch: you always step off a ledge with speed on, so
    -- by the time you have cleared the lip you are a good ten pixels
    -- downrange of the rope. The window is still inside the hole.
    for i = 1, #L.ropes do
        local r = L.ropes[i]
        if abs(G.px - r.x) < 20 and G.py > r.y0 and G.py < r.y1 - 24 then
            G.onRope = r
            G.px, G.vx, G.vy = r.x, 0, 0
            Harness.count("ropeGrabs")
            return
        end
    end
end

local function movePlayer(dt)
    local L = G.L
    if G.onRope then
        local r = G.onRope
        G.px, G.vx, G.vy = r.x, 0, 0
        G.py = clamp(G.py + Input.my * C.ROPE_SPD * dt, r.y0 + 12, r.y1)
        if Input.jump then
            G.onRope, G.ropeCd = nil, 0.9
            G.vy = -C.JUMPV * 0.55
            G.vx = Input.mx * C.RUN
            G.onGround, G.fallFrom = false, G.py
        elseif G.py >= r.y1 - 0.5 then
            G.onRope, G.ropeCd = nil, 0.6
            G.onGround, G.fallFrom = true, G.py
            G.pj = Level.floorOf(G.py)
        end
        return
    end

    -- Last-ditch extraction. The generator goes to some trouble never
    -- to drop a solid prop on a landing point, but a knockback or a
    -- falling rock can still leave the delver inside rock, and inside
    -- rock every axis is blocked including the jump. Lift out.
    if Level.solidBox(L, G.px, G.py, C.PW, C.PH) then
        local up = Level.top(Level.floorOf(G.py) - 1) + C.SLAB + C.PH
        G.py = math.max(C.TOP0, up)
        G.vy = 0
        if Level.solidBox(L, G.px, G.py, C.PW, C.PH) then
            G.px = clamp(G.px + 24 * G.face, C.WALLX + 8,
                C.W - C.WALLX - 8)
        end
        Harness.count("extracted")
    end

    local run = C.RUN * (G.wet and C.SWIM or 1)
    local acc = G.onGround and C.ACC or C.AIR
    if Input.mx ~= 0 then
        G.vx = clamp(G.vx + Input.mx * acc * dt, -run, run)
        G.face = (Input.mx > 0) and 1 or -1
    elseif G.onGround then
        if G.vx > 0 then G.vx = math.max(0, G.vx - C.FRICT * dt)
        else G.vx = math.min(0, G.vx + C.FRICT * dt) end
    end
    if Input.jump and (G.onGround or G.coyote > 0) then
        G.vy = -C.JUMPV
        G.onGround, G.coyote = false, 0
        G.fallFrom = G.py
        -- longer than the whole jump arc: a deliberate jump beside a
        -- rope must never re-grab it, or the bot rides the same line
        -- up and down for the rest of the level
        G.ropeCd = 0.9
        Sfx.jump()
    end
    G.vy = math.min(C.MAXFALL, G.vy + C.GRAV * dt)

    local nx = G.px + G.vx * dt
    if Level.solidBox(L, nx, G.py, C.PW, C.PH) then G.vx = 0 else G.px = nx end

    local ny = G.py + G.vy * dt
    if G.vy >= 0 then
        local ly = Level.landY(L, G.px, G.py, ny, C.PW)
        if ly then
            local drop = ly - G.fallFrom
            G.py, G.vy = ly, 0
            if not G.onGround then onLand(drop) end
            G.onGround, G.coyote = true, C.COYOTE
            G.pj = Level.floorOf(G.py)
            G.fallFrom = G.py
        else
            if G.onGround then G.fallFrom = G.py end
            G.py, G.onGround = ny, false
            G.coyote = math.max(0, G.coyote - dt)
        end
    else
        if Level.solidBox(L, G.px, ny, C.PW, C.PH) then
            G.vy = 0
        else
            G.py = ny
        end
        G.onGround = false
        if G.py < G.fallFrom then G.fallFrom = G.py end
    end
    if not G.onGround then tryRope(dt) end
end

function Game.camera(dt)
    local want = clamp(G.py - 148, 0, math.max(0, G.L.h - C.H))
    if dt then
        G.camy = G.camy + (want - G.camy) * math.min(1, dt * 7)
    else
        G.camy = want
    end
end

local function aim(dt)
    if abs(Input.crank) > 0.5 then
        G.pitch = G.pitch + Input.crank * C.CRANK_PITCH
    else
        local d = C.PITCH_HOME - G.pitch
        local s = C.PITCH_RETURN * dt
        G.pitch = (abs(d) <= s) and C.PITCH_HOME
            or (G.pitch + ((d > 0) and s or -s))
    end
    G.pitch = clamp(G.pitch, C.PITCH_MIN, C.PITCH_MAX)
end

-- ---- flares -----------------------------------------------------------

function Game.throwFlare()
    if G.flares <= 0 or G.flareCd > 0 then return end
    G.flares = G.flares - 1
    G.flaresSpent = G.flaresSpent + 1
    G.flareCd = C.FLARE_CD
    local f = G.flying[#G.flying + 1]
    if not f then f = {} G.flying[#G.flying + 1] = f end
    f.x = G.px + G.face * 8
    f.y = G.py - C.LAMP_Y
    f.vx = C.FLARE_VX * G.face + G.vx * 0.4
    f.vy = C.FLARE_VY + math.sin(G.pitch) * C.FLARE_AIM
    f.spin = 0
    Sfx.throw()
    Harness.count("flaresThrown")
end

local function settleFlare(x, y)
    if Level.poolAt(G.L, x, y) then
        Sfx.snuff()
        Kit.burst(G.parts, x, y - G.camy, 6, 60, 20)
        Harness.count("snuffed")
        return
    end
    local b = G.burning[#G.burning + 1]
    if not b then b = {} G.burning[#G.burning + 1] = b end
    b.x, b.y, b.t = x, y, C.FLARE_LIFE
    Sfx.ignite()
    Kit.burst(G.parts, x, y - G.camy, 10, 100, 30)
    Harness.count("flaresLit")
end

function Game.updateFlares(dt)
    local L = G.L
    for i = #G.flying, 1, -1 do
        local f = G.flying[i]
        f.spin = f.spin + dt * 14
        f.vy = math.min(C.MAXFALL, f.vy + C.FLARE_G * dt)
        local nx = f.x + f.vx * dt
        if nx < C.WALLX + 3 or nx > C.W - C.WALLX - 3 then
            f.vx = -f.vx * 0.4
        else
            f.x = nx
        end
        local ny = f.y + f.vy * dt
        if f.vy > 0 then
            local ly = Level.landY(L, f.x, f.y, ny, 3)
            if ly then
                settleFlare(f.x, ly - 3)
                table.remove(G.flying, i)
                goto continue
            end
        end
        f.y = ny
        if f.y > L.h then table.remove(G.flying, i) end
        ::continue::
    end
    for i = #G.burning, 1, -1 do
        local b = G.burning[i]
        b.t = b.t - dt
        if b.t <= 0 then
            table.remove(G.burning, i)
            Harness.count("flaresDied")
        end
    end
end

-- ---- the dark things ---------------------------------------------------

-- walk a mob along its slab; it will not step into a hole or a wall
local function stepMob(m, d)
    local nx = m.x + d
    if nx < C.WALLX + 6 or nx > C.W - C.WALLX - 6
        or not Level.colSolid(G.L, m.j, nx, 6) then
        m.dir = -m.dir
        return
    end
    m.x = nx
end

local function updateMob(m, i, dt)
    m.step = m.step + dt * 6
    if m.bite > 0 then m.bite = m.bite - dt end
    -- staggered Light.at: each query walks every light against every
    -- wall, so a mob refreshes its own answer every LIT_EVERY frames
    if (G.frame + i) % C.LIT_EVERY == 0 then
        local sy = m.y - 6 - G.camy
        m.lit = (sy > -40 and sy < C.H + 40) and Light.at(m.x, sy) or 0
    end

    if m.hang then
        -- a clinger drops the moment you walk under it in the dark
        if m.lit <= 0 and G.pj == m.j and abs(G.px - m.x) < C.CLING_DROP then
            m.hang, m.vy = false, 0
            Harness.count("clingers")
            Sfx.repel()
        end
        return
    end
    if m.vy and m.vy > 0 or (m.kind == "clinger" and m.y < Level.top(m.j) - 1) then
        m.vy = (m.vy or 0) + C.GRAV * dt
        local ny = m.y + m.vy * dt
        local ly = Level.landY(G.L, m.x, m.y, ny, 5)
        if ly then
            m.y, m.vy = ly, 0
            m.j = Level.floorOf(m.y)
        else
            m.y = ny
            if m.y > G.L.h then m.y = Level.top(m.j) end
        end
        return
    end

    if m.lit > 0 then
        -- driven back: it retreats from whatever is lighting it
        local sx = nearestSrc(m.x, m.y - 6) or (m.x - m.dir * 10)
        m.dir = (m.x >= sx) and 1 or -1
        stepMob(m, m.dir * m.spd * C.CRAWL_FLEE * dt)
        if m.litT <= 0 then
            Harness.count("repelled")
            Sfx.repel()
        end
        m.litT = 0.6
    else
        m.litT = math.max(0, m.litT - dt)
        local dx = G.px - m.x
        if G.pj == m.j and abs(dx) < C.CRAWL_RANGE then
            m.dir = (dx > 0) and 1 or -1
            stepMob(m, m.dir * m.spd * dt)
            if abs(dx) < C.CRAWL_HIT and abs(G.py - m.y) < 22
                and m.bite <= 0 then
                m.bite = C.CRAWL_CD
                Game.hurt(1, m.x)
            end
        end
    end
end

function Game.updateMobs(dt)
    local mobs = G.L.mobs
    for i = 1, #mobs do updateMob(mobs[i], i, dt) end
end

function Game.updateFallers(dt)
    local L = G.L
    for i = 1, #L.fallers do
        local f = L.fallers[i]
        if f.state == "wait" then
            f.t = f.t - dt
            if f.t <= 0 and G.pj == f.j then
                f.state, f.t = "warn", C.FALL_WARN
            elseif f.t <= 0 then
                f.t = 0.4
            end
        elseif f.state == "warn" then
            f.t = f.t - dt
            if f.t <= 0 then f.state, f.y = "fall", f.ceil end
        else
            f.y = f.y + C.FALL_SPD * dt
            if G.pj == f.j and abs(G.px - f.x) < 10
                and abs(G.py - f.y) < 22 then
                Game.hurt(1, nil)
                f.state, f.t, f.y = "wait", C.FALL_EVERY, nil
            elseif f.y >= f.base then
                Kit.shake(0.25)
                Sfx.rock()
                Kit.burst(G.parts, f.x, f.base - G.camy, 8, 110, 40)
                Harness.count("rockfalls")
                f.state, f.t, f.y = "wait", C.FALL_EVERY, nil
            end
        end
    end
end

-- ---- damage ------------------------------------------------------------

function Game.hurt(n, fromX)
    if G.invuln > 0 or G.exited then return end
    G.grit = G.grit - n
    G.invuln = C.HURT_INVULN
    G.hurtFlash = 0.3
    local away = (fromX and G.px < fromX) and -1 or 1
    G.vx = away * C.KNOCK
    G.vy = -120
    G.onGround, G.onRope = false, nil
    Kit.shake(0.35)
    Sfx.hurt()
    Harness.count("hits")
    if G.grit <= 0 then Game.blackout() end
end

function Game.blackout()
    G.deaths = G.deaths + 1
    Harness.count("deaths")
    G.grit = C.GRIT_MAX
    G.px, G.py = G.checkX, G.checkY
    G.vx, G.vy = 0, 0
    G.onGround, G.onRope = true, nil
    G.pj = Level.floorOf(G.py)
    G.fallFrom = G.py
    G.invuln = 2.0
    if G.lamp then G.oil = math.max(G.oil, 45) end
    G.flares = math.max(G.flares, 1)
    Game.camera(nil)
    Sfx.down()
    Kit.shake(0.6)
    Input.reset()
    -- shove anything close away, so you never wake into a bite
    for i = 1, #G.L.mobs do
        local m = G.L.mobs[i]
        if m.j == G.pj and abs(m.x - G.px) < 60 then
            m.x = clamp(m.x + ((m.x > G.px) and 46 or -46),
                C.WALLX + 8, C.W - C.WALLX - 8)
            m.bite = 1.5
        end
    end
    if G.boss then
        G.boss.x = (G.px < C.W / 2) and (C.W - C.WALLX - 30)
            or (C.WALLX + 30)
        G.boss.recoil = 1.2
    end
end

-- ---- fixtures ----------------------------------------------------------

function Game.fixtures(dt)
    local L = G.L
    for i = 1, #L.lanterns do
        local l = L.lanterns[i]
        if not l.lit and G.pj == l.j and abs(G.px - l.x) < C.LANT_NEAR
            and abs(G.py - l.y) < 26 then
            l.lit = true
            if G.lamp then G.oil = C.OIL_MAX end
            G.flares = C.FLARE_MAX
            G.grit = C.GRIT_MAX
            G.checkX, G.checkY = l.x, l.y
            G.lanternsLit = G.lanternsLit + 1
            Sfx.lantern()
            Kit.burst(G.parts, l.x, l.y - 20 - G.camy, 12, 90, 40)
            Harness.count("lanterns")
            Game.save()
        end
    end
    for i = 1, #L.crates do
        local c = L.crates[i]
        if c.t > 0 then
            c.t = c.t - dt
        elseif G.pj == c.j and abs(G.px - c.x) < C.CRATE_NEAR
            and abs(G.py - c.y) < 24 and G.flares < C.FLARE_MAX then
            c.t = C.CRATE_RESP
            G.flares = math.min(C.FLARE_MAX, G.flares + 2)
            Sfx.crate()
            Harness.count("crates")
        end
    end
    if not G.exited and not L.spec.boss and G.pj >= L.floors
        and abs(G.px - L.exitX) < C.EXIT_NEAR then
        Game.clearDepth()
    end
end

-- ---- the Warden ---------------------------------------------------------

local function startBoss()
    G.boss = {
        x = (G.px < C.W / 2) and (C.W - C.WALLX - 34) or (C.WALLX + 34),
        y = Level.top(1), j = 1,
        phase = 1, push = 0, recoil = 0, dir = -1,
        lit = 0, eye = 0, spd = C.BOSS_SPD,
    }
end

function Game.updateBoss(dt)
    local b = G.boss
    b.eye = b.eye + dt
    b.lit = Light.at(b.x, b.y - 16 - G.camy)
    if b.recoil > 0 then
        b.recoil = b.recoil - dt
        b.x = clamp(b.x + b.dir * 46 * dt, C.WALLX + 20,
            C.W - C.WALLX - 20)
        return
    end
    -- it does not lose you. Give it a gallery of daylight between you
    -- and it comes up (or down) through the workings to your floor.
    if b.j ~= G.pj then
        b.seek = (b.seek or 0) + dt
        if b.seek > 2.5 then
            b.j, b.seek = G.pj, 0
            b.y = Level.top(b.j)
            b.x = (G.px < C.W / 2) and (C.W - C.WALLX - 34)
                or (C.WALLX + 34)
            b.recoil = 0.6
            Kit.shake(0.4)
            Harness.count("wardenFollows")
        end
        return
    end
    b.seek = 0
    -- pressure: every lit-core source covering it pushes harder. The
    -- lamp alone is slow; a flare landed on it is worth three seconds.
    local n = Game.illum(b.x, b.y - 16)
    if n > 0 then
        b.push = math.min(C.BOSS_PUSH, b.push + C.BOSS_GAIN * n * dt)
    else
        b.push = math.max(0, b.push - C.BOSS_DRAIN * dt)
    end
    -- it only advances where Light.at says it is dark
    if b.lit <= 0 and G.pj == b.j then
        local d = G.px - b.x
        b.dir = (d > 0) and 1 or -1
        b.x = clamp(b.x + b.dir * b.spd * dt, C.WALLX + 20,
            C.W - C.WALLX - 20)
    end
    if G.pj == b.j and abs(G.px - b.x) < C.BOSS_HIT
        and abs(G.py - b.y) < 26 then
        Game.hurt(1, b.x)
    end
    if b.push >= C.BOSS_PUSH then
        b.push = 0
        b.recoil = C.BOSS_RECOIL
        b.dir = (G.px > b.x) and -1 or 1
        Harness.count("bossPhases")
        Sfx.phase()
        Kit.shake(0.7)
        if b.phase >= C.BOSS_PHASES then
            Game.bossDown()
        else
            b.phase = b.phase + 1
            b.j = math.min(G.L.floors, b.j + 1)
            b.y = Level.top(b.j)
            b.spd = C.BOSS_SPD + (b.phase - 1) * C.BOSS_RAMP
        end
    end
end

function Game.bossDown()
    G.boss.down = true
    G.exited = true
    G.cleared = C.LAST
    Harness.count("depths")
    Sfx.win()
    Game.save()
    Tale.play("end", function() Game.finish() end)
end

function Game.finish()
    Harness.count("done")
    Harness.set("won", 1)
    Kit.saveBest(G.cleared * 100 + math.max(0, 200 - G.deaths * 8))
    Kit.setMode("done", 1.2)
    Music.set(Sfx.WINDLASS)
end

-- ---- campaign flow -------------------------------------------------------

function Game.save()
    Save.set("depth", G.depth)
    Save.set("cleared", G.cleared)
    Save.set("deaths", G.deaths)
    Save.set("runT", floor(G.runT))
    Save.set("spent", G.flaresSpent)
    Save.set("lanterns", G.lanternsLit)
    Save.meta.name = "VESPER"
    Save.meta.place = G.L and G.L.spec.name or "THE ADIT"
    Save.meta.pct = floor(G.cleared / C.LAST * 100 + 0.5)
    Save.unlock(math.min(C.LAST, G.cleared + 1))
    Save.commit()
end

function Game.enterDepth(d)
    G.depth = math.min(C.LAST, d)
    local L = Level.build(G.depth)
    G.newDepth(L)
    Game.camera(nil)
    if L.spec.boss then startBoss() end
    Input.reset()
    Music.set(Sfx.SONGS[L.spec.song] or Sfx.SHAFT)
    Kit.setMode("play", 2.2)
    Harness.set("depth", G.depth)
    local scene = Tale.before[G.depth]
    if scene and not Save.flag("sc_" .. scene) then
        Save.flag("sc_" .. scene, true)
        Tale.play(scene)
    end
end

function Game.clearDepth()
    G.exited = true
    G.cleared = math.max(G.cleared, G.depth)
    G.exitT = 1.1
    Harness.count("depths")
    Sfx.clear()
    Kit.burst(G.parts, G.px, G.py - 10 - G.camy, 14, 120, 60)
    Game.save()
end

-- ---- title and slots ------------------------------------------------------

function Game.buildMenu()
    G.menu = {}
    if Save.any() then G.menu[#G.menu + 1] = "CONTINUE" end
    G.menu[#G.menu + 1] = "NEW DELVE"
    G.menu[#G.menu + 1] = "WIPE SAVES"
    G.menuSel = math.min(G.menuSel or 1, #G.menu)
end

function Game.toTitle()
    Kit.setMode("title")
    G.menuSel = 1
    Game.buildMenu()
    Music.set(Sfx.WINDLASS)
end

local function menuUpdate()
    if Kit.mode == "title" then
        if Input.upEdge then
            G.menuSel = (G.menuSel - 2) % #G.menu + 1
        elseif Input.downEdge then
            G.menuSel = G.menuSel % #G.menu + 1
        end
        if Input.aEdge then
            local label = G.menu[G.menuSel]
            if label == "WIPE SAVES" then
                Save.wipe()
                Game.buildMenu()
                Harness.count("wipes")
            else
                G.menuAct = label
                G.slotSel = Save.any() or 1
                Kit.setMode("slots")
            end
        end
        return
    end
    -- slot cards
    if Input.upEdge then
        G.slotSel = (G.slotSel - 2) % Save.SLOTS + 1
    elseif Input.downEdge then
        G.slotSel = G.slotSel % Save.SLOTS + 1
    end
    if Input.bEdge then
        Kit.setMode("title")
        return
    end
    if Input.aEdge then
        Save.use(G.slotSel)
        G.slot = G.slotSel
        G.newRun()
        if G.menuAct == "CONTINUE" and Save.load(G.slotSel) then
            G.depth = Save.get("depth", 1)
            G.cleared = Save.get("cleared", 0)
            G.deaths = Save.get("deaths", 0)
            G.runT = Save.get("runT", 0)
            G.flaresSpent = Save.get("spent", 0)
            G.lanternsLit = Save.get("lanterns", 0)
        else
            Save.reset{ name = "VESPER", place = "THE ADIT", pct = 0 }
        end
        Game.enterDepth(G.depth)
    end
end

-- ---- the tick --------------------------------------------------------------

function Game.update(dt)
    G.frame = G.frame + 1
    Music.update(dt)
    Kit.updateShake(dt)
    Kit.updateParts(G.parts, dt, 220, nil)
    Story.update(dt, Input.aEdge, false)

    if Kit.mode == "title" or Kit.mode == "slots" then
        menuUpdate()
        Light.begin(C.AMBIENT)
        Light.add(200, 176, 96, 0.45)
        Light.add(64, 96, 40, 0.35)
        return
    end
    if Kit.mode == "done" then
        Game.castLights()
        if Input.aEdge and Kit.modeT <= 0 then Game.toTitle() end
        return
    end
    -- a cutscene freezes the shaft but still lights it, so the scene
    -- plays over the room you are standing in
    if Story.active then
        Game.castLights()
        return
    end

    G.depthT = G.depthT + dt
    G.runT = G.runT + dt
    G.irisT = math.max(0, G.irisT - dt * 1.6)
    G.invuln = math.max(0, G.invuln - dt)
    G.hurtFlash = math.max(0, G.hurtFlash - dt)
    G.flareCd = math.max(0, G.flareCd - dt)
    G.ropeCd = math.max(0, (G.ropeCd or 0) - dt)

    if G.exitT then
        G.exitT = G.exitT - dt
        if G.exitT <= 0 then
            G.exitT = nil
            Game.enterDepth(G.depth + 1)
            return
        end
    end

    aim(dt)
    movePlayer(dt)
    local wet = G.onGround and Level.poolAt(G.L, G.px, G.py) ~= nil
    if wet and not G.wet then Harness.count("waded") end
    G.wet = wet
    Game.camera(dt)
    if G.lamp and G.oil > 0 then
        G.oil = math.max(0, G.oil - (G.wet and C.OIL_WET or C.OIL_BURN) * dt)
        if G.oil <= 0 then
            Sfx.snuff()
            Harness.count("lampOut")
        end
    end
    if Input.flare then Game.throwFlare() end
    Game.updateFlares(dt)
    Game.castLights()      -- after movement, before every Light.at query
    Game.updateMobs(dt)
    Game.updateFallers(dt)
    if G.boss and not G.boss.down then Game.updateBoss(dt) end
    Game.fixtures(dt)
end
