-- Beacon's headless contract (stripped from the .pdx by the Makefile).
--   lua tools/headless.lua beacon
--   SEED=4 lua tools/headless.lua beacon
--
-- The floors below are not "it ran": they are "the campaign was
-- played through". done=1 only fires after the ending scene, and each
-- of the others proves one of the night mechanics actually happened --
-- hulls turned by the beam, false lights smothered, the lifeboat lit
-- home, and the lamp cranked back to life in the last storm.

return {
    frames = 24000,
    counters = {
        done = 1,             -- the campaign was finished
        nightsCleared = 10,   -- all ten nights, not just survived
        cutscenes = 8,        -- opening, five turns, the lamp, the ending
        saidLines = 44,
        saved = 34,           -- hulls stood off out of the bay
        turned = 30,          -- ... because Light.at put their helm over
        doused = 3,           -- false lights smothered by the beam
        rescues = 2,          -- lifeboats lit out and home (nights 8, 10)
        relit = 1,            -- the lamp cranked back in the storm
        flashes = 1,          -- the lens surge used
        horns = 1,            -- the fog horn used
        saves = 10,           -- datastore commits (one per night cleared)
        musicBars = 40,
        stingers = 30,
    },
}
