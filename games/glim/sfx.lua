-- Glim: synth-only sound, plus the nocturne -- a sparse A-minor step
-- pattern at 70 bpm, mostly rests: low triangle roots on the one, a
-- high square answer drifting in late.

Sfx = {}

Sfx.NOCTURNE = {
    bpm = 70,
    bass = { 45, 0, 0, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 41, 0 },
    lead = { 0, 0, 0, 72, 0, 0, 0, 0, 0, 76, 0, 0, 69, 0, 0, 0 },
    hat  = { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 },
}

function Sfx.chime() -- a firefly jarred
    Snd.play("tri", 1319, 0.09, 0.3)
    Util.after(0.09, function() Snd.play("tri", 1760, 0.16, 0.3) end)
end

function Sfx.flutter() -- a moth got the wick
    for i = 0, 3 do
        Util.after(i * 0.04, function()
            Snd.play("noise", 700 - i * 120, 0.05, 0.25)
        end)
    end
end

function Sfx.pulse() -- the B flare
    Snd.play("square", 220, 0.06, 0.2)
    Util.after(0.05, function() Snd.play("square", 330, 0.05, 0.15) end)
end

function Sfx.warn() -- the wick is guttering
    Snd.play("tri", 196, 0.2, 0.2)
end

function Sfx.start() -- lighting the lantern
    Snd.play("tri", 440, 0.1, 0.2)
    Util.after(0.12, function() Snd.play("tri", 659, 0.15, 0.2) end)
end

function Sfx.snuff() -- the night ends
    for i = 0, 3 do
        Util.after(i * 0.12, function()
            Snd.play("tri", 392 - i * 60, 0.2, 0.18)
        end)
    end
end
