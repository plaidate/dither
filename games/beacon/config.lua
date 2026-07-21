-- Beacon: every tunable, in one table, with units. You are the keeper
-- of Vesper Rock; the crank turns a real Light.cone out over a black
-- bay, fog eats its reach, and Light.at at a ship's position is that
-- ship's steering input. Units: px, px/s, radians, radians/s, seconds.

C = {
    W = 400,
    H = 240,
    DT = 1 / 30,

    -- ---- the night ---------------------------------------------------
    AMBIENT = 0.12,       -- Light quantizes this to full dark
    HORIZON = 34,         -- sky/sea boundary; the bay is below
    OFFSHORE = 36,        -- y above which a ship has stood safely out
                          -- (the HUD board's lower edge, so nothing is
                          -- ever resolved out of sight behind it)
    SPAWN_Y = 42,         -- ships appear just under the board
    SPAWN_L = 74,         -- and between these x (the mouth of the bay)
    SPAWN_R = 326,

    -- ---- the lamp ----------------------------------------------------
    LX = 200, LY = 206,   -- the lantern room: beam origin, on the rock
    DIR0 = -1.5708,       -- straight out to sea (-pi/2 is up)
    DIR_MIN = -3.10,      -- the seaward arc the mechanism can reach
    DIR_MAX = -0.04,
    CRANK_GAIN = 0.55,    -- beam radians per crank radian (~2 turns/sweep)
    KEY_SLEW = 2.2,       -- rad/s when steering with left/right instead

    SPREAD_MIN = 0.14,    -- focused: a needle that reaches the horizon
    SPREAD_MAX = 0.85,    -- flooded: a wide wash that reaches nothing
    SPREAD_REF = 0.34,    -- the spread REACH is quoted at
    SPREAD0 = 0.30,       -- where the shutter starts each night
    SPREAD_RATE = 0.85,   -- rad/s while up/down is held
    REACH = 205,          -- beam length at SPREAD_REF in clear air
    REACH_CAP = 340,      -- and the mechanical limit of the lens
    REACH_MIN = 44,
    CORE = 0.55,          -- Light falloff: lit-core fraction of reach
    FOG_BITE = 0.5,       -- fraction of reach lost at fog 1.0

    -- the lantern-room glazing bars: two short Light.walls a few px off
    -- the lamp, which throw two fixed ~18-degree blind sectors over the
    -- bay. Real lighthouses have obscured sectors; here they are a
    -- mechanic — a ship inside one cannot be lit at all.
    AST_R = 12,           -- radius of the bars from the filament
    AST_L = 2.2,          -- their length (sets the sector width)
    AST_A = { -2.30, -0.84 },

    -- ---- oil ----------------------------------------------------------
    OIL_CAP = 120,        -- the meter's full mark
    OIL_BASE = 0.55,      -- oil/s at SPREAD_MIN
    OIL_SPREAD = 1.35,    -- extra oil/s at SPREAD_MAX
    FLASH_T = 0.9,        -- A: the lens surge, seconds of over-reach
    FLASH_MULT = 1.5,     -- reach multiplier while surging
    FLASH_CD = 2.2,
    FLASH_COST = 4,       -- oil per surge

    -- ---- the fog horn (B) ----------------------------------------------
    HORN_CD = 5.5,
    HORN_R = 155,         -- ships inside this heave to
    HORN_T = 3.0,         -- for this long
    HORN_SLOW = 0.22,     -- speed multiplier while hove to

    -- ---- ships ----------------------------------------------------------
    MAX_SHIPS = 10,       -- pool size; the pool is built once
    SPAWN_HD = 0.86,      -- spawn heading = down +/- U(0.34, this)
    WARN_SIN = -0.25,     -- sin(heading) under this = bow is offshore
    TURN_LOST = 0.55,     -- rad/s a warned ship keeps correcting at
    DWELL_DROP = 0.6,     -- s of darkness that resets a collier's dwell
    ROCK_AVOID = 62,      -- a lit ship steers around rock inside this
    ROCK_PUSH = 0.62,     -- rad of that steer
    BAY_L = 130, BAY_R = 270, -- outside this band, steer for the middle
    WALL_PUSH = 0.75,     -- rad of that steer at the bay wall
    LURE_R = 120,         -- a false light pulls unlit ships this far
    LURE_RATE = 0.5,      -- rad/s of pull

    -- per-kind: speed px/s, hull length px, turn rad/s under full light,
    -- core = only answers the lit core, dwell = seconds of continuous
    -- light before the master will answer at all
    KINDS = {
        smack   = { spd = 22, len = 12, turn = 1.5, core = false, dwell = 0 },
        brig    = { spd = 19, len = 17, turn = 0.9, core = true,  dwell = 0 },
        steamer = { spd = 30, len = 15, turn = 1.2, core = false, dwell = 0 },
        collier = { spd = 17, len = 19, turn = 0.9, core = false, dwell = 1.5 },
        lifeboat = { spd = 38, len = 9, turn = 2.4, core = false, dwell = 0 },
    },

    -- ---- rocks and the harbour --------------------------------------------
    ROCK_MIN = 9, ROCK_MAX = 15,
    ROCK_GAP = 54,        -- minimum separation when placing them
    HARB_X = 290,         -- the harbour mouth (the lifeboat's berth)
    HARB_Y = 180,
    LB_HOLD = 1.1,        -- s the lifeboat must stay lit alongside
    LB_DRIFT = 0.2,       -- fraction of her speed she makes unlit

    -- ---- wreckers ---------------------------------------------------------
    WRECK_R = 30,         -- radius of the false light they show
    DOUSE_T = 2.2,        -- s of your beam on them to put it out
    DOUSE_DECAY = 0.7,    -- s of progress lost per s off them

    -- ---- the storm --------------------------------------------------------
    WIND_A = 0.34,        -- rad/s of aim swing, slow component
    WIND_B = 0.20,        -- ... and fast component
    PRIME_GAIN = 0.11,    -- prime per radian cranked while the lamp is out
    NIGHT_MAX = 118,      -- hard cap on a night, seconds

    -- ---- fog --------------------------------------------------------------
    FOG_FULL = 55,        -- s for a night's fog to reach its full weight
    FOG_BANKS = 3,

    -- ---- autopilot ----------------------------------------------------------
    AP_SLEW = 0.13,       -- rad/frame the bot will crank (~225 deg/s)
    AP_LATCH = 1.1,       -- s a target stays chosen before a re-think
    AP_EDGE = 0.35,       -- urgency margin needed to switch early
    AP_SPREAD = 0.28,     -- the bot's preferred flood, oil-wise
    AP_SHADOW = 0.8,      -- s aimed-but-dark before blaming a blind sector
    AP_BLIND = 2.2,       -- s that target is then skipped for
    AP_HORN = 3.4,        -- s-to-grounding under which the bot sounds off
    AP_TAP = 8,           -- frames between menu / dialogue taps
}
