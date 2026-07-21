-- Dither core: step-sequencer music. The short form is one looping
-- 16-step pattern:
--
--   { bpm = 104,
--     bass = { 48, 0, 43, 0, ... },  -- 16 steps, midi notes, 0 = rest
--     lead = { 72, 0, 76, 0, ... },  -- 16 steps, midi notes, 0 = rest
--     hat  = { 1, 0, 0, 0, ... } }   -- 16 steps, nonzero = noise tick
--
-- The long form is a SONG: named patterns played in an order, so a
-- stage can have a verse, a chorus and a bridge without three copies
-- of the bass line:
--
--   { bpm = 96, len = 32,            -- len 16 (default) or 32
--     patterns = {
--       A = { bass = {...}, lead = {...}, hat = {...} },
--       B = { bass = {...}, lead = {...} },
--     },
--     order = { "A", "A", "B", "A" } }
--
-- Clock-driven: accumulate dt and fire steps on beat boundaries — zero
-- drift. All synth, mixed quiet under the sfx. Counters: musicBars on
-- every pattern wrap, stingers on every Music.sting.
--
-- Music.sting{ 72, 76, 79 } fires a short arpeggio on its own voice
-- OVER the bed (fanfares, discoveries, deaths) — it never disturbs the
-- sequencer clock. It rides Util.after, so the game must be ticking
-- Util.runPending (Kit.run does).

Music = {}

local snd = playdate.sound
local bass = snd.synth.new(snd.kWaveTriangle)
local lead = snd.synth.new(snd.kWaveSquare)
local hat = snd.synth.new(snd.kWaveNoise)
local stinger = snd.synth.new(snd.kWaveSquare)

-- midi note -> Hz
function Music.midihz(n)
    return 440 * 2 ^ ((n - 69) / 12)
end

local src                 -- the table the game handed us (identity)
local song                -- normalized { bpm, len, seq = {pattern...} }
local clock, stepI, orderI = 0, 0, 1
local norm = {}           -- cache: source table -> normalized song

-- Both forms collapse to a list of patterns played in sequence.
local function normalize(t)
    local cached = norm[t]
    if cached then return cached end
    local len = t.len or 16
    local seq = {}
    if t.patterns then
        local order = t.order
        if not order then
            order = {}
            for k in pairs(t.patterns) do order[#order + 1] = k end
            table.sort(order)
        end
        for i = 1, #order do
            seq[i] = t.patterns[order[i]] or {}
        end
    else
        seq[1] = t
    end
    if #seq == 0 then seq[1] = {} end
    local out = { bpm = t.bpm or 100, len = len, seq = seq }
    norm[t] = out
    return out
end

function Music.set(track)
    if track == src then return end
    src = track
    song = track and normalize(track) or nil
    -- park one step past the end so the very first update wraps into
    -- pattern 1 step 1 and counts that bar, like the old sequencer did
    clock = 0
    stepI = song and song.len or 16
    orderI = song and #song.seq or 1
end

function Music.stop()
    src, song = nil, nil
end

-- true while a bed is playing (games gate their "silence" beats on it)
function Music.playing()
    return song ~= nil
end

-- a short arpeggio over the bed: notes are midi, spaced `gap` seconds
-- (default 0.07). Counts one "stingers" tick per call.
function Music.sting(notes, gap, vol)
    if not notes then return end
    gap = gap or 0.07
    for i = 1, #notes do
        local n = notes[i]
        Util.after((i - 1) * gap, function()
            stinger:playNote(Music.midihz(n), vol or 0.16, gap * 1.6)
        end)
    end
    Harness.count("stingers")
end

function Music.update(dt)
    if not song then return end
    local stepDur = 60 / song.bpm / 4 -- sixteenth notes
    clock = clock + dt
    while clock >= stepDur do
        clock = clock - stepDur
        stepI = stepI + 1
        if stepI > song.len then
            stepI = 1
            orderI = orderI % #song.seq + 1
            Harness.count("musicBars")
        end
        local pat = song.seq[orderI] or song.seq[1]
        local b = pat.bass and pat.bass[stepI]
        if b and b ~= 0 then
            bass:playNote(Music.midihz(b), 0.12, stepDur * 1.8)
        end
        local l = pat.lead and pat.lead[stepI]
        if l and l ~= 0 then
            lead:playNote(Music.midihz(l), 0.07, stepDur * 0.9)
        end
        local h = pat.hat and pat.hat[stepI]
        if h and h ~= 0 then
            hat:playNote(4000, 0.04, stepDur * 0.3)
        end
    end
end
