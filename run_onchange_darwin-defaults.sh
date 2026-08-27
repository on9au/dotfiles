#!/bin/sh
# macOS system defaults -- Dock, Finder, Mission Control, text input.
#
# Sibling of darwin-key-repeat.sh, and it exists for the same reason: macOS
# keeps this half of a setup in preference domains rather than in files
# chezmoi can manage, so the only way to version it is a script that writes
# the domains. Same guard in .chezmoiignore (`ne .chezmoi.os "darwin"`), same
# run_onchange_ prefix, so it re-runs only when its own contents change.
#
# `defaults write` lands in the domain immediately, but an app that is already
# running generally re-reads its domain on launch only -- hence the restarts
# at the bottom. Everything here is a documented preference key; there are no
# private APIs and nothing needs sudo.
#
# The Dock and Mission Control blocks are load-bearing for AeroSpace rather
# than taste, and say so where it matters.

set -eu

command -v defaults >/dev/null 2>&1 || exit 0

# ---------------------------------------------------------------------------
# Dock
#
# AeroSpace tiles inside NSScreen.visibleFrame, and a pinned Dock is
# subtracted from that frame exactly the way the menu bar strip is -- see the
# gaps.outer.top comment in aerospace.toml. Leaving it pinned donates a whole
# edge of every workspace to it permanently. Autohiding gives that back, and
# the two timing keys remove the reveal delay that otherwise makes an
# autohidden Dock feel broken rather than hidden.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15

# Launching is L-Opt+Return / L-Opt+E / L-Opt+B (aerospace.toml), so the Dock
# is not the launcher here and recents only churn what was just hidden.
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 40

# ---------------------------------------------------------------------------
# Mission Control / Spaces -- required by AeroSpace, not preference
#
# AeroSpace addresses workspaces by index. mru-spaces lets macOS reorder
# Spaces by recent use behind its back, which moves the ground underneath it.
defaults write com.apple.dock mru-spaces -bool false

# Stop macOS switching Space by itself when an app is activated. AeroSpace
# already does the switching; with both acting, focus lands twice and the
# second one wins unpredictably.
defaults write com.apple.dock workspaces-auto-swoosh -bool false

# Mission Control's "group windows by application". AeroSpace treats windows
# individually, so grouping makes its view and the OS's disagree.
defaults write com.apple.dock expose-group-apps -bool false

# Window animations are dead time in front of a WM that repositions windows on
# every focus change and every workspace switch.
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# SketchyBar draws its own bar in the strip the native menu bar occupies (see
# sketchybarrc's height/notch comment). Hiding the real one is what makes that
# a replacement rather than a second bar competing for the same 32pt.
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# ---------------------------------------------------------------------------
# Finder
#
# Hidden files shown: this is a dotfiles repo, the whole subject matter is
# files Finder hides by default.
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# List view, folders first -- closest thing Finder has to a file manager.
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search the folder you are in, not the whole Mac. SCcf = current folder.
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# New windows open at $HOME rather than Recents.
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"

# Renaming a file's extension is a normal operation, not one worth a modal.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Stop scattering .DS_Store across network shares and USB sticks, where they
# are someone else's problem. Does nothing about local ones.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ---------------------------------------------------------------------------
# Text input
#
# Every one of these actively corrupts code and prose about code: smart quotes
# break shell snippets, the dash substitution turns `--flag` into an en dash,
# and autocapitalise mangles identifiers. This is the same class of fix as
# ApplePressAndHoldEnabled in darwin-key-repeat.sh -- a macOS default that
# assumes prose and is wrong in a terminal-shaped life.
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# ---------------------------------------------------------------------------
# Screenshots
#
# Ctrl+Shift+3/4/5, not Cmd+Shift+3/4/5 -- the Karabiner Ctrl<->Cmd swap moves
# them. See the header comment in aerospace.toml.
#
# Out of $HOME/Desktop, which is otherwise where they pile up.
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ---------------------------------------------------------------------------
# Trackpad
#
# Tap to click. Two domains because the setting is per-device class and the
# machine may see either: AppleMultitouchTrackpad is the built-in one, the
# AppleBluetoothMultitouch variant is an external Magic Trackpad. Writing
# both means the preference survives plugging one in.
#
# tapBehavior is the same switch as read by the login window and by apps that
# ask NSGlobalDomain rather than the driver; -currentHost is where the login
# window looks, so it needs writing separately rather than inheriting.
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ---------------------------------------------------------------------------
# Appearance
#
# Dark, to match: every theme in this repo is Catppuccin Mocha -- hypr's
# colors.lua, kitty's current-theme.conf, ghostty's `theme =`, sketchybarrc's
# hex block, tmux and nvim. A light system chrome around all of that is the
# only surface left disagreeing.
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# ---------------------------------------------------------------------------
# Hot corners
#
# 0 = none, 2 = Mission Control, 3 = Application Windows, 4 = Desktop,
# 5 = Screen Saver, 10 = Display Sleep, 11 = Launchpad,
# 12 = Notification Center, 13 = Lock Screen, 14 = Quick Note.
#
# Most of what hot corners offer is already bound or meaningless here:
# Mission Control and Desktop are what AeroSpace's workspaces are for,
# Launchpad is what L-Opt+Return/E/B are for, and Lock Screen is already on
# L-Opt+Shift+Esc in aerospace.toml. So this is mostly about turning one OFF.
#
# macOS ships bottom-right = Quick Note (14) enabled by default, and this
# setup makes it worse than usual: focus-follows-mouse is on in
# aerospace.toml, so the pointer gets flung to whatever window took focus and
# reaches screen corners far more often than it would otherwise.
defaults write com.apple.dock wvous-br-corner -int 0
defaults write com.apple.dock wvous-br-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tl-modifier -int 0

# The one that earns its place. _HIHideMenuBar above hides the native menu
# bar, and SketchyBar's clock item has no click_script (see sketchybarrc), so
# "click the clock for Notification Centre" -- which aerospace.toml's header
# offers as the swaync replacement -- no longer has an obvious target. This
# gives it one. Misfiring costs a panel sliding out, which is the cheapest
# failure of anything on this list.
defaults write com.apple.dock wvous-tr-corner -int 12
defaults write com.apple.dock wvous-tr-modifier -int 0

# ---------------------------------------------------------------------------
# Dialogs
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# ---------------------------------------------------------------------------
# Restart what reads the domains above.
#
# Finder and Dock re-read on launch only. SystemUIServer owns the menu bar
# extras affected by _HIHideMenuBar. Killing them is the documented way to
# apply this and costs open Finder windows, nothing else.
for _app in Dock Finder SystemUIServer; do
  killall "$_app" >/dev/null 2>&1 || true
done
unset _app

printf 'macOS defaults written (Dock, Finder, Spaces, trackpad, appearance,\nhot corners, text input, screenshots) -- log out for the trackpad and\nappearance keys to reach apps that were already running\n'

exit 0
