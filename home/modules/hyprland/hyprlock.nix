{ config, pkgs, ... }:

let
  fontColor = "rgba(248,248,242,1.0)";
  checkColor = "rgba(139,233,253,1.0)";
  innerColor = "rgba(100,100,100,0.2)";
  outerColor = "rgba(0,0,0,0.3)";
in
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = true;
        grace = 300;
        hide_cursor = true;
      };

      background = [
        {
          monitor = "";
          path = "/home/dk/.config/current-wallpaper";
          blur_passes = 3;
        }
      ];

      animations = {
        enabled = false;
      };

      input-field = [
        {
          monitor = "";

          size = "600, 120";
          position = "0, 0";
          halign = "center";
          valign = "center";

          outline_thickness = 4;

          inner_color = innerColor;
          outer_color = outerColor;

          font_family = "CaskaydiaMono Nerd Font";
          font_color = fontColor;

          placeholder_text = " Enter Password 󰈷 ";
          check_color = checkColor;
          fail_text = "<i>$PAMFAIL ($ATTEMPTS)</i>";

          rounding = 10;
          shadow_passes = 0;
          fade_on_empty = false;

          dots_size = 0.2;
          dots_spacing = 0.2;
        }
      ];

      auth = {
        "fingerprint:enabled" = false;
      };
    };
  };
}
