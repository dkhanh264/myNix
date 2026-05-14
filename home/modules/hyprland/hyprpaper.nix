{ config, ... }:
let
  wallpaperPath = config.home.sessionVariables.WALLPAPER
    or "${config.home.homeDirectory}/Pictures/wallpapers/wallpaper.jpg";
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
