-- Keyboard and mouse. This is a desktop, so there is no touchpad section.

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        -- 0 = use libinput's own acceleration untouched.
        sensitivity = 0,

        numlock_by_default = true,

        -- Snappier key repeat than the default 25/600.
        repeat_rate  = 40,
        repeat_delay = 250,
    },

    cursor = {
        -- Hide the pointer after 5s of no mouse movement.
        inactive_timeout = 5,
    },

    binds = {
        -- Pressing the current workspace's key again jumps back to the
        -- previous one.
        workspace_back_and_forth = true,
    },
})

--------------------------
---- POINTER FEEL      ----
--------------------------

-- Matched to how the mouse behaved under KDE.
--
-- KDE only overrode this one device (kcminputrc:
-- [Libinput][9610][8209][Glorious Model O Wireless]
-- PointerAccelerationProfile=1 -> Flat, with no PointerAcceleration key, so
-- speed 0). Everything else stayed on libinput defaults, so this is a device
-- rule rather than a global one -- leaving the drawing tablet and the
-- keyboard's built-in pointer untouched.
--
-- Two things had to change:
--
-- 1. accel_profile. Hyprland leaves libinput on its "adaptive" default, which
--    accelerates based on how fast you move. KDE was on "flat" (raw, 1:1).
--    This is the bigger of the two differences by far.
--
-- 2. sensitivity, to cancel out the scaling change. Pointer motion happens in
--    logical pixels, so a lower monitor scale means a wider logical desktop
--    and the same hand movement covers proportionally less of the screen:
--
--                   KDE scale -> logical      here -> logical     ratio
--      AOC  DP-2      1.5        2560 wide     1.25    3072       1.200
--      Dell DP-1      1.75       2194 wide     1.5     2560       1.167
--
--    libinput's flat profile is a plain multiplier of (1 + sensitivity), so
--    0.2 is +20%: exact for the AOC, and ~3% quick on the Dell -- below the
--    threshold where anyone notices, and one pointer cannot have two speeds.
--
-- If it still feels off, this is the only number to touch. It is linear:
-- 0.1 is +10%, -0.1 is -10%.
hl.device({
    name = "glorious-model-o-wireless",

    accel_profile = "flat",
    sensitivity   = 0.2,
})
