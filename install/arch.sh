#!/bin/sh
# Packages for an Arch machine -- bare metal (Hyprland) or WSL (shell only).
#
# Run from a real terminal, like system/*/install.sh:
#
#   sh install/arch.sh
#
# It calls sudo, and sudo needs a TTY to prompt on. Inside anything that is
# not one -- an editor's task runner, a CI step, an agent shell -- it fails
# with "a terminal is required to read the password" before installing
# anything. Not run under sudo itself: see require_not_root in lib.sh.
#
# Safe to re-run: every install is `--needed`, so an up-to-date machine is a
# no-op. Normally reached through install/bootstrap.sh rather than directly.
#
# The split mirrors .chezmoiignore exactly. WSL gets the shell half -- zsh,
# tmux, nvim and the tools they shell out to -- and none of the compositor
# half, because the desktop over there is Windows and nothing in the VM would
# ever read a Hyprland config. Bare metal gets both.

set -eu

. "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/lib.sh"

require_not_root
[ -f /etc/arch-release ] || die "this is the Arch script, and this is not Arch"

TARGET=$(dotfiles_target)
sudo_keepalive

# ---------------------------------------------------------------------------
# Shell half -- every Arch machine, WSL included.
#
# Grouped by what reads them, because the list is otherwise unreviewable.
# ---------------------------------------------------------------------------

# .zshrc, .zsh_plugins.txt, .tmux.conf. antidote is NOT here: the AUR package
# installs to /usr/share/antidote, and .zshrc looks for ~/.antidote or a
# Homebrew prefix -- so it is a git clone, in common.sh.
CORE="zsh starship tmux fzf"

# The things a shell is for.
CORE="$CORE git github-cli chezmoi openssh less man-db jq unzip"

# nvim. tree-sitter-cli is the CLI, not the library neovim already links --
# nvim-treesitter needs the former and :checkhealth fails without it. fzf,
# ripgrep, fd and lazygit back the fzf extra, grep pickers and Snacks.lazygit;
# sqlite is what plugins/java.lua probes for. unzip, above, is how Mason
# unpacks the LSP servers it downloads.
CORE="$CORE neovim tree-sitter-cli ripgrep fd lazygit sqlite"

# Compilers Mason and treesitter parsers need to build against, plus the AUR.
CORE="$CORE base-devel go python"

# wl-clipboard is not desktop-only despite the name: WSLg puts a Wayland
# socket in every WSL session, so wl-copy/wl-paste work there too and the
# clipboard stops depending on a win32yank.exe from a Windows-side install.
CORE="$CORE wl-clipboard"

step "installing shell packages"
# shellcheck disable=SC2086 -- word splitting is how the list becomes argv
sudo pacman -S --needed --noconfirm $CORE

# ---------------------------------------------------------------------------
# AUR
# ---------------------------------------------------------------------------

if ! have paru; then
    step "bootstrapping paru (not installed, and the AUR half needs it)"
    tmp=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
    # makepkg refuses to run as root, which is why nothing here is `sudo sh`.
    ( cd "$tmp/paru-bin" && makepkg -si --noconfirm )
    rm -rf "$tmp"
fi

# fnm rather than the `nodejs` package: nvim's LSPs and mmdc want a node the
# user can switch per project, and .zshrc already has the `fnm env` wiring.
# fnm-bin over fnm because the source package builds the whole Rust toolchain
# for a binary upstream already ships.
#
# .zshrc handles either install layout -- it PATH-prepends
# ~/.local/share/fnm (where the curl installer puts it, which is what the
# README's macOS/manual route uses) and then activates whatever `fnm` it can
# find on PATH, which is this one at /usr/bin/fnm.
step "installing AUR packages"
paru -S --needed --noconfirm fnm-bin

# ---------------------------------------------------------------------------
# Desktop half -- bare metal only.
# ---------------------------------------------------------------------------

if [ "$TARGET" = wsl ]; then
    step "WSL: skipping the compositor half"
    log "no Hyprland, waybar, fuzzel, portals or fonts -- the desktop here is"
    log "Windows, and .chezmoiignore keeps their configs out of \$HOME to match."
    log "Also skipped: imagemagick/ghostscript/tectonic. They exist to render"
    log "Snacks.image inline, which needs a terminal that speaks the kitty"
    log "graphics protocol; nothing on the Windows side of this VM does."
    exit 0
fi

step "installing the Hyprland desktop"

# Straight from the README's package list. hyprpolkitagent, cliphist and
# wtype are wired into hypr/autostart.lua and .local/bin; playerctl drives the
# media keys; pavucontrol/networkmanager/htop are what the waybar modules open
# on click; brightnessctl is the backlight keys and hypridle's dim-before-lock;
# power-profiles-daemon backs the waybar profile switcher and needs enabling
# separately (see below).
DESKTOP="hyprland uwsm xdg-desktop-portal-hyprland xdg-desktop-portal-kde
         plasma-integration fuzzel swaync hyprlock hypridle hyprpolkitagent
         awww hyprshot hyprpicker cliphist wl-clipboard wtype
         qt5-wayland qt6-wayland playerctl pavucontrol networkmanager
         brightnessctl power-profiles-daemon htop kdeconnect kitty"

# Icons. Without a nerd font, waybar and the tmux status line are tofu boxes;
# without noto-fonts-emoji the emoji picker lists them too.
DESKTOP="$DESKTOP ttf-firacode-nerd noto-fonts-emoji"

# Snacks.image's rendering chain: raster, PDF, LaTeX. kitty (above) is the
# terminal that can actually draw the result.
DESKTOP="$DESKTOP imagemagick ghostscript tectonic"

# The YubiKey FIDO2 SSH keys -- see "SSH agent and YubiKeys" in the README.
DESKTOP="$DESKTOP libfido2"

# shellcheck disable=SC2086
sudo pacman -S --needed --noconfirm $DESKTOP

# waybar from the AUR, not the repos: the release build cannot switch
# workspaces on click with a Lua config. bemoji is only in the AUR at all.
paru -S --needed --noconfirm waybar-git bemoji-git

step "desktop packages done -- the rest is not scriptable from here"
log "services:   sudo systemctl enable --now power-profiles-daemon"
log "greeter:    sudo sh system/greetd/install.sh   (then enable greetd.service)"
log "keyring:    sudo sh system/keyring/install.sh"
log "lid:        sudo sh system/logind/install.sh"
log "ssh agent:  systemctl --user enable --now ssh-agent.socket"
log "See the README -- each of those has a section explaining what it does."
