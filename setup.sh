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
esc_tab="$(printf '\t')"
enum_is_tty=no
enum_step_rc=0
count_status_rows=0
count_status_cols=0
count_step_total=0
count_step_success=0
count_step_failed=0
count_manifest=0
name_step_current=""
path_run=""
path_setuplog=""
path_journal=""
[ -t 1 ] && [ -t 2 ] && command -v tput >/dev/null 2>&1 && enum_is_tty=yes

# ---------------------------------------------------------------- helpers

probe_path() {
    [ -L "$1" ] && { printf 'symlink\n'; return 0; }
    [ -d "$1" ] && { printf 'dir\n'; return 0; }
    [ -f "$1" ] && { printf 'file\n'; return 0; }
    [ -e "$1" ] && { printf 'other\n'; return 0; }
    printf 'absent\n'
}

journal_add() {
    case "$path_journal" in "") return 0 ;; esac
    printf '%s\n' "$*" >>"$path_journal"
}

run_as() {
    local scope="$1"
    shift
    case "$scope" in
        sudo) sudo "$@" ;;
        *) "$@" ;;
    esac
}

link() {
    local scope="$1" src="$2" dst="$3"
    local path_dir prefix
    case "$scope" in
        sudo) prefix=sudo_ ;;
        *) prefix="" ;;
    esac
    case "$(probe_path "$path_dot/$src")" in
        absent)
            printf 'link: source path "%s" does not exist\n' "$src" >&2
            return 1
            ;;
    esac
    path_dir="$(dirname "$dst")"
    case "$(probe_path "$path_dir")" in
        absent)
            journal_add "${prefix}rmdir$esc_tab$path_dir"
            run_as "$scope" mkdir -p "$path_dir"
            ;;
    esac
    case "$(probe_path "$dst")" in
        symlink) journal_add "${prefix}relink$esc_tab$dst$esc_tab$(readlink "$dst")" ;;
        *)       journal_add "${prefix}unlink$esc_tab$dst" ;;
    esac
    run_as "$scope" ln -sfn "$path_dot/$src" "$dst" 2>/dev/null ||
        run_as "$scope" cp -f "$path_dot/$src" "$dst"
}

log() {
    local level="$1" message="$2"
    case "$level" in
        info)    printf '%s✓%s %s\n' "$esc_green" "$esc_reset" "$message" ;;
        warning) printf '%s[WARN]%s %s\n' "$esc_yellow" "$esc_reset" "$message" >&2 ;;
        error)   printf '%s[ERROR]%s %s\n' "$esc_red" "$esc_reset" "$message" >&2 ;;
    esac
    case "$path_setuplog" in "") return 0 ;; esac
    printf '%s: %s\n' "$level" "$message" >>"$path_setuplog"
}

ask_password() {
    local path_tty secret_first secret_second
    path_tty=/dev/tty
    [ -r "$path_tty" ] || {
        printf 'account: no terminal available for password entry\n' >&2
        return 1
    }
    while :; do
        printf 'PASSWORD? ' >"$path_tty"
        stty -echo <"$path_tty"
        read -r secret_first <"$path_tty"
        stty echo <"$path_tty"
        printf '\n' >"$path_tty"
        printf 'PASSWORD (again)? ' >"$path_tty"
        stty -echo <"$path_tty"
        read -r secret_second <"$path_tty"
        stty echo <"$path_tty"
        printf '\n' >"$path_tty"
        case "$secret_first" in
            "")
                printf 'empty, try again\n' >"$path_tty"
                continue
                ;;
        esac
        case "$secret_first" in
            "$secret_second") break ;;
        esac
        printf 'mismatch, try again\n' >"$path_tty"
    done
    printf '%s' "$secret_first"
}

rollback_step() {
    local op target extra
    case "$path_journal" in "") return 0 ;; esac
    [ -s "$path_journal" ] || return 0
    sed '1!G;h;$!d' "$path_journal" |
    while IFS="$esc_tab" read -r op target extra; do
        case "$op" in
            unlink) rm -f "$target" ;;
            relink) ln -sfn "$extra" "$target" ;;
            rmdir) rmdir "$target" 2>/dev/null || true ;;
            sudo_unlink) sudo rm -f "$target" ;;
            sudo_relink) sudo ln -sfn "$extra" "$target" ;;
            sudo_rmdir) sudo rmdir "$target" 2>/dev/null || true ;;
        esac
    done
    : >"$path_journal"
}

report_notice() {
    local text
    text="$(sed -n 's/^info: //p' "$path_setuplog" | awk '!seen[$0]++')"
    case "$text" in "") return 0 ;; esac
    printf '%s\n' "$text" | sed "s/^/${esc_green}INFO:${esc_reset} /"
    printf '\n'
}

summarize_run() {
    local text
    text="$(sed 's/\x1b\[[0-9;]*m//g; s/^\[ERROR\] */error: /; s/^\[WARN\] */warning: /; /^secret: /d; /^info: /d; /^[[:space:]]*$/d' "$path_setuplog" |
        awk '!seen[$0]++')"
    case "$text" in
        "")
            printf 'NO WARNING.\n'
            return 0
            ;;
    esac
    printf '%s\n' "$text" |
        sed -e 's/^error: /ERROR: /' -e 's/^warning: /WARN: /' \
            -e "s/^\(ERROR:\)/${esc_red}\1${esc_reset}/" \
            -e "s/^\(WARN:\)/${esc_yellow}\1${esc_reset}/"
}

# ---------------------------------------------------------------- status line
# One line at the bottom of the terminal: current step on the left, [n/m] on
# the right. Everything else scrolls above it.

status_start() {
    local rows cols
    case "$enum_is_tty" in yes) ;; *) return 0 ;; esac
    rows="$(tput lines 2>/dev/null || printf '0')"
    cols="$(tput cols 2>/dev/null || printf '0')"
    case "$rows" in ''|*[!0-9]*) rows=0 ;; esac
    case "$cols" in ''|*[!0-9]*) cols=0 ;; esac
    if [ "$rows" -lt 3 ] || [ "$cols" -lt 20 ]; then
        enum_is_tty=no
        return 0
    fi
    count_status_rows="$rows"
    count_status_cols="$cols"
    printf '\n\033[1;%dr\033[%d;1H' "$((rows - 1))" "$((rows - 1))" >/dev/tty
}

status_draw() {
    local text_count width
    text_count="[$count_step_total/$count_manifest]"
    case "$enum_is_tty" in
        yes) ;;
        *)
            printf '%s %s\n' "$1" "$text_count"
            return 0
            ;;
    esac
    width=$((count_status_cols - ${#text_count} - 1))
    printf '\0337\033[%d;1H\033[2K%.*s\033[%d;%dH%s\0338' \
        "$count_status_rows" "$width" "$1" \
        "$count_status_rows" "$((count_status_cols - ${#text_count} + 1))" "$text_count" >/dev/tty
}

status_stop() {
    case "$count_status_rows" in 0) return 0 ;; esac
    printf '\0337\033[%d;1H\033[2K\033[r\0338' "$count_status_rows" >/dev/tty
    count_status_rows=0
}

# ---------------------------------------------------------------- lock / sudo

claim_lock() {
    case "$(command -v flock || true)" in "") return 0 ;; esac
    exec 9>"$path_lock"
    flock -n 9 && return 0
    log error "setup: another run is still active, and two runs fight over pacman and the terminal"
    log error "setup: see what holds it with fuser $path_lock, then wait for those or stop them"
    return 1
}

stash_sudo() {
    local secret count
    case "$(id -u)" in 0) return 0 ;; esac
    command sudo -k -n true 2>/dev/null && return 0
    count=0
    while [ "$count" -lt 3 ]; do
        printf 'SUDO PASSWORD? ' >/dev/tty
        stty -echo </dev/tty
        read -r secret </dev/tty
        stty echo </dev/tty
        printf '\n' >/dev/tty
        command sudo -k
        if printf '%s\n' "$secret" | command sudo -S -p '' -v 2>/dev/null; then
            printf 'secret: %s\n' "$secret" >>"$path_setuplog"
            printf '#!/bin/sh\nsed -n "s/^secret: //p" "%s"\n' "$path_setuplog" >"$path_run/askpass"
            chmod 700 "$path_run/askpass"
            export SUDO_ASKPASS="$path_run/askpass"
            sudo() { command sudo -A "$@"; }
            return 0
        fi
        count=$((count + 1))
        printf 'wrong password, try again\n' >/dev/tty
    done
    log error "sudo: wrong password 3 times"
    return 1
}

check_sudo() {
    local name_user
    case "$(id -u)" in
        0)
            case "$(command -v sudo || true)" in
                "") sudo() { "$@"; } ;;
            esac
            return 0
            ;;
    esac
    name_user="$(id -un)"
    case "$(command -v sudo || true)" in
        "")
            log error "sudo: not installed. As root: pacman -S sudo, then add $name_user to wheel"
            return 1
            ;;
    esac
    if sudo -n true 2>/dev/null; then
        stash_sudo
        return
    fi
    case " $(id -nG) " in
        *" wheel "*) ;;
        *)
            log error "sudo: $name_user is not in the wheel group, so sudo would refuse it"
            log error "sudo: fix as root: usermod -aG wheel $name_user && EDITOR=nvim visudo (uncomment %wheel ALL=(ALL:ALL) ALL), then log in again"
            return 1
            ;;
    esac
    stash_sudo && return 0
    log error "sudo: $name_user is in wheel but sudo refused it; as root: EDITOR=nvim visudo and uncomment %wheel ALL=(ALL:ALL) ALL"
    return 1
}

# ---------------------------------------------------------------- step runner

# $1 = label, $2 = what happened ("failed" / "interrupted")
undo_step() {
    case " $list_step_irreversible " in
        *" ${1#*/} "*)
            log error "$1: $2. This step cannot be rolled back; what it installed or downloaded stays." 2>/dev/null
            ;;
        *)
            rollback_step
            log warning "$1: $2, its changes were rolled back" 2>/dev/null
            ;;
    esac
}

# Runs one step in a subshell with set -e. Always returns 0 and leaves the
# step's exit status in enum_step_rc, because calling it from an if/&&/||
# would silently switch set -e off inside the step.
run_step() {
    local name_label="$1" name_step
    name_step="${name_label#*/}"
    name_step_current="$name_label"
    count_step_total=$((count_step_total + 1))
    status_draw "$name_label"
    path_journal="$path_run/$name_step.journal"
    : >"$path_journal"
    set +e
    ( set -e; "setup_$name_step" ) >/dev/null 2>>"$path_setuplog"
    enum_step_rc=$?
    set -e
    case "$enum_step_rc" in
        0)
            count_step_success=$((count_step_success + 1))
            ;;
        *)
            undo_step "$name_label" failed
            count_step_failed=$((count_step_failed + 1))
            ;;
    esac
    path_journal=""
    name_step_current=""
}

run_report() {
    status_stop
    printf '\nTotal: %d  Success: %d  Failed: %d  Not run: %d\n\n' \
        "$count_manifest" "$count_step_success" "$count_step_failed" \
        "$((count_manifest - count_step_total))"
    report_notice
    summarize_run
}

on_interrupt() {
    case "$name_step_current" in
        "") ;;
        *) undo_step "$name_step_current" interrupted ;;
    esac
    status_stop
    printf '\n%sinterrupted%s\n\n' "$esc_red" "$esc_reset" >&2
    summarize_run
    exit "$1"
}

on_exit() {
    status_stop
    case "$path_run" in "") ;; *) rm -rf "$path_run" ;; esac
}

# ---------------------------------------------------------------- preparation
# Every tool the configuration steps rely on is installed here. If any of
# these fails, the run stops before touching configuration.

setup_check() {
    local cmd missing
    missing=""
    for cmd in pacman curl timedatectl ssh-keygen stty; do
        case "$(command -v "$cmd" || true)" in
            "") missing="$missing $cmd" ;;
        esac
    done
    case "$missing" in
        ?*)
            log error "check: missing commands:$missing"
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
    log info "packages: installed"
}

bootstrap_paru() {
    local path_work
    path_work="$(mktemp -d)"
    git clone -q "$uri_aur" "$path_work/paru"
    cd "$path_work/paru"
    set -- $(makepkg --printsrcinfo |
        awk '/^[[:space:]]*(make)?depends(_[a-z0-9_]+)? =/ {
            sub(/[<>=].*/, "", $3); print $3
        }' | sort -u)
    case "$#" in
        0) ;;
        *) sudo pacman -S --needed --noconfirm --asdeps "$@" >/dev/null ;;
    esac
    bash -c '. /etc/makepkg.conf
for path_dest in "${PKGDEST:-}" "${SRCDEST:-}" "${LOGDEST:-}" "${BUILDDIR:-}"; do
    case "$path_dest" in
        "") continue ;;
    esac
    mkdir -p "$path_dest"
done'
    makepkg --force --noconfirm >/dev/null
    set -- $(makepkg --packagelist | grep -v -- '-debug-' || true)
    case "$#" in
        0)
            log error "aur: makepkg produced no paru package"
            return 1
            ;;
    esac
    sudo pacman -U --noconfirm "$@" >/dev/null
    cd /
    rm -rf "$path_work"
    log info "aur: paru installed"
}

setup_aur() {
    case "$(command -v paru || true)" in
        "") bootstrap_paru ;;
        *) paru -Sua --noconfirm --sudoflags=-A >/dev/null ;;
    esac
    paru -S --needed --noconfirm --sudoflags=-A google-chrome >/dev/null
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

# ---------------------------------------------------------------- configuration
# Tools are guaranteed to exist from here on. Each step may fail on its own;
# the others still run.

setup_account() {
    local path_shell
    path_shell="$(command -v zsh)"
    case "$(id -u "$name_main_user" 2>/dev/null || true)" in
        "") sudo useradd --create-home --groups wheel --shell "$path_shell" "$name_main_user" ;;
        *) sudo usermod -aG wheel -s "$path_shell" "$name_main_user" ;;
    esac
    case "$(sudo passwd -S "$name_main_user" | awk '{print $2}')" in
        P) ;;
        *) printf '%s:%s\n' "$name_main_user" "$(ask_password)" | sudo chpasswd ;;
    esac
    printf '%%wheel ALL=(ALL:ALL) ALL\n' | sudo tee /etc/sudoers.d/10-wheel >/dev/null
    sudo chmod 0440 /etc/sudoers.d/10-wheel
    sudo visudo -c >/dev/null && return 0
    sudo rm -f /etc/sudoers.d/10-wheel
    log error "account: wheel sudoers drop-in rejected"
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
        log info "git-ssh: key already exists"
    else
        ssh-keygen -q -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
        log info "git-ssh: key generated"
    fi
    log info "git-ssh: public key: $(cat "$HOME/.ssh/id_ed25519.pub")"
}

setup_shell() {
    link user home/.zshrc "$HOME/.zshrc"
}

setup_nvim() {
    local path_lazy_nvim
    link user home/nvim/init.lua "$path_config/nvim/init.lua"
    link user home/nvim/lazylock.json "$path_config/nvim/lazylock.json"
    [ -L "$path_config/nvim/lazy-lock.json" ] && rm -f "$path_config/nvim/lazy-lock.json"
    path_lazy_nvim="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
    if [ -d "$path_lazy_nvim/.git" ]; then
        git -C "$path_lazy_nvim" fetch -q --tags --force origin
        git -C "$path_lazy_nvim" checkout -q stable
    else
        log warning "nvim: lazy.nvim absent, init.lua will clone it"
    fi
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1
}

setup_fcitx5() {
    local name_fcitx5_conf
    link user home/fcitx5/profile "$path_config/fcitx5/profile"
    link user home/fcitx5/config "$path_config/fcitx5/config"
    for name_fcitx5_conf in chttrans classicui clipboard hangul pinyin punctuation spell unicode waylandim; do
        link user "home/fcitx5/$name_fcitx5_conf.conf" "$path_config/fcitx5/conf/$name_fcitx5_conf.conf"
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

# ---------------------------------------------------------------- main

main() {
    local name_label
    claim_lock || exit 1
    for name_label in $list_prep_label $list_step_label; do
        count_manifest=$((count_manifest + 1))
    done
    printf '\n%s\n\n' "complete-works Setup Script"
    path_run="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/setup.XXXXXX")"
    path_setuplog="$path_run/setuplog"
    ( umask 077; : >"$path_setuplog" )
    trap 'on_interrupt 130' INT
    trap 'on_interrupt 143' TERM
    trap 'on_interrupt 129' HUP
    trap on_exit EXIT
    check_sudo || exit 1
    status_start

    for name_label in $list_prep_label; do
        run_step "$name_label"
        case "$enum_step_rc" in
            0) ;;
            *)
                log error "setup: preparation failed at ${name_label#*/}; no configuration step was run" 2>/dev/null
                run_report
                exit 1
                ;;
        esac
    done

    for name_label in $list_step_label; do
        run_step "$name_label"
    done

    run_report
    case "$count_step_failed" in 0) ;; *) exit 1 ;; esac
}

list_prep_label="prep/check prep/git repo/git_sync sysconfig/pacman_config \
    package/packages package/aur package/node package/python"
list_step_label="system/account system/time sysconfig/system_config \
    userconfig/paru_conf userconfig/chrome \
    repo/git_ssh \
    userconfig/shell userconfig/nvim userconfig/fcitx5 userconfig/hypr \
    userconfig/git_config"
list_step_irreversible="check git git_sync pack