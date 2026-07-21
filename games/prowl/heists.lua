-- Prowl: the ten heists, as data. One screen each -- the whole town
-- fits in Light's 64-segment occluder budget only because a heist is a
-- single room, and that constraint is the level design.
--
-- Every box is BOTH a collision volume and a shadow caster; that
-- duality is the game, so there is exactly one list of them.
--
--   boxes  { x, y, w, h, kind }        kind picks the art
--   lamps  { x, y, r, dousable }       a doused lamp is gone for good
--   guards { rt = {x,y, x,y, ...}, cone =, spread =, spd =, boss = }
--   dogs   { rt = ... }                hears, does not see
--   drunks { rt = ... }                a light with legs, sees nothing
--   loot   { x, y, kind }
--   escape                             alarm on the last piece
--
-- Coordinates are screen space; the playable rect is C.X0..C.X1 by
-- C.Y0..C.Y1. Game.freePoint nudges any authored point that landed
-- inside a box, so a typo costs a pixel, not a soft lock.

Heists = {}

Heists.list = {

    -- 1 --------------------------------------------------------------
    -- One lantern, one bored watch, plenty of crates. The tutorial for
    -- "the shadow is the floor".
    {
        name = "Fishmonger's Yard",
        sub = "One lantern. One bored watch.",
        song = "PROWL", par = 70,
        sx = 26, sy = 214, ex = 372, ey = 44,
        boxes = {
            { 46, 58, 38, 26, "crate" },
            { 150, 148, 46, 28, "crate" },
            { 252, 52, 34, 34, "crate" },
            { 300, 172, 52, 24, "cart" },
            { 186, 40, 18, 62, "wall" },
            { 92, 180, 26, 26, "barrel" },
        },
        lamps = { { 214, 58, 70 }, { 332, 120, 58, true } },
        guards = {
            { rt = { 170, 196, 330, 196, 330, 112, 170, 112 } },
        },
        loot = {
            { 58, 132, "fish" }, { 236, 204, "fish" }, { 358, 64, "coin" },
        },
    },

    -- 2 --------------------------------------------------------------
    -- Two watchmen walking opposite lanes: their cones cross in the
    -- middle of the alley and the only way through is the gap between
    -- the cooper's stacked staves.
    {
        name = "Cooper's Alley",
        sub = "Two lanterns, and they cross.",
        song = "PROWL", par = 80,
        sx = 24, sy = 140, ex = 376, ey = 158,
        boxes = {
            { 120, 34, 20, 86, "wall" },
            { 120, 166, 20, 60, "wall" },
            { 252, 34, 20, 86, "wall" },
            { 252, 166, 20, 60, "wall" },
            { 56, 124, 42, 26, "crate" },
            { 318, 112, 42, 26, "crate" },
            { 180, 120, 34, 24, "barrel" },
        },
        lamps = { { 200, 42, 64 }, { 200, 218, 64, true } },
        guards = {
            { rt = { 90, 62, 320, 62 } },
            { rt = { 320, 198, 90, 198 } },
        },
        loot = {
            { 40, 196, "coin" }, { 300, 58, "coin" }, { 368, 214, "cup" },
        },
    },

    -- 3 --------------------------------------------------------------
    -- Four street lamps in a row. All four can be put out, and a lamp
    -- you douse is a light removed from the level for good -- the first
    -- heist where you change the map instead of dodging it.
    {
        name = "Lamplighter Row",
        sub = "Four lamps. Four wicks to pinch.",
        song = "PROWL", par = 95,
        sx = 24, sy = 214, ex = 376, ey = 40,
        boxes = {
            { 60, 60, 36, 24, "crate" },
            { 150, 60, 36, 24, "crate" },
            { 240, 60, 36, 24, "crate" },
            { 330, 60, 36, 24, "crate" },
            { 104, 150, 40, 26, "cart" },
            { 214, 150, 40, 26, "cart" },
            { 310, 160, 40, 26, "cart" },
        },
        lamps = {
            { 80, 120, 62, true }, { 170, 120, 62, true },
            { 260, 120, 62, true }, { 350, 120, 62, true },
            { 200, 212, 58 },
        },
        guards = {
            { rt = { 110, 196, 336, 196, 336, 110, 110, 110 }, cone = 104 },
        },
        loot = {
            { 38, 88, "candle" }, { 200, 44, "candle" }, { 372, 196, "coin" },
        },
    },

    -- 4 --------------------------------------------------------------
    -- The kennel. The mastiff cannot see you at all -- darkness is no
    -- help. It hears you, so the answer is the creep, not the shadow.
    {
        name = "The Kennel",
        sub = "It cannot see you. It does not need to.",
        song = "WATCH", par = 95,
        sx = 24, sy = 44, ex = 376, ey = 226,
        boxes = {
            { 150, 40, 20, 70, "wall" },
            { 150, 150, 20, 76, "wall" },
            { 60, 120, 44, 28, "crate" },
            { 250, 60, 44, 28, "crate" },
            { 250, 170, 44, 28, "crate" },
            { 330, 110, 40, 26, "barrel" },
        },
        lamps = { { 96, 62, 60 }, { 330, 62, 58, true } },
        guards = {
            { rt = { 200, 196, 320, 196, 320, 64, 200, 64 } },
        },
        dogs = { { rt = { 70, 204, 132, 204, 132, 176, 70, 176 } } },
        loot = {
            { 32, 150, "fish" }, { 212, 128, "coin" }, { 372, 60, "cup" },
        },
    },

    -- 5 --------------------------------------------------------------
    -- A drunk wanders home with a lantern. He never looks at you --
    -- but wherever he goes, cover stops being cover.
    {
        name = "Drunkard's Lane",
        sub = "He is not looking. His lamp is.",
        song = "WATCH", par = 100,
        sx = 24, sy = 44, ex = 376, ey = 40,
        boxes = {
            { 70, 50, 40, 26, "crate" },
            { 180, 44, 20, 66, "wall" },
            { 180, 160, 20, 66, "wall" },
            { 260, 110, 44, 26, "cart" },
            { 90, 160, 40, 26, "cart" },
            { 316, 48, 40, 26, "crate" },
        },
        lamps = { { 40, 218, 52, true }, { 372, 122, 54, true } },
        guards = {
            { rt = { 60, 110, 150, 110, 150, 200, 60, 200 } },
        },
        drunks = { { rt = { 216, 220, 358, 220, 358, 96, 216, 96 } } },
        loot = {
            { 132, 84, "cup" }, { 240, 202, "coin" }, { 352, 194, "candle" },
        },
    },

    -- 6 --------------------------------------------------------------
    -- The counting house floor: two pillars and nothing else. There is
    -- no cover to slip behind, only the seconds between sweeps.
    {
        name = "The Counting House",
        sub = "No crates. No corners. Only timing.",
        song = "WATCH", par = 110,
        sx = 24, sy = 226, ex = 376, ey = 44,
        boxes = {
            { 110, 108, 18, 20, "pillar" },
            { 272, 108, 18, 20, "pillar" },
            { 191, 58, 18, 20, "pillar" },
            { 191, 182, 18, 20, "pillar" },
        },
        -- no street lamp at all: the floorwalker's own cone is the
        -- only light in the room, so the thing that can see you is
        -- also the only thing that can show you the floor
        lamps = {},
        guards = {
            { rt = { 120, 66, 300, 66 }, cone = 96 },
            { rt = { 300, 190, 100, 190 }, cone = 96 },
            { rt = { 200, 118 }, cone = 104, spread = 0.9 },
        },
        loot = {
            { 38, 122, "coin" }, { 368, 122, "coin" }, { 200, 220, "cup" },
        },
    },

    -- 7 --------------------------------------------------------------
    -- Bell tower: a dog on the yard side, a watch walking the whole
    -- perimeter, and the bell itself sitting in the light.
    {
        name = "The Bell Tower",
        sub = "Do not wake the bell.",
        song = "GAOL", par = 110,
        sx = 24, sy = 220, ex = 376, ey = 40,
        boxes = {
            { 170, 90, 60, 60, "tower" },
            { 58, 50, 36, 24, "crate" },
            { 300, 50, 36, 24, "crate" },
            { 58, 178, 36, 24, "crate" },
            { 300, 178, 36, 24, "crate" },
        },
        lamps = {
            { 200, 54, 64, true }, { 200, 208, 64, true }, { 46, 124, 54 },
        },
        guards = {
            { rt = { 126, 80, 284, 80, 284, 166, 126, 166 }, cone = 106 },
        },
        dogs = { { rt = { 210, 216, 280, 216, 280, 172, 246, 172 } } },
        loot = {
            { 128, 62, "bell" }, { 268, 202, "coin" }, { 372, 124, "cup" },
        },
    },

    -- 8 --------------------------------------------------------------
    -- The gaol: three parallel corridors, three keepers pacing them,
    -- and the way through is a serpentine you can only walk in the
    -- shadow each wall throws.
    {
        name = "The Gaol",
        sub = "Three keepers and a very long aisle.",
        song = "GAOL", par = 120,
        sx = 24, sy = 220, ex = 376, ey = 40,
        boxes = {
            -- cell dividers above and below one long aisle: the aisle
            -- is where the lanterns are, the cells are where you are
            { 60, 34, 18, 92, "wall" },
            { 60, 172, 18, 54, "wall" },
            { 168, 34, 18, 92, "wall" },
            { 168, 172, 18, 54, "wall" },
            { 276, 34, 18, 92, "wall" },
            { 276, 172, 18, 54, "wall" },
            { 110, 138, 34, 22, "crate" },
            { 222, 138, 34, 22, "crate" },
        },
        lamps = {
            { 200, 44, 58 }, { 200, 152, 56 },
            { 38, 206, 52, true }, { 362, 206, 52, true },
        },
        guards = {
            { rt = { 50, 148, 350, 148 }, cone = 96 },
            { rt = { 240, 124, 240, 60, 110, 60, 110, 124 }, cone = 96 },
            { rt = { 200, 202 }, cone = 100, spread = 1.0 },
        },
        loot = {
            { 30, 100, "key" }, { 124, 198, "coin" }, { 366, 200, "cup" },
        },
    },

    -- 9 --------------------------------------------------------------
    -- Chapel yard: everything at once. Two watchmen, the dog on the
    -- wall walk, the drunk cutting across the graves, three braziers
    -- you can smother.
    {
        name = "Chapel Yard",
        sub = "Everything the town has, at once.",
        song = "GAOL", par = 130,
        sx = 24, sy = 220, ex = 376, ey = 38,
        boxes = {
            { 80, 60, 50, 28, "tomb" },
            { 180, 60, 50, 28, "tomb" },
            { 280, 60, 50, 28, "tomb" },
            { 80, 150, 50, 28, "tomb" },
            { 180, 150, 50, 28, "tomb" },
            { 280, 150, 50, 28, "tomb" },
        },
        lamps = {
            { 56, 120, 58, true }, { 200, 120, 60, true },
            { 348, 120, 58, true }, { 200, 36, 54 },
        },
        guards = {
            { rt = { 80, 112, 330, 112 }, cone = 104 },
            { rt = { 330, 196, 110, 196 }, cone = 104 },
        },
        dogs = { { rt = { 40, 44, 296, 44 } } },
        drunks = { { rt = { 200, 224, 200, 100 } } },
        loot = {
            { 152, 122, "cup" }, { 248, 202, "candle" }, { 372, 62, "coin" },
        },
    },

    -- 10 -------------------------------------------------------------
    -- Ashgrave Manor. The Night Watchman sweeps one long beam down the
    -- length of the hall and the crown sits in it. Four sconces hold
    -- the room up; put them out and the hall belongs to you. Take the
    -- crown and the whole house wakes.
    {
        name = "Ashgrave Manor",
        sub = "The Watchman's beam. And the crown beneath it.",
        song = "MANOR", par = 170, escape = true,
        sx = 24, sy = 220, ex = 376, ey = 40,
        boxes = {
            { 90, 70, 26, 26, "plinth" },
            { 284, 70, 26, 26, "plinth" },
            { 90, 150, 26, 26, "plinth" },
            { 284, 150, 26, 26, "plinth" },
            { 186, 84, 28, 28, "plinth" },
        },
        lamps = {
            { 40, 50, 62, true }, { 360, 50, 62, true },
            { 40, 200, 62, true }, { 360, 200, 62, true },
        },
        guards = {
            { rt = { 66, 122, 334, 122 }, cone = 208, spread = 0.34,
              spd = 25, boss = true },
            { rt = { 110, 214, 320, 214 } },
            { rt = { 290, 50, 90, 50 } },
        },
        loot = {
            { 200, 132, "crown" }, { 40, 132, "coin" }, { 360, 132, "coin" },
        },
    },
}

-- how many heists there are, in one place
Heists.count = #Heists.list

function Heists.get(n)
    return Heists.list[math.max(1, math.min(Heists.count, n))]
end
