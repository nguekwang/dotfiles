#!/bin/sh
set -e
path_dot="$HOME/dotfiles"
path_config="${XDG_CONFIG_HOME:-$HOME/.config}"
path_etc="/etc"
path_rows="$path_dot/links.list"

link() {
    local src="$path_dot/$2"
    local dst="$3"
    local cmd_sudo=""
    [ "$1" = sudo ] && cmd_sudo=sudo
    [ -e "$src" ] || [ -L "$src" ] || {
        printf 'error: link: source "%s" does not exist\n' "$2" >&2
        return 1
    }
    $cmd_sudo mkdir -p "$(dirname "$dst")"
    $cmd_sudo ln -sfn "$src" "$dst"
}

while read -r enum_mode path_src enum_root path_rel; do
    case "$enum_root" in
        etc) path_base="$path_etc" ;;
        config) path_base="$path_config" ;;
        home) path_base="$HOME" ;;
    esac
    link "$enum_mode" "$path_src" "$path_base/$path_rel"
done < "$path_rows"
