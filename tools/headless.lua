-- Headless smoke: run a game's SMOKE build logic under system Lua 5.4
-- against tools/sdkstub.lua — no Simulator, no drawing, real math.
--
--   lua tools/headless.lua glim [frames]
--   SEED=4 lua tools/headless.lua prowl
--
-- Exits 0 and prints the final heartbeat + PASS when the run latches
-- no error and the game's expectations hold. A game ships its floors
-- in games/<g>/expect.lua (stripped from pdx staging):
--   return { frames = 20000, counters = { done = 1, ... } }
--
-- Headless is the fast gate, not the last word: it cannot catch a
-- misdrawn screen or an SDK call the stub happens to no-op. Every
-- game still has to run in the real Simulator (tools/smoke.sh).

local game = arg[1] or "glim"
local FRAMES = tonumber(arg[2]) or 20000

-- Fallback floors for the three wave-1 games, which predate expect.lua.
local EXPECT = {
    sprint = { laps = 1, finishes = 1 },
    glim = { jarred = 1 },
    skimmer = { catches = 1, runs = 1 },
}

local root = arg[0]:gsub("tools/headless%.lua$", "")
if root == arg[0] then root = "./" end

-- ---- per-game expect.lua override -----------------------------------------

local expect = EXPECT[game] or {}
do
    local p = root .. "games/" .. game .. "/expect.lua"
    local f = io.open(p, "r")
    if f then
        f:close()
        local spec = dofile(p)
        expect = spec.counters or spec
        if not tonumber(arg[2]) and spec.frames then
            FRAMES = spec.frames
        end
    end
end

-- ---- SDK stub -------------------------------------------------------------

STUB_ROOT, STUB_GAME = root, game
dofile(root .. "tools/sdkstub.lua")

SMOKE_BUILD = true
SMOKE_SHOT_PATH = nil
SMOKE_SEED = tonumber(os.getenv("SEED")) or 1

-- ---- run ------------------------------------------------------------------

import("main")

for _ = 1, FRAMES do
    playdate.update()
end

local err = DISK["err"]
local beat = DISK["smoke"] or {}
local keys = {}
for k in pairs(beat) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do
    print(string.format("  %-14s %s", k, tostring(beat[k])))
end
if err then
    print("FAIL: latched error: " .. tostring(err.err))
    os.exit(1)
end
local bad = false
for k, want in pairs(expect) do
    local got = tonumber(beat[k]) or 0
    if got < want then
        print(string.format("FAIL: %s = %s, want >= %s", k, got, want))
        bad = true
    end
end
if bad then os.exit(1) end
print("PASS (" .. FRAMES .. " frames, seed " .. SMOKE_SEED .. ")")
