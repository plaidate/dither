-- Beacon: all mutable shared state. G.newGame() starts a campaign,
-- G.startNight(spec) rebuilds the bay for one night. The ship and
-- wrecker pools are allocated ONCE on first use and reused for the
-- whole campaign — nothing here allocates per frame.

G = {
    frame = 0,        -- global frame count (HUD blink, bot cadence)
}

-- ---- pools (built once, reused every night) --------------------------

local function shipSlot()
    return {
        used = false, kind = "smack",
        x = 0, y = 0, hd = 0, spd = 0, len = 12, turn = 1,
        core = false, dwellNeed = 0, dwell = 0, dark = 0,
        lit = 0, warned = false, hove = 0, sink = 0,
        mode = "run",    -- run | out | hold | home (lifeboat legs)
        hold = 0, seq = 0,
    }
end

local function wreckerSlot()
    return { used = false, x = 0, y = 0, t = 0, out = false, flick = 0 }
end

local function rockSlot()
    return { x = 0, y = 0, r = 10, seed = 0 }
end

function G.pools()
    if G.ships then return end
    G.ships = {}
    for i = 1, C.MAX_SHIPS do G.ships[i] = shipSlot() end
    G.wreckers = {}
    for i = 1, 2 do G.wreckers[i] = wreckerSlot() end
    G.rocks = {}
    for i = 1, 5 do G.rocks[i] = rockSlot() end
    G.sched = {}          -- { t =, kind = } spawn schedule, contiguous
    G.parts = {}          -- Kit debris (wreckage)
    G.banks = {}          -- drifting fog banks {x, y, w, h, v}
    for i = 1, C.FOG_BANKS do
        G.banks[i] = { x = 0, y = 0, w = 120, h = 26, v = 6 }
    end
end

-- ---- a fresh campaign -------------------------------------------------

function G.newGame()
    G.pools()
    G.night = 1           -- the night about to be played
    G.totalSaved = 0
    G.totalLost = 0
    G.totalRescues = 0
    G.totalDoused = 0
    G.bestOil = 0
    G.cleared = 0         -- nights cleared this campaign
    G.resetLamp()
    G.nRocks, G.nWreckers, G.nSched = 0, 0, 0
    G.nShips = 0
end

-- lamp/optics state — reset at the top of every night
function G.resetLamp()
    G.dir = C.DIR0        -- beam bearing, radians (-pi .. 0 is seaward)
    G.spread = C.SPREAD0  -- beam width, radians
    G.reach = C.REACH     -- computed each frame from spread + fog
    G.fog = 0             -- 0..1; thickens through a night
    G.oil = C.OIL_CAP
    G.flashT, G.flashCd = 0, 0
    G.hornCd, G.hornT = 0, 0
    G.lampOut = false     -- the storm has taken the lamp
    G.prime = 0           -- 0..1 relight charge from cranking in the dark
    G.wind, G.windT = 0, 0
    G.idleV = 0.22        -- ceremonial sweep speed while a scene runs
end

-- ---- one night ---------------------------------------------------------

function G.startNight(spec)
    G.pools()
    G.resetLamp()
    G.spec = spec
    G.oil = math.min(C.OIL_CAP, spec.oil)
    G.t = 0               -- seconds since dusk
    G.fog = spec.fog0 or 0
    G.saved, G.lost = 0, 0
    G.rescued = false
    G.si = 1              -- next scheduled hull
    G.failT = spec.fail and (18 + math.random() * 6) or nil
    G.endT = 0            -- post-mortem hold before the result card
    G.result = nil        -- "clear" | "wreck" | "dry"
    G.irisT = 1           -- iris-in on the lamp
    G.seq = 0
    for i = 1, C.MAX_SHIPS do G.ships[i].used = false end
    for i = 1, 2 do G.wreckers[i].used = false end
    for i = #G.parts, 1, -1 do G.parts[i] = nil end
end
