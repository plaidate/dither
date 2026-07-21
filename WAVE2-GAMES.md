# Wave 2 — four new shade games (fleet guide)

Engine wave 2 is DONE and green: `lua tools/coretest.lua` is 88/88 and
sprint/glim/skimmer all pass `lua tools/headless.lua <g>` on the new
core. This wave adds four FULL games — a campaign each, not a single
endless mode: real progression, an authored soundtrack, cutscenes, a
save file, and an autopilot that plays the whole thing through.

You are building ONE game. Touch ONLY `games/<yourgame>/**`. Never
edit `core/`, `Makefile`, `tools/`, `*.md` at the repo root, or another
agent's game — four of you are running in parallel on the same
checkout and anything outside your directory is someone else's.
`DEVGUIDE.md` plus the header comment of each `core/*.lua` is the API
reference; this file lists what is NEW in wave 2 and your brief.

Your game's name is already in the Makefile's `GAMES` list, so
`make <yourgame>` and `lua tools/headless.lua <yourgame>` work as soon
as `games/<yourgame>/main.lua` exists.

## The thesis you must satisfy

Dither owns **shade**: the illusion of grayscale on a 1-bit screen,
promoted from an art trick to a game mechanic (`DESIGN.md`). A game
earns its place here only if it USES shade — hides something in
darkness, reveals something with light, or makes distance readable by
tone. Decoration is not enough. Each brief below names the mechanic
that has to carry its game; if you find yourself building something
that would play identically at ambient 1, stop and re-read it.

## What the engine gives you that it did not before

### Lighting grew occluders and cones (`core/light.lua`)

```lua
Light.begin(0.15)                       -- ambient 0..1; 1 = no-op
Light.wall(x1, y1, x2, y2)              -- a shadow-casting segment
Light.box(x, y, w, h)                   -- its four sides
Light.add(x, y, r, falloff)             -- point light (as before)
Light.cone(x, y, r, dir, spread, fall)  -- NEW: a wedge, dir in rads
Light.finish()                          -- composite darkness
Light.at(x, y)        -- 0 | 0.5 | 1, honours cones AND walls
Light.blocked(ax, ay, bx, by)  -- NEW: line-of-sight through walls
Light.stats()         -- {lights, walls, blits, fills, ms, ambient}
```

* Walls and cones are registered per frame between `begin` and
  `finish`, in any order, and reset every frame. Cap: 64 walls.
* `Light.at` and `Light.blocked` use the SAME geometry the compositor
  draws, so "the player is standing in shadow" is a query, not a
  guess. Detection, AI and visibility should all be built on them.
* Cost: each wall inside a light's reach adds one polygon fill per
  darkness band. Register only the walls near the action — a whole
  level's worth of segments every frame is the way to blow the budget.
* Documented caveat (top of `light.lua`): shadows are carved per light
  in add order, so add the shadow-casting light LAST when two lights
  overlap.

### Cutscenes (`core/dstory.lua`)

```lua
Story.play(function()
    fade(1, 0.4)                    -- veil to black over 0.4s
    say("Keeper", "The lamp is out.")
    act(function(dt) return Game.walkTo(dt, 120) end)  -- until true
    beat()                          -- 0.35s hold
    iris(200, 120, 0, 0.5)          -- open an iris
    flash()  tune(SONG)  sting{72, 76, 79}
    fade(0, 0.6)
end, { onDone = function() Game.startStage() end })
```

* Call `Story.update(dt, aPressed, bPressed)` FIRST in your update and
  skip the rest of the game's update while `Story.active`. Call
  `Story.draw()` LAST, after `Light.finish()`.
* Primitives are globals only while a scene runs; `Story.portraits =
  { ["Keeper"] = function(w, h) ... end }` adds 40x40 portraits.
* A scene counts `cutscenes`; every `say` counts `saidLines`. In smoke
  builds lines auto-advance after 1.6s, so an unattended run finishes.

### Saves (`core/dsave.lua`)

```lua
Save.use(1)  Save.reset{ name = "Vesper", place = "Cliff Road", pct = 0 }
Save.set("stage", 3)   Save.get("stage", 1)
Save.flag("metKeeper", true)   Save.flag("metKeeper")  -- read
Save.unlock(4)         -- monotonic highest-stage
Save.commit()          -- one datastore write; NOT per frame
Save.load(1)  Save.summary(2)  Save.any()  Save.wipe()
Kit.slots(sel, x, y, w)  -- the three save cards, drawn for you
```

JSON round trip eats numeric keys and holey arrays — key with strings
(`"s3"`), keep arrays contiguous. `tools/headless.lua` reproduces this
exactly, so a save bug fails there rather than on a device.

### Songs and stingers (`core/dmusic.lua`)

The old flat 16-step table still works. The new form has patterns and
an order, so a stage can have a verse and a chorus:

```lua
SONG = { bpm = 96, len = 32,
    patterns = { A = { bass = {...}, lead = {...}, hat = {...} },
                 B = { bass = {...}, lead = {...} } },
    order = { "A", "A", "B", "A" } }
Music.set(SONG)  Music.update(dt)  Music.sting{ 72, 76, 79 }
```

`musicBars` counts wraps, `stingers` counts stings. Give each zone or
phase its own song — a campaign that plays one loop for 20 minutes is
not finished.

### Cabinet furniture (`core/kit.lua`)

`Kit.meter(x, y, w, h, frac, level)` (dithered resource bar),
`Kit.list(title, rows, sel, x, y, w)` (menus; rows may be
`{label=, sub=}`), `Kit.slots(sel)` (save cards), plus the wave-1
`Kit.run/setMode/loadBest/saveBest/shake/burst/marker/drawSorted/
title/over/text/panel/centered/bigCentered`.

Smoke builds now seed from `SMOKE_SEED` (`make <g>-smoke SEED=4`,
`SEED=4 lua tools/headless.lua <g>`), so runs are reproducible: a bot
that passes at seed 1 and fails at seed 4 has a real bug.

## House rules (hard-won; do not relearn)

* **Zero per-frame allocation** in update and draw paths. Pool
  everything; build images and ladders at import time.
* **All art is procedural.** No PNG assets — every wave-1 game except
  sprint draws itself from primitives. Do not add launcher art; the
  orchestrator makes it from your screenshots.
* **Readability beats atmosphere.** The player must never be lost in
  the dither: white fills, black outlines, `Kit.marker` when needed.
* **The autopilot must FINISH the game.** `Input.gather()` (or
  `Input.poll`) returns synthetic inputs when `Harness.enabled`, and
  the run has to reach your `done` counter inside `expect.frames`. A
  bot that survives but never wins is not evidence.
* Autopilot menus by LABEL, never by index — menus grow.
* Plan steps must latch. A bot that re-decides every frame oscillates
  between two targets and finishes nothing.
* Guard every window: while `Story.active`, the field must not update.
* 30 fps, `C.DT = 1/30`, every tunable in `config.lua` with units.
* Follow the module layout in `DEVGUIDE.md` — `main.lua` (loop),
  `config.lua` (`C`), `gamestate.lua` (`G`), `game.lua` (`Game`),
  `input.lua` (`Input`), `draw.lua` (`Draw`), `sfx.lua` (`Sfx`),
  `pdxinfo` (`bundleID=com.sdwfrost.dither.<name>`), `README.md`.

## How you verify (you, not the orchestrator)

```
lua tools/coretest.lua              # must stay 88/88 — if it breaks,
                                    # you edited core/. Revert it.
lua tools/headless.lua <yourgame>   # your whole campaign, no GUI
SEED=1 lua tools/headless.lua <g>   # ... and seeds 2..5
```

**Do NOT launch the Playdate Simulator.** Four agents share one
machine and one Simulator; the orchestrator runs the real playthroughs
and screenshots serially after you hand back. Headless is your loop.

Ship `games/<yourgame>/expect.lua` (stripped from the pdx):

```lua
return {
    frames = 24000,                 -- headless run length
    counters = { done = 1, stagesCleared = 8, cutscenes = 6, ... },
}
```

Those floors are your contract: they must include `done = 1` and
`cutscenes >= 6`, plus the counters that prove the specific mechanic
of your game actually happened.

## Definition of done

1. Campaign of at least 8 stages/nights/levels with escalating ideas,
   plus a real finale (a boss, a storm, a last run — something that is
   not just "stage 9").
2. At least 6 cutscenes: an opening, a midpoint turn, and an ending
   with credits/stats. Story beats, not tooltips.
3. A save file: progress, best results, and a title screen that offers
   Continue via `Kit.slots`.
4. At least 3 songs plus stingers.
5. Autopilot completes the campaign headless at seeds 1-5.
6. `README.md` for the game: what it is, controls, the rules, and a
   paragraph making the **engine-over-scratch case** — name the core
   modules you leaned on and what they saved you.
7. A "Notes" section at the end of that README listing anything the
   next agent should know (a trap you hit, a budget you found). Do not
   edit the shared docs; the orchestrator folds those in.

---

# The four briefs

## 1. `prowl` — the shadow is the floor

**Shade mechanic:** darkness is cover. Guards carry `Light.cone`
lanterns; crates, walls and pillars are `Light.wall` occluders that
throw real shadows; you are seen exactly when `Light.at(player) > 0`
and `Light.blocked` says the guard has a clear line. Every wall in the
level is both a collision volume and a shadow caster — that duality is
the game.

A cat burgling a sleeping town by night: top-down, ambient ~0.12.
Move quietly (a modifier or the crank to creep — fast movement is
noisy, noise draws a guard's cone), hide in shadow, take the loot,
reach the roof. Guards patrol routes and investigate noise; a
detection meter (`Kit.meter`) fills while you are lit and drains in
the dark, so being briefly clipped by a beam is survivable and
standing in one is not. Ideas to escalate across ~10 heists: two
guards with crossing cones, a watchdog that hears rather than sees, a
lamp you can douse (removing a light for good), a moving light (a
lantern-carrying drunk), a room with no cover where timing is
everything, and a finale in the manor where the Night Watchman sweeps
a long beam and the loot sits under it.

## 2. `beacon` — the crank is a lighthouse

**Shade mechanic:** you own the only light. The crank rotates a long
`Light.cone` beam out to sea; fog (a `Shade`/`Fade.haze` bank that
thickens over the night) shortens it; ships only steer when the beam
is ON them, and `Light.at` at a ship's position is literally its
steering input.

You are the keeper. Ships approach from the dark horizon through
`Para` layers and must be turned away from the rocks before they run
aground; each night has more traffic, worse fog and less oil. Oil is a
`Kit.meter` — a wider beam burns faster, so the crank is a resource
dial as well as an aim. Escalate across ~10 nights: a ship that only
answers a held beam, a squall that swings your aim, wreckers on the
headland showing a false light (douse them by holding your beam on
them), a rescue where you must light a lifeboat all the way in, and a
final storm where the lamp itself fails and you relight it mid-scene.
The keeper's cottage, the log book and the harbourmaster's letters are
your cutscene furniture.

## 3. `echo` — you fly blind and paint with sound

**Shade mechanic:** light is memory. Ambient 0; a bat in a cave.
Pressing A emits a ping — an expanding `Light.add` whose radius grows
and whose falloff decays over ~0.8s — and for that moment the tunnel
is visible. Between pings you fly on what you remember, with only the
faintest silhouettes. Pings cost stamina, so the game is a rhythm of
"see, commit, see".

Built on `core/scaler.lua`, the Super Scaler road (see `games/skimmer`
for a worked example): stalactites, pillars, moths and gaps approach
out of the dark on mip ladders, hazed by distance. Fly the cave, eat
moths to refill stamina, do not hit rock. Escalate across ~10
caverns: narrowing gaps, a wind that pushes you between pings, water
that reflects your ping back as a second, softer reveal, a cavern
where something else is pinging (echo it back to find it), and a
finale chase with the owl that has been hunting the roost. Distance
must read as tone — that is the second half of the thesis.

## 4. `delve` — one lamp, three flares

**Shade mechanic:** light is a consumable you place. A side-view
descent into a mine: your helmet lamp is a short `Light.cone` that
points where you face, and you carry flares you can throw — each
becomes a `Light.add` that sits where it lands and burns down. The
creatures down here advance only in darkness (`Light.at` gates them,
the inverse of glim's moths), so a thrown flare is a wall you build
out of light, and a spent flare is a wall that falls down.

Platforming with rope, ledges and falling rock; `Cast.blob` anchors
you to the ground, `Para` layers give the shaft depth, and the lamp's
oil is a `Kit.meter` that only refills at lanterns you light on the
way down (checkpoints and save points at once). Escalate across ~10
depths: a shaft where the only path is lit by a flare you must throw
ahead, a flooded level that snuffs flares, a swarm that forces you to
ration, a collapse that takes your lamp and leaves you with two
flares, and a finale in the deepest gallery where the thing that has
been following you can only be driven back by light you cannot afford
to keep spending.
