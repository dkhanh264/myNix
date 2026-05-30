{ config, pkgs, lib, ... }:
{
  
  programs.home-manager.enable = true;

  imports = [
    ./core
    ./modules/shell
    ./modules/hyprland
    ./modules/terminal
    ./modules/extra-dots.nix
    ./modules/dev/git.nix
    ./modules/dev/neovim.nix
    ./modules/theme/gtk.nix
    ./modules/media/obs.nix
    ./modules/browser/firefox.nix
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
