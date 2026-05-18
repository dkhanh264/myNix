{ ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    settings = {
      background_opacity      = "0.85";
      confirm_os_window_close = 0;
      enable_audio_bell       = false;
      cursor_shape            = "beam";
      tab_bar_style           = "powerline";
      tab_powerline_style     = "slanted";
    };
    theme = "Tokyo Night";
  };
}
