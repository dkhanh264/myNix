{ pkgs, ... }:
{
  programs.btop = {
    enable = true;
    package = pkgs.btop.override { cudaSupport = true; };
    settings = {
      # wal-color-export maintains ~/.config/btop/themes/wal.theme.
      color_theme = "wal";
      theme_background = false;
      truecolor = true;
      graph_symbol = "braille";
      update_ms = 1000;
      shown_boxes = "cpu mem net proc gpu0";
      show_gpu_info = "Auto";
      selected_gpu = "Auto";
      show_battery = true;
      show_battery_watts = true;
      check_temp = true;
      gpu_mirror_graph = true;
    };
  };
}
