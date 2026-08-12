-- Compositor for the login screen. Installed to /etc/greetd/hyprland.lua.
--
-- Lua, not hyprlang. Hyprland 0.56 treats a .conf as "legacy config" and says
-- so on screen -- which on a greeter means the login prompt comes up with a
-- deprecation warning over it. The Lua path is silent.
--
-- Hyprland rather than cage, because cage cannot describe monitors: it only
-- extends across every output, which built one ~7680px space across both 4K
-- panels and put the prompt across the bezel seam.
--
-- Keep the monitor block in sync with ~/.config/hypr/monitors.lua.

------------------
---- MONITORS ----
------------------

-- AOC U32G4, 32" -- the prompt goes here.
hl.monitor({
    output   = "DP-2",
    mode     = "3840x2160@160",
    position = "0x0",
    scale    = 1.25,
})

-- Dell U2725QE, 27" -- switched off for the login screen.
--
-- This is what actually pins the prompt to the 32", and it is deliberate
-- rather than tidy. Hyprland enumerates DP-1 first (monitor ID 0), so it takes
-- focus at startup and the greeter opened there. Setting
-- cursor.default_monitor and a monitor="DP-2" window rule did NOT move it, and
-- a greeter is not something that can be iterated on quickly -- every attempt
-- costs a logout. With one output there is nothing to get wrong.
--
-- The panel is dark for the few seconds the login screen is up, then comes
-- back with the session. To have both lit instead, replace `disabled` with the
-- mode/position/scale lines from hypr/monitors.lua -- and expect to have to
-- solve the focus problem.
hl.monitor({
    output   = "DP-1",
    disabled = true,
})

-- Anything else that gets plugged in.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

--------------------
---- BEHAVIOUR  ----
--------------------

-- Run the greeter, then tear the compositor down as soon as it exits,
-- otherwise greetd would sit on an empty Hyprland after login.
--
-- The dispatch is in Lua form because this config is Lua -- the classic
-- `hyprctl dispatch exit` would be a parse error here.
hl.on("hyprland.start", function()
    hl.exec_cmd([[sh -c 'regreet; hyprctl dispatch "hl.dsp.exit()"']])
end)

hl.config({
    -- A single fullscreen window: nothing should hint at a tiling WM.
    general = {
        gaps_in     = 0,
        gaps_out    = 0,
        border_size = 0,
    },

    decoration = {
        rounding = 0,
        blur = { enabled = false },
    },

    -- Nothing to animate, and the greeter appears instantly.
    animations = { enabled = false },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,

        -- The greeter's config never changes while it runs.
        disable_autoreload = true,

        -- Silences the "launched directly" complaint. greetd starts this
        -- compositor straight from its config, so the XDG_* variables a
        -- session manager would normally export are not set -- which is fine
        -- for a greeter, but Hyprland warns about it on screen.
        disable_xdg_env_checks = true,

        -- Both panels run fractional scaling; without this Hyprland puts a
        -- notice about it over the login prompt.
        disable_scale_notification = true,

        -- No hyprland-qtutils on the greeter, and no watchdog nag.
        disable_hyprland_guiutils_check = true,
        disable_watchdog_warning        = true,
    },

    -- No news popups or donation nags on a login screen.
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },

    input = {
        kb_layout          = "us",
        numlock_by_default = true,
    },
})

------------------
---- CURSOR   ----
------------------

-- Copied to /usr/share/icons by install.sh, since the greeter user cannot read
-- /home/djpro. Without this the login screen uses the default X cursor and
-- then visibly changes once the session starts.
hl.env("XCURSOR_THEME", "Posy_Cursor_Black")
hl.env("XCURSOR_SIZE", "32")
