-- Beacon: the simulation. The lamp is one Light.cone whose bearing is
-- the crank and whose length is the shutter fighting the fog; the
-- lantern room's glazing bars are two Light.walls that carve fixed
-- blind sectors out of the bay. Every hull out there steers on
-- Light.at(ship) -- unlit, a master holds his course onto the rock;
-- lit, he puts his helm over, and how fast he answers is exactly how
-- bright you have him. Darkness is not paint here either.
--
-- Also: the campaign state machine (title -> slots -> brief -> play ->
-- result -> done), the ten nights out of nights.lua, and the save.

Game = {}

local gfx = playdate.graphics
local clamp = Util.clamp
local rnd = math.random
local cos, sin, atan = math.cos, math.sin, math.atan
local sqrt, abs, pi = math.sqrt, math.abs, math.pi
local floor, min, max = math.floor, math.min, math.max

-- ---- the bay ------------------------------------------------------------
-- One fixed shore profile, sampled every 8px and built at import: a
-- wide V of land with the light on the point of it, so the ONLY way
-- out of the bay is seaward, past the horizon. Ships cannot be saved
-- by wandering off the side of the screen.

local SN <const> = 50
local SHORE = {}
for i = 0, SN do
    local x = i * 8
    local t = (x - 200) / 200
    SHORE[i] = 198 - 142 * t ^ 4
        + 5 * sin(x * 0.21) + 3 * sin(x * 0.07 + 1.3)
end

-- the land silhouette as one pooled fillPolygon coordinate run
Game.landPoly = {}
do
    local p = Game.landPoly
    p[1], p[2] = 0, 244
    local n = 2
    for i = 0, SN do
        p[n + 1] = i * 8
        p[n + 2] = SHORE[i]
        n = n + 2
    end
    p[n + 1], p[n + 2] = 400, 244
    Game.landN = n + 2
end

-- y of the waterline under x (linear between samples)
function Game.shoreY(x)
    if x <= 0 then return SHORE[0] end
    if x >= 400 then return SHORE[SN] end
    local f = x / 8
    local i = floor(f)
    return SHORE[i] + (SHORE[i + 1] - SHORE[i]) * (f - i)
end

-- ---- light --------------------------------------------------------------

-- Per-frame Light pass. Order matters: the compositor carves each
-- light's shadows right after that light, so the SHADOW CASTER (our
-- beam, the only thing the glazing bars can occlude) is added LAST --
-- see the caveat at the top of core/light.lua.
function Game.castLights()
    Light.begin(C.AMBIENT)
    -- the lantern room's glazing bars: two short segments a few px off
    -- the filament, each throwing a fixed ~18-degree blind sector
    for i = 1, #C.AST_A do
        local a = C.AST_A[i]
        local cx, cy = C.LX + cos(a) * C.AST_R, C.LY + sin(a) * C.AST_R
        local px, py = -sin(a) * C.AST_L * 0.5, cos(a) * C.AST_L * 0.5
        Light.wall(cx - px, cy - py, cx + px, cy + py)
    end
    -- the wreckers' false lights are real lights; they burn first
    for i = 1, 2 do
        local w = G.wreckers[i]
        if w.used and not w.out then
            Light.add(w.x, w.y - 3, C.WRECK_R, 0.3)
        end
    end
    if not G.lampOut then
        Light.cone(C.LX, C.LY, G.reach, G.dir, G.spread, C.CORE)
    end
end

-- YOUR beam only, same wedge/occluder math Light.at uses. Ships steer
-- on Light.at (any light, including a wrecker's); dousing a wrecker
-- has to know it is your light on him and not his own, so it asks
-- this instead.
function Game.beamAt(x, y)
    if G.lampOut then return 0 end
    local dx, dy = x - C.LX, y - C.LY
    local d2 = dx * dx + dy * dy
    local r = G.reach
    if d2 > r * r then return 0 end
    local a = atan(dy, dx) - G.dir
    while a > pi do a = a - 2 * pi end
    while a < -pi do a = a + 2 * pi end
    if abs(a) > G.spread * 0.5 then return 0 end
    if Light.blocked(C.LX, C.LY, x, y) then return 0 end
    local rc = r * C.CORE
    return (d2 <= rc * rc) and 1 or 0.5
end

-- ---- rocks, wreckers, the harbour ----------------------------------------

function Game.rockHit(x, y)
    for i = 1, G.nRocks do
        local r = G.rocks[i]
        local dx, dy = x - r.x, y - r.y
        local rr = r.r + 3
        if dx * dx + dy * dy < rr * rr then return r end
    end
    return nil
end

function Game.nearestRock(x, y, within)
    local best, bd = nil, within * within
    for i = 1, G.nRocks do
        local r = G.rocks[i]
        local dx, dy = x - r.x, y - r.y
        local d = dx * dx + dy * dy
        if d < bd then best, bd = r, d end
    end
    return best
end

function Game.nearestLure(x, y)
    local best, bd = nil, C.LURE_R * C.LURE_R
    for i = 1, 2 do
        local w = G.wreckers[i]
        if w.used and not w.out then
            local dx, dy = x - w.x, y - w.y
            local d = dx * dx + dy * dy
            if d < bd then best, bd = w, d end
        end
    end
    return best
end

-- ---- ships ---------------------------------------------------------------

local function freeShip()
    for i = 1, C.MAX_SHIPS do
        if not G.ships[i].used then return G.ships[i] end
    end
    return nil
end

-- shortest-arc turn of `hd` toward `want`, at most `step` radians
local function steer(hd, want, step)
    local d = want - hd
    while d > pi do d = d - 2 * pi end
    while d < -pi do d = d + 2 * pi end
    if d > step then d = step elseif d < -step then d = -step end
    return hd + d
end

function Game.spawn(kind, x)
    local s = freeShip()
    if not s then return nil end
    local k = C.KINDS[kind]
    s.used, s.kind = true, kind
    s.spd, s.len, s.turn = k.spd, k.len, k.turn
    s.core, s.dwellNeed = k.core, k.dwell
    s.dwell, s.dark, s.lit = 0, 0, 0
    s.warned, s.hove, s.sink, s.hold = false, 0, 0, 0
    s.lured = false
    s.outT = 0
    G.seq = G.seq + 1
    s.seq = G.seq
    if kind == "lifeboat" then
        s.x, s.y = C.HARB_X, C.HARB_Y
        s.hd, s.mode = -pi / 2, "out"
        Harness.count("launches")
    else
        s.x, s.y = x, C.SPAWN_Y
        s.mode = "run"
        -- bow down-channel, always with a lateral component so no hull
        -- can sit still inside a blind sector all the way to the rock
        local a = 0.34 + rnd() * (C.SPAWN_HD - 0.34)
        if rnd() < 0.5 then a = -a end
        if s.x < 150 then a = -abs(a) elseif s.x > 250 then a = abs(a) end
        s.hd = pi / 2 + a
    end
    G.nShips = G.nShips + 1
    return s
end

-- where a master WOULD steer if he could see: offshore, nudged off the
-- bay walls and around the nearest reef
function Game.safeHeading(s)
    local ax = 0
    if s.x < C.BAY_L then
        ax = ax + C.WALL_PUSH * (C.BAY_L - s.x) / C.BAY_L
    elseif s.x > C.BAY_R then
        ax = ax - C.WALL_PUSH * (s.x - C.BAY_R) / (400 - C.BAY_R)
    end
    local r = Game.nearestRock(s.x, s.y, C.ROCK_AVOID)
    if r then
        ax = ax + ((s.x >= r.x) and C.ROCK_PUSH or -C.ROCK_PUSH)
    end
    return -pi / 2 + clamp(ax, -0.9, 0.9)
end

local function stoodOff(s)
    s.used = false
    G.saved = G.saved + 1
    G.totalSaved = G.totalSaved + 1
    Harness.count("saved")
    Sfx.stood()
    Music.sting{ 76, 79, 83 }
end

local function wreckShip(s, how)
    s.used = false
    G.lost = G.lost + 1
    G.totalLost = G.totalLost + 1
    Harness.count("wrecked")
    Harness.count(how == "rock" and "onRock" or "onShore")
    Kit.shake(0.45)
    Kit.burst(G.parts, s.x, s.y, 14, 110, 26)
    Sfx.wreck()
    Music.sting{ 48, 47, 45 }
    if G.lost > (G.spec.allow or 1) then Game.endNight("wreck") end
end

-- one merchantman. This is the whole thesis in twenty lines: `lit` is
-- Light.at at her position, and `lit` IS the rudder.
local function runShip(s, dt)
    s.lit = Light.at(s.x, s.y)
    local eff = s.lit
    if s.core and eff < 1 then eff = 0 end  -- deep hulls want the core
    if s.dwellNeed > 0 then                 -- ... and a collier wants time
        if s.lit > 0 then
            s.dwell = s.dwell + dt * s.lit
            s.dark = 0
        else
            s.dark = s.dark + dt
            if s.dark > C.DWELL_DROP then s.dwell = 0 end
        end
        if s.dwell < s.dwellNeed then eff = 0 end
    end
    if s.warned then
        -- she has her bearings now and holds the corrected course
        s.hd = steer(s.hd, Game.safeHeading(s), C.TURN_LOST * dt)
    elseif eff > 0 then
        s.hd = steer(s.hd, Game.safeHeading(s), s.turn * eff * dt)
        if sin(s.hd) < C.WARN_SIN then
            s.warned = true
            Sfx.turn()
            Harness.count("turned")
        end
    else
        local w = Game.nearestLure(s.x, s.y)
        if w then                           -- a false light has her
            s.hd = steer(s.hd, atan(w.y - s.y, w.x - s.x), C.LURE_RATE * dt)
            if not s.lured then
                s.lured = true
                Harness.count("lured")
            end
        end
    end
    local sp = s.spd
    if s.hove > 0 then
        s.hove = s.hove - dt
        sp = sp * C.HORN_SLOW
    end
    s.x = s.x + cos(s.hd) * sp * dt
    s.y = s.y + sin(s.hd) * sp * dt
    if s.y < C.OFFSHORE or s.x < 3 or s.x > 397 then
        stoodOff(s)
    elseif Game.rockHit(s.x, s.y) then
        wreckShip(s, "rock")
    elseif s.y >= Game.shoreY(s.x) - 2 then
        wreckShip(s, "shore")
    end
end

-- the rescue: she pulls only while you hold her lit, out to the
-- casualty, alongside for LB_HOLD seconds, then home
local function runLifeboat(s, dt)
    s.lit = Light.at(s.x, s.y)
    s.outT = s.outT + dt
    local tx, ty = G.lbx, G.lby
    if s.mode == "home" then tx, ty = C.HARB_X, C.HARB_Y end
    if s.mode == "hold" then
        if s.lit > 0 then
            s.hold = s.hold + dt * s.lit
            if s.hold >= C.LB_HOLD then
                s.mode = "home"
                Harness.count("aboard")
                Music.sting{ 72, 76 }
            end
        end
        return
    end
    -- she has way on even in the dark -- the crew keep pulling, they
    -- just cannot see -- so a blind sector can never strand her. Light
    -- is the difference between a crawl and a pull.
    local eff = max(C.LB_DRIFT, s.lit)
    s.hd = steer(s.hd, atan(ty - s.y, tx - s.x), s.turn * dt * eff)
    local sp = s.spd * eff
    s.x = s.x + cos(s.hd) * sp * dt
    s.y = s.y + sin(s.hd) * sp * dt
    local dx, dy = tx - s.x, ty - s.y
    if dx * dx + dy * dy < 121 then
        if s.mode == "out" then
            s.mode, s.hold = "hold", 0
        else
            s.used = false
            G.rescued = true
            G.totalRescues = G.totalRescues + 1
            Harness.count("rescues")
            Sfx.stood()
            Music.sting{ 79, 84, 88 }
        end
    end
end

local function updateShips(dt)
    for i = 1, C.MAX_SHIPS do
        local s = G.ships[i]
        if s.used then
            if s.kind == "lifeboat" then runLifeboat(s, dt)
            else runShip(s, dt) end
        end
    end
end

local function updateWreckers(dt)
    for i = 1, 2 do
        local w = G.wreckers[i]
        if w.used and not w.out then
            w.flick = w.flick + dt
            local b = Game.beamAt(w.x, w.y)
            if b > 0 then
                -- the core smothers it fastest; the fringe still works
                w.t = w.t + dt * (b >= 1 and 1.8 or 1)
            else
                w.t = max(0, w.t - dt * C.DOUSE_DECAY)
            end
            if w.t >= C.DOUSE_T then
                w.out = true
                G.totalDoused = G.totalDoused + 1
                Harness.count("doused")
                Kit.burst(G.parts, w.x, w.y - 4, 10, 70, 34)
                Sfx.douse()
                Music.sting{ 60, 55, 48 }
            end
        end
    end
end

-- ---- the optics ------------------------------------------------------------
-- Runs every frame in every mode, so the beam sweeps behind the title
-- and the cutscenes too. Input.beam is a signed radian delta -- the
-- crank on the device, the autopilot's P-controller in smoke builds.

function Game.optics(dt)
    if G.spec and G.spec.wind and Kit.mode == "play" then
        G.windT = G.windT + dt
        G.wind = sin(G.windT * 0.8) * C.WIND_A
            + sin(G.windT * 2.3 + 1.1) * C.WIND_B
    else
        G.wind = 0
    end
    G.dir = clamp(G.dir + Input.beam + G.wind * dt, C.DIR_MIN, C.DIR_MAX)
    G.spread = clamp(G.spread + Input.spread * C.SPREAD_RATE * dt,
        C.SPREAD_MIN, C.SPREAD_MAX)
    local r = C.REACH * sqrt(C.SPREAD_REF / G.spread)
        * (1 - G.fog * C.FOG_BITE)
    if G.flashT > 0 then r = r * C.FLASH_MULT end
    G.reach = clamp(r, C.REACH_MIN, C.REACH_CAP)
end

-- a slow ceremonial sweep while a scene is running
function Game.idleOptics(dt)
    G.dir = G.dir + G.idleV * dt
    if G.dir > C.DIR_MAX then G.dir, G.idleV = C.DIR_MAX, -G.idleV end
    if G.dir < C.DIR_MIN then G.dir, G.idleV = C.DIR_MIN, -G.idleV end
    G.reach = C.REACH * sqrt(C.SPREAD_REF / G.spread)
        * (1 - (G.fog or 0) * C.FOG_BITE)
end

-- ---- night set-up ------------------------------------------------------------

local function placeRocks(k)
    G.nRocks = 0
    local tries = 0
    while G.nRocks < k and tries < 160 do
        tries = tries + 1
        local x = 74 + rnd() * 252
        local y = 74 + rnd() * 82
        local ok = abs(x - C.LX) > 34
        for i = 1, G.nRocks do
            local r = G.rocks[i]
            local dx, dy = x - r.x, y - r.y
            if dx * dx + dy * dy < C.ROCK_GAP * C.ROCK_GAP then ok = false end
        end
        if ok then
            G.nRocks = G.nRocks + 1
            local r = G.rocks[G.nRocks]
            r.x, r.y = x, y
            r.r = C.ROCK_MIN + rnd() * (C.ROCK_MAX - C.ROCK_MIN)
            r.seed = rnd(1, 997)
        end
    end
end

local WRX <const> = { 66, 344 }   -- the two headlands the wreckers use

local function placeWreckers(k)
    G.nWreckers = k or 0
    for i = 1, 2 do
        local w = G.wreckers[i]
        w.used = i <= G.nWreckers
        if w.used then
            w.x = WRX[i]
            w.y = Game.shoreY(w.x) + 5
            w.t, w.out, w.flick = 0, false, rnd() * 3
            w.seq = -i          -- so the bot can validate a latched target
        end
    end
end

local function buildSchedule(spec)
    G.nSched = 0
    local t = 3.0
    for i = 1, spec.ships do
        G.nSched = G.nSched + 1
        local e = G.sched[G.nSched]
        if not e then
            e = {}
            G.sched[G.nSched] = e
        end
        e.t = t
        e.kind = spec.kinds[(i - 1) % #spec.kinds + 1]
        e.x = C.SPAWN_L + rnd() * (C.SPAWN_R - C.SPAWN_L)
        e.done = false
        t = t + spec.gap[1] + rnd() * (spec.gap[2] - spec.gap[1])
    end
    if spec.lifeboat then
        G.nSched = G.nSched + 1
        local e = G.sched[G.nSched]
        if not e then
            e = {}
            G.sched[G.nSched] = e
        end
        e.t, e.kind, e.x, e.done = 7.5, "lifeboat", C.HARB_X, false
    end
end

function Game.startPlay()
    local spec = Nights.get(G.night)
    G.startNight(spec)
    placeRocks(spec.rocks or 2)
    placeWreckers(spec.wreckers or 0)
    buildSchedule(spec)
    -- the casualty the lifeboat is sent to, clear of the reefs
    G.lbx, G.lby = 132 + rnd() * 146, 96 + rnd() * 44
    for _ = 1, 12 do
        if not Game.nearestRock(G.lbx, G.lby, 34) then break end
        G.lbx, G.lby = 132 + rnd() * 146, 96 + rnd() * 44
    end
    for i = 1, C.FOG_BANKS do
        local b = G.banks[i]
        b.x = rnd() * 400
        b.y = C.HORIZON + 12 + (i - 1) * 46 + rnd() * 14
        b.w = 130 + rnd() * 110
        b.h = 16 + rnd() * 12
        b.v = 5 + rnd() * 9
        if rnd() < 0.5 then b.v = -b.v end
    end
    Sfx.song(spec.song)
    Kit.setMode("play")
    Harness.count("nights")
    Harness.set("night", G.night)
end

-- ---- the campaign -------------------------------------------------------------

function Game.enterTitle()
    G.menu = {}
    if Save.any() then G.menu[#G.menu + 1] = "CONTINUE" end
    G.menu[#G.menu + 1] = "NEW WATCH"
    G.sel = 1
    G.slotSel = 1
    Sfx.song("CALM")
    Kit.setMode("title")
end

function Game.saveProgress()
    Save.set("night", G.night)
    Save.set("saved", G.totalSaved)
    Save.set("lost", G.totalLost)
    Save.set("rescues", G.totalRescues)
    Save.set("doused", G.totalDoused)
    Save.set("cleared", G.cleared)
    Save.unlock(G.night)
    local k = "o" .. G.night
    local oil = floor(G.oil + 0.5)
    if oil > Save.get(k, 0) then Save.set(k, oil) end
    Save.meta.name = "KEEPER"
    Save.meta.place = Nights.get(G.night).name
    Save.meta.pct = floor(100 * G.cleared / Nights.COUNT + 0.5)
    Save.commit()
end

local function loadProgress()
    G.newGame()
    G.night = clamp(Save.get("night", 1), 1, Nights.COUNT)
    G.totalSaved = Save.get("saved", 0)
    G.totalLost = Save.get("lost", 0)
    G.totalRescues = Save.get("rescues", 0)
    G.totalDoused = Save.get("doused", 0)
    G.cleared = Save.get("cleared", 0)
end

-- the night card, after any cutscene that owes the player a scene
function Game.enterBrief()
    Kit.setMode("brief", 0.5)
    Sfx.song(Nights.get(G.night).song)
end

function Game.enterNight()
    local scene = Tale.scene(G.night)
    local key = "sc" .. G.night
    if scene and not Save.flag(key) then
        Save.flag(key, true)
        Story.play(scene, { onDone = Game.enterBrief })
    else
        Game.enterBrief()
    end
end

function Game.endNight(res)
    if G.result then return end
    G.result = res
    G.endT = 1.1
    if res ~= "clear" then Sfx.snuff() end
end

local function showResult()
    if G.result == "clear" then
        G.cleared = max(G.cleared, G.night)
        Harness.count("nightsCleared")
        Music.sting{ 72, 76, 79, 84 }
        if G.night < Nights.COUNT then
            G.night = G.night + 1
        else
            G.night = Nights.COUNT
        end
        Game.saveProgress()
    else
        Harness.count("nightsFailed")
    end
    Kit.setMode("result", 0.8)
end

function Game.afterResult()
    if G.result == "clear" and G.cleared >= Nights.COUNT then
        Save.flag("scEnd", true)
        Story.play(Tale.ending, {
            onDone = function()
                Kit.setMode("done", 1.0)
                Kit.saveBest(G.totalSaved)
                Harness.count("done")
                Harness.set("finalSaved", G.totalSaved)
                Harness.set("finalLost", G.totalLost)
            end,
        })
        Sfx.song("HYMN")
    else
        Game.enterNight()
    end
end

-- ---- play ----------------------------------------------------------------------

local function allResolved()
    for i = 1, G.nSched do
        if not G.sched[i].done then return false end
    end
    for i = 1, C.MAX_SHIPS do
        if G.ships[i].used then return false end
    end
    return true
end

local function playUpdate(dt)
    G.t = G.t + dt
    G.irisT = max(0, G.irisT - dt * 1.4)
    G.flashT = max(0, G.flashT - dt)
    G.flashCd = max(0, G.flashCd - dt)
    G.hornCd = max(0, G.hornCd - dt)
    G.hornT = max(0, G.hornT - dt)
    -- the fog makes up through the night
    local spec = G.spec
    G.fog = spec.fog0 + (spec.fog1 - spec.fog0)
        * min(1, G.t / C.FOG_FULL)
    for i = 1, C.FOG_BANKS do
        local b = G.banks[i]
        b.x = b.x + b.v * dt
        if b.x > 400 + b.w then b.x = -b.w end
        if b.x < -b.w then b.x = 400 + b.w end
    end

    if G.result then
        -- a beat of wreckage and quiet before the card
        G.endT = G.endT - dt
        if G.endT <= 0 then showResult() end
        return
    end

    -- the storm takes the lamp partway through the last night
    if G.failT and G.t >= G.failT then
        G.failT = nil
        Save.flag("scFail", true)
        Story.play(Tale.lampFail)
        return
    end

    if G.lampOut then
        -- crank the mechanism by hand to prime it, then strike the lens
        local d = abs(Input.beam)
        if d > 0.002 then
            G.prime = min(1, G.prime + d * C.PRIME_GAIN)
            if G.frame % 6 == 0 then Sfx.crank() end
        end
        if G.prime >= 1 and Input.flash then
            G.lampOut, G.prime = false, 0
            Harness.count("relit")
            Sfx.spark()
            Story.flash()
            Music.sting{ 72, 79, 84 }
        end
    else
        local burn = C.OIL_BASE + C.OIL_SPREAD
            * (G.spread - C.SPREAD_MIN) / (C.SPREAD_MAX - C.SPREAD_MIN)
        G.oil = G.oil - burn * dt
        if Input.flash and G.flashCd <= 0 and G.oil > C.FLASH_COST then
            G.flashT, G.flashCd = C.FLASH_T, C.FLASH_CD
            G.oil = G.oil - C.FLASH_COST
            Sfx.flash()
            Harness.count("flashes")
        end
        if G.oil <= 0 then
            G.oil = 0
            Game.endNight("dry")
            return
        end
        if G.oil < 14 and (G.frame % 45) == 0 then Sfx.warn() end
    end

    if Input.horn and G.hornCd <= 0 then
        G.hornCd, G.hornT = C.HORN_CD, 0.7
        Sfx.horn()
        Harness.count("horns")
        for i = 1, C.MAX_SHIPS do
            local s = G.ships[i]
            if s.used and s.kind ~= "lifeboat" then
                local dx, dy = s.x - C.LX, s.y - C.LY
                if dx * dx + dy * dy < C.HORN_R * C.HORN_R then
                    s.hove = C.HORN_T
                end
            end
        end
    end

    for i = 1, G.nSched do
        local e = G.sched[i]
        if not e.done and G.t >= e.t then
            if Game.spawn(e.kind, e.x) then e.done = true end
        end
    end

    updateShips(dt)
    updateWreckers(dt)

    if allResolved() or G.t > C.NIGHT_MAX then
        local ok = G.lost <= (spec.allow or 1)
        if spec.lifeboat and not G.rescued then ok = false end
        Game.endNight(ok and "clear" or "wreck")
    end
end

-- ---- the loop ---------------------------------------------------------------------

function Game.update(dt)
    G.frame = G.frame + 1
    Music.update(dt)
    Kit.updateShake(dt)
    Kit.updateParts(G.parts, dt, 80, nil)

    Story.update(dt, Input.a, Input.b and Kit.mode ~= "play")
    if Story.active then
        Game.idleOptics(dt)
        Game.castLights()
        return
    end

    Game.optics(dt)
    Game.castLights()

    local m = Kit.mode
    if m == "title" then
        if Input.up then
            G.sel = (G.sel - 2) % #G.menu + 1
            Sfx.click()
        elseif Input.down then
            G.sel = G.sel % #G.menu + 1
            Sfx.click()
        elseif Input.a then
            G.menuAct = G.menu[G.sel]
            G.slotSel = Save.any() or 1
            Kit.setMode("slots")
            Sfx.click()
        end
    elseif m == "slots" then
        if Input.up then
            G.slotSel = (G.slotSel - 2) % Save.SLOTS + 1
            Sfx.click()
        elseif Input.down then
            G.slotSel = G.slotSel % Save.SLOTS + 1
            Sfx.click()
        elseif Input.b then
            Game.enterTitle()
        elseif Input.a then
            Save.use(G.slotSel)
            if G.menuAct == "CONTINUE" and Save.load(G.slotSel) then
                loadProgress()
                Game.enterBrief()
            else
                Save.reset{ name = "KEEPER", place = "VESPER ROCK", pct = 0 }
                G.newGame()
                Game.enterNight()
            end
            Sfx.click()
        end
    elseif m == "brief" then
        if Input.a and Kit.modeT <= 0 then Game.startPlay() end
    elseif m == "play" then
        playUpdate(dt)
    elseif m == "result" then
        if Input.a and Kit.modeT <= 0 then Game.afterResult() end
    elseif m == "done" then
        if Input.a and Kit.modeT <= 0 then Game.enterTitle() end
    end
end
