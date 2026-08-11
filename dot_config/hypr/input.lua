-- Keyboard and mouse. This is a desktop, so there is no touchpad section.

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        -- 0 = use libinput's own acceleration untouched.
        sensitivity = 0,

        numlock_by_default = true,

        -- Snappier key repeat than the default 25/600.
        repeat_rate  = 40,
        repeat_delay = 250,
    },

    cursor = {
        -- Hide the pointer after 5s of no mouse movement.
        inactive_timeout = 5,
    },

    binds = {
        -- Pressing the current workspace's key again jumps back to the
        -- previous one.
        workspace_back_and_forth = true,
    },
})
