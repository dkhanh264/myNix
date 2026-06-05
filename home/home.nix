{ config, pkgs, lib, ... }:
{
  
  programs.home-manager.enable = true;

  imports = [
    ./core
    ./modules/shell
    ./modules/hyprland
    ./modules/terminal
    ./modules/launcher
    ./modules/dev
    ./modules/theme
    ./modules/media
    ./modules/browser
  ];
  xdg.desktopEntries.android-studio = {
    name = "Android Studio";
    exec = "env QT_QPA_PLATFORM=xcb android-studio %f";
    icon = "android-studio";
    comment = "The official Android IDE (Forced XWayland Mode)";
    categories = [ "Development" "IDE" ];
    settings = {
      StartupWMClass = "jetbrains-studio";
    };
  };
}
