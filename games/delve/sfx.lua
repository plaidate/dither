-- Delve: synth-only sound and five step-sequencer songs. Each band of
-- the campaign gets its own bed so a twenty-minute descent is not one
-- loop: SHAFT for the dry upper workings, WATER for the flooded
-- middle, DEEP for the cold seams, WARDEN for the finale, and a slow
-- WINDLASS for the title and the ending. Stingers ride over the top.

Sfx = {}

-- ---- songs -----------------------------------------------------------

-- the upper workings: a pick-and-boot two-bar shuffle in D minor
Sfx.SHAFT = {
    bpm = 92, len = 16,
    patterns = {
        A = {
            bass = { 38, 0, 0, 0, 38, 0, 0, 0, 45, 0, 0, 0, 43, 0, 0, 0 },
            lead = { 0, 0, 62, 0, 0, 0, 65, 0, 0, 0, 62, 0, 0, 0, 57, 0 },
            hat  = { 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0 },
        },
        B = {
            bass = { 36, 0, 0, 0, 36, 0, 43, 0, 41, 0, 0, 0, 38, 0, 0, 0 },
            lead = { 0, 0, 60, 0, 0, 63, 0, 0, 0, 0, 65, 0, 62, 0, 0, 0 },
            hat  = { 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0 },
        },
    },
    order = { "A", "A", "B", "A" },
}

-- flooded middle: everything drips, the lead answers a beat late
Sfx.WATER = {
    bpm = 78, len = 16,
    patterns = {
        A = {
            bass = { 33, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 36, 0, 0, 0 },
            lead = { 0, 0, 0, 67, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 70, 0 },
            hat  = { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 },
        },
        B = {
            bass = { 31, 0, 0, 0, 0, 0, 38, 0, 0, 0, 0, 0, 34, 0, 0, 0 },
            lead = { 0, 0, 65, 0, 0, 0, 0, 68, 0, 0, 0, 0, 63, 0, 0, 0 },
        },
        C = {
            bass = { 33, 0, 0, 0, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 0, 0, 0, 0, 74, 0, 0, 0, 72, 0, 0, 0, 67, 0 },
            hat  = { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
    order = { "A", "B", "A", "C" },
}

-- cold seams: a 32-step crawl, tritone lead, almost no hat
Sfx.DEEP = {
    bpm = 66, len = 32,
    patterns = {
        A = {
            bass = { 29, 0, 0, 0, 0, 0, 0, 0, 29, 0, 0, 0, 0, 0, 0, 0,
                     35, 0, 0, 0, 0, 0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 0, 0, 0, 0, 59, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                     0, 0, 0, 0, 65, 0, 0, 0, 0, 0, 0, 0, 61, 0, 0, 0 },
            hat  = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
                     0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
        },
        B = {
            bass = { 28, 0, 0, 0, 0, 0, 0, 0, 34, 0, 0, 0, 0, 0, 0, 0,
                     28, 0, 0, 0, 0, 0, 0, 0, 33, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0,
                     0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
    order = { "A", "A", "B", "A" },
}

-- the Warden: driving, a semitone shove on the four
Sfx.WARDEN = {
    bpm = 116, len = 16,
    patterns = {
        A = {
            bass = { 26, 0, 26, 0, 27, 0, 26, 0, 26, 0, 26, 0, 31, 0, 30, 0 },
            lead = { 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0 },
            hat  = { 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1 },
        },
        B = {
            bass = { 26, 0, 33, 0, 26, 0, 32, 0, 26, 0, 31, 0, 26, 0, 30, 0 },
            lead = { 74, 0, 0, 0, 73, 0, 0, 0, 71, 0, 0, 0, 68, 0, 66, 0 },
            hat  = { 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0 },
        },
    },
    order = { "A", "A", "B", "B" },
}

-- title and ending: a windlass turning somewhere above you
Sfx.WINDLASS = {
    bpm = 60, len = 16,
    patterns = {
        A = {
            bass = { 41, 0, 0, 0, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 0, 69, 0, 67, 0 },
        },
        B = {
            bass = { 43, 0, 0, 0, 0, 0, 0, 0, 38, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 0, 0, 76, 0, 0, 0, 74, 0, 0, 0, 0, 0, 72, 0 },
            hat  = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
    order = { "A", "B", "A", "A" },
}

Sfx.SONGS = {
    SHAFT = Sfx.SHAFT, WATER = Sfx.WATER, DEEP = Sfx.DEEP,
    WARDEN = Sfx.WARDEN, WINDLASS = Sfx.WINDLASS,
}

-- ---- effects ---------------------------------------------------------

function Sfx.step()       -- boot on rock
    Snd.play("noise", 260, 0.03, 0.08)
end

function Sfx.jump()
    Snd.play("square", 300, 0.05, 0.12)
end

function Sfx.land()
    Snd.play("noise", 180, 0.06, 0.14)
end

function Sfx.throw()      -- the flare leaves your hand
    Snd.play("square", 480, 0.05, 0.16)
    Util.after(0.05, function() Snd.play("noise", 900, 0.05, 0.12) end)
end

function Sfx.ignite()     -- and catches where it lands
    Snd.play("noise", 1200, 0.14, 0.24)
    Util.after(0.08, function() Snd.play("tri", 880, 0.2, 0.14) end)
end

function Sfx.snuff()      -- ... unless it lands in water
    for i = 0, 2 do
        Util.after(i * 0.05, function()
            Snd.play("noise", 420 - i * 110, 0.09, 0.2)
        end)
    end
end

function Sfx.lantern()    -- a checkpoint takes
    Snd.play("tri", 523, 0.1, 0.22)
    Util.after(0.1, function() Snd.play("tri", 784, 0.16, 0.2) end)
    Util.after(0.24, function() Snd.play("tri", 1047, 0.22, 0.16) end)
end

function Sfx.crate()
    Snd.play("square", 392, 0.06, 0.16)
    Util.after(0.06, function() Snd.play("square", 587, 0.08, 0.14) end)
end

function Sfx.bite()
    Snd.play("noise", 160, 0.12, 0.3)
    Util.after(0.06, function() Snd.play("saw", 120, 0.14, 0.22) end)
end

function Sfx.repel()      -- something backs out of the light
    Snd.play("saw", 300, 0.08, 0.14)
    Util.after(0.07, function() Snd.play("saw", 210, 0.1, 0.12) end)
end

function Sfx.rock()       -- roof letting go
    Snd.boom(300, 4)
end

function Sfx.hurt()
    Snd.play("saw", 200, 0.16, 0.3)
end

function Sfx.down()       -- a grit spent, waking at the last lantern
    for i = 0, 3 do
        Util.after(i * 0.11, function()
            Snd.play("tri", 330 - i * 52, 0.2, 0.18)
        end)
    end
end

function Sfx.clear()      -- a depth finished
    Music.sting{ 60, 64, 67, 72 }
end

function Sfx.phase()      -- the Warden gives ground
    Music.sting{ 48, 55, 60, 67, 72 }
    Snd.boom(220, 5)
end

function Sfx.win()
    Music.sting{ 60, 67, 72, 76, 79, 84 }
end
