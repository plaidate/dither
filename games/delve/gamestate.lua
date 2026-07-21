-- Delve: all mutable shared state. G.newRun() starts a campaign,
-- Game.enterDepth() refills the per-depth half. The reuse pools
-- (G.srcs, G.flying, G.burning, G.parts) live here; the only churn in
-- the update path is Kit debris and one small table per flare thrown.

G = {
    frame = 0,        -- global frame count (HUD flash, AI stagger)
}

-- a whole campaign: what a save slot holds
function G.newRun()
    G.depth = 1           -- the depth being delved, 1..C.LAST
    G.cleared = 0         -- depths finished
    G.deaths = 0
    G.runT = 0            -- seconds delved this campaign
    G.flaresSpent = 0
    G.lanternsLit = 0
    G.slot = G.slot or 1
end

-- everything the shaft owns; Game.startDepth calls this after Level
function G.newDepth(L)
    G.L = L
    G.depthT = 0
    G.px, G.py = L.spawnX, Level.top(1)
    G.vx, G.vy = 0, 0
    G.face = 1            -- 1 right, -1 left
    G.pitch = C.PITCH_HOME
    G.onGround = true
    G.coyote = 0
    G.pj = 1              -- slab the delver last stood on (latched)
    G.fallFrom = G.py
    G.onRope = nil
    G.jumpHeld = false
    G.lamp = not L.spec.noLamp
    G.oil = G.lamp and C.OIL_MAX or 0
    G.grit = C.GRIT_MAX
    G.invuln = 0
    G.hurtFlash = 0
    G.flareCd = 0
    G.flares = L.spec.noLamp and 2 or C.FLARE_MAX
    G.wet = false
    G.camy = 0
    G.checkX, G.checkY = G.px, G.py
    G.exited = false
    G.irisT = 1           -- iris-in from black at the top of a depth
    -- pooled dynamics
    for i = #G.flying, 1, -1 do G.flying[i] = nil end
    for i = #G.burning, 1, -1 do G.burning[i] = nil end
    for i = #G.parts, 1, -1 do G.parts[i] = nil end
    G.nsrc = 0
    G.boss = nil
end

G.flying = {}    -- flares in the air: {x, y, vx, vy}
G.burning = {}   -- flares on the ground: {x, y, t, wet}
G.parts = {}     -- Kit debris
G.srcs = {}      -- this frame's light sources, world space, pooled:
                 -- {x, y, core} -- Game.illum counts cores over a point
