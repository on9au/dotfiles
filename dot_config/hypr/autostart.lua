-- Things started with the session.
--
-- The daemons below run on every machine. Which *applications* start, and on
-- which workspace, is per-machine and lives in the host file:
--
--   hosts/LAPTOP-ON9AU/autostart.lua
--   hosts/desktop/autostart.lua
--
-- The launch helpers both files use are in launch.lua, which explains why
-- everything goes through `uwsm app`.

local apps   = require("apps")
local host   = require("host")
local launch = require("launch")

hl.on("hyprland.start", function()
    -- Authentication dialogs (anything asking for a password / sudo prompt).
    launch.app("/usr/lib/hyprpolkitagent/hyprpolkitagent")

    -- Status bar and notification daemon.
    launch.app("waybar")
    launch.app("swaync")

    -- Idle handling: dim, lock, then blank the screen.
    launch.app("hypridle")

    -- Clipboard history, fed to the SUPER + SHIFT + V picker. Two watchers,
    -- because text and images are stored separately.
    launch.app("wl-paste --type text --watch cliphist store")
    launch.app("wl-paste --type image --watch cliphist store")

    -- Wallpaper. The daemon has to be up before an image can be handed to it,
    -- so the two are chained in one shell command rather than raced.
    hl.exec_cmd(
        ("sh -c 'awww-daemon & until awww query >/dev/null 2>&1; do sleep 0.1; done; awww img %q'")
            :format(apps.wallpaper)
    )

    ------------------------
    ---- APPLICATIONS   ----
    ------------------------
    --
    -- These used to be XDG autostart entries in ~/.config/autostart from the
    -- KDE days. Those are removed via .chezmoiremove -- left in place they run
    -- a second copy, since uwsm honours XDG autostart too.
    --
    -- required here rather than at the top of the file so that the launches
    -- inside it happen at start-up, alongside the daemons above.
    host.load("autostart")
end)
