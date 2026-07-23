{ pkgs, ... }:
let
  walColorExport = pkgs.writeShellScriptBin "wal-color-export" ''
      WALJSON="$HOME/.cache/wal/colors.json"
      OUT_DIR="$HOME/.config/current"
      OUT="$OUT_DIR/wal-colors.css"
      KITTY_WAL="$HOME/.config/kitty/wal-theme.conf"
      BTOP_THEME_DIR="$HOME/.config/btop/themes"
      BTOP_THEME="$BTOP_THEME_DIR/wal.theme"
      MAKO_WAL_DIR="$HOME/.cache/wal"
      MAKO_WAL_CONF="$MAKO_WAL_DIR/mako-colors.conf"
  
      mkdir -p "$OUT_DIR"
  
      if [ ! -f "$WALJSON" ]; then 
         ${pkgs.libnotify}/bin/notify-send "Theme error" "No Pywal palette was found"
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
      pkill -SIGUSR2 waybar || true
  
      # Persist terminal colors and live-apply to running Kitty windows.
      mkdir -p "$(dirname "$KITTY_WAL")"
      cat <<EOF > "$KITTY_WAL"
      background $BG
      foreground $FG
      selection_background $FG
      selection_foreground $BG
      cursor $FG
  
      color0  $(${pkgs.jq}/bin/jq -r '.colors.color0' "$WALJSON")
      color1  $(${pkgs.jq}/bin/jq -r '.colors.color1' "$WALJSON")
      color2  $(${pkgs.jq}/bin/jq -r '.colors.color2' "$WALJSON")
      color3  $(${pkgs.jq}/bin/jq -r '.colors.color3' "$WALJSON")
      color4  $(${pkgs.jq}/bin/jq -r '.colors.color4' "$WALJSON")
      color5  $(${pkgs.jq}/bin/jq -r '.colors.color5' "$WALJSON")
      color6  $(${pkgs.jq}/bin/jq -r '.colors.color6' "$WALJSON")
      color7  $(${pkgs.jq}/bin/jq -r '.colors.color7' "$WALJSON")
      color8  $(${pkgs.jq}/bin/jq -r '.colors.color8' "$WALJSON")
      color9  $(${pkgs.jq}/bin/jq -r '.colors.color9' "$WALJSON")
      color10 $(${pkgs.jq}/bin/jq -r '.colors.color10' "$WALJSON")
      color11 $(${pkgs.jq}/bin/jq -r '.colors.color11' "$WALJSON")
      color12 $(${pkgs.jq}/bin/jq -r '.colors.color12' "$WALJSON")
      color13 $(${pkgs.jq}/bin/jq -r '.colors.color13' "$WALJSON")
      color14 $(${pkgs.jq}/bin/jq -r '.colors.color14' "$WALJSON")
      color15 $(${pkgs.jq}/bin/jq -r '.colors.color15' "$WALJSON")
      EOF
      ${pkgs.kitty}/bin/kitty @ set-colors -a "$KITTY_WAL" >/dev/null 2>&1 || true
  
      # Generate btop theme from pywal palette so btop stays synced across restarts.
      mkdir -p "$BTOP_THEME_DIR"
      cat <<EOF > "$BTOP_THEME"
      theme[main_bg]="$BG"
      theme[main_fg]="$FG"
      theme[title]="$ACCENT"
      theme[hi_fg]="$ACCENT"
      theme[selected_bg]="$ACCENT"
      theme[selected_fg]="$BG"
      theme[inactive_fg]="$(${pkgs.jq}/bin/jq -r '.colors.color8' "$WALJSON")"
      theme[graph_text]="$(${pkgs.jq}/bin/jq -r '.colors.color6' "$WALJSON")"
      theme[meter_bg]="$(${pkgs.jq}/bin/jq -r '.colors.color0' "$WALJSON")"
      theme[proc_misc]="$(${pkgs.jq}/bin/jq -r '.colors.color5' "$WALJSON")"
      theme[cpu_box]="$(${pkgs.jq}/bin/jq -r '.colors.color4' "$WALJSON")"
      theme[mem_box]="$(${pkgs.jq}/bin/jq -r '.colors.color3' "$WALJSON")"
      theme[net_box]="$(${pkgs.jq}/bin/jq -r '.colors.color2' "$WALJSON")"
      theme[proc_box]="$(${pkgs.jq}/bin/jq -r '.colors.color1' "$WALJSON")"
      theme[div_line]="$(${pkgs.jq}/bin/jq -r '.colors.color8' "$WALJSON")"
      theme[temp_start]="$(${pkgs.jq}/bin/jq -r '.colors.color2' "$WALJSON")"
      theme[temp_mid]="$(${pkgs.jq}/bin/jq -r '.colors.color3' "$WALJSON")"
      theme[temp_end]="$(${pkgs.jq}/bin/jq -r '.colors.color1' "$WALJSON")"
      theme[cpu_start]="$(${pkgs.jq}/bin/jq -r '.colors.color2' "$WALJSON")"
      theme[cpu_mid]="$(${pkgs.jq}/bin/jq -r '.colors.color3' "$WALJSON")"
      theme[cpu_end]="$(${pkgs.jq}/bin/jq -r '.colors.color1' "$WALJSON")"
      theme[free_start]="$(${pkgs.jq}/bin/jq -r '.colors.color2' "$WALJSON")"
      theme[free_mid]="$(${pkgs.jq}/bin/jq -r '.colors.color3' "$WALJSON")"
      theme[free_end]="$(${pkgs.jq}/bin/jq -r '.colors.color1' "$WALJSON")"
      theme[cached_start]="$(${pkgs.jq}/bin/jq -r '.colors.color6' "$WALJSON")"
      theme[cached_mid]="$(${pkgs.jq}/bin/jq -r '.colors.color4' "$WALJSON")"
      theme[cached_end]="$(${pkgs.jq}/bin/jq -r '.colors.color5' "$WALJSON")"
      theme[available_start]="$(${pkgs.jq}/bin/jq -r '.colors.color6' "$WALJSON")"
      theme[available_mid]="$(${pkgs.jq}/bin/jq -r '.colors.color4' "$WALJSON")"
      theme[available_end]="$(${pkgs.jq}/bin/jq -r '.colors.color5' "$WALJSON")"
      theme[used_start]="$(${pkgs.jq}/bin/jq -r '.colors.color2' "$WALJSON")"
      theme[used_mid]="$(${pkgs.jq}/bin/jq -r '.colors.color3' "$WALJSON")"
      theme[used_end]="$(${pkgs.jq}/bin/jq -r '.colors.color1' "$WALJSON")"
      theme[download_start]="$(${pkgs.jq}/bin/jq -r '.colors.color2' "$WALJSON")"
      theme[download_mid]="$(${pkgs.jq}/bin/jq -r '.colors.color3' "$WALJSON")"
      theme[download_end]="$(${pkgs.jq}/bin/jq -r '.colors.color1' "$WALJSON")"
      theme[upload_start]="$(${pkgs.jq}/bin/jq -r '.colors.color6' "$WALJSON")"
      theme[upload_mid]="$(${pkgs.jq}/bin/jq -r '.colors.color4' "$WALJSON")"
      theme[upload_end]="$(${pkgs.jq}/bin/jq -r '.colors.color5' "$WALJSON")"
      EOF
  
      # Keep notification daemon in sync with current system palette.
      mkdir -p "$MAKO_WAL_DIR"
      cat <<EOF > "$MAKO_WAL_CONF"
      background-color=''${BG}99
      text-color=$FG
      border-color=$ACCENT
      EOF
      ${pkgs.mako}/bin/makoctl reload >/dev/null 2>&1 || true
  
      ${pkgs.libnotify}/bin/notify-send -t 2200 "Theme updated" \
        "System colors now match your wallpaper"
      pkill walker || true
    '';

  setBackground = pkgs.writeShellScriptBin "set-background" ''
      BACKGROUNDS_DIR="$HOME/Pictures/wallpapers"
      CURRENT_BACKGROUND_LINK="$HOME/.config/current-wallpaper"

      BACKGROUND_PATH="''${1:-}"
      if [[ -z "$BACKGROUND_PATH" ]]; then
        ${pkgs.libnotify}/bin/notify-send "Wallpaper" "No wallpaper was selected"
        exit 1
      fi

      if [[ "$BACKGROUND_PATH" = /* ]]; then
        NEW_BACKGROUND="$BACKGROUND_PATH"
      else
        NEW_BACKGROUND="$BACKGROUNDS_DIR/$BACKGROUND_PATH"
      fi
      WALLPAPER_ROOT=$(${pkgs.coreutils}/bin/realpath -m "$BACKGROUNDS_DIR")
      NEW_BACKGROUND=$(${pkgs.coreutils}/bin/realpath -m "$NEW_BACKGROUND")

      case "$NEW_BACKGROUND" in
        "$WALLPAPER_ROOT"/*) ;;
        *)
          ${pkgs.libnotify}/bin/notify-send "Wallpaper error" \
            "Select a file from ~/Pictures/wallpapers"
          exit 1
          ;;
      esac

      if [[ ! -f "$NEW_BACKGROUND" ]]; then
        ${pkgs.libnotify}/bin/notify-send "Wallpaper error" \
          "The selected file no longer exists"
        exit 1
      fi

      case "''${NEW_BACKGROUND,,}" in
        *.jpg|*.jpeg|*.png|*.webp|*.mp4|*.mkv|*.webm|*.avi|*.mov) ;;
        *)
          ${pkgs.libnotify}/bin/notify-send "Wallpaper error" \
            "That file type is not supported"
          exit 1
          ;;
      esac

      mkdir -p "$(dirname "$CURRENT_BACKGROUND_LINK")"
      ln -nsf "$NEW_BACKGROUND" "$CURRENT_BACKGROUND_LINK"

      is_video() {
        local file="''${1,,}"
        case "$file" in
          *.mp4|*.mkv|*.webm|*.avi|*.mov) return 0 ;;
          *) return 1 ;;
        esac
      }

      pkill mpvpaper || true
      pkill swaybg || true

      if is_video "$NEW_BACKGROUND"; then
        ${pkgs.mpvpaper}/bin/mpvpaper "*" \
          --mpv-options "loop no-audio" "$NEW_BACKGROUND" >/dev/null 2>&1 &

        TMPFRAME=$(mktemp /tmp/wallpaper-frame-XXXXXX.png)
        ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$NEW_BACKGROUND" -vframes 1 -q:v 2 \
          "$TMPFRAME" >/dev/null 2>&1
        ${pkgs.pywal}/bin/wal -i "$TMPFRAME" -n --saturate 0.7 -q \
          -o ${walColorExport}/bin/wal-color-export -b 010101
        rm -f "$TMPFRAME"
      else
        if ! pgrep -x swww-daemon >/dev/null 2>&1; then
          ${pkgs.swww}/bin/swww-daemon >/dev/null 2>&1 &
          sleep 0.3
        fi

        TRANSITIONS=(fade wipe wave grow center outer)
        TRANSITION_INDEX=$((RANDOM % ''${#TRANSITIONS[@]}))
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

  cycleBackground = pkgs.writeShellScriptBin "cycle-background" ''
      BACKGROUNDS_DIR="$HOME/Pictures/wallpapers"
      CURRENT_BACKGROUND_LINK="$HOME/.config/current-wallpaper"

      mapfile -d "" -t BACKGROUNDS < <(find "$BACKGROUNDS_DIR" -type f \( \
        -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \
        -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" -o -iname "*.mov" \
      \) -print0 | sort -z)
      TOTAL=''${#BACKGROUNDS[@]}

      if [[ $TOTAL -eq 0 ]]; then
         ${pkgs.libnotify}/bin/notify-send "Wallpaper" "The wallpaper folder is empty"
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

      exec ${setBackground}/bin/set-background "$NEW_BACKGROUND"
    '';

in
{
  home.packages = [ pkgs.pywal walColorExport setBackground cycleBackground ];
}
