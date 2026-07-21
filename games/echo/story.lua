-- Echo: the screenplays. Seven scenes -- an opening, five turns and an
-- ending with the run's numbers -- written as core/dstory.lua
-- coroutines, so they read top to bottom and block on their own.
--
-- Each is latched by a Save.flag, so a scene plays once per save file
-- and a replayed cavern goes straight back to the map. The ending is
-- the one that matters: Game.advance behind it is what sets `done`.
--
-- Portraits are 40x40 procedural faces (no image files anywhere in
-- this game). Pip is you; Thrum is the old bat who taught the roost to
-- listen; Vesper is the voice in The Answer.

Tale = {}

local gfx = playdate.graphics

-- ---- portraits -----------------------------------------------------------

-- a bat face: white on black, ears and a leaf nose. `wide` gives the
-- old one his heavy brow, `thin` gives Vesper her narrow one.
local function face(w, h, ear, brow)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, w, h)
    gfx.setColor(gfx.kColorWhite)
    -- ears
    gfx.fillTriangle(9, 15, 13, ear, 18, 16)
    gfx.fillTriangle(31, 15, 27, ear, 22, 16)
    -- skull
    gfx.fillEllipseInRect(8, 12, 24, 22)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(16, 22, 2) -- eyes
    gfx.fillCircleAtPoint(24, 22, 2)
    gfx.fillRect(19, 25, 2, 4)       -- nose leaf
    gfx.fillRect(16, 28, 8, 1)       -- mouth
    if brow > 0 then
        gfx.fillRect(12, 18 - brow, 7, 2)
        gfx.fillRect(21, 18 - brow, 7, 2)
    end
end

Story.portraits = {
    Pip = function(w, h) face(w, h, 4, 0) end,
    Thrum = function(w, h) face(w, h, 7, 2) end,
    Vesper = function(w, h) face(w, h, 2, 1) end,
}

-- ---- the scenes -------------------------------------------------------------

local SCENE = {}

SCENE.intro = function()
    fade(1, 0.01)
    tune(Sfx.DRIP)
    beat()
    say("Thrum", "Open your eyes, Pip. Good. Now notice that it made no difference.")
    fade(0, 1.2)
    say("Thrum", "There is no light under the hill. There never was. We are not owed any.")
    say("Pip", "Then how do you fly?")
    say("Thrum", "I shout, and the hill shouts back. What comes back is the map.")
    sting{ 72, 79, 84 }
    say("Thrum", "It fades. That is the whole art -- you fly on a map that is going out.")
    say("Thrum", "Press A to call. Then commit. Then call again, if you have the breath.")
    beat()
end

SCENE.moths = function()
    fade(1, 0.5)
    say("Thrum", "You are calling every second breath. You will be hollow by the deep galleries.")
    say("Pip", "I cannot fly what I cannot hear.")
    say("Thrum", "Then eat. Every moth is another call, and the garden is full of them.")
    say("Thrum", "Learn the greedy line: food sits where the way is open. It always has.")
    fade(0, 0.6)
end

SCENE.shadow = function()
    fade(1, 0.6)
    tune(Sfx.DEEP)
    say("Pip", "Thrum. The roost is quiet.")
    say("Thrum", "I know.")
    say("Pip", "Half the roost is quiet.")
    say("Thrum", "There is an owl on the hill. It has learned where we sleep, and it hunts by our voices.")
    sting{ 55, 51, 46 }
    say("Thrum", "Fly deep, Pip. Find the old roost past the water. Take the young ones there.")
    fade(0, 0.8)
end

SCENE.water = function()
    fade(1, 0.5)
    say("Pip", "The pool gave me back my own call. Twice over, and softer.")
    say("Thrum", "The still water is a second mouth. Let it speak -- it maps what your breath could not.")
    say("Thrum", "A cheap glimpse is still a glimpse. Take every one the hill offers you.")
    fade(0, 0.6)
end

SCENE.vesper = function()
    fade(1, 0.5)
    say("Vesper", "You answered. Nobody answers down here any more.")
    say("Pip", "You were calling into an empty gallery.")
    say("Vesper", "I have been calling for nine nights. I am the last of the west roost.")
    sting{ 67, 71, 76, 79 }
    say("Vesper", "Call when I call and my map is your map. It is thin, but it is two of us now.")
    say("Pip", "Then fly ahead of me. I will keep answering.")
    fade(0, 0.7)
end

SCENE.gather = function()
    fade(1, 0.6)
    tune(Sfx.HUNT)
    say("Vesper", "The young ones are at the throat of the last gallery. So is the owl.")
    say("Pip", "It hunts the voices. If I call, it finds me.")
    say("Vesper", "Yes. And if you do not call, the rock finds you.")
    say("Thrum", "That is the whole of it, Pip. Every glimpse you buy, you pay for twice.")
    sting{ 40, 47, 52 }
    say("Vesper", "Fly. I will call from the far side and give it two of us to choose from.")
    fade(0, 0.8)
end

SCENE.ending = function()
    fade(1, 0.8)
    tune(Sfx.DRIP)
    beat()
    say("Vesper", "It broke off at the throat. Owls will not follow into a gallery they cannot turn in.")
    say("Pip", "The young ones?")
    say("Vesper", "All of them. Loud, and complaining, and alive.")
    flash()
    sting{ 72, 76, 79, 84, 88 }
    say("Thrum", "You flew nine caverns on a map that was always going out, and you brought the roost with you.")
    say("Thrum", "Sleep, Pip. The hill will still be dark tomorrow.")
    beat()
    fade(0, 1.0)
end

-- cavern index -> the scene that plays after clearing it
local AFTER = {
    [3] = "moths",
    [5] = "shadow",
    [6] = "water",
    [7] = "vesper",
    [9] = "gather",
    [10] = "ending",
}

-- ---- driving ------------------------------------------------------------------

-- play a scene by key; onDone runs after the last beat (or a skip)
function Tale.play(key, onDone)
    local fn = SCENE[key]
    if not fn then
        if onDone then onDone() end
        return false
    end
    Harness.count("scene_" .. key)
    return Story.play(fn, { onDone = onDone })
end

-- the scene owed after clearing cavern i, once per save file
function Tale.after(i, onDone)
    local key = AFTER[i]
    if not key then return false end
    local flag = "t_" .. key
    if Save.flag(flag) then return false end
    Save.flag(flag, true)
    Save.commit()
    return Tale.play(key, onDone)
end
