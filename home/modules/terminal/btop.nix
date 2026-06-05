{ pkgs, ... }:
{
  home.packages = [ pkgs.btop ];
  xdg.configFile."btop/btop.conf".source = ../hyprland/dotfiles/btop/btop.conf;
}
