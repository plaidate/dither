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

---

## Prowl

**A cat burgles a sleeping town. Ten heists, and the dark is the only
floor you can walk on.**

Every guard carries a lantern, and a lantern is a cone of light with a
hard edge. Crates, walls and pillars throw real shadows — the black
wedge behind a barrel is a place you can stand. You are seen when the
light finds you *and* nothing blocks the guard's line; the meter in the
corner fills while you're lit and drains while you're not, so being
clipped by a passing beam is survivable and standing in one is not.

### Controls

| Input | Action |
|---|---|
| D-pad | Walk |
| B (hold) | Creep — slow and silent; walking makes noise a guard can follow |
| A | Take the loot / douse a lamp / open the way out |
| A / B | Advance dialogue / skip a cutscene |

### How to play

Take every piece of loot on the screen, then reach the exit. Guards
walk fixed routes and swing their lanterns; noise pulls them off route
to investigate, which is a tool as much as a mistake — a sound in the
wrong corner buys you the right corridor.

Some lamps are fixed to the wall and can be **doused**, removing that
light for the rest of the night. Some lights have legs and no route at
all. The watchdog in the kennel doesn't care about light: it hears you.

### The ten nights

Fishmonger's Yard teaches the shadow. Cooper's Alley crosses two cones
so there is no single safe wedge. Lamplighter Row gives you dousing;
the Kennel takes sight out of the equation; Drunkard's Lane sends a
light wandering. The Counting House has no cover at all — the only
light is a floorwalker turning on the spot, and the game is timing.
Then the Bell Tower, the Gaol, Chapel Yard, and finally **Ashgrave
Manor**, where the Night Watchman sweeps a long beam down the hall
with the crown sitting under it. Lifting it wakes the house.

### Tips

1. **Watch the cone, not the guard.** Guards turn faster than they
   walk; the beam tells you where they'll be looking, not where they
   are.
2. **Shadows move.** A wedge that hides you now closes as its light
   walks past. Plan the shadow you'll be standing in, not this one.
3. **Creep near anything with ears.** Full speed is loud everywhere.
4. **Dousing is permanent.** Spend the trip if the room stays dark for
   the rest of the night.

---

## Beacon

**Ten nights on Vesper Rock. You own the only light for thirty miles,
and every hull out there is steering by it.**

The crank turns your beam. Up and Down trade its width against its
reach — the same light spread thin or thrown far. Fog eats the reach.
And a ship only answers the helm while your beam is *on* her: caught in
the bright core she turns at once, brushed by the fringe she comes
round slowly, and left in the dark she holds her course straight onto
the reef.

### Controls

| Input | Action |
|---|---|
| Crank | Swing the beam |
| Up / Down | Narrow and throw / widen and shorten the beam |
| A | Strike the lamp, advance dialogue |
| B | Shutter the lamp (saves oil); skips a cutscene |

### How to play

Stand every hull off the rocks before dawn. The tally at the top counts
those saved and those lost. Oil drains all night and a wide beam drains
it faster, so the shutter is a real choice — go dark to save fuel, and
hope nothing is drifting in while you do.

Two glazing bars sit in front of the filament and cast permanent blind
sectors into your own arc. They are narrow. They are also exactly where
a ship will be at the worst moment.

### The ten nights

Traffic first, then brigs that answer only the bright core, then
colliers that need a beam held on them for a second and a half.
Night 5 is fog. Night 6 puts a **wrecker** on the headland showing a
false light to lure hulls onto the rocks — smother it by holding your
beam on it. Then a squall that shoves the mechanism, a lifeboat you
must escort out and home on light alone, two wreckers at once, and a
final storm in which the lamp itself drowns and you crank it back to
life by hand.

### Tips

1. **Narrow reaches, wide catches.** Sweep wide to find a hull, then
   narrow to steer her.
2. **Turn her early.** A hull answers by degrees; the closer to the
   reef, the less a turn buys.
3. **Shutter between hulls,** not during — oil spent on empty water is
   a hull lost at dawn.
4. **Learn where your blind bars are** and swing through them, never
   park in them.

---

## Echo

**A bat, ten caverns, and no light at all. You see by shouting.**

The screen is black because the cave is black. Press A and you call:
a ring of sound spreads out, and for a moment the rock it touches is
visible. Then it fades. What you have between calls is memory — the
tunnel dimming in your head at about the rate you'd expect it to.

Distance reads as tone: close rock is crisp, far rock is a whisper of
grey, and the returning echo comes back pitched and delayed by the real
round trip. Listen and you can hear how far away the wall is.

### Controls

| Input | Action |
|---|---|
| D-pad | Fly — up/down and side to side |
| A | Call (costs breath) |
| Crank | Trim your speed |
| B | Skip a cutscene |

### How to play

Fly the cavern to its end without hitting rock. Calling costs breath;
moths refill it. That is the whole economy: call often enough to see,
eat enough to keep calling. The BREATH meter is your budget and the
DEPTH meter is how far through the cavern you are.

You always have a faint sense of the tunnel immediately around you, so
a missed call is not instant death — but the teeth in the roof are only
visible if you asked.

### The ten caverns

Stalactites, then the moth economy, then pillars and pinches. A wind
that moves you *between* glimpses. Still water that throws your call
back a second, softer time. Vesper, who calls to you and must be
answered. A roof so thin your own voice brings it down. Then everything
at once, and **Owl Light**: the owl closes on you steadily, closes
faster every time you call, and closest of all while you are lit. To
see is to be seen.

### Tips

1. **Call on a rhythm,** roughly every two seconds — a steady map beats
   a panicked one.
2. **Commit to what you saw.** Flying tentatively through a gap you
   already read wastes the reveal.
3. **Moths are fuel, not points.** Detour for them early, before the
   breath is gone.
4. **In the finale, silence is speed.** Fly the last gallery on as few
   calls as you can bear.

---

## Delve

**Ten depths down an old mine. Your lamp is running out, and the things
down here only move in the dark.**

The helmet lamp is a short cone pointing where you face. Flares are
light you can *throw*: one lands, burns where it fell, and holds a
patch of the shaft open. The creatures advance only through darkness,
so a flare is a wall — and a wall with a fuse.

### Controls

| Input | Action |
|---|---|
| D-pad | Walk, climb ropes, aim |
| A | Jump; light a lantern; advance dialogue |
| B | Throw a flare; skip a cutscene |

### How to play

Get down. Lanterns on the way are checkpoints, oil refills and save
points at once — light one and the shaft behind you stays yours.
Between them, the OIL meter falls, and when it empties you are down to
what you can throw.

Flares are finite and pooled per depth. Spending one to *see* a route
and spending one to *hold back* a swarm are the same resource, which is
the whole game.

### The ten depths

The Adit, Crawlways, then **The Long Fall** — no glowing seams, so the
only way to read the route is to throw a flare ahead and look. The Sump
drowns any flare that lands in water. Rockfall, then the Swarm, then
the Rope Gallery. **The Collapse** takes your lamp and leaves you two
flares. The Cold Seam, and finally the **Deep Gallery**, where the
Warden has to be driven back through three galleries by light alone —
your lamp pushes it slowly, a flare landed at its feet pushes it hard,
and it follows you between floors.

### Tips

1. **Throw before you fall.** A flare down a shaft you can't read costs
   one flare; a blind drop costs the run.
2. **Light every lantern.** They're the only oil in the mine.
3. **A flare on the ground beats a flare in the air** — lead the thing
   you're pushing, don't hit it.
4. **Water kills flares.** In the Sump, throw at ledges.
