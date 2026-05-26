# File: home/modules/hyprland/scripts.nix
{ pkgs, ... }:
let
  walColorExport = pkgs.writeShellScriptBin "wal-color-export" ''
    #!/usr/bin/env bash
    WALJSON="$HOME/.cache/wal/colors.json"
    OUT_DIR="$HOME/.config/waybar"
    OUT="$OUT_DIR/wal-colors.css"
    KITTY_WAL="$HOME/.config/kitty/wal-theme.conf"
    BTOP_THEME_DIR="$HOME/.config/btop/themes"
    BTOP_THEME="$BTOP_THEME_DIR/wal.theme"
    MAKO_WAL_DIR="$HOME/.cache/wal"
    MAKO_WAL_CONF="$MAKO_WAL_DIR/mako-colors.conf"

    mkdir -p "$OUT_DIR"

    if [ ! -f "$WALJSON" ]; then 
       ${pkgs.libnotify}/bin/notify-send "Lỗi" "Không tìm thấy màu từ Pywal"
       exit 1
    fi

    read -r BG FG ACCENT C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 C10 C11 C12 C13 C14 C15 < <(
      ${pkgs.jq}/bin/jq -r '[.special.background, .special.foreground, .colors.color4, .colors.color0, .colors.color1, .colors.color2, .colors.color3, .colors.color4, .colors.color5, .colors.color6, .colors.color7, .colors.color8, .colors.color9, .colors.color10, .colors.color11, .colors.color12, .colors.color13, .colors.color14, .colors.color15] | @tsv' "$WALJSON"
    )

    write_if_changed() {
      local target="$1"
      local tmp="$2"
      if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
        rm -f "$tmp"
        return 1
      fi
      mv "$tmp" "$target"
      return 0
    }

    hex_to_rgba() {
       local hex=''${1#\#}
       local r=$((16#''${hex:0:2}))
       local g=$((16#''${hex:2:2}))
       local b=$((16#''${hex:4:2}))
       local a=''${2:-1}
       echo "rgba(''${r}, ''${g}, ''${b}, ''${a})"
    }

    waybar_tmp=$(mktemp)
    cat <<EOF > "$waybar_tmp"
    @define-color selected-text $ACCENT;
    @define-color text $(hex_to_rgba "$FG" 0.9);
    @define-color base $(hex_to_rgba "$BG" 0.4);
    @define-color border $(hex_to_rgba "$ACCENT" 0.7);
    @define-color foreground $(hex_to_rgba "$FG" 0.9);
    @define-color background $(hex_to_rgba "$BG" 0.9);
    EOF
    waybar_changed=0
    write_if_changed "$OUT" "$waybar_tmp" && waybar_changed=1 || true

    # Persist terminal colors and live-apply to running Kitty windows.
    mkdir -p "$(dirname "$KITTY_WAL")"
    kitty_tmp=$(mktemp)
    cat <<EOF > "$kitty_tmp"
    background $BG
    foreground $FG
    selection_background $FG
    selection_foreground $BG
    cursor $FG

    color0  $C0
    color1  $C1
    color2  $C2
    color3  $C3
    color4  $C4
    color5  $C5
    color6  $C6
    color7  $C7
    color8  $C8
    color9  $C9
    color10 $C10
    color11 $C11
    color12 $C12
    color13 $C13
    color14 $C14
    color15 $C15
    EOF
    write_if_changed "$KITTY_WAL" "$kitty_tmp" || true
    ${pkgs.kitty}/bin/kitty @ set-colors -a "$KITTY_WAL" >/dev/null 2>&1 || true

    # Generate btop theme from pywal palette so btop stays synced across restarts.
    mkdir -p "$BTOP_THEME_DIR"
    btop_tmp=$(mktemp)
    cat <<EOF > "$btop_tmp"
    theme[main_bg]="$BG"
    theme[main_fg]="$FG"
    theme[title]="$ACCENT"
    theme[hi_fg]="$ACCENT"
    theme[selected_bg]="$ACCENT"
    theme[selected_fg]="$BG"
    theme[inactive_fg]="$C8"
    theme[graph_text]="$C6"
    theme[meter_bg]="$C0"
    theme[proc_misc]="$C5"
    theme[cpu_box]="$C4"
    theme[mem_box]="$C3"
    theme[net_box]="$C2"
    theme[proc_box]="$C1"
    theme[div_line]="$C8"
    theme[temp_start]="$C2"
    theme[temp_mid]="$C3"
    theme[temp_end]="$C1"
    theme[cpu_start]="$C2"
    theme[cpu_mid]="$C3"
    theme[cpu_end]="$C1"
    theme[free_start]="$C2"
    theme[free_mid]="$C3"
    theme[free_end]="$C1"
    theme[cached_start]="$C6"
    theme[cached_mid]="$C4"
    theme[cached_end]="$C5"
    theme[available_start]="$C6"
    theme[available_mid]="$C4"
    theme[available_end]="$C5"
    theme[used_start]="$C2"
    theme[used_mid]="$C3"
    theme[used_end]="$C1"
    theme[download_start]="$C2"
    theme[download_mid]="$C3"
    theme[download_end]="$C1"
    theme[upload_start]="$C6"
    theme[upload_mid]="$C4"
    theme[upload_end]="$C5"
    EOF
    write_if_changed "$BTOP_THEME" "$btop_tmp" || true

    # Keep notification daemon in sync with current system palette.
    mkdir -p "$MAKO_WAL_DIR"
    mako_tmp=$(mktemp)
    cat <<EOF > "$mako_tmp"
    background-color=''${BG}99
    text-color=$FG
    border-color=$ACCENT
    EOF
    write_if_changed "$MAKO_WAL_CONF" "$mako_tmp" || true
    ${pkgs.mako}/bin/makoctl reload >/dev/null 2>&1 || true

    ${pkgs.libnotify}/bin/notify-send "Thành công" "Màu hệ thống đã được đồng bộ!"
    pkill walker || true
    if [ "$waybar_changed" -eq 1 ]; then
      pkill -SIGUSR2 waybar || true
    fi
  '';

  cycleBackground = pkgs.writeShellScriptBin "cycle-background" ''
    #!/usr/bin/env bash
    BACKGROUNDS_DIR="$HOME/Pictures/wallpapers"
    CURRENT_BACKGROUND_LINK="$HOME/.config/current-wallpaper"

    mapfile -d "" -t BACKGROUNDS < <(find "$BACKGROUNDS_DIR" -type f \( \
      -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \
      -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" -o -iname "*.mov" \
    \) -print0 | sort -z)
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

    # Detect video files
    is_video() {
      local f="''${1,,}"
      case "$f" in
        *.mp4|*.mkv|*.webm|*.avi|*.mov) return 0 ;;
        *) return 1 ;;
      esac
    }

    # Kill existing wallpaper daemons
    pkill mpvpaper || true
    pkill swaybg   || true

    if is_video "$NEW_BACKGROUND"; then
      # ── Video wallpaper ──────────────────────────────────────────────
      ${pkgs.mpvpaper}/bin/mpvpaper "*" --mpv-options "loop no-audio" "$NEW_BACKGROUND" >/dev/null 2>&1 &

      # Extract first frame so pywal can generate a colour scheme
      TMPFRAME=$(mktemp /tmp/wallpaper-frame-XXXXXX.png)
      ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$NEW_BACKGROUND" -vframes 1 -q:v 2 "$TMPFRAME" >/dev/null 2>&1
      ${pkgs.pywal}/bin/wal -i "$TMPFRAME" -n --saturate 0.7 -q \
        -o ${walColorExport}/bin/wal-color-export -b 010101
      rm -f "$TMPFRAME"
    else
      # ── Static image wallpaper with varied transition ────────────────
      # Ensure swww daemon is running
      if ! pgrep -x swww-daemon >/dev/null 2>&1; then
        ${pkgs.swww}/bin/swww-daemon >/dev/null 2>&1 &
        sleep 0.5
      fi
      TRANSITIONS=(fade wipe wave grow center outer)
      TRANSITION_INDEX=$((NEXT_INDEX % ''${#TRANSITIONS[@]}))
      SELECTED_TRANSITION="''${TRANSITIONS[$TRANSITION_INDEX]}"
      ${pkgs.swww}/bin/swww img "$NEW_BACKGROUND" \
        --transition-type "$SELECTED_TRANSITION" \
        --transition-duration 1 \
        --transition-fps 60 \
        >/dev/null 2>&1

      ${pkgs.pywal}/bin/wal -i "$NEW_BACKGROUND" -n --saturate 0.7 -q \
        -o ${walColorExport}/bin/wal-color-export -b 010101
    fi
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
       case $(menu "Power Profile" "󰾅 Performance\n󰾅 Balanced\n󰾅 Power Saver" "$SYSTEM_THEME") in
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

  waybarMusic = pkgs.writeShellScriptBin "waybar-music" ''
    #!/usr/bin/env bash
    output=$(${pkgs.playerctl}/bin/playerctl metadata --format '{{playerName}}|{{title}}' 2>/dev/null)

    if [ -z "$output" ] || [ "$output" = "|" ]; then
     echo "󰝛  Chưa phát nhạc"
     exit 0
    fi

    player=$(echo "$output" | cut -d'|' -f1)
    title=$(echo "$output" | cut -d'|' -f2-)

    case "$(echo "$player" | tr '[:upper:]' '[:lower:]')" in
     spotify*)                  icon="󰓇" ;;
     firefox*|librewolf*)       icon="󰈹" ;;
     chromium*|chrome*|google*) icon="󰊯" ;;
     mpv*)                      icon="󰕓" ;;
     vlc*)                      icon="󰕼" ;;
     *)                         icon="󰝛" ;;
    esac

    [ -z "$title" ] && echo "󰝛  Chưa phát nhạc" || echo "$icon  $title"
  '';

  waybarActiveApps = pkgs.writeShellScriptBin "waybar-active-apps" ''
    #!/usr/bin/env bash
    workspace=$(hyprctl activeworkspace -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.id')

    if [ -z "$workspace" ] || [ "$workspace" = "null" ]; then
     exit 0
    fi

    mapfile -t classes < <(hyprctl clients -j 2>/dev/null \
     | ${pkgs.jq}/bin/jq -r ".[] | select(.workspace.id == $workspace) | .class" \
     | sort -u)

    icons=""
    for class in "''${classes[@]}"; do
     lower=$(echo "$class" | tr '[:upper:]' '[:lower:]')
     case "$lower" in
       firefox*|librewolf*)        icon="󰈹" ;;
       chromium*|chrome*|google*)  icon="󰊯" ;;
       code*|vscodium*|vscodiym*)  icon="󰨞" ;;
       kitty*|alacritty*|foot*|wezterm*) icon="" ;;
       spotify*)                   icon="󰓇" ;;
       discord*)                   icon="󰙯" ;;
       telegram*)                  icon="" ;;
       thunar*|nautilus*|dolphin*|nemo*) icon="󰉋" ;;
       mpv*)                       icon="󰕓" ;;
       vlc*)                       icon="󰕼" ;;
       obs*)                       icon="󰑋" ;;
       gimp*)                      icon="󰐇" ;;
       inkscape*)                  icon="󰠠" ;;
       libreoffice*)               icon="󰈙" ;;
       steam*)                     icon="󰓓" ;;
       *)                          icon="" ;;
     esac
     [ -n "$icons" ] && icons="$icons $icon" || icons="$icon"
    done

    echo "$icons"
  '';

in
{
  home.packages = [ 
    pkgs.pywal 
    walColorExport
    cycleBackground 
    walkerMenu
    volumeOsd 
    waybarMusic
    waybarActiveApps
  ];
}
