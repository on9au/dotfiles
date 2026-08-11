-- Things started with the session.
--
-- Everything goes through `uwsm app`, which puts each program in its own
-- systemd user unit. That means `systemctl --user` can see and restart them,
-- and they get cleaned up properly on logout. It works whether or not the
-- session itself was launched via uwsm.

local apps = require("apps")

---Launch a program in its own systemd unit.
---@param cmd string
local function app(cmd)
    hl.exec_cmd("uwsm app -- " .. cmd)
end

hl.on("hyprland.start", function()
    -- Authentication dialogs (anything asking for a password / sudo prompt).
    app("/usr/lib/hyprpolkitagent/hyprpolkitagent")

    -- Status bar and notification daemon.
    app("waybar")
    app("swaync")

    -- Idle handling: dim, lock, then blank the screens.
    app("hypridle")

    -- Clipboard history, fed to the SUPER + SHIFT + V picker. Two watchers,
    -- because text and images are stored separately.
    app("wl-paste --type text --watch cliphist store")
    app("wl-paste --type image --watch cliphist store")

    -- Wallpaper. The daemon has to be up before an image can be handed to it,
    -- so the two are chained in one shell command rather than raced.
    hl.exec_cmd(
        ("sh -c 'awww-daemon & until awww query >/dev/null 2>&1; do sleep 0.1; done; awww img %q'")
            :format(apps.wallpaper)
    )
end)
