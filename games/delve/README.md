# Delve

**One lamp, three flares.** A side-view descent into a mine where light
is not atmosphere — it is a consumable you *place*.

Your helmet lamp is a `Light.cone` that points where you face and burns
oil you can only replace at a lantern. Your flares are `Light.add`s you
throw: each one sits where it lands, burns for nine seconds, shrinks,
and goes out. The things down here advance **only** where `Light.at`
says it is dark, and back out of any light that touches them — the
exact inverse of glim's moths. So a burning flare is a wall you built
out of light, and a spent flare is a wall that falls down.

And you cannot see where you are going, because the slab you are
standing on is registered with `Light.wall`. The floor under your boots
is both the thing holding you up and the thing hiding the drop. The
only way to read the gallery below is to throw a flare through the hole
first — and that is a flare you no longer have.

Ten depths, a lantern-checkpoint economy, a flooded level that drowns
flares on impact, a collapse that takes the lamp off your helmet, and
the Warden in the deepest gallery, which can only be driven back by
light you cannot afford to keep spending.

## Controls

| Input | Action |
|---|---|
| Left / Right | Walk. Facing aims the lamp |
| A | Jump. On a rope, let go |
| Down / Up | Climb a rope you have caught |
| B | Throw a flare — it lands, ignites, and burns down |
| Crank | Tilt the beam up and down. Tilted down the flare lands short; tilted up it goes long |
| A / B / Up / Down | Menus and the save slots |

## Rules

| Thing | Behaviour |
|---|---|
| The lamp | A short cone that burns 1.5 oil/s, 2.3 while you are standing in water. At zero it goes out and stays out until a lantern |
| Flares | Three at most. Thrown on an arc; where they land they light for 9s, then fade to nothing. Water snuffs one instantly |
| Crawlers | Advance on you only in darkness. Any light on them and they retreat from it. One white eye, visible only while lit |
| Clingers | Hang from the roof and drop on you when you pass beneath in the dark |
| Rockfall | Rigged roofs trickle dust for most of a second, then let go |
| Lanterns | Refill the lamp, restock the flares, restore your grit, save the game and become your respawn point. They stay lit |
| Crates | Two flares, restocked on a timer, so a depth can never dead-end for want of light |
| Grit | Three hits. At zero you wake at the last lantern with the depth's progress intact |
| Falling | More than about a floor and a half costs a grit. That is what the ropes are for |
| The Warden | Advances in darkness, and only light on it fills the pressure meter. The lamp alone works but is slow; a flare landed on it is worth three seconds. Three galleries |

## The shade case

Delve is not a platformer with a lighting filter. Take the light away
and there is no game left: the levels have no fog of war to reveal, no
enemy sight lines, no resource but oil and flares. Every rule reads off
`Light.at` and `Light.wall`.

## The engine-over-scratch case

Written from scratch this would have been a lighting engine with a game
attached. What the shared core actually supplied:

* **`core/light.lua`** did all of it. `Light.cone` is the helmet lamp,
  `Light.add` is a flare and a lantern and a glowworm seam,
  `Light.wall` turns the slab you stand on into the occluder that hides
  the floor below, and `Light.at` is the input to every creature's AI
  and the boss's pressure meter. Because the query runs the *same*
  disc/wedge/segment math the compositor draws, "that crawler is
  standing in the dark" is a fact rather than a guess — no shadow
  buffer, no visibility grid, no second source of truth to keep in sync.
  The stencil compositor is the single most expensive thing on screen
  and it cost this game zero lines.
* **`core/shade.lua`** is the whole art direction. Rock, slabs, water,
  the Warden's mass and the dithered props are `Shade.fill` /
  `Shade.over` at a chosen ramp level; there is not one image file in
  the game.
* **`core/kit.lua`** supplied the entire cabinet — the `Kit.run` loop
  with seeding and harness wiring, `Kit.meter` for the oil, `Kit.list`
  and `Kit.slots` for the pit-head menu and the save cards, panels,
  text, debris and screen shake.
* **`core/dstory.lua`** turned seven cutscenes into seven plain
  functions full of `say` / `fade` / `act`. The auto-advance in smoke
  builds is what lets an unattended headless run get through all of
  them.
* **`core/dsave.lua`** is the three-slot campaign save, including the
  JSON round-trip rules that `tools/headless.lua` reproduces, so save
  bugs surface off-device.
* **`core/dmusic.lua`** took five songs as data (patterns plus an
  order) instead of five sequencers, and `core/para.lua`,
  `core/cast.lua` and `core/fade.lua` covered the shaft's parallax, the
  delver's ground shadow and the iris in.

## Notes for the next agent

Things worth not rediscovering.

* **Chunk your `Light.wall` segments.** `light.lua` only carves a
  wall's shadow when one of the segment's *endpoints* lies inside that
  light's reach (the cheap reject in `carveShadows`). A single 376px
  floor edge is therefore invisible to the compositor while `Light.at`
  still honours it — pixels and logic disagree, in the direction the
  module's own header promises they never will. `C.WALL_CHUNK = 52`
  cuts each floor edge into pieces so the endpoints land in range.
  Budget: four slabs at eight chunks plus three `Light.box` props is
  ~40 walls, comfortably under the 64 cap; nearest slabs are registered
  first so that if the cap ever does bite, it bites the far ones.
  (The endpoint-only reject was an engine bug and has since been fixed
  in `carveShadows` — the chunking is kept as a budget control, since
  registering a whole depth's floor edges every frame is the easy way
  to blow the wall cap.)
* **Ambient is a three-value dial, not a continuum.** `Light.begin`
  quantizes to `K=3`, so every ambient below 0.5 is *identical* full
  dark. Authoring "depth 1 is dim, depth 8 is pitch black" by lowering
  `ambient` does nothing at all. Delve keeps one `C.AMBIENT` and varies
  the number of static glowworm lights per depth instead — that is the
  real darkness dial.
* **`Light.at` is not free.** Each call walks every light against every
  wall, so ~12 lights x ~40 walls per query. Mobs stagger their own
  query on `(frame + index) % C.LIT_EVERY` and cache the answer; the
  draw code reads that cache rather than re-querying for the eye pixel.
* **A generator that places solid props can brick its own level.** Every
  stall in this bot's development was the same bug: a rock prop
  straddling the point the delver *lands* on. Inside a solid box every
  axis is blocked including the jump, so the depth is unfinishable from
  the frame you arrive. `L.arrive[j]` is claimed before any prop is
  placed and there is a post-filter as well. If you generate solids,
  claim your arrival points.
* **A platformer bot needs a route, not a policy.** `L.route` is emitted
  by the generator as an ordered waypoint list and the bot only ever
  advances the index when a waypoint is satisfied or is on a floor
  already passed. Everything reactive (hop that rock, jump that hole,
  flare that crawler) sits *on top* of the latched plan. There is also
  a rewind (woke at a checkpoint above the plan), a recovery (landed on
  a floor the route skips — head for this floor's own hole) and a
  ten-second watchdog. Without the latch the bot oscillates between two
  targets and finishes nothing.
* **Ropes need a cooldown longer than a jump arc.** The rope's bottom is
  the floor you then walk on, so a jump taken beside it re-grabs at the
  top of the arc and the bot rides the same line forever. `G.ropeCd =
  0.9` on any jump, plus "only a falling delver grabs".
* **HUD text goes on solid black, always — and prove it.** The first
  build drew the status row straight onto the shaft dither and it was
  unreadable, with the depth name running into the oil meter at the
  longer names. The fix is one `Kit.panel` band holding every readout
  at FIXED x slots (no variable-length string in the band, so no two
  blocks can collide at any glyph width), plus `labelBoard`, which
  sizes a panel to its own measured string and trims the string rather
  than letting the board run into its neighbour. Worth stealing: a
  scratch harness that wraps `Kit.panel` and `gfx.drawText` in the
  stub, records their rects per frame, and asserts every text rect
  lands inside some panel rect — run at several `getTextSize` widths it
  catches both "on dither" and "collides at a wider font" without a
  Simulator.
* **`dstory`'s dialogue box holds two wrapped lines, not three.** The
  box is 58 tall at y=174 and the third wrapped line starts at y=225,
  already past the panel's bottom edge. Wrapping is at 314px with a
  portrait, so keep spoken lines under ~70 characters; splitting a long
  speech into two `say` calls reads better than crowding one anyway.
* **Budgets measured.** Whole campaign, autopilot, headless: ~8500-9400
  frames (about five minutes) with 0-1 deaths, stable across seeds
  1-24. Per frame: 5-8 lights, ~28-40 walls, `Light.stats().ms` around
  1ms in the stub. `lua tools/headless.lua delve` takes ~3s.

## Assets

Entirely procedural — no image or sound files. All art is drawn from
`Shade` / `Light` / `Cast` / `Fade` / `Para` primitives; the five songs
and every effect are the core synth. Code is original, MIT (see the
repo LICENSE).
