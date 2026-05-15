# File: home/modules/theme/gtk.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pywal
  ];

  gtk = {
    enable = true;
    theme = {
      name    = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name    = "Adwaita";
      size    = 24;
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  home.pointerCursor = {
    name       = "Adwaita";
    size       = 24;
    package    = pkgs.adwaita-icon-theme;
    gtk.enable = true;
    x11.enable = true;
  };

  qt = {
    enable             = true;
    platformTheme.name = "gtk";
    style.name         = "adwaita-dark";
  };
  
  # Đã xóa bỏ hoàn toàn phần xdg.configFile import file css bị lỗi
}
