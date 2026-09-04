#!/bin/sh
# Packages for the MacBook.
#
#   sh install/macos.sh
#
# Safe to re-run: brew install on an already-installed formula is a no-op with
# a warning. Normally reached through install/bootstrap.sh.
#
# This is the README's "Bring-up" section made executable. None of it is a
# literal port of the Linux half -- there is no Wayland here -- it is the
# closest analog stack macOS has: AeroSpace for Hyprland, SketchyBar for
# waybar, JankyBorders for looknfeel.lua's borders, Ghostty for kitty.

set -eu

. "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/lib.sh"

require_not_root
[ "$(dotfiles_target)" = darwin ] || die "this is the macOS script, and this is not macOS"

have brew || die "install Homebrew first: https://brew.sh"

# sketchybar and borders, and aerospace, live in third-party taps.
step "tapping"
brew tap FelixKratz/formulae
brew tap nikitabobko/tap

# Homebrew 6 refuses to load a third-party formula until its tap is trusted.
# Without this the install aborts with "Refusing to load formula ... from
# untrusted tap" and nothing in the whole command gets installed.
# Tolerated rather than fatal: `brew trust` only exists from Homebrew 6, and
# on an older brew there is nothing to trust in the first place. If the
# install below is the version that refuses, the message says so plainly.
brew trust felixkratz/formulae || warn "brew trust failed -- older Homebrew? upgrade it if the install is refused"
brew trust nikitabobko/tap || warn "brew trust failed -- older Homebrew? upgrade it if the install is refused"

step "installing formulae"
# antidote is a formula here rather than the git clone Linux uses; it lands in
# $HOMEBREW_PREFIX/share/antidote, which is the second branch .zshrc checks.
#
# tree-sitter-cli is the CLI, not the tree-sitter library neovim pulls in as a
# dependency -- nvim-treesitter needs the former and :checkhealth fails
# without it. imagemagick/ghostscript/tectonic are Snacks.image's rendering
# chain (raster, PDF, LaTeX); lazygit backs Snacks.lazygit; libfido2 is the
# YubiKey FIDO2 SSH keys.
brew install \
  chezmoi antidote starship tmux gh go fnm \
  neovim tree-sitter-cli ripgrep fd fzf lazygit \
  openssh libfido2 \
  imagemagick ghostscript tectonic \
  sketchybar borders

step "installing casks"
brew install --cask \
  ghostty aerospace karabiner-elements font-fira-code-nerd-font raycast orion

step "starting the bar and the borders"
brew services start sketchybar
brew services start borders

step "formulae done -- the rest cannot be scripted"
log "Raycast needs three things set by hand, none of them in a plist:"
log "  1. hotkey: press physical Command+Space into its recorder"
log "  2. disable its Window Management extension -- it fights AeroSpace"
log "  3. grant Accessibility when it asks (separate from AeroSpace's grant)"
log "AeroSpace and Karabiner each want Accessibility/Input Monitoring too."
log 'See "Permissions that cannot be scripted" in the README.'
