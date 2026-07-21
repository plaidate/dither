-- Prowl: every tunable, with units. A cat burgling a sleeping town by
-- night. Darkness is cover: guards carry Light.cone lanterns, every
-- crate and wall is a Light.wall occluder that throws a real shadow,
-- and you are seen exactly when Light.at(cat) > 0 and a guard has an
-- unblocked line to you. Units: px, px/s, seconds, radians.

C = {
    W = 400,
    H = 240,
    DT = 1 / 30,

    -- ---- the room ----------------------------------------------------
    -- Every heist is one screen. HUD owns the top 22px; the border band
    -- is solid stone (collision, but not registered as an occluder --
    -- see WALL_CULL below for why).
    X0 = 16, Y0 = 34,          -- inner playable rect (cat centre limits)
    X1 = 384, Y1 = 226,
    BORDER = 10,               -- drawn thickness of the stone band

    AMBIENT = 0.12,            -- night. Light quantizes this to dark.

    -- ---- the cat -----------------------------------------------------
    PRAD = 5,                  -- collision radius (px)
    WALK = 62,                 -- padding speed: fast, and NOISY
    CREEP = 34,                -- B held: half speed, silent
    ACCEL = 420,               -- px/s^2 toward the input heading

    -- ---- noise -------------------------------------------------------
    -- A noise is a point + radius; guards inside it go and look. The
    -- cat only makes noise while padding, never while creeping.
    NOISE_WALK = 74,           -- radius of a padding footfall
    NOISE_EVERY = 0.42,        -- s between footfalls
    PEBBLE_NOISE = 118,        -- a thrown pebble is a much louder lie
    PEBBLE_CD = 1.8,           -- s between throws
    PEBBLE_MAX = 3,            -- carried per heist
    THROW_MIN = 46,            -- crank dials the throw...
    THROW_MAX = 148,           -- ...between these
    THROW_0 = 92,              -- starting throw distance
    CRANK_GAIN = 0.34,         -- throw px per crank degree

    -- ---- detection ---------------------------------------------------
    -- One meter, 0..1. It fills while a guard can see you and drains
    -- in the dark, so being clipped by a passing beam is survivable and
    -- standing in one is not.
    DET_FILL = 0.70,           -- per second, fully lit at point blank
    DET_CONE = 1.65,           -- multiplier inside a guard's own cone
    DET_DIM = 0.55,            -- multiplier when Light.at says 0.5
    DET_DRAIN = 0.95,          -- per second in the dark
    DET_NEAR = 0.30,           -- floor on the closeness factor
    DET_SUSPECT = 0.34,        -- meter at which guards start closing in
    DET_HUNT = 0.72,           -- meter at which they know where you are
    DET_EVADE = 0.50,          -- crossing above this then reaching 0
                               -- counts one "evaded" -- a near miss

    -- ---- guards ------------------------------------------------------
    SIGHT = 112,               -- how far a guard can see a lit cat
    CONE_R = 108,              -- lantern cone reach (light + sight)
    CONE_SPREAD = 0.92,        -- total cone angle
    VIEW_ARC = 0.95,           -- half-angle he can notice things lit by
                               -- SOMETHING ELSE (wider than his lantern)
    G_SPD = 33,                -- patrol
    G_SUS = 44,                -- walking to a noise
    G_HUNT = 56,               -- coming for you
    G_PAUSE = 1.1,             -- s held at each waypoint
    G_LOOK = 2.6,              -- s spent searching a noise point
    G_HUNT_T = 4.5,            -- s of hunting before it decays
    SWEEP = 0.52,              -- rad of lantern sweep either side
    SWEEP_RATE = 1.15,         -- rad/s of the sweep oscillator
    TURN = 5.0,                -- rad/s the facing chases the heading
    STAND_SPIN = 0.55,         -- rad/s a stationary floorwalker turns
    TOUCH = 12,                -- a guard this close grabs you outright

    -- ---- the watchdog ------------------------------------------------
    -- Hears rather than sees: light is irrelevant to it, noise is not.
    DOG_SPD = 30,
    DOG_CHASE = 56,           -- deliberately slower than WALK: a cat
                               -- that runs the moment it is heard gets
                               -- away, a cat that keeps creeping does not
    DOG_HEAR = 96,             -- radius it notices a padding cat in
    DOG_CREEP_HEAR = 34,       -- ... and a creeping one
    DOG_LOSE = 3.2,            -- s of chasing before it gives up --
                               -- this does NOT refresh, so a cat that
                               -- runs the instant it is heard escapes
    DOG_COOL = 2.6,            -- s it will not re-acquire after that            -- s of chasing before it gives up
    DOG_TOUCH = 13,
    DOG_BARK = 128,            -- a barking dog is a noise to the guards

    -- ---- the drunk ---------------------------------------------------
    -- Carries a lantern, sees nothing. A light with legs.
    DRUNK_SPD = 21,
    DRUNK_R = 56,
    DRUNK_WOBBLE = 14,         -- px of lateral stagger

    -- ---- interaction -------------------------------------------------
    LOOT_R = 15,               -- reach for a piece of loot
    DOUSE_R = 22,              -- reach for a lamp
    EXIT_R = 18,               -- reach for the drainpipe
    DOUSE_T = 0.45,            -- s the paw is on the lamp
    LAMP_R = 66,               -- default lamp radius

    -- ---- occluder budget ---------------------------------------------
    -- Light.wall caps at 64 segments and every wall inside a light's
    -- reach costs one polygon fill per darkness band. A box is 4 walls,
    -- so we register only the boxes near the cat: SIGHT < WALL_CULL, so
    -- every occluder that could matter to detection is always in.
    WALL_CULL = 152,           -- px from the cat
    WALL_BOXES = 13,           -- hard cap on boxes registered per frame

    -- ---- pacing ------------------------------------------------------
    BRIEF_T = 2.6,             -- s the stage card holds
    CAUGHT_T = 1.6,            -- s the collar banner holds
    CLEAR_T = 1.2,             -- s before the clear card takes input
    ALARM_SPD = 1.35,          -- guard speed multiplier once the alarm
                               -- rings on the last piece of loot

    -- ---- autopilot ---------------------------------------------------
    AP_CELL = 8,               -- px per flow-field / walkability cell
    AP_PATIENCE = 1.8,         -- s it will wait in cover before risking
    AP_PUSH = 3.2,             -- s of "go anyway" once patience runs out
    AP_RISK_STOP = 0.52,       -- meter above which it aborts and hides
    AP_LUNGE = 46,             -- px: this close to the prize, take the
                               -- exposure rather than wait out the cone
    AP_KEEP = 48,              -- px it refuses to come to a guard
    AP_DOGKEEP = 58,           -- ... and to a dog (they are faster
                               -- than a creep and deaf to darkness)
    AP_DESPERATE = 50,         -- s in a heist before the bot stops
                               -- respecting light (bodies still count)
    AP_RECKLESS = 85,          -- s before it just walks the field --
                               -- a bounded attempt beats an open-ended
                               -- wait, because a collar costs 4s and a
                               -- deadlock costs the whole run
    AP_STUCK = 1.4,            -- s of no progress before a jiggle
    AP_REPATH = 12,            -- frames between flow-field rebuilds
}
