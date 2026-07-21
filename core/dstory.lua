-- Dither core: cutscenes as coroutine screenplays. A scene is a plain
-- function full of blocking calls; Story runs it one frame at a time.
--
--   Story.play(function()
--       fade(1, 0.4)                       -- veil to black
--       say("Keeper", "The lamp is out.")  -- dialogue box, waits
--       act(function(dt) return Game.walk(dt) end)  -- until true
--       fade(0, 0.6)
--   end)
--
-- The game calls Story.update(dt) BEFORE its own update (and skips
-- that update while Story.active), then Story.draw() last, after the
-- Light pass — the veil, letterbox and text box are screen furniture.
--
-- Primitives are installed as globals while a scene runs, so scripts
-- read like screenplays: say, wait, beat, act, fade, iris, flash,
-- tune, sting. They are also Story.say etc. if a game prefers those.
-- Every scene counts one "cutscenes" harness tick and every line one
-- "saidLines" — both are proof the story actually played.

local gfx = playdate.graphics

Story = {}

local W <const>, H <const> = 400, 240
local BOX_H <const> = 58      -- minimum; the box grows to fit its text
local MAXROWS <const> = 4     -- wrapped rows a single say() may show
local BAR_H <const> = 22      -- letterbox bars
local CPS <const> = 42        -- typewriter characters per second

Story.active = false
Story.veil = 0                -- 0..1 dissolve level (Fade.dissolve)
Story.bars = 0                -- 0..1 letterbox extension
Story.irisT = nil             -- {x, y, t} or nil
Story.portraits = nil         -- { ["Name"] = fn(w, h) }
Story.skippable = true
Story.line, Story.who = nil, nil

local co, waiter
local shown = 0               -- characters revealed
local full = nil              -- the full line being typed
local flashT = 0
local wrapCache = {}
local advance = false         -- edge flag: the player pressed A
local doneFn = nil

-- ---- word wrap -------------------------------------------------------
-- Cached per string — scenes reuse their lines, so this runs once per
-- distinct line and never inside the typewriter loop.
local function wrap(text, maxw)
    local c = wrapCache[text]
    if c then return c end
    local out, cur = {}, nil
    for word in text:gmatch("%S+") do
        local try = cur and (cur .. " " .. word) or word
        if cur and gfx.getTextSize(try) > maxw then
            out[#out + 1] = cur
            cur = word
        else
            cur = try
        end
    end
    if cur then out[#out + 1] = cur end
    wrapCache[text] = out
    return out
end

-- ---- the primitives --------------------------------------------------
-- Each yields a function(dt) -> true when the beat is finished.

local function block(fn)
    coroutine.yield(fn)
end

-- a line of dialogue: types out, then waits for A (or 1.6s of quiet
-- in smoke builds, so unattended runs still finish)
function Story.say(who, text)
    Story.who, full, shown = who, text, 0
    Story.line = text
    Harness.count("saidLines")
    local hold = 0
    block(function(dt)
        if shown < #full then
            shown = math.min(#full, shown + CPS * dt)
            if advance then shown = #full end
            return false
        end
        hold = hold + dt
        if advance or (Harness.enabled and hold > 1.6) then
            Story.line, Story.who, full = nil, nil, nil
            return true
        end
        return false
    end)
end

-- pause for t seconds
function Story.wait(t)
    local left = t
    block(function(dt)
        left = left - dt
        return left <= 0
    end)
end

-- one held beat (0.35s) — the comic timing unit
function Story.beat()
    Story.wait(0.35)
end

-- run fn(dt) every frame until it returns true (walk an actor into
-- place, pan a camera, wait for a door)
function Story.act(fn)
    block(fn)
end

-- animate the veil to `to` (0 clear .. 1 black) over t seconds
function Story.fade(to, t)
    local from, el = Story.veil, 0
    block(function(dt)
        el = el + dt
        local u = t > 0 and math.min(1, el / t) or 1
        Story.veil = from + (to - from) * u
        return u >= 1
    end)
end

-- animate an iris on (x, y): to 0 open .. 1 closed
function Story.iris(x, y, to, t)
    local from = Story.irisT and Story.irisT.t or 0
    Story.irisT = Story.irisT or { x = x, y = y, t = from }
    Story.irisT.x, Story.irisT.y = x, y
    local el = 0
    block(function(dt)
        el = el + dt
        local u = t > 0 and math.min(1, el / t) or 1
        Story.irisT.t = from + (to - from) * u
        if u >= 1 and to <= 0 then Story.irisT = nil end
        return u >= 1
    end)
end

-- one-frame white flash (thunder, a lamp catching)
function Story.flash()
    flashT = 0.12
end

-- swap the music bed / fire a stinger from inside a scene
function Story.tune(song)
    Music.set(song)
end

function Story.sting(notes)
    Music.sting(notes)
end

-- ---- driving ---------------------------------------------------------

local G_NAMES <const> = {
    "say", "wait", "beat", "act", "fade", "iris", "flash", "tune", "sting",
}
local saved = {}

local function installGlobals(on)
    for _, n in ipairs(G_NAMES) do
        if on then
            saved[n] = _G[n]
            _G[n] = Story[n]
        else
            _G[n] = saved[n]
        end
    end
end

-- start a scene. opts.onDone runs when it finishes (or is skipped).
function Story.play(fn, opts)
    if Story.active then return false end
    co = coroutine.create(fn)
    waiter, shown, full = nil, 0, nil
    Story.active = true
    Story.line, Story.who = nil, nil
    doneFn = opts and opts.onDone
    if opts and opts.skippable ~= nil then
        Story.skippable = opts.skippable
    else
        Story.skippable = true
    end
    Harness.count("cutscenes")
    installGlobals(true)
    return true
end

local function finish()
    installGlobals(false)
    co, waiter, full = nil, nil, nil
    Story.active = false
    Story.line, Story.who = nil, nil
    if doneFn then
        local f = doneFn
        doneFn = nil
        f()
    end
end

-- stop immediately (B on a skippable scene). The veil and iris are
-- cleared so a half-faded skip can never strand the game behind black.
function Story.stop()
    if not Story.active then return end
    Story.veil, Story.irisT = 0, nil
    Harness.count("cutsceneSkips")
    finish()
end

-- feed the scene one frame. `press` is the A edge, `skip` the B edge
-- (both optional — pass Input's edge flags).
function Story.update(dt, press, skip)
    flashT = math.max(0, flashT - dt)
    if not Story.active then return end
    advance = press or false
    if skip and Story.skippable then
        Story.stop()
        return
    end
    -- run the current blocking beat; when it clears, resume the scene
    if waiter and not waiter(dt) then return end
    waiter = nil
    local ok, res = coroutine.resume(co)
    if not ok then
        -- a broken scene must not wedge the game: report and bail out
        Harness.set("storyErr", tostring(res))
        Story.veil, Story.irisT = 0, nil
        finish()
        return
    end
    if coroutine.status(co) == "dead" then
        finish()
    else
        waiter = res
    end
end

-- ---- drawing ---------------------------------------------------------

local function drawBox()
    local text = full
    if not text then return end
    local n = math.floor(shown)
    local pw = (Story.portraits and Story.portraits[Story.who]) and 46 or 0
    -- The box GROWS to fit its wrapped text (up to MAXROWS) instead of
    -- silently spilling past the panel: a two-line speech looks exactly
    -- as before, a three-line one gets a taller box. Authors should not
    -- have to count characters to stay inside the furniture.
    local out = wrap(text, W - 24 - 16 - pw)
    local rows = math.min(#out, MAXROWS)
    local h = math.max(BOX_H, 26 + rows * 15)
    local x, y = 12, H - h - 8
    Kit.panel(x, y, W - 24, h)
    if pw > 0 then
        -- portrait fn gets (w, h, ox, oy): the SIZE of the frame and
        -- its absolute origin. Drawing is clipped to the frame but not
        -- translated, so a portrait must draw at ox/oy — the origin
        -- args exist because working it out from the box layout is a
        -- trap (it is 16, 178 for the stock box).
        gfx.pushContext()
        gfx.setClipRect(x + 4, y + 4, 40, 40)
        Story.portraits[Story.who](40, 40, x + 4, y + 4)
        gfx.popContext()
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x + 4, y + 4, 40, 40)
    end
    local tx = x + 8 + pw
    if Story.who then
        Kit.text(Story.who .. ":", tx, y + 5)
    end
    local left = n
    for i = 1, rows do
        local l = out[i]
        if left <= 0 then break end
        Kit.text(#l <= left and l or l:sub(1, left), tx, y + 21 + (i - 1) * 15)
        left = left - #l - 1
    end
    if n >= #text then
        Kit.text(">", W - 30, y + h - 18)
    end
end

-- draw AFTER the scene and the Light pass: letterbox, box, veil, iris,
-- flash. Safe to call every frame; it no-ops when nothing is running.
function Story.draw()
    if Story.irisT then
        Fade.iris(Story.irisT.x, Story.irisT.y, Story.irisT.t)
    end
    if Story.veil > 0 then Fade.dissolve(Story.veil) end
    if Story.active then
        if Story.bars > 0 then
            gfx.setColor(gfx.kColorBlack)
            local h = math.floor(BAR_H * Story.bars)
            gfx.fillRect(0, 0, W, h)
            gfx.fillRect(0, H - h, W, h)
        end
        drawBox()
    end
    if flashT > 0 then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, W, H)
    end
end
