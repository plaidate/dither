-- Skimmer: the pond simulation. The camera streams forward over the
-- water; obstacle rows spawn ahead on the depth queue and collide the
-- frame their z crosses the player plane. Reeds are dodged laterally,
-- lily pads only bite when you fly low, midge clusters are points
-- (times the crank trim). Three dunks end the flight.

Game = {}

local clamp = Util.clamp
local rnd = math.random
local floor = math.floor
local min, max = math.min, math.max

-- midges bob in their lane; draw and collision share this x
function Game.obsX(o)
    if o.ph then return o.x + math.sin(G.time * 2.2 + o.ph) * 8 end
    return o.x
end

local function addObs(kind, x, y, z, ph)
    G.obs[#G.obs + 1] = { kind = kind, x = x, y = y, z = z, ph = ph }
end

-- one row every ROW_DZ units: reeds (never in the safe lane, which
-- random-walks) or a lily rank, plus the odd midge cluster
local function spawnRow(z)
    G.safe = clamp(G.safe + rnd(-1, 1), -3, 3)
    if rnd() < C.LILY_P then
        for _ = 1, rnd(2, 3) do
            addObs("lily", rnd(-3, 3) * C.LANE + rnd(-10, 10), 0, z)
        end
    else
        local n = 1 + min(3, floor(G.dist / C.REED_RAMP))
        local used = { [G.safe] = true }
        for _ = 1, n * 3 do
            local lane = rnd(-3, 3)
            if not used[lane] then
                used[lane] = true
                addObs("reed", lane * C.LANE + rnd(-8, 8), 0, z)
                n = n - 1
                if n == 0 then break end
            end
        end
    end
    if rnd() < C.MIDGE_P then
        addObs("midge", rnd(-3, 3) * C.LANE + rnd(-12, 12),
            rnd(8, 32), z + rnd(0, 40), rnd() * 6.28)
    end
end

-- advance the pond: camera forward + lateral follow, spawn ahead,
-- prune what has flown past
local function stream(dt, spd)
    local cam = Scaler.cam
    cam.z = cam.z + spd * dt
    cam.x = G.px * C.CAMX
    while G.nextRowZ < cam.z + C.AHEAD do
        spawnRow(G.nextRowZ)
        G.nextRowZ = G.nextRowZ + C.ROW_DZ
    end
    for i = #G.obs, 1, -1 do
        -- gone once safely past the player plane: scale = f/dz
        -- explodes toward the camera (a passed lily became a
        -- screen-filling blob). Cull 16 units BEHIND the plane --
        -- this loop runs before crossings(), so the crossing frame
        -- must still see the obstacle (max speed ~12 units/frame).
        if G.obs[i].z < cam.z + C.PZ - 16 then
            table.remove(G.obs, i)
        end
    end
end

local function splash()
    local sx = Scaler.project(G.px, 0, Scaler.cam.z + C.PZ)
    Kit.burst(G.parts, sx, 228, 12, 90, 60)
end

local function dunk()
    G.lives = G.lives - 1
    G.invulnT = C.INVULN
    Kit.shake(0.3)
    Sfx.dunk()
    splash()
    Harness.count("dunks")
    if G.lives <= 0 then
        G.newBest = Kit.saveBest(G.score)
        G.dist = 0 -- attract mode restarts the reed ramp
        Kit.setMode("over", 0.9)
        Sfx.over()
    end
end

-- everything whose z crossed the player plane this frame
local function crossings(pzPrev, pz)
    for i = #G.obs, 1, -1 do
        local o = G.obs[i]
        if o.z > pzPrev and o.z <= pz then
            local dx = math.abs(Game.obsX(o) - G.px)
            if o.kind == "midge" then
                if dx < C.MIDGE_W
                    and math.abs(o.y - G.py) < C.MIDGE_H then
                    G.score = G.score
                        + floor(C.CATCH_PTS * G.trim + 0.5)
                    table.remove(G.obs, i)
                    Sfx.catch()
                    Harness.count("catches")
                end
            elseif G.invulnT <= 0 then
                if (o.kind == "reed" and dx < C.REED_W
                        and G.py < C.REED_H)
                    or (o.kind == "lily" and dx < C.LILY_W
                        and G.py < C.LILY_H) then
                    dunk()
                end
            end
        end
    end
end

function Game.start()
    if Harness.enabled then -- smoke rotation: dusk, day, dusk, ...
        G.todSel = 2 - G.runs % 2
    end
    G.runs = G.runs + 1
    G.tod = G.todSel
    G.ambient = C.TOD_AMBIENT[G.tod]
    G.startRun()
    Kit.setMode("play")
    Sfx.start()
    Harness.count("runs")
    Harness.count(C.TOD_NAMES[G.tod]:lower() .. "Runs")
end

function Game.update(dt)
    G.frame = G.frame + 1
    G.time = G.time + dt
    Music.update(dt)
    Kit.updateShake(dt)
    Kit.updateParts(G.parts, dt, 240, 231)
    G.curve = math.sin(G.time * C.CURVE_HZ) * C.CURVE_AMP
    local m = Kit.mode
    if m == "title" then
        stream(dt, C.SPD0 * 0.8)
        if Input.tod then
            G.todSel = G.todSel % 2 + 1
            G.tod = G.todSel
            G.ambient = C.TOD_AMBIENT[G.tod]
            Sfx.tick()
        end
        if Input.start then Game.start() end
        return
    elseif m == "over" then
        stream(dt, C.SPD0 * 0.6)
        G.dissT = min(0.55, G.dissT + dt * 0.9)
        if Input.start and Kit.modeT <= 0 then
            Kit.setMode("title")
        end
        return
    end
    -- play
    G.runT = G.runT + dt
    G.wipeT = max(0, G.wipeT - dt * 1.6)
    G.invulnT = max(0, G.invulnT - dt)
    G.trim = clamp(G.trim + Input.crank * C.TRIM_GAIN,
        C.TRIM_LO, C.TRIM_HI)
    G.px = clamp(G.px + Input.mx * C.XSPD * dt, -C.PX, C.PX)
    G.py = clamp(G.py + Input.my * C.YSPD * dt, C.PY_LO, C.PY_HI)
    G.spd = (C.SPD0 + min(C.RAMP_MAX, G.runT * C.RAMP)) * G.trim
    local pzPrev = Scaler.cam.z + C.PZ
    stream(dt, G.spd)
    G.dist = Scaler.cam.z - G.z0
    crossings(pzPrev, Scaler.cam.z + C.PZ)
    Harness.set("distance", floor(G.dist))
end
