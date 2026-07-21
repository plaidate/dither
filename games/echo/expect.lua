-- Echo: the headless contract (stripped from the .pdx by the Makefile).
--
--   lua tools/headless.lua echo
--   SEED=4 lua tools/headless.lua echo
--
-- The floors below are the campaign, not a survival test: `done` only
-- ticks after the ending scene, and cavernsCleared = 10 means the bot
-- flew every one of them. The rest prove the MECHANIC rather than the
-- progress -- pings/reveals/echoes are the ping loop, moths the
-- economy that pays for it, answers the call-and-response cavern,
-- reflections the still water, falls the cracked ceiling.
return {
    frames = 26000,
    counters = {
        done = 1,
        cavernsCleared = 10,
        cutscenes = 6,
        saidLines = 30,
        flights = 10,
        pings = 90,
        reveals = 700,
        echoes = 220,
        moths = 14,
        answers = 6,
        reflections = 14,
        falls = 5,
        calls = 14,
        owlCries = 3,
        musicBars = 150,
        stingers = 14,
        saves = 10,
    },
}
