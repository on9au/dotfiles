#!/bin/sh
# Reload Hyprland after `chezmoi apply`.
#
# Why this exists: chezmoi writes files in alphabetical order, so
# hyprland.lua lands before monitors.lua / rules.lua / looknfeel.lua. Hyprland
# watches its config and auto-reloads the moment hyprland.lua changes -- in
# that gap the modules it requires do not exist yet, and the session comes up
# with "module 'monitors' not found" until something reloads it again.
#
# Reloading once, after apply has finished writing everything, settles it.
# Harmless when Hyprland is not running (KDE session, SSH, fresh install).

set -eu

# Not inside a Hyprland session -> nothing to do.
[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || exit 0
command -v hyprctl >/dev/null 2>&1 || exit 0

hyprctl reload >/dev/null 2>&1 || true

# Surface any config errors instead of letting them sit until next login.
errors=$(hyprctl configerrors 2>/dev/null || true)
if [ -n "$errors" ]; then
    printf 'hyprland config errors after reload:\n%s\n' "$errors" >&2
fi

exit 0
