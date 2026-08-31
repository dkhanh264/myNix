{ lib, serpantinum, ... }:
let
  serpantinumKittyConf = builtins.readFile "${serpantinum}/config/kitty/kitty.conf";
  customizedKittyConf = lib.replaceStrings
    [
      "background_opacity 1.0"
      "font_size        16.0"
    ]
    [
      ''
        # Frosted glass blur effect
        background_opacity 0.56
        dynamic_background_opacity yes
        background_blur 1''
      "font_size        12.0"
    ]
    serpantinumKittyConf;
in
{
  programs.kitty = {
    enable = true;
    extraConfig = customizedKittyConf;
  };
}




