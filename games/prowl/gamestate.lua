-- Prowl: all mutable shared state. G.reset() starts a campaign,
-- Game.loadStage(n) rebuilds the room. Everything a frame touches is
-- allocated here or at stage load -- update and draw allocate nothing.

G = {
    frame = 0,      -- global frame count (autopilot cadence, blinks)
}

function G.reset()
    G.stage = 1              -- 1..Heists.count
    G.heist = nil            -- the active heist table (data, read-only)
    G.slot = 1               -- save slot in use
    G.sel = 1                -- menu / slot cursor
    G.menuRows = {}          -- current menu labels (autopilot reads it)
    G.totalLoot = 0          -- pieces lifted this campaign
    G.totalCaught = 0        -- collars this campaign
    G.totalDoused = 0        -- wicks pinched this campaign
    G.doneOnce = false       -- the campaign-complete latch
    G.parts = {}             -- Kit debris
    G.pings = {}             -- noise rings (visual only)
    G.peb = { live = false, x = 0, y = 0, tx = 0, ty = 0, t = 0 }
    G.boxes, G.lamps, G.loot = {}, {}, {}
    G.guards, G.dogs, G.drunks = {}, {}, {}
    G.walk = {}              -- flow-field walkability, rebuilt per stage
    G.clearT = 0             -- summary card timer
    G.stageT = 0
    G.det = 0
    G.lootN, G.lootNeed = 0, 0
end

-- per-heist state: called by Game.loadStage after the room is built
function G.enterStage()
    G.px, G.py = G.heist.sx, G.heist.sy   -- the cat, at the drain
    G.vx, G.vy = 0, 0
    G.fx, G.fy = 1, 0        -- facing (unit); the pebble goes this way
    G.creep = false
    G.det = 0                -- the detection meter, 0..1
    G.detPeak = 0            -- highest since the last time it hit 0
    G.stageT = 0             -- seconds on this attempt
    G.lootN = 0              -- pieces lifted here
    G.pebbles = C.PEBBLE_MAX
    G.throwR = C.THROW_0     -- crank-dialled pebble distance
    G.noiseT = 0             -- footfall timer
    G.pebT = 0               -- pebble cooldown
    G.douseT = 0             -- paw-on-the-lamp timer
    G.douseL = nil           -- the lamp being smothered
    G.alarm = false          -- the house is awake (finale)
    G.irisT = 1              -- iris-in from black
    G.graceT = 1.2           -- s of "just over the wall" invulnerability
    G.seenT = 0              -- s since a guard last had eyes on us
    G.peb.live = false
    for i = #G.pings, 1, -1 do G.pings[i] = nil end
    for i = #G.parts, 1, -1 do G.parts[i] = nil end
end
