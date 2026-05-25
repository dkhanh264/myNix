{ ... }:
{
  programs.waybar = {
    enable = true;
  };

  # Chỉ quản lý file tĩnh; chừa wal-colors.css để script runtime tự tạo/cập nhật
  xdg.configFile."waybar/config.jsonc".source = ./dotfiles/waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./dotfiles/waybar/style.css;
  xdg.configFile."walker" = {
    source = ./dotfiles/walker;
    recursive = true;
  };
}
