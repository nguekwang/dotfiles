# 手動セットアップ手順

`sh setup.sh` が行う処理を、すべて手で実行する場合の手順書。
`setup.sh` と同じ順序で並べてあり、各手順は何度実行しても同じ結果になる（冪等）。

前提: Arch Linux、通常ユーザー（root ではない）、`wheel` グループ所属または sudo が使えること。

以降、`$USER_MAIN` は主ユーザー名（既定 `nguekwang`、環境変数 `name_main_user` で変更可）。

```sh
USER_MAIN=nguekwang
```

## 0. 事前確認

### 0-1. root で実行していないこと

```sh
id -u
```

`0` なら一度ログアウトして通常ユーザーで入り直す（`makepkg` が root を拒否するため）。

### 0-2. sudo が使えること

```sh
sudo -v
```

拒否された場合は root で次を実行し、再ログインする。

```sh
usermod -aG wheel "$(id -un)"
EDITOR=nvim visudo    # "%wheel ALL=(ALL:ALL) ALL" のコメントを外す
```

### 0-3. 必要なコマンドとネットワーク

```sh
for cmd in pacman curl timedatectl ssh-keygen; do command -v "$cmd" || echo "missing: $cmd"; done
curl -fsS -o /dev/null --max-time 10 https://aur.archlinux.org && echo ok
```

`missing:` が出たら先にインストールする。`ok` が出なければネットワークを直す。

### 0-4. 二重起動しないこと

`setup.sh` は `flock` で排他制御しているが、手動では自分で守る。
別の `setup.sh`、`pacman`、`paru` が動いていないことを確認する。

```sh
pgrep -a 'setup.sh|pacman|paru|makepkg'
```

## 1. git の導入と更新（prep/git）

```sh
sudo pacman -Syu --needed --noconfirm git
```

## 2. dotfiles リポジトリの同期（repo/git_sync）

`~/dotfiles` が既にあれば更新、なければ clone する。

```sh
if [ -d "$HOME/dotfiles/.git" ]; then
    git -C "$HOME/dotfiles" pull --ff-only
else
    git clone -c remote.origin.pushurl=git@github.com:nguekwang/dotfiles.git \
        https://github.com/nguekwang/dotfiles.git "$HOME/dotfiles"
fi
```

fetch は HTTPS、push だけ SSH になる。

## 3. Claude Code（package/claude）

```sh
if command -v claude >/dev/null; then
    claude update
else
    d="$(mktemp -d)"
    curl -fsSL https://claude.ai/install.sh -o "$d/claude-install.sh"
    bash "$d/claude-install.sh"
    rm -rf "$d"
fi
```

## 4. Python（package/python）

uv を入れる（あれば更新）。

```sh
if command -v uv >/dev/null; then
    uv self update
else
    d="$(mktemp -d)"
    curl -fsSL https://astral.sh/uv/install.sh -o "$d/uv-install.sh"
    sh "$d/uv-install.sh"
    rm -rf "$d"
    export PATH="$HOME/.local/bin:$PATH"
fi
```

ipython を keras、matplotlib 付きで入れる（導入済みなら更新）。

```sh
uv tool install --upgrade ipython --with keras --with matplotlib
```

## 5. 主ユーザーのアカウント（system/account）

zsh が必要。入っていなければ `pkg.sh` の対象なので、先に `sudo pacman -S --needed zsh` を実行する。

### 5-1. ユーザー作成または更新

```sh
path_shell="$(command -v zsh)"
if id "$USER_MAIN" >/dev/null 2>&1; then
    sudo usermod -aG wheel -s "$path_shell" "$USER_MAIN"
else
    sudo useradd --create-home --groups wheel --shell "$path_shell" "$USER_MAIN"
fi
```

### 5-2. パスワード

状態が `P` なら設定済みなので不要。それ以外なら設定する。

```sh
sudo passwd -S "$USER_MAIN" | awk '{print $2}'
sudo passwd "$USER_MAIN"
```

### 5-3. wheel の sudoers drop-in

```sh
printf '%%wheel ALL=(ALL:ALL) ALL\n' | sudo tee /etc/sudoers.d/10-wheel >/dev/null
sudo chmod 0440 /etc/sudoers.d/10-wheel
sudo visudo -c
```

`visudo -c` が失敗したら、sudo が壊れる前に drop-in を消す。

```sh
sudo rm -f /etc/sudoers.d/10-wheel
```

## 6. タイムゾーンと NTP（system/time）

```sh
timedatectl show -p Timezone --value    # Asia/Tokyo
timedatectl show -p NTP --value         # yes
```

どちらかが違えば設定する（両方一致なら不要）。

```sh
sudo timedatectl set-timezone Asia/Tokyo
sudo timedatectl set-ntp true
```

## 7. hyprctl ガードの導入（sysconfig/system_config）

`setup.sh` は `/etc/hyprctl-guard-install.sh` を root で実行するだけ。
その前提として、次の 2 つが `/etc` に symlink されている必要がある
（リポジトリ内では `etc/wrap-hyprctl-install.sh` と `etc/hyprctl-guard`）。

```sh
sudo ln -sfn "$HOME/dotfiles/etc/wrap-hyprctl-install.sh" /etc/hyprctl-guard-install.sh
sudo ln -sfn "$HOME/dotfiles/etc/hyprctl-guard" /etc/hyprctl-guard
```

> この symlink 作成は `link.sh` の担当だが、`link.sh` が読む `links.list` はリポジトリに無い。
> 現状は上の 2 行を手で打つのが確実。

実行する。`/usr/bin/hyprctl` が無いと失敗するので、hyprland が入っていることが前提。

```sh
sudo /etc/hyprctl-guard-install.sh
```

確認（すでに適用済みなら何もしない）。

```sh
readlink -f /usr/bin/hyprctl    # .../dotfiles/etc/hyprctl-guard
ls /usr/bin/hyprctl.real
```

## 8. Git 用 SSH 鍵（repo/git_ssh）

鍵が無いときだけ作る。

```sh
mkdir -p "$HOME/.ssh"
[ -f "$HOME/.ssh/id_ed25519" ] || ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
cat "$HOME/.ssh/id_ed25519.pub"
```

表示された公開鍵を GitHub（Settings → SSH and GPG keys）に登録する。
パスフレーズは空（`-N ""`）にしている。

## 9. Neovim プラグインの復元（userconfig/nvim）

lazy-lock.json が symlink なら消す。実体ファイルなら触らない。

```sh
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
[ -L "$cfg/nvim/lazy-lock.json" ] && rm -f "$cfg/nvim/lazy-lock.json"
```

lazy.nvim があれば stable に合わせる。なければ `init.lua` が初回起動時に clone する。

```sh
lazy="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
if [ -d "$lazy/.git" ]; then
    git -C "$lazy" fetch --tags --force origin
    git -C "$lazy" checkout stable
fi
```

プラグインを lock どおりに復元する。

```sh
nvim --headless "+Lazy! restore" +qa
```

失敗したら `nvim` を普通に起動して `:Lazy restore` を実行する。

## 完了確認

```sh
git -C ~/dotfiles status -sb
command -v claude uv ipython
id "$USER_MAIN"
timedatectl status
ls -l ~/.ssh/id_ed25519.pub
```

## 失敗したときの戻し方

`setup.sh` は可逆な手順が失敗すると変更を巻き戻す。手動では次のとおり。

| 手順 | 戻し方 |
| --- | --- |
| 5-3 sudoers | `sudo rm -f /etc/sudoers.d/10-wheel` |
| 7 hyprctl | `sudo mv -f /usr/bin/hyprctl.real /usr/bin/hyprctl` |
| 9 nvim | `nvim` で `:Lazy restore` を再実行 |

パッケージ導入（1、3、4）、ユーザー作成（5-1）、ダウンロードを伴う手順は元に戻せない。
