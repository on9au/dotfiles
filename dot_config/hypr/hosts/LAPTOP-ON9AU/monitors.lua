-- Monitors -- LAPTOP-ON9AU (Dell Pro Max 16 Premium, built-in panel only).
--
--   +----------------------------------------+
--   |  Samsung 16"  3840x2400 @ 120Hz        |
--   |  scale 2 -> 1920x1200 logical          |
--   +----------------------------------------+
--     at 0x0
--
-- Why scale 2: the panel is ~283 DPI (348x223 mm), and 2 is what KDE was
-- using. It divides both axes evenly -- 1920x1200 exactly -- so nothing is
-- resampled. A fractional scale is where the blur on a panel this dense comes
-- from, and there is no second monitor here to match physical text size
-- against, which is the only reason the desktop needs fractional scales.
--
-- Why the mode is spelled out even though it equals `preferred`: unlike both
-- desktop monitors, this panel genuinely prefers 3840x2400@120, so
-- mode = "preferred" would be correct today. It is named anyway so that a
-- firmware or EDID change cannot quietly drop the session to 60Hz.

-- WHY NOT `output = "eDP-1"`:
--
-- The connector name is not stable on this machine. Same hardware, no config
-- change, different kernels:
--
--   kernel 7.1.6   i915 was card0   panel was eDP-2
--   kernel 7.1.8   i915 is  card1   panel is  eDP-1
--
-- simpledrm holds a DRM minor from the EFI framebuffer until a real driver
-- displaces it, and which of i915/nvidia lands on which minor depends on init
-- timing; the connector name follows. The nvidia card also exposes an eDP
-- connector of its own (nothing is wired to it), so both names exist in
-- /sys/class/drm at once. Matching on the EDID description survives all of it.
--
-- THE STRING BELOW IS UNVERIFIED. The panel's EDID carries manufacturer SDC
-- (Samsung Display) and model 16898 = 0x4202, but no product-name descriptor,
-- so the description Hyprland builds cannot be derived from the EDID alone.
-- Read the real one at the first Hyprland login and paste it here:
--
--   hyprctl monitors all          # the `description:` field
--
-- desc: is a prefix match, so a leading fragment of it is enough. If the
-- string is wrong this block is simply inert and the catch-all below still
-- brings the panel up correctly -- see the note there.
local PANEL = "desc:Samsung Display Corp"

-- Catch-all first: anything not matched below gets these.
--
-- Note the scale. On the desktop this line is a neutral fallback for a display
-- that gets plugged in; here it doubles as the safety net for the unverified
-- description above, so it is deliberately shaped like the built-in panel --
-- preferred mode (which is 120Hz on this panel) at scale 2. The cost is that
-- an external display plugged into HDMI or USB-C would also come up at scale
-- 2, which on a 1080p screen means a 960x540 logical desktop. That is wrong
-- but obvious, and the fix is to give that display its own hl.monitor block
-- here rather than to weaken the fallback for the screen that is always there.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 2,
})

-- The built-in panel.
hl.monitor({
    output   = PANEL,
    mode     = "3840x2400@120",
    position = "0x0",
    scale    = 2,

    -- The panel reports a 30-120Hz VRR range, so this could be 1 (or 2, which
    -- also applies it to fullscreen-only). It is off because that is what KDE
    -- has been running, so this migration changes one thing at a time --
    -- brightness flicker at low refresh is the usual reason an eDP panel is
    -- left with VRR off. Try 1 once the session is otherwise settled.
    vrr = 0,
})
