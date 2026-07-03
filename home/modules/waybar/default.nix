{ config, pkgs, ... }: {
  imports = [
    ./waybar-music.nix
  ];

  programs.waybar = {
    enable = true;
    
    # Kích hoạt hệ thống systemd để Waybar tự khởi động cùng Hyprland/Window Manager
    systemd.enable = true;
    systemd.target = "hyprland-session.target"; # Đảm bảo chỉ chạy khi vào Hyprland

    # Đọc trực tiếp file style.css bằng hàm native của Nix
    style = builtins.readFile ./style.css;
  };

  xdg.configFile."waybar/config".source = ./config.jsonc;
}
