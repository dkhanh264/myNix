{ ... }:
{
  programs.home-manager.enable = true;

  imports = [
    ./core
    ./modules/shell
    ./modules/niri
    ./modules/terminal
    ./modules/dev
    ./modules/theme
    ./modules/media
    ./modules/serpantinum
  ];
}
