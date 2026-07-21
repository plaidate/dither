-- Dither engine self-test. Drives every core module against
-- tools/sdkstub.lua and asserts the contracts the games rely on —
-- especially the ones a game would only discover at 3am: ramp
-- coverage, Light.at agreeing with the compositor's own radii, cone
-- angles, wall occlusion, the depth queue's far-to-near order, and
-- the JSON round trip that eats numeric save keys.
--
--   lua tools/coretest.lua
--
-- Run it after ANY change to core/. It is the cheap gate; the
-- Simulator is still the last word.

local root = arg[0]:gsub("tools/coretest%.lua$", "")
if root == arg[0] then root = "./" end

STUB_ROOT, STUB_GAME = root, nil
dofile(root .. "tools/sdkstub.lua")

SMOKE_BUILD = true
SMOKE_SEED = 1
SMOKE_SHOT_PATH = nil

import("lib")

-- ---- tiny harness ---------------------------------------------------------

local pass, fail = 0, 0

local function ok(cond, what)
    if cond then
        pass = pass + 1
    else
        fail = fail + 1
        print("  FAIL: " .. what)
    end
end

local function near(a, b, eps, what)
    ok(math.abs(a - b) <= (eps or 1e-6), what ..
        " (got " .. tostring(a) .. ", want " .. tostring(b) .. ")")
end

local function runs(fn, what)
    local good, err = pcall(fn)
    ok(good, what .. (good and "" or ": " .. tostring(err)))
end

-- ---- Shade ----------------------------------------------------------------

ok(Shade.quant(-3) == 0, "quant clamps low")
ok(Shade.quant(99) == 16, "quant clamps high")
ok(Shade.quant(4.6) == 5, "quant rounds")

local bay = Shade.ramp("bayer")
local function blackBits(rows)
    local n = 0
    for y = 1, 8 do
        for x = 0, 7 do
            if rows[y] & (1 << x) == 0 then n = n + 1 end
        end
    end
    return n
end
ok(blackBits(bay[0]) == 0, "ramp level 0 is white")
ok(blackBits(bay[16]) == 64, "ramp level 16 is black")
ok(blackBits(bay[8]) == 32, "ramp level 8 is half coverage")
ok(blackBits(bay[4]) == 16, "ramp level 4 is quarter coverage")
runs(function()
    Shade.fill(0, 0, 10, 10, 6)
    Shade.disc(20, 20, 8, 9)
    Shade.vgrad(0, 0, 400, 60, 0, 12)
    Shade.hgrad(0, 0, 400, 60, 12, 0)
    Shade.over(7)
    Shade.wash(3)
end, "Shade draw calls")

-- ---- Light ----------------------------------------------------------------

Light.begin(1)
ok(Light.at(0, 0) == 1, "ambient 1 is a no-op")
Light.add(100, 100, 40)
ok(Light.stats().lights == 0, "ambient 1 ignores lights")

Light.begin(0.1)
Light.add(100, 100, 40, 0.5)   -- lit core r 20, dim out to r 40
ok(Light.at(100, 100) == 1, "inside the lit core")
near(Light.at(130, 100), 0.5, 1e-9, "in the dim ring")
ok(Light.at(300, 100) == 0, "outside every light is dark")
ok(Light.stats().lights == 1, "stats count lights")

-- a cone only lights what it points at
Light.begin(0.1)
Light.cone(200, 120, 80, 0, 0.8, 0.5)   -- pointing +x, 0.8 rad wide
ok(Light.at(230, 120) == 1, "cone lights straight ahead")
ok(Light.at(170, 120) == 0, "cone does not light behind itself")
ok(Light.at(200, 190) == 0, "cone does not light off-axis")

-- walls block both the pixels and the logic
Light.begin(0.1)
Light.add(100, 120, 100, 0.5)
Light.wall(140, 60, 140, 180)           -- a wall 40px to the right
ok(Light.blocked(100, 120, 180, 120), "blocked through a wall")
ok(not Light.blocked(100, 120, 120, 120), "not blocked short of it")
ok(Light.at(180, 120) == 0, "the shadow behind the wall is dark")
ok(Light.at(120, 120) == 1, "in front of the wall is lit")
ok(Light.stats().walls == 1, "stats count walls")
Light.box(200, 60, 30, 30)
ok(Light.stats().walls == 5, "box adds four sides")
runs(Light.finish, "Light.finish composites with cones and walls")

-- a LONG wall crossing a small light: both endpoints are far outside
-- its reach, so an endpoint-only test would skip the shadow in the
-- pixels while Light.at still honoured it. Regression guard.
Light.begin(0.1)
Light.add(200, 120, 40, 0.5)
Light.wall(0, 100, 400, 100)
ok(Light.at(200, 60) == 0, "a long crossing wall shadows the logic")
Light.finish()
ok(Light.stats().fills > 2, "... and the compositor carves it too")

-- Light.at must agree with the compositor either side of a band edge
Light.begin(0.6)                        -- dusk: one darkness band
Light.add(50, 50, 30)
ok(Light.at(50, 50) == 1, "dusk core still fully lit")
ok(Light.at(200, 200) > 0, "dusk floor is dim, not black")
Light.begin(0)
Light.add(50, 50, 30)
ok(Light.at(200, 200) == 0, "midnight floor is black")

-- SHADOW POLARITY. This bug escaped twice, because Light.at cannot see
-- it and a screenshot only shows it if you measure: a shadow must be
-- painted in the OPPOSITE colour to the light shape it follows, or it
-- renders at the wrong band — same-colour-as-its-shape means a shadow
-- inside a light's own disc comes out fully lit. Instrument the stub
-- and assert the pairing directly.
do
    local g = playdate.graphics
    local realColor, realPoly, realMode = g.setColor, g.fillPolygon, g.setImageDrawMode
    local ev, colour = {}, "black"
    -- a disc light draws its shape as a white image blit (silent) or a
    -- FillBlack carve (loud); every fillPolygon here is a shadow
    g.setColor = function(c)
        colour = (c == g.kColorWhite) and "white" or "black"
    end
    g.setImageDrawMode = function(m)
        if m == g.kDrawModeFillBlack then ev[#ev + 1] = "shape:black" end
    end
    g.fillPolygon = function() ev[#ev + 1] = "shadow:" .. colour end

    Light.begin(0.1)
    Light.add(200, 120, 120, 0.5)
    Light.wall(140, 50, 140, 190)
    Light.finish()

    g.setColor, g.fillPolygon, g.setImageDrawMode = realColor, realPoly, realMode

    local paired, sawReach = true, false
    for i = 1, #ev do
        if ev[i] == "shape:black" and ev[i + 1] ~= "shadow:white" then
            paired = false
        end
        if ev[i] == "shadow:black" then sawReach = true end
    end
    ok(sawReach, "a light's reach carries black shadows")
    ok(paired, "a carved shape restores its shadow in white")
end

-- ---- Cast / Fade / Para ---------------------------------------------------

local img = playdate.graphics.image.new(16, 16)
runs(function()
    Cast.blob(50, 50, 20, 8)
    Cast.silhouette(img, 10, 10, 12)
    Cast.silhouette(img, 10, 10, 0)
end, "Cast draw calls")

runs(function()
    Fade.dissolve(0)
    Fade.dissolve(0.5)
    Fade.dissolve(1)
    Fade.iris(200, 120, 0.4)
    Fade.iris(200, 120, 1)
    Fade.wipe("left", 0.3)
    Fade.wipe("down", 0.8)
    Fade.haze(40, 80, 5)
end, "Fade draw calls")

runs(function()
    Para.clear()
    Para.layer(img, 0.2, 8, 40)
    Para.layer(function(ox) return ox end, 0.5, 0)
    Para.draw(120)
end, "Para layers and draws")

-- ---- Scaler ---------------------------------------------------------------

Scaler.cam.x, Scaler.cam.y, Scaler.cam.z = 0, 40, 0
Scaler.f, Scaler.horizon, Scaler.cx = 180, 120, 200
ok(Scaler.project(0, 0, -5) == nil, "behind the camera does not project")
local sx, sy, s = Scaler.project(0, 0, 180)
near(s, 1, 1e-9, "scale is f/dz")
near(sx, 200, 1e-9, "on-axis projects to cx")
near(sy, 160, 1e-9, "a ground point sits below the horizon")
local _, sy2 = Scaler.project(0, 40, 180)
near(sy2, 120, 1e-9, "a camera-height point sits on the horizon")

local lad = Scaler.ladderFromFn(function() end, 16, 16, 4, 2)
ok(lad.n == 4, "ladder has its steps")
ok(lad.ws[1] < lad.ws[4], "ladder steps grow")
near(lad.step, 0.5, 1e-9, "ladder step size")

-- the depth queue must draw far to near
local order = {}
local function drawer(name)
    return function() order[#order + 1] = name end
end
Scaler.clear()
Scaler.queue(drawer("near"), 0, 0, 40)
Scaler.queue(drawer("far"), 0, 0, 400)
Scaler.queue(drawer("mid"), 0, 0, 200)
Scaler.flush()
ok(order[1] == "far" and order[2] == "mid" and order[3] == "near",
    "depth queue draws far to near")
ok(Scaler.stats().sprites == 3, "queue stats")

local haze = Scaler.linearHaze(100, 300, 12)
near(haze(50), 0, 1e-9, "no haze up close")
near(haze(300), 12, 1e-9, "full haze at the far plane")
near(haze(200), 6, 1e-9, "haze is linear between")

runs(function()
    Scaler.floor({ stripes = { 4, 7 }, size = 64, band = 2, curve = 0.2 })
end, "Scaler.floor runs")
ok(Scaler.stats().fills > 0, "floor lays bands")
ok(type(Scaler.bendAt(200)) == "number", "bendAt reads back")

-- ---- Save -----------------------------------------------------------------

Save.wipe()
ok(Save.any() == nil, "no slots to start")
Save.use(2)
Save.reset({ name = "Test", place = "Cliff Road", pct = 0 })
Save.set("stage", 3)
Save.flag("metKeeper", true)
Save.unlock(4)
Save.data.list = { 10, 20, 30 }
Save.data.byName = { alpha = 1, beta = 2 }
Save.meta.pct = 42
Save.commit()

Save.data, Save.meta = {}, {}
ok(Save.load(2), "slot 2 loads back")
ok(Save.get("stage") == 3, "a scalar survives")
ok(Save.flag("metKeeper"), "a flag survives")
ok(Save.data.unlocked == 4, "unlock survives")
ok(#Save.data.list == 3 and Save.data.list[2] == 20, "an array survives")
ok(Save.data.byName.beta == 2, "a string-keyed table survives")
ok(Save.meta.place == "Cliff Road", "the meta card survives")
ok(type(Save.meta.time) == "number", "meta time is an integer stamp")
Save.unlock(2)
ok(Save.data.unlocked == 4, "unlock never walks backwards")
local sum = Save.summary(2)
ok(sum and sum.pct == 42, "summary reads without disturbing the game")
ok(Save.any() == 2, "any() finds the used slot")
ok(not Save.exists(1), "an empty slot stays empty")

-- the JSON trap this stub exists to reproduce
Save.use(3)
Save.reset({})
Save.data.rooms = { [1] = "a", [7] = "b" }   -- holey: comes back a dict
Save.commit()
Save.load(3)
ok(Save.data.rooms["7"] == "b",
    "holey arrays come back string-keyed (documented JSON trap)")
Save.wipe()

-- ---- Story ----------------------------------------------------------------

local finished, walked = false, 0
Story.play(function()
    fade(1, 0.1)
    say("Keeper", "The lamp is out.")
    act(function()
        walked = walked + 1
        return walked >= 3
    end)
    beat()
    fade(0, 0.1)
end, { onDone = function() finished = true end })
ok(Story.active, "the scene is running")
local guard = 0
while Story.active and guard < 2000 do
    Story.update(1 / 30)
    Util.runPending(1 / 30)
    guard = guard + 1
end
ok(finished, "the scene ran to completion")
ok(walked >= 3, "act() blocked until it returned true")
ok(Harness.counters.cutscenes == 1, "cutscene counted")
ok(Harness.counters.saidLines == 1, "line counted")
near(Story.veil, 0, 1e-9, "the veil came back down")
ok(_G.say == nil, "primitives are uninstalled after the scene")

-- a skipped scene must not strand the screen behind the veil
Story.play(function()
    fade(1, 0.2)
    say("Keeper", "You will not hear this.")
    wait(99)
end)
Story.update(1 / 30)
Story.update(1 / 30, false, true)   -- B
ok(not Story.active, "B skips a skippable scene")
near(Story.veil, 0, 1e-9, "the skip clears the veil")

-- a broken scene must report, not wedge
Story.play(function()
    error("boom")
end)
Story.update(1 / 30)
ok(not Story.active, "a broken scene bails out")
ok(Harness.counters.storyErr ~= nil, "the error is reported")
runs(Story.draw, "Story.draw is safe when idle")

-- ---- Music ----------------------------------------------------------------

local flat = {
    bpm = 120,
    bass = { 48, 0, 0, 0, 48, 0, 0, 0, 48, 0, 0, 0, 48, 0, 0, 0 },
    hat = { 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
}
Harness.counters.musicBars = 0
Music.set(flat)
ok(Music.playing(), "the flat track plays")
for _ = 1, 120 do Music.update(1 / 30) end
ok(Harness.counters.musicBars >= 2, "the flat track wraps bars")

local song = {
    bpm = 120, len = 16,
    patterns = {
        A = { bass = { 48, 0, 0, 0, 48, 0, 0, 0, 48, 0, 0, 0, 48, 0, 0, 0 } },
        B = { lead = { 72, 0, 76, 0, 79, 0, 76, 0, 72, 0, 0, 0, 0, 0, 0, 0 } },
    },
    order = { "A", "B", "A" },
}
Harness.counters.musicBars = 0
Music.set(song)
for _ = 1, 240 do Music.update(1 / 30) end
ok(Harness.counters.musicBars >= 3, "the song walks its order")
Harness.counters.stingers = 0
Music.sting({ 72, 76, 79 })
for _ = 1, 20 do Util.runPending(1 / 30) end
ok(Harness.counters.stingers == 1, "the sting is counted")
Music.stop()
ok(not Music.playing(), "stop silences the bed")

-- ---- Kit ------------------------------------------------------------------

Kit.best = 0
ok(Kit.saveBest(10), "a first score is a record")
ok(not Kit.saveBest(5), "a worse score is not")
ok(Kit.loadBest() == 10, "best round-trips")
Kit.setMode("play", 1.5)
ok(Kit.mode == "play" and Kit.modeT == 1.5, "mode and banner set")

local parts = {}
Kit.burst(parts, 100, 100, 12, 90, 40)
ok(#parts == 12, "burst spawns")
for _ = 1, 60 do Kit.updateParts(parts, 1 / 30, 400, 200) end
ok(#parts == 0, "particles expire")

Kit.shake(0.2)
Kit.updateShake(1 / 30)
ok(Kit.shakeT > 0, "shake decays over time")
for _ = 1, 20 do Kit.updateShake(1 / 30) end
ok(Kit.shakeT == 0 and Kit.sx == 0, "shake settles to zero")

local drawn = {}
Kit.drawSorted({
    { y = 50, fn = function() drawn[#drawn + 1] = "b" end },
    { y = 10, fn = function() drawn[#drawn + 1] = "a" end },
    { y = 50, fn = function() drawn[#drawn + 1] = "c" end },
})
ok(drawn[1] == "a" and drawn[2] == "b" and drawn[3] == "c",
    "the painter sort is stable on ties")

runs(function()
    Kit.meter(10, 10, 60, 6, 0.4)
    Kit.meter(10, 20, 60, 6, 2)      -- clamps
    Kit.list("PICK", { "one", { label = "two", sub = "99%" } }, 2, 20, 40, 200)
    Kit.slots(1)
    Kit.title("DITHER", { "A: start" })
    Kit.over("CAUGHT", { "score 12" })
    Kit.marker(100, 100, 1.2)
end, "Kit HUD furniture draws")

-- ---- Harness --------------------------------------------------------------

DISK["err"] = nil
Harness.frame(1, function() error("kaboom") end)
ok(DISK["err"] ~= nil, "a thrown frame is caught and latched")
DISK["err"] = nil

-- ---- report ---------------------------------------------------------------

print(string.format("coretest: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
