# complete-works

Machine setup for Arch Linux. One POSIX `sh` script, no arguments, safe to run
as many times as you like.

```sh
sh setup.sh
```

## Philosophy

### 1. No arguments

`sh setup.sh` is the entire interface. No flags, no subcommands, no targets to
remember. What happens is decided by the state of the machine, not by what you
type, so there is nothing to look up before a run and nothing to mistype.

A few environment variables override defaults when you need them:

| Variable | Default |
| --- | --- |
| `name_main_user` | `nguekwang` |
| `name_cookie_browser` | `chrome` |
| `XDG_CONFIG_HOME` | `$HOME/.config` |

### 2. Idempotent

Every step asks what is already there before it acts: what exists is updated,
what is missing is set up. A second run is not a different code path, it is the
same code path finding most of its work already done.

- config files are symlinks, so re-linking is `ln -sfn` over itself
- packages go through `pacman -S --needed`, `paru -Syu`, `bun upgrade`,
  `uv self update`
- the user account, timezone, NTP and the `wheel` sudoers drop-in are read
  before they are written
- the SSH key is generated only when `~/.ssh/id_ed25519` is absent
- a tool is installed when it is absent and upgraded when it is already there

This is the property that makes the script worth having: run it on a fresh
install, on a machine set up a year ago, or twice in a row by mistake, and the
outcome is the same.

### 3. No GNU Make

A `Makefile` would be a second vocabulary to learn — targets, `.PHONY`,
tab-versus-space, `make install` versus `make link` — layered on top of the
shell you already need to read any of the recipes. In exchange it offers
dependency ordering and parallelism that a linear machine setup does not want.
So there is no `Makefile`. The steps live in one list in the script, in the
order they run.

### 4. No comments

Code that needs a comment to say what it does needs a better name instead. The
script carries none, and the work a comment would have done is carried by the
code:

- every name states its type: `path_`, `name_`, `count_`, `enum_`, `list_`,
  `uri_`, `row_`, `pid_`, `esc_`, `secret_`. You know what a variable holds
  before you read what it holds.
- `probe_path` answers in words — `symlink`, `dir`, `file`, `other`, `absent` —
  so `case "$(probe_path "$dst")" in symlink)` reads as the sentence it is. A
  boolean would have needed a comment to say which way round it went.
- functions are named after the thing they act on, so the related ones share a
  prefix and sort together: `wave_start` / `wave_stop`, `status_start` /
  `status_stop`, `manifest_draw` / `manifest_set`, `journal_add`.
- four lists declare every step's properties in one place —
  `list_step_label`, `list_step_sudo`, `list_step_interactive`,
  `list_step_irreversible` — instead of flags buried in the bodies.
- a `setup_*` body is only the operations it performs. `setup_hypr` is six
  `link` calls and nothing else.

Really good code is obvious at a glance. When a line is not, that is a defect
in the line, not a missing comment.

### 5. Brief identifiers

The prefix already states the type, so the rest of a name can be one word:
`path_dot`, `path_run`, `row_wave`, `pid_main`, `esc_red`. Length is not
clarity. A name grows long only when it has started doing a comment's job.

The same rule collapses families of functions. Names that differ by one value
are one function taking that value, not several spellings to keep in sync:

| Instead of | There is |
| --- | --- |
| `log_info`, `log_progress`, `log_warning`, `log_error` | `log info`, `log progress`, ... |
| `link_userconfig`, `link_sysconfig` | `link user`, `link sudo` |

`log` and `link` are the shortest names still unambiguous in this script, so
that is what they are called.

## What a run prints

While the run goes, the bottom of the terminal holds one row per step (`[ ]`
pending, `[✓]` done, `[✘]` failed, `[-]` skipped) and the running step's name
animates below them next to how long it has been going, so a step that has
stalled stops looking like a step that is working. A step's own stdout is
discarded; its stderr is captured,
so a failure's output appears nested under the row that failed instead of
racing the live rows for the screen.

At the end, on stdout:

```
[✓] package/pkg
[✘] userconfig/nvim

Total: 16  Success: 15  Failed: 1  Skipped: 0

INFO: pkg: installed
INFO: git-ssh: key generated

WARN: nvim: plugin restore failed
NEXT: you should re-run nvim --headless "+Lazy! restore" +qa
```

`INFO:` lines are what the run actually did. `WARN:`/`NEXT:` pairs are what
needs attention — summarized by the `claude` CLI when it is on `PATH`, printed
one-to-one otherwise.

## What it writes

Inside the repository, only what `git pull` brings in; on a machine without
`~/dotfiles`, the repository itself is cloned there first. Working state —
collected findings, per-step stderr, per-step rollback journals — lives in a
`mktemp -d` directory and is removed on exit, Ctrl-C included.

It also holds a lock file at `$XDG_RUNTIME_DIR/complete-works.lock`, or under
`/tmp` when that is unset. That one
stays behind on purpose; see below.

Outside the repository a run creates symlinks under `$XDG_CONFIG_HOME` and
`/etc`, an SSH key and `/etc/sudoers.d/10-wheel`.

A pre-existing real file at a link target is overwritten. The repository is the
source of truth, so no `.bak` copies are kept.

## One run at a time

A second run started while the first is going would fight it for the pacman
database and for the terminal, and the loser ends up suspended rather than
finished. So the script takes an exclusive `flock` before it does anything, and
a second run refuses to start.

The lock lives on the open file descriptor, not on the file, so the kernel
releases it the moment the last process holding it dies. It cannot go stale the
way `/var/lib/pacman/db.lck` can. Child processes inherit it, which is the point
— while a package manager the run started is still alive, the run still counts
as active.

## Rollback

Each step records a journal of what it changed. When a reversible step fails,
its journal is replayed backwards and that step's changes are undone; the
remaining steps still run. Steps that install packages, create accounts or
download files cannot be undone — they are declared in
`list_step_irreversible`, and when one fails the run says so plainly rather
than pretending to clean up.

## Requirements

Arch Linux, and either root or a user in the `wheel` group. `sudo` is asked for
once, up front, and only if a step that needs it is going to run.

## Steps

| Step | Does |
| --- | --- |
| `package/pkg` | `base-devel`, `git`, `zsh`, `neovim` |
| `repo/git_sync` | `git pull` in `~/dotfiles`, or `git clone` it there |
| `system/account` | main user, shell, `wheel`, password, sudoers drop-in |
| `system/time` | timezone and NTP |
| `sysconfig/system_config` | `/etc` config, hyprctl guard, builds `paru` |
| `userconfig/paru` | `paru.conf` |
| `userconfig/chrome` | Chrome flags, managed policy, AUR install |
| `repo/git_ssh` | `~/.ssh/config`, ed25519 key |
| `userconfig/shell` | `.zshrc` |
| `userconfig/nvim` | `init.lua`, lock file, `Lazy! restore` |
| `userconfig/fcitx5` | profile, config, 9 addon confs |
| `userconfig/hypr` | Hyprland, mako, foot, waybar, qutebrowser |
| `userconfig/claude` | plugins, hooks, settings, keybindings |
| `package/node` | Bun, gemini-cli, codex |
| `package/python` | uv, ipython, keras, matplotlib |
| `userconfig/git_config` | `.gitconfig`, `.githooks`, `.gitmessage` |
