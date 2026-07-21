-- Beacon: the campaign. Ten nights on Vesper Rock, each one a table
-- read by Game.startPlay(). Nothing here is code — the escalation IS
-- the data: more hulls, thicker fog, less oil, and one new idea per
-- night until the last one has all of them at once.
--
--   name    the log-book heading
--   line    the harbourmaster's one-line forecast (shown on the card)
--   ships   how many hulls the night sends
--   kinds   the pool they are drawn from (see C.KINDS)
--   gap     { min, max } seconds between hulls
--   quota   hulls that must stand off safely (display; = ships - allow)
--   allow   wrecks tolerated before the night is lost
--   oil     the can you are given, out of C.OIL_CAP
--   fog0/1  fog at dusk and at its full weight (C.FOG_FULL seconds in)
--   rocks   reefs seeded in the bay
--   wreckers false lights on the headland
--   lifeboat a rescue you must escort out and back
--   wind    the squall that swings the mechanism
--   fail    the lamp itself dies partway through (night 10 only)
--   song    which bed plays

Nights = {}

Nights.list = {
    {
        name = "FIRST WATCH",
        line = "A flat calm. Learn the arc of your own light.",
        ships = 3, kinds = { "smack" }, gap = { 5.0, 6.5 },
        allow = 1, oil = 120, fog0 = 0.00, fog1 = 0.08,
        rocks = 2, song = "CALM",
    },
    {
        name = "THE EBB",
        line = "Four out of Kirkhaven, and a haar making up.",
        ships = 4, kinds = { "smack", "smack", "steamer" },
        gap = { 4.6, 6.0 },
        allow = 1, oil = 116, fog0 = 0.05, fog1 = 0.22,
        rocks = 3, song = "CALM",
    },
    {
        name = "HEAVY WEATHER",
        line = "Brigs. Deep hulls answer only the heart of a beam.",
        ships = 4, kinds = { "brig", "smack", "brig", "steamer" },
        gap = { 4.8, 6.2 },
        allow = 1, oil = 112, fog0 = 0.08, fog1 = 0.28,
        rocks = 3, song = "SWELL",
    },
    {
        name = "THE COLLIER",
        line = "Coal out of Blyth. Her master trusts nothing brief.",
        ships = 5, kinds = { "collier", "smack", "brig", "collier", "smack" },
        gap = { 4.4, 5.8 },
        allow = 2, oil = 106, fog0 = 0.10, fog1 = 0.32,
        rocks = 3, song = "SWELL",
    },
    {
        name = "THE FOG BANK",
        line = "You will not see them. You will only find them.",
        ships = 5, kinds = { "smack", "steamer", "smack", "brig", "smack" },
        gap = { 4.4, 5.6 },
        allow = 2, oil = 102, fog0 = 0.40, fog1 = 0.78,
        rocks = 3, song = "SWELL",
    },
    {
        name = "THE FALSE LIGHT",
        line = "Something burns on the headland that is not yours.",
        ships = 5, kinds = { "smack", "brig", "steamer", "collier", "smack" },
        gap = { 4.4, 5.6 },
        allow = 2, oil = 98, fog0 = 0.14, fog1 = 0.36,
        rocks = 3, wreckers = 1, song = "GALE",
    },
    {
        name = "THE SQUALL",
        line = "The mechanism will fight your hand tonight.",
        ships = 6, kinds = { "smack", "steamer", "brig", "smack", "steamer",
            "collier" },
        gap = { 4.2, 5.4 },
        allow = 2, oil = 94, fog0 = 0.18, fog1 = 0.42,
        rocks = 4, wind = true, song = "GALE",
    },
    {
        name = "THE LIFEBOAT",
        line = "Pull her out, hold her lit, and bring her home.",
        ships = 4, kinds = { "smack", "brig", "steamer", "smack" },
        gap = { 5.2, 6.6 },
        allow = 2, oil = 102, fog0 = 0.24, fog1 = 0.50,
        rocks = 3, lifeboat = true, song = "SWELL",
    },
    {
        name = "TWO LIGHTS",
        line = "Both headlands are lying to the sea.",
        ships = 6, kinds = { "brig", "smack", "collier", "steamer", "smack",
            "brig" },
        gap = { 4.2, 5.4 },
        allow = 2, oil = 90, fog0 = 0.30, fog1 = 0.58,
        rocks = 4, wreckers = 2, song = "GALE",
    },
    {
        name = "THE LONG NIGHT",
        line = "Everything at once, and then the lamp goes out.",
        ships = 7, kinds = { "steamer", "brig", "smack", "collier", "brig",
            "steamer", "smack" },
        gap = { 4.0, 5.2 },
        allow = 3, oil = 98, fog0 = 0.34, fog1 = 0.66,
        rocks = 4, wreckers = 2, lifeboat = true, wind = true,
        fail = true, song = "GALE",
    },
}

Nights.COUNT = #Nights.list

function Nights.get(n)
    return Nights.list[Util.clamp(n, 1, Nights.COUNT)]
end

-- the quota shown on the night card: hulls that must stand off
function Nights.quota(spec)
    return math.max(1, spec.ships - (spec.allow or 1))
end
