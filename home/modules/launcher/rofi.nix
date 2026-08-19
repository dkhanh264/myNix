{ pkgs, ... }:
let
  rofiLauncher = pkgs.writeShellScriptBin "rofi-launcher" ''
    exec ${pkgs.rofi}/bin/rofi -show drun -config "$HOME/.config/rofi/config.rasi"
  '';

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
