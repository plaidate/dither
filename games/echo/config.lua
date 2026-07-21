-- Echo: every tunable, with units. A bat flying a lightless cave on
-- the Super Scaler road. World units are px at scale 1; the player
-- plane sits at PZ so it projects at scale f/PZ = 2. The cave is a
-- tube: floor at world y 0, ceiling at y CAVEH, centre and half-width
-- both pure functions of z (see cave.lua) so renderer, collision and
-- autopilot all read the SAME cave.
--
-- Ambient is 0 everywhere in this game. The only light is a ping, and
-- a ping costs stamina -- so nearly every number below is really a
-- knob on the "see, commit, see" rhythm. The ones that matter most to
-- a HUMAN are PING_LIFE / PING_REACH / MEM_LIFE / FEEL: they decide
-- how long a glimpse stays useful and how much of the near tunnel you
-- can feel without sound. They are deliberately generous.

C = {
    DT = 1 / 30,

    -- ---- projection and the tube ---------------------------------------
    HORIZON = 120,    -- screen y of the vanishing line
    PZ = 90,          -- player plane depth (f/PZ = scale 2)
    CAMX = 0.45,      -- lateral camera follow (0 = fixed, 1 = glued)
    CAMY_F = 0.30,    -- vertical camera follow
    CAVEH = 64,       -- cave height, world units (constant campaign-wide)
    RING_SIZE = 44,   -- world units between drawn cross-sections
    RINGS = 22,       -- cross-sections per frame (968 units of tunnel)
    MIN_HALF = 34,    -- narrowest half-width the squeeze may produce
    OUTLINE_EVERY = 3, -- every Nth ring gets a white edge when it is lit

    -- ---- the bat -------------------------------------------------------
    BAT_HW = 11,      -- collision half-width, world units
    BAT_HH = 7,       -- collision half-height
    XSPD = 170,       -- lateral speed, units/s
    YSPD = 82,        -- climb/dive speed, units/s
    PY_LO = 5,        -- altitude limits (clamped, not fatal)
    PY_HI = 59,
    -- the crank is the throttle: slow down and every glimpse buys more
    -- reaction time, but in the last cavern the owl is closing
    TRIM_LO = 0.84, TRIM_HI = 1.22,
    TRIM_GAIN = 0.0016, -- trim per crank degree
    LIVES = 3,
    INVULN = 1.5,     -- s of grace after a crash
    STUN = 0.55,      -- s of half speed after a crash

    -- ---- the ping ------------------------------------------------------
    -- A ping is one growing Light.add plus an expanding world-space
    -- reveal front. The front travels PING_SPD units/s and dies at
    -- PING_REACH, so the glimpse always arrives before the rock does.
    PING_LIFE = 0.85,   -- s the screen light lives
    PING_CD = 0.30,     -- s between pings (anti-mash)
    PING_SPD = 980,     -- reveal front speed, units/s
    PING_REACH = 780,   -- how far a full ping maps, world units
    PING_R0 = 42,       -- screen radius at emission, px
    PING_R1 = 250,      -- screen radius at death, px
    PING_F0 = 0.62,     -- lit-core fraction at emission
    PING_F1 = 0.12,     -- ... and at death (the core shrinks, so the
                        -- glimpse decays from crisp to suggestion)
    PING_COST = 0.085,  -- stamina per ping (0..1)
    WHISPER = 0.40,     -- a low-stamina ping: this fraction of reach,
    WHISPER_R = 0.55,   -- radius and cost -- never a dead end

    -- ---- memory: light IS memory ----------------------------------------
    MEM_LIFE = 2.9,     -- s a glimpse stays useful
    MEM_FLOOR = 0.10,   -- residual silhouette of a pinged object
    FOG = 16,           -- shade added at zero memory (16 = invisible)
    FEEL_Z = 170,       -- world units you can "feel" without sound
    FEEL = 0.52,        -- memory floor at zero distance (fades to 0 at
                        -- FEEL_Z) -- the wingtip sense that stops the
                        -- game being a coin flip
    TONE_Z0 = 70,       -- depth haze: tone 0 out to here ...
    TONE_Z1 = 900,      -- ... rising to TONE_MAX at here
    TONE_MAX = 11,      -- distance read as tone, the second thesis

    -- ---- stamina --------------------------------------------------------
    STAM_MAX = 1.0,
    STAM_REGEN = 0.022, -- per s
    STAM_MOTH = 0.16,   -- per moth eaten
    STAM_ANSWER = 0.13, -- per answered call
    STAM_SCRAPE = 0.30, -- per s of grinding along a wall

    -- ---- walls ----------------------------------------------------------
    -- Walls forgive: you are clamped and drained, not killed, unless
    -- you lean on the rock for SCRAPE_KILL seconds.
    SCRAPE_KILL = 1.05, -- s of continuous scraping before it costs a life
    SCRAPE_TICK = 0.35, -- s between scrape chirps

    -- ---- obstacles ------------------------------------------------------
    LEN = { 24, 40, 56 }, -- stalactite/stalagmite lengths, world units
    TITE_W = 12,          -- collision half-widths
    MITE_W = 13,
    PILLAR_W = 15,
    MOTH_W = 20, MOTH_H = 16,
    -- one global dial on how generous the cave is with food. Breath
    -- is the whole economy, so this is the difficulty knob: at 1.0 a
    -- careful flier runs dry in the late caverns, at 1.4 they do not.
    MOTH_RATE = 1.4,
    SAFE_W = 46,        -- obstacles never spawn this close to the safe lane
    SAFE_M = 26,        -- ... and the safe lane keeps this off the wall
    AHEAD = 1150,       -- spawn horizon past the camera, world units
    BEHIND = 24,        -- cull this far behind the player plane
    MOTH_LIGHTS = 2,    -- moth glows registered per frame (light budget)
    MOTH_LIGHT_Z = 420, -- ... within this distance
    MOTH_R = 26,        -- moth glow radius, px

    -- ---- water: the second, softer reveal --------------------------------
    WET_DELAY = 0.55,   -- s before the pool throws your ping back
    WET_LIFE = 0.9,     -- s the reflection lives
    WET_R = 190,        -- its screen radius (wider, softer)
    WET_F = 0.16,       -- and its lit-core fraction
    WET_REACH = 0.75,   -- fraction of PING_REACH it maps

    -- ---- the other bat ---------------------------------------------------
    RIVAL_CD = 3.4,     -- s between Vesper's calls
    RIVAL_LIFE = 0.7,   -- s her call lights the cave
    RIVAL_R = 120,      -- screen radius of her call
    RIVAL_LEAD = 620,   -- how far ahead of you she flies, world units
    ANSWER_W = 1.5,     -- s after her call in which your ping ANSWERS
    ANSWER_REACH = 900, -- an answered call maps this far

    -- ---- the owl ----------------------------------------------------------
    OWL_START = 380,    -- world units behind you at the start of the hunt
    OWL_MAX = 460,      -- ... and the furthest it ever falls back
    OWL_CLOSE = 12,     -- units/s it gains by simply being an owl
    OWL_PING = 34,      -- units it gains every time you call
    OWL_LIT = 22,       -- extra units/s while your own light is on you
    OWL_MOTH = 70,      -- units you buy back with a moth
    OWL_RESET = 340,    -- where it falls back to after a strike
    OWL_CRY = 4.5,      -- s between its calls

    -- ---- falling rock -------------------------------------------------------
    FALL_CHANCE = 0.55, -- per stalactite in reach of a ping
    FALL_Z = 520,       -- ... within this distance
    FALL_SPD = 46,      -- units/s the tip descends

    -- ---- feel ----------------------------------------------------------------
    WIND_HZ = 0.37,     -- the cave breathes (gust frequency)
    WIND_HZ2 = 1.13,

    -- ---- autopilot -----------------------------------------------------------
    AP_LOOK = 620,      -- reaction window past the player plane
    AP_AIM = 300,       -- how far ahead it aims the corridor
    AP_LATCH = 7,       -- frames a chosen line is held (no oscillation)
    AP_PING = 2.15,     -- s between its calls (a human's rhythm)
    AP_PING_LOW = 1.25, -- ... when something is close and unmapped
    AP_MOTH_Z = 520,    -- moths it will divert for
    AP_MENU = 26,       -- frames between menu keypresses
}

C.MID = C.CAVEH * 0.5

-- ---- the campaign -----------------------------------------------------------
-- Ten caverns. len is world units (len/spd is roughly the flight time
-- in seconds); half/sqz/pinch shape the tube; dens is world units
-- between obstacle rows; w is the kind weighting; moth is the chance
-- of a moth per row. Feature flags switch on the escalating ideas:
-- wind (pushed between glimpses), wet (your ping comes back twice),
-- rival (something else is pinging), fall (your ping shakes the roof
-- down), owl (the hunt).
C.CAVERNS = {
    {
        name = "Drip Hall", song = "CAVE",
        len = 4600, spd = 165, half = 108, sqz = 8, pinch = 0,
        mnd = 24, mhz = 0.0055, shz = 0.009, phz = 0.004,
        dens = 300, moth = 0.45, w = { tite = 2, mite = 4, pillar = 0 },
        wind = 0, wet = false, rival = false, fall = false, owl = false,
        brief = "Wide and kind. Learn the call.",
    },
    {
        name = "The Fluting", song = "CAVE",
        len = 4800, spd = 176, half = 98, sqz = 15, pinch = 0,
        mnd = 30, mhz = 0.0062, shz = 0.011, phz = 0.005,
        dens = 255, moth = 0.42, w = { tite = 5, mite = 4, pillar = 0 },
        wind = 0, wet = false, rival = false, fall = false, owl = false,
        brief = "The roof grows teeth.",
    },
    {
        name = "Moth Garden", song = "CAVE",
        len = 5000, spd = 182, half = 96, sqz = 15, pinch = 0,
        mnd = 32, mhz = 0.0066, shz = 0.012, phz = 0.005,
        dens = 262, moth = 0.85, w = { tite = 4, mite = 4, pillar = 1 },
        wind = 0, wet = false, rival = false, fall = false, owl = false,
        brief = "Eat. Calling is not free.",
    },
    {
        name = "The Squeeze", song = "CAVE",
        len = 5200, spd = 190, half = 80, sqz = 22, pinch = 14,
        mnd = 30, mhz = 0.0070, shz = 0.014, phz = 0.0075,
        dens = 236, moth = 0.5, w = { tite = 4, mite = 4, pillar = 3 },
        wind = 0, wet = false, rival = false, fall = false, owl = false,
        brief = "Pillars, and the walls lean in.",
    },
    {
        name = "Windward Gallery", song = "DEEP",
        len = 5400, spd = 196, half = 90, sqz = 18, pinch = 8,
        mnd = 34, mhz = 0.0068, shz = 0.013, phz = 0.006,
        dens = 244, moth = 0.55, w = { tite = 4, mite = 4, pillar = 2 },
        wind = 46, wet = false, rival = false, fall = false, owl = false,
        brief = "The cave breathes. You drift while you are blind.",
    },
    {
        name = "Still Water", song = "DEEP",
        len = 5400, spd = 196, half = 94, sqz = 16, pinch = 8,
        mnd = 32, mhz = 0.0064, shz = 0.012, phz = 0.006,
        dens = 234, moth = 0.55, w = { tite = 5, mite = 3, pillar = 2 },
        wind = 18, wet = true, rival = false, fall = false, owl = false,
        brief = "The pool answers every call a second time.",
    },
    {
        name = "The Answer", song = "DEEP",
        len = 5600, spd = 202, half = 90, sqz = 18, pinch = 10,
        mnd = 34, mhz = 0.0070, shz = 0.013, phz = 0.0065,
        dens = 240, moth = 0.5, w = { tite = 4, mite = 4, pillar = 2 },
        wind = 22, wet = false, rival = true, fall = false, owl = false,
        brief = "Something out there is calling. Call back.",
    },
    {
        name = "Cracked Ceiling", song = "DEEP",
        len = 5600, spd = 210, half = 86, sqz = 20, pinch = 10,
        mnd = 32, mhz = 0.0072, shz = 0.014, phz = 0.007,
        dens = 226, moth = 0.55, w = { tite = 7, mite = 2, pillar = 2 },
        wind = 20, wet = false, rival = false, fall = true, owl = false,
        brief = "Your voice brings the roof down.",
    },
    {
        name = "The Long Throat", song = "HUNT",
        len = 6000, spd = 224, half = 76, sqz = 24, pinch = 16,
        mnd = 30, mhz = 0.0076, shz = 0.015, phz = 0.008,
        dens = 210, moth = 0.5, w = { tite = 5, mite = 4, pillar = 3 },
        wind = 32, wet = true, rival = true, fall = true, owl = false,
        brief = "Everything at once, and faster.",
    },
    {
        name = "Owl Light", song = "HUNT",
        len = 6400, spd = 236, half = 88, sqz = 18, pinch = 10,
        mnd = 34, mhz = 0.0074, shz = 0.013, phz = 0.007,
        dens = 238, moth = 0.75, w = { tite = 5, mite = 4, pillar = 2 },
        wind = 26, wet = false, rival = true, fall = false, owl = true,
        lives = 4, -- the hunt takes one from you almost by right
        brief = "To see is to be seen. Fly to the roost.",
    },
}

C.NCAV = #C.CAVERNS
C.MAP_ROWS = 5 -- cavern rows visible in the map list at once
