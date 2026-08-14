{ pkgs, ... }:
let
  rofiLauncher = pkgs.writeShellApplication {
    name = "rofi-launcher";
    runtimeInputs = [ pkgs.rofi ];
    text = ''
      exec rofi -show drun -config "$HOME/.config/rofi/config.rasi"
    '';
  };

in
{
  home.packages = [
    pkgs.rofi
    rofiLauncher
  ];

  xdg.configFile."rofi" = {
    source = ./rofi;
    recursive = true;
    force = true;
  };
}
