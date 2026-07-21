# Prowl

A cat burgles a sleeping town, ten heists in one night.

Prowl is the Dither game where **darkness is the floor you walk on**.
Guards carry real `Light.cone` lanterns. Every crate, cell divider and
tomb is a `Light.wall` occluder that throws a genuine shadow — and the
same rectangle is the thing you collide with, so cover and collision
are one list. You are seen exactly when

```
Light.at(cat) > 0                    -- something is lighting you
and a guard is within his sight      -- and near enough to care
and you are in his cone, or his arc  -- and looking roughly your way
and not Light.blocked(guard, cat)    -- with nothing in between
```

and a detection meter fills while that is true and drains while it is
not — so a beam clipping you as it sweeps past is survivable, and
standing in one is not. At ambient 1 this game does not exist.

## Controls

| Input | Action |
|---|---|
| D-pad | Pad about — fast, and every footfall is a noise guards come to look at |
| B (hold) | Creep: half speed, completely silent |
| A | Take whatever is in reach — loot, a lamp wick, the drainpipe |
| A (nothing in reach) | Throw a pebble where you are facing: a loud lie somewhere else |
| Crank | Dial how far the pebble goes (46–148 px) |
| A / B on menus | Choose / back |

## The rules

| Thing | Behaviour |
|---|---|
| The meter | Fills while a guard can see you, drains in the dark. Full = collared, retry the heist |
| Guards | Patrol routes, sweep their lantern, investigate noises, and come for you once the meter is high |
| Watchdogs | Deaf to darkness, sharp of ear. Creep past them; if one hears you, **run** — its chase clock does not refresh |
| The drunk | Sees nothing, reports nothing, and carries a lantern. Cover is only cover until he turns the corner |
| Lamps | Some can be pinched out. A doused lamp is gone for the rest of the heist — you are editing the level |
| The drainpipe | Opens once you have all the loot |
| Ashgrave Manor | The Night Watchman sweeps one 208px beam down the hall, the crown sits under it, and lifting the crown wakes the house |

Ten heists: Fishmonger's Yard, Cooper's Alley, Lamplighter Row, The
Kennel, Drunkard's Lane, The Counting House, The Bell Tower, The Gaol,
Chapel Yard, Ashgrave Manor. Three save slots, per-heist best times,
seven cutscenes, six step-sequencer songs.

## The engine-over-scratch case

Almost nothing in this game is a lighting *effect*; it is all lighting
*logic*, and `core/light.lua` is why it exists at all.

- **`Light.cone` / `Light.wall` / `Light.at` / `Light.blocked`** are the
  game. A guard's lantern is one `Light.cone`; the crate you slip
  behind is one `Light.box`; detection is `Light.at(cat) > 0` and
  `Light.blocked(guard, cat)`. Because the query uses the *same*
  geometry the compositor draws, the shadow you can see behind a crate
  is exactly the shadow the guard cannot see into. Hand-rolling that
  from scratch means writing a shadow-casting compositor AND a separate
  visibility oracle and then spending a week reconciling them.
- **`core/dstory.lua`** turned the seven cutscenes into seven ordinary
  functions full of `say` / `fade` / `iris` / `sting`. No state machine,
  no per-scene bookkeeping, and its smoke-build auto-advance is why an
  unattended headless run walks through the whole story.
- **`core/dsave.lua` + `Kit.slots`** gave three save slots, a Continue
  screen and per-heist best times for about twenty lines, with the JSON
  round-trip rules (string keys, contiguous arrays) already learned.
- **`core/dmusic.lua`**'s pattern/order form is why the campaign has six
  beds rather than one loop, including a 32-step finale and a chase bed
  that swaps in the moment a guard actually knows where you are.
- **`Kit.run`** owns the loop, the seed, the harness wiring and the
  ms EMAs; **`Kit.meter`** is the detection bar; **`Shade`**, **`Cast`**
  and **`Fade`** draw the cobbles, the drop shadows and the iris.

What is left in `games/prowl/` is a stealth game: ten rooms of data, a
guard brain, a detection rule, and a burglar bot.

## Files

| File | Lines | Role |
|---|---|---|
| `main.lua` | 57 | imports, `Kit.run`, heartbeat |
| `config.lua` | 134 | every tunable, with units |
| `gamestate.lua` | 54 | `G`, campaign and per-heist state |
| `heists.lua` | 320 | the ten rooms, as data |
| `game.lua` | 869 | lights, guards, dog, drunk, detection, stage flow, saves |
| `input.lua` | 565 | controls + the burgling autopilot |
| `draw.lua` | 461 | procedural rendering, no image files |
| `story.lua` | 199 | seven cutscenes + 40x40 procedural portraits |
| `sfx.lua` | 170 | six songs + one-shots |

Entirely procedural — no image or sound files. Code is original, MIT
(see the repo `LICENSE`).

## Notes for the next agent

Things that cost real time here; none of them are in the shared docs.

* **A patrol waypoint authored inside a crate is a soft lock.** The
  walker slides to the inflated edge, never "arrives", and stands there
  for the rest of the night blocking a corridor. `Game.loadStage` now
  runs every route through `Game.freePoint` at load, and every walker
  has a two-second anti-stick watchdog that skips to the next waypoint.
  The `nudged` heartbeat counter is the tripwire. Nudges at stage load
  should be zero, and are; the one or two you see over a full run come
  from the autopilot snapping a goal point (a lamp standing against a
  wall), which is harmless. Double figures means somebody fat-fingered
  a coordinate in `heists.lua`.
* **Occluder culling is a visible trade, not a free optimisation.**
  `Light.wall` caps at 64 segments and every wall inside a light's reach
  costs one polygon fill *per darkness band*. Prowl registers only the
  boxes within `C.WALL_CULL` (152px) of the cat, capped at 13 boxes —
  so `walls` in the heartbeat stays at 8–20 and `lightMs` at ~1ms in the
  stub. `WALL_CULL > C.SIGHT`, which is the invariant that matters:
  every occluder that could break a guard's line of sight is always
  registered. The cost is that shadows far from the cat are not drawn,
  which nobody is looking at. Guard cones are added **last**, per the
  documented `light.lua` caveat, because they are the lights whose
  shadows the player reads.
* **Anything that refreshes a "give up" timer becomes immortal.** The
  watchdog originally re-armed its 3.2s chase clock every time it heard
  a footfall — and running away *is* footfalls, so it never lost the
  cat and no escape existed. The chase clock now runs down regardless
  of re-hearing (and there is a cooldown after), which is what makes
  "bolt for the dark" a real answer. `Game.dogAlert` is the single
  place that decides this, because the dog's own ears AND `Game.noise`
  both feed it.
* **A stealth bot with no floor on its patience will stand in a doorway
  all night.** The autopilot has three tiers: careful (waits for cones
  to sweep, sidesteps into crate shadows, throws pebbles), *desperate*
  at 50s (ignores light, still avoids bodies), and *reckless* at 85s
  (walks the flow field, full stop). Bounding an attempt is what took
  the worst-case campaign from "never finishes" to ~35,500 frames. The
  earlier version scaled those timers off each heist's `par`, which
  made the slow heists slowest — absolute seconds are better.
* **Give-up lists need a forgiveness pass.** The bot blacklists an
  objective it has failed for 26s and moves on; with everything
  blacklisted, `pickGoal` fell through to "head for the exit", which
  does not open without the loot. Deadlock. It now clears the list and
  goes round again (`forgave` in the heartbeat).
* **Budget.** A 10-heist campaign with 7 cutscenes runs 14,500–35,500
  frames headless across seeds 1–10; `expect.frames` is 48,000. Each
  cutscene costs roughly 300–500 frames because smoke builds
  auto-advance a line after 1.6s. A collar costs ~150 frames (banner +
  stage card), which is deliberately cheap — retrying is how the bot
  makes progress on the hard rooms.
* **`Input.ap`** is deliberately exposed: it is the autopilot's plan
  (objective, push/wait timers), and being able to print it is the
  difference between debugging the bot in ten minutes and an hour.
