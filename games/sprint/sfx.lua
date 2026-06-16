-- Synth-only sound. The PySprint audio is a separate matter from its 1-bit
-- graphics, so the effects here are generated, not converted: countdown beeps,
-- a wall-scrape thud, a lap chime, and short win/lose stings.

local snd <const> = playdate.sound

Sfx = {}

local square = snd.synth.new(snd.kWaveSquare)
local tri = snd.synth.new(snd.kWaveTriangle)
local noise = snd.synth.new(snd.kWaveNoise)

function Sfx.go()
    square:playNote(880, 0.4, 0.18)
end

function Sfx.bump()
    noise:playNote(220, 0.35, 0.10)
end

function Sfx.lap()
    tri:playNote(988, 0.3, 0.12)
end

function Sfx.win()
    local notes = { 523, 659, 784, 1047 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * 0.12, function() tri:playNote(n, 0.3, 0.11) end)
    end
end

function Sfx.lose()
    local notes = { 392, 330, 262 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * 0.16, function() square:playNote(n, 0.25, 0.14) end)
    end
end
