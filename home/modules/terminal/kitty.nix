_: {
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 11;
    };
    settings = {
      # Frosted glass effect
      background_opacity = "0.47";
      dynamic_background_opacity = "yes";
      hide_window_decorations = "yes";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      cursor_shape = "beam";
      allow_remote_control = "yes";
    };
    themeFile = "tokyo_night_night";
    extraConfig = ''
      # Window padding (14px uniform padding like Alacritty x=14 y=14)
      window_padding_width 14

      # Dynamic pywal colors generated on wallpaper switch
      include ~/.config/kitty/wal-theme.conf

      # Keyboard bindings
      map f11 toggle_fullscreen
    '';
  };
}
