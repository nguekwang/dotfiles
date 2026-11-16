---
name: dotfile-deployment
description: Wiring a newly created dotfile into this repository's setup.sh so it actually reaches a machine. Use whenever you add a new dotfile under this repository — a file meant to end up under $HOME, $XDG_CONFIG_HOME, or /etc on a machine, as opposed to documentation or a produced artifact.
---

# Dotfile Deployment

A dotfile that exists only in this repository's tree is not yet part of the system: `setup.sh` is the sole path by which a file here reaches a real machine, so adding a dotfile without a matching `setup.sh` entry leaves it dead everywhere but this checkout.

- Whenever you create a new dotfile under this repository, add the matching call in `setup.sh` in the same change: `link_userconfig <repo-relative-path> <target-path>` for a user-scope file (destined for `$HOME` or `$XDG_CONFIG_HOME`), or `link_sysconfig <repo-relative-path> <target-path>` for a system-scope file (destined for `/etc`).
- Place the call inside the `setup_*` function that already groups that dotfile's tool or subsystem (a Claude Code file goes in `setup_claude`, a Hyprland file in `setup_hypr`, and so on). Add a new `setup_*` function, and register it in `list_step_spec` with its device scope, only when no existing function fits the dotfile's subsystem.
- Verify the wiring by reading back the edited `setup_*` function and confirming the new call's source path resolves to the file just created.

## Residual: Files That Are Not Dotfiles

Not everything created under this repository is a dotfile. Repository documentation (the notes in `silver-lake/`, directories and root files alike, a directory's `CLAUDE.md`) and a produced deliverable (see the `files-and-repository` skill's Artifact Output section) are never wired into `setup.sh`.
