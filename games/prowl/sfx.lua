-- Prowl: synth-only sound and the six beds. The town is scored in A
-- minor and gets one song per act, so a campaign never loops the same
-- sixteen steps for twenty minutes:
--
--   TITLE   the sign over the door
--   PROWL   heists 1-3, sparse and patient (verse/verse/turn/verse)
--   WATCH   heists 4-6, a walking bass -- something is awake
--   GAOL    heists 7-9, minor sixths and a hat on every other step
--   MANOR   the finale, 32 steps, the Watchman's long tread
--   CHASE   swapped in the moment a guard actually knows where you are
--
-- Stingers ride over whichever bed is playing (Music.sting), so the
-- loot chime never interrupts the sequencer clock.

Sfx = {}

Sfx.TITLE = {
    bpm = 74,
    bass = { 33, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0, 0, 0, 0, 31, 0 },
    lead = { 0, 0, 69, 0, 0, 0, 72, 0, 0, 0, 0, 76, 0, 0, 0, 0 },
    hat  = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
}

Sfx.PROWL = {
    bpm = 88, len = 16,
    patterns = {
        A = {
            bass = { 33, 0, 0, 0, 33, 0, 0, 0, 31, 0, 0, 0, 28, 0, 0, 0 },
            lead = { 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0 },
            hat  = { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 },
        },
        B = {
            bass = { 36, 0, 0, 0, 35, 0, 0, 0, 33, 0, 0, 0, 31, 0, 0, 0 },
            lead = { 76, 0, 74, 0, 72, 0, 0, 0, 69, 0, 0, 0, 0, 0, 67, 0 },
            hat  = { 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 },
        },
    },
    order = { "A", "A", "B", "A" },
}

Sfx.WATCH = {
    bpm = 100, len = 16,
    patterns = {
        A = {
            bass = { 33, 0, 40, 0, 33, 0, 40, 0, 31, 0, 38, 0, 31, 0, 38, 0 },
            lead = { 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 67, 0, 0, 0 },
            hat  = { 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0 },
        },
        B = {
            bass = { 28, 0, 35, 0, 28, 0, 35, 0, 29, 0, 36, 0, 29, 0, 36, 0 },
            lead = { 72, 0, 0, 71, 0, 0, 69, 0, 0, 67, 0, 0, 64, 0, 0, 0 },
            hat  = { 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
        },
    },
    order = { "A", "A", "B", "B" },
}

Sfx.GAOL = {
    bpm = 108, len = 16,
    patterns = {
        A = {
            bass = { 29, 0, 0, 29, 0, 36, 0, 0, 27, 0, 0, 27, 0, 34, 0, 0 },
            lead = { 0, 0, 68, 0, 0, 0, 65, 0, 0, 0, 63, 0, 0, 0, 60, 0 },
            hat  = { 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
        },
        B = {
            bass = { 24, 0, 0, 0, 31, 0, 0, 0, 26, 0, 0, 0, 33, 0, 0, 0 },
            lead = { 72, 71, 0, 69, 68, 0, 65, 0, 63, 0, 0, 60, 0, 0, 0, 0 },
            hat  = { 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0 },
        },
    },
    order = { "A", "B", "A", "B" },
}

-- the finale: 32 steps so the Watchman's beam and the bass line take
-- the same long walk down the hall
Sfx.MANOR = {
    bpm = 84, len = 32,
    patterns = {
        A = {
            bass = { 21, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0, 0, 0, 0, 0, 0,
                     23, 0, 0, 0, 0, 0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 0, 0, 60, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0,
                     0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 65, 0, 0, 0, 0, 0 },
            hat  = { 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
                     1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
        },
        B = {
            bass = { 21, 0, 21, 0, 23, 0, 23, 0, 24, 0, 24, 0, 26, 0, 26, 0,
                     28, 0, 28, 0, 26, 0, 26, 0, 24, 0, 24, 0, 23, 0, 0, 0 },
            lead = { 84, 0, 0, 0, 83, 0, 0, 0, 81, 0, 0, 0, 80, 0, 0, 0,
                     78, 0, 0, 0, 76, 0, 0, 0, 75, 0, 0, 0, 72, 0, 0, 0 },
            hat  = { 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
                     1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1 },
        },
    },
    order = { "A", "A", "B", "A" },
}

Sfx.CHASE = {
    bpm = 132,
    bass = { 33, 33, 0, 33, 31, 31, 0, 31, 29, 29, 0, 29, 28, 28, 0, 28 },
    lead = { 69, 0, 72, 0, 68, 0, 71, 0, 67, 0, 70, 0, 64, 0, 67, 0 },
    hat  = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
}

-- pick the bed a heist opens with
function Sfx.bed(name)
    return Sfx[name] or Sfx.PROWL
end

-- ---- one-shots ---------------------------------------------------------

function Sfx.pad()               -- a paw down on cobble
    Snd.play("noise", 240, 0.03, 0.06)
end

function Sfx.grab()              -- loot lifted
    Snd.play("tri", 988, 0.07, 0.26)
    Util.after(0.07, function() Snd.play("tri", 1319, 0.13, 0.24) end)
end

function Sfx.douse()             -- a wick pinched out
    Snd.play("noise", 520, 0.09, 0.22)
    Util.after(0.08, function() Snd.play("noise", 180, 0.16, 0.16) end)
end

function Sfx.pebble()            -- a stone skitters away
    Snd.play("square", 660, 0.03, 0.14)
    Util.after(0.09, function() Snd.play("square", 440, 0.03, 0.11) end)
    Util.after(0.17, function() Snd.play("square", 330, 0.04, 0.09) end)
end

function Sfx.spot()              -- "oi!" -- a guard has eyes on you
    Snd.play("square", 392, 0.09, 0.24)
    Util.after(0.1, function() Snd.play("square", 494, 0.12, 0.22) end)
end

function Sfx.bark()
    for i = 0, 1 do
        Util.after(i * 0.11, function()
            Snd.play("saw", 180 - i * 30, 0.09, 0.26)
        end)
    end
end

function Sfx.caught()            -- collared
    for i = 0, 3 do
        Util.after(i * 0.1, function()
            Snd.play("saw", 220 - i * 42, 0.16, 0.24)
        end)
    end
end

function Sfx.clear()             -- up the drainpipe, clean away
    local n = { 69, 72, 76, 81 }
    for i = 1, #n do
        Util.after((i - 1) * 0.09, function()
            Snd.play("tri", Music.midihz(n[i]), 0.14, 0.22)
        end)
    end
end

function Sfx.alarm()             -- the house wakes
    for i = 0, 5 do
        Util.after(i * 0.14, function()
            Snd.play("square", (i % 2 == 0) and 740 or 560, 0.11, 0.22)
        end)
    end
end
