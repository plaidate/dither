-- Delve: every tunable in one table, commented with units. A side-view
-- mine descent where light is a consumable you PLACE: the helmet lamp
-- is a short Light.cone that burns oil, and a flare is a Light.add you
-- throw once and never get back. The creatures advance only where
-- Light.at says it is dark (the inverse of glim's moths), so a lit
-- flare is a wall built out of light and a spent one is a wall that
-- falls down.
--
-- Units: px, px/s, px/s^2, seconds, radians.

C = {
    W = 400, H = 240,
    DT = 1 / 30,

    -- ---- the shaft ---------------------------------------------------
    -- A depth is a stack of full-width rock slabs, each with one hole.
    -- You descend by walking into the hole. The slab you are standing
    -- on is ALSO the occluder that hides the floor below it, so you
    -- genuinely cannot see where you are about to land -- that duality
    -- (collision volume + Light.wall) is the level design.
    FLOOR_H = 62,       -- px between slab tops
    SLAB = 10,          -- slab thickness, px
    TOP0 = 74,          -- world y of slab 1's top surface
    HOLE_W = 44,        -- descent hole width, px
    WALLX = 12,         -- side wall thickness, px
    BOTTOM_PAD = 44,    -- world height below the last slab

    -- Occluder budget. Light's compositor only carves a wall's shadow
    -- when one of the segment's ENDPOINTS lies inside the light's
    -- reach, so a 380px floor edge would be invisible to it. Cut every
    -- floor edge into WALL_CHUNK pieces and register only the slabs
    -- around the player -- Light.wall caps at 64 per frame.
    WALL_CHUNK = 52,    -- px per occluder segment
    OCC_ROCKS = 3,      -- solid props registered as Light.box per frame

    -- ---- the delver --------------------------------------------------
    PW = 5,             -- half width, px
    PH = 20,            -- height, px (y is the feet)
    RUN = 82,           -- top ground speed
    ACC = 720,          -- ground acceleration
    FRICT = 900,        -- ground deceleration
    AIR = 340,          -- air acceleration
    GRAV = 620,
    JUMPV = 224,        -- launch speed
    MAXFALL = 330,
    COYOTE = 0.09,      -- s of grace after stepping off an edge
    FALL_HURT = 104,    -- fall further than this and it costs a grit
    SWIM = 0.55,        -- speed multiplier while wading a pool
    ROPE_SPD = 58,      -- climb speed
    GRIT_MAX = 3,       -- hits before you black out
    HURT_INVULN = 1.3,
    KNOCK = 130,        -- knockback speed on a hit

    -- ---- the helmet lamp ---------------------------------------------
    LAMP_R = 98,        -- cone reach, px
    LAMP_SPREAD = 1.02, -- total wedge, radians
    LAMP_FALL = 0.5,    -- lit-core fraction of the reach
    LAMP_Y = 14,        -- px above the feet the lamp sits
    OIL_MAX = 100,
    OIL_BURN = 1.5,     -- oil/s with the lamp lit
    OIL_WET = 2.3,      -- oil/s while standing in water
    PITCH_HOME = 0.30,  -- rad below horizontal the beam rests at
    PITCH_MIN = -0.85, PITCH_MAX = 1.20,
    CRANK_PITCH = 0.006,-- rad per crank degree
    PITCH_RETURN = 0.5, -- rad/s the beam drifts back to home

    -- ---- flares ------------------------------------------------------
    FLARE_MAX = 3,
    FLARE_R = 80,       -- radius while burning bright
    FLARE_FALL = 0.42,  -- lit-core fraction
    FLARE_LIFE = 9.0,   -- s of burn
    FLARE_FADE = 3.2,   -- last s over which the radius collapses
    FLARE_VX = 138, FLARE_VY = -126, FLARE_G = 560,
    FLARE_AIM = 120,    -- px/s of launch vy per unit sin(beam pitch):
                        -- tilt the beam down and the flare lands short
    FLARE_CD = 0.4,     -- s between throws

    -- ---- fixtures ----------------------------------------------------
    LANT_R = 78, LANT_FALL = 0.5,
    LANT_NEAR = 17,     -- proximity that lights a lantern
    CRATE_NEAR = 15,
    CRATE_RESP = 8,     -- s before a looted crate is restocked
    GLOW_R = 36, GLOW_FALL = 0.34,  -- glowworm seams: the only ambient
    GLOW_MAX = 5,       -- nearest glows registered per frame
    EXIT_NEAR = 16,

    -- ---- the dark things ---------------------------------------------
    CRAWL_SPD = 33,     -- px/s at depth 1
    CRAWL_RAMP = 1.7,   -- +px/s per depth
    CRAWL_FLEE = 1.4,   -- retreat speed multiplier while lit
    CRAWL_HIT = 10,     -- contact radius, px
    CRAWL_CD = 1.5,     -- s between bites
    CRAWL_RANGE = 190,  -- px it will notice you from
    CLING_DROP = 30,    -- px of horizontal overlap that trips a clinger
    LIT_EVERY = 3,      -- frames between a mob's Light.at query

    FALL_EVERY = 3.4,   -- s between rockfalls on a rigged floor
    FALL_WARN = 0.9,    -- s of trickling dust before the rock lets go
    FALL_SPD = 240,

    -- ---- the Warden (the finale) --------------------------------------
    BOSS_SPD = 25,      -- px/s advance in darkness, phase 1
    BOSS_RAMP = 9,      -- +px/s per phase
    BOSS_HIT = 19,
    BOSS_PUSH = 1.0,    -- pressure needed to drive it down a level
    BOSS_GAIN = 0.15,   -- push/s per lit source covering it: the lamp
                        -- alone takes ~8s, a flare landed on it halves that
    BOSS_DRAIN = 0.03,  -- push/s lost while it stands in darkness
    BOSS_RECOIL = 2.6,  -- s it reels after a phase breaks
    BOSS_PHASES = 3,

    AMBIENT = 0.12,     -- Light quantizes anything < 0.5 to full dark,
                        -- so DEPTH DARKNESS IS AUTHORED WITH `glows`,
                        -- not with this number (see README notes).
}

-- ---- the campaign --------------------------------------------------
-- Ten depths. Each spec is the recipe the generator fills a shaft
-- from; `glows` is the real difficulty dial (how much of the rock
-- lights itself), `dark` marks a depth whose route you have to throw a
-- flare ahead to read, `noLamp` is the collapse that takes the lamp.
C.DEPTHS = {
    { name = "THE ADIT", floors = 6, glows = 8,
      crawlers = 0, clingers = 0, fallers = 0, pools = 0, ropes = 0,
      rocks = 2, lanterns = 2, crates = 1, song = "SHAFT",
      blurb = "Follow the old rail down." },

    { name = "CRAWLWAYS", floors = 7, glows = 5,
      crawlers = 3, clingers = 0, fallers = 0, pools = 0, ropes = 0,
      rocks = 3, lanterns = 2, crates = 1, song = "SHAFT",
      blurb = "Something moves beyond the lamp." },

    { name = "THE LONG FALL", floors = 8, glows = 0, dark = true,
      crawlers = 4, clingers = 1, fallers = 0, pools = 0, ropes = 0,
      rocks = 3, lanterns = 2, crates = 2, song = "SHAFT",
      blurb = "Throw a flare. Then look." },

    { name = "THE SUMP", floors = 8, glows = 3,
      crawlers = 4, clingers = 2, fallers = 0, pools = 3, ropes = 0,
      rocks = 2, lanterns = 2, crates = 2, song = "WATER",
      blurb = "Water drowns a flare in a breath." },

    { name = "ROCKFALL", floors = 8, glows = 4,
      crawlers = 4, clingers = 1, fallers = 4, pools = 1, ropes = 0,
      rocks = 4, lanterns = 2, crates = 2, song = "WATER",
      blurb = "The roof is not finished settling." },

    { name = "THE SWARM", floors = 9, glows = 2,
      crawlers = 8, clingers = 3, fallers = 0, pools = 1, ropes = 0,
      rocks = 3, lanterns = 3, crates = 3, song = "WATER",
      blurb = "Ration the light. There is not enough." },

    { name = "ROPE GALLERY", floors = 9, glows = 3,
      crawlers = 5, clingers = 2, fallers = 2, pools = 1, ropes = 2,
      rocks = 3, lanterns = 2, crates = 2, song = "DEEP",
      blurb = "Two floors of nothing under the rope." },

    -- no lamp at all: every Light.at down here answers from flares,
    -- glow seams and lanterns alone, so the mobs are thinned and
    -- slowed and the crate/lantern economy is doubled to compensate
    { name = "THE COLLAPSE", floors = 9, glows = 3, dark = true,
      noLamp = true, mobSpd = 0.55,
      crawlers = 3, clingers = 1, fallers = 2, pools = 0, ropes = 1,
      rocks = 3, lanterns = 3, crates = 5, song = "DEEP",
      blurb = "No lamp. Two flares. Go." },

    { name = "THE COLD SEAM", floors = 10, glows = 2,
      crawlers = 6, clingers = 3, fallers = 4, pools = 3, ropes = 1,
      rocks = 4, lanterns = 3, crates = 3, song = "DEEP",
      blurb = "Everything at once, and colder." },

    { name = "THE DEEP GALLERY", floors = 4, glows = 2, boss = true,
      crawlers = 2, clingers = 0, fallers = 0, pools = 1, ropes = 0,
      rocks = 2, lanterns = 3, crates = 4, song = "WARDEN",
      blurb = "It has been waiting at the bottom." },
}

C.LAST = #C.DEPTHS
