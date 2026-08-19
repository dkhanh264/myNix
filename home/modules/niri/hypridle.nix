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
        # Giảm độ sáng màn hình sau 3 phút (180s)
        {
          timeout = 180;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
        # Tự động khóa màn hình sau 5 phút (300s)
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        # Tắt màn hình sau 10 phút (600s)
        {
          timeout = 600;
          on-timeout = "niri msg action power-off-monitors";
        }
      ];
    };
  };
}
