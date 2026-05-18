{ config, pkgs, lib, ... }:
{
  
  programs.home-manager.enable = true;

  imports = [
    ./core
    ./modules/shell
    ./modules/hyprland
    ./modules/terminal/kitty.nix
    ./modules/extra-dots.nix
    ./modules/dev/git.nix
    ./modules/dev/neovim.nix
    ./modules/theme/gtk.nix
    ./modules/media/obs.nix
  ];
}
