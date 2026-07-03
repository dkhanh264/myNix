{ config, pkgs, lib, ... }:
{
  
  programs.home-manager.enable = true;

  imports = [
    ./core
    ./modules/shell
    ./modules/hyprland
    ./modules/terminal
    ./modules/launcher
    ./modules/dev
    ./modules/theme
    ./modules/media
    ./modules/browser
    ./modules/waybar
  ];
}
