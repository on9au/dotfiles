# Working in this repo

Read this before editing anything. It is short because most of the repo
explains itself in comments — these are the things that are *not* visible from
the file you happen to have open.

`README.md` is the human documentation and is far longer. It is the reference
for *why* any given config looks the way it does; this file is about how not
to break the repo while changing it.

## This is a chezmoi source tree, not a config directory

Files here are **source state**. They are not the files that are in use — those
are in `$HOME`, written by `chezmoi apply`.

- Edit `dot_zshrc` here, then `chezmoi apply`. Do **not** edit `~/.zshrc`; the
  next apply overwrites it.
- If a file in `$HOME` has already drifted, `chezmoi re-add <target>` pulls the
  change back into the source tree. `chezmoi status` shows drift, `chezmoi
  diff` shows it in full.
- Naming is meaningful: `dot_` → `.`, `private_` → mode 0600, `executable_` →
  `+x`, `.tmpl` → rendered as a Go template, `run_onchange_` / `run_after_` →
  scripts chezmoi executes during apply rather than files it writes.

## Every top-level entry becomes a path in $HOME

`.chezmoiignore` paths are relative to `$HOME`, and anything at the root of
this repo that is not ignored gets written into the home directory.

**If you add a top-level file or directory that is not a dotfile, add it to
`.chezmoiignore` in the same change.** This has already gone wrong once: every
apply was dropping a full copy of `README.md` into `$HOME`. `docs`, `system`,
`install`, `README.md`, `AGENTS.md` and `CLAUDE.md` are all ignored for exactly
this reason, and each has a comment there saying so.

## Four targets, one tree

`.chezmoiignore` decides which half of the repo lands where: Arch/Hyprland,
macOS/AeroSpace, Windows/GlazeWM, and WSL (shell half only — zsh, tmux, nvim).

WSL is detected on the **kernel release string** containing `microsoft`, never
on a hostname — the WSL install and the Windows install share the hostname
`G3JC7G4`, so a hostname test would put both on the same side.

When you add a config, decide which targets should get it and edit the
relevant blocks. A config that only makes sense on a compositor belongs in the
`darwin` and WSL exclusion lists.

## install/

Bring-up scripts, run by hand from a clone. `bootstrap.sh` is the entry point
and runs three steps in a fixed order: packages (`arch.sh` / `macos.sh`) →
`chezmoi apply` → `common.sh`. The order is forced — step 1 installs chezmoi
itself, and step 3 reads files that step 2 writes.

- POSIX `sh`, `set -eu`, idempotent, and safe to re-run. Match that style.
- They call `sudo` per command and **must not be run as root** — `common.sh`
  writes into `$HOME`, and a root-owned `~/.antidote` is worse than a missing
  one. `require_not_root` in `lib.sh` enforces this.
- They need a **real terminal**, because `sudo` needs a TTY to prompt on. From
  an agent shell or any other non-TTY they fail at the first sudo with
  "a terminal is required to read the password".

**Target detection is duplicated.** `dotfiles_target` in `install/lib.sh` and
the `contains "microsoft"` test in `.chezmoiignore` make the same decision in
two languages. Change one, change the other, or the packages and the configs
land on different sides of the same fence.

## Gotchas that have already bitten

**`lazy-lock.json` is committed *and* written by nvim.** So it is a
chezmoi-managed file that another program edits behind chezmoi's back, and an
apply stops with `has changed since chezmoi last wrote it?` when it drifts.
Anything scripted must use `nvim --headless "+Lazy! restore"`, which installs
the pinned commits — **never `Lazy! sync`**, which updates every plugin and
rewrites the lock. To move the pins deliberately: `:Lazy update`, then
`chezmoi re-add ~/.config/nvim/lazy-lock.json`, then commit.

**`system/` is not chezmoi-managed and is not part of `install/`.** Those
scripts write to `/etc`, need root, and have consequences worth reading first
— a broken `/etc/greetd` locks you out of the machine. They are run by hand,
one at a time, after reading the matching README section.

**The branch is `hyprland`, not `main`.** `main` is far behind and has no
macOS or Windows support. Clone with `chezmoi init --branch hyprland …`.

## House style

Comments explain **why**, not what, and they are long where the reasoning was
hard-won — most of this repo's value is in them. When you change a config
because something broke, say what broke in a comment next to the fix. When you
remove such a fix, say why it is no longer needed. Match the density of the
file you are in rather than the density you would pick.
