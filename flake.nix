{
  description = "Home Manager configuration of danilo";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # Monta uma configuração a partir da arquitetura e dos módulos do ambiente
      mkHome = { system, modules }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};

          modules = [
            ./home.nix
            (import ./local.nix)
          ] ++ modules;
        };

      wsl = mkHome {
        system = "x86_64-linux";
        modules = [ ./hosts/wsl.nix ];
      };
    in {
      homeConfigurations = {
        "danilo@wsl" = wsl;

        # Mantém o nome antigo apontando para o WSL, para
        # "home-manager switch" sem --flake continuar funcionando lá
        "danilo" = wsl;
      };
    };
}