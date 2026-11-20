{ config, pkgs, lib, gitEmail ? null, ... }:

let
  effectiveGitEmail =
    if gitEmail == ""
       then throw "Defina GIT_EMAIL antes de executar home-manager switch"
       else gitEmail;

  starshipToml = ./dotfiles/starship.toml;
  starshipSettings = builtins.fromTOML (builtins.readFile starshipToml);
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "danilo";
  home.homeDirectory = "/home/danilo";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    xdg-utils
    socat
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/danilo/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
    ZELLIJ_AUTO_EXIT = lib.mkForce "true";
    CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
    PATH="$HOME/.local/bin:$PATH";
    BROWSER="/mnt/c/Windows/System32/cmd.exe /c start";
    SSH_AUTH_SOCK = "$HOME/.ssh/agent.sock";
  };

  home.activation.allowedSigners =
    config.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/git"
  
      if [ -f "/mnt/c/Users/Danilo/.ssh/id_ed25519_sk.pub" ]; then
        echo "${effectiveGitEmail} $(cat /mnt/c/Users/Danilo/.ssh/id_ed25519_sk.pub)" \
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
          UNIX-LISTEN:%h/.ssh/agent.sock \
          EXEC:'/mnt/c/Windows/System32/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent'
      '';

      Restart = "always";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };

  # Let Home Manager install and manage itself.
  programs = {
    home-manager.enable = true;

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ls = "eza -1lagh --git --color --icons always";
      };
    };

    zellij = {
      enable = true;
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = starshipSettings;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
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
        user = {
          name = "Danilo Raisi";
          email = effectiveGitEmail;
        };
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
      };

      signing = {
        signByDefault = true;
        key = "/mnt/c/Users/Danilo/.ssh/id_ed25519_sk.pub";
      };
    };
  };


  xdg.enable = true;
}
