{ pkgs, lib, config, ... }:
{
  programs.serpantinum = {
    enable = true;
    systemd.enable = true;

    settings = {
      wallpaperDir = "${config.home.homeDirectory}/Pictures/wallpapers";
      bar = {
        position = "top";
        style = "modular";
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
