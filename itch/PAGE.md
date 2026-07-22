# Dither — itch.io page copy

## Tagline

Seven 1-bit games where the darkness is a mechanic, not a mood.

## Description

The Playdate screen has two colours. **Dither** is a collection of seven
original games built on a shared engine that treats the *illusion* of
grey — dithered light, shadow and distance — as something you play
with rather than something you look at.

Every game here has to earn that. Each one hides something in the dark,
reveals something with light, or makes distance readable by tone:

- **Prowl** — a cat burgles a sleeping town. Guards carry lanterns, and
  a lantern is a cone of light with a hard edge; crates and walls throw
  real shadows you can stand in. Ten heists, ending under the Night
  Watchman's sweeping beam.
- **Beacon** — ten nights keeping a lighthouse. The crank swings your
  beam through the fog, and a ship only answers her helm while the
  light is on her: caught in the bright core she turns at once, left in
  the dark she holds her course onto the reef.
- **Echo** — a bat in a cave with no light in it at all. Press A and you
  call; for a moment the tunnel is visible, and then it isn't. Ten
  caverns flown on memory, with an owl at the end that closes fastest
  while you are lit.
- **Delve** — ten depths of an old mine. Your helmet lamp burns down,
  and the flares you throw stay where they land: the things down here
  only advance through darkness, so a flare is a wall you build out of
  light, with a fuse.
- **Sprint** — top-down circuit racing where the crank is literally
  your steering wheel. Eight tracks, three drone rivals, and a
  time-of-day switch that turns the last race into headlights in the
  dark.
- **Glim** — a firefly-keeper in a walled night garden. The crank trims
  your lantern's wick: a wider flame shows you more and burns out
  sooner. Moths outside the light don't move at all until you find them.
- **Skimmer** — a dragonfly over a pond, flying into the screen. Read
  your altitude off your own shadow and the distance off the haze.

## Features

- Seven games on one shared engine, each with its own idea about light
- Four full campaigns (Prowl, Beacon, Echo, Delve) with ten stages
  apiece, cutscenes, saved progress and their own soundtracks
- Dynamic lighting with real occluders — walls and crates cast shadows
  the game logic agrees with, so hiding actually hides you
- Crank-driven mechanics that aren't just steering: a lighthouse beam,
  a lantern wick, a throttle
- All-synth sound, all-procedural art, and a 1-bit screen used on purpose
- Progress and records saved on the device, per game

## Installing (no dev tools needed)

Download the `.pdx.zip` for the game you want from Releases (or
`dist/`), then either:

- **On a Playdate**: upload the zip at
  https://play.date/account/sideload/ and download it to the device
  from Settings → Games, or
- **In the Playdate Simulator** (free with the Playdate SDK): unzip and
  open the `.pdx` in the Simulator.

The full player's manual — controls, rules and tips for all seven
games — ships in the repo as `MANUAL.md`. How the engine works, and how
to add a game to it, is in `DESIGN.md` and `DEVGUIDE.md`.

## Controls

Every game: **A** confirms and **B** cancels or skips; the **crank** is
the star of Sprint (steering), Beacon (the beam), Glim (the wick) and
Skimmer (the throttle). Per-game controls are listed in `MANUAL.md`.
