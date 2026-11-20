# Específico do Arch no Andronix (proot, aarch64): sem systemd e sem acesso
# à YubiKey, então não há ponte de ssh-agent nem assinatura de commits
{ config, pkgs, lib, ... }:

{
  # Sem systemd no proot, não há serviços de usuário para gerenciar
  systemd.user.startServices = false;

  programs.zsh.shellAliases = {
    hms = "home-manager switch -b backup --flake ~/.config/home-manager#danilo@android";
  };
}
