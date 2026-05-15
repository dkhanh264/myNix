# File: home/modules/extra-dots.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    mpv
    neofetch
    alacritty
  ];

  xdg.configFile = {
    "btop".source = ./hyprland/dotfiles/btop;
    "mpv".source = ./hyprland/dotfiles/mpv;
    "neofetch".source = ./hyprland/dotfiles/neofetch;
    "alacritty".source = ./hyprland/dotfiles/alacritty;
    
    # Lưu ý: Đảm bảo bạn đã copy 2 file này vào đúng trong thư mục dotfiles nhé
    "hypr/hyprlock.conf".source = ./hyprland/dotfiles/hyprlock.conf;
    "hypr/hypridle.conf".source = ./hyprland/dotfiles/hypridle.conf;
    
    "starship.toml".source = ./hyprland/dotfiles/starship.toml;
  };
}
