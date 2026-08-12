# dotfiles

its *my* dotfiels

managed with chezmoi :3

## Hyprland specific

current packages used are:

```bash
sudo pacman -S hyprland uwsm xdg-desktop-portal-hyprland waybar fuzzel swaync hyprlock hypridle hyprpolkitagent awww hyprshot cliphist wl-clipboard qt5-wayland qt6-wayland playerctl pavucontrol networkmanager
```

`playerctl` drives the media keys, `pavucontrol` and `networkmanager` (nmtui)
are what the waybar audio/network modules open on click.

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

This is not cosmetic, and it has a known casualty: **clicking a workspace
number in waybar does nothing.** Waybar has `dispatch workspace name:<n>`
compiled into the binary, so no amount of waybar config can fix it. Switch
workspaces with `SUPER`+`1`–`0`, or by scrolling over the bar — those are
written in the Lua form and work.

A `~/.local/bin/hyprctl` shim translating the old syntax was tried and
deliberately removed: shadowing a system binary for the whole graphical
session is a worse long-term problem than losing one click target.

The same applies to anything else that shells out to `hyprctl dispatch`. If a
tool or a snippet from the wiki appears to do nothing, run its command by hand
— a Lua parse error is the giveaway, and the fix is to rewrite it as
`hl.dsp.*`. The dispatcher names are in `/usr/share/hypr/stubs/hl.meta.lua`.

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

### Tray

waybar's tray has no per-item ignore list, so unwanted indicators are turned
off at the source. fcitx5's is its `notificationitem` addon, disabled in
`fcitx5/addon/notificationitem.conf` — input switching still works, only the
icon is gone.

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

`QT_QPA_PLATFORMTHEME=kde` in `uwsm/env` is what makes Dolphin, Gwenview and
Okular read their colours, icons and fonts from `kdeglobals`. Without it they
fall back to unstyled Qt. The plugin comes from `plasma-integration`.

File associations live in `mimeapps.list` (tracked). Images had no entry at
all, so they fell through to whatever the system mimeinfo cache picked —
Brave — which is what produced the broken "open with" prompt. They are pinned
to Gwenview now:

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
