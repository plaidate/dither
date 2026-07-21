-- Prowl: the screenplay. Seven scenes -- an opening, four interludes
-- that turn the job over, a gate scene before the manor, and an ending
-- with the tally. Each is a plain function full of blocking calls
-- (core/dstory.lua turns it into a coroutine), and each latches a save
-- flag so a Continue never replays a scene you have already sat
-- through.
--
-- Cast: Whisker (you, a cat with a professional interest in windows),
-- the Magpie (a fence with a bird's opinion of ownership), and the
-- Night Watchman of Ashgrave, who is not a character so much as a
-- beam of light with a man behind it.

Tale = {}

local gfx = playdate.graphics

-- ---- 40x40 procedural portraits ---------------------------------------

local function pCat(w, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, w, h)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(20, 24, 13)             -- head
    gfx.fillTriangle(9, 16, 15, 4, 20, 16)        -- ears
    gfx.fillTriangle(31, 16, 25, 4, 20, 16)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(15, 22, 3)              -- eyes
    gfx.fillCircleAtPoint(25, 22, 3)
    gfx.fillTriangle(18, 28, 22, 28, 20, 31)      -- nose
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(14, 21, 1, 1)
    gfx.fillRect(24, 21, 1, 1)
    for i = 0, 2 do                               -- whiskers
        gfx.drawLine(6, 28 + i * 2, 15, 30)
        gfx.drawLine(34, 28 + i * 2, 25, 30)
    end
end

local function pBird(w, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, w, h)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillEllipseInRect(8, 12, 26, 24)          -- body
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(8, 18, 15, 16)          -- black wing
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(26, 11, 8)              -- head
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(24, 11, 8)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(27, 9, 2)               -- eye
    gfx.fillTriangle(32, 10, 39, 13, 32, 15)      -- beak
end

local function pWatch(w, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, w, h)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillTriangle(2, 40, 20, 8, 38, 40)        -- the beam
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(20, 14, 9)              -- the hat brim
    gfx.fillRect(6, 12, 28, 4)
    gfx.fillRect(11, 22, 18, 18)                  -- shoulders
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(16, 16, 3, 2)                    -- two cold eyes
    gfx.fillRect(22, 16, 3, 2)
    gfx.drawRect(11, 22, 18, 18)
end

Story.portraits = {
    Whisker = pCat,
    Magpie = pBird,
    Watchman = pWatch,
}

-- ---- the scenes --------------------------------------------------------

local function sceneOpen()
    fade(1, 0.01)
    tune(Sfx.PROWL)
    say("Magpie", "There you are. Four hours past moonrise and the "
        .. "whole town asleep with its windows open.")
    fade(0, 0.9)
    say("Whisker", "I was washing.")
    say("Magpie", "You were sulking. Listen: lanterns move, shadows "
        .. "do not. Stand in the dark and you are furniture.")
    say("Magpie", "Stand in the light and you are a cat with a "
        .. "criminal record. Off you go.")
    sting{ 69, 76 }
end

local function sceneLamps()
    fade(1, 0.5)
    say("Magpie", "The lamplighter has done his rounds. Four wicks "
        .. "burning down the whole row.")
    say("Whisker", "Wicks pinch out.")
    say("Magpie", "They do. And they stay out. A lamp you smother is "
        .. "one less thing in the world that can see you.")
    iris(200, 120, 0, 0.5)
    fade(0, 0.6)
end

local function sceneTurn()
    fade(1, 0.5)
    tune(Sfx.WATCH)
    say("Magpie", "Small stuff. Fish, spoons, a bell. You are worth "
        .. "more than spoons, Whisker.")
    say("Whisker", "Say it.")
    say("Magpie", "Ashgrave Manor. The Ash crown, under glass, in a "
        .. "hall with one light in it.")
    beat()
    say("Magpie", "One light. It is two hundred feet long and it "
        .. "belongs to the Night Watchman, and it never stops moving.")
    say("Whisker", "Then neither do I.")
    flash()
    sting{ 60, 67, 72 }
    fade(0, 0.7)
end

local function sceneDogs()
    fade(1, 0.5)
    tune(Sfx.GAOL)
    say("Magpie", "Word is out. They have put dogs on the yards and "
        .. "doubled the gaol watch.")
    say("Whisker", "Dogs do not care about shadows.")
    say("Magpie", "No. Dogs care about noise. So stop running "
        .. "everywhere like a kitten and creep.")
    fade(0, 0.6)
end

local function sceneGates()
    fade(1, 0.5)
    say("Magpie", "The chapel took the last of the small stuff. "
        .. "Ashgrave is over the wall.")
    say("Whisker", "The sconces?")
    say("Magpie", "Four. All of them can be pinched. Do that first "
        .. "and the hall goes as dark as the inside of a hat.")
    say("Magpie", "The Watchman's beam will still be there. Nothing "
        .. "puts that out.")
    beat()
    say("Whisker", "Then I will go where it has just been.")
    fade(0, 0.6)
end

local function sceneManor()
    fade(1, 0.5)
    tune(Sfx.MANOR)
    say("Watchman", "Forty years on this floor. Nothing has ever "
        .. "crossed it that I did not see.")
    beat()
    say("Whisker", "Nothing you did not see.")
    iris(200, 130, 0, 0.7)
    sting{ 45, 52, 57 }
    fade(0, 0.8)
end

local function sceneEnd()
    fade(1, 0.7)
    tune(Sfx.TITLE)
    say("Magpie", "Well?")
    say("Whisker", "It is heavier than it looks.")
    say("Magpie", "They all are. Put it down, then -- there, on the "
        .. "ridge tiles, where the whole town can see it catch the "
        .. "moon.")
    say("Whisker", "The Watchman will see it too.")
    say("Magpie", "Good. Let him have something to look at. He has "
        .. "earned one thing worth sweeping a beam across.")
    flash()
    sting{ 69, 72, 76, 81 }
    fade(0, 1.0)
end

-- stage number -> the scene that plays BEFORE it
local BEFORE = {
    [1] = sceneOpen,
    [3] = sceneLamps,
    [5] = sceneTurn,
    [7] = sceneDogs,
    [9] = sceneGates,
    [10] = sceneManor,
}

-- Play the interlude due before heist n, if any, and hand the room
-- back to the game when it finishes. Returns true if a scene started
-- (the caller must not also start the room).
function Tale.before(n)
    local fn = BEFORE[n]
    if not fn then return false end
    if Save.flag("sc" .. n) then return false end
    Save.flag("sc" .. n, true)
    return Story.play(fn, { onDone = function() Game.startRoom(n) end })
end

function Tale.ending()
    Story.play(sceneEnd, { onDone = function() Game.markDone() end })
end

-- how many interludes exist, for the credits card
Tale.count = 7
