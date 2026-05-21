{ ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 11;
    };
    settings = {
      background_opacity      = "0.4";
      confirm_os_window_close = 0;
      enable_audio_bell       = false;
      cursor_shape            = "beam";
      draw_bold_text_with_bright_colors = true;
      # Font offsets
      font_size = 11;
      modify_font = "cell_height +0px";
    };
    theme = "Tokyo Night";
    extraConfig = ''
      # Window padding similar to alacritty
      window_padding_width 14 14

      # Colors
      background #222222
      foreground #F8F8F2

      # Keyboard bindings
      map f11 toggle_fullscreen
    '';
  };
}
