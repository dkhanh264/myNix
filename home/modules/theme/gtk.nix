# File: home/modules/theme/gtk.nix
{ pkgs, ... }:

let
  aospCursor = pkgs.stdenvNoCC.mkDerivation {
    pname = "aosp-cursors";
    version = "local";

    src = ../../assets/cursors/aosp-cursors;

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/share/icons/aosp-cursors"
      cp -r "$src"/. "$out/share/icons/aosp-cursors/"

      runHook postInstall
    '';
  };
in
{
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = ":";
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = ":";
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/wm/preferences" = {
        button-layout = ":";
      };
    };
  };

  home.pointerCursor = {
    enable = true;

    name = "aosp-cursors";
    package = aospCursor;
    size = 24;

    gtk.enable = true;
    x11.enable = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };
}
