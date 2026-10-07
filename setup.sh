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
esc_blue="$(printf '\033[1;34m')"
esc_reset="$(printf '\033[0m')"
esc_cyan="$(printf '\033[1;36m')"
enum_is_tty=no
enum_sleep_frac=no
count_status_rows=0
index_step=0
count_step_total=0
count_step_success=0
count_step_failed=0
count_step_skipped=0
count_manifest=0
count_link_failed=0
name_step_current=""
list_step_state=""
row_manifest_top=0
row_wave=0
pid_wave=""
pid_keepalive=""
path_run=""
pid_main=$$
[ -t 1 ] && [ -t 2 ] && command -v tput >/dev/null 2>&1 && enum_is_tty=yes
sleep 0.01 2>/dev/null && enum_sleep_frac=yes

render_elapsed() {
    local total
    total=$(( $(date +%s) - $1 ))
    if [ "$total" -lt 60 ]; then
        printf '%ds' "$total"
    else
        printf '%dm%02ds' "$((total / 60))" "$((total % 60))"
    fi
}

render_row() {
    case "$1" in
        done)    printf '%s[✓]%s %s' "$esc_green" "$esc_reset" "$2" ;;
        failed)  printf '%s[✘]%s %s' "$esc_red" "$esc_reset" "$2" ;;
        skipped) printf '%s[-] %s%s' "$esc_blue" "$2" "$esc_reset" ;;
        *)       printf '[ ] %s' "$2" ;;
    esac
}

report_failure() {
    local line
    render_row failed "$1"
    printf '\n'
    case "$(probe_path "$2")" in
        file) ;;
        *) return 0 ;;
    esac
    while IFS= read -r line; do
        case "$line" in
            "") continue ;;
        esac
        printf '  - %s\n' "$line"
    done <"$2"
}

wave_frame() {
    awk -v s="$1" -v p="$2" 'BEGIN {
        n = length(s)
        crest = p % (n + 10)
        split("231 159 123 87 51 45 38 32 31 30", ramp, " ")
        out = ""
        for (i = 1; i <= n; i++) {
            d = i - crest
            if (d < 0) d = -d
            if (d > 9) d = 9
            out = out "\033[1;38;5;" ramp[d + 1] "m" substr(s, i, 1)
        }
        printf "%s\033[0m", out
    }'
}

wave_start() {
    local phase time_start
    case "$enum_is_tty:$enum_sleep_frac" in yes:yes) ;; *) return 0 ;; esac
    time_start="$(date +%s)"
    (
        phase=0
        while kill -0 "$pid_main" 2>/dev/null; do
            printf '\0337\033[%d;1H\033[2K  %s %s%s%s\0338' \
                "$row_wave" "$(wave_frame "$1" "$phase")" \
                "$esc_cyan" "$(render_elapsed "$time_start")" "$esc_reset" >/dev/tty
            phase=$((phase + 1))
            sleep 0.08
        done
    ) &
    pid_wave=$!
}

wave_stop() {
    case "$pid_wave" in "") return 0 ;; esac
    kill "$pid_wave" 2>/dev/null || true
    wait "$pid_wave" 2>/dev/null || true
    pid_wave=""
    case "$enum_is_tty" in
        yes) printf '\0337\033[%d;1H\033[2K\0338' "$row_wave" >/dev/tty ;;
    esac
}

manifest_draw() {
    local entry mark label row
    case "$enum_is_tty" in yes) ;; *) return 0 ;; esac
    row="$row_manifest_top"
    printf '\0337' >/dev/tty
    for entry in $list_step_state; do
        mark="${entry%%:*}"
        label="${entry#*:}"
        printf '\033[%d;1H\033[2K%s' "$row" "$(render_row "$mark" "$label")" >/dev/tty
        row=$((row + 1))
    done
    printf '\0338' >/dev/tty
}

manifest_print() {
    local entry
    for entry in $list_step_state; do
        render_row "${entry%%:*}" "${entry#*:}"
        printf '\n'
    done
}

manifest_set() {
    local entry rebuilt
    rebuilt=""
    for entry in $list_step_state; do
        case "${entry#*:}" in
            "$1") rebuilt="$rebuilt ${2}:${1}" ;;
            *) rebuilt="$rebuilt $entry" ;;
        esac
    done
    list_step_state="$rebuilt"
    manifest_draw
}

status_start() {
    local rows
    case "$enum_is_tty" in yes) ;; *) return 0 ;; esac
    rows="$(tput lines 2>/dev/null || printf '0')"
    case "$rows" in ''|*[!0-9]*) enum_is_tty=no; return 0 ;; esac
    if [ "$rows" -lt $((count_manifest + 5)) ]; then
        enum_is_tty=no
        return 0
    fi
    count_status_rows="$rows"
    row_wave="$rows"
    row_manifest_top=$((rows - count_manifest))
    printf '\033[1;%dr' "$((row_manifest_top - 1))" >/dev/tty
    printf '\033[%d;1H' "$((row_manifest_top - 1))" >/dev/tty
}

status_stop() {
    wave_stop
    case "$count_status_rows" in 0) return 0 ;; esac
    printf '\033[1;%dr\033[%d;1H\033[J' "$count_status_rows" "$row_manifest_top" >/dev/tty
    count_status_rows=0
}
path_finding=""
record_finding() {
    case "$path_finding" in "") return 0 ;; esac
    printf '%s\n' "$1" >>"$path_finding"
}

log() {
    local level="$1" message="$2"
    case "$level" in
        info)
            printf '%s✓%s %s\n' "$esc_green" "$esc_reset" "$message"
            record_finding "info: $message"
            ;;
        warning)
            printf '%s[WARN]%s %s\n' "$esc_yellow" "$esc_reset" "$message" >&2
            record_finding "warning: $message"
            ;;
        error)
            printf '%s[ERROR]%s %s\n' "$esc_red" "$esc_reset" "$message" >&2
            record_finding "error: $message"
            ;;
    esac
}

path_journal=""
esc_tab="$(printf '\t')"

journal_add() {
    case "$path_journal" in "") return 0 ;; esac
    printf '%s\n' "$*" >>"$path_journal"
}

rollback_step() {
    local line op target extra
    case "$path_journal" in "") return 0 ;; esac
    case "$(probe_path "$path_journal")" in file) ;; *) return 0 ;; esac
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

probe_path() {
    [ -L "$1" ] && { printf 'symlink\n'; return 0; }
    [ -d "$1" ] && { printf 'dir\n'; return 0; }
    [ -f "$1" ] && { printf 'file\n'; return 0; }
    [ -e "$1" ] && { printf 'other\n'; return 0; }
    printf 'absent\n'
}

probe_read_access() {
    [ -r "$1" ] && { printf 'yes\n'; return 0; }
    printf 'no\n'
}

link() {
    local scope="$1" src="$2" dst="$3"
    local path_dir journal_prefix cmd
    journal_prefix=$([ "$scope" = sudo ] && echo sudo_ || echo "")
    cmd() { [ "$scope" = sudo ] && sudo "$@" || "$@"; }

    case "$(probe_path "$path_dot/$src")" in
        absent)
            count_link_failed=$((count_link_failed + 1))
            log error "source path \"$src\" does not exist"
            return 1
            ;;
    esac

    path_dir="$(dirname "$dst")"
    case "$(probe_path "$path_dir")" in
        absent) journal_add "${journal_prefix}rmdir$esc_tab$path_dir"; cmd mkdir -p "$path_dir" ;;
    esac

    case "$(probe_path "$dst")" in
        symlink) journal_add "${journal_prefix}relink$esc_tab$dst$esc_tab$(readlink "$dst")" ;;
        *)       journal_add "${journal_prefix}unlink$esc_tab$dst" ;;
    esac

    cmd ln -sfn "$path_dot/$src" "$dst" 2>/dev/null || cmd cp -f "$path_dot/$src" "$dst"
}

claim_lock() {
    case "$(command -v flock || true)" in "") return 0 ;; esac
    exec 9>"$path_lock"
    flock -n 9
}

check_sudo() {
    local name_user
    case "$(id -u)" in
        0)
            case "$(command -v sudo || true)" in
                "") sudo() { "$@"; } ;;
            esac
            enum_has_sudo=yes
            return 0
            ;;
    esac
    enum_has_sudo=no
    name_user="$(id -un)"
    case "$(command -v sudo || true)" in
        "")
            log error "sudo: not installed. As root: pacman -S sudo, then add $name_user to wheel (see below)"
            return 1
            ;;
    esac
    if sudo -n true 2>/dev/null; then
        enum_has_sudo=yes
        return 0
    fi
    case " $(id -nG) " in
        *" wheel "*) ;;
        *)
            log error "sudo: $name_user is not in the wheel group, so sudo would refuse it"
            log error "sudo: fix as root: usermod -aG wheel $name_user && EDITOR=nvim visudo (uncomment %wheel ALL=(ALL:ALL) ALL), then log in again"
            return 1
            ;;
    esac
    if sudo -v; then
        enum_has_sudo=yes
        return 0
    fi
    log error "sudo: $name_user is in wheel but sudo refused it; as root: EDITOR=nvim visudo and uncomment %wheel ALL=(ALL:ALL) ALL"
    return 1
}
refresh_sudo() {
    case "$(id -u)" in 0) return 0 ;; esac
    sudo -n true 2>/dev/null && return 0
    wave_stop
    printf '%s%s: sudo password expired, enter it again%s\n' "$esc_yellow" "$name_step" "$esc_reset" >/dev/tty
    sudo -v </dev/tty >/dev/tty 2>&1
}

keepalive_sudo() {
    case "$(id -u)" in 0) return 0 ;; esac
    (
        while kill -0 "$pid_main" 2>/dev/null; do
            sudo -n -v 2>/dev/null || true
            sleep 50
        done
    ) &
    pid_keepalive=$!
}

install_paru() {
    local path_paru path_work
    path_paru="$(command -v paru || true)"
    case "$path_paru" in
        ?*)
            paru -Syu --noconfirm >/dev/null
            return 0
            ;;
    esac
    sudo pacman -Syu --noconfirm >/dev/null
    sudo pacman -S --needed --noconfirm base-devel git >/dev/null
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
    cd "$path_dot"
    case "$#" in
        0)
            rm -rf "$path_work"
            log error "paru: makepkg produced no package"
            return 1
            ;;
    esac
    sudo pacman -U --noconfirm "$@" >/dev/null
    rm -rf "$path_work"
    log info "paru: installed"
}
setup_pkg() {
    sudo pacman -S --needed --noconfirm base-devel git zsh neovim >/dev/null
    log info "pkg: installed"
}
ask_password() {
    local path_tty secret_first secret_second
    path_tty=/dev/tty
    case "$(probe_read_access "$path_tty")" in
        no)
            log error "account: no terminal available for password entry"
            return 1
            ;;
    esac
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

setup_account() {
    local path_shell path_zsh name_main_user_uid secret_password enum_sudoers
    sudo pacman -S --needed --noconfirm zsh >/dev/null
    path_zsh="$(command -v zsh || true)"
    case "$path_zsh" in
        "") path_shell=/bin/bash ;;
        *) path_shell="$path_zsh" ;;
    esac
    name_main_user_uid="$(id -u "$name_main_user" 2>/dev/null || true)"
    case "$name_main_user_uid" in
        "")
            sudo useradd --create-home --groups wheel --shell "$path_shell" "$name_main_user"
            ;;
        *)
            sudo usermod -aG wheel -s "$path_shell" "$name_main_user"
            ;;
    esac
    case "$(sudo passwd -S "$name_main_user" | awk '{print $2}')" in
        P) ;;
        *)
            secret_password="$(ask_password)" || return 1
            printf '%s:%s\n' "$name_main_user" "$secret_password" | sudo chpasswd
            ;;
    esac
    case "$(probe_path /etc/sudoers.d/10-wheel)" in
        absent)
            printf '%%wheel ALL=(ALL:ALL) ALL\n' | sudo tee /etc/sudoers.d/10-wheel >/dev/null
            sudo chmod 0440 /etc/sudoers.d/10-wheel
            enum_sudoers=valid
            sudo visudo -c >/dev/null || enum_sudoers=invalid
            case "$enum_sudoers" in
                invalid)
                    sudo rm -f /etc/sudoers.d/10-wheel
                    log error "account: wheel sudoers drop-in rejected"
                    return 1
                    ;;
            esac
            ;;
    esac
}

setup_time() {
    local enum_time_zone enum_ntp
    enum_time_zone="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
    enum_ntp="$(timedatectl show -p NTP --value 2>/dev/null || true)"
    case "$enum_time_zone:$enum_ntp" in
        "$name_time_zone:yes")
            return 0
            ;;
    esac
    sudo timedatectl set-timezone "$name_time_zone"
    sudo timedatectl set-ntp true
}
setup_system_config() {
    link sudo etc/locale.conf "$path_etc/locale.conf"
    link sudo etc/vconsole.conf "$path_etc/vconsole.conf"
    link sudo etc/mkinitcpio.conf "$path_etc/mkinitcpio.conf"
    link sudo etc/pacman.conf "$path_etc/pacman.conf"
    link sudo etc/mirrorlist "$path_etc/pacman.d/mirrorlist"
    link sudo etc/makepkg.conf "$path_etc/makepkg.conf"
    link sudo etc/sysctld-lowswap.conf "$path_etc/sysctl.d/99-lowswap.conf"
    link sudo etc/sysctld-file-watchers.conf "$path_etc/sysctl.d/90-file-watchers.conf"
    link sudo etc/ssh-keepalive.conf "$path_etc/ssh/ssh_config.d/20-keepalive.conf"
    link sudo etc/hyprctl-guard "$path_etc/hyprctl-guard"
    link sudo etc/wrap-hyprctl-install.sh "$path_etc/hyprctl-guard-install.sh"
    link sudo etc/wrap-hyprctl.hook "$path_etc/pacman.d/hooks/wrap-hyprctl.hook"
    sudo "$path_etc/hyprctl-guard-install.sh"
    install_paru || log error "paru install failed"
}
setup_chrome() {
    link user home/browser/chrome-flags.conf "$path_config/chrome-flags.conf"
    link sudo etc/chrome-policy-restore-tabs.json "$path_etc/opt/chrome/policies/managed/restore-tabs.json"
    case "$(command -v google-chrome-stable || true)" in
        ?*)
            log info "chrome: already installed"
            return 0
            ;;
    esac
    case "$(command -v paru || true)" in
        "")
            log warning "chrome: paru absent, cannot install from the AUR yet"
            return 0
            ;;
    esac
    paru -S --needed --noconfirm google-chrome >/dev/null 2>&1 ||
        log error "chrome: install failed"
    case "$(command -v google-chrome-stable || true)" in
        ?*) log info "chrome: installed" ;;
        *) log error "chrome: google-chrome-stable is not on PATH after the install" ;;
    esac
}
setup_paru() {
    link user home/paru/paru.conf "$path_config/paru/paru.conf"
}
setup_git_ssh() {
    link user etc/sshconfig "$HOME/.ssh/config"
    case "$(probe_path "$HOME/.ssh/id_ed25519")" in
        file)
            log info "git-ssh: key already exists"
            cat "$HOME/.ssh/id_ed25519.pub"
            return 0
            ;;
    esac
    ssh-keygen -q -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
    log info "git-ssh: key generated"
    cat "$HOME/.ssh/id_ed25519.pub"
}
setup_git_sync() {
    case "$(probe_path "$path_dot/.git")" in
        dir) git -C "$path_dot" pull -q --ff-only ;;
        *) git clone -q -c remote.origin.pushurl="$uri_push" "$uri_repo" "$path_dot" ;;
    esac
}
setup_shell() {
    link user home/.zshrc "$HOME/.zshrc"
}
setup_nvim() {
    local path_nvim path_lazy_nvim
    link user home/nvim/init.lua "$path_config/nvim/init.lua"
    link user home/nvim/lazylock.json "$path_config/nvim/lazylock.json"
    case "$(probe_path "$path_config/nvim/lazy-lock.json")" in
        symlink) rm -f "$path_config/nvim/lazy-lock.json" ;;
    esac
    path_nvim="$(command -v nvim || true)"
    case "$path_nvim" in
        "")
            log error "nvim: not installed, skipping plugin restore"
            return 0
            ;;
    esac
    path_lazy_nvim="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
    case "$(probe_path "$path_lazy_nvim/.git")" in
        dir)
            (git -C "$path_lazy_nvim" fetch -q --tags --force origin &&
                git -C "$path_lazy_nvim" checkout -q stable) ||
                log error "nvim: lazy.nvim update failed"
            ;;
        *)
            log warning "nvim: lazy.nvim absent, init.lua will clone it"
            ;;
    esac
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || log error "nvim: plugin restore failed"
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
setup_node() {
    local path_bun
    path_bun="$(command -v bun || true)"
    case "$path_bun" in
        "")
            curl -fsSL https://bun.sh/install | bash >/dev/null
            export PATH="$HOME/.bun/bin:$PATH"
            ;;
        *)
            bun upgrade >/dev/null
            ;;
    esac
    bun add -g --silent @google/gemini-cli@latest >/dev/null 2>&1 || true
    bun add -g --silent @openai/codex@latest >/dev/null 2>&1 || true
}
setup_python() {
    local path_uv
    path_uv="$(command -v uv || true)"
    case "$path_uv" in
        "")
            curl -fsSL https://astral.sh/uv/install.sh | sh >/dev/null
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        *)
            uv self update -q
            ;;
    esac
    uv tool install -q --upgrade ipython >/dev/null 2>&1 || true
    uv tool install -q --upgrade keras >/dev/null 2>&1 || true
    uv tool install -q --upgrade matplotlib >/dev/null 2>&1 || true
}
setup_git_config() {
    link user home/.gitconfig "$HOME/.gitconfig"
    link user home/.gitignore-global "$HOME/.gitignore-global"
    link user home/.githooks "$HOME/.githooks"
    link user home/.gitmessage "$HOME/.gitmessage"
    link user home/.gitconfig-paru "$HOME/.gitconfig-paru"
}
list_step_label="package/pkg repo/git_sync \
    system/account system/time sysconfig/system_config \
    userconfig/paru userconfig/chrome \
    repo/git_ssh \
    userconfig/shell \
    userconfig/nvim userconfig/fcitx5 userconfig/hypr \
    package/node package/python \
    userconfig/git_config"
list_step_sudo="pkg account time system_config chrome"
list_step_interactive="account"
list_step_irreversible="pkg git_sync account time node python git_ssh chrome"

claim_lock || {
    log error "setup: another run is still active, and two runs fight over pacman and the terminal"
    log error "setup: see what holds it with fuser $path_lock, then wait for those or stop them"
    exit 1
}

for name_label in $list_step_label; do
    list_step_state="$list_step_state pending:$name_label"
    count_manifest=$((count_manifest + 1))
done

printf '\n'
printf '%s\n' "complete-works Setup Script"
printf '\n'
enum_print_plain=yes
case "$enum_is_tty" in
    yes) enum_print_plain=no ;;
esac
case "$enum_print_plain" in
    yes)
        manifest_print
        printf '\n'
        ;;
esac
path_run="$(mktemp -d)"
path_finding="$path_run/findings"
: >"$path_finding"
status_start
case "$enum_is_tty:$enum_print_plain" in
    no:no)
        manifest_print
        printf '\n'
        ;;
esac
on_interrupt() {
    enum_interrupted=yes
    wave_stop
    case "$name_step_current" in
        "") ;;
        *)
            case " $list_step_irreversible " in
                *" ${name_step_current#*/} "*)
                    log error "$name_step_current: interrupted. This step cannot be rolled back; what it installed or downloaded stays."
                    ;;
                *)
                    rollback_step
                    log warning "$name_step_current: interrupted, its changes were rolled back"
                    ;;
            esac
            manifest_set "$name_step_current" failed
            ;;
    esac
    status_stop
    manifest_print
    printf '\n%sinterrupted%s\n' "$esc_red" "$esc_reset" >&2
    rm -rf "$path_run"
    exit "$1"
}
enum_interrupted=no
trap 'on_interrupt 130' INT
trap 'on_interrupt 143' TERM
trap 'on_interrupt 129' HUP
trap 'status_stop; case "$pid_keepalive" in "") ;; *) kill "$pid_keepalive" 2>/dev/null || true ;; esac; rm -rf "$path_run"' EXIT
manifest_draw

enum_has_sudo=yes
enum_needs_sudo=no
for name_step in $list_step_sudo; do
    case " $list_step_state " in
        *" pending:"*"/$name_step "*) enum_needs_sudo=yes ;;
    esac
done
case "$enum_needs_sudo" in
    no) ;;
    *) check_sudo && keepalive_sudo || log error "sudo: unavailable, skipping: $list_step_sudo" ;;
esac

for name_label in $list_step_label; do
    name_step="${name_label#*/}"
    index_step=$((index_step + 1))
    name_step_current="$name_label"
    count_step_total=$((count_step_total + 1))
    case "$enum_has_sudo: $list_step_sudo " in
        yes:*" $name_step "*) refresh_sudo || enum_has_sudo=no ;;
    esac
    case "$enum_has_sudo: $list_step_sudo " in
        no:*" $name_step "*)
            log warning "$name_label: skipped, sudo unavailable"
            manifest_set "$name_label" skipped
            count_step_skipped=$((count_step_skipped + 1))
            case "$enum_is_tty" in
                no) render_row skipped "$name_label"; printf '\n' ;;
            esac
            continue
            ;;
    esac

    case " $list_step_interactive " in
        *" $name_step "*) ;;
        *) wave_start "$name_label" ;;
    esac
    path_journal="$path_run/$name_step.journal"
    : >"$path_journal"
    count_link_failed=0
    if "setup_$name_step" >/dev/null 2>"$path_run/$name_step.err" &&
        [ "$count_link_failed" -eq 0 ]; then
        wave_stop
        manifest_set "$name_label" done
        count_step_success=$((count_step_success + 1))
        case "$enum_is_tty" in
            no) render_row done "$name_label"; printf '\n' ;;
        esac
    else
        wave_stop
        case " $list_step_irreversible " in
            *" $name_step "*)
                log error "$name_label: failed. This step cannot be rolled back; what it installed or downloaded stays." \
                    2>>"$path_run/$name_step.err"
                ;;
            *)
                rollback_step
                log warning "$name_label: failed, its changes were rolled back" \
                    2>>"$path_run/$name_step.err"
                ;;
        esac
        manifest_set "$name_label" failed
        report_failure "$name_label" "$path_run/$name_step.err"
        count_step_failed=$((count_step_failed + 1))
    fi
    path_journal=""
    name_step_current=""
done

report_notice() {
    local text
    case "$(probe_path "$path_finding")" in file) ;; *) return 0 ;; esac
    text="$(sed -n 's/^info: //p' "$path_finding" | awk '!seen[$0]++')"
    case "$text" in "") return 0 ;; esac
    printf '%s\n' "$text" | sed "s/^/${esc_green}INFO:${esc_reset} /"
    printf '\n'
}

summarize_run() {
    local text out prompt
    text="$(cat "$path_finding" "$path_run"/*.err 2>/dev/null |
        sed 's/\x1b\[[0-9;]*m//g; s/^\[\(ERROR\|WARN\)\] *//; /^info: /d; /^[[:space:]]*$/d' |
        awk '!seen[$0]++')"
    case "$text" in
        "")
            printf 'NO WARNING.\n'
            return 0
            ;;
    esac
    out=""
    if command -v claude >/dev/null 2>&1; then
        prompt='These are the warnings and errors from one run of a dotfiles setup script.
For each distinct problem print exactly two lines and nothing else:

WARN: <the problem, one sentence, ending in a period>
NEXT: you should <the one next action>

Merge repeated instances of one problem into a single pair. Name the concrete
command or file where there is one. No preamble, no headings, no markdown, and
no blank line between pairs.'
        out="$(printf '%s\n' "$text" | claude -p "$prompt" 2>/dev/null || true)"
    fi
    case "$out" in
        "")
            out="$(printf '%s\n' "$text" |
                sed -e 's/^error: //' -e 's/^warning: //' -e 's/^/WARN: /' \
                    -e 's/$/\
NEXT: you should act on the line above/')"
            ;;
    esac
    printf '%s\n' "$out" | sed "s/^WARN:/${esc_yellow}WARN:${esc_reset}/"
}

status_stop
printf '\n'
manifest_print
printf '\n'
printf 'Total: %d  Success: %d  Failed: %d  Skipped: %d\n' \
    "$count_step_total" "$count_step_success" "$count_step_failed" "$count_step_skipped"
printf '\n'
report_notice
summarize_run
