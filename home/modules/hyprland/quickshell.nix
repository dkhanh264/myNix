{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    quickshell
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qt5compat
  ];

  xdg.configFile."quickshell" = {
    source = ./dotfiles/quickshell;
    recursive = true;
  };

  wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
    "qs -c ~/.config/quickshell/shell.qml"
  ];
}
