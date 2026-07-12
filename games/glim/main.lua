-- Glim -- a firefly-keeper in a walled night garden. The identity
-- game for the Dither shade stack: the lantern is a Light whose
-- radius is the crank-trimmed wick (bright burns fast), fireflies
-- are their own tiny lights, and moths are dark sprites that only
-- stalk while lit -- Light.at gates their AI, so darkness is
-- mechanics, not paint.
--
--   config.lua      C: tunables
--   gamestate.lua   G: mutable state
--   sfx.lua         Sfx: synth effects + the nocturne
--   game.lua        Game: simulation + state machine
--   input.lua       Input: d-pad/crank/B + smoke autopilot
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
        Kit.loadBest()
        Draw.init()
        G.reset()
        Kit.setMode("title")
        Music.set(Sfx.NOCTURNE)
    end,
    extra = function(t)
        t.mode = Kit.mode
        t.wickPct = math.floor(G.wick + 0.5)
        t.flies = #G.flies
        t.moths = #G.moths
        t.best = Kit.best
        local s = Light.stats()
        t.lights = s.lights
        t.lightMs = s.ms
    end,
}
