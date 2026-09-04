#!/bin/sh
# The half of the install that is not a package: things that live in $HOME and
# are fetched the same way on every OS.
#
#   sh install/common.sh
#
# Safe to re-run: every step checks for what it is about to create first.
# Normally reached through install/bootstrap.sh, after the per-OS package
# script -- it needs git, zsh, tmux, fnm and nvim to already be there.

set -eu

. "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/lib.sh"

require_not_root
TARGET=$(dotfiles_target)

# ---------------------------------------------------------------------------
# antidote
#
# .zshrc looks in exactly two places: ~/.antidote/antidote.zsh, and
# $HOMEBREW_PREFIX/share/antidote/antidote.zsh. On macOS the formula covers
# the second, so there is nothing to do. On Linux it has to be the clone --
# the AUR package installs to /usr/share/antidote, which .zshrc does not look
# at, so `paru -S antidote` would install a plugin manager that never loads.
# ---------------------------------------------------------------------------

if [ "$TARGET" = darwin ]; then
    step "antidote: provided by Homebrew, nothing to clone"
elif [ -d "$HOME/.antidote" ]; then
    step "antidote: already at ~/.antidote"
else
    step "cloning antidote"
    git clone --depth 1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
fi

# .zshrc puts this at the front of $fpath before compinit runs. zsh tolerates
# a missing fpath entry, so this is only so there is somewhere obvious to drop
# a hand-written completion.
mkdir -p "$HOME/.zsh/completion"

# ---------------------------------------------------------------------------
# tmux plugins
#
# .tmux.conf ends with `run '~/.tmux/plugins/tpm/tpm'`, and every `set -g
# @plugin` above it is inert until tpm is there to read it -- an un-bootstrapped
# tmux comes up with the default green status bar and no catppuccin, no
# resurrect, no vim-tmux-navigator (so C-h/j/k/l stop crossing the nvim/tmux
# boundary).
# ---------------------------------------------------------------------------

TPM="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM" ]; then
    step "tpm: already at ~/.tmux/plugins/tpm"
else
    step "cloning tpm"
    git clone --depth 1 https://github.com/tmux-plugins/tpm.git "$TPM"
fi

if have tmux; then
    step "installing tmux plugins"
    # Starts its own throwaway server, so this works with no session attached.
    "$TPM/bin/install_plugins" >/dev/null || warn "tpm install_plugins failed -- run it by hand"
else
    warn "tmux not installed, skipping plugin install"
fi

# ---------------------------------------------------------------------------
# node
#
# nvim's LSPs (Mason downloads a lot of node ones) and mmdc below. Via fnm
# rather than a system node so the version is switchable per project, which is
# what the `fnm env` block in .zshrc is for.
# ---------------------------------------------------------------------------

# The curl installer puts fnm in ~/.local/share/fnm and expects that dir on
# PATH; the pacman/brew packages put it on PATH already. Same two-case handling
# as .zshrc, because this script does not run under .zshrc.
[ -d "$HOME/.local/share/fnm" ] && PATH="$HOME/.local/share/fnm:$PATH"

if have fnm; then
    eval "$(fnm env --shell bash)"
    if fnm list 2>/dev/null | grep -q lts-latest; then
        step "node: an LTS is already installed"
    else
        step "installing node LTS"
        # Not fatal: a second run where `fnm list` did not report the alias in
        # the shape this grep expects should not abort the whole bootstrap
        # before the nvim step below.
        fnm install --lts || warn "fnm install --lts failed"
    fi
    # Without a default, a fresh shell activates nothing and `node` is missing
    # again -- or, on WSL, resolves to the Windows node that /mnt/c puts on
    # PATH, which cannot run Linux native modules.
    fnm default lts-latest >/dev/null 2>&1 || warn "could not set the default node version"
else
    warn "fnm not installed, skipping node"
fi

# ---------------------------------------------------------------------------
# mermaid-cli
#
# plugins/diagrams.lua shells out to `mmdc` to turn a diagram into a PNG and
# hands the PNG to image.nvim, which draws it with the kitty graphics
# protocol. WSL has no terminal that speaks that protocol -- the terminal is on
# the Windows side -- so the whole chain is skipped there, the same way
# arch.sh skips imagemagick/ghostscript/tectonic.
# ---------------------------------------------------------------------------

if [ "$TARGET" = wsl ]; then
    step "mermaid-cli: skipped on WSL (no kitty graphics protocol to draw into)"
elif ! have npm; then
    warn "npm not found, skipping mermaid-cli"
elif have mmdc; then
    step "mermaid-cli: already installed"
else
    step "installing mermaid-cli"
    # npm will warn that it blocked puppeteer's postinstall script. That
    # usually does not break mmdc -- puppeteer falls back to a Chrome already
    # on the machine. Check rather than assume:
    #   printf 'graph TD\n  A-->B\n' > /tmp/t.mmd && mmdc -i /tmp/t.mmd -o /tmp/t.png
    # If it does fail: npm i -g --allow-scripts=puppeteer @mermaid-js/mermaid-cli
    npm i -g @mermaid-js/mermaid-cli || warn "mermaid-cli install failed"
fi

# ---------------------------------------------------------------------------
# neovim
#
# LazyVim bootstraps itself on first launch anyway; doing it here means the
# first real launch is not a five-minute progress bar, and any plugin that
# fails to build says so now, in this log, rather than inside a UI.
#
# `restore`, not `sync`. lazy-lock.json is committed to this repo, so it is a
# chezmoi-managed file that nvim also writes -- and `sync` updates every
# plugin to its latest commit and rewrites the lock, which means the next
# `chezmoi apply` stops with "lazy-lock.json has changed since chezmoi last
# wrote it?" and a bootstrap leaves the tree dirty. `restore` installs what is
# missing and checks out exactly the pinned commits, so a fresh machine ends
# up on the same plugin versions as every other one, which is the entire
# reason to commit a lockfile.
#
# To move the pins deliberately: `:Lazy update` in nvim, then `chezmoi re-add
# ~/.config/nvim/lazy-lock.json` and commit.
# ---------------------------------------------------------------------------

if have nvim && [ -f "$HOME/.config/nvim/init.lua" ]; then
    step "restoring neovim plugins at their pinned commits (slow on a fresh machine)"
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || warn "nvim plugin restore had errors -- open nvim and check :Lazy"
else
    log "nvim config not applied yet; plugins will bootstrap on first launch"
fi

# ---------------------------------------------------------------------------
# login shell
# ---------------------------------------------------------------------------

ZSH_BIN=$(command -v zsh || true)

# The passwd entry, not $SHELL. $SHELL is inherited from whatever started this
# process and says nothing about what the account is actually set to -- run
# the bootstrap from a bash subshell and it reads /bin/bash, prompting for a
# chsh you already did. getent is Linux-only; $SHELL is the fallback on macOS.
LOGIN_SHELL=$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)
[ -n "$LOGIN_SHELL" ] || LOGIN_SHELL=${SHELL:-}

case "$LOGIN_SHELL" in
    */zsh) ;;
    *)
        if [ -n "$ZSH_BIN" ]; then
            step "setting zsh as the login shell"
            # Needs the account password, and fails if zsh is not in
            # /etc/shells (a Homebrew zsh on macOS, typically). Not worth
            # dying over -- everything else here still works.
            chsh -s "$ZSH_BIN" || warn "chsh failed; add $ZSH_BIN to /etc/shells and re-run 'chsh -s $ZSH_BIN'"
        fi
        ;;
esac

step "done"
