-- Delve -- one lamp, three flares. A side-view descent into a mine
-- where light is a consumable you PLACE: the helmet lamp is a short
-- Light.cone that burns oil and points where you face, and a flare is
-- a Light.add you throw once and never get back. The things down here
-- advance only where Light.at says it is dark, so a burning flare is a
-- wall built out of light -- and a spent one is a wall that falls down.
--
--   config.lua      C: tunables + the ten-depth campaign table
--   gamestate.lua   G: mutable state, pooled
--   level.lua       Level: the shaft generator, its route, its occluders
--   sfx.lua         Sfx: synth effects + five step-sequencer songs
--   story.lua       Tale: seven cutscene screenplays + portraits
--   game.lua        Game: simulation + campaign flow
--   input.lua       Input: d-pad/A/B/crank + the route-following bot
--   draw.lua        Draw: procedural rendering (no image files)

import "lib"

import "config"
import "gamestate"
import "level"
import "sfx"
import "story"
import "game"
import "input"
import "draw"

playdate.getSystemMenu():addMenuItem("pit head", function()
    Game.toTitle()
end)

Kit.run{
    init = function()
        Kit.loadBest()
        Draw.init()
        G.newRun()
        Game.toTitle()
    end,
    extra = function(t)
        t.mode = Kit.mode
        t.depth = G.depth
        t.cleared = G.cleared
        t.oil = math.floor(G.oil or 0)
        t.flares = G.flares
        t.grit = G.grit
        t.floor = G.pj
        t.wp = Input.wp
        t.story = Story.active and 1 or 0
        local s = Light.stats()
        t.lights = s.lights
        t.walls = s.walls
        t.lightMs = s.ms
    end,
}
