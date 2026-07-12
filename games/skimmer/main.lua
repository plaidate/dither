-- Skimmer -- a dragonfly flying fast and low over a pond at golden
-- dusk, into the screen. The super-scaler proof game for Dither:
-- distance is scale AND tone (mip ladders + depth haze), the water
-- is a striped perspective floor with a meandering bend, and the
-- shadow on the water is how you judge your height over the lilies.
--
--   config.lua      C: tunables
--   gamestate.lua   G: mutable state
--   sfx.lua         Sfx: synth effects + the airborne loop
--   game.lua        Game: stream/spawn/collide + state machine
--   input.lua       Input: d-pad/crank + smoke autopilot
--   draw.lua        Draw: procedural rendering (no image files)

import "lib"

import "config"
import "gamestate"
import "sfx"
import "game"
import "input"
import "draw"

playdate.getSystemMenu():addMenuItem("restart", function()
    Kit.setMode("title")
end)

Kit.run{
    init = function()
        Scaler.horizon = C.HORIZON
        Scaler.cam.y = C.CAMY
        Kit.loadBest()
        Draw.init()
        G.reset()
        Kit.setMode("title")
        Music.set(Sfx.LOOP)
    end,
    extra = function(t)
        t.mode = Kit.mode
        t.tod = C.TOD_NAMES[G.tod]
        t.score = G.score
        t.best = Kit.best
        t.lives = G.lives
        t.spd = math.floor(G.spd + 0.5)
        t.trim = string.format("%.2f", G.trim)
        local s = Scaler.stats()
        t.sprites = s.sprites
        t.fills = s.fills
    end,
}
