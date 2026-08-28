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
    NVD_BACKEND               = "direct";

    # Dynamic GPU & Wayland Offloading for Chromium/Electron/Firefox
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    NIXOS_OZONE_WL               = "1";

    # Force GUI frameworks to use Wayland backend
    QT_QPA_PLATFORM    = "wayland;xcb";
    SDL_VIDEODRIVER    = "wayland";
    MOZ_ENABLE_WAYLAND = "1";

    # Fcitx5 input method
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
  };
}
