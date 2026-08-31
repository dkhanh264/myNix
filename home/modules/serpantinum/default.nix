{ pkgs, lib, config, serpantinum, ... }:
{
  programs.serpantinum = {
    enable = true;
    systemd.enable = true;
    package = serpantinum.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [
        ./patches/fix-niri-multimonitor-workspaces.patch
      ];
    });

    settings = {
      wallpaperDir = "${config.home.homeDirectory}/Pictures/wallpapers";
      bar = {
        position = "top";
        style = "fill";
        time = {
          format = "HH:mm:ss";
        };
      };
      theme = {
        fontFamily = "JetBrains Mono";
        borderRadius = 10;
        matugen = true;
      };
      notifications = {
        dnd = false;
        position = "top right";
        sound = true;
      };
      idle = {
        enabled = true;
      };
    };
  };
}
