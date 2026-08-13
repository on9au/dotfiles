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
-- Keep the monitor blocks in sync with ~/.config/hypr/hosts/<host>/monitors.lua.
--
-- ONE FILE, TWO MACHINES. Unlike the session config, this one is not templated
-- by chezmoi: it lives in /etc, which chezmoi does not manage, and gets there
-- through install.sh. It does not need to be templated, because a monitor
-- block for an output that is not connected is simply inert -- so every
-- machine's block can sit here at once and only the matching one takes effect.

------------------
---- MONITORS ----
------------------

-- LAPTOP-ON9AU -- the built-in 16" panel.
--
-- Matched by EDID description, not by connector name: the panel comes up as
-- eDP-1 or eDP-2 depending on which DRM minor i915 gets on that boot. The same
-- unverified-string caveat as the session config applies -- read the real
-- description with `hyprctl monitors all` in a Hyprland session and paste it
-- into both places. If it is wrong here, the catch-all at the bottom still
-- lights the panel, just at whatever scale Hyprland picks for it.
hl.monitor({
    output   = "desc:Samsung Display Corp",
    mode     = "3840x2400@120",
    position = "0x0",
    scale    = 2,
})

-- AOC U32G4, 32" -- on the desktop, the prompt goes here.
hl.monitor({
    output   = "DP-2",
    mode     = "3840x2160@160",
    position = "0x0",
    scale    = 1.25,
})

-- Dell U2725QE, 27" -- switched off for the login screen. Desktop only; there
-- is no DP-1 on the laptop, so this block does nothing there.
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

        -- The desktop's panels run fractional scaling; without this Hyprland
        -- puts a notice about it over the login prompt. The laptop is on an
        -- integer scale and would not raise it, but the option is harmless
        -- there and this file is shared.
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
