{ ... }:
{
  programs.starship = {
    enable = true;
    # Bỏ trống phần settings để hệ thống tự đọc file starship.toml từ ~/.config
  };
  xdg.configFile."starship.toml".source = ../hyprland/dotfiles/starship.toml;
}
