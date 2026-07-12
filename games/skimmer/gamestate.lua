-- Skimmer: all mutable shared state. G.reset() boots the pond;
-- G.startRun() begins a flight without breaking the world's stream.

G = {
    frame = 0, -- global frame count (autopilot cadence, HUD blink)
    time = 0,  -- global clock (pond meander, midge bob)
    runs = 0,  -- flights flown this session (smoke tod rotation)
}

function G.reset()
    G.px, G.py = 0, 24     -- dragonfly: lateral, altitude
    G.trim = 1.0           -- crank throttle trim
    G.spd = C.SPD0         -- current forward speed
    G.lives = C.LIVES
    G.score, G.newBest = 0, false
    G.runT = 0             -- s since this flight began
    G.dist = 0             -- world units flown this flight
    G.z0 = Scaler.cam.z    -- cam.z at flight start
    G.invulnT = 0          -- post-dunk grace
    G.wipeT = 0            -- wipe-in remaining (1 -> 0)
    G.dissT = 0            -- game-over dissolve (0 -> ~0.55)
    G.curve = 0            -- this frame's floor bend
    G.todSel, G.tod = 2, 2 -- golden dusk by default
    G.ambient = C.TOD_AMBIENT[2]
    G.safe = 0             -- the guaranteed-open lane (random walk)
    G.obs = {}             -- upcoming reeds/lilies/midges, by z
    G.nextRowZ = Scaler.cam.z + 160
    G.parts = {}           -- Kit splash particles
end

function G.startRun()
    G.px, G.py, G.trim = 0, 24, 1.0
    G.lives = C.LIVES
    G.score, G.newBest = 0, false
    G.runT, G.dist = 0, 0
    G.z0 = Scaler.cam.z
    G.invulnT = 1.2 -- grace through the attract-mode leftovers
    G.wipeT, G.dissT = 1, 0
end
