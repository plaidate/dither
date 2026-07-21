-- Echo -- a bat in a cave with no light in it. Press A and a call
-- goes out: a growing Light.add on the screen and a reveal front
-- racing down the tunnel at PING_SPD, marking rock as it goes. Then
-- the memory rots and you fly on what is left. See, commit, see.
--
--   config.lua      C: tunables + the ten-cavern campaign
--   gamestate.lua   G: mutable state, the pooled obstacle list
--   cave.lua        Cave: the tube (centre and half-width of z) + spawning
--   sfx.lua         Sfx: four beds, the call, and the returning echo
--   game.lua        Game: ping / memory / collision / campaign
--   story.lua       Tale: seven screenplays and their portraits
--   input.lua       Input: d-pad + crank, and the smoke autopilot
--   draw.lua        Draw: procedural rendering (no image files)

import "lib"

import "config"
import "gamestate"
import "cave"
import "sfx"
import "game"
import "story"
import "input"
import "draw"

playdate.getSystemMenu():addMenuItem("to the map", function()
    if Kit.mode == "play" then
        Kit.setMode("map")
        Music.set(Sfx.DRIP)
    end
end)

Kit.run{
    init = function()
        Scaler.horizon = C.HORIZON
        Scaler.cam.y = C.MID
        Draw.init()
        G.boot()
        Save.use(1)
        Kit.setMode("title")
        Music.set(Sfx.DRIP)
    end,
    extra = function(t)
        t.mode = Kit.mode
        t.cav = G.cavI
        t.place = G.cav.name
        t.lives = G.lives
        t.moths = G.moths
        t.dist = math.floor(G.dist)
        t.stam = string.format("%.2f", G.stam)
        t.lit = string.format("%.2f", G.lit)
        t.unlocked = Save.get("unlocked", 1)
        if G.owl.on then t.owlD = math.floor(G.owl.d) end
        local l = Light.stats()
        t.lights = l.lights
        t.lightMs = l.ms
        local s = Scaler.stats()
        t.sprites = s.sprites
    end,
}
