-- Shared state. The mode machine lives in Kit.mode ("title" ->
-- "toRace" -> "grid" -> "play" -> "finish" -> "over").

G = {
    frame = 0,
    laps = 3,
    menuSel = 1,     -- index into C.LAPS_OPTIONS
    trackSel = 1,    -- 1..8
    todSel = 1,      -- title selector: index into C.TOD_NAMES
    tod = 1,         -- time of day of the race being run
    ambient = 1,     -- C.TOD_AMBIENT[G.tod], read by the lighting
    races = 0,       -- races started (drives the smoke tod rotation)

    cars = nil,      -- { player, drone1.. }; [1] is the player
    player = nil,

    countdown = 0,   -- seconds left of 3..2..1
    goFlash = 0,     -- seconds the "GO!" stays up
    raceFrame = 0,   -- frames since GO (lap timing)
    lapStartFrame = 0,

    place = 1,       -- player's current standing (1..4)
    lastLap = nil,   -- seconds of the last completed lap
    bestLap = nil,   -- best ever (persisted)
    records = nil,
}
