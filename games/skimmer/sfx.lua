-- Skimmer: synth-only sound, plus the airborne loop -- a pastoral
-- 104 bpm C-major step pattern that keeps playing in flight (no
-- engine noise up here): triangle roots, a lilting square answer,
-- brushed offbeat hats.

Sfx = {}

Sfx.LOOP = {
    bpm = 104,
    bass = { 48, 0, 0, 0, 43, 0, 0, 0, 45, 0, 0, 0, 43, 0, 0, 0 },
    lead = { 72, 0, 76, 79, 0, 0, 76, 0, 74, 0, 77, 0, 76, 0, 74, 0 },
    hat  = { 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0 },
}

function Sfx.catch() -- a midge cluster eaten
    Snd.play("tri", 1175, 0.06, 0.28)
    Util.after(0.06, function() Snd.play("tri", 1568, 0.1, 0.28) end)
end

function Sfx.dunk() -- clipped a reed / pancaked a lily
    Snd.play("tri", 110, 0.18, 0.3)
    Snd.boom(320, 4)
end

function Sfx.tick() -- title toggles
    Snd.play("square", 440, 0.05, 0.15)
end

function Sfx.start() -- wings up
    for i, n in ipairs({ 523, 659, 784 }) do
        Util.after((i - 1) * 0.07, function()
            Snd.play("tri", n, 0.09, 0.22)
        end)
    end
end

function Sfx.over() -- the last dunk
    for i, n in ipairs({ 392, 330, 262 }) do
        Util.after(0.3 + (i - 1) * 0.14, function()
            Snd.play("tri", n, 0.18, 0.2)
        end)
    end
end
