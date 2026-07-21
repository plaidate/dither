-- Prowl: the headless contract. `lua tools/headless.lua prowl` runs the
-- whole campaign with the autopilot at the wheel; these floors must
-- hold at SEED=1..5. `done = 1` means the bot actually took the Ash
-- crown and sat through the credits -- surviving is not evidence.
--
-- The floors are set near half the worst observed run, so a real
-- regression trips them and ordinary seed variance does not. The
-- slowest of ten seeds finished around frame 35500, hence the budget.
return {
    frames = 48000,
    counters = {
        done = 1,             -- the campaign was completed
        stagesCleared = 10,   -- all ten heists, drainpipe reached
        cutscenes = 6,        -- opening, four turns, gate, ending
        saidLines = 26,
        saves = 11,           -- one commit per cleared heist, plus new game

        -- the mechanic, proved:
        loot = 28,            -- 30 pieces exist; retries add more
        doused = 15,          -- wicks pinched out for good
        pebbles = 8,          -- decoys thrown
        lured = 3,            -- ... that actually pulled a cone off us
        sighted = 5,          -- a lantern found the cat
        evaded = 3,           -- ... and the meter drained back to zero
        alarms = 1,           -- the manor woke when the crown moved
        barks = 2,            -- the mastiff heard something

        -- the soundtrack ran the whole time
        stingers = 45,
        musicBars = 300,
    },
}
