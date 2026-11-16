---
name: environment-assumptions
description: This user's OS, tools, and hardware assumptions (Arch Linux, pacman/paru, Hyprland, Zsh, Neovim, foot, HHKB), and where to read the live configuration under user/ and etc/. Use whenever you assume an OS, a package manager, an editor, a terminal, or hardware while working for this user, or need to answer what the current setup actually is.
---

# Environment Assumptions

The lists below are a cached snapshot for quick reasoning, not a live source —
see "Configuration Source of Truth" for when to read the actual files instead.

- OS: Arch Linux
- Package Manager: pacman
- AUR Helper: paru
- Display protocol: Wayland
- GUI: Hyprland (bar is Waybar)
  - Input Method: fcitx5
  - Text Expansion: espanso
- Shell: Zsh
- Editor: Neovim (lazy.nvim)
- Browser: Google Chrome (`google-chrome-stable`, from the AUR). Chosen over
  Chromium because password, passkey and tab sync to a Google account needs the
  proprietary API keys only Chrome's build carries. qutebrowser is also
  installed, for keyboard-driven browsing.

## Software

- Terminal is foot
  - https://wiki.archlinux.org/title/Foot
  - https://codeberg.org/dnkl/foot
- Terminal multiplexer is tmux
- OS / distro is Arch Linux
- Editor is Neovim
  - Configure via `~/.config/nvim/init.lua`.
  - Use `lazy.nvim` as the package manager.
  - https://github.com/folke/lazy.nvim
- GUI is Hyprland. The bar is Waybar.
- Screenshot is `grim`
- Screen recording is `wf-recorder`

## Hardware

- Keyboard is HHKB

## Source

Derived from `silver-lake/life/independent-computing.md`, which also documents the
reasoning: a local, CLI-first, keyboard-driven setup that survives a device
replacement intact, over a cloud-service-based setup with recurring cost and
vendor lock-in.

## Configuration Source of Truth

Before answering any question about the current editor, shell, window manager,
browser, or related tooling setup — not only before proposing a change to it —
read this repository's own configuration rather than relying on the snapshot
above: `user/` for per-user dotfiles, `etc/` for system files, and `setup.sh` for
how each one is deployed. Infer the existing file locations, dependencies, and
naming from what is actually there, and align any proposal with that
organization so the result stays manageable as configuration files under
version control.

This supersedes the former external reference to a separate `dotfiles`
repository: those files live here, under `user/` and `etc/`.
