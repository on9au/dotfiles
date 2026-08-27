# Karabiner-Elements

Exists for exactly one rule: **Caps Lock is the hyper key.** It's what gives
AeroSpace the single-key mod that `SUPER` already is on Linux -- see
`../aerospace/aerospace.toml` for the binds and `../hypr/binds.lua` for the
Hyprland original they're ported from. `karabiner.json` is JSON and can't hold
comments, hence this file.

## Why not just use a real modifier

There is no free single modifier on a Mac. `cmd` is claimed system-wide, and
bare `alt` is claimed by macOS as a *text* modifier (Option+arrows move by
word, Option+letter types dead keys and symbols) -- a global grab on it breaks
typing everywhere, which is what this setup originally did and why it moved.
Caps Lock is the only key on the board macOS assigns nothing important to.

## Why hyper is ctrl+opt+cmd and not ctrl+opt+cmd+shift

The usual "hyper" recipe folds `shift` in too. That would be wrong here: the
Hyprland binds this mirrors use `SUPER` for focus and `SUPER+SHIFT` for move,
so `shift` has to stay free to act as the second half of the pair. Held Caps
Lock therefore sends three modifiers, not four, and `Caps+shift+h` cleanly
reaches AeroSpace's `ctrl-alt-cmd-shift-h`.

`ctrl+opt+cmd` is unclaimed on macOS. The near misses all drop one of the
three: Ctrl+Cmd+Space (emoji), Ctrl+Cmd+F (fullscreen), Cmd+Opt+Esc (force
quit). VoiceOver's VO key is Ctrl+Opt, but only while VoiceOver is running.

## Tap vs hold

Tapped alone, Caps Lock sends **Escape** -- the standard arrangement for a
vim/nvim setup, and this repo is one (`../nvim`, plus `mode-keys vi` in
`~/.tmux.conf`). The trade is that you lose Caps Lock as Caps Lock. To get it
back, change `to_if_alone` in `karabiner.json` from `escape` to `caps_lock`;
to make hold-only, delete the `to_if_alone` block entirely.

`basic.to_if_alone_timeout_milliseconds` (200) is the cutoff between the two:
press and release inside 200 ms and it's Escape, hold longer and it's hyper.

## The binds work without Karabiner

Nothing in `aerospace.toml` depends on this file. The binds are plain
`ctrl-alt-cmd-*`, so physically holding Control+Option+Command reaches all of
them whether Karabiner is running or not. Caps Lock is a convenience alias for
that chord, not a prerequisite -- so a machine without Karabiner, or one where
the driver extension hasn't been approved yet, still has a working WM.

## Setup that can't be scripted

`chezmoi apply` writes this config, but Karabiner itself needs a one-time
manual install -- it ships a DriverKit system extension, so it needs an admin
password and two approvals in System Settings that no script can grant:

    brew install --cask karabiner-elements

Then approve the driver extension (System Settings > General > Login Items &
Extensions > Driver Extensions) and grant Input Monitoring to
`Karabiner-Elements` and `karabiner_grabber` when prompted.

## Drift

Karabiner's Settings GUI rewrites `karabiner.json` on save, normalising and
padding it with every default key. Edit the file here and `chezmoi apply`
rather than using the GUI; if the GUI does rewrite it, `chezmoi diff` will
show the churn. This is the same problem `.chezmoiignore` documents for
`kwinrc`, but not bad enough to give up managing the file -- Karabiner
reloads live on file change, so editing it directly works fine.
