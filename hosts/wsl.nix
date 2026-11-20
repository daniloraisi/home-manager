# Específico do Arch no WSL: ponte com o ssh-agent do Windows (YubiKey),
# navegador do Windows e assinatura de commits com a chave -sk
{ config, pkgs, lib, ... }:

let
  windowsSshDir = "/mnt/c/Users/Danilo/.ssh";
  signingKey = "${windowsSshDir}/id_ed25519_sk.pub";
in
{
  home.packages = [ pkgs.socat ];

  home.sessionVariables = {
    BROWSER = "/mnt/c/Windows/System32/cmd.exe /c start";
    SSH_AUTH_SOCK = "$HOME/.ssh/agent.sock";
  };

  programs.zsh.shellAliases = {
    hms = "home-manager switch -b backup --flake ~/.config/home-manager#danilo@wsl";
  };

  home.activation.allowedSigners =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/git"

      if [ -f "${signingKey}" ]; then
        echo "${config.programs.git.settings.user.email} $(cat ${signingKey})" \
          > "$HOME/.config/git/allowed_signers"
      fi
    '';

  systemd.user.services.windows-ssh-agent = {
    Unit = {
      Description = "Windows OpenSSH Agent bridge";
    };

    Service = {
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p %h/.ssh"
        "${pkgs.coreutils}/bin/rm -f %h/.ssh/agent.sock"
      ];

      ExecStart = ''
        ${pkgs.socat}/bin/socat \
          UNIX-LISTEN:%h/.ssh/agent.sock,fork,umask=077 \
          EXEC:'/mnt/c/Windows/System32/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent',nofork
      '';

      Restart = "always";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };

  programs.git = {
    settings = {
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
    };

    signing = {
      signByDefault = true;
      key = signingKey;
    };
  };
}
