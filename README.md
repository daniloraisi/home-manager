# Home Manager configuration for Nix and Arch Linux

### Install the necessary system packages on Arch Linux
```bash
sudo pacman -S --needed --noconfirm git curl wget base-devel net-tools openssh zsh
```

### Update the user shell to be zsh
```bash
chsh -s /bin/zsh ${USER}
```

### It's now time to install Nix
```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

### Configure Nix to apply some experimental features
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

### Download the dotfiles and HM config
```bash
mkdir -p ~/.config
git clone git@github.com:daniloraisi/home-manager ~/.config/home-manager
```

### Install Home Manager and Switch
```bash
nix run home-manager/release-24.11 -- init --switch
```

