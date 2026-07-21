-- Echo: all mutable shared state. G.boot() runs once; G.enter(i)
-- installs a cavern and G.launch() begins a flight through it.
--
-- The obstacle list is POOLED: G.obs holds the live ones, G.free the
-- dead. Nothing in the flight path allocates a table, so a 28-second
-- cavern with 200 rows of rock costs one allocation burst at the top
-- and none afterwards.

G = {
    frame = 0,  -- global frame counter (autopilot cadence, blink)
    time = 0,   -- global clock (wind, wing beat, moth bob)
    cavI = 1,   -- the cavern being flown / selected
    cav = nil,  -- C.CAVERNS[cavI]
    slotSel = 1,
    mapSel = 1,
    mapTop = 1,     -- first visible row of the map list
    mapDirty = true,
    mapRows = {},   -- pre-built Kit.list rows (rebuilt only when dirty)
    cleared = 0,    -- caverns cleared this save
    done = false,   -- the campaign is finished
    obs = {},       -- live obstacles
    free = {},      -- the pool
    parts = {},     -- Kit debris
    sx = 200, sy = 120, -- the bat's screen position (set each draw)
    lit = 0,        -- Light.at(bat) from LAST frame's light pass
}

-- one-time boot: nothing here depends on a cavern
function G.boot()
    G.px, G.py = 0, C.MID
    G.stam = C.STAM_MAX
    G.lives = C.LIVES
    G.pingT, G.pingAge, G.front, G.prevFront = 0, 0, 0, 0
    G.pingCD, G.whisper = 0, false
    G.reach, G.pingR1 = C.PING_REACH, C.PING_R1
    G.trim = 1.0
    G.spd = 0
    G.memZ, G.memT = 0, 0
    G.wetT, G.wetPend = 0, 0
    G.wind, G.gust = 0, 0
    G.dist, G.z0 = 0, 0
    G.moths, G.runT = 0, 0
    G.invulnT, G.stunT, G.scrapeT, G.scrapeTick = 0, 0, 0, 0
    G.wipeT, G.dissT = 0, 0
    G.nextRowZ = 0
    G.safe = 0
    G.rival = { on = false, z = 0, x = 0, y = C.MID, t = 0, cd = 0,
        callT = 0, window = 0, answered = false }
    G.owl = { on = false, d = C.OWL_START, cryT = 0, hitT = 0 }
    G.enter(1)
end

-- install cavern i (menus, briefings and flights all read G.cav)
function G.enter(i)
    G.cavI = math.max(1, math.min(C.NCAV, i))
    G.cav = C.CAVERNS[G.cavI]
end

-- start a flight through the installed cavern
function G.launch()
    local cv = G.cav
    Scaler.cam.z = 0
    Scaler.cam.x, Scaler.cam.y = 0, C.MID
    G.px, G.py = Cave.centerAt(C.PZ), C.MID
    G.stam = C.STAM_MAX
    G.lives = C.LIVES
    G.pingT, G.pingAge, G.front, G.prevFront = 0, 0, 0, 0
    G.pingCD, G.whisper = 0, false
    G.reach, G.pingR1 = C.PING_REACH, C.PING_R1
    G.trim = 1.0
    G.spd = 0
    G.memZ, G.memT = 0, 0
    G.wetT, G.wetPend = 0, 0
    G.wind, G.gust = 0, 0
    G.dist, G.z0 = 0, 0
    G.moths, G.runT = 0, 0
    G.invulnT, G.stunT = 1.0, 0
    G.scrapeT, G.scrapeTick = 0, 0
    G.wipeT, G.dissT = 1, 0
    G.safe = 0
    G.nextRowZ = C.PZ + 420 -- a clear run-up before the first row
    G.spd = cv.spd
    Cave.clear()
    local r = G.rival
    r.on = cv.rival
    r.z = C.PZ + C.RIVAL_LEAD
    r.x, r.y = 0, C.MID
    r.t, r.cd, r.callT, r.answered = 0, 1.6, 0, false
    r.window = 0
    local o = G.owl
    o.on = cv.owl
    o.d = C.OWL_START
    o.cryT, o.hitT = 1.5, 0
end
