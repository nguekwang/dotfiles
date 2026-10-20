# dotfiles

## Installation by Device

### Clean install

```sh
iwctl station wlan0 connect "<SSID>"
```
Check the connection
```sh
ping -c 3 archlinux.org
```
Sync the clock and set the time zone
```sh
timedatectl set-ntp true
timedatectl set-timezone Asia/Tokyo
```

### WSL2
```powershell
wsl --install archlinux
```

### Termux
```sh
pkg update && pkg upgrade
pkg install proot-distro
```

```sh
proot-distro install https://mirrors.dotsrc.org/archlinuxarm/os/ArchLinuxARM-aarch64-latest.tar.gz --name arch
```

```sh
proot-distro login arch
```

```sh
termux-setup-storage
```

## Common setup 

### Account setup 
Log in as root user
```sh
su -
```
Install sudo
```sh
pacman -Syu --noconfirm --needed sudo
```
Create user
```sh
# If you are new
sudo useradd -m -G wheel -s "$(command -v bash)" nguekwang

# If you are not new
sudo usermod -a -G wheel -s "$(command -v bash)" nguekwang
```
Set the password
```sh
passwd nguekwang
```
Allow `wheel` to use sudo
```sh
printf '%%wheel ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
visudo -c
```
Set the time zone and enable NTP on the installed system
```sh
timedatectl set-timezone Asia/Tokyo
timedatectl set-ntp true
```
Log in as the user
```sh
su - nguekwang
```

### Configuration setup 

Install git-related CLI tools
```sh
sudo pacman -Syu --noconfirm --needed git github-cli openssh
```
Check the required commands and that the AUR is reachable
```sh
command -v pacman curl timedatectl ssh-keygen
curl -fsS -o /dev/null --max-time 10 https://aur.archlinux.org
```
Clone `dotfiles` directory
```sh
git clone https://github.com/nguekwang/dotfiles.git ~/dotfiles
```
Link configs and install packages (the lock refuses a second run while one is active)
```sh
flock -n "${XDG_RUNTIME_DIR:-/tmp}/dotfiles.lock" sh ~/dotfiles/sh/init
```
Guard hyprctl (only if Hyprland was installed before the link; the pacman hook does it afterwards)
```sh
sudo /etc/hyprctl-guard-install.sh
```
Remove a stale `lazy-lock.json` symlink and pin lazy.nvim to `stable` (if lazy.nvim is absent, `init.lua` clones it)
```sh
[ -L ~/.config/nvim/lazy-lock.json ] && rm -f ~/.config/nvim/lazy-lock.json
git -C ~/.local/share/nvim/lazy/lazy.nvim fetch -q --tags --force origin
git -C ~/.local/share/nvim/lazy/lazy.nvim checkout -q stable
```
Restore Neovim plugins
```sh
nvim --headless "+Lazy! restore" +qa
```

### Tools setup

Install Claude Code
```sh
curl -fsSL https://claude.ai/install.sh | bash
```
Install uv and Python tools
```sh
curl -LsSf https://astral.sh/uv/install.sh | sh
. ~/.local/bin/env
uv tool install --upgrade ipython --with keras --with matplotlib
```

### GitHub setup

Generate an SSH key
```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
```
Register it with GitHub
```sh
gh auth login
gh ssh-key add ~/.ssh/id_ed25519.pub
```
Push over SSH
```sh
git -C ~/dotfiles remote set-url origin git@github.com:nguekwang/dotfiles.git
```

## Update

Pull the repository
```sh
git -C ~/dotfiles pull --ff-only
```
Re-link configs and upgrade packages
```sh
flock -n "${XDG_RUNTIME_DIR:-/tmp}/dotfiles.lock" sh ~/dotfiles/sh/init
```
Upgrade Claude Code, uv and Python tools
```sh
claude update
uv self update
uv tool install --upgrade ipython --with keras --with matplotlib
```
Restore Neovim plugins
```sh
nvim --headless "+Lazy! restore" +qa
```
