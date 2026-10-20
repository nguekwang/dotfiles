# dotfiles

Machine setup for Arch Linux. A few POSIX `sh` scripts under `sh/`, no
arguments, safe to run as many times as you like. Everything the scripts do not
do is a step in `README.md`.

```sh
sh ~/dotfiles/sh/init
```

## Layout

| File | Does |
| --- | --- |
| `sh/init` | refreshes `sudo` for the whole run, then runs `sh/link` and `sh/pkg` |
| `sh/link` | symlinks every row of `sh/link-list` into place |
| `sh/pkg` | installs every row of `sh/pkg-list` with pacman or paru |
| `sh/run` | sourced by the others: `path_home`, `path_dot` and `run` |
| `sh/link-list` | one row per link: `enum_mode path_src enum_root path_rel` |
| `sh/pkg-list` | one row per package: `enum_source name_pkg` |

`enum_mode` is `user` or `sudo`, `enum_root` is `etc`, `config` or `home`, and
`enum_source` is `pacman` or `aur`. Adding a config or a package is adding a
row, not editing a script.

## Philosophy

### 1. No arguments

`sh sh/init` is the entire interface. No flags, no subcommands, no targets to
remember. What happens is decided by the lists and the state of the machine,
not by what you type.

A few environment variables override defaults when you need them:

| Variable | Default |
| --- | --- |
| `name_main_user` | `nguekwang` |
| `XDG_CONFIG_HOME` | `$HOME/.config` |

### 2. Idempotent

A second run is not a different code path, it is the same code path finding
most of its work already done.

- config files are symlinks, so re-linking is `ln -sfn` over itself
- packages go through `pacman -Syu --needed` and `paru -S --needed`
- paru is built from the AUR only when it is absent, and upgraded otherwise

Run it on a fresh install, on a machine set up a year ago, or twice in a row by
mistake, and the outcome is the same.

### 3. No GNU Make

A `Makefile` would be a second vocabulary to learn — targets, `.PHONY`,
tab-versus-space — layered on top of the shell you already need to read any of
the recipes. In exchange it offers dependency ordering and parallelism that a
linear machine setup does not want. So there is no `Makefile`.

### 4. No comments

Code that needs a comment to say what it does needs a better name instead. The
scripts under `sh/` carry none:

- every name states its type: `path_`, `name_`, `enum_`, `list_`, `uri_`,
  `pid_`. You know what a variable holds before you read what it holds.
- what a step acts on lives in a list, so a script body is only the operations
  it performs.

### 5. Brief identifiers

The prefix already states the type, so the rest of a name can be one word:
`path_dot`, `path_rows`, `uri_aur`, `pid_sudo`. A name grows long only when it
has started doing a comment's job.

Names that differ by one value are one function taking that value:

| Instead of | There is |
| --- | --- |
| `run_as_user`, `run_as_root` | `run user`, `run sudo` |

## What it writes

Symlinks under `/etc`, `$XDG_CONFIG_HOME` and `$HOME`, and the packages in
`sh/pkg-list`. A pre-existing real file or directory at a link target is
replaced. The repository is the source of truth, so no `.bak` copies are kept.

## Requirements

Arch Linux, the repository at `~/dotfiles`, and either root or a user in the
`wheel` group. `README.md` covers getting there.
