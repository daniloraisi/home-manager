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


### GitHub Codespaces (dotfiles)

The same configuration runs in any codespace whose devcontainer has Nix (FatiaCerta, Iron, Opções a Seco, Swing Trade),
so `gh codespace ssh` opens zsh with starship, zellij and AstroNvim.

1. On github.com → **Settings → Codespaces → Dotfiles**, select this repository and check **Automatically install
   dotfiles**. It applies to codespaces created from then on.
2. When a codespace is created, GitHub clones this repository and runs `install.sh`, which:
   - generates `local.nix` with the codespace user (`vscode`), its home and the git name/email set by Codespaces;
   - clones the AstroNvim template into `~/.astronvim`;
   - runs `home-manager switch` with `danilo@codespace` (`hosts/codespace.nix`);
   - makes zsh the login shell, so SSH sessions start in it.
3. Connect with `gh codespace ssh` (the devcontainer needs the `sshd` feature). zellij starts automatically only in
   SSH sessions; the VS Code terminal opens zsh without it.

Outside a codespace, or in a codespace without Nix, `install.sh` does nothing. The output is in
`/workspaces/.codespaces/.persistedshare/creation.log`. The first switch downloads the packages from `home.nix`, so
creating a codespace takes a few extra minutes.

After changing the configuration inside a codespace, apply it with `hms`.
