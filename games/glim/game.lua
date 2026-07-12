-- Glim: the night simulation. Wick burn, firefly drift, moth stalks,
-- jarring, pulses, the difficulty ramp and the title/play/over state
-- machine. Light.at gates the moth AI: a moth outside every light
-- does not advance -- darkness is mechanics, not paint.

Game = {}

local clamp = Util.clamp
local rnd = math.random
local sqrt = math.sqrt

function Game.newFly()
    return {
        x = rnd(C.X0 + 10, C.X1 - 10),
        y = rnd(C.Y0 + 4, C.Y1 - 10),
        vx = 0, vy = 0, wt = 0,   -- wander velocity + re-pick timer
        blink = rnd() * 4,        -- glow blink phase
    }
end

function Game.newMoth()
    return {
        x = (rnd() < 0.5) and C.X0 + 4 or C.X1 - 4,
        y = rnd(C.Y0, C.Y1),
        fleeT = 0,                -- retreat time after a hit / pulse
        flap = rnd() * 4,         -- wingbeat phase
    }
end

local function startNight()
    G.reset()
    Kit.setMode("play")
    Sfx.start()
    Harness.count("nights")
end

local function endNight()
    G.newBest = Kit.saveBest(G.score)
    Kit.setMode("over", 0.8)
    Sfx.snuff()
end

-- per-frame Light pass: lantern + optional pulse flare + jar glow +
-- coalesced, capped firefly glows. Runs before the AI so Light.at
-- answers from this frame's sources.
local ax, ay = {}, {} -- reused scratch: this frame's firefly lights

local function castLights()
    Light.begin(C.AMBIENT)
    Light.add(G.px, G.py - 6, G.radius)
    if G.pulseT > 0 then
        Light.add(G.px, G.py - 6, C.PULSE_R, 0.7)
    end
    local jdx, jdy = G.px - C.JARX, G.py - C.JARY
    if jdx * jdx + jdy * jdy < C.JAR_NEAR * C.JAR_NEAR then
        Light.add(C.JARX, C.JARY - 6, C.JAR_GLOW)
    end
    local n, cc = 0, C.FLY_COALESCE * C.FLY_COALESCE
    for i = 1, #G.flies do
        local f = G.flies[i]
        local own = true
        for j = 1, n do
            local dx, dy = f.x - ax[j], f.y - ay[j]
            if dx * dx + dy * dy < cc then
                own = false
                break
            end
        end
        if own and n < C.FLY_LIGHTS then
            n = n + 1
            ax[n], ay[n] = f.x, f.y
            Light.add(f.x, f.y, C.FLY_R, 0.4)
        end
    end
end

local function scatterFlies()
    for i = 1, #G.flies do
        local f = G.flies[i]
        local dx, dy = f.x - G.px, f.y - G.py
        local d = sqrt(dx * dx + dy * dy)
        if d < C.SCATTER and d > 0 then
            f.vx, f.vy = dx / d * 70, dy / d * 70
            f.wt = 0.8
        end
    end
end

local function updateFlies(dt)
    for i = #G.flies, 1, -1 do
        local f = G.flies[i]
        f.wt = f.wt - dt
        if f.wt <= 0 then
            local a = rnd() * 6.283
            f.vx = math.cos(a) * C.FLY_SPD
            f.vy = math.sin(a) * C.FLY_SPD
            f.wt = 0.6 + rnd()
        end
        f.blink = (f.blink + dt) % 4
        local dx, dy = G.px - f.x, G.py - 6 - f.y
        local d = sqrt(dx * dx + dy * dy)
        if d < G.radius and d > 12 then -- drawn to the lantern
            f.x = f.x + dx / d * C.FLY_PULL * dt
            f.y = f.y + dy / d * C.FLY_PULL * dt
        end
        f.x = clamp(f.x + f.vx * dt, C.X0, C.X1)
        f.y = clamp(f.y + f.vy * dt, C.Y0 - 30, C.Y1)
        local jx, jy = f.x - C.JARX, f.y - (C.JARY - 6)
        if jx * jx + jy * jy < C.JAR_R * C.JAR_R then
            table.remove(G.flies, i)
            G.score = G.score + 1
            Sfx.chime()
            Kit.burst(G.parts, C.JARX, C.JARY - 8, 8, 60, 30)
            Harness.count("jarred")
        end
    end
end

local function updateMoths(dt)
    local want = math.min(C.MOTH_MAX,
        C.MOTH_MIN + math.floor(G.nightT / C.MOTH_EVERY))
    if #G.moths < want then
        G.moths[#G.moths + 1] = Game.newMoth()
    end
    local spd = C.MOTH_SPD0 + G.nightT * C.MOTH_RAMP
    for i = 1, #G.moths do
        local m = G.moths[i]
        m.flap = m.flap + dt * 10
        local dx, dy = G.px - m.x, G.py - 6 - m.y
        local d = sqrt(dx * dx + dy * dy)
        if m.fleeT > 0 then
            m.fleeT = m.fleeT - dt
            if d > 0 then
                m.x = m.x - dx / d * spd * 1.6 * dt
                m.y = m.y - dy / d * spd * 1.6 * dt
            end
        elseif Light.at(m.x, m.y) > 0 and d > 0 then
            -- lit: fly at the lantern (unlit moths stay frozen)
            m.x = m.x + dx / d * spd * dt
            m.y = m.y + dy / d * spd * dt
            if d < C.MOTH_HIT then
                G.wick = G.wick - C.MOTH_STEAL
                m.fleeT = C.MOTH_FLEE
                Kit.shake(0.25)
                Sfx.flutter()
                scatterFlies()
                Harness.count("mothHits")
            end
        end
        m.x = clamp(m.x, C.X0 - 6, C.X1 + 6)
        m.y = clamp(m.y, C.Y0 - 40, C.Y1 + 6)
    end
end

local function pulse()
    if G.pulseCd > 0 or G.wick <= C.PULSE_COST then return end
    G.wick = G.wick - C.PULSE_COST
    G.pulseT = C.PULSE_T
    G.pulseCd = C.PULSE_CD
    Sfx.pulse()
    Harness.count("pulses")
    for i = 1, #G.moths do
        local m = G.moths[i]
        local dx, dy = m.x - G.px, m.y - G.py
        if dx * dx + dy * dy < C.PULSE_R * C.PULSE_R then
            m.fleeT = C.MOTH_FLEE
        end
    end
end

function Game.update(dt)
    G.frame = G.frame + 1
    Music.update(dt)
    Kit.updateShake(dt)
    Kit.updateParts(G.parts, dt, 140, C.Y1)
    if Kit.mode == "title" then
        castLights()
        updateFlies(dt) -- garden lives behind the title panel
        if Input.start then startNight() end
        return
    end
    if Kit.mode == "over" then
        castLights()
        G.dissT = math.min(0.6, G.dissT + dt * 0.8)
        if Input.start and Kit.modeT <= 0 then
            Kit.setMode("title")
        end
        return
    end
    -- play
    G.nightT = G.nightT + dt
    G.irisT = math.max(0, G.irisT - dt * 1.4)
    G.pulseCd = math.max(0, G.pulseCd - dt)
    G.pulseT = math.max(0, G.pulseT - dt)
    G.px = clamp(G.px + Input.mx * C.WALK * dt, C.X0, C.X1)
    G.py = clamp(G.py + Input.my * C.WALK * dt, C.Y0, C.Y1)
    -- trim the wick: crank up = brighter = faster burn
    G.radius = clamp(G.radius + Input.crank * C.CRANK_GAIN,
        C.RMIN, C.RMAX)
    local t = (G.radius - C.RMIN) / (C.RMAX - C.RMIN)
    G.wick = G.wick - (C.BURN_BASE + C.BURN_K * t ^ 1.5) * dt
    if Input.pulse then pulse() end
    castLights() -- after movement, before the AI queries
    updateFlies(dt)
    updateMoths(dt)
    G.respT = G.respT - dt -- respawn slows as the night wears on
    if G.respT <= 0 then
        if #G.flies < C.FLY_CAP then
            G.flies[#G.flies + 1] = Game.newFly()
        end
        G.respT = C.RESP0 + G.nightT * C.RESP_RAMP
    end
    if G.wick < C.WARN_AT then -- guttering warning
        G.warnT = G.warnT - dt
        if G.warnT <= 0 then
            Sfx.warn()
            G.warnT = 2
        end
    end
    if G.wick <= 0 then
        G.wick = 0
        endNight()
    end
end
