#!/bin/sh
set -e
name_main_user="${name_main_user:-nguekwang}"
path_dot="$HOME/dotfiles"
path_config="${XDG_CONFIG_HOME:-$HOME/.config}"
path_etc="/etc"
path_lock="${XDG_RUNTIME_DIR:-/tmp}/dotfiles.lock"
name_time_zone="Asia/Tokyo"
uri_repo="https://github.com/nguekwang/dotfiles.git"
uri_push="git@github.com:nguekwang/dotfiles.git"
esc_red="$(printf '\033[1;31m')"
esc_green="$(printf '\033[1;32m')"
esc_yellow="$(printf '\033[1;33m')"
esc_reset="$(printf '\033[0m')"

list_prep_label="prep/check prep/git repo/git_sync \
    package/claude package/python"
list_step_label="system/account system/time sysconfig/system_config \
    repo/git_ssh userconfig/nvim"

count_status_rows=0
count_status_cols=0
count_step_total=0
count_step_success=0
count_step_failed=0
pid_keepalive=""
path_run=""
path_setuplog=""

on_exit() {
    local text
    kill "$pid_keepalive" 2>/dev/null || true
    [ "$count_status_rows" = 0 ] || printf '\0337\033[%d;1H\033[2K\033[r\0338' "$count_status_rows" >/dev/tty
    [ -n "$path_setuplog" ] || return 0
    printf '\nTotal: %d  Success: %d  Failed: %d  Not run: %d\n\n' \
        "$count_manifest" "$count_step_success" "$count_step_failed" \
        "$((count_manifest - count_step_total))"
    text="$(sed -n 's/^info: //p' "$path_setuplog" | awk '!seen[$0]++')"
    case "$text" in
        ?*) printf '%s\n\n' "$text" | sed "s/^./${esc_green}INFO:${esc_reset} &/" ;;
    esac
    text="$(sed -e 's/\x1b\[[0-9;]*m//g' -e '/^info: /d' -e '/^[[:space:]]*$/d' "$path_setuplog" |
        awk '!seen[$0]++')"
    case "$text" in
        "") printf 'NO WARNING.\n' ;;
        *)
            printf '%s\n' "$text" |
                sed -e "s/^error: /${esc_red}ERROR:${esc_reset} /" \
                    -e "s/^warning: /${esc_yellow}WARN:${esc_reset} /"
            ;;
    esac
    rm -rf "$path_run"
}

setup_check() {
    for cmd in pacman curl timedatectl ssh-keygen; do
        command -v "$cmd" >/dev/null || missing="$missing $cmd"
    done
    [ -z "$missing" ] || { printf 'error: check: missing commands:%s\n' "$missing" >&2; return 1; }
    curl -fsS -o /dev/null --max-time 10 https://aur.archlinux.org
}

setup_git() {
    sudo pacman -Syu --needed --noconfirm git >/dev/null
}

setup_git_sync() {
    if [ -d "$path_dot/.git" ]; then
        git -C "$path_dot" pull -q --ff-only
    else
        git clone -q -c remote.origin.pushurl="$uri_push" "$uri_repo" "$path_dot"
    fi
}

setup_claude() {
    if command -v claude >/dev/null; then
        claude update >/dev/null
    else
        curl -fsSL https://claude.ai/install.sh -o "$path_run/claude-install.sh"
        bash "$path_run/claude-install.sh" >/dev/null
    fi
}

setup_python() {
    if command -v uv >/dev/null; then
        uv self update -q
    else
        curl -fsSL https://astral.sh/uv/install.sh -o "$path_run/uv-install.sh"
        sh "$path_run/uv-install.sh" >/dev/null
        export PATH="$HOME/.local/bin:$PATH"
    fi
    uv tool install -q --upgrade ipython --with keras --with matplotlib
}

setup_account() {
    path_shell="$(command -v bash)"
    if id "$name_main_user" >/dev/null 2>&1; then
        sudo usermod -aG wheel -s "$path_shell" "$name_main_user"
    else
        sudo useradd --create-home --groups wheel --shell "$path_shell" "$name_main_user"
    fi
    case "$(sudo passwd -S "$name_main_user" | awk '{print $2}')" in
        P) ;;
        *) sudo passwd "$name_main_user" </dev/tty >/dev/tty 2>&1 ;;
    esac
    printf '%%wheel ALL=(ALL:ALL) ALL\n' | sudo tee /etc/sudoers.d/10-wheel >/dev/null
    sudo chmod 0440 /etc/sudoers.d/10-wheel
    sudo visudo -c >/dev/null || {
        sudo rm -f /etc/sudoers.d/10-wheel
        printf 'error: account: wheel sudoers drop-in rejected\n' >&2
        return 1
    }
}

setup_time() {
    case "$(timedatectl show -p Timezone --value):$(timedatectl show -p NTP --value)" in
        "$name_time_zone:yes") return 0 ;;
    esac
    sudo timedatectl set-timezone "$name_time_zone"
    sudo timedatectl set-ntp true
}

setup_system_config() {
    sudo "$path_etc/hyprctl-guard-install.sh"
}

setup_git_ssh() {
    mkdir -p "$HOME/.ssh"
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        printf 'info: git-ssh: key already exists\n' >&2
    else
        ssh-keygen -q -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
        printf 'info: git-ssh: key generated\n' >&2
    fi
    printf 'info: git-ssh: public key: %s\n' "$(cat "$HOME/.ssh/id_ed25519.pub")" >&2
}

setup_nvim() {
    [ -L "$path_config/nvim/lazy-lock.json" ] && rm -f "$path_config/nvim/lazy-lock.json"
    path_lazy_nvim="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
    if [ -d "$path_lazy_nvim/.git" ]; then
        git -C "$path_lazy_nvim" fetch -q --tags --force origin
        git -C "$path_lazy_nvim" checkout -q stable
    else
        printf 'warning: nvim: lazy.nvim absent, init.lua will clone it\n' >&2
    fi
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1
}

printf '\n%s\n\n' "dotfiles Setup Script"

case "$(id -u)" in
    0)
        printf '%s[ERROR]%s run this as your normal user, not root (makepkg refuses to run as root)\n' \
            "$esc_red" "$esc_reset" >&2
        exit 1
        ;;
esac

if command -v flock >/dev/null 2>&1; then
    exec 9>"$path_lock"
    flock -n 9 || {
        printf '%s[ERROR]%s another run is still active; see what holds it with: fuser %s\n' \
            "$esc_red" "$esc_reset" "$path_lock" >&2
        exit 1
    }
fi

sudo -v || {
    printf '%s[ERROR]%s sudo refused. As root: usermod -aG wheel %s && EDITOR=nvim visudo (uncomment %%wheel ALL=(ALL:ALL) ALL), then log in again\n' \
        "$esc_red" "$esc_reset" "$(id -un)" >&2
    exit 1
}

set -- $list_prep_label $list_step_label
count_manifest=$#
path_run="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/setup.XXXXXX")"
path_setuplog="$path_run/setuplog"
( umask 077; : >"$path_setuplog" )
trap 'printf "error: interrupted\n" >>"$path_setuplog"; exit 130' INT
trap 'printf "error: terminated\n" >>"$path_setuplog"; exit 143' TERM
trap 'printf "error: hung up\n" >>"$path_setuplog"; exit 129' HUP
trap on_exit EXIT

while :; do sudo -n -v 2>/dev/null || true; sleep 60; done &
pid_keepalive=$!

if [ -t 1 ] && [ -t 2 ]; then
    rows="$(tput lines 2>/dev/null || printf '0')"
    cols="$(tput cols 2>/dev/null || printf '0')"
    case "$rows" in ''|*[!0-9]*) rows=0 ;; esac
    case "$cols" in ''|*[!0-9]*) cols=0 ;; esac
    if [ "$rows" -ge 3 ] && [ "$cols" -ge 20 ]; then
        count_status_rows="$rows"
        count_status_cols="$cols"
        printf '\n\033[1;%dr\033[%d;1H' "$((rows - 1))" "$((rows - 1))" >/dev/tty
    fi
fi

for name_label in "$@"; do
    name_step="${name_label#*/}"
    count_step_total=$((count_step_total + 1))

    text_count="[$count_step_total/$count_manifest]"
    case "$count_status_rows" in
        0) printf '%s %s\n' "$name_label" "$text_count" ;;
        *)
            printf '\0337\033[%d;1H\033[2K%.*s\033[%d;%dH%s\0338' \
                "$count_status_rows" "$((count_status_cols - ${#text_count} - 1))" "$name_label" \
                "$count_status_rows" "$((count_status_cols - ${#text_count} + 1))" "$text_count" >/dev/tty
            ;;
    esac

    set +e
    ( set -e; "setup_$name_step" ) >/dev/null 2>>"$path_setuplog"
    enum_rc=$?
    set -e

    case "$enum_rc" in
        0)
            count_step_success=$((count_step_success + 1))
            ;;
        *)
            printf 'error: %s: failed\n' "$name_label" >>"$path_setuplog"
            count_step_failed=$((count_step_failed + 1))
            case " $list_prep_label " in
                *" $name_label "*)
                    printf 'error: setup: preparation failed at %s; no configuration step was run\n' \
                        "$name_step" >>"$path_setuplog"
                    exit 1
                    ;;
            esac
            ;;
    esac
done

case "$count_step_failed" in 0) ;; *) exit 1 ;; esac
