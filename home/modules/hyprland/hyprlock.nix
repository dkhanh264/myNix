{ config, pkgs, ... }: {
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
          path = "/home/yourusername/Pictures/wallpaper.png"; 
          blur_passes = 2;
        }
      ];
      input-field = [
        {
          monitor = "eDP-1";
          size = "250, 60";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.2;
          fade_on_empty = false;
        }
      ];
    };
  };
}
