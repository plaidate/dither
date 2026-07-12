-- Skimmer controls: the d-pad flies the dragonfly (up = climb), the
-- crank trims the throttle, A starts, B toggles day/dusk on the
-- title. The smoke autopilot weaves between reed lanes by reading
-- the upcoming depth queue, dips for midges, and past a grace period
-- deliberately misjudges lily height so both endings get exercised.

Input = { mx = 0, my = 0, crank = 0, start = false, tod = false }

local pd = playdate
local clamp = Util.clamp
local abs = math.abs

-- a lateral column is blocked if a reed (or, when aiming low, a
-- lily) sits inside the reaction window past the player plane
local function blocked(x, low, pz)
    for i = 1, #G.obs do
        local o = G.obs[i]
        local dz = o.z - pz
        if dz > 8 and dz < C.AP_LOOK then
            if o.kind == "reed" and abs(o.x - x) < C.AP_MARGIN then
                return true
            end
            if low and o.kind == "lily"
                and abs(o.x - x) < C.AP_MARGIN + 8 then
                return true
            end
        end
    end
    return false
end

-- nearest clear column, searching outward one lane at a time
local function clearLaneNear(x, pz)
    for d = 0, 3 do
        for s = -1, 1, 2 do
            local lx = clamp(x + s * d * C.LANE, -C.PX, C.PX)
            if not blocked(lx, false, pz) then return lx end
        end
    end
    return x
end

local function autopilot()
    Input.mx, Input.my, Input.crank = 0, 0, 0
    Input.start, Input.tod = false, false
    if Kit.mode ~= "play" then
        Input.start = (G.frame % 40 == 0)
        return
    end
    Input.crank = clamp((C.AP_TRIM - G.trim) / C.TRIM_GAIN, -25, 25)
    -- the scripted misjudgement: hold a deck-level line with frozen
    -- steering; lilies and reeds bite, and with the speed ramp and
    -- three lives a game over lands well inside smoke time
    if G.runT > C.AP_GRACE
        and G.frame % C.AP_BLUNDER < C.AP_OOPS then
        if G.py > 7 then Input.my = -1 end
        return
    end
    local pz = Scaler.cam.z + C.PZ
    -- dip for the nearest reachable midge cluster, else cruise
    local tx, ty, bd = G.px, C.AP_CRUISE, 1e9
    for i = 1, #G.obs do
        local o = G.obs[i]
        if o.kind == "midge" then
            local dz = o.z - pz
            if dz > 20 and dz < C.AP_LOOK and dz < bd then
                local mx = Game.obsX(o)
                if not blocked(mx, o.y < C.LILY_H + 4, pz) then
                    tx, ty, bd = mx, o.y, dz
                end
            end
        end
    end
    -- weave: if the aimed column is blocked, take the nearest gap
    if blocked(tx, ty < C.LILY_H + 4, pz) then
        tx = clearLaneNear(G.px, pz)
        if ty < C.AP_CRUISE then ty = C.AP_CRUISE end
    end
    if tx > G.px + 5 then Input.mx = 1
    elseif tx < G.px - 5 then Input.mx = -1 end
    if ty > G.py + 3 then Input.my = 1
    elseif ty < G.py - 3 then Input.my = -1 end
end

function Input.poll()
    if Harness.enabled then
        autopilot()
        return
    end
    Input.mx, Input.my = 0, 0
    if pd.buttonIsPressed(pd.kButtonLeft) then Input.mx = -1 end
    if pd.buttonIsPressed(pd.kButtonRight) then Input.mx = 1 end
    if pd.buttonIsPressed(pd.kButtonUp) then Input.my = 1 end
    if pd.buttonIsPressed(pd.kButtonDown) then Input.my = -1 end
    Input.crank = pd.getCrankChange()
    Input.start = pd.buttonJustPressed(pd.kButtonA)
    Input.tod = pd.buttonJustPressed(pd.kButtonB)
end
