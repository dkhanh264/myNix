{ pkgs, config, lib, ... }:

let
  # Tạo một script thực thi cava động để kết hợp cấu hình gốc và màu sắc từ Matugen
  cava-dynamic = pkgs.writeShellScriptBin "cava" ''
    mkdir -p ~/.config/cava
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
    exec ${pkgs.cava}/bin/cava "$@"
  '';
in
{
  home.packages = with pkgs; [
    quickshell            # Engine chạy Widget Shell chính
    rofi                  # Menu hệ thống thay thế Walker
    matugen               # Hệ thống sinh phối màu tự động từ hình nền
    playerctl             # Điều khiển nhạc nền qua phím tắt đa phương tiện
    swayosd               # Trình hiển thị OSD cho âm lượng và độ sáng
    
    # Các dependencies cần thiết cho các Widget QML của Quickshell
    qt6.qtmultimedia
    qt6.qt5compat
    qt6.qtwebsockets
    qt6.qtwebengine
    
    # Bộ công cụ phục vụ chụp ảnh / quay video màn hình chất lượng cao
    gpu-screen-recorder
    satty
    zbar
    python3
    
    # Các công cụ dòng lệnh bổ trợ hệ thống
    socat
    jq
    acpi
    bc
    lm_sensors
    ffmpeg
    imagemagick
    swww
    
    (lib.hiPrio cava-dynamic) # Ưu tiên chạy wrapper của cava động
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Ép chạy chế độ Wayland thuần cho các app Qt6/Electron
  };

  # ── Kích hoạt dịch vụ ngầm SwayOSD Daemon ────────────────────────────
  services.swayosd = {
    enable = true;
    topMargin = 0.9;
    stylePath = "${config.home.homeDirectory}/.config/swayosd/style.css";
  };

  # ── Liên kết Symlink cấu hình tĩnh an toàn qua Nix Store ─────────────
  home.file.".config/hypr/scripts" = {
    source = ./dotfiles/hypr/scripts;
    recursive = true;
  };

  xdg.configFile."rofi" = {
    source = ./dotfiles/rofi;
    recursive = true;
  };

  xdg.configFile."matugen" = {
    source = ./dotfiles/matugen;
    recursive = true;
  };

  xdg.configFile."cava/config_base" = {
    source = ./dotfiles/cava/config;
  };
}
