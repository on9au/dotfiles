# dotfiles

its *my* dotfiels

managed with chezmoi :3

## Hyprland specific

current packages used are:

```bash
sudo pacman -S hyprland uwsm xdg-desktop-portal-hyprland xdg-desktop-portal-kde plasma-integration fuzzel swaync hyprlock hypridle hyprpolkitagent awww hyprshot cliphist wl-clipboard qt5-wayland qt6-wayland playerctl pavucontrol networkmanager

# waybar from the AUR, not the repos -- see "The Lua config gotcha" below.
# The release build cannot switch workspaces on click with a Lua config.
paru -S waybar-git
```

`playerctl` drives the media keys, `pavucontrol` and `networkmanager` (nmtui)
are what the waybar audio/network modules open on click.

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

sudo systemctl disable sddm.service
sudo systemctl enable greetd.service
```

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

The prompt is pinned to the **32" AOC by disabling `DP-1` for the login
screen** — so the Dell is dark for the few seconds the greeter is up.

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
| wallpaper | `/usr/share/backgrounds/regreet-wallpaper.jpg` |
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
sudo systemctl disable greetd && sudo systemctl enable sddm && sudo reboot
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
| `hypr/colors.lua` | Catppuccin Mocha palette |
| `hypr/apps.lua` | default terminal / browser / launcher / wallpaper |
| `hypr/monitors.lua` | resolution, refresh rate, scaling, placement |
| `hypr/env.lua` | Wayland toolkit + cursor env vars |
| `hypr/looknfeel.lua` | gaps, borders, blur, animations |
| `hypr/input.lua` | keyboard and mouse |
| `hypr/binds.lua` | keybindings |
| `hypr/rules.lua` | window / workspace / layer rules |
| `hypr/autostart.lua` | what starts with the session |

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
| `SUPER` + `,` / `.` | focus left / right monitor |
| `SUPER` + `V` | toggle floating |
| `SUPER` + `F` / `Shift` + `F` | fullscreen / maximize |
| `SUPER` + `T` | flip split direction |
| `SUPER` + `S` | scratchpad |
| `SUPER` + `Shift` + `V` | clipboard history |
| `SUPER` + `N` | notification centre |
| `SUPER` + `Escape` | lock |
| `SUPER` + `Shift` + `M` | power menu (lock / log out / suspend / reboot / shut down) |
| `Print` / `Shift`+`Print` / `Alt`+`Print` | screenshot region / monitor / window |

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

Defined in `hypr/autostart.lua`, not XDG autostart:

| app | lands on |
| --- | --- |
| kitty | 1 |
| firefox | 2 |
| discord | 6 |
| spotify | 7 |
| steam | tray only (`-silent`, no window) |

Placement uses the per-launch rule argument to `hl.exec_cmd`, **not** a
`window_rule` matching on class. A class rule would drag *every* future window
of that app to the workspace — so opening a second terminal would yank it to 1.
This way only the launched instance is placed. `silent` puts it there without
switching to it, so the session doesn't shuffle you around while it comes up.

The old `~/.config/autostart` entries for Discord and Steam are deleted via
`.chezmoiremove`: uwsm runs XDG autostart too, so leaving them there launches
each app twice. Both apps rewrite that file when their in-app "run on startup"
setting is toggled, so turn it off inside them as well if they reappear.

### Session management

`SUPER`+`Shift`+`M` opens `~/.local/bin/powermenu`, a fuzzel menu with lock /
log out / suspend / reboot / shut down. fuzzel rather than wlogout so it
inherits the same theme and there is one less package to configure.

Log out runs **`uwsm stop`**, not `hyprctl dispatch exit`. The session is a
systemd unit under uwsm, so killing just the compositor leaves the rest of the
user session units running.

### HiDPI and XWayland

Wayland-native apps handle the 1.25/1.5 scaling themselves. X11 apps cannot, so
`hypr/xwayland.lua` sets `force_zero_scaling`: they get the real 3840x2160 and
render sharp, instead of drawing at logical size and being upscaled into a
blurry mess.

The catch is that an X11 app then draws at 1:1 and looks small unless it scales
itself, so those need handling one at a time — Steam via
`STEAM_FORCE_DESKTOPUI_SCALING` in `uwsm/env`.

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
