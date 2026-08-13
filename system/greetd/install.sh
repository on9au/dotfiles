#!/bin/sh
# Stage greetd + ReGreet. Run with sudo from a real terminal:
#
#   sudo sh ~/.local/share/chezmoi/system/greetd/install.sh
#
# This installs packages, copies the assets the greeter needs and drops the
# configs into /etc. It deliberately does NOT enable greetd or disable the
# current display manager -- that switch is a separate, verified step, so a
# mistake here cannot leave you without a way to log in.
#
# Optionally takes the wallpaper path as its first argument, for a machine not
# listed below:
#
#   sudo sh install.sh ~/Pictures/Wallpapers/something.jpg

set -eu

# The user whose wallpaper/themes get copied. $SUDO_USER is who invoked sudo.
USER_NAME=${SUDO_USER:-djpro}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
REPO="$USER_HOME/.local/share/chezmoi/system/greetd"

# Which wallpaper this machine uses. Same split as hypr/host.lua, and the same
# reason: the laptop panel is 16:10 and the desktop's screens are 16:9, so one
# image cannot serve both without cropping. Keep these paths in step with
# hypr/hosts/<host>/apps.lua, which is what the session itself reads.
if [ "${1:-}" ]; then
    WALLPAPER=$1
elif [ "$(hostname)" = "LAPTOP-ON9AU" ]; then
    WALLPAPER="$USER_HOME/Pictures/Wallpapers/wallpaper-3840x2400.png"
else
    WALLPAPER="$USER_HOME/Pictures/Wallpapers/wallhaven-je8p85.jpg"
fi

echo "==> installing packages"
# cage is no longer used (it cannot describe monitors, so the greeter spanned
# both 4K panels); Hyprland hosts the greeter instead and is already installed.
pacman -S --needed --noconfirm greetd greetd-regreet

# The greeter runs as the unprivileged `greeter` user and cannot read
# $USER_HOME (mode 700), so everything it references is copied somewhere
# world-readable.
echo "==> copying assets the greeter can read"
# Checked explicitly so a missing file says which file, rather than failing as
# a bare `install: cannot stat` two thirds of the way through the script.
if [ ! -r "$WALLPAPER" ]; then
    echo "ERROR: wallpaper not found: $WALLPAPER" >&2
    echo "       Put an image there (the laptop panel wants 3840x2400), or" >&2
    echo "       pass a path: sudo sh install.sh /path/to/image.jpg" >&2
    exit 1
fi
# The destination has no extension on purpose. regreet.toml can only name one
# path, but the two machines' wallpapers are different formats (the laptop's is
# a PNG, the desktop's a JPEG). ReGreet loads it through GdkPixbuf, which
# detects the format from the file's contents and ignores the name, so one
# extensionless path serves both -- and beats copying a PNG to a .jpg name.
install -Dm644 "$WALLPAPER" /usr/share/backgrounds/regreet-wallpaper

for theme in "$USER_HOME/.icons/Posy_Cursor_Black" \
    "$USER_HOME/.local/share/icons/YAMIS"; do
    [ -d "$theme" ] || continue
    dest="/usr/share/icons/$(basename "$theme")"
    rm -rf "$dest"
    cp -r "$theme" "$dest"
    chmod -R a+rX "$dest"
done

echo "==> installing configs"
install -Dm644 "$REPO/config.toml" /etc/greetd/config.toml
install -Dm644 "$REPO/regreet.toml" /etc/greetd/regreet.toml
install -Dm644 "$REPO/hyprland.lua" /etc/greetd/hyprland.lua

# Stale hyprlang greeter config from before the switch to Lua; leaving it would
# just be a confusing second config that nothing reads.
rm -f /etc/greetd/hyprland.conf

# Sanity-check the greeter compositor config before it becomes the only way in.
#
# Run as $USER_NAME, not root: Hyprland refuses to start for the root user
# (that is what its --i-am-really-stupid flag exists to bypass), so checking it
# under sudo always "fails" regardless of the config. The file is world
# readable, so an unprivileged check is fine.
if [ "$(id -u)" -eq 0 ] && command -v runuser >/dev/null 2>&1; then
    # normal case: script was run with sudo, drop to the user to check
    verify_cmd="runuser -u $USER_NAME -- "
else
    # already unprivileged (script run without sudo, e.g. re-checking by hand)
    verify_cmd=""
fi

if ! $verify_cmd Hyprland --verify-config -c /etc/greetd/hyprland.lua 2>&1 |
    grep -q 'config ok'; then
    echo "ERROR: /etc/greetd/hyprland.lua failed to parse -- not switching." >&2
    exit 1
fi

echo "==> greeter compositor config parses"

echo
# Report what is actually true rather than assuming a first-time install --
# re-runs happen far more often than the initial one, and claiming "sddm is
# still your login manager" after the switch is worse than saying nothing.
#
# The display manager is whatever display-manager.service points at. Do NOT
# hardcode a name here: this repo said `sddm` for a long time while the machine
# was actually running plasmalogin, so the documented "disable sddm" command
# silently did nothing.
CURRENT_DM=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null || true)

if [ "$(systemctl is-enabled greetd.service 2>/dev/null)" = "enabled" ]; then
    echo "STAGED-OK -- greetd is already your login manager."
    echo "Log out to pick up the new greeter config."
elif [ -n "$CURRENT_DM" ] && [ "$CURRENT_DM" != "." ]; then
    echo "STAGED-OK -- nothing switched over yet."
    echo "$CURRENT_DM is still your login manager. Verify, then switch with:"
    echo "  sudo systemctl disable $CURRENT_DM"
    echo "  sudo systemctl enable greetd.service"
else
    echo "STAGED-OK -- nothing switched over yet."
    echo "No display manager is enabled. Switch on the greeter with:"
    echo "  sudo systemctl enable greetd.service"
fi
