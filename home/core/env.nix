{ config, ... }:
{
  home.sessionVariables = {
    EDITOR   = "nvim";
    BROWSER  = "google-chrome";
    TERMINAL = "kitty";
    WALLPAPER = "${config.home.homeDirectory}/Pictures/wallpapers/wallpaper.jpg";

    # NVIDIA + Wayland — bốn biến này BẮT BUỘC phải có.
    # Thiếu một trong số này có thể gây crash hoặc render sai.
    LIBVA_DRIVER_NAME         = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND               = "nvidia-drm";
    WLR_NO_HARDWARE_CURSORS   = "1";

    # Buộc các framework dùng Wayland backend
    QT_QPA_PLATFORM    = "wayland";
    GDK_BACKEND        = "wayland,x11";
    SDL_VIDEODRIVER    = "wayland";
    MOZ_ENABLE_WAYLAND = "1";

    # Fcitx5 — input method tiếng Việt


    XMODIFIERS    = "@im=fcitx";
  };
}
