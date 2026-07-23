{
  description = "NixOS 25.11 — Dual Boot Laptop với Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    lanzaboote.url = "github:nix-community/lanzaboote";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix.url = "github:sadjow/codex-cli-nix";

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixvim,
      lanzaboote,
      codex-cli-nix,
      antigravity-nix,
      ...
    }:
    let
      mkSystem =
        hostname:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            ./hosts/${hostname}/configuration.nix
            lanzaboote.nixosModules.lanzaboote
            home-manager.nixosModules.home-manager

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                extraSpecialArgs = { inherit nixvim codex-cli-nix antigravity-nix; };

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
                    stateVersion = "25.11";
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
