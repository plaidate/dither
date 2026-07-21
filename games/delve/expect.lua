-- Delve's headless contract (stripped from the pdx by the Makefile).
-- These floors are the proof that the specific mechanic happened, not
-- merely that the run survived:
--   done/depths/bossPhases  the campaign was actually finished
--   flaresThrown/flaresLit  light was spent, and it landed and burned
--   repelled                things in the dark were driven back by it
--   scoutFlares             a flare was thrown ahead into an unlit shaft
--   waded                   the flooded depths were actually crossed
-- (`snuffed`, a flare drowned on landing, is reported but not
-- required: whether one lands in water depends on where the crawlers
-- happen to be standing, so it is not true on every seed.)
--   lanterns/crates/saves   the checkpoint and resupply economy ran
--   cutscenes/saidLines     all seven scenes played through
-- Measured floors across seeds 1-12 are roughly 2x these numbers; the
-- whole campaign finishes around frame 8500-9400, so `frames` carries
-- better than 2x headroom.
return {
    frames = 20000,
    counters = {
        done = 1,
        depths = 10,
        bossPhases = 3,
        cutscenes = 7,
        saidLines = 40,
        lanterns = 16,
        crates = 6,
        saves = 20,
        flaresThrown = 32,
        flaresLit = 28,
        repelled = 40,
        scoutFlares = 5,
        waded = 3,
        clingers = 4,
        rockfalls = 4,
        ropeGrabs = 3,
        musicBars = 120,
        stingers = 14,
    },
}
