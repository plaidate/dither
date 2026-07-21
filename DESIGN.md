# Dither — the shade engine

## The thesis

Every engine in this fleet owns a rendering idea: phosphor owns *lines*,
tiles owns *the grid*, voxel owns *volume*. Dither owns **shade** — the
illusion of grayscale on a 1-bit screen, promoted from an art trick to a
game mechanic. The SDK gives you one pattern at a time; Dither gives you
ramps, lights, shadows, and transitions built on top of them:

- **Grays are a resource.** A ramp of dither levels is a first-class
  object, not eight magic byte-tables scattered through draw code.
- **Light is gameplay.** Dynamic light sources (headlights, lanterns,
  muzzle flashes, day/night) that games can reason about — "is this
  point lit?" is a query, not just pixels.
- **Shade tells depth.** Parallax layers fade with distance;
  shadows anchor sprites to the ground; transitions dissolve through
  the same Bayer thresholds the terrain is drawn with.
- **Distance is scale AND tone.** The super-scaler road: sprites
  approach by stepping up a mip ladder while the depth haze lifts.

A game earns Dither the way a game earns voxel's height rule: it must
USE shade — hide something in darkness, reveal something with light,
or make distance readable by tone. A game that only wants sprites on a
screen belongs in classics.

## Core modules (the contract)

Existing thin core stays: `cutil.lua` (Util), `harness.lua` (Harness),
`lib.lua` (imports, updated with the new modules in dependency order).

- **`shade.lua` (Shade)** — the ramp system. A ramp is 17 pattern
  levels (0 = white … 16 = black) derived from the Bayer 8x8 threshold
  matrix. `Shade.set(level)` (fractional ok, clamps), `Shade.fill(x, y,
  w, h, level)`, `Shade.vgrad(x, y, w, h, l0, l1)` /
  `Shade.hgrad(...)` (banded gradients, one fill per band),
  `Shade.disc(x, y, r, level)`. Materials: `Shade.ramp(name)` returns
  a table of pattern levels a game can index. All patterns precomputed
  at import; zero allocation at draw time.
- **`light.lua` (Light)** — dynamic lighting, the flagship.
  A screen-space light layer quantized to K levels (default 3:
  lit / dim / dark). Per frame: `Light.begin(ambient)` (ambient 0..1,
  1 = full day — the whole system no-ops at ambient 1),
  `Light.add(x, y, r [, falloff])` for each source,
  `Light.finish()` composites darkness over the scene: for each level,
  a stencil mask (precomputed radial disc images blitted into a
  reusable mask buffer) gates a dithered black fill. Queries:
  `Light.at(x, y)` -> 0..1 (from the same disc math, so what you see
  is what the game logic gets). Costs: K reusable 400x240 mask images
  allocated ONCE; per frame K clears + one blit per light per level +
  K stencil fills. A visible budget: `Light.stats()` for the harness.
  Verify `gfx.setStencilImage` / stencil-pattern semantics against
  Inside Playdate before building; if stencils can't gate pattern
  fills, the fallback compositor is per-level `setPattern` fills
  through `setClipRect` unions — decide empirically and document.
- **`cast.lua` (Cast)** — cheap shadows and silhouettes.
  `Cast.blob(x, y, w, level)` (the anchoring drop shadow, dithered);
  `Cast.silhouette(img, x, y, level)` (draw an image's alpha as a
  flat dithered shape — for cast shadows and for the ghost-behind
  trick, via image draw modes + stencil pattern).
- **`fade.lua` (Fade)** — transitions & atmospherics.
  `Fade.dissolve(t)` (full-screen Bayer-threshold dissolve, t 0..1),
  `Fade.iris(x, y, t)` (closing/opening circle with a dithered rim),
  `Fade.wipe(dir, t)`. Built from Shade levels; drawn AFTER the scene.
  `Fade.haze(y0, y1, level)` — horizontal atmospheric band for
  parallax skylines.
- **`para.lua` (Para)** — parallax with atmospheric depth.
  `Para.layer(img_or_fn, speed, shade)` registers layers;
  `Para.draw(camx)` draws back-to-front, applying each layer's shade
  level as a faded draw (`image:drawFaded` with the ramp's dither —
  verify drawFaded's dither argument in the SDK) so distance reads as
  tone. Works with tiling images or draw callbacks.
- **`scaler.lua` (Scaler)** — Super Scaler pseudo-3D (Space Harrier /
  After Burner / OutRun lineage). `Scaler.project(wx, wy, wz)` ->
  sx, sy, scale (nil behind the camera) from a forward-moving
  `Scaler.cam` {x, y, z} with tunable focal `Scaler.f` and
  `Scaler.horizon`. Sprites draw from **mip ladders**:
  `Scaler.ladder(img, steps, maxScale)` / `Scaler.ladderFromFn(...)`
  build `steps` scaled copies ONCE (`image:scaledImage`);
  `Scaler.draw` picks the nearest step <= scale, centered-bottom,
  hazing distant sprites via `drawFaded`. The **depth queue**
  (`Scaler.clear/queue/flush(shadeByZ)`) pool-sorts far-to-near
  (stable) and applies `Scaler.linearHaze(z0, z1, lmax)` so distance
  reads as tone. `Scaler.floor(opts)` is the perspective ground:
  horizontal bands below the horizon, world z from row
  (z = camY*f/(sy-horizon)), stripe phase from z + cam.z (forward
  scroll comes free), opaque Shade pattern fills — ~60 fills/frame at
  band 2; `opts.checker` adds lateral cells (budget-capped),
  `opts.curve` is the accumulating OutRun bend, exposed to road art
  via `Scaler.bendAt(sy)`. Draw order: sky vgrad -> Para ->
  Scaler.floor -> Scaler.flush -> near actors -> Light -> Fade/HUD.
  `Scaler.stats()` for the harness.
Wave 2 grew the stack where the games needed it:

- **`light.lua`** gained **occluders and cones**. `Light.wall(x1, y1,
  x2, y2)` / `Light.box(x, y, w, h)` register shadow-casting segments
  for the frame; each light carves their shadow quads into its own
  band mask, so a crate throws a real shadow you can stand in.
  `Light.cone(x, y, r, dir, spread, falloff)` is a wedge instead of a
  disc — beams, torches, guard sight cones. `Light.at` honours both,
  and `Light.blocked(ax, ay, bx, by)` exposes the same occluders as a
  line-of-sight test, so "can that guard see me" and "am I in shadow"
  are answered by the geometry the player is looking at.
- **`dsave.lua` (Save)** — three-slot campaign progress
  (`{v, meta{name, place, pct, time}, data}` per slot), with the JSON
  round-trip rules documented where they bite.
- **`dstory.lua` (Story)** — cutscenes as coroutine screenplays:
  `Story.play(fn)` over blocking primitives (`say`, `wait`, `beat`,
  `act`, `fade`, `iris`, `flash`, `tune`, `sting`), a typewriter
  dialogue box with optional portraits, and letterbox/veil/iris
  furniture drawn after the Light pass.
- **`dmusic.lua`** grew songs — named patterns played in an `order`,
  optional 32-step bars, and `Music.sting` fanfares over the bed.

- **`kit.lua` (Kit)** — the fleet cabinet, ported from tiles/voxel:
  `Kit.run{init=, extra=, shotPath=}` (loop, refresh rate, seeding
  before init, Harness wiring, updMs/drwMs EMA), `Kit.setMode/mode/
  modeT`, `Kit.loadBest/saveBest/best`, `Kit.shake/updateShake/
  applyShake/doneShake`, debris particles (2D, with the bounce
  friction), `Kit.text/panel/bigText`.
- **`dsnd.lua` (Snd)** — sound pools, port of tiles' tsnd.
- **`dmusic.lua` (Music)** — step-sequencer music, port of voxel's
  vmusic.

Everything precomputes at import and allocates nothing per frame in
draw paths. Every module works at any ambient/level so release builds
that don't use lighting pay nothing.

## The proof games

1. **sprint (retrofit)** — cabinet + shade stack. Races get a
   time-of-day option: DAY (as now), DUSK (ambient 0.55, cars carry
   cone headlights, the finish gantry is lit), NIGHT (ambient 0.25 —
   headlights matter; drones' lights telegraph their lines). Title ->
   race via Fade.iris on the player car; lap flash via Fade.dissolve
   blip. Records/HUD/music via the cabinet. The racer must remain
   readable at every ambient — palette rules apply (white player car,
   marker caret stays).
2. **glim (new, compact)** — the identity game: a firefly-keeper in a
   walled night garden. Ambient 0.15. You carry a lantern (Light.add,
   radius = wick that burns down; crank trims the wick — bigger light
   burns faster). Fireflies wander (tiny lights); guide them to the
   jar by standing near (they drift toward your lantern) while moths
   (dark sprites, only visible inside light) steal wick. Score =
   fireflies jarred before the wick dies; Light.at() drives ALL
   visibility logic (a moth outside every light literally does not
   update its stalk — darkness is mechanics, not paint). Parallax
   hedge/moon skyline via Para, night music, full harness/autopilot.
   Target ~roost scale (300-450 lines + tiny procedural art).
3. **skimmer (new)** — a Space Harrier-lineage dragonfly pond skimmer
   on the scaler; altitude is read off the Cast.blob shadow, distance
   off the haze.

Wave 2 added four full campaigns, each carried by a different reading
of the thesis — ten stages, cutscenes, saves and songs apiece:

4. **prowl** — *darkness is cover*. Guards carry `Light.cone`
   lanterns; every crate and wall is a `Light.wall` occluder throwing
   a real shadow you can stand in; you are seen exactly when
   `Light.at(cat) > 0` and `Light.blocked` gives the guard a clear
   line. Ten heists ending under the Night Watchman's beam.
5. **beacon** — *you own the only light*. The crank swings a
   `Light.cone` out to sea and `Light.at(ship)` IS her rudder: lit
   core turns her at once, fringe turns her slowly, dark holds her
   course onto the reef. Two glazing bars carve permanent blind
   sectors out of your own arc. Ten nights of fog, wreckers and oil.
6. **echo** — *light is memory*. Ambient 0. A ping is a growing
   `Light.add` plus a reveal front; what objects carry afterwards is a
   memory that rots, blended with `Scaler.linearHaze` so one number
   answers both "have I heard this" and "how far is it". Ten caverns,
   and an owl that closes fastest while you are lit.
7. **delve** — *light is a consumable you place*. A helmet `Light.cone`
   and thrown flares that land, burn down and hold a patch of shaft
   open; the creatures advance only through dark, so a flare is a wall
   with a fuse. Ten depths, ending with the Warden driven back by
   light you cannot afford to keep spending.

## Non-goals

No general sprite/scene system (the SDK sprite chapter covers that; a
game wanting one can use it directly). No physics (games hand-roll or
borrow). No asset pipeline beyond what sprint already has.
