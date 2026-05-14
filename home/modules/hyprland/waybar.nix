{ ... }:
{
  programs.waybar = {
    enable = true;
  };

  # Đẩy toàn bộ thư mục cấu hình từ dotfiles vào ~/.config
  xdg.configFile."waybar".source = ./dotfiles/waybar;
  xdg.configFile."walker".source = ./dotfiles/walker;
  xdg.configFile."cava".source = ./dotfiles/cava;
}
