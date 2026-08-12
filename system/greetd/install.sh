#!/bin/sh
# Stage greetd + ReGreet. Run with sudo from a real terminal:
#
#   sudo sh ~/.local/share/chezmoi/system/greetd/install.sh
#
# This installs packages, copies the assets the greeter needs and drops the
# configs into /etc. It deliberately does NOT enable greetd or disable sddm --
# that switch is a separate, verified step, so a mistake here cannot leave you
# without a way to log in.

set -eu

# The user whose wallpaper/themes get copied. $SUDO_USER is who invoked sudo.
USER_NAME=${SUDO_USER:-djpro}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
REPO="$USER_HOME/.local/share/chezmoi/system/greetd"

echo "==> installing packages"
# cage is no longer used (it cannot describe monitors, so the greeter spanned
# both 4K panels); Hyprland hosts the greeter instead and is already installed.
pacman -S --needed --noconfirm greetd greetd-regreet

# The greeter runs as the unprivileged `greeter` user and cannot read
# $USER_HOME (mode 700), so everything it references is copied somewhere
# world-readable.
echo "==> copying assets the greeter can read"
install -Dm644 "$USER_HOME/Pictures/Wallpapers/wallhaven-je8p85.jpg" \
    /usr/share/backgrounds/regreet-wallpaper.jpg

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
install -Dm644 "$REPO/hyprland.conf" /etc/greetd/hyprland.conf

# Sanity-check the greeter compositor config before it becomes the only way in.
if ! Hyprland --verify-config -c /etc/greetd/hyprland.conf 2>&1 | grep -q 'config ok'; then
    echo "ERROR: /etc/greetd/hyprland.conf failed to parse -- not switching." >&2
    exit 1
fi

echo
echo "STAGED-OK -- nothing switched over yet."
echo "sddm is still your login manager. Verify, then switch with:"
echo "  sudo systemctl disable sddm.service"
echo "  sudo systemctl enable greetd.service"
