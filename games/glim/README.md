# Glim

A firefly-keeper in a walled night garden — the identity game for
Dither's shade stack. Your lantern is a real dynamic light: the crank
trims the wick, so a brighter lantern burns it down faster. Lead the
fireflies (each one its own tiny glow) into the jar before the wick
dies, and mind the moths — dark sprites the darkness genuinely hides,
whose AI only advances while they stand in light (`Light.at` gates
them: darkness is mechanics, not paint).

## Controls

| Input | Action |
|---|---|
| D-pad | Walk the keeper |
| Crank | Trim the wick — up brightens (burns faster), down dims |
| B | Lantern pulse: shoos nearby lit moths (costs a little wick) |
| A | Light the lantern / start the next night |

## Rules

| Thing | Behaviour |
|---|---|
| Wick | Drains ~radius^1.5; at zero the night ends (game over) |
| Fireflies | Wander; inside your lantern they drift toward you |
| The jar | Bottom-left; a firefly within reach gets jarred (+1) |
| Moths | Invisible and frozen in darkness; lit ones fly at your lantern and steal wick on contact |
| Ramp | Firefly respawns slow down; moths speed up and multiply |
| Score | Fireflies jarred when the wick dies; BEST saves on device |

## Assets

Entirely procedural — no image or sound files. All art is drawn from
the shared `Shade`/`Light`/`Cast`/`Fade`/`Para` modules; music is the
core step-sequencer. Code is original, MIT (see repo LICENSE).
