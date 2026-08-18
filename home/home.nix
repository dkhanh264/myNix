{ ... }:
{
  programs.home-manager.enable = true;

  imports = [
    ./core
    ./modules/shell
    ./modules/niri
    ./modules/terminal
    ./modules/launcher
    ./modules/dev
    ./modules/theme
    ./modules/media
  ];
}
