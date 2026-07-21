-- Prowl -- a cat burgles a sleeping town, ten heists in one night.
--
-- The shade game where darkness is the floor you walk on. Guards carry
-- Light.cone lanterns; every crate, wall and tomb is a Light.wall
-- occluder that throws a real shadow AND the thing you collide with;
-- you are seen exactly when Light.at(cat) > 0 and Light.blocked says a
-- guard has a clear line. The detection meter fills while that is true
-- and drains while it is not, so being clipped by a passing beam is
-- survivable and standing in one is not. At ambient 1 this game does
-- not exist.
--
--   config.lua      C: tunables, with units
--   gamestate.lua   G: mutable state
--   heists.lua      Heists: the ten rooms, as data
--   sfx.lua         Sfx: synth one-shots + six step-sequencer beds
--   story.lua       Tale: seven cutscenes + procedural portraits
--   game.lua        Game: lights, guards, detection, stage flow, saves
--   input.lua       Input: d-pad/B/A/crank + the burgling autopilot
--   draw.lua        Draw: procedural rendering (no image files)

import "lib"

import "config"
import "gamestate"
import "heists"
import "sfx"
import "story"
import "game"
import "input"
import "draw"

playdate.getSystemMenu():addMenuItem("title", function()
    Kit.setMode("title")
end)

Kit.run{
    init = function()
        Draw.init()
        G.reset()
        Save.use(1)
        Game.loadStage(1)     -- the town is alive behind the title card
        Kit.setMode("title")
        Music.set(Sfx.TITLE)
    end,
    extra = function(t)
        t.mode = Kit.mode
        t.stage = G.stage
        t.heist = G.heist and G.heist.name or "-"
        t.lootN = G.lootN .. "/" .. G.lootNeed
        t.det = math.floor(G.det * 100)
        t.totalLoot = G.totalLoot
        local s = Light.stats()
        t.lights = s.lights
        t.walls = s.walls
        t.lightMs = s.ms
    end,
}
