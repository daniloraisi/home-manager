# Específico dos GitHub Codespaces (devcontainers com Nix, como os do FatiaCerta).
# Aplicado pelo install.sh, que o Codespaces roda ao criar cada codespace (Settings → Codespaces → Dotfiles).
#
# O usuário e a home vêm do local.nix que o install.sh gera (vscode ou codespace, conforme a imagem).
# O git e o gh já chegam autenticados pelo Codespaces (GITHUB_TOKEN e o credential helper dele): nada de YubiKey,
# assinatura de commit ou credential helper do gh aqui.
{ config, pkgs, lib, ... }:

{
  # Sem systemd de usuário no container
  systemd.user.startServices = false;

  # O Nix do devcontainer é de usuário único e só entra no PATH pelos arquivos do bash. Como o zsh vira o shell de
  # login, o perfil do Nix (e os programas do Home Manager) precisa entrar também nele.
  programs.zsh.envExtra = ''
    if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
      . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi
  '';

  # O zellij só abre sozinho nas sessões SSH (gh codespace ssh). No terminal do VS Code, o zsh fica sem ele.
  programs.zellij.enableZshIntegration = lib.mkForce false;
  programs.zsh.initContent = lib.mkOrder 1500 ''
    if [[ -n "$SSH_CONNECTION" && -z "$ZELLIJ" && -o interactive ]]; then
      eval "$(${config.programs.zellij.package}/bin/zellij setup --generate-auto-start zsh)"
    fi
  '';

  programs.zsh.shellAliases = {
    hms = "home-manager switch -b backup --flake ~/.config/home-manager#danilo@codespace";
  };
}
