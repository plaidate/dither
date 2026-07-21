-- Beacon: synth-only sound and the four beds. The songs are the long
-- Music form (named patterns played in an order) so a night can have a
-- verse and a swell without three copies of the bass line. Everything
-- sits in D minor so a stinger can be fired over any of them.
--
--   CALM   the first watches: a slack tide, mostly rests
--   SWELL  traffic and weather building
--   GALE   wreckers, squall, the long night
--   HYMN   the morning after — the ending and the credits

Sfx = {}

Sfx.CALM = {
    bpm = 66, len = 16,
    patterns = {
        A = {
            bass = { 38, 0, 0, 0, 0, 0, 0, 0, 45, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 0, 74, 0, 0, 0, 0, 0, 69, 0, 0, 0, 0, 72, 0 },
            hat  = { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 },
        },
        B = {
            bass = { 41, 0, 0, 0, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 0, 0, 77, 0, 0, 0, 74, 0, 0, 0, 0, 0, 72, 0, 0, 0 },
            hat  = { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 },
        },
    },
    order = { "A", "A", "B", "A" },
}

Sfx.SWELL = {
    bpm = 88, len = 16,
    patterns = {
        A = {
            bass = { 38, 0, 38, 0, 45, 0, 0, 0, 41, 0, 41, 0, 36, 0, 0, 0 },
            lead = { 0, 0, 69, 0, 0, 72, 0, 0, 0, 0, 74, 0, 0, 0, 0, 0 },
            hat  = { 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0 },
        },
        B = {
            bass = { 43, 0, 43, 0, 38, 0, 0, 0, 45, 0, 0, 0, 43, 0, 41, 0 },
            lead = { 77, 0, 0, 0, 74, 0, 0, 72, 0, 0, 70, 0, 0, 0, 69, 0 },
            hat  = { 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
        },
        C = {
            bass = { 36, 0, 0, 0, 36, 0, 0, 0, 41, 0, 0, 0, 43, 0, 0, 0 },
            lead = { 0, 0, 0, 0, 81, 0, 79, 0, 0, 0, 77, 0, 0, 0, 0, 0 },
            hat  = { 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1 },
        },
    },
    order = { "A", "A", "B", "C" },
}

Sfx.GALE = {
    bpm = 108, len = 16,
    patterns = {
        A = {
            bass = { 36, 0, 36, 36, 0, 36, 0, 41, 0, 36, 0, 36, 43, 0, 41, 0 },
            lead = { 0, 0, 72, 0, 74, 0, 0, 75, 0, 0, 74, 0, 72, 0, 0, 0 },
            hat  = { 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1 },
        },
        B = {
            bass = { 34, 0, 34, 0, 41, 0, 34, 0, 36, 0, 36, 0, 43, 0, 45, 0 },
            lead = { 79, 0, 77, 0, 0, 75, 0, 74, 0, 72, 0, 0, 70, 0, 69, 0 },
            hat  = { 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1 },
        },
        C = {
            bass = { 36, 36, 0, 0, 36, 36, 0, 0, 34, 34, 0, 0, 34, 0, 34, 0 },
            lead = { 0, 0, 84, 0, 0, 0, 82, 0, 0, 0, 81, 0, 79, 0, 77, 0 },
            hat  = { 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1 },
        },
    },
    order = { "A", "B", "A", "C" },
}

Sfx.HYMN = {
    bpm = 58, len = 16,
    patterns = {
        A = {
            bass = { 45, 0, 0, 0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 69, 0, 0, 72, 0, 0, 74, 0, 0, 77, 0, 0, 0, 74, 0, 0 },
        },
        B = {
            bass = { 43, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 0 },
            lead = { 72, 0, 0, 74, 0, 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
    order = { "A", "B" },
}

Sfx.SONGS = {
    CALM = Sfx.CALM, SWELL = Sfx.SWELL, GALE = Sfx.GALE, HYMN = Sfx.HYMN,
}

function Sfx.song(name)
    Music.set(Sfx.SONGS[name] or Sfx.CALM)
end

-- ---- effects -----------------------------------------------------------

function Sfx.turn()   -- a master sees the light and puts his helm over
    Snd.play("tri", 523, 0.07, 0.22)
    Util.after(0.07, function() Snd.play("tri", 698, 0.11, 0.2) end)
end

function Sfx.stood()  -- she is clear of the rock and standing out
    Snd.play("tri", 698, 0.08, 0.24)
    Util.after(0.09, function() Snd.play("tri", 880, 0.09, 0.22) end)
    Util.after(0.19, function() Snd.play("tri", 1047, 0.16, 0.2) end)
end

function Sfx.wreck()  -- timbers on the reef
    Snd.boom(180, 5)
    Util.after(0.1, function() Snd.play("saw", 82, 0.4, 0.22) end)
end

function Sfx.horn()   -- the fog horn: two low notes over the water
    Snd.play("saw", 98, 0.5, 0.24)
    Util.after(0.16, function() Snd.play("tri", 73, 0.6, 0.2) end)
end

function Sfx.flash()  -- the lens surge
    Snd.play("square", 880, 0.05, 0.14)
    Util.after(0.04, function() Snd.play("square", 1245, 0.07, 0.12) end)
end

function Sfx.douse()  -- a false light goes out
    for i = 0, 3 do
        Util.after(i * 0.06, function()
            Snd.play("noise", 900 - i * 190, 0.07, 0.24)
        end)
    end
end

function Sfx.spark()  -- the lamp catches again
    for i = 0, 2 do
        Util.after(i * 0.05, function()
            Snd.play("noise", 500 + i * 300, 0.05, 0.2)
        end)
    end
    Util.after(0.2, function() Snd.play("tri", 1047, 0.3, 0.24) end)
end

function Sfx.crank()  -- the priming lever biting
    Snd.play("square", 150, 0.03, 0.09)
end

function Sfx.warn()   -- the can is nearly out
    Snd.play("tri", 175, 0.22, 0.2)
end

function Sfx.click()  -- menus
    Snd.play("square", 440, 0.03, 0.12)
end

function Sfx.snuff()  -- the lamp dies, or the night is lost
    for i = 0, 3 do
        Util.after(i * 0.12, function()
            Snd.play("tri", 330 - i * 52, 0.22, 0.18)
        end)
    end
end
