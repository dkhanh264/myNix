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
        # Dim screen brightness after 2 minutes (120s)
        {
          timeout = 120;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
        # Lock screen after 4 minutes (240s)
        {
          timeout = 240;
          on-timeout = "loginctl lock-session";
        }
        # Turn off monitors after 6 minutes (360s)
        {
          timeout = 360;
          on-timeout = "niri msg action power-off-monitors";
        }
        # Tự động ngủ sâu (Suspend) sau 15 phút (900s) không sử dụng để bảo toàn pin
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
