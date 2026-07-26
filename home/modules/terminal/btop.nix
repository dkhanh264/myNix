{ config, pkgs, ... }: {
  programs.btop = {
    enable = true;
    settings = {
      # wal-color-export maintains ~/.config/btop/themes/wal.theme.
      color_theme = "wal";
      theme_background = false;
      truecolor = true;
      graph_symbol = "braille";
      update_ms = 1000;
    };
  };
}
