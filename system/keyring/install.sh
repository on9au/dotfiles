#!/bin/sh
# Stage gnome-keyring as this machine's Secret Service. Run with sudo from a
# real terminal:
#
#   sudo sh ~/.local/share/chezmoi/system/keyring/install.sh
#
# Nothing owned org.freedesktop.secrets before this: gnome-keyring was never
# installed, and the kwallet left over from the KDE days only ever offered
# org.kde.secretservicecompat, which is a different bus name. Anything asking
# the freedesktop Secret Service for a password -- Chromium, Brave, Electron
# apps, git-credential-libsecret -- got
#
#   GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown:
#   The name is not activatable
#
# and either fell back to storing secrets in plaintext or just failed.
#
# Safe to re-run: the PAM edits are idempotent and skip files that already
# reference pam_gnome_keyring.

set -eu

USER_NAME=${SUDO_USER:-djpro}

echo "==> installing packages"
# gnome-keyring provides the daemon, pam_gnome_keyring.so and the Secret
# Service implementation. libsecret (the client library, and the
# git-credential-libsecret helper git ships in /usr/lib/git-core) is already
# pulled in by half the desktop, but name it so this works on a fresh box.
pacman -S --needed --noconfirm gnome-keyring libsecret

# The keyring has to be unlocked with a password, and the only password the
# user types at login is the one PAM already has in hand. So the unlock is done
# by pam_gnome_keyring rather than by a systemd user unit: a unit can start the
# daemon, but it cannot unlock it without prompting again.
#
# Which PAM file gets the lines is the whole trick here. The usual Arch
# instructions patch /etc/pam.d/sddm or /etc/pam.d/gdm; this machine has
# neither -- greetd authenticates through /etc/pam.d/greetd, and that file's
# `auth include system-local-login` is where the password actually arrives.
#
# `-` prefixes the module so PAM stays quiet (rather than logging a failure on
# every login) if gnome-keyring is ever uninstalled. `optional` means a keyring
# that refuses to unlock can never lock you out of the machine.
patch_pam() {
    file=$1
    shift
    if [ ! -f "$file" ]; then
        echo "    $file does not exist, skipping"
        return
    fi
    if grep -q pam_gnome_keyring "$file"; then
        echo "    $file already references pam_gnome_keyring, leaving it alone"
        return
    fi
    cp -a "$file" "$file.bak-keyring"
    printf '%s\n' "$@" >>"$file"
    echo "    patched $file (original saved as $file.bak-keyring)"
}

echo "==> wiring PAM"
# auto_start starts the daemon inside the session greetd is about to launch, so
# it lands on the user's own D-Bus (dbus-broker at $XDG_RUNTIME_DIR/bus, which
# pam_systemd has already set up by the time these session lines run).
#
# The greeter itself runs as the `greeter` user through this same PAM service,
# so it gets a keyring daemon too. That is harmless -- it is a throwaway
# session with no keyring file -- but it is why you may see a second
# gnome-keyring-daemon under that user.
patch_pam /etc/pam.d/greetd \
    '' \
    '# Unlock the GNOME keyring with the login password. See' \
    '# ~/.local/share/chezmoi/system/keyring/install.sh in the dotfiles repo.' \
    '-auth      optional   pam_gnome_keyring.so' \
    '-session   optional   pam_gnome_keyring.so auto_start'

# Without this, changing the login password with passwd(1) leaves the keyring
# still encrypted under the old one, and the next login cannot auto-unlock it:
# you get a "Unlock Login Keyring" dialog asking for a password you have
# already replaced. use_authtok tells the module to re-key with the password
# PAM just accepted instead of prompting for its own.
patch_pam /etc/pam.d/passwd \
    '' \
    '# Re-key the GNOME keyring when the login password changes.' \
    '-password  optional   pam_gnome_keyring.so use_authtok'

echo
echo "STAGED-OK -- nothing is running yet."
echo "The keyring is created and unlocked by PAM at login, so:"
echo "  1. log out and back in (a full session, not just hyprlock)"
echo "  2. check it took:  busctl --user list | grep secrets"
echo "  3. git and ssh wiring is per-user, run as $USER_NAME:"
echo "       git config --global credential.helper libsecret"
echo "       systemctl --user enable --now gcr-ssh-agent.socket"
