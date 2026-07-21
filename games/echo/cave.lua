-- Echo: the cave itself. Two pure functions of world z -- centreline
-- and half-width -- define the whole tube, so the renderer's
-- cross-sections, the collision clamp and the autopilot's corridor
-- search all read the SAME rock. Nothing here holds state except the
-- obstacle pool and the safe-lane random walk.
--
-- Obstacle kinds:
--   tite    hangs from the ceiling; its tip is at CAVEH - len
--   mite    stands on the floor; its tip is at len
--   pillar  floor to ceiling; only a lateral gap saves you
--   moth    food: stamina, and (in the hunt) a burst of speed
-- Every one is a pooled table -- see G.free.

Cave = {}

local rnd = math.random
local sin = math.sin
local max, min = math.max, math.min
local clamp = Util.clamp

-- ---- the tube -------------------------------------------------------

-- lateral centre of the tunnel at world z
function Cave.centerAt(z)
    local cv = G.cav
    return cv.mnd * sin(z * cv.mhz)
        + cv.mnd * 0.42 * sin(z * cv.mhz * 2.3 + 1.1)
end

-- half-width of the tunnel at world z: a base squeeze plus, in the
-- later caverns, sharp pinches (sin^4 spikes) you have to be lined up
-- for before you can see them
function Cave.halfAt(z)
    local cv = G.cav
    local h = cv.half - cv.sqz * (0.5 + 0.5 * sin(z * cv.shz + 0.7))
    if cv.pinch > 0 then
        local p = sin(z * cv.phz)
        if p > 0 then
            local p2 = p * p
            h = h - cv.pinch * p2 * p2
        end
    end
    if h < C.MIN_HALF then h = C.MIN_HALF end
    return h
end

-- the widest lateral position that is still inside the rock at z
function Cave.limitAt(z)
    return Cave.halfAt(z) - C.BAT_HW
end

-- ---- the obstacle pool ------------------------------------------------

function Cave.clear()
    local obs, free = G.obs, G.free
    for i = #obs, 1, -1 do
        free[#free + 1] = obs[i]
        obs[i] = nil
    end
end

local function take()
    local n = #G.free
    if n > 0 then
        local o = G.free[n]
        G.free[n] = nil
        return o
    end
    return {}
end

-- every spawned obstacle gets a serial, so a plan that latched onto
-- one can tell it apart from the recycled table that replaced it
local serial = 0

local function add(kind, x, y, z, size)
    local o = take()
    serial = serial + 1
    o.serial = serial
    o.kind, o.x, o.y, o.z, o.size = kind, x, y, z, size or 1
    o.mem = 0        -- how well this thing is remembered, 0..1
    o.ph = rnd() * 6.28
    o.drop = 0       -- how far a cracked stalactite has fallen
    o.falling = false
    o.gone = false
    G.obs[#G.obs + 1] = o
    return o
end

-- swap-remove: the depth queue sorts every frame anyway, so obstacle
-- order carries no meaning and the last entry can fill the hole. Safe
-- to call while iterating BACKWARDS (the entry moved down has already
-- been visited).
local function drop(i)
    local obs = G.obs
    local o = obs[i]
    o.gone = true
    G.free[#G.free + 1] = o
    obs[i] = obs[#obs]
    obs[#obs] = nil
end

Cave.dropAt = drop

-- moths bob in place; draw and collision must share this x
function Cave.obsX(o)
    if o.kind == "moth" then
        return o.x + sin(G.time * 2.0 + o.ph) * 9
    end
    return o.x
end

function Cave.obsY(o)
    if o.kind == "moth" then
        return o.y + sin(G.time * 1.4 + o.ph * 1.7) * 6
    end
    return o.y
end

-- where the bob WILL be in t seconds. An intercept aimed at where a
-- moth is now arrives where the moth is not; the autopilot leads it.
function Cave.obsXAt(o, t)
    if o.kind == "moth" then
        return o.x + sin((G.time + t) * 2.0 + o.ph) * 9
    end
    return o.x
end

function Cave.obsYAt(o, t)
    if o.kind == "moth" then
        return o.y + sin((G.time + t) * 1.4 + o.ph * 1.7) * 6
    end
    return o.y
end

-- the top of a stalagmite / the tip of a stalactite, world y
function Cave.tipY(o)
    if o.kind == "tite" then
        return max(0, C.CAVEH - C.LEN[o.size] - o.drop)
    elseif o.kind == "mite" then
        return C.LEN[o.size]
    end
    return C.CAVEH
end

-- ---- the collision predicate --------------------------------------------
-- ONE definition of "is this rock in my way", used by the simulation
-- (pad 0) and by the autopilot (pad > 0, so it plans with clearance).
-- A stalactite that has finished falling is a boulder on the floor and
-- must be flown OVER, not under -- if the two callers disagreed about
-- that, the bot would fly a line the game then killed it for.

function Cave.widthOf(o)
    local k = o.kind
    if k == "tite" then return C.TITE_W end
    if k == "mite" then return C.MITE_W end
    return C.PILLAR_W
end

function Cave.landed(o)
    return o.kind == "tite" and o.drop >= C.CAVEH - C.LEN[o.size] - 0.5
end

function Cave.blocks(o, y, pad)
    pad = pad or 0
    local k = o.kind
    if k == "pillar" then return true end
    if k == "tite" and not Cave.landed(o) then
        return y + C.BAT_HH + pad > Cave.tipY(o)
    end
    local tip = Cave.landed(o) and C.LEN[o.size] or Cave.tipY(o)
    return y - C.BAT_HH - pad < tip
end

-- ---- spawning ----------------------------------------------------------
-- One row every cv.dens units. The safe lane random-walks across the
-- tunnel and nothing solid is placed within SAFE_W of it, so every
-- cavern is flyable -- being unable to SEE the lane is the game, being
-- unable to FIT through it is not.

local function pickKind(cv)
    local w = cv.w
    local total = w.tite + w.mite + w.pillar
    local r = rnd() * total
    if r < w.tite then return "tite" end
    if r < w.tite + w.mite then return "mite" end
    return "pillar"
end

local function spawnRow(z)
    local cv = G.cav
    local c, h = Cave.centerAt(z), Cave.halfAt(z)
    G.safe = clamp(G.safe + (rnd() - 0.5) * 0.7, -1, 1)
    local lane = c + G.safe * max(0, h - C.SAFE_M)
    local n = 1 + (rnd() < 0.55 and 1 or 0) + (rnd() < 0.22 and 1 or 0)
    for _ = 1, n do
        for _ = 1, 5 do -- a few tries to land clear of the safe lane
            local x = c + (rnd() * 2 - 1) * (h - 12)
            if math.abs(x - lane) > C.SAFE_W then
                local kind = pickKind(cv)
                local size = rnd(1, 3)
                if kind == "pillar" then size = 1 end
                add(kind, x, 0, z + rnd(-18, 18), size)
                break
            end
        end
    end
    if rnd() < cv.moth * C.MOTH_RATE then
        -- moths sit ON or near the lane: food is where the way is
        local mx = clamp(lane + (rnd() - 0.5) * 60,
            c - h + 20, c + h - 20)
        add("moth", mx, rnd(12, C.CAVEH - 12), z + rnd(-30, 30))
    end
end

-- stream the cave: spawn ahead of the camera, cull behind the plane
function Cave.stream()
    local camz = Scaler.cam.z
    while G.nextRowZ < camz + C.AHEAD do
        spawnRow(G.nextRowZ)
        G.nextRowZ = G.nextRowZ + G.cav.dens
    end
    local cull = camz + C.PZ - C.BEHIND
    for i = #G.obs, 1, -1 do
        if G.obs[i].z < cull then drop(i) end
    end
end

-- remove one obstacle by identity (a moth that has been eaten)
function Cave.remove(o)
    for i = #G.obs, 1, -1 do
        if G.obs[i] == o then
            drop(i)
            return
        end
    end
end
