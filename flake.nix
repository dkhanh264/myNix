{
  description = "NixOS 25.11 — Dual Boot Laptop với Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, nixvim, ... }:
  let
    mkSystem = hostname:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./hosts/${hostname}/configuration.nix

          stylix.nixosModules.stylix
          
          home-manager.nixosModules.home-manager

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              extraSpecialArgs = { inherit nixvim; };

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
      "your-laptop" = mkSystem "laptop";
    };
  };
}
