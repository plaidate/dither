-- Echo: synth-only sound, and four beds. In a game you play by ear,
-- the sound effects are not decoration -- Sfx.ret is the OTHER half
-- of the thesis: a returning echo's DELAY is the real round trip
-- (2*distance / PING_SPD) and its PITCH falls with distance, so a
-- player who is listening knows how far the rock is before the light
-- shows it. Everything rides Util.after, which Kit.run ticks.
--
-- Beds: DRIP (menus, cold water in the dark), CAVE (the first four
-- caverns, patient), DEEP (the middle, minor and lower), HUNT (the
-- last two, a driven pulse -- the owl's cavern).

Sfx = {}

-- ---- the beds ---------------------------------------------------------

Sfx.DRIP = {
    bpm = 72,
    patterns = {
        A = {
            bass = { 36, 0, 0, 0, 0, 0, 0, 0, 31, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 72, 0, 0, 0, 0, 67, 0, 0, 0, 0, 75, 0, 0, 0 },
        },
        B = {
            bass = { 36, 0, 0, 0, 0, 0, 0, 0, 34, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 0, 79, 0, 0, 74, 0, 0, 0, 70, 0, 0, 0, 0, 0 },
        },
    },
    order = { "A", "B" },
}

Sfx.CAVE = {
    bpm = 88,
    patterns = {
        A = {
            bass = { 40, 0, 0, 0, 40, 0, 0, 0, 35, 0, 0, 0, 38, 0, 0, 0 },
            lead = { 0, 0, 64, 0, 0, 67, 0, 0, 0, 0, 71, 0, 0, 67, 0, 0 },
            hat  = { 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0 },
        },
        B = {
            bass = { 43, 0, 0, 0, 43, 0, 0, 0, 40, 0, 0, 0, 35, 0, 0, 0 },
            lead = { 74, 0, 0, 71, 0, 0, 67, 0, 64, 0, 0, 67, 0, 0, 0, 0 },
            hat  = { 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0 },
        },
    },
    order = { "A", "A", "B", "A" },
}

Sfx.DEEP = {
    bpm = 96,
    patterns = {
        A = {
            bass = { 33, 0, 0, 33, 0, 0, 36, 0, 31, 0, 0, 31, 0, 0, 28, 0 },
            lead = { 0, 0, 63, 0, 0, 66, 0, 0, 68, 0, 0, 66, 0, 63, 0, 0 },
            hat  = { 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0 },
        },
        B = {
            bass = { 29, 0, 0, 29, 0, 0, 32, 0, 34, 0, 0, 34, 0, 0, 0, 0 },
            lead = { 70, 0, 68, 0, 66, 0, 63, 0, 61, 0, 63, 0, 66, 0, 0, 0 },
            hat  = { 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1 },
        },
    },
    order = { "A", "A", "B", "B" },
}

Sfx.HUNT = {
    bpm = 118,
    patterns = {
        A = {
            bass = { 28, 0, 28, 0, 31, 0, 28, 0, 26, 0, 26, 0, 29, 0, 31, 0 },
            lead = { 0, 0, 0, 0, 75, 0, 0, 0, 0, 0, 0, 0, 73, 0, 0, 0 },
            hat  = { 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1 },
        },
        B = {
            bass = { 26, 0, 26, 0, 26, 0, 29, 0, 31, 0, 31, 0, 33, 0, 0, 0 },
            lead = { 79, 0, 78, 0, 75, 0, 73, 0, 71, 0, 73, 0, 75, 0, 78, 0 },
            hat  = { 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1 },
        },
    },
    order = { "A", "B", "A", "B" },
}

Sfx.SONGS = {
    CAVE = Sfx.CAVE, DEEP = Sfx.DEEP, HUNT = Sfx.HUNT, DRIP = Sfx.DRIP,
}

-- ---- the voice ---------------------------------------------------------

-- the call itself: a short rising chirp, quiet (it is a bat, not a horn)
function Sfx.ping()
    Snd.play("tri", 1760, 0.045, 0.20)
    Util.after(0.04, function() Snd.play("tri", 2637, 0.05, 0.16) end)
end

function Sfx.whisper()
    Snd.play("tri", 1245, 0.05, 0.11)
end

function Sfx.dry() -- nothing left to call with
    Snd.play("noise", 300, 0.05, 0.08)
end

-- a return: dz is how far away the thing that bounced it is. Pitch
-- falls with distance, so the ear reads depth the way the screen does.
function Sfx.ret(dz, vol)
    local u = Util.clamp(dz / C.PING_REACH, 0, 1)
    local f = 320 + 980 * (1 - u) ^ 1.4
    Snd.play("square", f, 0.05, vol or 0.10)
    Harness.count("echoes")
end

-- the pool throwing your own voice back at you
function Sfx.wet()
    Snd.play("tri", 660, 0.14, 0.12)
    Util.after(0.1, function() Snd.play("tri", 880, 0.16, 0.09) end)
end

function Sfx.moth()
    Snd.play("tri", 1397, 0.05, 0.24)
    Util.after(0.05, function() Snd.play("tri", 1865, 0.08, 0.22) end)
end

function Sfx.crash()
    Snd.play("tri", 98, 0.2, 0.3)
    Snd.boom(280, 4)
end

function Sfx.scrape()
    Snd.play("noise", 180, 0.07, 0.14)
end

-- Vesper's call: lower than yours, and unmistakable
function Sfx.call()
    Snd.play("tri", 988, 0.09, 0.18)
    Util.after(0.09, function() Snd.play("tri", 784, 0.12, 0.15) end)
end

function Sfx.answer()
    Music.sting{ 76, 79, 83, 88 }
end

function Sfx.owl()
    Snd.play("saw", 220, 0.22, 0.20)
    Util.after(0.18, function() Snd.play("saw", 165, 0.3, 0.17) end)
end

function Sfx.strike()
    Snd.play("noise", 420, 0.2, 0.34)
    Snd.boom(520, 5)
    Music.sting{ 48, 47, 43 }
end

function Sfx.clear()
    Music.sting{ 72, 76, 79, 84 }
end

function Sfx.fail()
    Music.sting{ 60, 56, 51, 44 }
end

function Sfx.tick()
    Snd.play("square", 520, 0.04, 0.12)
end

function Sfx.select()
    Snd.play("square", 740, 0.06, 0.16)
end
