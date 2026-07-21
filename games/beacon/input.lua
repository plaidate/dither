-- Beacon controls. The crank IS the lighthouse: getCrankChange comes
-- in as a signed radian delta on Input.beam and Game.optics applies it
-- to the beam's bearing. Up/Down work the shutter (fine <-> wide), A
-- is the lens surge, B the fog horn; in menus the same buttons pick
-- and confirm.
--
-- THE AUTOPILOT SEAM: the headless stub returns 0 for getCrankChange,
-- so the bot cannot "turn the crank" -- it writes Input.beam directly,
-- in radians, through the exact field the crank feeds. Everything
-- downstream (wind, clamping, priming the dead lamp) is therefore
-- identical for a player and for the bot; there is no autopilot-only
-- path through the optics.

Input = {
    beam = 0,      -- signed radians to turn the beam THIS frame
    spread = 0,    -- -1 draw fine, +1 open wide, 0 hold
    flash = false, -- A: the lens surge (and the strike, when relighting)
    horn = false,  -- B: the fog horn
    a = false, b = false, up = false, down = false, -- menu edges
}

local pd = playdate
local clamp = Util.clamp
local abs, min, max = math.abs, math.min, math.max
local atan, sin, cos, pi = math.atan, math.sin, math.cos, math.pi
local sqrt = math.sqrt

local DEG2RAD <const> = pi / 180

-- ---- the bot -------------------------------------------------------------
-- One latched target at a time. Re-deciding every frame makes a beam
-- that oscillates between two hulls and turns neither, so a choice
-- sticks for AP_LATCH seconds unless something clearly worse turns up.

local AP = {
    tgt = nil,        -- the entity table
    seq = 0,          -- its identity, so a recycled pool slot is caught
    mode = "none",    -- ship | lifeboat | wrecker
    t = 0,            -- latch countdown
    aimT = 0,         -- seconds aimed at it and still finding it dark
    sweep = 1,        -- ping-pong direction for the idle sweep
    tap = 0,
}

local function wrap(a)
    while a > pi do a = a - 2 * pi end
    while a < -pi do a = a + 2 * pi end
    return a
end

local function bearing(x, y)
    return atan(y - C.LY, x - C.LX)
end

local function dist(x, y)
    local dx, dy = x - C.LX, y - C.LY
    return sqrt(dx * dx + dy * dy)
end

-- seconds until this hull is on something hard, on her present course
local function trouble(s)
    local best = 99
    local vy = sin(s.hd) * s.spd
    if vy > 1 then best = (Game.shoreY(s.x) - s.y) / vy end
    for i = 1, G.nRocks do
        local r = G.rocks[i]
        local dx, dy = r.x - s.x, r.y - s.y
        local d = sqrt(dx * dx + dy * dy) - r.r - 4
        -- only rocks she is actually pointed at count
        if d < 90 and (cos(s.hd) * dx + sin(s.hd) * dy) > 0 then
            local t = d / max(1, s.spd)
            if t < best then best = t end
        end
    end
    return best
end

local function stillValid()
    local t = AP.tgt
    if not t or not t.used or t.seq ~= AP.seq then return false end
    if AP.mode == "wrecker" then return not t.out end
    if AP.mode == "ship" then return not t.warned end
    return true                       -- the lifeboat, until she is home
end

-- lower is more urgent
-- returns the chosen target, its urgency and its kind, plus a
-- fallback: the best target IGNORING the blind-sector penalty, so that
-- when every hull afloat is behind a glazing bar the beam still sits
-- on the worst of them instead of idling at the horizon
local function pick()
    local bt, bu, bm = nil, 1e9, "none"
    local ft, fu, fm = nil, 1e9, "none"
    local loose = 0                   -- hulls still needing a light
    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.used and s.kind ~= "lifeboat" and not s.warned then
            loose = loose + 1
        end
    end
    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.used then
            local u
            if s.kind == "lifeboat" then
                -- she waits her turn unless nothing else is in danger --
                -- but the longer she is out there in the dark with no
                -- light on her, the louder she gets
                u = (loose == 0) and 1.0
                    or max(1.8, 7.0 - (s.outT or 0) * 0.12)
            elseif not s.warned then
                u = trouble(s)
                -- a master who wants the core, or wants time, is slower
                -- to answer: start on him earlier
                if s.core then u = u - 1.6 end
                if s.dwellNeed > 0 then u = u - s.dwellNeed end
            end
            if u then
                local m = (s.kind == "lifeboat") and "lifeboat" or "ship"
                if u < fu then ft, fu, fm = s, u, m end
                if u < bu and (s.apBlind or 0) <= 0 then
                    bt, bu, bm = s, u, m
                end
            end
        end
    end
    for i = 1, 2 do
        local w = G.wreckers[i]
        if w.used and not w.out then
            local u = 8.0 - w.t * 2.2          -- finish what you started
            for j = 1, C.MAX_SHIPS do
                local s = G.ships[j]
                if s.used and not s.warned and s.kind ~= "lifeboat" then
                    local dx, dy = s.x - w.x, s.y - w.y
                    if dx * dx + dy * dy < (C.LURE_R * 1.4) ^ 2 then
                        u = u - 4.5                -- he is pulling one in
                    end
                end
            end
            if u < fu then ft, fu, fm = w, u, "wrecker" end
            if u < bu and (w.apBlind or 0) <= 0 then
                bt, bu, bm = w, u, "wrecker"
            end
        end
    end
    if not bt then return ft, fu, fm end
    return bt, bu, bm
end

local function play(dt)
    -- the storm has the lamp: crank it hard between the stops to bring
    -- the pressure up, then strike
    if G.lampOut then
        if G.dir >= C.DIR_MAX - 0.06 then AP.sweep = -1
        elseif G.dir <= C.DIR_MIN + 0.06 then AP.sweep = 1 end
        Input.beam = AP.sweep * C.AP_SLEW
        Input.flash = G.prime >= 1
        return
    end

    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.apBlind and s.apBlind > 0 then s.apBlind = s.apBlind - dt end
    end
    for i = 1, 2 do
        local w = G.wreckers[i]
        if w.apBlind and w.apBlind > 0 then w.apBlind = w.apBlind - dt end
    end

    AP.t = AP.t - dt
    local cand, cu, cm = pick()
    if not stillValid() then
        AP.tgt, AP.mode = nil, "none"
    end
    if cand and (not AP.tgt or (AP.t <= 0)
        or cu < (AP.cu or 1e9) - C.AP_EDGE) then
        if cand ~= AP.tgt then
            AP.tgt, AP.seq, AP.mode = cand, cand.seq, cm
            AP.aimT = 0
            AP.t = C.AP_LATCH
        end
        AP.cu = cu
    end

    -- the fog horn: somebody else is about to be on the reef and the
    -- beam cannot be in two places
    local worst = 99
    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.used and not s.warned and s.kind ~= "lifeboat" and s ~= AP.tgt then
            worst = min(worst, trouble(s))
        end
    end
    if worst < C.AP_HORN and G.hornCd <= 0 then Input.horn = true end

    local tx, ty = 200, C.SPAWN_Y
    local core = false
    if AP.tgt then
        tx, ty = AP.tgt.x, AP.tgt.y
        core = (AP.mode == "wrecker") or (AP.tgt.core == true)
    end

    local err = wrap(bearing(tx, ty) - G.dir)
    Input.beam = clamp(err, -C.AP_SLEW, C.AP_SLEW)

    -- shutter: the widest beam that still reaches, capped so the can
    -- lasts the night. Fine light is cheap light.
    local d = dist(tx, ty)
    if AP.tgt then
        local fogf = 1 - G.fog * C.FOG_BITE
        local need = d * (core and (1 / C.CORE) or 1) * 1.06
        local want = C.SPREAD_REF * (C.REACH * fogf / max(1, need)) ^ 2
        want = clamp(want, C.SPREAD_MIN, C.AP_SPREAD)
        if G.spread < want - 0.02 then Input.spread = 1
        elseif G.spread > want + 0.02 then Input.spread = -1 end
        -- the surge, when even a needle will not carry that far
        local carry = G.reach * (core and C.CORE or 1)
        if d > carry and G.flashCd <= 0 and G.oil > 26
            and (AP.cu or 99) < 6 then
            Input.flash = true
        end
    else
        Input.spread = -1              -- idle: draw fine, burn nothing
    end

    -- am I aimed at it and STILL not lighting it? Then it is inside a
    -- blind sector of the lantern; leave it and come back.
    if AP.tgt then
        local slack = max(0.05, G.spread * 0.35)
        if abs(err) < slack and d < G.reach and Light.at(tx, ty) <= 0 then
            AP.aimT = AP.aimT + dt
            if AP.aimT > C.AP_SHADOW then
                AP.tgt.apBlind = C.AP_BLIND
                AP.tgt, AP.mode, AP.aimT = nil, "none", 0
                Harness.count("blindSector")
            end
        else
            AP.aimT = 0
        end
    end
end

local function autopilot()
    local dt = C.DT
    Input.beam, Input.spread = 0, 0
    Input.flash, Input.horn = false, false
    Input.a, Input.b, Input.up, Input.down = false, false, false, false

    AP.tap = AP.tap + 1
    local tap = (AP.tap % C.AP_TAP) == 0

    if Story.active then
        Input.a = tap
        return
    end

    local m = Kit.mode
    if m == "play" then
        play(dt)
        return
    end

    -- everything else is menus: a slow idle sweep so the lamp is never
    -- dead on screen, and taps by LABEL, never by index
    if G.dir >= C.DIR_MAX - 0.1 then AP.sweep = -1
    elseif G.dir <= C.DIR_MIN + 0.1 then AP.sweep = 1 end
    Input.beam = AP.sweep * 0.02

    if m == "title" then
        local want = 1
        for i = 1, #G.menu do
            if G.menu[i] == "NEW WATCH" then want = i end
        end
        if G.sel ~= want then Input.down = tap else Input.a = tap end
    elseif m == "slots" then
        if G.slotSel ~= 1 then Input.down = tap else Input.a = tap end
    elseif m == "brief" or m == "result" then
        Input.a = tap
    end
    -- "done" is terminal: the bot stops pressing and the log book stands
end

Harness.autopilot = autopilot

function Input.poll()
    if Harness.enabled then
        autopilot()
        return
    end
    -- the crank turns the lens; left/right is the docked-crank fallback
    local dd = pd.getCrankChange() * DEG2RAD * C.CRANK_GAIN
    if pd.buttonIsPressed(pd.kButtonLeft) then dd = dd - C.KEY_SLEW * C.DT end
    if pd.buttonIsPressed(pd.kButtonRight) then dd = dd + C.KEY_SLEW * C.DT end
    Input.beam = dd
    Input.spread = 0
    if pd.buttonIsPressed(pd.kButtonUp) then Input.spread = -1 end
    if pd.buttonIsPressed(pd.kButtonDown) then Input.spread = 1 end
    Input.a = pd.buttonJustPressed(pd.kButtonA)
    Input.b = pd.buttonJustPressed(pd.kButtonB)
    Input.up = pd.buttonJustPressed(pd.kButtonUp)
    Input.down = pd.buttonJustPressed(pd.kButtonDown)
    Input.flash = Input.a
    Input.horn = Input.b
end
