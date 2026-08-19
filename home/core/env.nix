{ config, ... }:
{
  home.sessionVariables = {
    EDITOR   = "nvim";
    BROWSER  = "brave";
    TERMINAL = "kitty";
    WALLPAPER = "${config.home.homeDirectory}/Pictures/wallpapers/wallpaper.jpg";

    # NVIDIA + Wayland + GPU Offloading
    LIBVA_DRIVER_NAME         = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND               = "nvidia-drm";
    NVD_BACKEND               = "direct";

    # Dynamic GPU & Wayland Offloading for Chromium/Electron/Firefox
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    NIXOS_OZONE_WL               = "1";

    # Tối ưu hóa bộ cấp phát bộ nhớ (trả RAM nhàn rỗi về cho Kernel ngay lập tức)
    MALLOC_TRIM_THRESHOLD_ = "131072";

    # Buộc các framework dùng Wayland backend
    QT_QPA_PLATFORM    = "wayland;xcb";
    SDL_VIDEODRIVER    = "wayland";
    MOZ_ENABLE_WAYLAND = "1";

    # Fcitx5 — input method tiếng Việt
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
  };
}
