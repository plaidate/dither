# Dither — Developer's Guide

How the shared layer works, how a game is put together, and how to add a
new one to the collection. Sister project to `phosphor/` (vector games);
Dither is the raster/1-bit-sprite side and shares its thin-core philosophy
with `classics/`.

## The shared core (`core/`)

Every module is staged into every build. Games use globals-as-modules
(`Util`, `Harness`, `Shade`, `Light`, `Cast`, `Fade`, `Para`, `Scaler`,
`Kit`, `Snd`, `Music`, `Save`, `Story`, and per-game `C`, `G`, `Game`,
`Input`, `Draw`, ...) — that is the repo convention, not an accident.
Everything precomputes at import and allocates nothing per frame, and
every module no-ops when a game does not use it, so a release build
that never lights anything pays nothing for the lighting.

`DESIGN.md` documents the shade stack (`shade`/`light`/`cast`/`fade`/
`para`/`scaler`) module by module. The rest:

- **`lib.lua`** — the one import a game's `main.lua` starts with. Pulls
  `CoreLibs/graphics`, then every core module in dependency order.
- **`cutil.lua`** — `Util`:
  - `Util.clamp(v, lo, hi)`
  - `Util.after(delay, fn)` / `Util.runPending(dt)` — a delayed-call
    scheduler. The game calls `runPending(C.DT)` once per tick; `after`
    is how e.g. `Sfx.win()` arpeggiates notes without timers.
- **`harness.lua`** — `Harness`, the smoke-test harness as a first-class
  module. The Makefile writes a `smokeflag.lua` into every staged build:
  `SMOKE_BUILD = false` for release (everything below is a no-op, games
  pay nothing), `true` for `make <game>-smoke`, which also injects
  `SMOKE_SHOT_PATH`. When on:
  - `Harness.count(key, n)` / `Harness.set(key, val)` — telemetry
    counters (Sprint counts `laps`, `bumps`, `nudges`, `finishes`,
    `wins`).
  - `Harness.frame(frame, updateFn)` — wraps the real per-frame update
    in `pcall`; errors go to the `"err"` datastore, a heartbeat of all
    counters (plus `Harness.extra(t)` fields) goes to the `"smoke"`
    datastore every 90 frames, and a PNG screenshot is written to
    `SMOKE_SHOT_PATH` every 300 frames in the Simulator.
  - `Harness.autopilot` — convention slot: the game's `Input.gather()`
    checks `Harness.enabled` and returns synthetic inputs so smoke
    builds play themselves. (Sprint keeps its autopilot local to
    `input.lua`; either style is fine.)
- **`kit.lua`** — `Kit`, the fleet cabinet: `Kit.run` (loop, refresh
  rate, seeding, Harness wiring, updMs/drwMs), modes and banners,
  best-score persistence, shake, debris particles, the painter sort,
  and the HUD furniture — `Kit.text/panel/title/over/marker`,
  `Kit.meter` (dithered resource bar), `Kit.list` (menus),
  `Kit.slots` (save cards).
- **`dsnd.lua` / `dmusic.lua`** — `Snd` synth pools; `Music`, a
  step sequencer taking either one looping 16-step pattern or a song
  of named patterns plus an `order`, with `Music.sting{...}` for
  fanfares over the bed.
- **`dsave.lua`** — `Save`, three-slot campaign progress:
  `Save.use/reset/set/get/flag/unlock/commit/load/summary/any/wipe`,
  written to the `"save1".."save3"` datastore keys as
  `{v, meta{name, place, pct, time}, data}`. JSON round-trip rules
  (string keys, contiguous arrays) are documented in the file and
  reproduced by the headless runner.
- **`dstory.lua`** — `Story`, cutscenes as coroutine screenplays.
  `Story.play(fn)` runs a function full of blocking primitives
  (`say`, `wait`, `beat`, `act`, `fade`, `iris`, `flash`, `tune`,
  `sting`, installed as globals while a scene runs);
  `Story.update(dt, aPressed, bPressed)` first in the game's update,
  `Story.draw()` last, after the Light pass.

## Anatomy of a game (`games/<name>/`)

Each game owns its own `playdate.update` loop and follows the same
module convention as `classics/`:

| File | Global | Role |
|---|---|---|
| `main.lua` | — | imports `lib` + modules, state machine (`title` / `play` / `over`), `playdate.update` calls `Harness.frame(G.frame + 1, tick)` |
| `config.lua` | `C` | every tunable in one table, commented with units |
| `gamestate.lua` | `G` | all mutable shared state, initialised with comments |
| `game.lua` | `Game` | simulation: physics, AI, scoring, datastore persistence |
| `input.lua` | `Input` | `Input.gather()` returns the frame's inputs; returns autopilot values instead when `Harness.enabled` |
| `draw.lua` | `Draw` | all rendering; loads images at import time with an `assert` wrapper |
| `sfx.lua` | `Sfx` | synth-only sound effects |
| `pdxinfo` | — | name / author / bundleID `com.sdwfrost.dither.<game>` / version |
| `README.md` | — | per-game page: controls, rules, asset provenance (not staged into the .pdx) |

Games run at a fixed 30 fps (`playdate.display.setRefreshRate(30)`,
`C.DT = 1/30`) and simulate in whatever logical space suits their source
material, scaling only at draw time.

## Build system

`make <game>` stages `core/*.lua` + `games/<game>/*` into
`build/<game>/source` (pdc wants a single source root), deletes `*.md` /
`screenshot*.png` / `*.py` / `expect.lua` from the staging dir, copies the
`LICENSE` in, writes `smokeflag.lua`, and runs `pdc` to
`out/<Title>.pdx`. `make <game>-smoke` does the same with
`SMOKE_BUILD = true` and produces `out/<Title>Smoke.pdx`.

Smoke builds are SEEDED: `smokeflag.lua` carries `SMOKE_SEED` (from
`make <game>-smoke SEED=4`, default 1) and `Kit.run` seeds the RNG from
it, so a smoke run is reproducible — a bot that passes at seed 1 and
fails at seed 4 has a real bug, not bad luck. Release builds still seed
from the clock.

Three ways to run a game, cheapest first:

- `lua tools/coretest.lua` — the engine's own self-test (88 checks)
  against the stubbed SDK in `tools/sdkstub.lua`: ramp coverage,
  `Light.at` agreeing with the compositor's radii, cone angles, wall
  occlusion, the depth queue's order, the save JSON round trip, story
  coroutines, the sequencer. Run it after ANY change to `core/`.
- `lua tools/headless.lua <game> [frames]` (`SEED=n` to vary) — the
  whole game under system Lua with drawing no-op'd. It passes when no
  error latched and the floors in `games/<game>/expect.lua`
  (`{frames = n, counters = {...}}`, stripped from the pdx) are met.
  Fast enough to be an inner loop; blind to anything visual.
- `tools/smoke.sh <game> [seconds] [until-grep]` — the real thing:
  builds the smoke variant, launches it in the Simulator, polls the
  game's datastore dir for `err.json` / `smoke.json` (bundle
  `com.sdwfrost.dither.<game>`), optionally exits early when the
  heartbeat matches `until-grep`, and copies the final heartbeat to
  `results/<game>.json` plus a screenshot to `build/<game>-shot.png`.
  Headless is the gate; the Simulator is the last word.

`dist/` holds committed release builds; `build/`, `out/` and `results/`
are gitignored scratch.

## Adding a new game

1. `mkdir games/<name>` (lowercase — the dir name is the make target)
   and add the module files above. Start `main.lua` with `import "lib"`.
2. Give it a `pdxinfo` with `bundleID=com.sdwfrost.dither.<name>`.
3. Add the name to `GAMES :=` in the Makefile — the pattern rules
   generate the `<name>` and `<name>-smoke` targets.
4. Wire the harness: wrap your tick in `Harness.frame`, sprinkle
   `Harness.count` on the events that prove the game is being played
   (deaths, laps, scores), set `Harness.extra` for state fields, and
   make `Input.gather()` return autopilot inputs when
   `Harness.enabled`.
5. Write `games/<name>/expect.lua` — the counters that prove the game
   was actually played through — then iterate on
   `lua tools/headless.lua <name>` until it PASSes at seeds 1-5, and
   finish with `tools/smoke.sh <name> 180 '"<counter>":[1-9]'` in the
   real Simulator, with no `err.json` and a screenshot you have looked
   at.
6. Add the game's row to the README table and a section to `MANUAL.md`;
   binary assets (1-bit PNGs) live in the game dir, with any converter
   script (`convert.py` style) kept beside them — converters are
   stripped from the staged build.

Keep third-party asset provenance in the game's README (Dither's code is
MIT; art may be CC0 third-party, per game).

## Per-game notes

- **Sprint** (`games/sprint/`) — top-down Super Sprint-style racer.
  Physics runs in PySprint's native 640x400 logical space (constants and
  track data apply directly) and draws at S=0.6 onto the 400x240 screen.
  Eight generated `trackN_data.lua` (gate geometry; gate midpoints form
  the racing line) + `trackN_mask.lua` (baked '#'/'.' drivable grid, 2px
  cells) pairs come from `convert.py`, which rebuilds them and the 1-bit
  images from a CC0 PySprint checkout. `track.lua` turns the active
  track's gates into an arc-length polyline used for lap counting
  (windowed projection via `Track.projectNear`, so progress can't snap
  across the infield wall), standings, drone pathing, and the autopilot
  (tangent-following with a cross-track correction term). Collision
  tests the car centre only — a nose probe wedges in hairpins. Best lap
  per track persists in the `"records"` datastore with string keys so
  the JSON round-trips.
- **Glim** (`games/glim/`) — firefly-keeper night garden, the shade
  stack's identity game, all-procedural (no image files) on the
  `Kit.run` cabinet loop. Ambient 0.15; the lantern is one `Light.add`
  whose radius is the crank-trimmed wick (burn ~radius^1.5). Firefly
  glows are their own lights, coalesced (neighbours within 14px share
  one add) and capped at `C.FLY_LIGHTS` so the per-frame budget stays
  ~11 lights worst-case; `Light.stats()` folds into the heartbeat as
  `lights`/`lightMs`. `Light.at` gates the moth AI — an unlit moth
  does not advance — and picks their one white eye pixel at draw time.
  The autopilot herds the nearest firefly, pausing whenever it lags
  past 0.55x the lantern radius so it can't outrun its own light.
