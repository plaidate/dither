-- Delve: the screenplays. Seven scenes, written as blocking coroutine
-- scripts for core/dstory.lua -- an opening at the mine mouth, four
-- turns on the way down, the collapse that takes the lamp, and an
-- ending with the run's numbers. Story primitives (say/fade/act/beat/
-- iris/flash/tune/sting) are installed as globals only while a scene
-- runs, so these bodies read like a script and not like an API.
--
-- Each scene is latched by a Save.flag in Game.enterDepth, so a
-- continued campaign never replays what it has already seen.
--
-- Keep every line under about 70 characters. dstory's box wraps at
-- 314px and its third line starts at y=225, which already runs past
-- the box; two wrapped lines is the real budget, and splitting a long
-- speech into two `say` calls reads better than crowding one anyway.

Tale = {}

local gfx = playdate.graphics

-- ---- portraits ---------------------------------------------------------
-- 40x40, drawn procedurally into the dialogue box's frame. Palette rule
-- as everywhere else: white fills, black outlines, no dither soup.

local function head(w, h, cx, cy, r)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, w, h)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(cx, cy, r)
    gfx.setColor(gfx.kColorBlack)
end

Story.portraits = {
    -- the delver: helmet, lamp bracket, one hard eye
    VESPER = function(w, h)
        head(w, h, 20, 24, 11)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(9, 12, 22, 7)          -- helmet brim
        gfx.fillCircleAtPoint(20, 13, 10)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(18, 6, 6, 6)           -- the lamp itself
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(18, 6, 6, 6)
        gfx.fillRect(16, 24, 3, 3)          -- eyes
        gfx.fillRect(23, 24, 3, 3)
        gfx.fillRect(16, 31, 9, 2)          -- set mouth
    end,
    -- the pit boss, heard down a speaking tube: beard, ear trumpet
    KELL = function(w, h)
        head(w, h, 20, 21, 11)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(11, 24, 18, 12)        -- beard
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(11, 24, 18, 1)
        for x = 12, 28, 3 do
            gfx.fillRect(x, 28, 1, 8)
        end
        gfx.fillRect(15, 17, 3, 3)
        gfx.fillRect(22, 17, 3, 3)
        gfx.fillRect(8, 10, 24, 3)          -- cap
        gfx.fillRect(30, 18, 8, 4)          -- the tube
    end,
    -- the thing at the bottom: nothing but eyes and a suggestion
    WARDEN = function(w, h)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, w, h)
        Shade.over(6)
        gfx.fillCircleAtPoint(20, 26, 17)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(11, 18, 5, 3)
        gfx.fillRect(24, 18, 5, 3)
        gfx.fillRect(14, 30, 2, 2)
        gfx.fillRect(19, 32, 2, 2)
        gfx.fillRect(24, 30, 2, 2)
        gfx.setColor(gfx.kColorBlack)
    end,
}

-- ---- scenes ---------------------------------------------------------------

Tale.scenes = {}

Tale.scenes.open = function()
    fade(1, 0.01)
    tune(Sfx.WINDLASS)
    say("KELL", "Cage only goes to the adit. Below that it is your legs.")
    fade(0, 0.9)
    say("KELL", "Lamp is full. Three flares on your belt. That is the lot.")
    say("VESPER", "The other three crews went down with the same.")
    say("KELL", "They did.")
    beat()
    say("KELL", "Light a lantern where you find one. It fills the lamp.")
    say("KELL", "It is also where you wake up, if the dark has you.")
    say("VESPER", "And if I run out of flare?")
    say("KELL", "Then you stand very still, girl.")
    say("KELL", "And you think hard about the shape of the roof.")
    sting{ 55, 60, 62 }
    tune(Sfx.SHAFT)
    beat()
end

Tale.scenes.seen = function()
    fade(1, 0.5)
    say("VESPER", "Kell. Something came to the edge of the beam and stopped.")
    fade(0, 0.7)
    say("KELL", "Stopped where?")
    say("VESPER", "Exactly where the light stopped. Not a step further in.")
    beat()
    say("KELL", "Then that is what they are.")
    say("KELL", "They live in the part you are not looking at.")
    say("KELL", "Throw ahead of yourself. Do not walk into a hole you have not lit.")
    sting{ 50, 53, 57 }
end

Tale.scenes.follow = function()
    fade(1, 0.5)
    tune(Sfx.WATER)
    say("VESPER", "Water to the knee down here.")
    say("VESPER", "My flare went out before it stopped falling.")
    fade(0, 0.8)
    say("KELL", "Then do not spend one over water. Simple as that.")
    say("VESPER", "Kell. There is a track behind me in the silt.")
    say("VESPER", "It is mine, going down.")
    beat()
    say("VESPER", "And there is a second one on top of it.")
    say("KELL", "...")
    say("KELL", "Keep going down. It has had four crews already.")
    say("KELL", "It is still hungry, so it is not ahead of you.")
    flash()
    sting{ 45, 48, 51 }
end

Tale.scenes.ration = function()
    fade(1, 0.5)
    tune(Sfx.DEEP)
    say("KELL", "How many flares.")
    fade(0, 0.8)
    say("VESPER", "Two. There is a crate every gallery if I can reach it.")
    say("KELL", "Then reach it. And Vesper -- burn one to move, never to look.")
    beat()
    say("VESPER", "I found the third crew. Their lamps are all still on the hooks.")
    say("VESPER", "All of them full.")
    say("KELL", "They put them down.")
    say("KELL", "Do not put yours down.")
    sting{ 41, 44, 48 }
end

Tale.scenes.collapse = function()
    fade(1, 0.4)
    say("KELL", "Vesper? The gauge says the whole west side just--")
    local t = 0
    act(function(dt)
        t = t + dt
        Kit.shake(0.5)
        return t > 1.1
    end)
    flash()
    fade(0, 0.9)
    say("VESPER", "Lamp's gone. The bracket sheared clean off.")
    say("VESPER", "It went into the sump with half the roof.")
    say("KELL", "Come back up.")
    beat()
    say("VESPER", "I have two flares and I can hear the bottom, Kell. It is close.")
    say("KELL", "Two flares is nine seconds of seeing anything at all.")
    say("VESPER", "Then I had better be quick about where I look.")
    sting{ 38, 41, 45 }
end

Tale.scenes.deep = function()
    fade(1, 0.6)
    tune(Sfx.WARDEN)
    say("VESPER", "Kell. There is a gallery down here the maps do not have.")
    fade(0, 1.0)
    say("VESPER", "The walls are worked. Somebody cut this.")
    beat()
    say("WARDEN", "...")
    say("VESPER", "It will not come into the light.")
    say("VESPER", "It waits at the edge for the light to run out.")
    say("KELL", "Then do not let it.")
    say("VESPER", "That is the trouble with light, Kell.")
    say("VESPER", "There is only ever so much of it.")
    flash()
    sting{ 33, 36, 40, 45 }
end

Tale.scenes["end"] = function()
    fade(1, 0.7)
    tune(Sfx.WINDLASS)
    say("VESPER", "It went down into its own sump.")
    say("VESPER", "I lit the last flare and I did not look away.")
    fade(0, 1.0)
    say("KELL", "Is it dead?")
    say("VESPER", "It is under a great deal of light.")
    beat()
    say("KELL", "Come up. The cage is waiting and I have the lamp oil out.")
    say("VESPER", string.format(
        "Ten depths. %d lanterns lit, %d flares spent.",
        G.lanternsLit, G.flaresSpent))
    say("VESPER", string.format("%d times the dark had me.", G.deaths))
    say("KELL", string.format(
        "Thirty-eight minutes by my clock. You did it in %d.",
        math.max(1, math.floor(G.runT / 60))))
    beat()
    say("VESPER", "Keep the lantern on the adit burning, Kell.")
    say("VESPER", "There is more down there than one of us can light.")
    sting{ 60, 64, 67, 72, 76 }
    say("KELL", "DELVE -- a Dither game.")
    say("KELL", "Shade, light and shadow by the core. Every pixel procedural.")
    fade(1, 1.2)
    fade(0, 0.8)
end

-- which scene fires on the way into which depth
Tale.before = {
    [1] = "open",
    [3] = "seen",
    [5] = "follow",
    [7] = "ration",
    [8] = "collapse",
    [10] = "deep",
}

function Tale.play(name, onDone)
    local fn = Tale.scenes[name]
    if not fn then
        if onDone then onDone() end
        return false
    end
    return Story.play(fn, { onDone = onDone, skippable = false })
end
