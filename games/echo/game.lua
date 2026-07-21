-- Echo: the simulation. The camera streams forward down the tube; the
-- bat moves on the screen plane; obstacles collide the frame their z
-- crosses the player plane (the skimmer pattern). Everything else in
-- this file exists to serve one loop:
--
--   ping -> a reveal front races out at PING_SPD, marking obstacles
--        -> memory decays over MEM_LIFE, so the glimpse rots
--        -> you commit to a line you can no longer see
--        -> ping again, if you can afford it
--
-- Light is memory here, so "how lit is a thing" is not a lighting
-- question but a bookkeeping one: o.mem plus the FEEL floor near the
-- bat plus depth tone. Game.shadeOf is the single place those three
-- combine, and draw.lua asks it for every sprite and every ring.

Game = {}

local clamp = Util.clamp
local floor, min, max, abs = math.floor, math.min, math.max, math.abs
local sin = math.sin
local rnd = math.random

-- ---- memory ------------------------------------------------------------

-- 0..1 memory of world depth dz in front of the player plane. Anything
-- the last ping reached decays with G.memT; anything inside FEEL_Z is
-- felt through the air whatever you last heard.
function Game.memAt(wz, dz)
    local m = 0
    if wz <= G.memZ and G.memT > 0 then
        m = G.memT / C.MEM_LIFE
    end
    if dz < C.FEEL_Z then
        local f = C.FEEL * (1 - dz / C.FEEL_Z)
        if f > m then m = f end
    end
    return m
end

-- depth haze: distance read as tone, 0 near .. TONE_MAX far
function Game.tone(dz)
    if dz <= C.TONE_Z0 then return 0 end
    if dz >= C.TONE_Z1 then return C.TONE_MAX end
    return (dz - C.TONE_Z0) * C.TONE_MAX / (C.TONE_Z1 - C.TONE_Z0)
end

-- the shade level (0 crisp .. 16 invisible) an object at depth dz with
-- memory m should draw at. Both halves of the thesis in one line.
function Game.shadeOf(m, dz)
    if dz < C.FEEL_Z then
        local f = C.FEEL * (1 - dz / C.FEEL_Z)
        if f > m then m = f end
    end
    return Game.tone(dz) + (1 - m) * C.FOG
end

-- anything ever heard keeps a residual silhouette, so the cave is
-- never a black rectangle with a bat in it
function Game.memOf(o)
    local m = o.mem
    if o.seen and m < C.MEM_FLOOR then m = C.MEM_FLOOR end
    return m
end

-- ---- the ping -----------------------------------------------------------

local function playerZ()
    return Scaler.cam.z + C.PZ
end
Game.playerZ = playerZ

-- mark everything in the shell (a, b] ahead of the plane as heard
local function revealShell(a, b)
    local pz = playerZ()
    local obs = G.obs
    for i = 1, #obs do
        local o = obs[i]
        local dz = o.z - pz
        if dz > a and dz <= b then
            o.mem, o.seen = 1, true
            Harness.count("reveals")
        end
    end
end

-- an instant, whole-shell reveal (an answered call, a pool's echo)
function Game.revealTo(reach)
    revealShell(-1, reach)
    G.memZ = max(G.memZ, playerZ() + reach)
    G.memT = C.MEM_LIFE
end

-- the returning chirps: nearest three things ahead, each played back
-- after its real round trip, pitched by distance (sfx.lua)
local function scheduleEchoes(reach)
    local pz = playerZ()
    local obs = G.obs
    local n = 0
    local best = { 1e9, 1e9, 1e9 }
    for i = 1, #obs do
        local o = obs[i]
        if o.kind ~= "moth" then
            local dz = o.z - pz
            if dz > 12 and dz <= reach then
                -- insertion into a three-slot nearest list, no alloc
                if dz < best[1] then
                    best[3], best[2], best[1] = best[2], best[1], dz
                elseif dz < best[2] then
                    best[3], best[2] = best[2], dz
                elseif dz < best[3] then
                    best[3] = dz
                end
                n = min(3, n + 1)
            end
        end
    end
    for i = 1, n do
        local dz = best[i]
        Util.after(2 * dz / C.PING_SPD, function()
            Sfx.ret(dz, 0.12 - (i - 1) * 0.03)
        end)
    end
end

-- your voice shakes the cracked roof loose (Cracked Ceiling onward)
local function crack()
    local pz = playerZ()
    local obs = G.obs
    for i = 1, #obs do
        local o = obs[i]
        if o.kind == "tite" and not o.falling then
            local dz = o.z - pz
            if dz > 60 and dz < C.FALL_Z and rnd() < C.FALL_CHANCE then
                o.falling = true
                Harness.count("falls")
            end
        end
    end
end

-- emit. Costs stamina; below the price it drops to a WHISPER (short
-- reach, small light) rather than nothing -- an empty bat can still
-- feel its way out.
function Game.ping()
    if G.pingCD > 0 then return end
    local cost, reach, r1 = C.PING_COST, C.PING_REACH, C.PING_R1
    local whis = false
    if G.stam < cost then
        cost = cost * C.WHISPER
        if G.stam < cost then
            Sfx.dry()
            G.pingCD = C.PING_CD
            return
        end
        reach, r1, whis = reach * C.WHISPER, r1 * C.WHISPER_R, true
    end
    G.stam = G.stam - cost
    G.pingT, G.pingAge = C.PING_LIFE, 0
    G.front, G.prevFront = 0, 0
    G.reach, G.pingR1, G.whisper = reach, r1, whis
    G.pingCD = C.PING_CD
    G.memT = C.MEM_LIFE
    Harness.count("pings")
    if whis then
        Harness.count("whispers")
        Sfx.whisper()
    else
        Sfx.ping()
    end
    scheduleEchoes(reach)
    if G.cav.wet then G.wetPend = C.WET_DELAY end
    if G.cav.fall then crack() end
    if G.owl.on then G.owl.d = G.owl.d - C.OWL_PING end
    -- answering Vesper: her call is still ringing, so yours lands on it
    local r = G.rival
    if r.on and r.window > 0 and not r.answered then
        r.answered = true
        G.stam = min(C.STAM_MAX, G.stam + C.STAM_ANSWER)
        Game.revealTo(C.ANSWER_REACH)
        Harness.count("answers")
        Sfx.answer()
    end
end

local function updatePing(dt)
    if G.pingT > 0 then
        G.pingT = max(0, G.pingT - dt)
        G.pingAge = G.pingAge + dt
        G.prevFront = G.front
        G.front = min(G.reach, G.pingAge * C.PING_SPD)
        revealShell(G.prevFront, G.front)
        G.memZ = max(G.memZ, playerZ() + G.front)
    end
    -- the pool's second, softer answer
    if G.wetPend > 0 then
        G.wetPend = G.wetPend - dt
        if G.wetPend <= 0 then
            G.wetPend = 0
            G.wetT = C.WET_LIFE
            Game.revealTo(C.PING_REACH * C.WET_REACH)
            Sfx.wet()
            Harness.count("reflections")
        end
    end
    G.wetT = max(0, G.wetT - dt)
    G.memT = max(0, G.memT - dt)
end

-- ---- damage --------------------------------------------------------------

local function crash()
    if G.invulnT > 0 then return end
    G.lives = G.lives - 1
    G.invulnT, G.stunT, G.scrapeT = C.INVULN, C.STUN, 0
    Kit.shake(0.32)
    Kit.burst(G.parts, G.sx, G.sy, 14, 120, 50)
    Sfx.crash()
    Harness.count("crashes")
    local pz = playerZ()
    G.px = G.px + (Cave.centerAt(pz) - G.px) * 0.65
    G.py = C.MID
    if G.lives <= 0 then Game.failCavern() end
end
Game.crash = crash

local function owlStrike()
    G.owl.d = C.OWL_RESET
    G.owl.hitT = 0.7
    Kit.shake(0.45)
    Sfx.strike()
    Harness.count("owlStrikes")
    if G.invulnT <= 0 then
        G.lives = G.lives - 1
        G.invulnT = C.INVULN
        if G.lives <= 0 then Game.failCavern() end
    end
end

-- ---- collisions ------------------------------------------------------------

local function eat(o, i)
    G.moths = G.moths + 1
    G.stam = min(C.STAM_MAX, G.stam + C.STAM_MOTH)
    if G.owl.on then
        G.owl.d = min(C.OWL_MAX, G.owl.d + C.OWL_MOTH)
    end
    Sfx.moth()
    Harness.count("moths")
    Cave.dropAt(i)
end

local function crossings(zPrev, zNow)
    local obs = G.obs
    for i = #obs, 1, -1 do
        local o = obs[i]
        if o.z > zPrev and o.z <= zNow then
            local dx = abs(Cave.obsX(o) - G.px)
            if o.kind == "moth" then
                if dx < C.MOTH_W
                    and abs(Cave.obsY(o) - G.py) < C.MOTH_H then
                    eat(o, i)
                end
            elseif G.invulnT <= 0
                and dx < Cave.widthOf(o) and Cave.blocks(o, G.py) then
                crash()
            end
        end
    end
end

-- walls forgive: you are clamped and drained, and only killed if you
-- lean on the rock for SCRAPE_KILL seconds
local function walls(dt)
    local pz = playerZ()
    local c, lim = Cave.centerAt(pz), Cave.limitAt(pz)
    local d = G.px - c
    local on = false
    if d > lim then
        G.px, on = c + lim, true
    elseif d < -lim then
        G.px, on = c - lim, true
    end
    if on then
        G.scrapeT = G.scrapeT + dt
        G.stam = max(0, G.stam - C.STAM_SCRAPE * dt)
        G.scrapeTick = G.scrapeTick - dt
        if G.scrapeTick <= 0 then
            G.scrapeTick = C.SCRAPE_TICK
            Sfx.scrape()
            Harness.count("scrapes")
        end
        if G.scrapeT >= C.SCRAPE_KILL then crash() end
    else
        G.scrapeT = max(0, G.scrapeT - dt * 2)
    end
end

-- ---- the other bat, and the owl ---------------------------------------------

local function rival(dt)
    local r = G.rival
    if not r.on then return end
    local pz = playerZ()
    r.z = pz + C.RIVAL_LEAD + sin(G.time * 0.5) * 90
    local h = Cave.halfAt(r.z)
    r.x = Cave.centerAt(r.z) + sin(G.time * 0.43) * h * 0.35
    r.y = C.MID + sin(G.time * 0.71) * 15
    r.callT = max(0, r.callT - dt)
    r.window = max(0, r.window - dt)
    r.cd = r.cd - dt
    if r.cd <= 0 then
        r.cd = C.RIVAL_CD
        r.callT = C.RIVAL_LIFE
        r.window = C.ANSWER_W
        r.answered = false
        Sfx.call()
        Harness.count("calls")
        -- her voice lights her own stretch of tunnel, not yours
        local obs = G.obs
        for i = 1, #obs do
            local o = obs[i]
            if abs(o.z - r.z) < 280 then
                o.mem, o.seen = 1, true
            end
        end
    end
end

local function owl(dt)
    local o = G.owl
    if not o.on then return end
    o.d = o.d - C.OWL_CLOSE * dt
    if G.lit > 0 then
        o.d = o.d - C.OWL_LIT * G.lit * dt
    end
    if o.d > C.OWL_MAX then o.d = C.OWL_MAX end
    o.hitT = max(0, o.hitT - dt)
    o.cryT = o.cryT - dt
    if o.cryT <= 0 then
        o.cryT = C.OWL_CRY
        Sfx.owl()
        Harness.count("owlCries")
    end
    if o.d <= 0 then owlStrike() end
end

-- ---- per-object bookkeeping ---------------------------------------------------
-- one pass: memory rots, cracked stalactites come down

local function tickObjects(dt)
    local rot = dt / C.MEM_LIFE
    local obs = G.obs
    for i = 1, #obs do
        local o = obs[i]
        if o.mem > 0 then
            o.mem = o.mem - rot
            if o.mem < 0 then o.mem = 0 end
        end
        if o.falling then
            local limit = C.CAVEH - C.LEN[o.size]
            if o.drop < limit then
                o.drop = min(limit, o.drop + C.FALL_SPD * dt)
            end
        end
    end
end

-- ---- the campaign -------------------------------------------------------------

function Game.unlocked()
    return Save.get("unlocked", 1)
end

function Game.cavIndexByName(name)
    for i = 1, C.NCAV do
        if C.CAVERNS[i].name == name then return i end
    end
    return 1
end

-- the map list: five rows around the selection, rebuilt only when the
-- selection window or the save actually changes (menus are a draw
-- path too)
function Game.buildMap()
    G.enter(G.mapSel) -- the backdrop previews whatever is selected
    local top = clamp(G.mapSel - 2, 1, max(1, C.NCAV - C.MAP_ROWS + 1))
    G.mapTop = top
    local un = Game.unlocked()
    for r = 1, C.MAP_ROWS do
        local i = top + r - 1
        local row = G.mapRows[r]
        if not row then
            row = {}
            G.mapRows[r] = row
        end
        local cv = C.CAVERNS[i]
        row.label = i .. ". " .. cv.name
        if i > un then
            row.sub = "locked"
        else
            local m = Save.get("m" .. i, -1)
            row.sub = m >= 0 and (m .. " moths") or "new"
        end
        row.index = i
    end
    G.mapDirty = false
end

function Game.chooseSlot()
    Save.use(G.slotSel)
    if Save.load(G.slotSel) then
        G.cleared = Save.get("cleared", 0)
        G.mapSel = clamp(Game.unlocked(), 1, C.NCAV)
        G.mapDirty = true
        Kit.setMode("map")
        Music.set(Sfx.DRIP)
        Sfx.select()
    else
        Save.reset{ name = "Pip", place = C.CAVERNS[1].name, pct = 0 }
        Save.set("unlocked", 1)
        Save.set("cleared", 0)
        Save.commit()
        G.cleared = 0
        G.mapSel = 1
        G.mapDirty = true
        Kit.setMode("map")
        Tale.play("intro")
    end
end

function Game.begin()
    G.enter(G.mapSel)
    G.launch()
    G.lives = G.cav.lives or C.LIVES
    Kit.setMode("play")
    Music.set(Sfx.SONGS[G.cav.song])
    Harness.count("flights")
    Harness.set("cavern", G.cav.name)
end

function Game.clearCavern()
    local i = G.cavI
    Save.unlock(min(C.NCAV, i + 1))
    if G.moths > Save.get("m" .. i, -1) then
        Save.set("m" .. i, G.moths)
    end
    local t = floor(G.runT * 10) / 10
    local bt = Save.get("t" .. i, 0)
    if bt == 0 or t < bt then Save.set("t" .. i, t) end
    Save.set("cleared", max(Save.get("cleared", 0), i))
    Save.meta.place = G.cav.name
    Save.meta.pct = floor(Save.get("cleared", 0) / C.NCAV * 100 + 0.5)
    Save.commit()
    G.cleared = Save.get("cleared", 0)
    G.mapDirty = true
    Harness.count("cavernsCleared")
    Kit.setMode("clear", 1.0)
    Sfx.clear()
end

function Game.failCavern()
    Kit.setMode("fail", 0.9)
    Sfx.fail()
    Harness.count("groundings")
end

-- leave a cleared cavern: play its scene if it has one, then move the
-- map cursor to whatever comes next
function Game.advance()
    if G.cavI >= C.NCAV then
        G.done = true
        Harness.set("done", 1)
        Kit.setMode("end")
        Music.set(Sfx.DRIP)
        return
    end
    G.mapSel = clamp(G.cavI + 1, 1, C.NCAV)
    G.mapDirty = true
    Kit.setMode("map")
    Music.set(Sfx.DRIP)
end

function Game.afterCavern()
    if not Tale.after(G.cavI, Game.advance) then
        Game.advance()
    end
end

-- ---- the loop -------------------------------------------------------------------

local function menu(dt)
    local m = Kit.mode
    if m == "title" then
        if Input.a then
            Kit.setMode("slots")
            Sfx.select()
        end
    elseif m == "slots" then
        if Input.up or Input.down then
            G.slotSel = clamp(G.slotSel + (Input.down and 1 or -1),
                1, Save.SLOTS)
            Sfx.tick()
        end
        if Input.a then Game.chooseSlot() end
        if Input.b then Kit.setMode("title") end
    elseif m == "map" then
        if Input.up or Input.down then
            G.mapSel = clamp(G.mapSel + (Input.down and 1 or -1),
                1, C.NCAV)
            G.mapDirty = true
            Sfx.tick()
        end
        if Input.a then
            if G.mapSel <= Game.unlocked() then
                Game.begin()
            else
                Sfx.dry()
            end
        end
        if Input.b then Kit.setMode("slots") end
        if G.mapDirty then Game.buildMap() end
    elseif m == "clear" then
        G.dissT = min(0.35, G.dissT + dt * 0.8)
        if Input.a and Kit.modeT <= 0 then Game.afterCavern() end
    elseif m == "fail" then
        G.dissT = min(0.55, G.dissT + dt * 0.9)
        if Kit.modeT <= 0 then
            if Input.a then
                Game.begin() -- straight back in, same cavern
            elseif Input.b then
                Kit.setMode("map")
                Music.set(Sfx.DRIP)
            end
        end
    elseif m == "end" then
        if Input.a then
            Kit.setMode("title")
            Sfx.select()
        end
    end
end

local function fly(dt)
    local cv = G.cav
    local cam = Scaler.cam
    G.runT = G.runT + dt
    G.wipeT = max(0, G.wipeT - dt * 1.6)
    G.invulnT = max(0, G.invulnT - dt)
    G.stunT = max(0, G.stunT - dt)
    G.pingCD = max(0, G.pingCD - dt)
    G.stam = min(C.STAM_MAX, G.stam + C.STAM_REGEN * dt)

    if Input.a then Game.ping() end
    updatePing(dt)

    G.trim = clamp(G.trim + Input.crank * C.TRIM_GAIN,
        C.TRIM_LO, C.TRIM_HI)

    -- the cave breathes: between glimpses the wind moves you
    if cv.wind > 0 then
        G.gust = sin(G.time * C.WIND_HZ) * 0.72
            + sin(G.time * C.WIND_HZ2 + 1.7) * 0.28
        G.wind = cv.wind * G.gust
    else
        G.wind, G.gust = 0, 0
    end

    G.px = G.px + (Input.mx * C.XSPD + G.wind) * dt
    G.py = clamp(G.py + Input.my * C.YSPD * dt, C.PY_LO, C.PY_HI)

    G.spd = cv.spd * G.trim * (G.stunT > 0 and 0.55 or 1)
    local zPrev = cam.z + C.PZ
    cam.z = cam.z + G.spd * dt
    cam.x = G.px * C.CAMX
    cam.y = C.MID + (G.py - C.MID) * C.CAMY_F
    Cave.stream()
    G.dist = cam.z - G.z0

    walls(dt)
    crossings(zPrev, cam.z + C.PZ)
    tickObjects(dt)
    rival(dt)
    owl(dt)

    Harness.set("dist", floor(G.dist))
    if G.dist >= cv.len then Game.clearCavern() end
end

function Game.update(dt)
    G.frame = G.frame + 1
    G.time = G.time + dt
    Music.update(dt)
    Kit.updateShake(dt)
    Kit.updateParts(G.parts, dt, 90, nil)
    -- a scene owns the frame it ends on too: without this, the A that
    -- dismissed the last line would also pick the menu item under it
    local wasStory = Story.active
    Story.update(dt, Input.a, Input.b)
    if Story.active or wasStory then return end
    if Kit.mode == "play" then
        fly(dt)
    else
        menu(dt)
    end
end
