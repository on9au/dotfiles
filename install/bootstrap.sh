#!/bin/sh
# Take a fresh machine from "this repo is cloned" to "everything works".
#
# Run from a real terminal -- the package step calls sudo, which needs a TTY
# to prompt on:
#
#   sh install/bootstrap.sh
#
# Three steps, in this order and for this reason:
#
#   1. packages   -- the per-OS script below. Installs chezmoi itself, among
#                    other things, which is why it cannot come second.
#   2. apply      -- writes the configs into $HOME.
#   3. common.sh  -- the $HOME half: antidote, tpm, node, nvim plugins. Comes
#                    last because it reads the files step 2 wrote (tpm needs
#                    ~/.tmux.conf's @plugin lines, LazyVim needs
#                    ~/.config/nvim).
#
# Safe to re-run from any state; every step is idempotent. Each of the three
# is also runnable on its own if only one of them needs redoing.
#
# Not covered, by design: everything under system/. Those write to /etc, want
# root, and each has consequences worth reading about first (a broken
# /etc/greetd locks you out of the machine). arch.sh prints the list at the
# end; the README explains each one.

set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lib.sh"

ROOT=$(dotfiles_root "$0")
TARGET=$(dotfiles_target)

require_not_root

step "bootstrapping $ROOT"
log "target: $TARGET"

case "$TARGET" in
    darwin) sh "$HERE/macos.sh" ;;
    linux|wsl)
        [ -f /etc/arch-release ] || die "only Arch is scripted here; install the equivalents of install/arch.sh by hand, then run install/common.sh"
        sh "$HERE/arch.sh"
        ;;
    *) die "unsupported: $(uname -s)" ;;
esac

# ---------------------------------------------------------------------------
# Apply
#
# --source pins it to the tree this script was run from, so a clone in an
# unusual place still applies itself rather than whatever chezmoi's configured
# source directory happens to hold.
# ---------------------------------------------------------------------------

step "applying the dotfiles"
have chezmoi || die "chezmoi still not on PATH after the package step"

configured=$(chezmoi source-path 2>/dev/null || true)
if [ -n "$configured" ] && [ "$configured" != "$ROOT" ]; then
    warn "chezmoi's source directory is $configured, not $ROOT"
    warn "applying from $ROOT this once -- later 'chezmoi apply' calls will use"
    warn "the other tree unless you re-init:"
    warn "  chezmoi init --branch hyprland <url>"
fi

chezmoi apply --source "$ROOT"

sh "$HERE/common.sh"

step "bootstrap finished"
log "start a new login shell to pick it all up."
