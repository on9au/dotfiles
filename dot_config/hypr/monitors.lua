-- Monitors.
--
-- Physical layout, left to right:
--
--   +---------------------------+  +----------------------+
--   |  AOC U32G4   32"  DP-2    |  | Dell U2725QE 27" DP-1|
--   |  3840x2160 @ 160Hz        |  | 3840x2160 @ 120Hz    |
--   |  scale 1.25 -> 3072x1728  |  | scale 1.5 -> 2560x1440|
--   +---------------------------+  +----------------------+
--     at 0x0 (primary)               at 3072x144
--
-- Why the explicit modes: BOTH panels advertise 3840x2160@60 as their
-- *preferred* mode, so `mode = "preferred"` silently caps you at 60Hz.
-- Naming the mode is what gets you 160/120Hz.
--
-- Why those scales: the 32" is ~138 DPI and the 27" is ~163 DPI. Scaling
-- them 1.25 and 1.5 makes text come out the same physical size on both.
-- Both divide 3840 evenly (3072 and 2560), which avoids fractional-scale
-- blurring.
--
-- The 144px y-offset on the Dell centres it vertically against the taller
-- logical height of the AOC ((1728 - 1440) / 2 = 144), so the mouse crosses
-- between screens at the height you expect.
--
-- To identify outputs after a cable change:  hyprctl monitors all

-- Catch-all first: any output not named below gets sane defaults, so
-- plugging in a random display still lights it up.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- AOC U32G4 -- 32" 4K 160Hz, left, primary
hl.monitor({
    output   = "DP-2",
    mode     = "3840x2160@160",
    position = "0x0",
    scale    = 1.25,
})

-- Dell U2725QE -- 27" 4K 120Hz, right
hl.monitor({
    output   = "DP-1",
    mode     = "3840x2160@120",
    position = "3072x144",
    scale    = 1.5,
})
