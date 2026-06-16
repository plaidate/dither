-- Controls: the crank is the wheel, A the throttle, B the brake (d-pad
-- left/right is a full-lock fallback). Also defines the smoke-test autopilot.

Input = {}

local clamp = Util.clamp

-- shortest signed delta on the 16-unit angle wheel (unclamped)
local function shortDelta(t)
    t = t % 16
    if t > 8 then t = t - 16 elseif t < -8 then t = t + 16 end
    return t
end

-- Tangent-following controller: steer toward the racing-line direction at the
-- car, plus a bounded cross-track pull back onto the line. Unlike aiming at a
-- lookahead point, this does not oscillate through hairpins (where the target
-- point swings to the far leg). It brakes for the curvature just ahead.
local function tangentAngAt(s)
    local _, _, ux, uy = Track.pointAt(s)
    return Game.angOf(ux, uy)
end

local function autopilot()
    local p = G.player
    if not p or not p.ux then return 0, true, false, true end
    local tangentAng = Game.angOf(p.ux, p.uy)
    -- signed distance off the line; the correction term must be strong enough
    -- to peel the car off a wall, so it's proportional and only mild near the
    -- line (small e) but large when far off (clamped).
    local e = (p.x - p.cx) * (-p.uy) + (p.y - p.cy) * p.ux
    local corr = clamp(-e * 0.14, -4, 4)
    local turn = clamp(shortDelta(tangentAng + corr - p.ang), -C.MAX_TURN, C.MAX_TURN)

    -- hold a target speed: crawl the bend ahead, run the straights. Sampled
    -- over a range so it brakes before and all through the corner. Always > 0.
    local bend = math.max(
        math.abs(shortDelta(tangentAngAt(p.s + 25) - tangentAng)),
        math.abs(shortDelta(tangentAngAt(p.s + 55) - tangentAng)))
    local target = (bend > 0.9) and 1.9 or 5.0
    local accel = p.speed < target
    local brake = p.speed > target + 1.0
    return turn, accel, brake, true
end

-- returns: turn (angle units), accel, brake, start
function Input.gather()
    if Harness.enabled then return autopilot() end

    local turn = playdate.getCrankChange() / 22.5 * C.CRANK_GAIN
    if playdate.buttonIsPressed(playdate.kButtonLeft) then turn = turn - C.ROT_STEP end
    if playdate.buttonIsPressed(playdate.kButtonRight) then turn = turn + C.ROT_STEP end
    turn = clamp(turn, -C.MAX_TURN, C.MAX_TURN)

    local accel = playdate.buttonIsPressed(playdate.kButtonA)
    local brake = playdate.buttonIsPressed(playdate.kButtonB)
    local start = playdate.buttonJustPressed(playdate.kButtonA)
        or playdate.buttonJustPressed(playdate.kButtonB)
    return turn, accel, brake, start
end
