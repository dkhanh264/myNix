{ pkgs, ... }:
let
  walkerMenu = pkgs.writeShellScriptBin "walker-menu" ''
      
      APP_THEME="transparent-apps"
      SYSTEM_THEME="transparent-system"
  
      menu() { printf '%b\n' "$2" | walker --dmenu --theme "$3" -p "$1…"; }
  
      system_menu() {
         case $(menu "System" "Lock\nSuspend\nRestart\nShut down\nSign out" "$SYSTEM_THEME") in
         *Lock*) hyprlock ;;
         *Suspend*) systemctl suspend ;;
         *Restart*) systemctl reboot ;;
         *Shut*) systemctl poweroff ;;
         *Sign*) hyprctl dispatch exit ;;
         esac
      }
  
      profile_menu() {
         BRIGHTNESS_STATE="/tmp/.brightness_before_powersave"

         case $(menu "Power mode" "Performance\nBalanced\nPower saver" "$SYSTEM_THEME") in
         *Performance*) 
            powerprofilesctl set performance 
            hyprctl keyword monitor "eDP-1, 1920x1080@144, 1920x0, 1"
            if [ -f "$BRIGHTNESS_STATE" ]; then
               brightnessctl set "$(cat "$BRIGHTNESS_STATE")" >/dev/null 2>&1
               rm -f "$BRIGHTNESS_STATE"
            fi
            ${pkgs.libnotify}/bin/notify-send -t 2000 "Power mode" "Performance mode enabled"
            ;;
         *Balanced*) 
            powerprofilesctl set balanced 
            hyprctl keyword monitor "eDP-1, 1920x1080@144, 1920x0, 1"
            if [ -f "$BRIGHTNESS_STATE" ]; then
               brightnessctl set "$(cat "$BRIGHTNESS_STATE")" >/dev/null 2>&1
               rm -f "$BRIGHTNESS_STATE"
            fi
            ${pkgs.libnotify}/bin/notify-send -t 2000 "Power mode" "Balanced mode enabled"
            ;;
         *Saver*) 
            powerprofilesctl set power-saver 
            hyprctl keyword monitor "eDP-1, 1920x1080@60, 1920x0, 1"
            if [ ! -f "$BRIGHTNESS_STATE" ]; then
               brightnessctl get > "$BRIGHTNESS_STATE"
            fi
            brightnessctl set 40% >/dev/null 2>&1
            ${pkgs.libnotify}/bin/notify-send -t 2000 "Power mode" "Power saver enabled"
            ;;
         esac
      }

      wallpaper_menu() {
         WALLPAPER_DIR="$HOME/Pictures/wallpapers"
         if [ ! -d "$WALLPAPER_DIR" ]; then
            ${pkgs.libnotify}/bin/notify-send "Wallpaper" \
              "Create ~/Pictures/wallpapers and add an image first"
            return 1
         fi

         SELECTION=$(find "$WALLPAPER_DIR" -type f \( \
           -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \
           -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" -o -iname "*.mov" \
         \) -printf '%P\n' | sort \
           | walker --dmenu --theme "$APP_THEME" -p "Choose wallpaper…")

         if [ -n "$SELECTION" ]; then
            set-background "$SELECTION"
         fi
      }

      launcher_menu() {
         case $(menu "Launcher" "Applications\nWallpapers" "$SYSTEM_THEME") in
         *Applications*) walker --theme "$APP_THEME" ;;
         *Wallpapers*) wallpaper_menu ;;
         esac
      }
  
      case "''${1:-apps}" in
      system) system_menu ;;
      profile) profile_menu ;;
      wallpapers) wallpaper_menu ;;
      launcher) launcher_menu ;;
      apps) walker --theme "$APP_THEME" ;;
      esac
    '';

in
{
  home.packages = [ walkerMenu ];
  xdg.configFile."walker" = {
    source = ./walker;
    recursive = true;
    force = true;
  };
}
