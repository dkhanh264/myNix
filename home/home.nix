{ ... }:
{
  programs.home-manager.enable = true;

  services.open-design = {
    enable = true;
    autoStart = true; # Đặt true nếu muốn tự động chạy nền khi login
    webFrontend.enable = true; # Bật giao diện web tĩnh Caddy (mặc định port 5174)
  };

  imports = [
    ./core
    ./modules/shell
    ./modules/niri
    ./modules/terminal
    ./modules/launcher
    ./modules/dev
    ./modules/theme
    ./modules/media
    ./modules/notification
    ./modules/quickshell
  ];
}
