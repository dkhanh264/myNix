{ pkgs, ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd     = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd            = "qs ipc call lockscreen lock";
      };

      listener = [
        # Giảm độ sáng màn hình sau 3 phút (180s)
        {
          timeout = 180;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
      ];
    };
  };
}
