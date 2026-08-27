# Karabiner-Elements

Five rules, all there to make a Mac keyboard behave like the Linux one this
repo is really built around. `karabiner.json` is JSON and can't hold comments,
hence this file.

| rule | what it does |
| --- | --- |
| **Left Option -> hyper** | held, sends `ctrl+opt+cmd` -- the single-key `SUPER` that drives AeroSpace |
| **Caps Lock -> Escape** | for nvim, and `mode-keys vi` in `~/.tmux.conf`. macOS-only -- Linux leaves `kb_options` empty |
| **Ctrl <-> Cmd** | copy/paste/quit/tabs move to Control, like every Linux desktop. Terminals excluded |
| **Cmd+Space in terminals** | patches one hole the exclusion above opens -- see below |
| **Cmd+Tab** | no app switcher; Tab cycles tabs the Linux way |

## Why Left Option is the modifier

Muscle memory is positional, not nominal. The bottom rows do not line up:

    PC/Linux:  [Ctrl] [Super] [Alt ] [Space]
    Mac:       [Ctrl] [Opt  ] [Cmd ] [Space]

The key sitting where `SUPER` lives on a PC is **Option**, so that is the one
mapped to hyper. Reaching for `SUPER+H` lands on the right physical key with
no retraining, and `../aerospace/aerospace.toml` binds it to `focus left` --
the same thing `../hypr/binds.lua` binds `SUPER+H` to.

The cost is real and worth stating: **left Option stops being a text
modifier.** macOS uses Option to type symbols (`Opt+3` -> `#`) and to move
word-wise with the arrows. Only the left key is grabbed, so **right Option
still does all of that** -- the loss is one of two keys, not the function.

Caps Lock held used to be the hyper key here, and both were briefly on offer.
Left Option won on position. Caps Lock kept the half that has nothing to do
with the window manager: tapped, it is Escape.

## Why hyper is ctrl+opt+cmd and not ctrl+opt+cmd+shift

The usual "hyper" recipe folds `shift` in too. That would be wrong here: the
Hyprland binds this mirrors use `SUPER` for focus and `SUPER+SHIFT` for move,
so `shift` has to stay free to act as the second half of the pair. Held Option
therefore sends three modifiers, not four, and `L-Opt+shift+h` cleanly reaches
AeroSpace's `ctrl-alt-cmd-shift-h`.

`ctrl+opt+cmd` is unclaimed on macOS. The near misses all drop one of the
three: Ctrl+Cmd+Space (emoji), Ctrl+Cmd+F (fullscreen), Cmd+Opt+Esc (force
quit). VoiceOver's VO key is Ctrl+Opt, but only while VoiceOver is running.

## Why the Ctrl/Cmd swap excludes terminals

Swapping the two everywhere would put `Ctrl+C` on the Command key -- and in a
terminal `Ctrl+C` is not "copy", it is SIGINT. Losing the interrupt to a
modifier swap is not a trade worth making, so every terminal emulator is
listed under `frontmost_application_unless` and keeps stock macOS behaviour:
`Ctrl+C` interrupts, `Cmd+C`/`Cmd+V` copy and paste.

`../ghostty/config` already covers the Linux terminal idiom on its own --
`copy-on-select = true` and `ctrl+shift+v` to paste, exactly as a Linux
terminal does -- so the exclusion costs nothing there.

This per-app carve-out is the whole reason the swap lives in Karabiner rather
than in **System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys**.
That panel can swap Control and Command globally in two clicks, but it is all
or nothing, with no way to exempt an application.

Editors are deliberately *not* excluded. With the swap on, VS Code gets
`Ctrl+C`/`Ctrl+P`/`Ctrl+Shift+P`, which is its Linux keymap.

## The hole the terminal exclusion opens, and the patch

Excluding terminals is right for `Ctrl+C`, but it is an *app-wide* exclusion,
and that has a consequence worth stating plainly: **every chord behaves
differently inside a terminal than outside it.**

That is invisible for app shortcuts, which are per-app anyway. It is not
invisible for a global hotkey. The launcher is Command+Space, which outside a
terminal the swap turns into `Ctrl+Space` -- what Raycast listens for. Inside
Ghostty the swap is off, so the same press stays `Cmd+Space`, Raycast never
sees it, and Spotlight answers instead. The launcher silently stops working in
the one app you are most likely to launch things from.

Hence the fourth rule: in the same bundle list, and *only* for the spacebar
carrying Command, emit `Ctrl+Space` anyway. Nothing else about the terminal
exclusion changes -- `Ctrl+C` is not touched, because that rule matches
`spacebar` and nothing else.

Safe here because `Ctrl+Space` is unclaimed in this terminal stack: the tmux
prefix is `C-a` (`~/.tmux.conf`), nvim binds nothing to it, and ghostty's only
keybind is `ctrl+shift+v`. Check those three before adding a second chord to
this rule.

The general shape of the problem is worth remembering: **a global hotkey built
from a swapped modifier needs a rule like this one, or it dies in terminals.**
A chord holding both Ctrl and Cmd does not, being symmetric, and neither does
anything built on hyper, since that rule has no app condition at all.

## Why Cmd+Tab is gone

Two reasons, and the second is the real one.

It is redundant: AeroSpace already switches windows on `L-Opt+hjkl` and
workspaces on `L-Opt+1..0`, across applications, so a separate
application-only switcher adds nothing.

More to the point, it was **stealing next-tab.** On both Linux and stock
macOS, cycling tabs in a browser is `Ctrl+Tab`. Under the swap, physical
Ctrl+Tab emits `Cmd+Tab`, so the app switcher grabbed it before Firefox ever
saw it -- and the real `Ctrl+Tab` ended up on physical Cmd+Tab, which is not
somewhere anyone would think to look.

So this rule maps `Cmd+Tab` back to `Ctrl+Tab`. The result is that **both**
physical Ctrl+Tab and physical Cmd+Tab cycle tabs, and neither reaches the
app switcher, which is exactly the intent.

Deliberately unconditional, unlike rule 3. Terminals are exempt from the swap
but not from this: without the rule, Cmd+Tab would still summon the switcher
in Ghostty alone. Nothing in `~/.tmux.conf` or `ghostty/config` binds Tab, so
there is nothing there to collide with.

`L-Opt+Tab` is untouched -- it is AeroSpace's `workspace-back-and-forth`, and
it rides on hyper, whose rule has no app condition and no Command in it.

There is no supported `defaults` key for disabling the application switcher;
it lives in the Dock and WindowServer rather than in symbolichotkeys. A
Karabiner rule is the way to do it.

## The swap does not disturb the window-manager binds

Two independent reasons, either one sufficient:

1. **The chord is symmetric.** `ctrl-alt-cmd` contains both swapped keys, so
   exchanging them maps the set onto itself. Whatever else changes,
   `{ctrl, opt, cmd}` is still `{ctrl, opt, cmd}`.
2. **Karabiner does not re-process its own output.** Events a manipulator
   emits in `to` go to the virtual keyboard, not back through the
   complex-modification pipeline, so the hyper rule's `ctrl+opt+cmd` is never
   seen by the swap rule.

## The binds work without Karabiner

Nothing in `aerospace.toml` depends on this file. The binds are plain
`ctrl-alt-cmd-*`, so physically holding Control+Option+Command reaches all of
them whether Karabiner is running or not. Left Option is a convenience alias
for that chord, not a prerequisite -- so a machine without Karabiner, or one
where the driver extension hasn't been approved yet, still has a working WM
(and stock macOS Cmd shortcuts, since the swap is off too).

## Setup that can't be scripted

`chezmoi apply` writes this config, but Karabiner itself needs a one-time
manual install -- it ships a DriverKit system extension, so it needs an admin
password and two approvals in System Settings that no script can grant:

    brew install --cask karabiner-elements

Then approve the driver extension (System Settings > General > Login Items &
Extensions > Driver Extensions) and grant Input Monitoring to
`Karabiner-Elements` and `karabiner_grabber` when prompted.

Worth checking once it is running, in this order -- each isolates one rule:

| press | in | expect |
| --- | --- | --- |
| `L-Opt+2` | anywhere | AeroSpace switches to workspace 2 |
| `L-Opt+shift+2` | anywhere | focused window moves to workspace 2 |
| `R-Opt+3` | any text field | types `#` (right Option untouched) |
| `Ctrl+C` | Firefox | copies |
| `Ctrl+C` | Ghostty | interrupts, does **not** copy |
| `Cmd+Space` | Ghostty | opens Raycast, **not** Spotlight |
| `Ctrl+Tab` | Firefox, 2+ tabs | next tab, **no** app switcher |
| Caps Lock | nvim insert mode | leaves insert mode |

**Karabiner-EventViewer** (installed alongside) shows exactly what each press
resolves to, which is the fastest way to debug a rule that does not fire.

## Drift

Karabiner's Settings GUI rewrites `karabiner.json` on save, normalising and
padding it with every default key. Edit the file here and `chezmoi apply`
rather than using the GUI; if the GUI does rewrite it, `chezmoi diff` will
show the churn. This is the same problem `.chezmoiignore` documents for
`kwinrc`, but not bad enough to give up managing the file -- Karabiner
reloads live on file change, so editing it directly works fine.
