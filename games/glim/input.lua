-- Glim controls: d-pad walks the keeper, the crank trims the wick,
-- B pulses the lantern, A starts. The smoke autopilot herds the
-- nearest firefly into the lantern, leads it to the jar (pausing when
-- it lags), keeps the wick trimmed to mid and pulses at lit moths.

Input = { mx = 0, my = 0, crank = 0, pulse = false, start = false }

local pd = playdate
local clamp = Util.clamp

local function nearestFly()
    local best, bd = nil, 1e9
    for i = 1, #G.flies do
        local f = G.flies[i]
        local dx, dy = f.x - G.px, f.y - G.py
        local d = dx * dx + dy * dy
        if d < bd then best, bd = f, d end
    end
    return best, math.sqrt(bd)
end

local function autopilot()
    Input.mx, Input.my, Input.crank = 0, 0, 0
    Input.pulse, Input.start = false, false
    if Kit.mode ~= "play" then
        Input.start = (G.frame % 40 == 0)
        return
    end
    -- keep the lantern trimmed to the middle of its range
    local mid = (C.RMIN + C.RMAX) / 2
    Input.crank = clamp((mid - G.radius) / C.CRANK_GAIN, -20, 20)
    -- herd: walk at the nearest firefly; once it is inside the
    -- lantern, lead it to the jar, pausing whenever it falls behind
    local f, d = nearestFly()
    local tx, ty = 200, 170
    if f then
        if d < G.radius * 0.8 then
            tx, ty = C.JARX, C.JARY - 10
            if d > G.radius * 0.55 then tx, ty = G.px, G.py end
        else
            tx, ty = f.x, f.y
        end
    end
    local dx, dy = tx - G.px, ty - G.py
    if dx > 4 then Input.mx = 1 elseif dx < -4 then Input.mx = -1 end
    if dy > 4 then Input.my = 1 elseif dy < -4 then Input.my = -1 end
    -- every 15 s the keeper drowses for 4 s: no pulsing, drifting
    -- toward the nearest moth so one can land -- this exercises the
    -- mothHits counter alongside the happy path
    if (G.nightT % 15) < 4 then
        local bm, bd = nil, 1e9
        for i = 1, #G.moths do
            local m = G.moths[i]
            local dx, dy = m.x - G.px, m.y - G.py
            local d = dx * dx + dy * dy
            if d < bd then bm, bd = m, d end
        end
        if bm then
            Input.mx = (bm.x > G.px + 4) and 1
                or (bm.x < G.px - 4) and -1 or 0
            Input.my = (bm.y > G.py + 4) and 1
                or (bm.y < G.py - 4) and -1 or 0
        end
        return
    end
    for i = 1, #G.moths do
        local m = G.moths[i]
        local mx, my = m.x - G.px, m.y - G.py
        if mx * mx + my * my < 34 * 34 and m.fleeT <= 0
            and Light.at(m.x, m.y) > 0 then
            Input.pulse = true
        end
    end
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
    Input.crank = pd.getCrankChange()
    Input.pulse = pd.buttonJustPressed(pd.kButtonB)
    Input.start = pd.buttonJustPressed(pd.kButtonA)
end
