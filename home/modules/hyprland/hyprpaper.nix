{ config, ... }:
let
  wallpaperPath = config.home.sessionVariables.WALLPAPER;
in
{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload  = [ wallpaperPath ];
      # Dùng "" không có tên monitor để áp dụng cho tất cả màn hình
      wallpaper = [ ", ${wallpaperPath}" ];
    };
  };
}
