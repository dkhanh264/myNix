{ pkgs, ... }:
let
  walkerMenu = pkgs.writeShellScriptBin "walker-menu" ''
      #!/usr/bin/env bash
      
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
         case $(menu "Power Profile" "󰾅  Performance\n󰾅  Balanced\n󰾅  Power Saver" "$SYSTEM_THEME") in
         *Performance*) 
            powerprofilesctl set performance 
            ${pkgs.libnotify}/bin/notify-send -t 2000 "Power Profile" "Đã chuyển sang Hiệu năng cao" 
            ;;
         *Balanced*) 
            powerprofilesctl set balanced 
            ${pkgs.libnotify}/bin/notify-send -t 2000 "Power Profile" "Đã chuyển sang Cân bằng" 
            ;;
         *Saver*) 
            powerprofilesctl set power-saver 
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
  xdg.configFile."walker".source = ../hyprland/dotfiles/walker;
}
