# File: home/modules/extra-dots.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    mpv
    neofetch
  ];

  xdg.configFile = {
    "btop".source = ./hyprland/dotfiles/btop;
    "mpv".source = ./hyprland/dotfiles/mpv;
    "neofetch".source = ./hyprland/dotfiles/neofetch;
    
    # Lưu ý: Đảm bảo bạn đã copy 2 file này vào đúng trong thư mục dotfiles nhé
    "hypr/hyprlock.conf".source = ./hyprland/dotfiles/hyprlock.conf;
    
    "starship.toml".source = ./hyprland/dotfiles/starship.toml;
  };
}
