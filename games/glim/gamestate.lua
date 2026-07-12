-- Glim: all mutable shared state. G.reset() rebuilds a fresh night.

G = {
    frame = 0, -- global frame count (autopilot cadence, HUD flash)
}

function G.reset()
    G.px, G.py = 200, 170 -- keeper position (feet)
    G.wick = C.WICK_MAX   -- 0..100; the night ends at 0
    G.radius = C.R0       -- lantern radius, crank-trimmed
    G.score = 0           -- fireflies jarred tonight
    G.newBest = false
    G.nightT = 0          -- seconds since nightfall
    G.pulseT = 0          -- flare light remaining
    G.pulseCd = 0
    G.warnT = 0           -- low-wick beep timer
    G.irisT = 1           -- iris-in from black (1 -> 0)
    G.dissT = 0           -- game-over dissolve (0 -> ~0.6)
    G.respT = C.RESP0     -- firefly respawn countdown
    G.flies = {}
    for _ = 1, C.FLY_START do
        G.flies[#G.flies + 1] = Game.newFly()
    end
    G.moths = {}
    for _ = 1, C.MOTH_MIN do
        G.moths[#G.moths + 1] = Game.newMoth()
    end
    G.parts = {}          -- Kit debris particles
end
