-- Shared state.

G = {
    state = "title", -- "title" | "play" | "over"
    frame = 0,
    laps = 3,
    menuSel = 1,     -- index into C.LAPS_OPTIONS
    trackSel = 1,    -- 1..8

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

    overT = 0,
}
