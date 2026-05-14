{ pkgs, config, ... }:
let
  walCacheDir = "${config.home.homeDirectory}/.cache/wal";
in
{
  home.packages = with pkgs; [
    pywal
  ];

  systemd.user.services.pywal-theme = {
    Unit = {
      Description = "Generate Pywal colors from wallpaper";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.pywal}/bin/wal -i ${config.home.sessionVariables.WALLPAPER} -n";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

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
  xdg.configFile."gtk-3.0/gtk.css".source =
    config.lib.file.mkOutOfStoreSymlink "${walCacheDir}/colors-gtk.css";

  xdg.configFile."gtk-4.0/gtk.css".source =
    config.lib.file.mkOutOfStoreSymlink "${walCacheDir}/colors-gtk.css";
}
