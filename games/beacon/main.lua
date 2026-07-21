-- Beacon -- the keeper of Vesper Rock. The crank is a lighthouse: it
-- turns a long Light.cone out over a black bay, the shutter trades the
-- beam's width against its reach, and the night's fog eats the far end
-- of it. Every hull out there steers on Light.at(ship) -- unlit, her
-- master holds his course onto the reef; lit, he puts his helm over,
-- and how fast he answers is exactly how brightly you have him.
--
-- Ten nights, escalating: deep hulls that only answer the lit core, a
-- collier whose master wants a HELD beam, a fog bank that halves your
-- reach, wreckers showing a false light you have to smother, a squall
-- that fights the mechanism, a lifeboat you must light out and home,
-- and a last night where the lamp itself dies and you crank it back.
--
--   config.lua      C: tunables
--   nights.lua      Nights: the ten-night campaign, as data
--   gamestate.lua   G: mutable state + the entity pools
--   sfx.lua         Sfx: synth effects and the four beds
--   story.lua       Tale: the eight cutscenes and their portraits
--   game.lua        Game: optics, hulls, wreckers, the state machine
--   input.lua       Input: crank/shutter/A/B + the smoke autopilot
--   draw.lua        Draw: procedural rendering (no image files)

import "lib"

import "config"
import "nights"
import "gamestate"
import "sfx"
import "story"
import "game"
import "input"
import "draw"

playdate.getSystemMenu():addMenuItem("log book", function()
    Game.enterTitle()
end)

Kit.run{
    init = function()
        Kit.loadBest()
        Draw.init()
        G.newGame()
        Game.enterTitle()
    end,
    extra = function(t)
        t.mode = Kit.mode
        t.night = G.night
        t.cleared = G.cleared
        t.oil = math.floor(G.oil + 0.5)
        t.fog = math.floor(G.fog * 100)
        t.reach = math.floor(G.reach + 0.5)
        t.spread = string.format("%.2f", G.spread)
        t.dir = string.format("%.2f", G.dir)
        t.tSaved = G.totalSaved
        t.tLost = G.totalLost
        t.story = Story.active and "on" or "off"
        local s = Light.stats()
        t.lights, t.walls, t.lightMs = s.lights, s.walls, s.ms
    end,
}
