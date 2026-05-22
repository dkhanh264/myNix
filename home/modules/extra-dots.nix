# File: home/modules/extra-dots.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    mpv
  ];

  xdg.configFile = {
    "btop".source = ./hyprland/dotfiles/btop;
    "mpv".source = ./hyprland/dotfiles/mpv;
    
    "starship.toml".source = ./hyprland/dotfiles/starship.toml;
  };
}
