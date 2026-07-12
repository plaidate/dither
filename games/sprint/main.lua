-- Sprint for Playdate -- an original top-down racer in the spirit of Super
-- Sprint. The crank is the wheel, A the throttle, B the brake. Built on the
-- CC0 PySprint assets (github.com/salem-ok/PySprint), converted to 1-bit by
-- convert.py; all game logic here is written from scratch.
--
--   config.lua        C: tunables (incl. the logical->screen scale)
--   trackN_data.lua   TrackN: gate/finish geometry (generated, tracks 1-8)
--   trackN_mask.lua   TrackNMask: baked drivable grid (generated)
--   track.lua         Track: racing line, projection, wall collision
--   gamestate.lua     G: shared state
--   sfx.lua           Sfx: synth effects + the title music loop
--   game.lua          Game: car physics, drones, laps, standings
--   input.lua         Input: crank/pedals + smoke autopilot
--   draw.lua          Draw: rendering (incl. time-of-day lighting)
--
-- Runs on the Kit.run cabinet. Modes (Kit.mode): title -> toRace (iris
-- closes on the player car) -> grid (iris opens on the grid) -> play ->
-- finish (dissolve out) -> over (results dissolve in).

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
    if Harness.enabled then
        -- smoke rotation: night first, then dusk, then day
        G.races = G.races + 1
        G.todSel = 3 - (G.races - 1) % 3
    end
    Game.reset(C.LAPS_OPTIONS[G.menuSel])
    G.tod = G.todSel
    G.ambient = C.TOD_AMBIENT[G.tod]
    Music.stop() -- from here the engines are the soundtrack
    Kit.setMode("toRace", C.FADE_T)
end

local function titleTick()
    if playdate.buttonJustPressed(playdate.kButtonLeft)
        or playdate.buttonJustPressed(playdate.kButtonRight) then
        G.menuSel = (G.menuSel % #C.LAPS_OPTIONS) + 1
    end
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        G.trackSel = (G.trackSel - 2) % Track.count + 1
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        G.trackSel = G.trackSel % Track.count + 1
    end
    if playdate.buttonJustPressed(playdate.kButtonB) then
        G.todSel = G.todSel % #C.TOD_NAMES + 1
    end
    if playdate.buttonJustPressed(playdate.kButtonA)
        or (Harness.enabled and Input.start) then
        startRace()
    end
end

-- cabinet update: Kit.run polls Input, ticks Kit.modeT, calls this,
-- then Draw.frame(). The race simulation itself lives in Game.race.
function Game.update(dt)
    G.frame = G.frame + 1
    Music.update(dt)
    local m = Kit.mode
    if m == "title" then
        titleTick()
    elseif m == "toRace" then
        if Kit.modeT <= 0 then Kit.setMode("grid", C.FADE_T) end
    elseif m == "grid" then
        if Kit.modeT <= 0 then Kit.setMode("play") end
    elseif m == "play" then
        Game.race(Input.turn, Input.accel, Input.brake, Input.start)
    elseif m == "finish" then
        if Kit.modeT <= 0 then Kit.setMode("over", C.OVER_T) end
    elseif m == "over" then
        if Input.start and Kit.modeT <= 0 then
            Kit.setMode("title")
            Music.set(Sfx.TITLE)
        end
    end
end

Kit.run{
    init = function()
        Game.loadRecords()
        Track.load(G.trackSel)
        Music.set(Sfx.TITLE)
        playdate.getSystemMenu():addMenuItem("restart", function()
            Kit.setMode("title")
            Music.set(Sfx.TITLE)
        end)
    end,
    extra = function(t)
        t.state = Kit.mode
        t.tod = C.TOD_NAMES[G.tod]
        t.ambient = G.ambient
        t.lights = Light.stats().lights
        if G.player then
            t.lap = G.player.lap
            t.place = G.place
            t.speed = string.format("%.1f", G.player.speed)
        end
    end,
}
