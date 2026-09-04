# Shared helpers for the scripts in this directory. Sourced, never run:
#
#   . "$(dirname "$0")/lib.sh"
#
# POSIX sh, like system/*/install.sh -- these run on a machine that may not
# have zsh yet (installing it is the point), and on macOS, whose /bin/bash is
# still 3.2.

# ---------------------------------------------------------------------------
# Output
#
# Two levels, so a long install reads as a list of steps rather than a wall of
# package-manager output. Everything goes to stderr, leaving stdout free for
# the handful of helpers below that return a value.
# ---------------------------------------------------------------------------

step() { printf '\n==> %s\n' "$*" >&2; }
log()  { printf '    %s\n' "$*" >&2; }
warn() { printf '    WARNING: %s\n' "$*" >&2; }
die()  { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Which machine is this
#
# The same three-way split .chezmoiignore makes, by the same test: WSL is
# detected on the kernel release string rather than a hostname, so it holds
# for any distro under any WSL install. Keep the two in sync -- if this says
# `wsl` and .chezmoiignore's `contains "microsoft"` disagrees, the install
# and the config land on different sides of the same fence.
#
# Windows itself is not a target here: the GlazeWM half is applied by a
# chezmoi running under Windows, which never executes these scripts.
# ---------------------------------------------------------------------------

dotfiles_target() {
    case "$(uname -s)" in
        Darwin) echo darwin ;;
        Linux)
            if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
                echo wsl
            else
                echo linux
            fi
            ;;
        *) echo unknown ;;
    esac
}

# Absolute path to the root of this source tree (the parent of install/).
# Resolved from $0 rather than assuming ~/.local/share/chezmoi, so the scripts
# work from a clone anywhere -- including before chezmoi is installed at all.
dotfiles_root() {
    CDPATH= cd -- "$(dirname -- "$1")/.." && pwd
}

# ---------------------------------------------------------------------------
# Privilege
#
# The scripts install packages, so they need root -- but they must NOT be run
# as root outright: everything in common.sh writes into $HOME (~/.antidote,
# ~/.tmux/plugins, fnm's node), and a root-owned ~/.antidote is worse than a
# missing one. So they run as the user and reach for sudo per command.
# ---------------------------------------------------------------------------

require_not_root() {
    [ "$(id -u)" -eq 0 ] && die "run this as your normal user, not root -- it calls sudo where it needs to"
    return 0
}

# Warm the sudo timestamp up front, so the password prompt happens now rather
# than fifteen minutes into a package build.
sudo_keepalive() {
    have sudo || die "sudo not found"
    log "asking for sudo up front, so the install can run unattended"
    sudo -v || die "sudo failed"
}
