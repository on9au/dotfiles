#!/bin/sh
# Install the lid-switch drop-in. Run with sudo from a real terminal:
#
#   sudo sh ~/.local/share/chezmoi/system/logind/install.sh
#
# /etc is outside chezmoi's reach, so lid.conf beside this script is the source
# of truth and this copies it into place. Safe to re-run.

set -eu

USER_NAME=${SUDO_USER:-djpro}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
REPO="$USER_HOME/.local/share/chezmoi/system/logind"

if [ ! -r "$REPO/lid.conf" ]; then
    echo "ERROR: $REPO/lid.conf not found" >&2
    exit 1
fi

echo "==> installing /etc/systemd/logind.conf.d/99-lid.conf"
install -Dm644 "$REPO/lid.conf" /etc/systemd/logind.conf.d/99-lid.conf

# Reloading logind is enough; it re-reads its config without dropping sessions.
# NOT `systemctl restart systemd-logind` -- that has historically taken the
# graphical session with it.
echo "==> reloading systemd-logind"
systemctl kill -s HUP systemd-logind

echo
echo "==> in effect now:"
# Reads back what logind actually resolved, rather than echoing the file we
# just wrote -- another drop-in sorting after 99- would win and this is how you
# would find out.
for k in HandleLidSwitch HandleLidSwitchExternalPower HandleLidSwitchDocked; do
    printf '    %-30s %s\n' "$k" \
        "$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
            org.freedesktop.login1.Manager "$k" 2>/dev/null |
            awk '{print $2}' | tr -d '"' || echo '?')"
done

echo
echo "Clamshell is the other half of this -- the panel is turned off by"
echo "hypr/hosts/LAPTOP-ON9AU/binds.lua, not by logind. Check the switch is"
echo "named what that file expects:"
echo "  hyprctl devices | grep -i switch"
