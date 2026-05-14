# File: home/modules/hyprland/scripts.nix
{ pkgs, config, ... }:
let
  # 1. Tự động ẩn hiện Waybar
  waybarAuto = pkgs.writeShellScriptBin "waybar-auto" ''
    #!/usr/bin/env bash
    bar_visible=true
    trap "exit" SIGINT SIGTERM
    waybar -c ~/.config/waybar/min.jsonc -s ~/.config/waybar/min.css >/dev/null 2>&1 &
    
    while true; do
       Y=$(hyprctl cursorpos -j | ${pkgs.jq}/bin/jq '.y' 2>/dev/null)
       [[ -z "$Y" ]] && sleep 0.1 && continue

       if ((Y <= 5)) && $bar_visible; then
          sleep 0.4
          y=$(hyprctl cursorpos -j | ${pkgs.jq}/bin/jq '.y' 2>/dev/null)
          [[ -z "$y" ]] && sleep 0.1 && continue
          if ((y <= 5)); then
             waybar -c ~/.config/waybar/max.jsonc -s ~/.config/waybar/max.css >/dev/null 2>&1 &
             pkill -f "min.css"
             bar_visible=false
          fi
       elif ((Y > 40)) && ! $bar_visible; then
          pkill -f "max.css"
          waybar -c ~/.config/waybar/min.jsonc -s ~/.config/waybar/min.css >/dev/null 2>&1 &
          bar_visible=true
       fi
       sleep 0.1
    done
  '';

  # 2. Đổi hình nền tuần tự
  cycleBackground = pkgs.writeShellScriptBin "cycle-background" ''
    #!/usr/bin/env bash
    BACKGROUNDS_DIR="$HOME/Pictures/wallpapers"
    CURRENT_BACKGROUND_LINK="$HOME/.config/current-wallpaper"

    mapfile -d ''\''' -t BACKGROUNDS < <(find "$BACKGROUNDS_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | sort -z)
    TOTAL=''${#BACKGROUNDS[@]}

    if [[ $TOTAL -eq 0 ]]; then exit 1; fi

    if [[ -L "$CURRENT_BACKGROUND_LINK" ]]; then
       CURRENT_BACKGROUND=$(readlink "$CURRENT_BACKGROUND_LINK")
    else
       CURRENT_BACKGROUND=""
    fi

    INDEX=-1
    for i in "''${!BACKGROUNDS[@]}"; do
       if [[ "''${BACKGROUNDS[$i]}" == "$CURRENT_BACKGROUND" ]]; then
          INDEX=$i
          break
       fi
    done

    NEXT_INDEX=$(((INDEX + 1) % TOTAL))
    NEW_BACKGROUND="''${BACKGROUNDS[$NEXT_INDEX]}"

    ln -nsf "$NEW_BACKGROUND" "$CURRENT_BACKGROUND_LINK"
    pkill swaybg || true
    ${pkgs.swaybg}/bin/swaybg -i "$CURRENT_BACKGROUND_LINK" -m fill >/dev/null 2>&1 &
    
    # Kích hoạt tạo màu Pywal
    systemctl --user restart pywal-theme.service
  '';

  # 3. Thông báo OSD âm lượng
  volumeOsd = pkgs.writeShellScriptBin "volume-osd" ''
    #!/usr/bin/env bash
    case "$1" in
    up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    esac

    volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    muted=$(echo "$volume" | grep -o "MUTED")
    volume_percent=$(echo "$volume" | awk '{print int($2 * 100)}')

    if [ -n "$muted" ]; then
       notify-send -h string:x-canonical-private-synchronous:volume -t 2000 "🔇 Đã tắt tiếng"
    else
       notify-send -h string:x-canonical-private-synchronous:volume -h int:value:"$volume_percent" -t 2000 "Âm lượng: $volume_percent%"
    fi
  '';

  # 4. Walker Menu (Ứng dụng & Nguồn)
  walkerMenu = pkgs.writeShellScriptBin "walker-menu" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    menu() { echo -e "$2" | walker --dmenu -p "$1…"; }

    system_menu() {
       case $(menu "System" "  Lock\n󰤄  Suspend\n󰜉  Reboot\n󰐥  Shutdown\n  Logout") in
       *Lock*) hyprlock ;;
       *Suspend*) systemctl suspend ;;
       *Reboot*) systemctl reboot ;;
       *Shutdown*) systemctl poweroff ;;
       *Logout*) hyprctl dispatch exit ;;
       esac
    }

    case "''${1:-apps}" in
    system) system_menu ;;
    apps) walker -p "Launch…" ;;
    esac
  '';

in
{
  home.packages = [ waybarAuto cycleBackground volumeOsd walkerMenu ];
}
