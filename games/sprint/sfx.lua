-- Synth-only sound, played through the core's Snd pools. The PySprint
-- audio is a separate matter from its 1-bit graphics, so the effects
-- here are generated, not converted: countdown beeps, a wall-scrape
-- thud, a lap chime, and short win/lose stings. Sfx.TITLE is the
-- starting-grid loop the title screen hands to Music.set.

Sfx = {}

function Sfx.go()
    Snd.play("square", 880, 0.18, 0.4)
end

function Sfx.bump()
    Snd.play("noise", 220, 0.10, 0.35)
end

function Sfx.lap()
    Snd.play("tri", 988, 0.12, 0.3)
end

function Sfx.win()
    local notes = { 523, 659, 784, 1047 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * 0.12, function()
            Snd.play("tri", n, 0.11, 0.3)
        end)
    end
end

function Sfx.lose()
    local notes = { 392, 330, 262 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * 0.16, function()
            Snd.play("square", n, 0.14, 0.25)
        end)
    end
end

-- moody starting-grid loop, ~100 bpm in A minor: a low idling bass,
-- sparse high answers, brushed off-beat hats. Music.stop() the moment
-- the race starts — from GO the engines are the soundtrack.
Sfx.TITLE = {
    bpm = 100,
    bass = {
        33, 0, 0, 33, 0, 0, 31, 0,
        28, 0, 0, 28, 0, 0, 31, 0,
    },
    lead = {
        0, 0, 69, 0, 0, 72, 0, 0,
        0, 76, 0, 0, 71, 0, 0, 0,
    },
    hat = {
        0, 0, 1, 0, 0, 0, 1, 0,
        0, 0, 1, 0, 1, 0, 1, 0,
    },
}
