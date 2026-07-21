# Echo

A bat under a hill with no light in it.

Ambient is **0**. Not dim — zero. The only light in the game is the one
you make: press **A** and a call goes out, an expanding `Light.add` on
the screen and a reveal front racing down the tunnel at 980 units a
second, marking rock as it passes. For about a second the cave exists.
Then the memory rots, the stalactites fade back to a speckle, and you
are flying on what you remember.

Calls cost breath. Breath comes from moths. So the game is a rhythm:
**see, commit, see** — and the interesting decision is never "which
gap" but "can I afford to look again yet".

Ten caverns, an owl at the end of them.

## Controls

| | |
|---|---|
| **A** | call (a ping) |
| **D-pad** | fly — up climbs, down dives, left/right slide |
| **Crank** | throttle: slower buys reaction time, faster outruns the owl |
| **B** | back out of a menu |

On the menus: up/down choose, **A** takes, **B** goes back.

## The rules

* A **call** costs breath and maps everything within 780 units. Below
  the price it drops to a **whisper**: 40% of the reach, a small light,
  a fraction of the cost. You are never completely mute.
* The **glimpse rots** over about 2.9 seconds. Rock you have heard
  keeps a faint silhouette; rock you have never heard is not drawn at
  all. Inside 170 units you can *feel* the cave through the air whatever
  you last heard — that is the only thing keeping this fair.
* **Distance is tone.** Near rock is bright, far rock greys out into
  the throat of the tunnel, and the returning echoes fall in pitch with
  distance. If you are listening you know how far the wall is before
  you can see it.
* **Moths are breath.** Every one is roughly two more calls, and they
  sit near the open lane, so the greedy line and the safe line are
  usually the same line. Usually.
* **Walls forgive, rock does not.** Grinding along the tunnel wall
  drains breath and eventually costs a wing; a stalagmite at speed
  costs one immediately. Three lives (four in the last cavern).
* **Progress saves** to one of three slots — a cavern's best time and
  best moth count, and the caverns you have opened.

## The ten caverns

| | | the new idea |
|---|---|---|
| 1 | Drip Hall | wide and kind: learn the call |
| 2 | The Fluting | stalactites — the roof grows teeth |
| 3 | Moth Garden | the breath economy bites |
| 4 | The Squeeze | pillars, and pinch points in the tube |
| 5 | Windward Gallery | wind moves you *between* glimpses |
| 6 | Still Water | the pool throws your call back a second time, softer |
| 7 | The Answer | something else is calling; call back and share its map |
| 8 | Cracked Ceiling | your own voice brings the roof down |
| 9 | The Long Throat | all of it, narrower, faster |
| 10 | **Owl Light** | the hunt: every call you make tells it where you are |

The finale is the thesis with the safety off. The owl closes steadily,
closes further every time you call, and closes faster while your own
light is still on you (`Light.at` at the bat is literally its input).
Moths buy distance back. To see is to be seen.

## Why the engine, not from scratch

Four core modules did the heavy lifting and none of them is decoration:

* **`core/light.lua`** *is* the ping. One `Light.add` whose radius grows
  and whose lit-core fraction decays over 0.85s gives the whole
  "glimpse" feel for one line of code, and its `Light.at(x, y)` query is
  what the owl hunts by — pixels and logic read the same math, so
  "am I lit?" is never a guess. At ambient 0 the compositor is doing two
  stencil-gated full-screen pattern fills a frame; writing that by hand,
  correctly, is a week.
* **`core/scaler.lua`** is the cave. `Scaler.project` + mip ladders
  built once in `Draw.init` + the pooled depth queue means a stalactite
  is four lines of game code (`Scaler.queue(Draw.obj, x, tip, z, o)`)
  and the rest — sorting, culling, choosing a ladder step, the haze —
  is free. `Scaler.linearHaze` is installed directly over `Game.tone`,
  so "distance reads as tone" is one core function, not a hand-rolled
  falloff.
* **`core/dstory.lua`** turned seven cutscenes into seven readable
  screenplays with portraits and a typewriter, and — crucially — it
  auto-advances in smoke builds, so the campaign's story beats do not
  block the unattended run that proves the campaign works.
* **`core/dsave.lua`** + `Kit.slots` is the whole save/continue screen,
  with the JSON round-trip rules already learned; `Kit.meter`,
  `Kit.list`, `Kit.over`, `Kit.title` and `Kit.run` are the entire
  cabinet. `core/dmusic.lua`'s pattern/order form gave four beds for
  the price of four tables.

What is left in `games/echo/` is the game: the tube, the memory model,
the breath economy and the owl. That ratio is the argument.

## Notes for the next agent

* **`Scaler.floor` does not fit a cave.** It only paints *below* the
  horizon, and a tube needs a ceiling, two walls and a floor from one
  projection. `draw.lua` draws the tunnel as nested cross-section
  rectangles instead — near to far, each clipped to the previous
  (nearer) opening, which is exactly the occlusion a tube has and gets
  "you can see round the bend" for free. It costs **22 pattern fills a
  frame**, about a third of `Scaler.floor`'s band loop, and the stripe
  phase trick still works: anchor the ring z's to `floor(cam.z/SIZE)`
  and they stream toward you as you fly.
* **Invert the palette at ambient 0.** Everything else in the fleet
  draws dark sprites on light ground. In a cave that is invisible: rock
  and wings here are white with black outlines, and after `Light.finish`
  the bat gets one 4x4 white pip drawn on top so the player can never
  lose themselves in the dither.
* **`Light.at` is a one-frame-lagged query if you register lights in
  draw.** The pool is not cleared until the next `Light.begin`, so
  calling it from `Game.update` reads last frame's lights. Echo does it
  deliberately (`G.lit` is set in the light pass, read by the owl next
  tick) — but know which frame you are reading.
* **Light budget:** worst case here is five sources (ping + water
  reflection + two moth glows + Vesper's call), above the 2-4ms figure
  in `light.lua`'s header. `MOTH_LIGHTS` is the knob if the device
  frame time bites.
* **The autopilot bug worth not repeating:** its reachability test
  originally asked "is this lateral position inside the tube at *every*
  z between here and the aim point". In a meandering tunnel that
  rejects almost every reachable target — it ate 8 moths a campaign
  instead of 20. Ask at the z that matters (where the moth *is*), and
  let the wall clamp handle the rest.
* **Score the line the bat will fly, not the line it aims at.** Adding
  transit prediction (clamp the candidate offset by `XSPD * dz/spd`)
  to the obstacle test roughly halved the crash rate: near obstacles are
  met *while* you are still climbing over the last one.
* **One collision predicate.** `Cave.blocks(o, y, pad)` is used by the
  simulation with pad 0 and by the autopilot with clearance. When they
  were two functions, a landed stalactite was a floor obstacle to one
  and a ceiling obstacle to the other, and the bot flew lines the game
  then killed it for.
* **Ping cadence is tuned for a human, and headless cannot check it.**
  The reveal reaches 780 units; at the fastest cavern speed (236 u/s)
  that is 3.3 seconds of lead, and memory lasts 2.9 seconds, so a
  player calling every ~2.5 seconds always has an unbroken map. The
  autopilot deliberately calls slower than it could (`AP_PING` 2.15s)
  so the counters reflect a rhythm a person can actually hold. If real
  play in the Simulator feels tight, raise `MEM_LIFE` and `FEEL` before
  touching anything else — those two are the whole fairness budget.
* Headless: `lua tools/headless.lua echo` (floors in `expect.lua`),
  verified at seeds 1-5. A full campaign run is ~20k frames; the
  contract allows 26k for the seeds where the bot loses a cavern and
  has to fly it again.

All art is procedural — there are no image files in this directory.
