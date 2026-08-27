# dotfiles

its *my* dotfiels

managed with chezmoi :3

One source tree, four targets. `.chezmoiignore` decides which half of it lands
where — the compositor configs and the shell configs are kept apart there, per
OS, with WSL detected on the kernel release string rather than a hostname.

| target | window manager | notes |
| --- | --- | --- |
| Arch desktop + laptop | Hyprland | the main setup — [below](#hyprland-specific) |
| MacBook Pro | AeroSpace | [macOS specific](#macos-specific) |
| Windows work laptop (`G3JC7G4`) | GlazeWM | `.glzr`, undocumented so far |
| WSL | none | shell half only: zsh, tmux, nvim |

**Everything lives on the `hyprland` branch, not `main`.** `main` is far
behind and has no macOS or Windows support at all, so clone with
`chezmoi init --branch hyprland …`.

## Machine notes

`docs/` holds write-ups of hardware and OS problems that took real work to pin
down — prose rather than config, so it is in `.chezmoiignore` alongside
`system/`.

| doc | about |
| --- | --- |
| [`LAPTOP-ON9AU-nvme-vmd-stalls.md`](docs/LAPTOP-ON9AU-nvme-vmd-stalls.md) | the ~30s whole-machine freezes on the laptop: an Intel VMD erratum losing NVMe interrupts. No kernel fix exists or is planned, so **upgrading will not clear it** |

## Hyprland specific

current packages used are:

```bash
sudo pacman -S hyprland uwsm xdg-desktop-portal-hyprland xdg-desktop-portal-kde plasma-integration fuzzel swaync hyprlock hypridle hyprpolkitagent awww hyprshot hyprpicker cliphist wl-clipboard wtype noto-fonts-emoji qt5-wayland qt6-wayland playerctl pavucontrol networkmanager brightnessctl power-profiles-daemon htop

# waybar from the AUR, not the repos -- see "The Lua config gotcha" below.
# The release build cannot switch workspaces on click with a Lua config.
#
# bemoji is the emoji picker -- see "Emoji picker" below. Only in the AUR.
paru -S waybar-git bemoji-git
```

`playerctl` drives the media keys, `pavucontrol` and `networkmanager` (nmtui)
are what the waybar audio/network modules open on click, and `htop` is what the
cpu/memory modules open. `brightnessctl` is the laptop's backlight keys and
hypridle's dim-before-lock; `power-profiles-daemon` backs the waybar power
profile switcher and needs enabling (`systemctl enable --now
power-profiles-daemon`). `wtype` and `noto-fonts-emoji` are for the emoji
picker — without the font the picker lists tofu boxes.

### Two machines

This branch runs on a two-monitor desktop and on a laptop (`LAPTOP-ON9AU`, a
16" Dell with one 3840x2400 panel and hybrid Intel/NVIDIA graphics). The
settings that genuinely differ live in `hypr/hosts/<host>/`, one file per
topic, and `hypr/host.lua` — the only templated file in the Hyprland config —
says which directory this machine uses. Everything else is shared.

| topic | what differs |
| --- | --- |
| `monitors.lua` | three outputs vs one; fractional vs integer scale |
| `input.lua` | mouse feel vs touchpad; numlock |
| `binds.lua` | focus-a-monitor keys vs backlight keys |
| `rules.lua` | 10 workspaces pinned across two screens vs 5 on one |
| `apps.lua` | wallpaper (16:9 vs 16:10) |
| `autostart.lua` | which applications start, and where |

An unrecognised hostname falls through to `hosts/desktop/`. Adding a third
machine is a new directory plus one case in `host.lua.tmpl`.

`uwsm/env` is templated for the same reason — see **Hybrid graphics** below.

### Login manager (greetd + ReGreet)

```bash
sudo pacman -S greetd greetd-regreet
```

Config lives in `/etc`, which chezmoi does not manage, so the copies in
`system/greetd/` are the source of truth and `system` is in `.chezmoiignore`
(otherwise chezmoi would try to create `~/system/…`). To install them:

```bash
# installs packages, copies the assets the greeter can read, and drops
# config.toml / regreet.toml / hyprland.lua into /etc/greetd.
# Safe to re-run; refuses to continue if the greeter config fails to parse.
sudo sh system/greetd/install.sh

# NOT `disable sddm.service` -- this machine has never run sddm. Check what is
# actually enabled before disabling anything; install.sh prints it for you.
sudo systemctl disable plasmalogin.service
sudo systemctl enable greetd.service
```

The display manager here is **`plasmalogin.service`**, not sddm. This README
said `disable sddm.service` for a long time, which is a command that succeeds,
prints nothing useful, and leaves the old greeter enabled. `install.sh` now
reads `display-manager.service` and tells you the real name.

ReGreet is a GTK app, so it needs a compositor. greetd runs it inside
**Hyprland**, using `system/greetd/hyprland.lua`.

Not cage: cage cannot describe monitors. It either extends across every output
(the default) or uses whichever connected last. Extending builds one ~7680px
output space across both 4K panels, so the prompt lands across the bezel seam
and the background is stretched over both screens. Hyprland gives the greeter
the same modes, scales and positions as the session — **keep those monitor
lines in sync with `hypr/monitors.lua`.**

The greeter config is **Lua**, like the session's. A `.conf` works, but
Hyprland calls it "legacy config" and says so on screen — a deprecation warning
sitting over the login prompt. The `hyprland.start` handler runs
`regreet; hyprctl dispatch "hl.dsp.exit()"`, tearing the compositor down the
moment the greeter finishes (note the Lua dispatch form — the classic syntax
would be a parse error here too).

`/etc/greetd/hyprland.lua` carries every machine's monitor block at once. It is
not templated (chezmoi does not manage `/etc`), and it does not need to be: a
block for an output that is not plugged in is inert, so the desktop ignores the
panel's block and the laptop ignores the AOC's.

The `DP-*` lines are the exception, and they are why **the ultrawide's block
has to stay above them.** Rules match in declaration order, first hit wins.
The laptop's external display arrives over USB-C on some unpredictable `DP-*`
connector, and `DP-1` — which this file *disables* to pin the desktop's prompt
to the AOC — is as likely as any. Claiming it by description first is what
stops the greeter blanking it. The old comment there claimed "there is no DP-1
on the laptop"; that stopped being true the day the laptop got a monitor.

On the laptop both screens are left lit at the greeter, so which one the prompt
opens on is down to enumeration order. Disabling the panel the way `DP-1` is
disabled would also disable it when the laptop is on its own, leaving nothing
to log in on.

On the desktop the prompt is pinned to the **32" AOC by disabling `DP-1` for
the login screen** — so the Dell is dark for the few seconds the greeter is up.

That is blunt on purpose. Hyprland enumerates `DP-1` first (monitor ID 0), so
it takes focus at startup and the greeter opened there.
`cursor.default_monitor = "DP-2"` and a `monitor = "DP-2"` window rule both
failed to move it, and a greeter cannot be iterated on quickly — every attempt
costs a logout. One output cannot be got wrong.

To light both instead, give `DP-1` the mode/position/scale from
`hypr/monitors.lua` in place of `disabled`, and expect to have to solve the
focus problem.

A greeter is not a session, so several of Hyprland's on-screen notices are
turned off in `misc` — otherwise they stack up over the login prompt:

| option | silences |
| --- | --- |
| `disable_xdg_env_checks` | "launched directly" — greetd starts it without a session manager's `XDG_*` vars |
| `disable_scale_notification` | the fractional-scaling notice |
| `disable_hyprland_guiutils_check`, `disable_watchdog_warning` | qtutils / watchdog nags |
| `ecosystem.no_update_news`, `no_donation_nag` | update news and donation popups |

**The greeter runs as the `greeter` user and cannot read `/home/djpro`** (mode
`700`). Anything it references has to be world-readable, so these are copied
into `/usr/share` rather than pointed at the home directory:

| asset | copied to |
| --- | --- |
| wallpaper | `/usr/share/backgrounds/regreet-wallpaper` (no extension — the two machines use different formats and GdkPixbuf sniffs the content) |
| `Posy_Cursor_Black` | `/usr/share/icons/` |
| `YAMIS` icons | `/usr/share/icons/` |

A default cursor or missing background at the login screen means one of those
copies is stale — re-copy after changing the wallpaper. `system/greetd/install.sh`
does the whole staging step and is safe to re-run.

`/etc/greetd/regreet.toml` is owned by the `greetd-regreet` package, so an
upgrade will drop a `.pacnew` beside it rather than overwrite; re-apply from
this repo if that happens.

Sudo prompts outside a terminal (GUI apps, launcher scripts) use
`SUDO_ASKPASS=/usr/bin/ksshaskpass`, set in `uwsm/env`. Requires
`pacman -S ksshaskpass`.

Pick **"Hyprland (uwsm)"** in the session list, not plain "Hyprland" — see
below. `vt = 1` in `config.toml` puts the greeter on the first VT, and
`Ctrl`+`Alt`+`F2` reaches a text login if the greeter ever fails to start.
Recovery from there:

```bash
sudo systemctl disable greetd && sudo systemctl enable plasmalogin && sudo reboot
```

### Logging in

Pick **"Hyprland (uwsm)"** at the greeter, not plain "Hyprland". uwsm runs the
session as a proper systemd user session, so `graphical-session.target` works
and everything autostarted gets its own unit you can poke at:

```bash
systemctl --user status waybar
```

### Layout

Hyprland 0.56 uses a Lua config. It is split by topic instead of living in one
12KB file:

| file | what's in it |
| --- | --- |
| `hypr/hyprland.lua` | entry point, just `require`s the rest |
| `hypr/host.lua` | which machine this is (generated from `host.lua.tmpl`) |
| `hypr/hosts/<host>/` | the per-machine half of the files below |
| `hypr/colors.lua` | Catppuccin Mocha palette |
| `hypr/apps.lua` | default terminal / browser / launcher / wallpaper |
| `hypr/monitors.lua` | resolution, refresh rate, scaling, placement |
| `hypr/env.lua` | Wayland toolkit + cursor env vars |
| `hypr/looknfeel.lua` | gaps, borders, blur, animations |
| `hypr/input.lua` | keyboard and mouse |
| `hypr/binds.lua` | keybindings |
| `hypr/rules.lua` | window / workspace / layer rules |
| `hypr/autostart.lua` | what starts with the session |
| `hypr/launch.lua` | the `uwsm app` helpers autostart uses |

`hyprlock.conf` and `hypridle.conf` sit in the same folder but are **hyprlang**,
not Lua — they belong to separate programs that kept the old format.

Check a config edit before logging out and finding out the hard way:

```bash
Hyprland --verify-config
```

`run_after_reload-hyprland.sh` reloads Hyprland at the end of every
`chezmoi apply`. Without it, apply writes `hyprland.lua` before the modules it
requires (alphabetical order), Hyprland's config watcher fires in that gap, and
the session sits there insisting `module 'monitors' not found`.

The authoritative Lua API for the installed version is
`/usr/share/hypr/stubs/hl.meta.lua` — worth reading, the wiki lags it.

### Monitors

Desktop (`hosts/desktop/monitors.lua`):

| output | monitor | mode | scale | position |
| --- | --- | --- | --- | --- |
| `DP-2` | AOC U32G4, 32" | 3840x2160@160 | 1.25 | left, primary |
| `DP-1` | Dell U2725QE, 27" | 3840x2160@120 | 1.5 | right |

Both panels advertise **3840x2160@60 as their preferred mode**, so
`mode = "preferred"` silently caps them at 60Hz. The modes are named explicitly
for that reason — don't "simplify" them back.

Scales are chosen so text is the same physical size on both (the 27" is denser)
and so both divide 3840 evenly. Workspaces 1–5 are pinned to the AOC, 6–10 to
the Dell.

Laptop (`hosts/LAPTOP-ON9AU/monitors.lua`):

| output | monitor | mode | scale | position |
| --- | --- | --- | --- | --- |
| `desc:Samsung…` | built-in 16" panel | 3840x2400@120 | 2 | `0x0` |
| `desc:Dell Inc. DELL U40` | Dell U4025QW, 40" ultrawide | `maxwidth` → 5120x2160@120 | 1.25 | `1920x-528` |

Both matched **by EDID description, not by connector name.** The panel comes up
as `eDP-1` or `eDP-2` depending on the boot: `simpledrm` holds a DRM minor from
the EFI framebuffer until a real driver displaces it, and which of i915/nvidia
lands where depends on init timing — the same hardware answered to `eDP-2` on
kernel 7.1.6 and `eDP-1` on 7.1.8. The ultrawide arrives over USB-C and gets
whichever `DP-*` is going. Get the description strings from
`hyprctl monitors all`.

Panel scale is an integer 2 (1920x1200 logical) — at ~283 DPI, taking
fractional-scaling blur would buy nothing. The ultrawide is ~140 DPI, the same
density as the desktop's 32" AOC, so it gets the same 1.25 → 4096x1728, both
axes exact. The panel keeps the origin and the ultrawide is offset around it
rather than the other way round, so pulling the cable changes nothing about the
undocked layout.

`1920x-528` places it **to the right of the panel with their bottom edges
flush**, matching the desk: the laptop sits beside the monitor on its left, and
low, because a laptop screen starts at desk level. `x = 1920` is the panel's
logical width, so the two touch with no gap; `y = 1200 - 1728 = -528` lines the
bottoms up. Bottom-flush is deliberate — it makes the panel's y range a subset
of the ultrawide's, so every row of the panel has somewhere to go and the
cursor never sticks at the seam.

**`desc:` is a prefix match**, not a glob. `desc:Dell Inc. DELL U40` therefore
covers the whole Dell 40" 5K2K family (U4021QW / U4023QW / U4025QW) in one
block — they are all 5120x2160 across ~39.7", so one scale fits all of them.

#### Why `maxwidth` and not `highres`

These are shared work monitors: some of the 40" ultrawides here cap at 60Hz and
some do 120Hz, so a hardcoded mode is a modeset failure on half of them. Of the
three keywords, only `maxwidth` sorts this panel shape correctly:

| keyword | comparator | result |
| --- | --- | --- |
| `highres` | `a.x > b.x && a.y > b.y` | **broken here.** 5120x2160 vs 3840x2160 fails on `2160 > 2160`, and the equal-resolution tiebreak also needs `x` within 1px. Every 2160-tall mode is mutually incomparable, and the sort is unstable → arbitrary width. |
| `highrr` | refresh first, resolution only breaks an exact tie | one fleet monitor offering 1920x1080@144 wins outright over 5120x2160@120 ([#9209](https://github.com/hyprwm/Hyprland/issues/9209)) |
| `maxwidth` | `a.x > b.x`, ties by higher refresh | widest mode, then fastest at that width. What we want. |

Hyprland keeps the best 3 modes **plus** the preferred one as a fallback chain,
so a 60Hz sibling lands on 5120x2160@60 by itself and a failed modeset walks
120 → 100 → 75 → 60 rather than going dark.

That fallback matters: 5120x2160@120 is ~1485 MHz of pixel clock, ~35.6 Gbit/s,
which is more than DP 1.4 HBR3 carries (25.92) — **120Hz only exists with DSC.**
It works over this cable under Windows, so the link and the Arc iGPU can both
do it, but it is the first thing to suspect if the session comes up at 60. Note
also that the monitor's own USB-C setting can halve the lane count to keep USB 3
data speed.

Workspaces **1–5 are pinned to the ultrawide, 6–10 to the panel**, same split as
the desktop. Only 1–5 are persistent — ten permanently-lit numbers is most of a
16" waybar gone to workspaces nobody opened, and undocked the 16" bar is the
only bar there is. A workspace bound to an absent monitor opens on whatever is
present, so undocked you get all ten on the panel and in clamshell all ten on
the ultrawide, with no extra configuration.

#### Clamshell

Closing the lid with the external display attached disables the built-in panel;
opening it brings it back. Closing it with nothing else attached suspends
instead. Two halves:

| where | what it does |
| --- | --- |
| `hypr/hosts/LAPTOP-ON9AU/binds.lua` | `switch:on:Lid Switch` → disable the panel, but only if `#hl.get_monitors() > 1` |
| `system/logind/lid.conf` | `HandleLidSwitchDocked=ignore` so logind does not suspend out from under it |

logind counts "docked" as *in a dock **or** more than one display connected*,
which is the same condition as the Hyprland-side guard — the two agree by
construction. The other two `HandleLidSwitch*` settings are left at `suspend`.

Calling `hl.monitor()` at runtime **merges** into the existing rule for that
output name and schedules a re-apply, so flipping `disabled` keeps the panel's
mode/position/scale — no `hyprctl` shell-out, and nothing restated.

`SW_LID` reads 1 when the lid is *closed*, hence `switch:on` being the close
event. The device name is libinput's, not guaranteed — check with
`hyprctl devices | grep -i switch`.

### Keys

`SUPER` is the modifier. Full list at runtime: `hyprctl binds`.

| bind | does |
| --- | --- |
| `SUPER` + `Return` | terminal |
| `Alt` + `Space` | app launcher |
| `SUPER` + `Space` | switch input method (fcitx5, not Hyprland) |
| `SUPER` + `E` / `B` | file manager / browser |
| `SUPER` + `Q` | close window |
| `SUPER` + `hjkl` or arrows | move focus |
| `SUPER` + `Shift` + `hjkl` | move window |
| `SUPER` + `Ctrl` + `hjkl` | resize window |
| `SUPER` + `1`–`0` | switch workspace |
| `SUPER` + `Shift` + `1`–`0` | send window to workspace |
| `SUPER` + `,` / `.` | focus left / right monitor (**desktop only**) |
| `SUPER` + `V` | toggle floating |
| `SUPER` + `F` / `Shift` + `F` | fullscreen / maximize |
| `SUPER` + `T` | flip split direction |
| `SUPER` + `S` | scratchpad |
| `SUPER` + `Shift` + `V` | clipboard history |
| `SUPER` + `Shift` + `E` | emoji picker |
| `SUPER` + `N` | notification centre |
| `SUPER` + `Escape` | lock |
| `SUPER` + `Shift` + `M` | power menu (lock / log out / suspend / reboot / shut down) |
| `Print` / `Shift`+`Print` / `Alt`+`Print` | screenshot region / monitor / window |
| `SUPER` + `C` / `Shift` + `C` | pick a colour on screen, as hex / rgb |

Laptop-only, from `hosts/LAPTOP-ON9AU/binds.lua`:

| bind | does |
| --- | --- |
| `XF86MonBrightnessUp` / `Down` | panel backlight, 5% steps |
| `XF86KbdBrightnessUp` / `Down` | keyboard backlight, one of three levels |

Both call `brightnessctl` with an explicit `-d`. That is not tidiness: this
laptop has **two** devices in `/sys/class/backlight` — `intel_backlight` (the
panel) and `nvidia_0` (the discrete GPU, which has no display wired to it) —
and `brightnessctl` with no `-d` picks `nvidia_0`, reports a plausible
percentage and changes nothing you can see. The waybar `backlight` module has
the same trap and the same fix.

These follow i3/sway convention, which is **not** what Hyprland ships:
upstream puts the terminal on `SUPER`+`Q` and close on `SUPER`+`C`. Lock is on
`Escape` rather than the usual `SUPER`+`L` because `L` is taken by hjkl focus.

### The Lua config gotcha

Worth knowing before debugging anything that talks to Hyprland: because the
config is Lua, **`hyprctl dispatch` evaluates its argument as Lua**, and the
classic syntax that every guide and third-party tool uses is a parse error.

```bash
hyprctl dispatch workspace 3                    # error: ')' expected near '3'
hyprctl dispatch 'hl.dsp.focus({workspace = 3})' # ok
```

This bites any program that shells out to `hyprctl dispatch` with the old
syntax, and it is why **waybar-git is used instead of the `waybar` release**.
Release builds send `dispatch workspace name:<n>` when you click a workspace,
which is a parse error here, so clicking did nothing at all. Upstream has since
switched to emitting `hl.dsp.focus({ workspace = "..." })`, so on waybar-git it
works. Downgrading to the release build silently loses workspace clicking
again.

A `~/.local/bin/hyprctl` shim translating the old syntax was tried and
deliberately removed — shadowing a system binary for the whole graphical
session was a worse problem than the one it solved. Upstream fixing it was the
better outcome.

If some other tool or a snippet from the wiki appears to do nothing, run its
command by hand: a Lua parse error is the giveaway, and the fix is to rewrite
it as `hl.dsp.*`. The dispatcher names are all in
`/usr/share/hypr/stubs/hl.meta.lua`.

### Icons

Use only **Plane-15** Nerd Font glyphs (U+F0000 and above, the Material Design
range). Icons from the Basic Multilingual Plane private use area
(U+E000–U+F8FF) do not survive being written into these files and silently
become empty strings — which is what emptied the power menu, thermometer, wifi
and launcher-prompt icons.

The installed FiraCode Nerd Font covers `f000-f381` and `f0001-f1af0`; check
before picking a glyph:

```bash
fc-query --format='%{charset}\n' /usr/local/share/fonts/f/FiraCodeNerdFont_Regular.ttf
```

### Notification centre has no volume slider

Deliberate. swaync 0.12.6's `volume` widget binds to a sink at startup and does
not follow the default-sink selection, so it showed and controlled the wrong
output. It is not a PipeWire mismatch — `pactl info` and `wpctl status` both
report the right default; swaync just ignores it.

There is no way to point it at a sink (only the `backlight` widget takes a
`device`), and `swaync-git` is *older* than the released 0.12.6, so there is
nothing to upgrade to. A slider that lies about the volume is worse than none.

Volume lives in waybar instead: scroll it to adjust, click for `pavucontrol`.
To try the widget again, put `"volume"` back in `widgets` in
`swaync/config.json`.

### Tray

waybar's tray has no per-item ignore list, so unwanted indicators are turned
off at the source. fcitx5's is its `notificationitem` addon, switched off with
`--disable=notificationitem`. Input switching still works, only the icon goes.

The flag has to be in **two** places, and the one that actually matters is the
less obvious one:

| file | start path |
| --- | --- |
| `local/share/dbus-1/services/org.fcitx.Fcitx5.service` | **D-Bus activation — this is the live one** |
| `autostart/org.fcitx.Fcitx5.desktop` | XDG autostart |

fcitx5 is started on demand by D-Bus, not by autostart:
`app-org.fcitx.Fcitx5@autostart.service` sits *inactive* while
`dbus-…-org.fcitx.Fcitx5@0.service` runs. So patching only the autostart entry
changes nothing — the first app to ask for the `org.fcitx.Fcitx5` name
re-activates it from `/usr/share/dbus-1/services`, without the flag.
`$XDG_DATA_HOME/dbus-1/services` overrides that.

Two things that look tidier and do nothing: `Enabled=False` in
`fcitx5/addon/notificationitem.conf` (fcitx5 loads the addon anyway), and
patching the autostart entry alone. Check which path is live with:

```bash
systemctl --user list-units --all | grep -i fcitx
pgrep -af /usr/bin/fcitx5          # should show --disable=notificationitem
```

### What starts with the session

Defined in `hypr/autostart.lua`, not XDG autostart. The daemons — waybar,
swaync, hypridle, the polkit agent, the two cliphist watchers, the wallpaper —
are the same everywhere; the applications are per-machine and live in
`hosts/<host>/autostart.lua`:

| app | desktop | laptop |
| --- | --- | --- |
| kitty | 1 | 1 |
| firefox | 2 | 2 |
| discord | 6 | — |
| spotify | 7 | 5 |
| steam | tray only (`-silent`) | — (not installed) |

Placement uses the per-launch rule argument to `hl.exec_cmd`, **not** a
`window_rule` matching on class. A class rule would drag *every* future window
of that app to the workspace — so opening a second terminal would yank it to 1.
This way only the launched instance is placed. `silent` puts it there without
switching to it, so the session doesn't shuffle you around while it comes up.

The old `~/.config/autostart` entries for Discord and Steam are deleted via
`.chezmoiremove`: uwsm runs XDG autostart too, so leaving them there launches
each app twice. Both apps rewrite that file when their in-app "run on startup"
setting is toggled, so turn it off inside them as well if they reappear.

### Emoji picker

`SUPER`+`Shift`+`E` opens `~/.local/bin/emoji`, a wrapper around **bemoji**
(`paru -S bemoji-git`) that draws the list with fuzzel, so it inherits the same
theme, size and `Ctrl`+`j`/`k` navigation as the launcher. The pick is copied
to the clipboard *and* typed into the focused window.

Not on `SUPER`+`.`, which is what most desktops use: the desktop host spends
comma and period on focus-a-monitor, so that bind would work on the laptop and
be dead on the desktop.

bemoji has no config file — every knob is an environment variable, which is why
there is a script rather than a bare `hl.exec_cmd("bemoji")`:

| | |
| --- | --- |
| `BEMOJI_PICKER_CMD` | pinned to fuzzel. bemoji's own search order is bemenu → wofi → rofi → dmenu → wmenu → ilia → fuzzel, so it lands on fuzzel here only because none of the others are installed |
| `-c -t` | copy *and* type. Typing needs `wtype`; the script checks for it first, because bemoji would otherwise copy and then print "No suitable typing tool found" |
| `-n` | no trailing newline, so pasting doesn't also press Enter |

Inside the picker, `Alt`+`1` copies only and `Alt`+`2` types only. That is not
configured anywhere: fuzzel's `custom-1`/`custom-2` binds exit with codes 10
and 11, and those are exactly the codes bemoji reads as clip-only and
type-only.

First run downloads the Unicode emoji list to `~/.local/share/bemoji/`
(needs network, once). Picks are counted in
`~/.local/state/bemoji-history.txt` and float to the top of the list after
that. `bemoji -D nerd` adds the Nerd Font glyphs to the same database — the
terminal font here is a Nerd Font, so they render.

### Colour picker

`SUPER`+`C` picks a pixel anywhere on screen and puts it on the clipboard as
`#rrggbb`; `SUPER`+`Shift`+`C` does the same and writes `rgb(30, 30, 46)`
instead. The screen freezes while you aim, with a zoom lens under the cursor,
and the value comes back as a notification with a swatch of the colour.

The picking is **hyprpicker** (`pacman -S hyprpicker`, same authors as the
compositor). `~/.local/bin/colorpicker` is the wrapper around it, and exists
for four small reasons — hyprpicker has both `--autocopy` and `--notify` built
in, and neither is quite right here:

| | |
| --- | --- |
| `-b` (no-fancy) | hyprpicker otherwise wraps its output in ANSI colour escapes. Readable in a terminal; from a keybind those bytes would land on the clipboard |
| own `wl-copy` | `--autocopy` appends a newline, so pasting into a config file also presses Enter. It would also copy hex when rgb was asked for |
| rgb | hyprpicker emits one format per run, so the pick is always taken as hex and converted afterwards. That is also what lets the swatch exist for both binds |
| swatch | the notification shows the colour, not just six characters of hex. Drawn with ImageMagick, with a `surface2` border so a colour near the notification's own background still has an edge. Optional — no ImageMagick, no picture, everything else still works |

Picks go through `wl-copy`, so cliphist stores them and old ones come back
under `SUPER`+`Shift`+`V`.

`-l` for lowercase hex, matching `colors.lua` and the stylesheets. `-r` freezes
the *inactive* displays too, so a hover state or a video on the other screen
holds still while you aim.

One thing to know if a pick ever looks a shade off: every external screen here
runs a fractional scale (1.25 on the 32" and the ultrawide, 1.5 on the 27"), so
a logical cursor position does not land on exactly one device pixel.
`hyprpicker -t` disables fractional-scale handling and is the first flag to try
if that shows up — add it to the `hyprpicker` line in the script. The laptop
panel is on scale 2 and cannot be affected.

### Session management

`SUPER`+`Shift`+`M` opens `~/.local/bin/powermenu`, a fuzzel menu with lock /
log out / suspend / reboot / shut down. fuzzel rather than wlogout so it
inherits the same theme and there is one less package to configure.

Log out runs **`uwsm stop`**, not `hyprctl dispatch exit`. The session is a
systemd unit under uwsm, so killing just the compositor leaves the rest of the
user session units running.

### Keyring (secrets, git credentials, ssh)

Nothing on this machine implemented the freedesktop **Secret Service** until
now. gnome-keyring was never installed, and the `kwallet` left over from the
KDE days only registers `org.kde.secretservicecompat` — a different bus name,
which nothing outside KDE looks for. So every app that stores a password hit:

```
GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name is not activatable
```

Chromium, Brave, Electron apps and `git-credential-libsecret` all ask for
`org.freedesktop.secrets` by name; with no owner they either fall back to
storing secrets in plaintext or fail outright. gnome-keyring rather than
kwallet, because the rest of this session is deliberately not KDE.

`/etc` is outside chezmoi, so the same pattern as greetd and logind — the
install script is in this repo and run by hand:

```bash
# installs gnome-keyring and patches /etc/pam.d/{greetd,passwd}.
# Safe to re-run; skips PAM files that already mention pam_gnome_keyring.
sudo sh system/keyring/install.sh
```

**The unlock has to come from PAM.** A systemd user unit can start the daemon
but cannot unlock the keyring without prompting for a password, and the only
password typed at login is the one PAM already has. The usual Arch instructions
patch `/etc/pam.d/sddm` or `/etc/pam.d/gdm`; this machine has neither —
**greetd authenticates through `/etc/pam.d/greetd`**, so that is the file that
gets `pam_gnome_keyring.so` (`auth` + `session … auto_start`). `/etc/pam.d/passwd`
gets the `password … use_authtok` line too, otherwise changing the login
password with `passwd` leaves the keyring encrypted under the old one and the
next login shows an "Unlock Login Keyring" dialog for a password that no longer
exists.

Both lines are `optional` and `-` prefixed: a keyring that will not unlock can
never block a login, and PAM stays quiet if gnome-keyring is uninstalled.

The keyring is created on the **next full login**, not by the script — log out
and back in rather than just unlocking hyprlock. Then:

```bash
busctl --user list | grep secrets   # org.freedesktop.secrets, owned
secret-tool store --label=test test key   # optional round-trip check
secret-tool lookup test key
```

The per-user half needs no root and is already set:

```bash
# git: stores HTTPS credentials in the keyring instead of asking every push.
# The helper ships with git, in /usr/lib/git-core, so the bare name resolves.
git config --global credential.helper libsecret

# ssh: nothing here any more -- gcr-ssh-agent was tried first and then
# retired, see "SSH agent and YubiKeys" below. It must stay disabled.
systemctl --user disable --now gcr-ssh-agent.socket
```

`gh` is not covered by any of this — it keeps its token in
`~/.config/gh/hosts.yml` in plaintext and has no libsecret backend.

### SSH agent and YubiKeys

SSH keys live on two YubiKey 5C NFCs as FIDO2 keys — `sk-ssh-ed25519`, one per
key, `id_ed25519_sk_primary` and `id_ed25519_sk_backup`. The private half never
leaves the device; what sits in `~/.ssh` is only a *handle*, useless without the
YubiKey that made it. Every authentication needs a physical touch.

**Which agent, and why it changed.** gcr-ssh-agent was the answer while keys
were ordinary files on disk (see Keyring above). It cannot hold these:
`/usr/lib/gcr-ssh-agent` links no libfido2 and knows no `sk-*` key types. So it
is disabled and OpenSSH's own agent — which talks to the key through
`/usr/lib/ssh/ssh-sk-helper` — took over:

```bash
systemctl --user disable --now gcr-ssh-agent.socket
systemctl --user enable  --now ssh-agent.socket
```

**The socket path has to be named twice, and neither place is optional.**
`ssh-agent.socket` listens on `$XDG_RUNTIME_DIR/ssh-agent.socket` but exports
nothing; its own unit file says *"Requires SSH_AUTH_SOCK … to be set in
environment"*. The two readers of that variable are reached differently:

| File | Covers | Why the other one misses it |
| --- | --- | --- |
| `.config/environment.d/10-ssh-agent.conf` | the systemd user manager, so every graphical app and user unit | a shell never reads environment.d |
| `.zshrc` | interactive shells, including SSHing *into* this machine | that login has no systemd user manager env to inherit |

Set in only one, the symptom is a partial one: `ssh` works in kitty and the
editor's git integration says `Connection refused`, or the reverse. Both files
carry the same value and the `.zshrc` line is guarded on the socket existing,
since WSL shares that file and has no such unit.

The old gcr path is stickier than it looks. `SSH_AUTH_SOCK` survives in the
systemd user environment after its unit is disabled, so a machine that has run
both will keep answering `/run/user/1000/gcr/ssh` until the next full login.
`systemctl --user show-environment | grep SSH_AUTH_SOCK` is the check;
`systemctl --user set-environment SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"`
fixes the running session without logging out.

**One credential per key, both resident.** The two keys are genuinely two
devices — a backup generated on the primary would not be a backup at all, and
the handle files in `~/.ssh` look identical either way, so it is worth being
able to re-check:

| Handle | Fingerprint | Device |
| --- | --- | --- |
| `id_ed25519_sk_primary` | `SHA256:KYhxT8Wejm4/tJ2b++vMK3oKtRa6BiREOI/iAYDvFLY` | serial 38362833 |
| `id_ed25519_sk_backup` | `SHA256:3+++WT+/EMp5qBV1H8nsFVBQlcXdrxDhQPmJn1Zt3Qg` | serial 38362959 |

Both were generated `-O resident`, which is the property worth having: the
credential lives on the key itself, so `~/.ssh` is a convenience rather than
something whose loss costs the key. With exactly one key plugged in:

```bash
cd "$(mktemp -d)" && ssh-keygen -K && ssh-keygen -lf *.pub
```

downloads that key's credential (PIN, then touch) and prints its fingerprint —
which one comes back tells you which device is in your hand. It lands as
`id_ed25519_sk_rk`, no application suffix, because the application is exactly
`ssh:`. `ykman fido info` is the no-touch version: *Credential storage
remaining* differs per device (95 and 94 here — five and six credentials used,
the rest being website passkeys), so it distinguishes the two keys without
authenticating, but it cannot say *which* credentials those are.

Both `.pub` files go to GitHub and to every `authorized_keys` — while the old
`id_ed25519` still works, not after.

**A PIN prompt needs an askpass when there is no tty.** `ssh-keygen -K`, and
anything else that asks for a FIDO2 PIN, falls back to `$SSH_ASKPASS` when it
has no controlling terminal — from a GUI app, or from a tool driving the shell.
Unset, it defaults to `/usr/lib/ssh/ssh-askpass`, which Arch ships only in
`x11-ssh-askpass`; the failure is a misleading *"incorrect passphrase supplied
to decrypt private key"* for a passphrase it never managed to read. This
machine already has `ksshaskpass` for sudo, so:

```bash
SSH_ASKPASS=/usr/bin/ksshaskpass SSH_ASKPASS_REQUIRE=force ssh-keygen -K
```

**ssh-agent is the worst case of this**, because it is a systemd unit and so
never has a tty at all — an sk key loaded with `ssh-add -K` cannot sign until
the agent has an askpass. The symptom is `agent refused operation` on the
client, with `sshkey_sign: incorrect passphrase supplied to decrypt private
key` in `journalctl --user -u ssh-agent`; neither points at a missing prompt.
Worse, it is silent about the cause: once the agent holds an identity, ssh uses
that copy and never falls back to the handle file on disk, so a broken agent
key shadows a working one. `ssh-add -D` is the quick way out.

`SSH_ASKPASS` is therefore set in `environment.d` and not only in `uwsm/env` —
the user manager starts the agent from its own environment, not the session's.

Note also that `ssh-keygen -Y sign` writes its signature next to the file being
signed, so signing `/dev/null` as a throwaway probe fails on `/dev/null.sig`
long after the interesting part — the touch — has already happened.

**Both handles are named under `Host *`, and the second key costs a wasted
touch.** ssh offers identities in the order they are listed, so with only the
backup plugged it offers the primary first — and a FIDO2 key insists on a touch
*before* it will admit it does not hold a credential, since enumerating a
YubiKey's credentials without authenticating is exactly what that rule prevents.
So: touch, failure, then the backup works. Reordering only moves which key pays.

This is accepted rather than fixed. The fix, if it becomes annoying, is the
agent — both credentials are resident, so it can hold only the key in hand:

```bash
ssh-add -K          # PIN + touch; loads the plugged key's resident credential
ssh-add -l          # exactly one sk key
```

That only helps once the `IdentityFile` lines are gone, though: a listed file is
offered whether or not the agent has it.

One side effect of listing them at all: an explicit `IdentityFile` *replaces*
the `~/.ssh/id_*` defaults rather than adding to them, so `id_ed25519` is no
longer offered to anything — GitHub included, which fails silently here because
this repo's remote is HTTPS through the libsecret helper. Both sk keys need to
be on GitHub and in every `authorized_keys`.

The file itself is not in this repo (it names hosts that need not be public,
and lives next to private keys).

Not in play on this machine: `pcscd` stays off (FIDO2 goes over hidraw; only
the PIV and OpenPGP applets need a smartcard daemon), commit signing is still
GPG key `3FCF1E93FFC208B5` rather than the YubiKey, and root is plain ext4, so
`systemd-cryptenroll --fido2-device` has nothing to enroll into.

### Idle, locking and suspend

`hypr/hypridle.conf`, one file for both machines:

| after | happens |
| --- | --- |
| 2m30s | backlight dims to 10% (saved and restored, so it comes back where you left it) |
| 5m00s | `loginctl lock-session` → hyprlock |
| 5m30s | screen off (DPMS) |
| 15m00s | suspend — **on battery only** |

hypridle has no idea what host it is on, so "laptop only" is expressed as a
condition on the command instead. The suspend listener uses hypridle's own
`condition_cmd`, which runs at the timeout and fires the listener only if it
exits 0:

```
condition_cmd = grep -q '^0$' /sys/class/power_supply/AC/online
```

That is false whenever the charger is in, and on a desktop it is false always —
which preserves the desktop's original rule of never suspending, because it
runs docker and tailscale and sleeping drops both. The dim listener is
self-limiting in the same way: a machine with no backlight device just fails
the `brightnessctl` call harmlessly.

**Lid close is not hypridle.** It is split between logind and Hyprland — see
**Clamshell** under *Monitors*. `/etc` is outside chezmoi, so the drop-in lives
in this repo and is installed by hand:

```bash
# writes /etc/systemd/logind.conf.d/99-lid.conf, HUPs logind, and prints back
# what logind actually resolved. Safe to re-run.
sudo sh system/logind/install.sh
```

### Hybrid graphics (laptop)

The laptop has an Intel Arc 140T iGPU and an NVIDIA RTX PRO 2000. **Every
display connector is wired to the Intel side** — the panel, HDMI and USB-C —
and the NVIDIA card has no outputs at all; it exists for render offload.

`uwsm/env` therefore pins the compositor to the iGPU:

```sh
_igpu=$(readlink -f /dev/dri/by-path/pci-0000:00:02.0-card 2>/dev/null || true)
if [ -c "$_igpu" ]; then
    export AQ_DRM_DEVICES="$_igpu"
fi
unset _igpu
```

That has to be set before the compositor starts, so it belongs in `uwsm/env`
and not in `hypr/env.lua` — by the time `hl.env()` runs, aquamarine has already
chosen its devices. It is also the whole reason that file is a chezmoi
template: the same line on a machine without that PCI device would leave the
compositor with no card to open.

**Do not write the `by-path` symlink into that variable directly.** It looks
like the obvious thing to do — the PCI address is the stable name, and the
`cardN` minors move between boots here — but `AQ_DRM_DEVICES` is a
**colon-separated list**, and every PCI address contains colons. The symlink is
not read as one device, it is split into three that do not exist:

```
drm: Explicit device list /dev/dri/by-path/pci-0000:00:02.0-card
ERR drm: Failed to canonicalize path /dev/dri/by-path/pci-0000
ERR drm: Failed to canonicalize path 00
ERR drm: Failed to canonicalize path 02.0-card
ERR drm: Found no gpus to use, cannot continue
```

Hyprland then aborts in `CBackend::create()` before reading any monitor config,
and the session drops straight back to the greeter — with `--verify-config`
still reporting the config as fine, because the config *is* fine. No escaping
helps; the colon is the delimiter. Resolving the symlink at login gets both
properties: the lookup is by PCI address and happens fresh each session, and
what aquamarine receives is a single colon-free path.

The `if [ -c ... ]` guard matters too: an empty `AQ_DRM_DEVICES` means "use no
devices", not "use all of them", and fails exactly the same way.

With only the iGPU opened, the NVIDIA card can runtime-suspend to D3cold for
the whole session instead of idling:

```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status   # -> suspended
```

Under KDE this reads `active` regardless, because KWin opens both cards. Use
`prime-run <program>` for anything that actually wants the NVIDIA card.

**Do not** add `GBM_BACKEND` or `__GLX_VENDOR_LIBRARY_NAME`. Those configure
the opposite arrangement — NVIDIA driving the display — and would break this
one.

### HiDPI and XWayland

Wayland-native apps handle scaling themselves (1.25/1.5 on the desktop, 2 on
the laptop). X11 apps cannot, so `hypr/xwayland.lua` sets `force_zero_scaling`:
they get the panel's real pixel size and render sharp, instead of drawing at
logical size and being upscaled into a blurry mess.

The catch is that an X11 app then draws at 1:1 and looks small unless it scales
itself, so those need handling one at a time — Steam via
`STEAM_FORCE_DESKTOPUI_SCALING` in `uwsm/env`, which is set per machine to
match that machine's scale.

The better fix is always to get the app off XWayland entirely. Spotify was the
easy win: `spotify-launcher.conf` passes it Ozone flags so it runs native
Wayland. To see what is still on X11:

```bash
hyprctl clients -j | jq -r '.[] | select(.xwayland) | .class'
```

### Qt apps outside Plasma

**Do not set `QT_QPA_PLATFORMTHEME=kde`.** It is the obvious way to theme
Dolphin outside Plasma, and it works, but it also breaks opening files: KIO
stops resolving the default application and shows an "Open With" dialog that
lists nothing. Measured with `kde-open <image>`:

| `QT_QPA_PLATFORMTHEME` | opens the image |
| --- | --- |
| `kde` (plasma-integration) | 0/3 |
| unset | 4/4 |
| `gtk3` | 2/2 |
| `xdgdesktopportal` | 2/2 |
| **`qt6ct`** (in use) | **3/3** |

So it is specific to plasma-integration's plugin, not to platform themes in
general. Theming is **qt6ct**, which passes that test:

```sh
export QT_QPA_PLATFORMTHEME=qt6ct   # in uwsm/env
```

Configured in `qt6ct/qt6ct.conf` (tracked) or the `qt6ct` GUI — widget style,
icon theme, fonts and dialog behaviour.

Dolphin, Gwenview and Okular are themed **Catppuccin Mocha**, matching kitty,
waybar, fuzzel and swaync. That needs two pieces:

- **style `Fusion`**, not Kvantum. Fusion honours the Qt palette; Kvantum
  ignores it and paints its own colours, which is why the desktop looked like
  two different themes.
- **`qt6ct/colors/catppuccin-mocha.conf`** (tracked), a 21-role QPalette in
  `#aarrggbb`, selected with `custom_palette=true` + `color_scheme_path`.

To go back to Kvantum: `style=kvantum` and `custom_palette=false`. Its theme
(`Dream-Violet-Dark-Kvantum`) is still configured via `kvantummanager`.

`QT_STYLE_OVERRIDE` is deliberately **not** set: it beats qt6ct's own style
setting and makes the style dropdown in the GUI do nothing.

Re-run the check after changing any of this — the failure mode is silent, and
it shows up as an empty "Open With" dialog rather than an error:

```bash
kde-open ~/Pictures/Wallpapers/*.jpg   # should open Gwenview, not a dialog
```

File associations live in `mimeapps.list` (tracked). Images had no entry at
all, so they fell through to whatever the system mimeinfo cache picked —
Brave. They are pinned to Gwenview now:

```bash
xdg-mime query default image/png
```

### Input method (fcitx5)

```bash
sudo pacman -S fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-mozc fcitx5-chinese-addons
```

Groups are configured in `fcitx5/profile`: `keyboard-us`, `pinyin`, `mozc`.
Toggle with `SUPER`+`Space`, GUI via `fcitx5-configtool`.

fcitx5 is **not** in `hypr/autostart.lua` on purpose. It ships an XDG autostart
entry (`/etc/xdg/autostart/org.fcitx.Fcitx5.desktop`) which uwsm already starts
as `app-org.fcitx.Fcitx5@autostart.service`; adding it to autostart.lua would
run a second copy.

The variables it needs live in `uwsm/env`, not `hypr/env.lua`, because fcitx5
is launched by systemd rather than by the compositor — `hl.env()` would never
reach it. Only `XMODIFIERS` is set for toolkits: Hyprland speaks
text-input-v3, so Wayland-native GTK/Qt apps reach fcitx5 through the
compositor, and setting `GTK_IM_MODULE`/`QT_IM_MODULE` there tends to *break*
them. Those two are left commented out in `uwsm/env` for the XWayland-only
apps that occasionally need them.

```bash
systemctl --user restart app-org.fcitx.Fcitx5@autostart.service   # after changes
```

### Still on KDE

Plasma configs (`kdeglobals`, `kwinrc`, …) are still in here and still
untracked-or-ignored as before. Nothing in the Hyprland setup touches them, so
both sessions remain usable while the migration settles.

## macOS specific

This branch also lands on a 14" MacBook Pro (M5, macOS 26). There is no
Wayland here, so none of it is a literal port — it is the closest analog stack
macOS has, config for config:

| Linux / Hyprland | macOS | config |
| --- | --- | --- |
| Hyprland | AeroSpace | `.config/aerospace` |
| waybar | SketchyBar | `.config/sketchybar` |
| `looknfeel.lua` borders | JankyBorders | `.config/borders` |
| kitty | Ghostty | `.config/ghostty` |
| `kb_options` in `input.lua` | Karabiner-Elements | `.config/karabiner` |
| `repeat_rate` / `repeat_delay` | `darwin-key-repeat.sh` | `run_onchange_…` |

Ghostty rather than kitty for one reason: **background blur.** kitty's blur is
Wayland-only (wlroots/KWin) and is a silent no-op on macOS; Ghostty implements
it through `NSVisualEffectView`. Linux keeps kitty, and `.chezmoiignore` keeps
each half off the other OS — see the `darwin` blocks there.

### Bring-up

**Clone the right branch.** `origin/HEAD` is `main`, and `main` has none of
this — no AeroSpace, no SketchyBar, no Ghostty, no per-OS `.chezmoiignore`
rules. A plain `chezmoi init` gets a nearly empty macOS config:

```bash
chezmoi init --branch hyprland https://github.com/on9au/dotfiles.git
```

Then [Homebrew](https://brew.sh), and:

```bash
# sketchybar + borders, and aerospace, live in third-party taps
brew tap FelixKratz/formulae
brew tap nikitabobko/tap

# Homebrew 6 refuses to load a third-party formula until its tap is trusted.
# Without this the install aborts with "Refusing to load formula … from
# untrusted tap" and nothing in the whole command gets installed.
brew trust felixkratz/formulae
brew trust nikitabobko/tap

brew install \
  chezmoi antidote starship tmux gh go fnm \
  neovim tree-sitter-cli ripgrep fd fzf lazygit \
  imagemagick ghostscript tectonic \
  sketchybar borders

brew install --cask \
  ghostty aerospace karabiner-elements font-fira-code-nerd-font

brew services start sketchybar
brew services start borders
```

`tree-sitter-cli` is the CLI, not the `tree-sitter` library neovim pulls in as
a dependency — nvim-treesitter needs the former and `:checkhealth` fails
without it.

`imagemagick`, `ghostscript` and `tectonic` are Snacks.image's rendering
chain (raster, PDF, LaTeX). `lazygit` backs `Snacks.lazygit`.

Then the pieces brew does not cover:

```bash
# node — nvim's LSPs, and mmdc below
fnm install --lts

# mermaid-cli: plugins/diagrams.lua shells out to `mmdc`
npm i -g @mermaid-js/mermaid-cli

# tmux plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins
```

`npm` will warn that it blocked puppeteer's postinstall script, which sounds
like it broke mmdc's headless browser. It generally has not — puppeteer falls
back to a Chrome already installed on the machine. Check rather than assume:

```bash
printf 'graph TD\n  A-->B\n' > /tmp/t.mmd && mmdc -i /tmp/t.mmd -o /tmp/t.png
```

If that does fail, reinstall with `npm i -g --allow-scripts=puppeteer
@mermaid-js/mermaid-cli`.

### Keyboard

The point of this section is to type on a Mac the way you type on Linux.
Karabiner does all of it; `.config/karabiner/README.md` carries the full
reasoning, including what each rule costs.

| held / tapped | does | replaces |
| --- | --- | --- |
| **Left Option** | hyper (`ctrl+opt+cmd`) — the AeroSpace mod | `SUPER` |
| **Caps Lock** | Escape | nothing — Linux leaves `kb_options` empty |
| **Control** | Command, everywhere except terminals | — |

**Left Option is the modifier because muscle memory is positional.** The
bottom rows do not line up:

```
PC/Linux:  [Ctrl] [Super] [Alt ] [Space]
Mac:       [Ctrl] [Opt  ] [Cmd ] [Space]
                    ^
       the key where SUPER lives is Option
```

So `SUPER+H` on Linux and `L-Opt+H` here are the same physical motion, and
both mean `focus left`. Only the **left** Option is grabbed — right Option
still types `Opt+3` → `#` and still moves word-wise with the arrows.

**Control and Command are swapped** so `Ctrl+C`/`Ctrl+V`/`Ctrl+T`/`Ctrl+W`
work the way they do on every Linux desktop — *except in terminals*, which are
excluded by bundle ID so `Ctrl+C` stays SIGINT. Ghostty needs no help here:
`copy-on-select` and `ctrl+shift+v` already make it behave like a Linux
terminal.

Two knock-on effects worth knowing before you go hunting for a bug:

- macOS's own screenshot shortcuts move with the swap: **`Ctrl+Shift+3/4/5`**,
  not `Cmd+Shift+3/4/5`.
- Anything holding *both* Ctrl and Cmd is unaffected, because swapping the two
  maps the pair onto itself. That covers the emoji picker (`Ctrl+Cmd+Space`)
  and, more importantly, every `ctrl-alt-cmd-*` bind in `aerospace.toml`.

The swap lives in Karabiner rather than **System Settings → Keyboard →
Modifier Keys** purely for that terminal exclusion — the built-in panel is
global, with no per-app exemption.

None of the AeroSpace binds *require* Karabiner. They are plain
`ctrl-alt-cmd-*`, so physically holding Control+Option+Command reaches all of
them on a machine where the driver extension has not been approved yet.

### The bar has to match the display

`sketchybarrc`'s `height`, `notch_width` and `notch_display_height` are
measured from one specific panel. **They do not transfer between Macs** — this
config moved from a 15" Air to a 14" Pro and every one of the three was wrong:

| | 15" Air | 14" Pro |
| --- | --- | --- |
| screen | 1710×1107 pt | 1512×982 pt |
| safe-area top | 38 pt | 32 pt |
| notch width | 209 pt | 185 pt |

Symptoms of not re-measuring are a bar noticeably taller than the real menu
bar, and a notch mask wide enough to swallow items either side of the cutout.
Re-measure with:

```bash
swift - <<'EOF'
import AppKit
let s = NSScreen.main!
print("frame:", s.frame)
print("safeAreaInsets top:", s.safeAreaInsets.top)   // -> bar height
if let l = s.auxiliaryTopLeftArea, let r = s.auxiliaryTopRightArea {
    print("notch width:", r.minX - l.maxX)           // -> notch_width
}
EOF
```

`gaps.outer.top` in `aerospace.toml` does **not** need updating alongside it,
and must not have the bar height added to it. AeroSpace tiles inside
`NSScreen.visibleFrame`, which has already subtracted the strip the bar sits
in — adding it back double-counts. It is plain `12`, the same as the other
three edges, and it stayed correct across the 38 → 32 change.

The clock is deliberately not `position=center`: true screen centre falls
*inside* the notch's excluded range, so a centred item renders behind the
physical cutout and never appears at all.

### Permissions that cannot be scripted

`chezmoi apply` writes every file, but three approvals need a human:

1. **AeroSpace** — Accessibility, on first launch. Without it the WM starts
   and does nothing at all.
2. **Karabiner** — an admin password at install, then the driver extension
   under *General → Login Items & Extensions → Driver Extensions*, plus Input
   Monitoring for `Karabiner-Elements` and `karabiner_grabber`.
3. **Log out and back in** after the first apply, so
   `run_onchange_darwin-key-repeat.sh`'s `NSGlobalDomain` values reach apps
   that were already running.

That script is the macOS half of `input.lua`'s `repeat_rate`/`repeat_delay`.
Its units are 15 ms ticks, not milliseconds, so the Linux numbers do not
transfer literally — the arithmetic is in the script's header comment. The
piece that matters most is `ApplePressAndHoldEnabled = false`: left at its
default, holding a key pops the accent picker instead of repeating, so held
`hjkl` in nvim does nothing.

### Not ported

Dropped because macOS has no equivalent to port *to*, not by oversight:
hypridle/hyprlock (`CGSession -suspend` is a straight lock, with no idle
daemon to tell), the power menu, swaync, fcitx5, `power-profiles-daemon`,
temperature (no stable sensor path), and SketchyBar's missing systray — which
is also why Steam is absent from `aerospace/autostart.sh` where it exists in
`hosts/desktop/autostart.lua`, having been tray-only there.

AeroSpace has no equivalent for centring a floating window, pinning above
workspaces, pseudo-tiling, the scratchpad, or scroll-to-switch-workspace.
`resize smart ±60` is an approximation of `binds.lua`'s per-direction resize —
AeroSpace resizes by dimension, not by direction.

`norg` is a permanent `:checkhealth` warning, not a local misconfiguration:
nvim-treesitter has no parser registered under that name, so Snacks' hardcoded
check list can only ever warn.
