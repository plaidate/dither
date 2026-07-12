-- Glim: every tunable. A firefly-keeper in a walled night garden --
-- the crank trims the lantern wick (bright burns fast), fireflies
-- drift toward your light, moths stalk it. Units: px, px/s, seconds.

C = {
    W = 400,
    H = 240,
    DT = 1 / 30,

    AMBIENT = 0.15,      -- night: Light quantizes this to full dark
    HORIZON = 100,       -- skyline y; the garden floor is below

    -- walled garden bounds the keeper walks in
    X0 = 14, X1 = 386,
    Y0 = 108, Y1 = 226,

    -- keeper
    WALK = 64,           -- walk speed

    -- lantern wick
    WICK_MAX = 100,
    RMIN = 24, RMAX = 80, -- lantern radius range (the wick trim)
    R0 = 52,              -- starting radius
    CRANK_GAIN = 0.12,    -- radius px per crank degree
    BURN_BASE = 0.7,      -- wick/s at RMIN
    BURN_K = 2.2,         -- extra wick/s at RMAX (^1.5 curve)
    WARN_AT = 20,         -- low-wick warning threshold

    -- pulse (B): a brief flare that shoos lit moths
    PULSE_R = 90,
    PULSE_T = 0.08,       -- flare light duration (~2 frames)
    PULSE_COST = 2,       -- wick
    PULSE_CD = 0.5,       -- between pulses

    -- fireflies
    FLY_START = 8,
    FLY_CAP = 12,
    FLY_SPD = 14,         -- wander speed
    FLY_PULL = 46,        -- drift toward the keeper inside the light
    FLY_R = 10,           -- their own glow radius
    FLY_LIGHTS = 8,       -- cap on firefly Light.adds per frame
    FLY_COALESCE = 14,    -- flies closer than this share one glow
    RESP0 = 5,            -- s between respawns at nightfall
    RESP_RAMP = 0.06,     -- +s per s of night (respawn slows)

    -- moths
    MOTH_MIN = 2, MOTH_MAX = 4,
    MOTH_EVERY = 45,      -- +1 moth per this many s of night
    MOTH_SPD0 = 26,       -- stalk speed at nightfall
    MOTH_RAMP = 0.14,     -- +px/s per s of night
    MOTH_STEAL = 9,       -- wick stolen per hit
    MOTH_HIT = 9,         -- contact radius
    MOTH_FLEE = 2.0,      -- s of retreat after a hit or a pulse
    SCATTER = 50,         -- flies this near the keeper scatter on hit

    -- the jar (bottom-left)
    JARX = 36, JARY = 206,
    JAR_R = 14,           -- catch radius
    JAR_GLOW = 18,        -- its light when the keeper is near
    JAR_NEAR = 90,
}
