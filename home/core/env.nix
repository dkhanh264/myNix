{ config, ... }:
{
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "brave";
    TERMINAL = "kitty";
    WALLPAPER = "${config.home.homeDirectory}/Pictures/wallpapers/wallpaper.jpg";

    # Hardware Video Acceleration & GPU Offload
    # Intel iHD driver for efficient video decode on iGPU (keeps dGPU in D3cold 0W)
    LIBVA_DRIVER_NAME = "iHD";

    # Dynamic GPU & Wayland Offloading for Chromium/Electron/Firefox
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    NIXOS_OZONE_WL = "1";

    # Force GUI frameworks to use Wayland backend
    QT_QPA_PLATFORM = "wayland;xcb";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";

    # Fcitx5 input method
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];
}
