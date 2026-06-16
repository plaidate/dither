-- Sprint for Playdate -- an original top-down racer in the spirit of Super
-- Sprint. The crank is the wheel, A the throttle, B the brake. Built on the
-- CC0 PySprint assets (github.com/salem-ok/PySprint), converted to 1-bit by
-- convert.py; all game logic here is written from scratch.
--
--   config.lua        C: tunables (incl. the logical->screen scale)
--   track1_data.lua   Track1: gate/finish geometry (generated)
--   track1_mask.lua   Track1Mask: baked drivable grid (generated)
--   track.lua         Track: racing line, projection, wall collision
--   gamestate.lua     G: shared state
--   sfx.lua           Sfx: synth effects
--   game.lua          Game: car physics, drones, laps, standings
--   input.lua         Input: crank/pedals + smoke autopilot
--   draw.lua          Draw: rendering

import "lib"

import "config"
import "track1_data"
import "track2_data"
import "track3_data"
import "track4_data"
import "track5_data"
import "track6_data"
import "track7_data"
import "track8_data"
import "track1_mask"
import "track2_mask"
import "track3_mask"
import "track4_mask"
import "track5_mask"
import "track6_mask"
import "track7_mask"
import "track8_mask"
import "track"
import "gamestate"
import "sfx"
import "game"
import "input"
import "draw"

local function startRace()
    Game.reset(C.LAPS_OPTIONS[G.menuSel])
    G.state = "play"
end

local function tick()
    G.frame = G.frame + 1
    Util.runPending(C.DT)

    local turn, accel, brake, start = Input.gather()

    if G.state == "title" then
        if playdate.buttonJustPressed(playdate.kButtonLeft)
            or playdate.buttonJustPressed(playdate.kButtonRight) then
            G.menuSel = (G.menuSel % #C.LAPS_OPTIONS) + 1
        end
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            G.trackSel = (G.trackSel - 2) % Track.count + 1
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            G.trackSel = G.trackSel % Track.count + 1
        end
        Draw.title()
        if start then startRace() end
    elseif G.state == "play" then
        Game.update(turn, accel, brake, start)
        if G.state == "over" then Draw.over() else Draw.play() end
    elseif G.state == "over" then
        G.overT = G.overT + C.DT
        Draw.over()
        if start and G.overT > 0.8 then G.state = "title" end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.extra = function(t)
    t.state = G.state
    if G.player then
        t.lap = G.player.lap
        t.place = G.place
        t.speed = string.format("%.1f", G.player.speed)
    end
end

playdate.getSystemMenu():addMenuItem("restart", function()
    G.state = "title"
end)

Game.loadRecords()
Track.load(G.trackSel)
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)
