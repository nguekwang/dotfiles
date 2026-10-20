# dotfiles

## Installation by Device

### Clean install

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
Create user
```sh
# If you are new
sudo useradd -m -G wheel -s "$(command -v bash)" nguekwang

# If you are not new
sudo usermod -a -G wheel -s "$(command -v bash)" nguekwang
```

### Configuration setup 

Install git-related CLI tools
```sh
sudo pacman -Syu --noconfirm --needed git github-cli
```
Clone `dotfiles` directory
```sh
git clone https://github.com/nguekwang/dotfiles.git
```

```sh
git remote set-url origin git@github.com:nguekwang/dotfiles.git
```
