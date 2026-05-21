{ ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 11;
    };
    settings = {
      background_opacity = "0.4";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      cursor_shape = "beam";
    };
    theme = "Tokyo Night";
    extraConfig = ''
      # Enable bold text rendering with bright colors (like Alacritty)
      draw_bold_text_with_bright_colors yes
      
      # Window padding (14px uniform padding like Alacritty x=14 y=14)
      window_padding_width 14

      # Colors matching Alacritty theme
      background #222222
      foreground #F8F8F2

      # Keyboard bindings
      map f11 toggle_fullscreen
    '';
  };
}
