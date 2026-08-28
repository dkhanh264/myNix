{ pkgs, ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        ignore_dbus_inhibit = false;
        lock_cmd            = "pidof hyprlock || hyprlock";
        before_sleep_cmd    = "loginctl lock-session";
      };

      listener = [
        # Dim screen brightness after 3 minutes (180s)
        {
          timeout = 180;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
        # Lock screen after 5 minutes (300s)
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        # Turn off monitors after 10 minutes (600s)
        {
          timeout = 600;
          on-timeout = "niri msg action power-off-monitors";
        }
      ];
    };
  };
}
