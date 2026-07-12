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

---

## Glim

**A firefly-keeper in a walled night garden. Your lantern is the only
thing between you and the dark — and it's burning.**

The garden is pitch black past your lantern's reach. Fireflies drift
about as tiny sparks of their own light; anything else out there, you
won't see until your lamp finds it. Jar as many fireflies as you can
before the wick gutters out.

### Controls

| Input | Action |
|---|---|
| D-pad | Walk the keeper |
| Crank | Trim the wick — crank up for a bigger, brighter lantern |
| B | Lantern pulse — a flare that shoos nearby moths |
| A | Light the lantern / start the next night |

### How to play

The crank sets your lantern's radius, and the radius sets the burn:
a wide flame eats the wick fast, a low flame sips it. The wick never
stops draining — every night ends. Your score is the fireflies you
jar before it does; the best night is saved on the device.

Fireflies wander the garden, glowing on their own. Any firefly inside
your lantern's light drifts toward you — walk it over to the **jar**
in the bottom-left corner and it hops in (+1). Herding works best at
a walking pace: rush and the firefly falls out of your light.

### The moths

Moths are the dark's own creatures. Outside light they are invisible
*and inert* — a moth no light touches does not move at all. Step too
close with your lantern and it wakes, flying straight at the flame;
on contact it bites a chunk out of your wick and scatters the
fireflies you'd gathered. Press **B** to pulse the lantern — a brief
flare that costs a sliver of wick and sends every lit moth tumbling
back into the dark.

As the night wears on the moths get faster and more numerous, and new
fireflies arrive more rarely. The low-wick murmur means the flame is
guttering — bank what you can.

### Tips

1. **Dim is thrift.** Crank the wick low while you cross empty
   ground; open it up only to sweep for fireflies.
2. **A small light wakes fewer moths.** The bigger your lantern, the
   more of the garden's moths are lit — and stalking.
3. **Pulse early.** A moth shooed at the edge of your light costs 2
   wick; a moth that reaches the lantern costs 9.
4. **Walk fireflies, don't sprint them.** They chase your light at
   less than your top speed; pause and let them catch up.
5. **The jar glows when you're near** — use its light as a free porch
   lamp while you funnel flies into the corner.

---

## Skimmer

**A dragonfly, a pond at golden dusk, and everything streaming
toward you. Fly fast, fly low — but not *that* low.**

You are a skimmer dragonfly racing over the water into the screen.
Reeds rush up out of the haze, lily pads slide by under your wings,
and clouds of midges hang in the lanes waiting to be eaten. The pond
never ends; the question is how far — and how well fed — you get on
three lives.

### Controls

| Input | In flight | On the title screen |
|---|---|---|
| D-pad Left / Right | Bank across the pond | — |
| D-pad Up / Down | Climb / dive (water to sky) | — |
| Crank | Throttle trim — forward for speed, back for safety | — |
| A | — | Take off |
| B | — | Toggle DAY / DUSK |

After a flight, press A to return to the title. The system menu also
has a **restart** item that drops you back to the title.

### How to play

The world streams toward you and only gets faster. Steer around the
**reeds** (tall, dark, rooted in the water — only the highest sliver
of sky clears them, so dodge sideways), and mind the **lily pads**:
they lie flat on the surface and only matter when you fly low.
Clipping either is a dunk — you lose one of three lives, shake off
the splash, and get a moment of grace.

Fly through a **midge cluster** to eat it. Every catch is worth its
points times your current **trim** — the crank sets your throttle
between x0.7 (slow, safe, cheap catches) and x1.4 (fast, deadly,
rich catches). The multiplier is live on the HUD.

**Watch your shadow.** The dark blob on the water directly below you
is your altimeter: wide and dark means you're skimming the surface
(lily territory), small and pale means you're up in the safe air.
It's the only height cue you get — trust it.

### Day and dusk

On the title screen, B toggles the time of day. **DAY** is bright
and plain. **DUSK** drops the sun onto the treeline, darkens the
pond, and gives your dragonfly a faint glow that carries with you —
prettier, and every bit as playable.

### Tips

1. **Live in the middle air.** Cruising above lily height with room
   under the reed tops means only reeds can touch you — and those
   you dodge sideways.
2. **Dive on purpose, briefly.** Midges often hang low; drop, eat,
   climb. Loitering at deck level is how lilies get you.
3. **Trim rich when the pond is open.** Early rows are sparse — run
   x1.3+ and bank fat catches. Back it off when the reeds thicken.
4. **The safe lane exists.** Every reed row leaves at least one gap,
   and it drifts only a lane at a time — follow the gaps, not the
   panic.
5. **Use the grace.** After a dunk you're briefly untouchable —
   spend it repositioning into a clear lane, not hesitating.
