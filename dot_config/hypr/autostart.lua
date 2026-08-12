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

---Launch a program and place it on a workspace.
---
---The rule is attached to this launch only, so it does not follow the app
---around: opening a second terminal later still lands wherever you are, which
---a `hl.window_rule` matching on class would not.
---
---`silent` puts the window on the workspace without switching to it, so
---startup does not shuffle you between screens while things come up.
---@param cmd string
---@param workspace string|number
local function app_on(cmd, workspace)
    hl.exec_cmd("uwsm app -- " .. cmd, { workspace = workspace .. " silent" })
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

    ------------------------
    ---- APPLICATIONS   ----
    ------------------------
    --
    -- These used to be XDG autostart entries in ~/.config/autostart from the
    -- KDE days. Those are removed via .chezmoiremove -- left in place they run
    -- a second copy, since uwsm honours XDG autostart too.

    app_on(apps.terminal, 1)
    app_on(apps.browser, 2)
    app_on("discord", 6)
    app_on("spotify-launcher", 7)

    -- Steam to the tray only. -silent is Steam's own flag for starting without
    -- opening the library window, so there is no window to place.
    app("steam -silent")
end)
