# Dither

> Part of **[plAIdate](https://plaidate.github.io)** — AI-built 1-bit games, ports, and engines for the Playdate.

Original 1-bit **pixel/sprite** games for the [Playdate](https://play.date),
sharing one thin core library. Sister project to
[`phosphor`](../phosphor/) (vector beam games) — where phosphor draws
white strokes on black, Dither leans into the 1-bit raster screen: baked
bitmaps, sprite sheets, and dithered tone.

Each game links to its own page with controls, rules, and a screenshot.
The full player's manual (one section per game) is in
[**MANUAL.md**](MANUAL.md); engine internals and how to add a game are in
[**DEVGUIDE.md**](DEVGUIDE.md).

| Game | Style |
|---|---|
| [Sprint](games/sprint/) | top-down circuit racer (crank wheel, A/B pedals) |
| [Glim](games/glim/) | firefly-keeper night garden (crank trims the lantern wick) |
| [Skimmer](games/skimmer/) | into-the-screen dragonfly super-scaler (crank trims the throttle) |
| [Prowl](games/prowl/) | ten-heist stealth campaign — guards' light cones, real shadows to hide in |
| [Beacon](games/beacon/) | ten nights keeping a lighthouse; the crank is the beam, the beam is a ship's rudder |
| [Echo](games/echo/) | ten caverns flown blind — each ping is a light, and between pings you fly on memory |
| [Delve](games/delve/) | ten depths of a mine; your lamp burns down and thrown flares are walls of light |

## Play it (no build needed)

Ready-to-run copies of every game live in [`dist/`](dist/), and zipped
`.pdx` builds are attached to the GitHub
[Releases](../../releases).

- **On a Playdate**: sign in at [play.date/account/sideload](https://play.date/account/sideload),
  upload the `.pdx` you want (zip it first if your browser requires a
  single file), then download it to the device from Settings → Games.
- **In the Playdate Simulator** (ships with the
  [Playdate SDK](https://play.date/dev/)): open the `.pdx` directly, or
  drag it onto the Simulator window.

High scores and records save per game on the device.

## Development

Requires the Playdate SDK with `pdc` on your PATH. Game names are the
lowercase dirs in `games/`.

- `make <game>` — build one game to `out/<Title>.pdx`
- `make all` — build everything
- `make <game>-smoke` — instrumented build: the game plays itself
  (autopilot) and writes telemetry counters, errors, and periodic
  screenshots through the built-in harness
- `tools/smoke.sh <game> [seconds] [until-grep]` — build the smoke
  variant, run it headlessly in the Simulator, and report
- `lua tools/headless.lua <game>` — run a whole game off-device under
  system Lua against a stubbed SDK (`SEED=n` to vary the pinned RNG);
  it passes when the floors in `games/<game>/expect.lua` are met
- `lua tools/coretest.lua` — the engine's own 90-check self-test; run
  it after any change to `core/`

### Layout

- `core/` — the shade engine: `shade` (17-level dither ramps), `light`
  (dynamic lights, cones, wall occluders, `Light.at`), `cast`, `fade`,
  `para`, `scaler` (Super Scaler pseudo-3D), plus the cabinet — `kit`
  (loop, HUD, saves-of-best, particles), `dsnd`/`dmusic`, `dsave`
  (campaign slots), `dstory` (coroutine cutscenes), `cutil` and
  `harness` (the smoke-test harness; a staged `smokeflag.lua` switches
  it on per build). Each game owns its own `playdate.update` loop and
  the `config.lua` / `gamestate.lua` / `game.lua` / `input.lua` /
  `draw.lua` module convention. See [DESIGN.md](DESIGN.md).
- `games/<name>/` — each game's modules plus its bitmaps/sounds.
- The Makefile stages `core/` + the game into `build/<name>/source` and
  runs `pdc`; `dist/` holds committed release builds. Bundle IDs are
  `com.sdwfrost.dither.<game>`.

## Licensing

The Lua game code is original work, © 2026 Simon Frost, under the MIT
[LICENSE](LICENSE), staged into every built `.pdx`. Individual games may
build on public-domain (CC0) third-party artwork; see each game's README
for its asset provenance and attribution (e.g. Sprint's sprites derive
from the CC0 [PySprint](https://github.com/salem-ok/PySprint) assets).
