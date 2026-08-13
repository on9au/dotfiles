-- Pointing devices -- LAPTOP-ON9AU.
--
-- One touchpad, one touchscreen, no external mouse. The touchscreen needs no
-- configuration: libinput maps it to the only output on its own.

-- Only the leaves named here are changed; the keyboard and cursor settings in
-- input.lua are left alone.
hl.config({
    input = {
        -- Off here, inherited as `true` from the desktop, which has a
        -- full-size keyboard with a numpad.
        --
        -- Whether this keyboard has one was not established: the kernel's
        -- "AT Translated Set 2 keyboard" advertises the whole standard keymap
        -- including KP0-KP9 whether the keys physically exist or not, so the
        -- capability bits prove nothing either way. If there is no numpad this
        -- setting does nothing at all; if there is one, its keys start as
        -- navigation keys and one press of Num Lock fixes it for good. Flip to
        -- true if that turns out to be annoying.
        numlock_by_default = false,

        touchpad = {
            -- Both carried over from KDE, which had them set on this exact
            -- device (kcminputrc,
            -- [Libinput][1739][53241][VEN_06CB:00 06CB:CFF9 Touchpad]):
            --   NaturalScroll=true
            --   DisableWhileTyping=false
            natural_scroll      = true,
            disable_while_typing = false,

            -- KDE had no entry for these, which means its defaults were in
            -- effect: tapping counts as a click, and tap-then-drag works.
            -- Hyprland defaults both to off, so they are set explicitly rather
            -- than silently lost in the move.
            tap_to_click  = true,
            tap_and_drag  = true,

            -- Two-finger scroll speed. Unlike the desktop's mouse sensitivity
            -- this is not derived from anything -- KDE exposes no equivalent
            -- number to carry over, and Hyprland's 1.0 scrolls a touchpad
            -- noticeably faster than Plasma did. This is a starting point and
            -- the only number here worth touching: raise it toward 1.0 if
            -- scrolling feels sluggish, lower it if a flick overshoots.
            scroll_factor = 0.6,
        },
    },
})

-- No hl.device block. There is only one touchpad, so the section above already
-- addresses it unambiguously. If a per-device setting is ever needed, the name
-- Hyprland knows it by is:
--
--   ven_06cb:00-06cb:cff9-touchpad
--
-- Confirm with `hyprctl devices` before relying on it.
