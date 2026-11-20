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
  };

  # Let Home Manager install and manage itself.
  programs = {
    home-manager.enable = true;

    zsh = {
      enable = true;
      defaultKeymap = "emacs";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
    
      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        share = true;
      };
    
      historySubstringSearch = {
        enable = true;
        searchUpKey = [ "^[[A" "^[OA" ];
        searchDownKey = [ "^[[B" "^[OB" ];
      };
    
      initContent = lib.mkMerge [
        # fzf-tab: depois do compinit (570), antes do autosuggestions (700)
        (lib.mkOrder 600 ''
          source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
          zstyle ':completion:*:descriptions' format '[%d]'
          zstyle ':completion:*' menu no
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
          zstyle ':fzf-tab:*' switch-group '<' '>'
        '')
    
        # o que você já tinha (ordem padrão, 1000)
        ''
          bindkey '^[[H'    beginning-of-line     # Home
          bindkey '^[[F'    end-of-line           # End
          bindkey '^[[1;5H' beginning-of-line     # Ctrl+Home
          bindkey '^[[1;5F' end-of-line           # Ctrl+End
          bindkey '^[[1;5D' backward-word         # Ctrl+←
          bindkey '^[[1;5C' forward-word          # Ctrl+→
          bindkey '^[[3~'   delete-char           # Delete
          bindkey '^[[3;5~' kill-word             # Ctrl+Delete
          bindkey '^H'      backward-kill-word    # Ctrl+Backspace
    
          WORDCHARS='*?_[]~=&;!#$%^(){}<>'
        ''
      ];
    };

    zellij = {
      enable = true;
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
      settings = starshipSettings;
    };

    zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };

    fzf = {
      enable = true;
      historyWidget.options = [
        "--height=40%"
        "--layout=reverse"
        "--border=top"
      ];
    };

    direnv = {
      enable = true;
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

    git.enable = true;

    ssh = {
      enable = true;
      enableDefaultConfig = false;
    
      settings."github.com" = {
        ControlMaster = "auto";
        ControlPath = "~/.ssh/cm-%C";
        ControlPersist = "10m";
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
