-- A stubbed Playdate SDK for running dither off-device under system
-- Lua 5.4. Shared by tools/headless.lua (whole games) and
-- tools/coretest.lua (the engine's own self-test).
--
-- Drawing is no-op'd: the shade/light/scaler stack still runs all of
-- its math, it just paints into nothing. The datastore stub mimics
-- JSON round-trip semantics (dict keys become strings, contiguous
-- arrays stay arrays), so save/load bugs surface here, off device.
--
-- Callers set STUB_ROOT (repo root, trailing slash) and optionally
-- STUB_GAME (a games/<g>/ dir to resolve imports from) before dofile.

local root = STUB_ROOT or "./"
local game = STUB_GAME

local function noop() end

local newImage

local imageMeta = {}
imageMeta.__index = imageMeta

function imageMeta:draw() end
function imageMeta:drawScaled() end
function imageMeta:drawFaded() end
function imageMeta:drawRotated() end
function imageMeta:drawCentered() end
function imageMeta:drawAnchored() end
function imageMeta:drawTiled() end
function imageMeta:clear() end
function imageMeta:getSize() return self.width, self.height end
function imageMeta:setInverted() return self end
function imageMeta:invertedImage() return self end
function imageMeta:copy() return newImage(self.width, self.height) end

function imageMeta:scaledImage(sx, sy)
    return newImage(math.max(1, math.floor(self.width * sx)),
        math.max(1, math.floor(self.height * (sy or sx))))
end

newImage = function(w, h)
    return setmetatable({ width = w or 1, height = h or 1 }, imageMeta)
end

local gfx = {
    kColorBlack = 0, kColorWhite = 1, kColorClear = 2, kColorXOR = 3,
    kDrawModeCopy = 0, kDrawModeFillWhite = 1, kDrawModeFillBlack = 2,
    kDrawModeNXOR = 3, kDrawModeInverted = 4,
    kLineCapStyleButt = 0, kLineCapStyleRound = 1,
    image = {
        new = function(w, h) return newImage(w, h) end,
        kDitherTypeBayer8x8 = 1,
        kDitherTypeBayer4x4 = 2,
        kDitherTypeNone = 0,
    },
    pushContext = noop, popContext = noop,
    setColor = noop, setPattern = noop, setImageDrawMode = noop,
    setStencilImage = noop, setStencilPattern = noop, clearStencil = noop,
    clearStencilImage = noop,
    setClipRect = noop, clearClipRect = noop,
    fillRect = noop, drawRect = noop, drawLine = noop,
    drawPixel = noop, fillTriangle = noop, fillCircleAtPoint = noop,
    drawCircleAtPoint = noop, drawArc = noop, fillCircleInRect = noop,
    fillEllipseInRect = noop, drawEllipseInRect = noop,
    fillRoundRect = noop, drawRoundRect = noop,
    fillPolygon = noop, drawPolygon = noop,
    setLineWidth = noop, setLineCapStyle = noop,
    setDitherPattern = noop, setDrawOffset = noop, setBackgroundColor = noop,
    clear = noop,
    drawText = noop, drawTextAligned = noop, setFont = noop,
    getTextSize = function(s) return #tostring(s) * 7, 16 end,
    getDisplayImage = function() return newImage(400, 240) end,
}

kTextAlignment = { left = 0, right = 1, center = 2 }

-- JSON round trip: dict keys stringify, contiguous arrays survive
local function jsonify(v)
    if type(v) ~= "table" then return v end
    local n = 0
    for _ in pairs(v) do n = n + 1 end
    local isArray = n == #v
    local out = {}
    for k, val in pairs(v) do
        if isArray then
            out[k] = jsonify(val)
        else
            out[tostring(k)] = jsonify(val)
        end
    end
    return out
end

DISK = {}
local disk = DISK

-- silent synths (dsnd pools, dmusic voices)
local sound = {
    kWaveSquare = 0, kWaveTriangle = 1, kWaveSawtooth = 2,
    kWaveSine = 3, kWaveNoise = 4, kWavePOPhase = 5,
    synth = {
        new = function()
            return {
                playNote = noop, stop = noop, setADSR = noop,
                setVolume = noop, isPlaying = function() return false end,
            }
        end,
    },
}

local ms = 0

playdate = {
    graphics = gfx,
    sound = sound,
    datastore = {
        write = function(t, name) disk[name or "data"] = jsonify(t) end,
        read = function(name)
            local v = disk[name or "data"]
            return v and jsonify(v) or nil
        end,
        delete = function(name) disk[name or "data"] = nil end,
    },
    display = {
        setRefreshRate = noop, setInverted = noop,
        getWidth = function() return 400 end,
        getHeight = function() return 240 end,
    },
    kButtonA = "a", kButtonB = "b", kButtonUp = "up",
    kButtonDown = "down", kButtonLeft = "left", kButtonRight = "right",
    buttonIsPressed = function() return false end,
    buttonJustPressed = function() return false end,
    buttonJustReleased = function() return false end,
    getCrankTicks = function() return 0 end,
    getCrankChange = function() return 0, 0 end,
    getCrankPosition = function() return 0 end,
    isCrankDocked = function() return false end,
    getSecondsSinceEpoch = function()
        return tonumber(os.getenv("SEED")) or 12345
    end,
    getCurrentTimeMilliseconds = function()
        ms = ms + 1
        return ms
    end,
    resetElapsedTime = noop,
    getElapsedTime = function() return 0 end,
    getFPS = function() return 30 end,
    setMenuImage = noop,
    getSystemMenu = function()
        return {
            addMenuItem = noop, addOptionsMenuItem = noop,
            addCheckmarkMenuItem = noop, removeAllMenuItems = noop,
        }
    end,
    simulator = nil,
}

-- ---- import shim ----------------------------------------------------------

local loaded = {}

function import(name)
    if loaded[name] then return end
    loaded[name] = true
    if name == "smokeflag" or name:find("^CoreLibs/") then return end
    local paths = { root .. "core/" .. name .. ".lua" }
    if game then
        paths[#paths + 1] = root .. "games/" .. game .. "/" .. name .. ".lua"
    end
    for _, p in ipairs(paths) do
        local f = io.open(p, "r")
        if f then
            f:close()
            dofile(p)
            return
        end
    end
    error("import: cannot find " .. name)
end
