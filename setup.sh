#!/bin/sh
set -e
name_main_user="${name_main_user:-nguekwang}"
path_dot="$HOME/dotfiles"
path_config="${XDG_CONFIG_HOME:-$HOME/.config}"
path_etc="/etc"
path_lock="${XDG_RUNTIME_DIR:-/tmp}/complete-works.lock"
name_time_zone="Asia/Tokyo"
uri_aur="https://aur.archlinux.org/paru.git"
uri_repo="https://github.com/nguekwang/dotfiles.git"
uri_push="git@github.com:nguekwang/dotfiles.git"
esc_red="$(printf '\033[1;31m')"
esc_green="$(printf '\033[1;32m')"
esc_yellow="$(printf '\033[1;33m')"
esc_reset="$(printf '\033[0m')"

# Preparation: installs every tool. The first failure stops the whole run.
list_prep_label="prep/check prep/git repo/git_sync sysconfig/pacman_config \
    package/packages package/aur package/node package/python"
# Configuration: assumes the tools exist. A failure here does not stop the rest.
list_step_label="system/account system/time sysconfig/system_config \
    userconfig/paru_conf userconfig/chrome \
    repo/git_ssh \
    userconfig/shell userconfig/claude userconfig/nvim userconfig/fcitx5 userconfig/hypr \
    userconfig/git_config"

count_status_rows=0
count_status_cols=0
count_step_total=0
count_step_success=0
count_step_failed=0
count_manifest=0
pid_keepalive=""
path_run=""
path_setuplog=""

# Nothing is rolled back: whatever a step changed stays, even if it fails.
#
# Steps report through stderr, which goes to the setup log:
#   printf 'info: ...\n' >&2      shown in the final INFO list
#   printf 'warning: ...\n' >&2   shown in the final WARN list
#   printf 'error: ...\n' >&2     shown in the final ERROR list

# ================================================================ helpers

# link <user|sudo> <path under dotfiles> <destination>
# Replaces the destination with a symlink to the dotfile.
link() {
    local src="$path_dot/$2" dst="$3" cmd_sudo=""
    case "$1" in sudo) cmd_sudo=sudo ;; esac
    [ -e "$src" ] || [ -L "$src" ] || {
        printf 'error: link: source "%s" does not exist\n' "$2" >&2
        return 1
    }
    $cmd_sudo mkdir -p "$(dirname "$dst")"
    $cmd_sudo ln -sfn "$src" "$dst"
}

# Runs on every exit: stops the sudo keepalive, frees the status line,
# prints the report and removes the run directory.
on_exit() {
    local text
    case "$pid_keepalive" in ?*) kill "$pid_keepalive" 2>/dev/null || true ;; esac
    case "$count_status_rows" in
        0) ;;
        *) printf '\0337\033[%d;1H\033[2K\033[r\0338' "$count_status_rows" >/dev/tty ;;
    esac
    case "$path_setuplog" in "") return 0 ;; esac
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

# ================================================================ preparation

setup_check() {
    missing=""
    for cmd in pacman curl timedatectl ssh-keygen; do
        case "$(command -v "$cmd" || true)" in
            "") missing="$missing $cmd" ;;
        esac
    done
    case "$missing" in
        ?*)
            printf 'error: check: missing commands:%s\n' "$missing" >&2
            return 1
            ;;
    esac
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

setup_pacman_config() {
    link sudo etc/pacman.conf "$path_etc/pacman.conf"
    link sudo etc/mirrorlist "$path_etc/pacman.d/mirrorlist"
    link sudo etc/makepkg.conf "$path_etc/makepkg.conf"
}

setup_packages() {
    sudo pacman -Syu --needed --noconfirm base-devel git zsh neovim >/dev/null
    printf 'info: packages: installed\n' >&2
}

setup_aur() {
    case "$(command -v paru || true)" in
        "")
            path_work="$(mktemp -d)"
            git clone -q "$uri_aur" "$path_work/paru"
            bash -c '. /etc/makepkg.conf
for path_dest in "${PKGDEST:-}" "${SRCDEST:-}" "${LOGDEST:-}" "${BUILDDIR:-}"; do
    [ -z "$path_dest" ] || mkdir -p "$path_dest"
done'
            cd "$path_work/paru"
            makepkg -si --noconfirm >/dev/null
            cd /
            rm -rf "$path_work"
            printf 'info: aur: paru installed\n' >&2
            ;;
        *)
            paru -Sua --noconfirm >/dev/null
            ;;
    esac
    paru -S --needed --noconfirm google-chrome >/dev/null
}

setup_node() {
    case "$(command -v bun || true)" in
        "")
            curl -fsSL https://bun.sh/install -o "$path_run/bun-install.sh"
            bash "$path_run/bun-install.sh" >/dev/null
            export PATH="$HOME/.bun/bin:$PATH"
            ;;
        *)
            bun upgrade >/dev/null
            ;;
    esac
    bun add -g --silent @google/gemini-cli@latest @openai/codex@latest >/dev/null
}

setup_python() {
    case "$(command -v uv || true)" in
        "")
            curl -fsSL https://astral.sh/uv/install.sh -o "$path_run/uv-install.sh"
            sh "$path_run/uv-install.sh" >/dev/null
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        *)
            uv self update -q
            ;;
    esac
    uv tool install -q --upgrade ipython --with keras --with matplotlib
}

# ================================================================ configuration

setup_account() {
    path_shell="$(command -v zsh)"
    case "$(id -u "$name_main_user" 2>/dev/null || true)" in
        "") sudo useradd --create-home --groups wheel --shell "$path_shell" "$name_main_user" ;;
        *) sudo usermod -aG wheel -s "$path_shell" "$name_main_user" ;;
    esac
    case "$(sudo passwd -S "$name_main_user" | awk '{print $2}')" in
        P) ;;
        *) sudo passwd "$name_main_user" </dev/tty >/dev/tty 2>&1 ;;
    esac
    printf '%%wheel ALL=(ALL:ALL) ALL\n' | sudo tee /etc/sudoers.d/10-wheel >/dev/null
    sudo chmod 0440 /etc/sudoers.d/10-wheel
    sudo visudo -c >/dev/null && return 0
    sudo rm -f /etc/sudoers.d/10-wheel
    printf 'error: account: wheel sudoers drop-in rejected\n' >&2
    return 1
}

setup_time() {
    case "$(timedatectl show -p Timezone --value):$(timedatectl show -p NTP --value)" in
        "$name_time_zone:yes") return 0 ;;
    esac
    sudo timedatectl set-timezone "$name_time_zone"
    sudo timedatectl set-ntp true
}

setup_system_config() {
    link sudo etc/locale.conf "$path_etc/locale.conf"
    link sudo etc/vconsole.conf "$path_etc/vconsole.conf"
    link sudo etc/mkinitcpio.conf "$path_etc/mkinitcpio.conf"
    link sudo etc/sysctld-lowswap.conf "$path_etc/sysctl.d/99-lowswap.conf"
    link sudo etc/sysctld-file-watchers.conf "$path_etc/sysctl.d/90-file-watchers.conf"
    link sudo etc/ssh-keepalive.conf "$path_etc/ssh/ssh_config.d/20-keepalive.conf"
    link sudo etc/hyprctl-guard "$path_etc/hyprctl-guard"
    link sudo etc/wrap-hyprctl-install.sh "$path_etc/hyprctl-guard-install.sh"
    link sudo etc/wrap-hyprctl.hook "$path_etc/pacman.d/hooks/wrap-hyprctl.hook"
    sudo "$path_etc/hyprctl-guard-install.sh"
}

setup_paru_conf() {
    link user home/paru/paru.conf "$path_config/paru/paru.conf"
}

setup_chrome() {
    link user home/browser/chrome-flags.conf "$path_config/chrome-flags.conf"
    link sudo etc/chrome-policy-restore-tabs.json "$path_etc/opt/chrome/policies/managed/restore-tabs.json"
}

setup_git_ssh() {
    link user etc/sshconfig "$HOME/.ssh/config"
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        printf 'info: git-ssh: key already exists\n' >&2
    else
        ssh-keygen -q -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
        printf 'info: git-ssh: key generated\n' >&2
    fi
    printf 'info: git-ssh: public key: %s\n' "$(cat "$HOME/.ssh/id_ed25519.pub")" >&2
}

setup_shell() {
    link user home/.zshrc "$HOME/.zshrc"
}

setup_claude() {
    link user home/claude/settings.json "$HOME/.claude/settings.json"
}

setup_nvim() {
    link user home/nvim/init.lua "$path_config/nvim/init.lua"
    link user home/nvim/lazylock.json "$path_config/nvim/lazylock.json"
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

setup_fcitx5() {
    link user home/fcitx5/profile "$path_config/fcitx5/profile"
    link user home/fcitx5/config "$path_config/fcitx5/config"
    for name_conf in chttrans classicui clipboard hangul pinyin punctuation spell unicode waylandim; do
        link user "home/fcitx5/$name_conf.conf" "$path_config/fcitx5/conf/$name_conf.conf"
    done
}

setup_hypr() {
    link user home/hypr/hyprland.lua "$path_config/hypr/hyprland.lua"
    link user home/hypr/mako "$path_config/mako/config"
    link user home/hypr/foot.ini "$path_config/foot/foot.ini"
    link user home/hypr/waybar-config "$path_config/waybar/config"
    link user home/hypr/waybar-style.css "$path_config/waybar/style.css"
    link user home/browser/qutebrowser.py "$path_config/qutebrowser/config.py"
}

setup_git_config() {
    link user home/.gitconfig "$HOME/.gitconfig"
    link user home/.gitignore-global "$HOME/.gitignore-global"
    link user home/.githooks "$HOME/.githooks"
    link user home/.gitmessage "$HOME/.gitmessage"
    link user home/.gitconfig-paru "$HOME/.gitconfig-paru"
}

# ================================================================ main

printf '\n%s\n\n' "complete-works Setup Script"

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

for name_label in $list_prep_label $list_step_label; do
    count_manifest=$((count_manifest + 1))
done
path_run="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/setup.XXXXXX")"
path_setuplog="$path_run/setuplog"
( umask 077; : >"$path_setuplog" )
# The signal traps only make sure on_exit runs; nothing is undone.
trap 'printf "error: interrupted\n" >>"$path_setuplog"; exit 130' INT
trap 'printf "error: terminated\n" >>"$path_setuplog"; exit 143' TERM
trap 'printf "error: hung up\n" >>"$path_setuplog"; exit 129' HUP
trap on_exit EXIT

# Keep the sudo timestamp fresh so long builds never hit a password prompt.
while :; do sudo -n -v 2>/dev/null || true; sleep 60; done &
pid_keepalive=$!

# Reserve the bottom line of the terminal for the status line.
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

for name_label in $list_prep_label $list_step_label; do
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

    # The step runs as a plain command (never inside if/&&/||), so set -e
    # stays in force inside it.
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
