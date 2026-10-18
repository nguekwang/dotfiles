#!/bin/sh
set -e
path_dot="$HOME/dotfiles"
path_rows="$path_dot/pkg.list"
uri_aur="https://aur.archlinux.org/paru.git"
list_pacman=""
list_aur=""

while read -r enum_source name_pkg; do
    case "$enum_source" in
        pacman) list_pacman="$list_pacman $name_pkg" ;;
        aur) list_aur="$list_aur $name_pkg" ;;
    esac
done < "$path_rows"

sudo pacman -Syu --needed --noconfirm $list_pacman >/dev/null
printf 'info: pkg: packages installed\n' >&2

if command -v paru >/dev/null; then
    paru -Sua --noconfirm >/dev/null
else
    path_work="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/pkg.XXXXXX")"
    trap 'rm -rf "$path_work"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    git clone -q "$uri_aur" "$path_work/paru"
    bash -c '. /etc/makepkg.conf
for path_dest in "${PKGDEST:-}" "${SRCDEST:-}" "${LOGDEST:-}" "${BUILDDIR:-}"; do
    [ -z "$path_dest" ] || mkdir -p "$path_dest"
done'
    (cd "$path_work/paru" && makepkg -si --noconfirm >/dev/null)
    printf 'info: pkg: paru installed\n' >&2
fi

paru -S --needed --noconfirm $list_aur >/dev/null
