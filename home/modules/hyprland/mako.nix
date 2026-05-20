{ ... }:
{
  services.mako = {
    enable = true;
    
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
      background-color = "#1e1e2e99";
      text-color = "#cdd6f4";
      layer = "top";
      anchor = "top-right";
    };
  };
}
