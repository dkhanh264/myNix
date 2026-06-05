{ pkgs, ... }:
{
  home.packages = [ pkgs.mpv ];
  xdg.configFile."mpv".source = ../hyprland/dotfiles/mpv;
}
