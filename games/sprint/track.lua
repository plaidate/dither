-- Track geometry. One of the eight generated TrackN / TrackNMask pairs is
-- made active by Track.load(idx). The gate midpoints are the racing line: a
-- closed polyline giving arc-length progress (laps + standings) and the drone
-- path; the mask gives wall collision. All in PySprint's logical 640x400 space.

Track = {}

local sqrt <const> = math.sqrt
local floor <const> = math.floor

-- collect the generated globals (imported before this module)
local DATA, MASK = {}, {}
for i = 1, 8 do
    DATA[i] = _G["Track" .. i]
    MASK[i] = _G["Track" .. i .. "Mask"]
end
Track.count = 8

-- name + difficulty of a track without making it active (for the menu)
function Track.meta(idx)
    local d = DATA[idx]
    return d.name, d.difficulty
end

-- active-track state, (re)built by Track.load
local seg = {}      -- segment table for the racing line
local n = 0
local rows, D, MW, MH = nil, 2, 0, 0

function Track.load(idx)
    local data = DATA[idx]
    local mask = MASK[idx]
    Track.idx = idx
    Track.start = data.start
    Track.finishRect = data.finishRect
    Track.name = data.name

    -- racing-line waypoints = gate midpoints
    local wp = {}
    for i, g in ipairs(data.gates) do
        wp[i] = { x = (g.ex + g.ix) / 2, y = (g.ey + g.iy) / 2 }
    end
    n = #wp
    Track.n = n

    seg = {}
    local cum = 0
    for i = 1, n do
        local a, b = wp[i], wp[i % n + 1]
        local dx, dy = b.x - a.x, b.y - a.y
        local len = sqrt(dx * dx + dy * dy)
        seg[i] = { ax = a.x, ay = a.y, ux = dx / len, uy = dy / len, len = len, cum = cum }
        cum = cum + len
    end
    Track.L = cum

    rows = mask.rows
    D, MW, MH = mask.D, mask.W, mask.H
end

-- nearest point on the racing line: s, distance, nearest point, tangent
function Track.project(px, py)
    local bestD2, bestS, bx, by, bux, buy = 1e18, 0, 0, 0, 1, 0
    for i = 1, n do
        local s = seg[i]
        local t = ((px - s.ax) * s.ux + (py - s.ay) * s.uy)
        if t < 0 then t = 0 elseif t > s.len then t = s.len end
        local cx, cy = s.ax + s.ux * t, s.ay + s.uy * t
        local dx, dy = px - cx, py - cy
        local d2 = dx * dx + dy * dy
        if d2 < bestD2 then
            bestD2, bestS, bx, by, bux, buy = d2, s.cum + t, cx, cy, s.ux, s.uy
        end
    end
    return bestS, sqrt(bestD2), bx, by, bux, buy
end

-- like project, but only considers segments within `window` arc-length of
-- sHint. The track folds past its own infield (opposite sides of the road are
-- close in space but far apart in s); a global nearest search snaps progress
-- across the infield wall, so we keep it local.
function Track.projectNear(px, py, sHint, window)
    sHint = sHint % Track.L
    local bestD2, bestS, bx, by, bux, buy = 1e18, sHint, px, py, 1, 0
    for i = 1, n do
        local sg = seg[i]
        local mid = sg.cum + sg.len * 0.5
        local dd = math.abs(mid - sHint)
        if dd > Track.L - dd then dd = Track.L - dd end -- cyclic distance
        if dd <= window then
            local t = ((px - sg.ax) * sg.ux + (py - sg.ay) * sg.uy)
            if t < 0 then t = 0 elseif t > sg.len then t = sg.len end
            local cx, cy = sg.ax + sg.ux * t, sg.ay + sg.uy * t
            local ex, ey = px - cx, py - cy
            local d2 = ex * ex + ey * ey
            if d2 < bestD2 then
                bestD2, bestS, bx, by, bux, buy = d2, sg.cum + t, cx, cy, sg.ux, sg.uy
            end
        end
    end
    return bestS, sqrt(bestD2), bx, by, bux, buy
end

-- point + tangent at arc-length s (wraps)
function Track.pointAt(s)
    s = s % Track.L
    if s < 0 then s = s + Track.L end
    for i = 1, n do
        local sg = seg[i]
        if s >= sg.cum and s < sg.cum + sg.len then
            local t = s - sg.cum
            return sg.ax + sg.ux * t, sg.ay + sg.uy * t, sg.ux, sg.uy
        end
    end
    local sg = seg[n]
    return sg.ax, sg.ay, sg.ux, sg.uy
end

-- is the logical point on drivable road? (out of bounds = wall)
function Track.onTrack(lx, ly)
    local gx = floor(lx / D) + 1
    local gy = floor(ly / D) + 1
    if gx < 1 or gx > MW or gy < 1 or gy > MH then return false end
    return rows[gy]:byte(gx) == 35 -- '#'
end
