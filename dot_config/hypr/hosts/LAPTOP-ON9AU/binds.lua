-- Hardware keys that only exist on LAPTOP-ON9AU.
--
-- Nothing here uses SUPER: these are the dedicated Fn-row keys, which the
-- shared binds.lua has no reason to know about.
--
-- `locked` keeps them working while hyprlock is up -- being unable to turn the
-- backlight up on a dark lock screen is exactly when you want it most.
-- `repeating` lets the key auto-repeat while held.
local keys = { locked = true, repeating = true }

--------------------------
---- SCREEN BACKLIGHT ----
--------------------------

-- `-d intel_backlight` is not optional. This machine has TWO devices in
-- /sys/class/backlight -- intel_backlight (the panel) and nvidia_0 (the
-- discrete GPU, which has no display wired to it). brightnessctl with no -d
-- picks the first device it finds, which is nvidia_0, so the unqualified
-- command appears to work, reports a percentage, and changes nothing you can
-- see.
--
-- `-n` clamps the minimum to 1 rather than 0, so holding the down key cannot
-- black the panel out entirely and leave you hunting for it in the dark.
local backlight = "brightnessctl -d intel_backlight -n set "

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(backlight .. "5%+"), keys)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(backlight .. "5%-"), keys)

----------------------------
---- KEYBOARD BACKLIGHT ----
----------------------------

-- dell::kbd_backlight is an LED, not a backlight, hence -c leds. It has three
-- levels (0, 1, 2), so this steps by 1 rather than by a percentage -- 5% of a
-- range of 2 rounds to nothing.
--
-- Dell's firmware may already handle this key itself, in which case these
-- binds are redundant rather than harmful: check with `brightnessctl -c leds
-- -d dell::kbd_backlight get` before and after pressing it. If the level moves
-- by two steps at a time, the firmware is also acting on it -- delete these
-- two lines and let the firmware have it.
local kbd = "brightnessctl -c leds -d dell::kbd_backlight set "

hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(kbd .. "+1"), keys)
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(kbd .. "1-"), keys)
