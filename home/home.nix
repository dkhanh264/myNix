{ config, pkgs, lib, ... }:
{
  
  programs.home-manager.enable = true;

  # Screenshot history uses trash-put so deletions remain recoverable.
  home.packages = [ pkgs.trash-cli ];

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
    ./modules/quickshell
  ];
}
