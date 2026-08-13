-- Applications started with the session -- LAPTOP-ON9AU.
--
-- The daemons (waybar, swaync, hypridle, the polkit agent, cliphist, the
-- wallpaper) are not here; they are the same on every machine and live in
-- autostart.lua. This file is only the applications.
--
-- Required from inside the hyprland.start handler, so these run at start-up
-- like the daemons above them.

local apps   = require("apps")
local launch = require("launch")

launch.app_on(apps.terminal, 1)
launch.app_on(apps.browser, 2)

-- Spotify was on workspace 7 when 6-10 lived on a second screen. With five
-- persistent workspaces on one panel it goes to the last of them: still out of
-- the way of the terminal and the browser, but one key away and visible in the
-- bar.
launch.app_on("spotify-launcher", 5)

-- Not started here, and deliberately:
--
--   discord   was on workspace 6, which no longer exists as its own screen.
--             Start it by hand when it is wanted.
--   steam     is not installed on this machine. Leaving `steam -silent` in
--             would fail at every single login.
