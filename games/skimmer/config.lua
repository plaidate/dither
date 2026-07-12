-- Skimmer: every tunable. A dragonfly skimming a pond at golden
-- dusk, Space Harrier style: the Scaler camera flies forward, the
-- player moves on the screen plane. World units are px at scale 1
-- (the player plane projects at scale 2). Speeds are units/s.

C = {
    DT = 1 / 30,

    -- projection: camera height, vanishing line, player plane depth
    HORIZON = 110,      -- screen y of the vanishing line
    CAMY = 60,          -- camera height over the water
    PZ = 90,            -- player plane depth (f/PZ = scale 2)
    CAMX = 0.5,         -- camera lateral follow factor

    -- flight envelope (world units; y is altitude over the water)
    PX = 150,           -- lateral range +-
    PY_LO = 4, PY_HI = 52,
    XSPD = 170, YSPD = 62,

    -- crank throttle trim: speed AND points multiplier
    TRIM_LO = 0.7, TRIM_HI = 1.4,
    TRIM_GAIN = 0.0015, -- trim per crank degree

    -- forward speed and the difficulty ramp
    SPD0 = 150,         -- base units/s
    RAMP = 2.2,         -- +units/s per second of flight
    RAMP_MAX = 170,     -- ramp cap (top base speed 320)

    -- pond layout: obstacle rows on the depth queue
    LANE = 44,          -- lane width
    ROW_DZ = 90,        -- world units between spawn rows
    AHEAD = 700,        -- spawn horizon past the camera
    LILY_P = 0.32,      -- a row is a lily rank this often
    MIDGE_P = 0.55,     -- midge cluster chance per row
    REED_RAMP = 1400,   -- +1 reed per row per this distance

    -- collision half-widths / heights (world units, player plane)
    REED_W = 13, REED_H = 44,  -- tall: dodge laterally (or top it)
    LILY_W = 20, LILY_H = 10,  -- flat: only bites when you fly low
    MIDGE_W = 14, MIDGE_H = 11,
    CATCH_PTS = 10,     -- x trim at the moment of the catch
    LIVES = 3,
    INVULN = 1.6,       -- s of grace after a dunk

    -- the pond meanders: floor curve amplitude (px/band) and rate
    CURVE_AMP = 0.03, CURVE_HZ = 0.3,

    -- depth haze: shade 0 out to Z0, rising to MAX at Z1
    HAZE_Z0 = 100, HAZE_Z1 = 620, HAZE_MAX = 12,

    -- time of day (title B toggle); dusk lights the dragonfly
    TOD_NAMES = { "DAY", "DUSK" },
    TOD_AMBIENT = { 1, 0.6 },
    SUN_X = 300,
    SUN_Y = { 34, 88 },  -- the dusk sun sits low on the treeline
    SUN_R = { 15, 18 },
    GLOW_R = 46,         -- dusk glow the dragonfly carries

    -- autopilot
    AP_LOOK = 280,       -- reaction window past the player plane
    AP_MARGIN = 26,      -- lateral clearance a lane needs
    AP_CRUISE = 24,      -- cruising altitude (clears every lily)
    AP_TRIM = 1.15,      -- greedy-but-safe throttle setting
    AP_GRACE = 15,       -- s before it starts misjudging
    AP_BLUNDER = 300,    -- frames between scripted low passes
    AP_OOPS = 50,        -- frames each low pass lasts
}
