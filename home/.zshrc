# Helper functions
a() { alias "$1"="$2"; }
e() { export "$1"="$2"; }
# Prepend a directory to PATH once. `rr` re-sources this file, and a plain
# PATH="$1:$PATH" would add the same entry on every re-source.
p() { case ":$PATH:" in *":$1:"*) ;; *) export PATH="$1:$PATH" ;; esac; }
s() { printf '%*s\n' "$(tput cols)" '' | tr ' ' '-'; }

# CLI
PS1='%~ $(git_prompt) '
git_prompt() {
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  printf 'git:%s' "$branch"
}
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"

# Vi mode
bindkey -v
export KEYTIMEOUT=1 # ms before an Esc-prefixed key is treated as a lone Esc (mode switch)

# vi mode drops the terminal's Home/End/Delete bindings; restore them via terminfo
zmodload zsh/terminfo
[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]}"  ]] && bindkey "${terminfo[kend]}"  end-of-line
[[ -n "${terminfo[kdch1]}" ]] && bindkey "${terminfo[kdch1]}" delete-char

# Cursor shape reflects the current mode: block = normal, beam = insert
function zle-keymap-select {
  case $KEYMAP in
    vicmd)      echo -ne '\e[1 q' ;;
    viins|main) echo -ne '\e[5 q' ;;
  esac
}
zle -N zle-keymap-select
zle -N zle-line-init
zle-line-init() { echo -ne '\e[5 q' }

if ! pgrep -x "Hyprland" > /dev/null; then
  start-hyprland
fi
eval "$(direnv hook zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

## Basic command
a c "cd $HOME/pjt-build-complete-works/ && claude --chrome"
a n  "nvim"
a r  "nvim -R"
a cp "cp -i"
a mv "mv -i"
a l  "ls -ahF --color=always"
a ll "ls -alhiF --color=always"
# systemctl helpers
a ss "sudo SYSTEMD_EDITOR=/usr/bin/nvim systemctl"
sl()  { systemctl list-units      --state="${1:-}" "${@:2}"; }
sll() { systemctl list-unit-files --state="${1:-}" "${@:2}"; }

# pacman
a pm "sudo pacman"

# Git
a glc "git commit"
a gll "git log --oneline"
a glr "git show"
a glu "git "
a gld "git revert"

# refs
a grc "git "
a grl "git "
a grr "git "
a gru "git "
a grd "git "

a gsc "git remote "
a gsl "git remote -vv"
a gsr "git remote show"
a gsu "git remote rename"
a gsd "git remote remove"

# CLI configuration
a nr "nvim ~/.zshrc"
a rr "source ~/.zshrc"
a nn "nvim ~/.config/nvim/init.lua"
a nnc "nvim ~/.config/nvim/lua/core.lua"
a nnp "nvim ~/.config/nvim/lua/plugins.lua"
a ng "git config --global --edit"

e BUN_INSTALL "$HOME/.bun"
p "$BUN_INSTALL/bin"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

e EDITOR "nvim"
e VISUAL "nvim"

# GUI configuration
## -- Reload --
a rh "hyprctl reload > /dev/null; pkill waybar; (nohup waybar > /dev/null 2>&1 &); makoctl reload > /dev/null 2>&1; pkill -x foot; (nohup foot --server > /dev/null 2>&1 &)"
## -- Edit --
a nh "nvim ~/.config/hypr/hyprland.lua"
a nk "nvim ~/.config/mako/config"
a nw "nvim ~/.config/waybar/config"
a nws "nvim ~/.config/waybar/style.css"
a nf "nvim ~/.config/foot/foot.ini"

# Browser
a nq "nvim ~/.config/qutebrowser/config.py"
a rq "(qutebrowser :config-source > /dev/null 2>&1 &)"

# Input
a nx "fcitx5-configtool"
a rx "fcitx5 -rd > /dev/null 2>&1"

ufi() {
  local live="$HOME/.config/fcitx5/profile"
  local repo="$HOME/dotfiles/fcitx5-profile"
  if [ -L "$live" ]; then
    echo "profile still symlinked; nothing to sync"
  else
    cp "$live" "$repo" && ln -sfn "$repo" "$live" && echo "profile synced to repo; symlink restored"
  fi
}

# Self-host with Docker
penpot() {
  local REPO="$HOME/penpot"
  local COMPOSE="$REPO/docker/devenv/docker-compose.yaml"

  if [[ ! -f "$COMPOSE" ]]; then
    echo "compose file not found: $COMPOSE" >&2
    return 1
  fi

  docker compose -f "$COMPOSE" up -d
}

# Input method
e GTK_IM_MODULE fcitx # GNOME/GTK apps<D-'>
e QT_IM_MODULE fcitx # KDE/Qt apps
e XMODIFIERS @im=fcitx # X11 apps
e SDL_IM_MODULE fcitx # SDL apps (mainly game apps)
e IMSETTINGS_MODULE fcitx # Fedora Linux
e INPUT_METHOD fcitx # OS default IM

compinit -i
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.log/zsh"

setopt allexport
setopt autocd
setopt correct
setopt hist_ignore_dups
setopt hist_append
setopt PROMPT_SUBST

. "$HOME/.local/bin/env"

# SSH to android
[ -f "$HOME/dotfiles/.env" ] && source "$HOME/dotfiles/.env"

# `and` used to be an alias (`a and ...`); unalias it first so re-sourcing
# this file in a shell that still has that alias loaded doesn't break the
# function definition below ("defining function based on alias `and'").
unalias and 2>/dev/null

and() {
  local host="${TERMUX_HOST:-$(ip route | grep default | grep -oP 'via \K[\d.]+')}"
  local port="${TERMUX_PORT:-8022}"
  local user="${TERMUX_USER:-u0_a339}"
  if [ -n "$TERMUX_SSH_KEY_PASSPHRASE" ] && command -v sshpass >/dev/null 2>&1; then
    sshpass -P 'assphrase' -p "$TERMUX_SSH_KEY_PASSPHRASE" ssh -p "$port" "$user@$host" "$@"
  else
    ssh -p "$port" "$user@$host" "$@"
  fi
}

# git push/pull <-> termux(/sdcard) sync
om() {
  local models=($(ollama list | tail -n +2 | awk '{print $1}'))
  [ ${#models[@]} -eq 0 ] && { echo "No models."; return 1; }
  PS3="Select model: "
  select m in "${models[@]}"; do
    [ -n "$m" ] && { ollama run "$m" "$@"; break; }
    echo "Invalid number."
  done
}
