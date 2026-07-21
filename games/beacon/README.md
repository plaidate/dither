# Beacon

You are the keeper of Vesper Rock. The crank is a lighthouse: it turns
a long `Light.cone` out over a black bay, and every hull out there
steers on `Light.at(ship)` — unlit, a master holds his course onto the
reef; lit, he puts his helm over, and how fast he answers is exactly
how brightly you have him. The whole game is one sentence of geometry:
**you own the only light, and the light is the rudder.**

A ten-night campaign. Ships come out of the dark at the top of the bay
carrying nothing but a guttering riding light; you sweep for them, find
them, hold them, and turn them back out to sea before they are on the
rocks. The fog thickens as each night wears on and eats the far end of
your beam. The oil in the can is finite and a wide beam drinks it.

## Controls

| Input | Action |
|---|---|
| Crank | Turn the beam. One turn of the crank is about half the seaward arc |
| Left / Right | Turn the beam without the crank (docked-crank fallback) |
| Up | Draw the beam **fine** — longer reach, tighter aim, less oil |
| Down | Open the beam **wide** — more sea covered, much shorter reach |
| A | Lens surge: 0.9s of over-reach, costs oil. (In the last storm: strike the primed lamp) |
| B | Fog horn: hulls within earshot heave to for three seconds |
| A / Up / Down | Confirm and move in the menus; B backs out of the slot list |

## The rules

| Thing | Behaviour |
|---|---|
| Light is the rudder | `Light.at(ship)` gates her turn: 0 = she holds course, 0.5 (beam fringe) = she answers slowly, 1 (the lit core) = she answers at once |
| Reach vs width | Reach is `REACH * sqrt(SPREAD_REF / spread)` — constant light, spread thin or spread deep. Oil burn goes the other way |
| Fog | Multiplies reach by `1 - fog * 0.5`, and makes up through the night. In a real fog only a needle reaches the horizon |
| Blind sectors | The lantern room's glazing bars are two real `Light.wall` segments 12px from the filament. They throw two fixed ~11° wedges of bay that **cannot be lit at all** — learn where they are |
| Deep hulls (brigs) | Only answer the lit core, not the fringe |
| Colliers | Will not answer at all until they have had 1.5s of *continuous* light; let it lapse for 0.6s and the count restarts |
| Wreckers | Walk a lantern on the headland to look like a beam. Unlit hulls near one are pulled toward the rocks. Hold *your* beam on the man for 2.2s and he puts it out |
| The lifeboat | Pulls hard only while lit; out to the casualty, 1.1s alongside, then home. Unlit she still creeps, so a blind sector cannot strand her |
| The squall | Adds a wandering torque to the mechanism — your aim will not stay where you left it |
| Oil | A `Kit.meter`. At zero the lamp dies and the night is lost |
| A night is lost | If wrecks exceed the night's allowance, or the oil runs out, or the lifeboat never gets home. You stand the same watch again |

## The campaign

Ten nights, one new idea each: **First Watch** (learn the arc) → **The
Ebb** → **Heavy Weather** (brigs want the core) → **The Collier** (a
held beam) → **The Fog Bank** (78% fog: you will not see them, you will
only find them) → **The False Light** (one wrecker) → **The Squall**
(the mechanism fights you) → **The Lifeboat** (an escort while the
traffic keeps coming) → **Two Lights** (both headlands lying) → **The
Long Night** (everything at once, and partway through, the lamp itself
drowns and has to be cranked back up by hand and struck).

Eight cutscenes carry it: the harbourmaster's briefing on arrival, four
turns of the screw, the lamp failing mid-storm, and a dawn that reads
your log book back to you. Progress, totals and best oil-per-night live
in a three-slot save; the title screen offers Continue.

Four beds — CALM, SWELL, GALE and the HYMN over the ending — plus
stingers on every hull turned, lost, doused and brought home.

## Why the engine and not from scratch

Almost none of what makes Beacon work is Beacon's code.

* **`core/light.lua`** is the game. `Light.cone` *is* the beam;
  `Light.wall` *is* the lantern's glazing bars, and the blind sectors
  they carve are not drawn and then also hard-coded — they are one
  geometry, so what the compositor paints and what `Light.at` tells a
  ship's master are guaranteed to agree. Writing a stencil-composited
  three-band darkness layer with occluder shadow quads and a matching
  point-query, at 30fps on a 1-bit screen, would have been the entire
  project. Here it was `Light.begin` / `Light.wall` / `Light.cone` /
  `Light.finish` and one `Light.at` call in the ship update.
* **`core/dstory.lua`** turned eight cutscenes into eight plain
  functions. No dialogue state machine, no typewriter timer, no
  letterbox bookkeeping — and the smoke build auto-advances lines, so
  the autopilot walks straight through the campaign's story.
* **`core/dsave.lua`** + `Kit.slots` gave a three-slot campaign save
  and its title-screen furniture for the cost of naming the keys.
* **`core/dmusic.lua`**'s long song form meant four beds with verses
  and choruses instead of four sixteen-step loops.
* **`core/shade.lua`** / **`fade.lua`** / **`para.lua`** did the night:
  a pale noise sea that comes up bright the instant the beam crosses
  it, three parallax swell layers where distance reads as tone, and
  fog banks that are `Shade.wash` and `Fade.haze` — white speckle, so
  fog *lightens* the dark instead of darkening it, which is what fog
  actually does to a beam.
* **`core/kit.lua`** owns the loop, the seed, the shake, the meters,
  the menus and the harness wiring. `games/beacon` is a bay, ten
  nights of data and one autopilot.

## Assets

Entirely procedural — no image or sound files. All art is drawn from
the shared `Shade`/`Light`/`Fade`/`Para` primitives; all sound is the
core synth pools and step sequencer. Code is original, MIT (see repo
LICENSE).

## Notes for the next agent

* **`Story.portraits` do not get an origin.** `Story.draw` sets a clip
  rect at the portrait box and calls your function with `(40, 40)` —
  the width and height, *not* a position. A portrait must therefore
  draw at the box's absolute screen coordinates, which for the stock
  58px dialogue box are **(16, 178)**. See `PX`/`PY` at the top of
  `story.lua`. Draw at (0, 0) and you get a clipped nothing.
* **A `Light.wall` near a light is an enormous shadow.** Angular width
  of the blind wedge is roughly `wall_length / wall_radius`: a 3.4px
  bar 11px from the filament ate **35° of a 180° arc**. Halving the
  length to 2.2px at radius 12 got it to a fair ~11° each. If you want
  a "dead sector" mechanic, compute the angle, do not eyeball the
  pixels.
* **An entity that only moves while lit can deadlock inside a blind
  sector, permanently.** The first lifeboat build stalled at a bearing
  1° off a glazing bar and sat there until the oil ran out, and the
  bot dutifully aimed at it for eighty seconds. Anything gated on
  `Light.at` needs a floor (`C.LB_DRIFT = 0.2` here) or a hazard that
  cannot be static. Hulls were fine — they always have way on.
* **Give the autopilot a fallback target that ignores its own
  penalties.** The bot benches a target it decides is in a blind
  sector; with only one hull afloat that meant benching *everything*
  and idling. `pick()` now returns both the filtered best and an
  unfiltered best and uses the latter when the former is empty.
* **Budget:** at night the pass is 1 cone + up to 2 wrecker discs + 2
  walls, so `Light.stats()` reports `lights <= 3`, `walls = 2`, and
  ~1ms in the Simulator. There is a lot of headroom left for more
  occluders; the cap is 64 walls.
* **Headless timing:** a full ten-night playthrough with one retry is
  ~11-14k frames; the worst seed measured (7) was 17.9k. `expect.lua`
  is set to 24000, which is roughly 35% headroom. Cutscenes are ~2.5k
  frames of that, and the bot taps A every 8 frames to walk them.
* The autopilot drives the beam through `Input.beam` (signed radians),
  the same field `getCrankChange()` feeds — the stub returns 0 for the
  crank, so any game whose crank handling lives *inside* `Input.poll`'s
  device branch cannot be driven headless at all. Keep the seam in the
  field, not in the reader.
