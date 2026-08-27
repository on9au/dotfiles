#!/bin/sh
# macOS key-repeat parity with hypr/input.lua.
#
# Linux sets repeat_rate = 40 and repeat_delay = 250 there; macOS has no
# equivalent config file, only NSGlobalDomain defaults, and it ships far
# slower values than either. This script is the macOS half of that setting.
#
# Units: both keys are counted in 15 ms ticks (one frame at 60 Hz), not
# milliseconds, so the Linux numbers do not transfer literally:
#
#   repeat_rate  40/sec = 25 ms between repeats -> 25/15 = 1.67 -> 2 (30 ms)
#   repeat_delay 250 ms                         -> 250/15 = 16.7 -> 17 (255 ms)
#
# 2 is also the fastest stop the System Settings slider offers; 17 sits
# between its stops, which is fine -- the slider only writes these same keys.
#
# ApplePressAndHoldEnabled is the third piece and the one that actually
# matters most here: left at its default, holding a key pops up the accent
# picker instead of repeating, so held hjkl in nvim/less does nothing.
#
# Takes effect for an app the next time that app launches, so log out and
# back in to get it everywhere.
#
# Guarded by .chezmoiignore -- see the `ne .chezmoi.os "darwin"` block there.

set -eu

command -v defaults >/dev/null 2>&1 || exit 0

defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 17
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

printf 'key repeat set (log out and back in to apply everywhere)\n'

exit 0
