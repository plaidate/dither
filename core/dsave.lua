-- Dither core: progress saves, three slots. Kit.saveBest keeps one
-- number; this keeps a campaign — which stages are unlocked, what the
-- player is carrying, where they were.
--
--   Save.use(1)                     -- pick a slot
--   Save.data.stage = 4             -- the game's own table
--   Save.meta.place = "Cliff Road"  -- the save-card line
--   Save.commit()                   -- one datastore write
--
-- On disk (datastore keys "save1".."save3", per-bundle sandbox):
--   { v = 1,
--     meta = { name=, place=, pct=, time= },  -- scalars only
--     data = <the game's table> }
--
-- JSON round-trip rules, learned the hard way in lore and reproduced
-- by tools/headless.lua so bugs surface off-device:
--  * table keys come back as STRINGS — key your tables with strings
--    ("s3", not 3), or use arrays with no holes.
--  * arrays with holes come back as dicts. Keep them contiguous.
--  * functions and nan do not survive. Scalars, strings, booleans,
--    arrays and string-keyed tables do.
-- `time` is an integer from playdate.getSecondsSinceEpoch(), not a
-- formatted date — formatting is the game's business.

Save = {}

Save.SLOTS = 3
Save.VERSION = 1

Save.slot = 1
Save.data = {}   -- the game's progress table
Save.meta = {}   -- the save card: name / place / pct / time

local function key(slot)
    return "save" .. (slot or Save.slot)
end

-- switch the active slot without touching what is in memory
function Save.use(slot)
    Save.slot = math.max(1, math.min(Save.SLOTS, slot or 1))
    return Save.slot
end

-- start a fresh game in the active slot (memory only — nothing is
-- written until commit)
function Save.reset(meta)
    Save.data = {}
    Save.meta = meta or {}
    return Save.data
end

-- read a slot -> true if a save was there. Fills Save.data/Save.meta.
function Save.load(slot)
    Save.use(slot or Save.slot)
    local t = playdate.datastore.read(key())
    if not t or not t.data then return false end
    Save.data = t.data
    Save.meta = t.meta or {}
    Harness.count("loads")
    return true
end

-- write the active (or given) slot. Cheap enough for every
-- checkpoint; games should NOT call it every frame.
function Save.commit(slot)
    Save.use(slot or Save.slot)
    Save.meta.time = playdate.getSecondsSinceEpoch()
    playdate.datastore.write({
        v = Save.VERSION,
        meta = Save.meta,
        data = Save.data,
    }, key())
    Harness.count("saves")
    return true
end

-- the save card for a slot without disturbing the live game, or nil
function Save.summary(slot)
    local t = playdate.datastore.read(key(slot))
    if not t or not t.data then return nil end
    return t.meta or {}
end

function Save.exists(slot)
    return Save.summary(slot) ~= nil
end

-- any slot at all — for the title screen's "Continue"
function Save.any()
    for s = 1, Save.SLOTS do
        if Save.exists(s) then return s end
    end
    return nil
end

function Save.wipe(slot)
    if slot then
        playdate.datastore.delete(key(slot))
    else
        for s = 1, Save.SLOTS do
            playdate.datastore.delete(key(s))
        end
    end
    Save.data, Save.meta = {}, {}
end

-- ---- shorthands ------------------------------------------------------
-- String keys only (see the JSON rules above). Save.flag is the
-- one-way latch campaigns want for "this cutscene has played".

function Save.set(k, v)
    Save.data[tostring(k)] = v
end

function Save.get(k, default)
    local v = Save.data[tostring(k)]
    if v == nil then return default end
    return v
end

function Save.flag(k, on)
    k = "f_" .. tostring(k)
    if on == nil then return Save.data[k] == true end
    Save.data[k] = on and true or nil
    if on then Harness.count("flagsSet") end
    return on
end

-- highest unlocked stage: monotonic, never walks backwards
function Save.unlock(n)
    local cur = Save.data.unlocked or 1
    if n > cur then
        Save.data.unlocked = n
        Harness.set("unlocked", n)
    end
    return Save.data.unlocked
end
