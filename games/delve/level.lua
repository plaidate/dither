-- Delve: the shaft generator and every geometric query the rest of the
-- game asks. A depth is a stack of full-width rock slabs, one hole per
-- slab; everything else (lanterns, crates, pools, props, mobs) is
-- decoration hung off that spine.
--
-- Two exports matter.
--
-- L.route is an ORDERED list of waypoints from the spawn to the exit
-- hatch, one or more per slab the delver actually stands on: light the
-- lantern, loot the crate, leave by the hole. It exists so the
-- autopilot can LATCH onto a plan instead of re-deciding every frame
-- (house rule: a bot that re-decides oscillates and finishes nothing),
-- and so the HUD can say how far down a depth you are. Fixtures are
-- deliberately placed BETWEEN where you land on a floor and where you
-- leave it (L.arrive / L.leave), so following the route never requires
-- crossing the hole you are about to fall down.
--
-- Level.castWalls hands the same slabs to Light.wall as chunked
-- segments. That is the whole trick of the game: the floor you are
-- standing on is the thing that hides the floor you are about to land
-- on, and it is one object doing both jobs.

Level = {}

local rnd = math.random
local floor = math.floor
local abs = math.abs

-- world y of slab j's top surface (j = 0 is the roof over floor 1)
function Level.top(j)
    return C.TOP0 + (j - 1) * C.FLOOR_H
end

-- the slab a feet-y belongs to, rounded to the nearest slab top
function Level.floorOf(y)
    return floor((y - C.TOP0) / C.FLOOR_H + 0.5) + 1
end

-- ---- generation ------------------------------------------------------

-- holes zig-zag between the halves of the shaft so every floor is a
-- real traverse (~200px at C.RUN is about 2.5 seconds of walking blind)
local function placeHoles(L)
    local lo = C.WALLX + 16
    local hi = C.W - C.WALLX - 16 - C.HOLE_W
    local side = (rnd() < 0.5) and 1 or -1
    for j = 1, L.floors - 1 do
        if side > 0 then
            L.slabs[j].hx = rnd(floor(C.W * 0.55), hi)
        else
            L.slabs[j].hx = rnd(lo, floor(C.W * 0.28))
        end
        side = -side
    end
end

-- a rope hangs through TWO aligned holes, so the drop beneath it is a
-- floor and a half and taking it as a fall costs a grit
local function placeRopes(L, n)
    local used = {}
    local tries = 0
    while n > 0 and tries < 40 do
        tries = tries + 1
        local j = rnd(2, math.max(2, L.floors - 3))
        if not used[j] and not used[j - 1] and not used[j + 1]
            and j + 2 <= L.floors then
            used[j], used[j + 1] = true, true
            L.slabs[j].rope = true
            L.slabs[j + 1].hx = L.slabs[j].hx  -- align the two holes
            L.ropes[#L.ropes + 1] = {
                x = L.slabs[j].hx + C.HOLE_W / 2,
                -- the catchable span starts at the lip, not below the
                -- slab: you step off already moving and are past the
                -- slab's own thickness within three frames
                y0 = Level.top(j) + 2,
                y1 = Level.top(j + 2),
                j = j,
            }
            n = n - 1
        end
    end
end

-- the chain of slabs the delver actually stands on (a rope skips one)
local function walkChain(L)
    local chain, j = {}, 1
    while j <= L.floors do
        chain[#chain + 1] = j
        if j >= L.floors then break end
        j = L.slabs[j].rope and (j + 2) or (j + 1)
    end
    if chain[#chain] ~= L.floors then chain[#chain + 1] = L.floors end
    return chain
end

-- A free spot on floor j, ALWAYS on the same side of the hole as the
-- point you land on. This is not tidiness: a lantern on the far lip
-- would mean the only way to reach it is a running jump across the
-- drop you are about to take, from a standing start you may not have
-- the runway for. Preference order is (1) the stretch you already walk
-- between landing and the hole, (2) anywhere else on the landing side.
local function spanX(L, j, w, claimed)
    local a = L.arrive[j] or 200
    local s = L.slabs[j]
    local lo, hi
    if s.hx and j < L.floors then
        local h0, h1 = s.hx, s.hx + C.HOLE_W
        if a > h1 then
            lo, hi = h1 + w + 16, a - 6
            if hi - lo < 30 then hi = C.W - C.WALLX - 16 end
        else
            lo, hi = a + 6, h0 - w - 16
            if hi - lo < 30 then lo = C.WALLX + 16 end
        end
    else
        local b = L.leave[j] or a
        lo, hi = math.min(a, b) + 14, math.max(a, b) - 14
        if hi - lo < 30 then
            lo, hi = C.WALLX + 16, C.W - C.WALLX - 16
        end
    end
    if hi - lo < 22 then return nil end
    for _ = 1, 28 do
        local x = rnd(floor(lo), floor(hi))
        local ok = true
        if s.hx and x > s.hx - w - 20
            and x < s.hx + C.HOLE_W + w + 20 then
            ok = false
        end
        if ok and claimed then
            for i = 1, #claimed do
                if abs(x - claimed[i]) < w + 24 then ok = false break end
            end
        end
        if ok then
            if claimed then claimed[#claimed + 1] = x end
            return x
        end
    end
    return nil
end

-- anywhere on floor j that is actually floor (mobs do not care which
-- side of the hole they wander)
local function solidX(L, j)
    for _ = 1, 20 do
        local x = rnd(C.WALLX + 16, C.W - C.WALLX - 16)
        if Level.colSolid(L, j, x, 10) then return x end
    end
    return C.WALLX + 20
end

-- n floors picked evenly out of chain[from..to], no repeats
local function spread(chain, n, from, to)
    local out = {}
    local span = to - from
    if span < 0 or n <= 0 then return out end
    for i = 1, n do
        local k = from + floor(span * (i - 0.5) / n + 0.5)
        local j = chain[math.max(from, math.min(to, k))]
        local dup = false
        for q = 1, #out do if out[q] == j then dup = true end end
        if not dup then out[#out + 1] = j end
    end
    return out
end

function Level.build(depth)
    local spec = C.DEPTHS[depth]
    local L = {
        depth = depth, spec = spec,
        floors = spec.floors,
        slabs = {}, ropes = {}, rocks = {}, rocksBy = {},
        lanterns = {}, crates = {}, pools = {}, glows = {},
        mobs = {}, fallers = {}, route = {},
        arrive = {}, leave = {},
    }
    L.h = Level.top(L.floors) + C.SLAB + C.BOTTOM_PAD
    for j = 0, L.floors do
        L.slabs[j] = { y = Level.top(j), hx = nil, rope = false }
        L.rocksBy[j] = {}
    end
    placeHoles(L)
    if (spec.ropes or 0) > 0 then placeRopes(L, spec.ropes) end

    local chain = walkChain(L)
    L.chain = chain

    -- spawn on the far side of the first hole so floor 1 is a walk
    L.spawnX = C.WALLX + 26
    if L.slabs[1].hx and L.slabs[1].hx < C.W / 2 then
        L.spawnX = C.W - C.WALLX - 26
    end
    -- Walk the chain fixing where you land on each floor and where you
    -- leave it. If a floor's hole would sit right under where you
    -- land, shove it to the far half: every floor should be a real
    -- traverse, and you should never arrive standing on the lip of the
    -- next drop with no runway either side of it.
    local lo = C.WALLX + 16
    local hi = C.W - C.WALLX - 16 - C.HOLE_W
    for k = 1, #chain do
        local j = chain[k]
        L.arrive[j] = (k == 1) and L.spawnX or L.leave[chain[k - 1]]
        local s = L.slabs[j]
        if j < L.floors and s.hx then
            if abs(s.hx + C.HOLE_W / 2 - L.arrive[j]) < 74 then
                local nhx = (L.arrive[j] < C.W / 2)
                    and rnd(floor(C.W * 0.55), hi)
                    or rnd(lo, floor(C.W * 0.28))
                s.hx = nhx
                if s.rope then      -- a rope's two holes stay aligned
                    L.slabs[j + 1].hx = nhx
                    for i = 1, #L.ropes do
                        if L.ropes[i].j == j then
                            L.ropes[i].x = nhx + C.HOLE_W / 2
                        end
                    end
                end
            end
            L.leave[j] = s.hx + C.HOLE_W / 2
        end
    end
    -- the hatch out, on the far side of the last landing
    L.exitX = ((L.arrive[L.floors] or L.spawnX) > C.W / 2)
        and (C.WALLX + 32) or (C.W - C.WALLX - 32)
    L.leave[L.floors] = L.exitX
    L.exitY = Level.top(L.floors)

    -- the spawn and the hatch are claimed before anything else is
    -- placed: a rock prop dropped on top of the spawn point boxes the
    -- delver in on every side, jump included, and the depth is
    -- unfinishable from frame one
    local claim = {}
    for _, j in ipairs(chain) do
        claim[j] = { L.arrive[j] or 200 }
    end
    claim[L.floors][#claim[L.floors] + 1] = L.exitX

    -- lanterns: checkpoint, oil, flares and a save, all at once. Never
    -- on floor 1 -- the spawn is already a checkpoint.
    for _, j in ipairs(spread(chain, spec.lanterns or 2, 2, #chain)) do
        local x = spanX(L, j, 12, claim[j])
        if x then
            L.lanterns[#L.lanterns + 1] =
                { x = x, y = Level.top(j), j = j, lit = false, ph = 0 }
        end
    end
    -- flare crates, restocked on a timer so a depth can never dry out
    for _, j in ipairs(spread(chain, spec.crates or 1, 2, #chain)) do
        local x = spanX(L, j, 10, claim[j])
        if x then
            L.crates[#L.crates + 1] =
                { x = x, y = Level.top(j), j = j, t = 0 }
        end
    end
    -- glowworm seams: the only light the mine gives away free, and the
    -- real darkness dial (Light quantizes any ambient < 0.5 to black)
    for _ = 1, (spec.glows or 0) do
        local j = chain[rnd(1, #chain)]
        L.glows[#L.glows + 1] = {
            x = rnd(C.WALLX + 14, C.W - C.WALLX - 14),
            y = Level.top(j) - 22 - rnd(0, 16), j = j,
            ph = rnd() * 6.283,
        }
    end
    -- standing water: snuffs a flare the instant it lands, wets the
    -- wick, and slows a wade to a crawl
    for _, j in ipairs(spread(chain, spec.pools or 0, 2, #chain)) do
        local w = rnd(58, 108)
        local x = spanX(L, j, w / 2, nil)
        if x then
            L.pools[#L.pools + 1] =
                { x0 = x - w / 2, x1 = x + w / 2, y = Level.top(j), j = j }
        end
    end
    -- fallen rock: solid props you hop, and Light.box occluders that
    -- throw a real shadow down the drift
    for _ = 1, (spec.rocks or 0) do
        local j = chain[rnd(1, #chain)]
        local w = rnd(16, 26)
        local x = spanX(L, j, w / 2 + 6, claim[j])
        if x then
            local h = rnd(12, 18)
            local base = Level.top(j)
            local r = { x0 = x - w / 2, x1 = x + w / 2,
                        top = base - h, base = base, j = j }
            L.rocks[#L.rocks + 1] = r
            local rl = L.rocksBy[j]
            rl[#rl + 1] = r
        end
    end
    -- rigged roofs
    for _, j in ipairs(spread(chain, spec.fallers or 0, 2, #chain)) do
        local x = spanX(L, j, 8, nil)
        if x then
            L.fallers[#L.fallers + 1] = {
                x = x, j = j, base = Level.top(j),
                ceil = Level.top(j) - C.FLOOR_H + C.SLAB + 4,
                state = "wait", t = 0.6 + rnd() * C.FALL_EVERY, y = nil,
            }
        end
    end
    -- the dark things
    local spd = (C.CRAWL_SPD + (depth - 1) * C.CRAWL_RAMP)
        * (spec.mobSpd or 1)
    local first = math.min(2, #chain)
    for _ = 1, (spec.crawlers or 0) do
        local j = chain[rnd(first, #chain)]
        L.mobs[#L.mobs + 1] = {
            kind = "crawler",
            x = solidX(L, j), y = Level.top(j), j = j,
            dir = (rnd() < 0.5) and 1 or -1, spd = spd,
            lit = 0, litT = 0, bite = 0, step = rnd() * 6.283,
            hang = false, vy = 0,
        }
    end
    for _ = 1, (spec.clingers or 0) do
        local j = chain[rnd(first, #chain)]
        L.mobs[#L.mobs + 1] = {
            kind = "clinger",
            x = solidX(L, j),
            y = Level.top(j) - C.FLOOR_H + C.SLAB + 12, j = j,
            dir = 1, spd = spd,
            lit = 0, litT = 0, bite = 0, step = rnd() * 6.283,
            hang = true, vy = 0,
        }
    end

    -- Belt and braces on the worst hazard this generator has: a solid
    -- prop straddling the point you land on boxes the delver in on
    -- every side -- jump included, because the prop is as tall as the
    -- headroom over it -- and the depth becomes unfinishable the
    -- instant you arrive. Nothing solid may overlap an arrival point.
    for i = #L.rocks, 1, -1 do
        local r = L.rocks[i]
        local a = L.arrive[r.j]
        if a and a + 9 > r.x0 and a - 9 < r.x1 then
            table.remove(L.rocks, i)
            local rl = L.rocksBy[r.j]
            for q = #rl, 1, -1 do
                if rl[q] == r then table.remove(rl, q) end
            end
        end
    end

    Level.buildRoute(L)
    return L
end

-- ---- the route -------------------------------------------------------

function Level.buildRoute(L)
    local function wp(kind, x, j, ref)
        L.route[#L.route + 1] = { kind = kind, x = x, j = j, ref = ref }
    end
    for _, j in ipairs(L.chain) do
        for i = 1, #L.lanterns do
            if L.lanterns[i].j == j then
                wp("lantern", L.lanterns[i].x, j, L.lanterns[i])
            end
        end
        for i = 1, #L.crates do
            if L.crates[i].j == j then
                wp("crate", L.crates[i].x, j, L.crates[i])
            end
        end
        if j >= L.floors then
            wp("exit", L.exitX, j)
        elseif L.slabs[j].rope then
            for i = 1, #L.ropes do
                if L.ropes[i].j == j then
                    wp("rope", L.ropes[i].x, j, L.ropes[i])
                end
            end
        else
            wp("hole", L.slabs[j].hx + C.HOLE_W / 2, j)
        end
    end
end

-- ---- queries ---------------------------------------------------------

-- is slab j solid across the column [x-hw, x+hw]?
function Level.colSolid(L, j, x, hw)
    if j < 0 or j > L.floors then return false end
    local s = L.slabs[j]
    if not s then return false end
    if s.hx and x - hw >= s.hx and x + hw <= s.hx + C.HOLE_W then
        return false
    end
    return true
end

-- does the box (feet at x, y; hw half-width; h tall) hit rock?
function Level.solidBox(L, x, y, hw, h)
    if x - hw < C.WALLX or x + hw > C.W - C.WALLX then return true end
    local top = y - h
    local j0 = floor((top - C.TOP0) / C.FLOOR_H)
    for j = j0, j0 + 2 do
        if j >= 0 and j <= L.floors then
            local sy = Level.top(j)
            if y > sy and top < sy + C.SLAB
                and Level.colSolid(L, j, x, hw) then
                return true
            end
            local rl = L.rocksBy[j]
            for i = 1, #rl do
                local r = rl[i]
                if x + hw > r.x0 and x - hw < r.x1
                    and y > r.top and top < r.base then
                    return true
                end
            end
        end
    end
    return false
end

-- the highest surface between y0 and y1 that stops a falling box, else
-- nil. Slabs are the common case; rock props are checked too.
function Level.landY(L, x, y0, y1, hw)
    local best = nil
    local j0 = floor((y0 - C.TOP0) / C.FLOOR_H) - 1
    for j = j0, j0 + 3 do
        if j >= 0 and j <= L.floors then
            local sy = Level.top(j)
            if sy >= y0 - 0.01 and sy <= y1
                and Level.colSolid(L, j, x, hw)
                and (not best or sy < best) then
                best = sy
            end
            local rl = L.rocksBy[j]
            for i = 1, #rl do
                local r = rl[i]
                if x + hw > r.x0 and x - hw < r.x1
                    and r.top >= y0 - 0.01 and r.top <= y1
                    and (not best or r.top < best) then
                    best = r.top
                end
            end
        end
    end
    return best
end

-- the pool covering (x, y), or nil. Pools sit on a slab's surface.
function Level.poolAt(L, x, y)
    for i = 1, #L.pools do
        local p = L.pools[i]
        if x > p.x0 and x < p.x1 and y > p.y - 14 and y < p.y + 8 then
            return p
        end
    end
    return nil
end

-- ---- the occluder pass ------------------------------------------------
-- Register the slabs around the delver with Light.wall, cut into
-- WALL_CHUNK pieces. The chunking is not cosmetic: light.lua only
-- carves a wall's shadow when one of the segment's ENDPOINTS falls
-- inside that light's reach, so one 376px segment would be silently
-- skipped by the compositor while Light.at still honoured it -- pixels
-- and logic would disagree. Nearest slabs go first so that when the
-- 64-wall cap bites, it bites the far ones.

local function emitRow(sy, hx, x0, x1)
    if hx then
        local h0, h1 = hx, hx + C.HOLE_W
        if h1 <= x0 or h0 >= x1 then
            Light.wall(x0, sy, x1, sy)
        else
            if h0 - x0 > 3 then Light.wall(x0, sy, h0, sy) end
            if x1 - h1 > 3 then Light.wall(h1, sy, x1, sy) end
        end
    else
        Light.wall(x0, sy, x1, sy)
    end
end

local ORDER <const> = { 1, 0, -1, 2 }   -- below, own, above, further

function Level.castWalls(L, pj, camy)
    for oi = 1, #ORDER do
        local j = pj + ORDER[oi]
        if j >= 0 and j <= L.floors then
            local sy = Level.top(j) - camy
            if sy > -30 and sy < C.H + 30 then
                local hx = L.slabs[j].hx
                local x = C.WALLX
                while x < C.W - C.WALLX do
                    local x2 = math.min(x + C.WALL_CHUNK, C.W - C.WALLX)
                    emitRow(sy, hx, x, x2)
                    x = x2
                end
            end
        end
    end
    local n = 0
    for j = pj - 1, pj + 1 do
        local rl = L.rocksBy[j]
        if rl then
            for i = 1, #rl do
                if n >= C.OCC_ROCKS then return end
                local r = rl[i]
                Light.box(r.x0, r.top - camy, r.x1 - r.x0, r.base - r.top)
                n = n + 1
            end
        end
    end
end
