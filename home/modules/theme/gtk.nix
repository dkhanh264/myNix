# File: home/modules/theme/gtk.nix
{ pkgs, ... }:

let
  frierenCursor = pkgs.stdenvNoCC.mkDerivation {
    pname = "frierenblz-cursor-theme";
    version = "local";

    src = ../../../assets/cursors/FrierenBLZ;

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/share/icons/FrierenBLZ"
      cp -r "$src"/. "$out/share/icons/FrierenBLZ/"

      runHook postInstall
    '';
  };
in
{
  home.packages = with pkgs; [
    pywal
  ];

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
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  home.pointerCursor = {
    enable = true;

    name = "FrierenBLZ";
    package = frierenCursor;
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
