#!/bin/sh
# Run as root by etc/wrap-hyprctl.hook (a pacman PostTransaction hook on the
# hyprland package). Every hyprland install/upgrade reinstalls a pristine,
# unguarded /usr/bin/hyprctl -- this makes /usr/bin/hyprctl the guard
# (etc/hyprctl-guard) again, and keeps the real binary reachable at
# /usr/bin/hyprctl.real. Idempotent: safe to run when already applied.
set -e

target="/usr/bin/hyprctl"
real="/usr/bin/hyprctl.real"
guard="/etc/hyprctl-guard"

if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$guard")" ]; then
    exit 0
fi

mv -f "$target" "$real"
ln -sfn "$guard" "$target"
