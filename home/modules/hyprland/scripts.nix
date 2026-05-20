# File: home/modules/hyprland/scripts.nix
{ pkgs, ... }:
let
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

  walColorExport = pkgs.writeShellScriptBin "wal-color-export" ''
    #!/usr/bin/env bash
    WALJSON="$HOME/.cache/wal/colors.json"
    OUT_DIR="$HOME/.config/current"
    OUT="$OUT_DIR/wal-colors.css"

    mkdir -p "$OUT_DIR"
    sleep 1

    if [ ! -f "$WALJSON" ]; then 
       ${pkgs.libnotify}/bin/notify-send "Lỗi" "Không tìm thấy màu từ Pywal"
       exit 1
    fi

    BG=$(${pkgs.jq}/bin/jq -r '.special.background' "$WALJSON")
    FG=$(${pkgs.jq}/bin/jq -r '.special.foreground' "$WALJSON")
    ACCENT=$(${pkgs.jq}/bin/jq -r '.colors.color4' "$WALJSON")

    hex_to_rgba() {
       local hex=''${1#\#}
       local r=$((16#''${hex:0:2}))
       local g=$((16#''${hex:2:2}))
       local b=$((16#''${hex:4:2}))
       local a=''${2:-1}
       echo "rgba(''${r}, ''${g}, ''${b}, ''${a})"
    }

    cat <<EOF > "$OUT"
    @define-color selected-text $ACCENT;
    @define-color text $(hex_to_rgba "$FG" 0.9);
    @define-color base $(hex_to_rgba "$BG" 0.4);
    @define-color border $(hex_to_rgba "$ACCENT" 0.7);
    @define-color foreground $(hex_to_rgba "$FG" 0.9);
    @define-color background $(hex_to_rgba "$BG" 0.9);
    EOF

    ${pkgs.libnotify}/bin/notify-send "Thành công" "Màu hệ thống đã được đồng bộ!"
    pkill walker || true
  '';

  cycleBackground = pkgs.writeShellScriptBin "cycle-background" ''
    #!/usr/bin/env bash
    BACKGROUNDS_DIR="$HOME/Pictures/wallpapers"
    CURRENT_BACKGROUND_LINK="$HOME/.config/current-wallpaper"

    mapfile -d "" -t BACKGROUNDS < <(find "$BACKGROUNDS_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | sort -z)
    TOTAL=''${#BACKGROUNDS[@]}

    if [[ $TOTAL -eq 0 ]]; then 
       ${pkgs.libnotify}/bin/notify-send "Lỗi" "Thư mục hình nền trống"
       exit 1
    fi

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
    
    ${pkgs.pywal}/bin/wal -i "$NEW_BACKGROUND" -n --saturate 0.7 -q -o ${walColorExport}/bin/wal-color-export -b 010101
  '';

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
       case $(menu "Power Profile" "🚀  Performance\n⚖️  Balanced\n🍃  Power Saver" "$SYSTEM_THEME") in
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
       ${pkgs.libnotify}/bin/notify-send -h string:x-canonical-private-synchronous:volume -t 2000 "🔇 Đã tắt tiếng"
    else
       ${pkgs.libnotify}/bin/notify-send -h string:x-canonical-private-synchronous:volume -h int:value:"$volume_percent" -t 2000 "Âm lượng: $volume_percent%"
    fi
  '';

  cavaJson = pkgs.writeShellScriptBin "cava-json" ''
    #!/usr/bin/env bash
    cfg="$1"
    limit=''${CAVA_SILENCE_FRAMES:-100} # ~0.5s at 60 FPS
    silence=0
    last=""
    glyphs=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

    render_frame() {
       local raw="$1"
       local rendered=""
       local active=0
       local value
       local idx
       local -a values=()

       IFS=';' read -r -a values <<< "$raw"

       for value in "''${values[@]}"; do
          [[ -z "$value" ]] && continue
          [[ "$value" =~ ^[0-9]+$ ]] || continue

          if ((value > 0)); then
             active=1
          fi

          # CAVA ascii_max_range is set to 90, so divide by 91 to map 0-90 across 8 glyph levels.
          idx=$((value * ''${#glyphs[@]} / 91))
          if ((idx >= ''${#glyphs[@]})); then
             idx=$((''${#glyphs[@]} - 1))
          fi

          rendered+="''${glyphs[$idx]}"
       done

       printf '%s:%s\n' "$active" "$rendered"
    }

    cava -p "$cfg" | while read -r line; do
       frame=$(render_frame "$line")
       active=''${frame%%:*}
       clean=''${frame#*:}

       if ((active == 0)); then
          ((silence++))
          if ((silence >= limit)); then
             printf '{"text":"","class":"silent"}\n'
          else
             printf '{"text":"%s","class":"active idle"}\n' "$last"
          fi
       else
          silence=0
          last="$clean"
          printf '{"text":"%s","class":"active"}\n' "$clean"
       fi
    done
  '';

in
{
  home.packages = [ 
    pkgs.pywal 
    walColorExport
    waybarAuto 
    cycleBackground 
    walkerMenu
    volumeOsd 
    cavaJson
  ];
}
