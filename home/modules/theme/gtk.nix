{ pkgs, config, ... }:
let
  wallpaperPath = config.home.sessionVariables.WALLPAPER
    or "${config.home.homeDirectory}/Pictures/wallpapers/wallpaper.jpg";
  walCacheDir = "${config.home.homeDirectory}/.cache/wal";
  pywalThemeScript = pkgs.writeShellScript "pywal-theme" ''
    mkdir -p "${walCacheDir}"
    if [ ! -f "${wallpaperPath}" ]; then
      if [ ! -f "${walCacheDir}/colors-gtk.css" ]; then
        printf '%s\n' ':root {}' > "${walCacheDir}/colors-gtk.css"
      fi
      echo "pywal-theme: wallpaper not found at ${wallpaperPath}" >&2
      exit 0
    fi

    ${pkgs.pywal}/bin/wal -i "${wallpaperPath}" -n
  '';
in
{
  home.packages = with pkgs; [
    pywal
  ];

  systemd.user.services.pywal-theme = {
    Unit = {
      Description = "Generate Pywal colors from wallpaper";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pywalThemeScript;
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
  xdg.configFile."gtk-3.0/gtk.css".text = ''
    @import url("file://${walCacheDir}/colors-gtk.css");
  '';

  xdg.configFile."gtk-4.0/gtk.css".text = ''
    @import url("file://${walCacheDir}/colors-gtk.css");
  '';
}
