{ pkgs, ... }:
{
  home.packages = [ pkgs.neofetch ];
  xdg.configFile."neofetch".source = ../hyprland/dotfiles/neofetch;
}
