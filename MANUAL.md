# Dither — Player's Manual

Original 1-bit pixel/sprite games for the Playdate, one shared core.
One section per game.

---

## Sprint

**Top-down circuit racing: the crank is your steering wheel.**

Somewhere between the county fair and the scrapyard, four buzzing little
cars line up on a single-screen circuit. Three of them are drones that
never miss an apex. The fourth one is yours — and yours is the only one
with a real wheel. Grab the crank and out-drive them.

### Controls

| Input | In race | On the title screen |
|---|---|---|
| Crank | Steer — the crank IS the wheel | — |
| D-pad Left / Right | Steer at full lock (crank-free fallback) | Choose 3 or 5 laps |
| D-pad Up / Down | — | Choose track (1–8) |
| A | Throttle | Start the race |
| B | Brake / reverse | Start the race |
| A or B (during 3‑2‑1) | Skip the countdown | |

After a race, press A or B to return to the title screen. The system
menu also has a **restart** item that drops you back to the title.

### How to play

Pick a track (eight of them, rated Easy and up) and a race length
(3 or 5 laps), then race the three drones around the circuit. Steering
is direct: one full crank turn spins the car all the way around, so you
drive with small, deliberate wrist motions — about a sixteenth of a
crank turn per car heading step. Hold A to accelerate, tap B to brake
(hold it to reverse). Let go of A and the car coasts down gently.

Stay on the dark road. The bright dithered areas are walls and
infield — scraping one scrubs your speed down to a crawl, and hitting
one head-on nearly stops you. Your car is the **solid white** one with
the little bobbing caret above it; the drones are **hollow outlines**.

- **Laps and standings** — your position (1st–4th) is live, measured by
  laps plus distance around the racing line. Finish your lap count in
  1st to win.
- **Lap timer** — the clock starts at GO. Your last lap and your best
  lap show at the top right; the best lap **per track** is saved on the
  device forever, so every track has its own record to chase.
- **Countdown** — races start with a 3‑2‑1. Press A or B to skip it
  (the lap clock starts either way at GO).

### Hazards

- **Walls** (everything off the road): a glancing scrape caps you at
  about a quarter of top speed; a square hit stops you almost dead. The
  car can always rotate freely against a wall, so steer out and drive on
  — or tap B to back out.
- **Drone cars** (three of them): they run fixed racing lines at fixed
  speeds — one hugs the inside, one the outside, one the centre, each a
  little faster than the last. They never crash and never yield. Touch
  one and you get shoved clear and lose a slice of your speed; the drone
  doesn't feel a thing.

### Tips

1. **You are faster than every drone** — top speed beats even the
   quickest one. You don't have to out-corner them, just keep the
   throttle down on the straights and don't hit anything.
2. **Walls cost more than brakes.** A scrape drops you to a crawl;
   braking early for a hairpin costs far less. When in doubt, brake.
3. **Coast into sweepers, brake for hairpins.** Releasing A bleeds
   speed gently — often enough for fast corners. Save B for the tight
   stuff.
4. **Reverse is your unstick button.** Nosed into a wall? Hold B — the
   car backs up, then swing the crank and go.
5. **Pass on the empty lane.** The drones hold inside, centre and
   outside lines. Whichever lane the nearest drone isn't using is your
   overtaking lane; contact only ever slows *you*.
6. **Learn one track's record line.** Best laps save per track, so
   pick a favourite and grind the record — 3-lap races are the fastest
   way to get clean timed laps.

### Known quirk

Tracks 2, 4, 6 and 8 originally have bridges (an upper deck). This port
drives the lower deck throughout — everyone on the same level, fair and
square.
