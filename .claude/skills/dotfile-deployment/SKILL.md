---
name: dotfile-deployment
description: Wire new dotfiles in home/ or etc/ into this dotfiles repository's setup.sh and validate their deployment without modifying the host.
---

# Dotfile deployment

Use this repository's `home/`, `etc/` and `setup.sh` interface. Add a `link user
<repo-path> <target>` or `link sudo <repo-path> <target>` call to the appropriate
`setup_*` function for each new deployment source. A linked directory also covers
its descendants. The fcitx5 loop covers only its explicitly listed configurations.

If a new subsystem requires a new setup function, register it in
`list_step_label` and the relevant scope/interaction/irreversibility lists.
Files intentionally not deployed go in `test/unwired-files.txt` with a tab and a
concrete reason. Do not add exemptions just to hide wiring defects.

Run `sh test/all` before finishing. The tests never run setup.sh, install packages
or change the machine. The PostToolUse hook is advisory and delegates to the same
deployment test. Do not run setup.sh merely to validate a repository edit: its
machine deployment needs its own authorization.
