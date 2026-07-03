{ pkgs, ... }:
let
  walkerMenu = pkgs.writeShellScriptBin "walker-menu" ''
      
      APP_THEME="--theme transparent-apps"
      SYSTEM_THEME="--theme transparent-system"
  
      menu() { echo -e "$2" | walker --dmenu $3 -p "$1…"; }
  
      system_menu() {
         case $(menu "System" "  Lock\n󰤄  Suspend\n󰜉  Reboot\n󰐥  Shutdown\n  Logout" "$SYSTEM_THEME") in
         *Lock*) hyprlock ;;
         *Suspend*) systemctl suspend ;;
         *Reboot*) systemctl reboot ;;
         *Shutdown*) systemctl poweroff ;;
         *Logout*) hyprctl dispatch exit ;;
         esac
      }
  
      profile_menu() {
         BRIGHTNESS_STATE="/tmp/.brightness_before_powersave"

         case $(menu "Power Profile" "󰾅  Performance\n󰾅  Balanced\n󰾅  Power Saver" "$SYSTEM_THEME") in
         *Performance*) 
            powerprofilesctl set performance 
            hyprctl keyword monitor "eDP-1, 1920x1080@144, 1920x0, 1"
            if [ -f "$BRIGHTNESS_STATE" ]; then
               brightnessctl set "$(cat "$BRIGHTNESS_STATE")" >/dev/null 2>&1
               rm -f "$BRIGHTNESS_STATE"
            fi
            ${pkgs.libnotify}/bin/notify-send -t 2000 "Power Profile" "Đã chuyển sang Hiệu năng cao" 
            ;;
         *Balanced*) 
            powerprofilesctl set balanced 
            hyprctl keyword monitor "eDP-1, 1920x1080@144, 1920x0, 1"
            if [ -f "$BRIGHTNESS_STATE" ]; then
               brightnessctl set "$(cat "$BRIGHTNESS_STATE")" >/dev/null 2>&1
               rm -f "$BRIGHTNESS_STATE"
            fi
            ${pkgs.libnotify}/bin/notify-send -t 2000 "Power Profile" "Đã chuyển sang Cân bằng" 
            ;;
         *Saver*) 
            powerprofilesctl set power-saver 
            hyprctl keyword monitor "eDP-1, 1920x1080@60, 1920x0, 1"
            if [ ! -f "$BRIGHTNESS_STATE" ]; then
               brightnessctl get > "$BRIGHTNESS_STATE"
            fi
            brightnessctl set 40% >/dev/null 2>&1
            ${pkgs.libnotify}/bin/notify-send -t 2000 "Power Profile" "Đã chuyển sang Tiết kiệm pin" 
            ;;
         esac
      }
  
      case "''${1:-apps}" in
      system) system_menu ;;
      profile) profile_menu ;;
      apps) walker $APP_THEME ;;
      esac
    '';

in
{
  home.packages = [ walkerMenu ];
  xdg.configFile."walker" = {
    source = ./walker;
    recursive = true;
  };
}
