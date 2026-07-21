-- Beacon: the screenplays. Eight scenes run by core/dstory.lua --
-- an opening, five night-cards that turn the campaign, the lamp
-- failing in the middle of the last night, and an ending with the
-- log book's totals.
--
-- Scenes are plain functions full of blocking calls (say/act/fade/
-- iris/beat/tune/sting are installed as globals while one runs), so
-- they read like a script. The field does not update while a scene is
-- active -- Game.update returns early -- but the lamp keeps turning,
-- because a lighthouse does not stop for anybody's conversation.
--
-- PORTRAIT TRAP: Story.draw clips a 40x40 box and calls the portrait
-- function without moving the origin, so a portrait must draw at the
-- box's ABSOLUTE screen position. That is (16, 178) for the stock
-- 58px dialogue box; PX/PY below are it.

Tale = {}

local gfx = playdate.graphics
local PX <const>, PY <const> = 16, 178

-- ---- portraits -----------------------------------------------------------
-- Four heads, drawn from primitives at import-time cost of nothing:
-- white face, black outline, the palette rule the whole fleet uses.

local function head(brow, chin)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(PX, PY, 40, 40)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillEllipseInRect(PX + 9, PY + brow, 22, chin)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(PX + 14, PY + brow + 9, 3, 2)   -- eyes
    gfx.fillRect(PX + 23, PY + brow + 9, 3, 2)
end

Tale.portraits = {
    ["KEEPER"] = function()
        head(9, 26)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(PX + 6, PY + 6, 28, 6)       -- the cap
        gfx.fillRect(PX + 12, PY + 26, 16, 5)     -- the beard
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(PX + 13, PY + 27, 14, 3)
        gfx.setColor(gfx.kColorBlack)
    end,
    ["MAIRI"] = function()
        head(8, 25)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(PX + 7, PY + 5, 26, 8)       -- fringe
        gfx.fillRect(PX + 5, PY + 12, 5, 20)      -- the braid
        gfx.fillRect(PX + 30, PY + 12, 5, 16)
        gfx.setColor(gfx.kColorBlack)
    end,
    ["GANTON"] = function()
        head(11, 24)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(PX + 4, PY + 8, 32, 5)       -- the peaked cap
        gfx.fillRect(PX + 8, PY + 3, 24, 6)
        gfx.fillRect(PX + 11, PY + 30, 18, 6)     -- collar
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(PX + 18, PY + 31, 4, 5)
        gfx.setColor(gfx.kColorBlack)
    end,
    ["THE HEADLAND"] = function()
        -- no face: a black square with one guttering false light
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(PX, PY, 40, 40)
        Shade.fill(PX, PY + 26, 40, 14, 12, "noise")
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(PX + 20, PY + 22, 3)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(PX + 20, PY + 22, 1)
        gfx.setColor(gfx.kColorBlack)
    end,
}

-- ---- shared beats ----------------------------------------------------------

-- sweep the lamp to a bearing over `t` seconds; usable inside act()
local function sweepTo(want, t)
    local from, el = G.dir, 0
    return function(dt)
        el = el + dt
        local u = t > 0 and math.min(1, el / t) or 1
        G.dir = from + (want - from) * u
        return u >= 1
    end
end

local function open()
    Story.bars = 1
    Story.portraits = Tale.portraits
end

local function close()
    Story.bars = 0
end

-- ---- the scenes ---------------------------------------------------------------

-- 1. Vesper Rock, the first evening. The letter, the lamp, the arc.
function Tale.arrive()
    open()
    Story.veil = 1
    beat()
    say("GANTON", "Vesper Rock. Nine miles of reef and one lamp on it.")
    fade(0, 1.2)
    say("GANTON",
        "The last keeper walked into the sea. You will not do that.")
    say("KEEPER", "No, sir.")
    act(sweepTo(-2.4, 0.9))
    say("GANTON",
        "Crank turns the lens. Shutter opens her wide or draws her fine.")
    act(sweepTo(-0.8, 1.1))
    say("GANTON",
        "Wide light finds more sea. Fine light reaches further and " ..
        "drinks less oil. That is the whole trade.")
    act(sweepTo(C.DIR0, 0.8))
    say("GANTON",
        "A master steers on what he can see. So: what he can see is " ..
        "on you.")
    sting{ 60, 64, 67, 72 }
    beat()
    close()
end

-- 3. Deep hulls. The first hard lesson about the lit core.
function Tale.brigs()
    open()
    say("MAIRI", "Father. Two brigs off the Skerry, deep-laden.")
    say("KEEPER", "They'll not answer a glim.")
    say("MAIRI", "No. A brig wants the heart of the beam on her, " ..
        "not the fringe of it.")
    say("KEEPER",
        "Then draw her fine and put the hot part of the light on the hull.")
    beat()
    say("MAIRI", "And the fringe? What is the fringe for?")
    say("KEEPER", "Finding them. The core is for turning them.")
    close()
end

-- 5. The fog. The midpoint of the mechanical argument.
function Tale.fog()
    open()
    fade(0.55, 0.8)
    say("MAIRI", "It came up off the water in ten minutes flat.")
    say("KEEPER", "Fog does not dim the lamp. It shortens it.")
    say("KEEPER",
        "Every yard of it eats the far end of the beam. Wide light " ..
        "dies at arm's length tonight.")
    say("MAIRI", "Then we can't see them coming at all.")
    say("KEEPER",
        "We were never seeing them, girl. We were finding them.")
    fade(0, 0.8)
    sting{ 55, 58, 62 }
    close()
end

-- 6. The turn: somebody else is showing a light.
function Tale.wreckers()
    open()
    tune(Sfx.GALE)
    say("MAIRI", "Father, there's a fire on the north headland.")
    say("KEEPER", "There is nothing on the north headland.")
    say("THE HEADLAND", "...")
    say("MAIRI",
        "It swings. Somebody is walking a lantern to look like a beam.")
    say("KEEPER",
        "Wreckers. They want a hull on the rocks and the cargo up the " ..
        "beach by morning.")
    say("KEEPER",
        "Hold our light on the man until he cannot bear it. He will " ..
        "put his out.")
    flash()
    sting{ 48, 51, 55 }
    close()
end

-- 8. The rescue: a beam as a tow rope.
function Tale.rescue()
    open()
    say("GANTON", "Smack foundering in the bay. The boat is going out.")
    say("KEEPER", "In this? They'll not find her.")
    say("GANTON",
        "They will find her if you light them all the way. Every " ..
        "stroke, keeper. Out, alongside, and home.")
    say("MAIRI", "And the rest of the traffic?")
    say("KEEPER", "Will have to want it badly.")
    beat()
    say("GANTON", "Aye. That is the job.")
    close()
end

-- 10. The long night.
function Tale.storm()
    open()
    tune(Sfx.GALE)
    fade(0.4, 0.6)
    say("GANTON", "Everything that floats is running for shelter.")
    say("MAIRI", "Seven hulls. Two lights on the headlands. And the boat.")
    say("KEEPER", "And eighty measures of oil in the can.")
    say("GANTON", "Then do not waste any of it being wide.")
    fade(0, 0.7)
    say("KEEPER", "Get below, Mairi.")
    say("MAIRI", "No.")
    beat()
    say("KEEPER", "...good.")
    sting{ 36, 43, 48 }
    close()
end

-- mid-night-10: the lamp itself goes out and must be brought back
function Tale.lampFail()
    open()
    flash()
    say("MAIRI", "The lamp -- father, the LAMP --")
    G.lampOut = true
    G.prime = 0
    fade(0.72, 0.5)
    say("KEEPER", "Wick's drowned. Get the priming lever.")
    say("MAIRI", "There are three of them still coming in!")
    say("KEEPER",
        "Then crank. Crank until the pressure comes up and I will " ..
        "strike her.")
    fade(0, 0.6)
    close()
    Harness.count("lampFailed")
end

-- the morning after: the log book adds it up
function Tale.ending()
    open()
    fade(1, 1.0)
    tune(Sfx.HYMN)
    beat()
    fade(0, 1.6)
    say("GANTON", "Dawn. And a bay with nothing broken in it.")
    say("GANTON",
        "Ten nights. " .. G.totalSaved .. " hulls stood off, " ..
        G.totalLost .. " lost.")
    say("GANTON",
        G.totalDoused .. " false lights put out, " .. G.totalRescues ..
        " rescues brought home.")
    say("MAIRI", "Is that good?")
    say("GANTON",
        "It is a light that was where it was needed. There is no " ..
        "better word for it than that.")
    beat()
    say("KEEPER", "Trim the wick, Mairi. It gets dark again tonight.")
    sting{ 72, 76, 79, 84 }
    beat()
    close()
end

-- which scene, if any, owes the player a look before night n
local SCENES <const> = {
    [1] = Tale.arrive,
    [3] = Tale.brigs,
    [5] = Tale.fog,
    [6] = Tale.wreckers,
    [8] = Tale.rescue,
    [10] = Tale.storm,
}

function Tale.scene(n)
    return SCENES[n]
end
