-- Echo controls: d-pad flies (up climbs), A calls, B backs out of a
-- menu, the crank is the throttle. That is the whole scheme -- a game
-- you play by ear cannot afford a busy pad.
--
-- The smoke autopilot below plays the campaign end to end. It cheats
-- in exactly one way, and it is the honest way: it reads the true
-- world (Cave.centerAt / halfAt / G.obs) instead of the remembered
-- one, because a bot that had to hear the cave would be testing my
-- memory model rather than the game. Everything else it does is
-- something a player does -- it picks a line through a 5x5 grid of
-- candidate lateral/altitude pairs plus any moth worth diverting for,
-- LATCHES that line for AP_LATCH frames so it cannot oscillate
-- between two gaps, calls on a human cadence (about every two
-- seconds, longer while the owl is listening), and menus by LABEL.

Input = {
    mx = 0, my = 0, crank = 0,
    a = false, b = false, up = false, down = false,
}

local pd = playdate
local clamp = Util.clamp
local abs, min, max = math.abs, math.min, math.max

-- ---- autopilot state (module-local, never reallocated) ------------------

local latch = 0        -- frames the current line is held
local tx, ty = 0, 32   -- the latched line
local pingT = 0        -- s until the next call
local menuT = 0        -- frames until the next menu keypress
local prey = nil       -- the moth this plan is committed to ...
local preyId = 0       -- ... and its serial, so a recycled table
                       --     cannot be mistaken for it

local candX, candY = {}, {}
local nCand = 0

-- ---- reading the cave ---------------------------------------------------

-- would a bat sitting at (x, y) be hit by o? Cave.blocks is the same
-- predicate the simulation kills you with, asked with clearance.
local function hits(o, x, y, margin)
    if abs(Cave.obsX(o) - x) >= Cave.widthOf(o) + margin then
        return false
    end
    return Cave.blocks(o, y, 3)
end

-- distance to the nearest thing that would hit the CURRENT line
local function nearestThreat(pz)
    local obs = G.obs
    local best = 1e9
    for i = 1, #obs do
        local o = obs[i]
        if o.kind ~= "moth" then
            local dz = o.z - pz
            if dz > 4 and dz < best and hits(o, G.px, G.py, 2) then
                best = dz
            end
        end
    end
    return best
end

-- is lateral position x inside the tube at world z? Asked at the z
-- that matters (where the moth is, where the aim point is) and NOT
-- along the whole path: the corridor meanders, and a bat is expected
-- to meander with it. Testing a fixed x at every z in between rejects
-- almost every reachable target -- that mistake cost this autopilot
-- most of its dinner before it was found.
local function insideAt(x, z)
    return abs(x - Cave.centerAt(z)) <= Cave.limitAt(z) - 5
end

-- ---- hunting -------------------------------------------------------------
-- Moths are the whole economy: every one is another two calls. The
-- bot commits to ONE and holds the intercept until it is eaten,
-- passed, or blocked -- re-deciding every frame is how a bot ends a
-- cavern hungry, having chased six moths and caught none.

local preyX, preyY = 0, 32 -- where the committed moth WILL be

local function pickPrey(pz)
    local obs = G.obs
    local best, bd = nil, 1e9
    for i = 1, #obs do
        local o = obs[i]
        if o.kind == "moth" then
            local dz = o.z - pz
            if dz > 55 and dz < C.AP_MOTH_Z and dz < bd then
                local t = dz / max(60, G.spd)
                if insideAt(Cave.obsXAt(o, t), o.z) then
                    best, bd = o, dz
                end
            end
        end
    end
    return best
end

-- the commitment is to the MOTH, not to a straight line at it: the
-- line search below still runs every frame and still refuses to fly
-- into rock, it just weights everything toward the moth. A bot that
-- dropped its target the moment a stalagmite got in the way would
-- spend a cavern picking new targets and eat nothing.
local function trackPrey(pz)
    if prey and (prey.gone or prey.serial ~= preyId
            or prey.kind ~= "moth" or prey.z - pz < 6) then
        prey = nil
    end
    if not prey and G.scrapeT <= 0 then
        prey = pickPrey(pz)
        if prey then preyId = prey.serial end
    end
    if prey then
        local t = (prey.z - pz) / max(60, G.spd)
        preyX, preyY = Cave.obsXAt(prey, t), Cave.obsYAt(prey, t)
    end
end

-- ---- choosing a line ----------------------------------------------------

local FX <const> = { -0.80, -0.42, 0, 0.42, 0.80 }
local FY <const> = { 11, 21, 32, 43, 53 }
local NUDGE <const> = { 0, -22, 22 } -- lateral offsets around the prey

local function buildCandidates(pz)
    local aimZ = pz + C.AP_AIM
    local c = Cave.centerAt(aimZ)
    local h = Cave.limitAt(aimZ) - 6
    nCand = 0
    for i = 1, #FX do
        local x = c + FX[i] * h
        for j = 1, #FY do
            nCand = nCand + 1
            candX[nCand], candY[nCand] = x, FY[j]
        end
    end
    if nCand == 0 then -- pinched: aim dead centre and hope
        nCand = 1
        candX[1], candY[1] = c, C.MID
    end
    -- the committed moth's own intercept, plus two nudges either side
    -- of it so the search can slip past rock and still arrive fed
    if prey then
        for i = 1, #NUDGE do
            local x = preyX + NUDGE[i]
            if insideAt(x, prey.z) then
                nCand = nCand + 1
                candX[nCand], candY[nCand] = x, preyY
            end
        end
    end
end

-- lower is better: collisions dominate, then travel, then a mild pull
-- toward the middle of the tube and toward food
local function scoreLine(x, y, pz)
    local obs = G.obs
    local s = 0
    local spd = max(60, G.spd)
    local hunger = 1 - G.stam
    local mothWant = 240 + hunger * 420 + (G.owl.on and 320 or 0)
    for i = 1, #obs do
        local o = obs[i]
        local dz = o.z - pz
        if dz > 4 and dz < C.AP_LOOK then
            -- where the bat will actually BE when this one arrives:
            -- the near obstacles are met in transit, not at the
            -- target, and testing the target instead is how a bot
            -- clips the stalagmite it was already climbing over
            local t = dz / spd
            local xa = G.px + clamp(x - G.px, -C.XSPD * t, C.XSPD * t)
            local ya = G.py + clamp(y - G.py, -C.YSPD * t, C.YSPD * t)
            if o.kind == "moth" then
                if abs(Cave.obsX(o) - xa) < C.MOTH_W - 4
                    and abs(Cave.obsY(o) - ya) < C.MOTH_H - 3 then
                    s = s - mothWant / (1 + dz * 0.004)
                end
            elseif hits(o, xa, ya, 7) then
                -- rock always outbids food: the flat 2000 keeps any
                -- colliding line above any clear one, and the 1/dz
                -- term ranks the unavoidable ones by how soon
                s = s + 2000 + 60000 / (dz + 45)
            end
        end
    end
    -- a smooth pull toward the committed moth, so even a line that
    -- cannot quite reach it drifts that way and the next frame can
    if prey then
        s = s - 1100 / (1 + abs(x - preyX) * 0.07 + abs(y - preyY) * 0.09)
    end
    s = s + abs(x - G.px) * 0.55 + abs(y - G.py) * 0.42
    s = s + abs(x - Cave.centerAt(pz + C.AP_AIM)) * 0.16
    -- the wind pushes you off a line you cannot hold
    if G.wind ~= 0 then s = s + abs(G.wind) * 0.02 end
    return s
end

local function chooseLine(pz)
    buildCandidates(pz)
    local bestS, bx, by = 1e18, candX[1], candY[1]
    for i = 1, nCand do
        local s = scoreLine(candX[i], candY[i], pz)
        if s < bestS then
            bestS, bx, by = s, candX[i], candY[i]
        end
    end
    tx, ty = bx, by
end

-- ---- menus, by label -----------------------------------------------------

local function press()
    if menuT > 0 then
        menuT = menuT - 1
        return false
    end
    menuT = C.AP_MENU
    return true
end

local function menuBot()
    local m = Kit.mode
    if m == "title" then
        Input.a = press()
    elseif m == "slots" then
        -- the label the cards draw for slot n; walk to it, then take it
        local want = "Slot 1"
        if ("Slot " .. G.slotSel) ~= want then
            if press() then Input.down = true end
        else
            Input.a = press()
        end
    elseif m == "map" then
        -- always head for the deepest cavern the save has unlocked,
        -- found by NAME, never by row number
        local wantName = C.CAVERNS[clamp(Game.unlocked(), 1, C.NCAV)].name
        local wantI = Game.cavIndexByName(wantName)
        if G.mapSel < wantI then
            if press() then Input.down = true end
        elseif G.mapSel > wantI then
            if press() then Input.up = true end
        else
            Input.a = press()
        end
    elseif m == "clear" or m == "fail" then
        if Kit.modeT <= 0 then Input.a = press() end
    end
    -- "end": the campaign is over; the bot stops pressing buttons so
    -- the final heartbeat stays put
end

-- ---- flying ---------------------------------------------------------------

local function flyBot()
    local pz = Game.playerZ()

    -- throttle: cruise flat, but outrun the owl when it is listening
    local wantTrim = G.owl.on and C.TRIM_HI or 1.0
    Input.crank = clamp((wantTrim - G.trim) / C.TRIM_GAIN, -30, 30)

    -- call cadence: a human rhythm, tightened when something close is
    -- unmapped, stretched in the hunt (every call is a lure)
    local threat = nearestThreat(pz)
    pingT = pingT - C.DT
    local gap = C.AP_PING
    if G.owl.on then gap = gap * 1.5 end
    if threat < 320 then gap = C.AP_PING_LOW end
    if pingT <= 0 and G.pingCD <= 0 and G.stam >= C.PING_COST then
        Input.a = true
        pingT = gap
    end

    -- the committed hunt, if there is one
    trackPrey(pz)

    -- re-plan on the latch, at once if the held line is now unsafe,
    -- and every frame while a moth is being chased (the moth moves)
    latch = latch - 1
    if latch <= 0 or prey or threat < 130 or G.scrapeT > 0.2 then
        chooseLine(pz)
        latch = C.AP_LATCH
    end

    if tx > G.px + 3 then
        Input.mx = 1
    elseif tx < G.px - 3 then
        Input.mx = -1
    end
    if ty > G.py + 2.5 then
        Input.my = 1
    elseif ty < G.py - 2.5 then
        Input.my = -1
    end
    -- hold station against the gust rather than letting it walk you
    if Input.mx == 0 and abs(G.wind) > 14 then
        Input.mx = G.wind > 0 and -1 or 1
    end
end

local function autopilot()
    Input.mx, Input.my, Input.crank = 0, 0, 0
    Input.a, Input.b = false, false
    Input.up, Input.down = false, false
    if Story.active then
        return -- smoke builds auto-advance dialogue after 1.6s
    end
    if Kit.mode == "play" then
        flyBot()
    else
        menuBot()
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
    if pd.buttonIsPressed(pd.kButtonUp) then Input.my = 1 end
    if pd.buttonIsPressed(pd.kButtonDown) then Input.my = -1 end
    Input.up = pd.buttonJustPressed(pd.kButtonUp)
    Input.down = pd.buttonJustPressed(pd.kButtonDown)
    Input.a = pd.buttonJustPressed(pd.kButtonA)
    Input.b = pd.buttonJustPressed(pd.kButtonB)
    Input.crank = pd.getCrankChange()
end
