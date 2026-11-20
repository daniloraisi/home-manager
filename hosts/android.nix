# Específico do Arch no Andronix (proot, aarch64): sem systemd e sem acesso
# à YubiKey, então não há ponte de ssh-agent nem assinatura de commits.
# A autenticação no GitHub é feita pelo GH CLI, via HTTPS.
{ config, pkgs, lib, ... }:

{
  # Sem systemd no proot, não há serviços de usuário para gerenciar
  systemd.user.startServices = false;

  # O gh vira o credential helper do git para github.com e gist.github.com
  programs.gh = {
    gitCredentialHelper.enable = true;
    settings.git_protocol = "https";
  };

  # Repositórios clonados com URL SSH passam a usar HTTPS (e o token do gh)
  programs.git.settings.url."https://github.com/".insteadOf = [
    "git@github.com:"
    "ssh://git@github.com/"
  ];

  programs.zsh.shellAliases = {
    hms = "home-manager switch -b backup --flake ~/.config/home-manager#danilo@android";
  };
}