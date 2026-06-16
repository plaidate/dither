-- Tunables. An original top-down racer in the spirit of Super Sprint, built
-- on the CC0 PySprint assets (converted to 1-bit by convert.py). Physics runs
-- in PySprint's native 640x400 logical space so its constants and the track
-- data apply directly; everything is drawn at S scale onto the 400x240 screen.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    -- logical -> screen
    LOGW = 640,
    LOGH = 400,
    S = 0.6,
    OX = 8, -- (400 - 640*0.6) / 2
    OY = 0,

    -- player car (logical px/frame, angle units = 22.5 deg; from PySprint)
    MAX_SPEED = 6.5,
    ACCEL = 0.30,    -- throttle (A)
    COAST = 0.15,    -- decel when off the throttle
    BRAKE = 0.55,    -- brake / reverse (B)
    REVERSE_MAX = -2.0,
    ROT_STEP = 0.32,  -- d-pad lock, angle-units/frame
    CRANK_GAIN = 1.0, -- 22.5 deg of crank = one angle unit of steer
    MAX_TURN = 0.9,   -- clamp on per-frame steer
    BUMP_SPEED = 1.6, -- speed left after scraping a wall

    -- drones (AI on the racing line)
    N_DRONES = 3,
    DRONE_SPEED = { 4.6, 5.0, 5.5 }, -- logical px/frame along the line
    DRONE_LANES = { -22, 22, 0 },    -- lateral offset (logical px)

    CAR_HIT = 18,    -- car-to-car contact radius (logical)
    PROBE = 9,       -- collision probe ahead of car centre (logical)
    COUNTDOWN = 3,   -- seconds of 3..2..1 before GO

    LAPS_OPTIONS = { 3, 5 },
}
