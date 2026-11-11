---
name: installation-steps
description: Presenting installation steps as copy-pasteable Arch Linux commands (pacman, AUR/paru, git+docker, Wine). Use whenever you present the steps to install a package or application on this user's machine.
---

# Rules for Presenting Installation Steps

Present installation as copy-pasteable commands for the selected method. Which method to select is governed by the `tool-evaluation-installation` skill; this skill governs how to render the steps.

- Present complete commands that are executable by copy-paste alone.
- Use only commands suited to Arch Linux.
- Explanations premised on apt / brew are prohibited.

## pacman

```shell
sudo pacman -S <package>
```

## AUR

```shell
paru -S <package>
```

## git + docker

```shell
git clone <repository>
cd <repository>
docker compose up -d
```

## Wine

```shell
mkdir -p ~/.wine-<appname>
wget <url> or curl -LO <url>
WINEPREFIX=$HOME/.wine-<appname> wine <installer>
```
