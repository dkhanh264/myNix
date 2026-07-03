{ config, pkgs, ... }: {
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "TTY"; 
      theme_background = false;
      truecolor = true;
      graph_symbol = "braille";
      update_ms = 1000;
    };
  };
}
