{ pkgs, lib, config, ... }:
{
  programs.serpantinum = {
    enable = true;
    systemd.enable = true;

    # Cấu hình tùy chọn cho Serpantinum (nếu muốn ghi đè cấu hình mặc định)
    # settings = {
    #   wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
    #   bar = {
    #     position = "top"; # "top" | "bottom" | "left" | "right"
    #   };
    # };
  };
}
