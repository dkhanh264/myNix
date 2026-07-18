{ ... }:
{
  services.mako = {
    enable = true;
    extraConfig = ''
      include=~/.cache/wal/mako-colors.conf
    '';
    
    # Gom toàn bộ cấu hình cũ vào khối settings và đổi sang dạng dấu gạch ngang (-)
    settings = {
      font = "Noto Sans 10";
      width = 360;
      height = 130;
      margin = "12";
      padding = "16";
      border-size = 0;
      border-radius = 24;
      default-timeout = 5000;
      max-history = 50;
      icons = true;
      max-icon-size = 48;
      layer = "top";
      anchor = "top-right";
    };
  };
}
