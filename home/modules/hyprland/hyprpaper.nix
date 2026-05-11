{ ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload  = [ "~/Pictures/wallpapers/wallpaper.jpg" ];
      # Dùng "" không có tên monitor để áp dụng cho tất cả màn hình
      wallpaper = [ ", ~/Pictures/wallpapers/wallpaper.jpg" ];
    };
  };
}
