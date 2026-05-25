{ ... }:
{
  services.mako = {
    enable = true;
    extraConfig = ''
      include=~/.cache/wal/mako-colors.conf
    '';
    
    # Gom toàn bộ cấu hình cũ vào khối settings và đổi sang dạng dấu gạch ngang (-)
    settings = {
      font = "JetBrainsMono Nerd Font 10";
      width = 300;
      height = 100;
      margin = "10";
      padding = "10";
      border-size = 0;
      border-radius = 10;
      default-timeout = 2000;
      layer = "top";
      anchor = "top-right";
    };
  };
}
