{
  description = "NixOS 26.05 — Dual Boot Laptop with Niri";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fcitx5-lotus = {
      url = "github:LotusInputMethod/fcitx5-lotus";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:niri-wm/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [ "https://niri.cachix.org" ];
    extra-trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixvim,
      lanzaboote,
      codex-cli-nix,
      antigravity-nix,
      fcitx5-lotus,
      niri,
      ...
    }@inputs:
    let
      mkSystem =
        hostname:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/${hostname}/configuration.nix
            lanzaboote.nixosModules.lanzaboote
            home-manager.nixosModules.home-manager
            fcitx5-lotus.nixosModules.fcitx5-lotus

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";

                extraSpecialArgs = { inherit codex-cli-nix antigravity-nix; };

                sharedModules = [
                  nixvim.homeModules.nixvim
                ];

                users.dk = { ... }: {
                  imports = [
                    ./home/home.nix
                  ];

                  home = {
                    username = "dk";
                    homeDirectory = "/home/dk";
                    stateVersion = "26.05";
                  };
                };
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        "HiMeo" = mkSystem "laptop";
      };
    };
}
