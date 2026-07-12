# Skimmer

A skimmer dragonfly flying fast and low over a pond at golden dusk,
into the screen — the super-scaler proof game for Dither's `Scaler`
module. Distance is scale AND tone: reeds and lily pads approach up
their mip ladders while the depth haze lifts, the water is a striped
perspective floor whose bands stream by as ripples (and meander in
slow S-curves), and your blob shadow on the water is the classic
Harrier grounding cue — it's how you judge height over the lilies.

## Controls

| Input | Action |
|---|---|
| D-pad | Fly — left/right across the pond, up/down between water and sky |
| Crank | Throttle trim — faster pays more per catch, slower is safer |
| A | Take off / fly again |
| B (title) | Toggle DAY / DUSK (dusk: low sun, the dragonfly glows) |

## Rules

| Thing | Behaviour |
|---|---|
| Reeds | Tall — dodge laterally (only the very top clears them) |
| Lily pads | Flat on the water — deadly only when you fly low |
| Midges | Bobbing clusters; fly through one to eat it (points x trim) |
| Dunks | Reed or lily contact; 3 lives, brief grace after each |
| Ramp | Speed climbs steadily; reed rows thicken with distance |
| Score | Midges eaten, multiplied by your trim; BEST saves on device |

## Assets

Entirely procedural — no image or sound files. Reed / lily / midge /
dragonfly art is drawn at boot and laddered via `Scaler.ladderFromFn`;
water, sky, treelines and lighting come from the shared
`Shade`/`Scaler`/`Para`/`Fade`/`Light`/`Cast` modules; music is the
core step-sequencer. Code is original, MIT (see repo LICENSE).
