{ config, pkgs, lib, ... }:

let
  starshipToml = ./dotfiles/starship.toml;
  starshipSettings = builtins.fromTOML (builtins.readFile starshipToml);
in
{
  home.username = "danilo";
  home.homeDirectory = "/home/danilo";

  home.stateVersion = "26.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    xdg-utils
    socat
    ripgrep
    fd
    lazygit
    gcc
    tree-sitter
    nodejs
    python3
  ];

  home.file = {};

  home.sessionVariables = {
    ZELLIJ_AUTO_EXIT = lib.mkForce "true";
    CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
    PATH="$HOME/.local/bin:$PATH";
    BROWSER="/mnt/c/Windows/System32/cmd.exe /c start";
    SSH_AUTH_SOCK = "$HOME/.ssh/agent.sock";
  };

  home.activation.allowedSigners =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/git"
  
      if [ -f "/mnt/c/Users/Danilo/.ssh/id_ed25519_sk.pub" ]; then
        echo "${config.programs.git.settings.user.email} $(cat /mnt/c/Users/Danilo/.ssh/id_ed25519_sk.pub)" \
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

  # Let Home Manager install and manage itself.
  programs = {
    home-manager.enable = true;

    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ls = "eza -1lagh --git --color --icons always";
      };

      # vai pro início do .bashrc
      bashrcExtra = ''
        [[ $- == *i* ]] && source ${pkgs.blesh}/share/blesh/ble.sh --noattach
      '';
    
      # vai pro final, depois das integrações (starship etc.)
      initExtra = lib.mkOrder 3000 ''
        bleopt complete_auto_menu=300   # abre a lista sozinha após 300 ms, estilo ListView
        [[ ! ''${BLE_VERSION-} ]] || ble-attach
      '';
    };

    zellij = {
      enable = true;
      enableBashIntegration = true;
    };

    starship = {
      enable = true;
      enableBashIntegration = true;
      settings = starshipSettings;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      options = [ "--cmd cd" ];
    };

    fzf = {
      enable = true;
      enableBashIntegration = true;
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    eza = {
      enable = true;
      colors = "always";
      git = true;
      icons = "always";
      extraOptions = [ "-1lagh" ];
    };
    
    lazygit.enable = true;

    gh.enable = true;

    gh-dash.enable = true;

    git = {
      enable = true;

      settings = {
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
      };

      signing = {
        signByDefault = true;
        key = "/mnt/c/Users/Danilo/.ssh/id_ed25519_sk.pub";
      };
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      sideloadInitLua = true;
    };
  };


  xdg = {
    enable = true;
    configFile."nvim".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/.astronvim";
  };
}
