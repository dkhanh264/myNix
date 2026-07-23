{ lib, pkgs, ... }:
let
  fallbackCavaTheme = pkgs.writeText "cava-wal-fallback" ''
    [color]
    foreground = '#E9E7EF'
    gradient = 1
    gradient_color_1 = '#A9C7FF'
    gradient_color_2 = '#C0C1FF'
    gradient_color_3 = '#D7B9FF'
    gradient_color_4 = '#F3B7DD'
    gradient_color_5 = '#9DDBD4'
  '';


  fallbackBtopTheme = pkgs.writeText "btop-wal-fallback" ''
    theme[main_bg]="#1b1b1f"
    theme[main_fg]="#e5e1e6"
    theme[title]="#c0c1ff"
    theme[hi_fg]="#a9c7ff"
    theme[selected_bg]="#a9c7ff"
    theme[selected_fg]="#1b1b1f"
    theme[inactive_fg]="#938f99"
    theme[graph_text]="#d7b9ff"
    theme[meter_bg]="#1b1b1f"
    theme[proc_misc]="#f3b7dd"
    theme[cpu_box]="#a9c7ff"
    theme[mem_box]="#d7b9ff"
    theme[net_box]="#9ddbd4"
    theme[proc_box]="#c0c1ff"
    theme[div_line]="#938f99"
    theme[temp_start]="#9ddbd4"
    theme[temp_mid]="#f3b7dd"
    theme[temp_end]="#ffb4ab"
    theme[cpu_start]="#9ddbd4"
    theme[cpu_mid]="#f3b7dd"
    theme[cpu_end]="#ffb4ab"
    theme[free_start]="#ffb4ab"
    theme[free_mid]="#f3b7dd"
    theme[free_end]="#9ddbd4"
    theme[cached_start]="#d7b9ff"
    theme[cached_mid]="#a9c7ff"
    theme[cached_end]="#f3b7dd"
    theme[available_start]="#d7b9ff"
    theme[available_mid]="#a9c7ff"
    theme[available_end]="#f3b7dd"
    theme[used_start]="#9ddbd4"
    theme[used_mid]="#f3b7dd"
    theme[used_end]="#ffb4ab"
    theme[download_start]="#9ddbd4"
    theme[download_mid]="#d7b9ff"
    theme[download_end]="#a9c7ff"
    theme[upload_start]="#a9c7ff"
    theme[upload_mid]="#f3b7dd"
    theme[upload_end]="#d7b9ff"
    theme[process_start]="#9ddbd4"
    theme[process_mid]="#f3b7dd"
    theme[process_end]="#ffb4ab"
  '';

  fallbackHyprlockTheme = pkgs.writeText "hyprlock-wal-fallback" ''
    $bg = rgba(27, 27, 31, 1.0)
    $fg = rgba(229, 225, 230, 1.0)
    $primary = rgba(169, 199, 255, 1.0)
    $primary_bright = rgba(192, 193, 255, 1.0)
    $secondary = rgba(243, 183, 221, 1.0)
    $tertiary = rgba(215, 185, 255, 1.0)
    $surface = rgba(27, 27, 31, 0.70)
    $surface_container = rgba(35, 36, 42, 0.85)
    $on_primary = rgba(17, 19, 24, 1.0)
    $error = rgba(255, 180, 171, 1.0)
  '';

  walColorExport = pkgs.writeShellApplication {
    name = "wal-color-export";
    runtimeInputs = with pkgs; [
      coreutils
      hyprland
      jq
      kitty
      libnotify
      procps
    ];
    text = ''
      set -Eeuo pipefail

      WAL_JSON="$HOME/.cache/wal/colors.json"
      CURRENT_DIR="$HOME/.config/current"
      SEMANTIC_PALETTE="$CURRENT_DIR/system-palette.json"
      GTK_COLORS="$CURRENT_DIR/wal-colors.css"
      KITTY_COLORS="$HOME/.config/kitty/wal-theme.conf"
      BTOP_COLORS="$HOME/.config/btop/themes/wal.theme"
      CAVA_COLORS="$HOME/.config/cava/themes/wal"
      HYPR_COLORS="$HOME/.config/hypr/wal-colors.conf"
      HYPRLOCK_COLORS="$HOME/.config/hypr/hyprlock-colors.conf"

      declare -a TEMP_FILES=()
      cleanup() {
        if (( ''${#TEMP_FILES[@]} > 0 )); then
          rm -f -- "''${TEMP_FILES[@]}"
        fi
      }
      trap cleanup EXIT

      notify_error() {
        notify-send -a "System Theme" -u critical -t 5000 \
          "Theme update failed" "$1" || true
      }

      # Write in the destination directory, then rename. Readers therefore see
      # either the complete old palette or the complete new one.
      atomic_write() {
        local target="$1"
        local directory temporary
        directory=$(dirname -- "$target")
        mkdir -p -- "$directory"
        temporary=$(mktemp --tmpdir="$directory" ".''${target##*/}.XXXXXX")
        TEMP_FILES+=("$temporary")
        cat > "$temporary"
        chmod 0644 "$temporary"

        if [[ -f "$target" ]] && cmp -s -- "$temporary" "$target"; then
          rm -f -- "$temporary"
          return 1
        fi

        mv -f -- "$temporary" "$target"
        return 0
      }

      css_rgba() {
        local hex="''${1#\#}"
        local alpha="''${2:-1}"
        printf 'rgba(%d, %d, %d, %s)' \
          "$((16#''${hex:0:2}))" \
          "$((16#''${hex:2:2}))" \
          "$((16#''${hex:4:2}))" \
          "$alpha"
      }

      readable_on_color() {
        local hex="''${1#\#}"
        local red green blue yiq
        red=$((16#''${hex:0:2}))
        green=$((16#''${hex:2:2}))
        blue=$((16#''${hex:4:2}))
        yiq=$(((red * 299 + green * 587 + blue * 114) / 1000))
        if (( yiq >= 150 )); then
          printf '111318'
        else
          printf 'f5f3fa'
        fi
      }

      if [[ ! -r "$WAL_JSON" ]]; then
        notify_error "No readable Pywal palette was found."
        exit 1
      fi

      # Parse and validate the palette once. This avoids 19 jq processes and
      # prevents a partial/invalid colors.json from reaching application files.
      if ! PALETTE_TSV=$(jq -er '
        [
          .special.background,
          .special.foreground,
          .colors.color0, .colors.color1, .colors.color2, .colors.color3,
          .colors.color4, .colors.color5, .colors.color6, .colors.color7,
          .colors.color8, .colors.color9, .colors.color10, .colors.color11,
          .colors.color12, .colors.color13, .colors.color14, .colors.color15
        ] as $palette
        | if ($palette | all(.[];
            type == "string" and test("^#[0-9A-Fa-f]{6}$")))
          then $palette | @tsv
          else error("palette contains a missing or malformed color")
          end
      ' "$WAL_JSON"); then
        notify_error "Pywal produced an incomplete or malformed palette."
        exit 1
      fi

      IFS=$'\t' read -r \
        BG FG C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 C10 C11 C12 C13 C14 C15 \
        <<< "$PALETTE_TSV"

      PRIMARY="$C4"
      PRIMARY_BRIGHT="$C12"
      SECONDARY="$C5"
      SECONDARY_BRIGHT="$C13"
      TERTIARY="$C6"
      TERTIARY_BRIGHT="$C14"
      SURFACE="$C0"
      MUTED="$C8"
      SUCCESS="$C2"
      WARNING="$C3"
      ERROR="#ffb4ab"
      ERROR_CONTAINER="#5a2225"
      ON_ERROR="#2b0b0e"

      BG_HEX="''${BG#\#}"
      FG_HEX="''${FG#\#}"
      PRIMARY_HEX="''${PRIMARY#\#}"
      PRIMARY_BRIGHT_HEX="''${PRIMARY_BRIGHT#\#}"
      SECONDARY_HEX="''${SECONDARY#\#}"
      TERTIARY_HEX="''${TERTIARY#\#}"
      MUTED_HEX="''${MUTED#\#}"
      ON_PRIMARY_HEX=$(readable_on_color "$PRIMARY")
      ON_SECONDARY_HEX=$(readable_on_color "$SECONDARY")

      changed_any=0
      css_changed=0
      kitty_changed=0
      cava_changed=0
      hypr_changed=0

      if atomic_write "$SEMANTIC_PALETTE" <<EOF
      {
        "background": "$BG",
        "foreground": "$FG",
        "surface": "$SURFACE",
        "surfaceVariant": "$MUTED",
        "primary": "$PRIMARY",
        "primaryBright": "$PRIMARY_BRIGHT",
        "secondary": "$SECONDARY",
        "secondaryBright": "$SECONDARY_BRIGHT",
        "tertiary": "$TERTIARY",
        "tertiaryBright": "$TERTIARY_BRIGHT",
        "success": "$SUCCESS",
        "warning": "$WARNING",
        "error": "$ERROR",
        "errorContainer": "$ERROR_CONTAINER",
        "onError": "$ON_ERROR"
      }
EOF
      then
        changed_any=1
      fi

      # Legacy role names stay available for Waybar and Walker, while the new
      # semantic names give future consumers one stable palette contract.
      if atomic_write "$GTK_COLORS" <<EOF
      @define-color selected-text $PRIMARY;
      @define-color text $(css_rgba "$FG" 0.94);
      @define-color base $(css_rgba "$BG" 0.46);
      @define-color border $(css_rgba "$PRIMARY" 0.78);
      @define-color foreground $(css_rgba "$FG" 0.94);
      @define-color background $(css_rgba "$BG" 0.92);
      @define-color primary $PRIMARY;
      @define-color primary-bright $PRIMARY_BRIGHT;
      @define-color secondary $SECONDARY;
      @define-color tertiary $TERTIARY;
      @define-color surface $(css_rgba "$SURFACE" 0.72);
      @define-color surface-variant $(css_rgba "$MUTED" 0.28);
      @define-color outline $(css_rgba "$MUTED" 0.64);
      @define-color success $SUCCESS;
      @define-color warning $WARNING;
      @define-color error $ERROR;
EOF
      then
        changed_any=1
        css_changed=1
      fi

      if atomic_write "$KITTY_COLORS" <<EOF
      background $BG
      foreground $FG
      cursor $PRIMARY_BRIGHT
      cursor_text_color $BG
      selection_background $PRIMARY
      selection_foreground $BG
      url_color $TERTIARY
      active_border_color $PRIMARY
      inactive_border_color $MUTED
      bell_border_color $WARNING
      active_tab_background $PRIMARY
      active_tab_foreground $BG
      inactive_tab_background $SURFACE
      inactive_tab_foreground $FG

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
      then
        changed_any=1
        kitty_changed=1
      fi

      if atomic_write "$BTOP_COLORS" <<EOF
      theme[main_bg]="$BG"
      theme[main_fg]="$FG"
      theme[title]="$PRIMARY_BRIGHT"
      theme[hi_fg]="$PRIMARY"
      theme[selected_bg]="$PRIMARY"
      theme[selected_fg]="$BG"
      theme[inactive_fg]="$MUTED"
      theme[graph_text]="$TERTIARY"
      theme[meter_bg]="$SURFACE"
      theme[proc_misc]="$SECONDARY"
      theme[cpu_box]="$PRIMARY"
      theme[mem_box]="$WARNING"
      theme[net_box]="$SUCCESS"
      theme[proc_box]="$C1"
      theme[div_line]="$MUTED"
      theme[temp_start]="$SUCCESS"
      theme[temp_mid]="$WARNING"
      theme[temp_end]="$C1"
      theme[cpu_start]="$SUCCESS"
      theme[cpu_mid]="$WARNING"
      theme[cpu_end]="$C1"
      theme[free_start]="$C1"
      theme[free_mid]="$WARNING"
      theme[free_end]="$SUCCESS"
      theme[cached_start]="$TERTIARY"
      theme[cached_mid]="$PRIMARY"
      theme[cached_end]="$SECONDARY"
      theme[available_start]="$TERTIARY"
      theme[available_mid]="$PRIMARY"
      theme[available_end]="$SECONDARY"
      theme[used_start]="$SUCCESS"
      theme[used_mid]="$WARNING"
      theme[used_end]="$C1"
      theme[download_start]="$SUCCESS"
      theme[download_mid]="$TERTIARY"
      theme[download_end]="$PRIMARY"
      theme[upload_start]="$PRIMARY"
      theme[upload_mid]="$SECONDARY"
      theme[upload_end]="$TERTIARY"
      theme[process_start]="$SUCCESS"
      theme[process_mid]="$WARNING"
      theme[process_end]="$C1"
EOF
      then
        changed_any=1
      fi

      # Cava reads colors from this standalone theme, so SIGUSR2 can update the
      # gradient without reinitializing PipeWire or its FFT pipeline.
      if atomic_write "$CAVA_COLORS" <<EOF
      [color]
      foreground = '$FG'
      gradient = 1
      gradient_color_1 = '$PRIMARY'
      gradient_color_2 = '$PRIMARY_BRIGHT'
      gradient_color_3 = '$SECONDARY'
      gradient_color_4 = '$SECONDARY_BRIGHT'
      gradient_color_5 = '$TERTIARY'
      gradient_color_6 = '$TERTIARY_BRIGHT'
EOF
      then
        changed_any=1
        cava_changed=1
      fi


      # Hyprland sources this file after its static fallbacks. Full option paths
      # make the generated contract independent of the Nix attribute layout.
      if atomic_write "$HYPR_COLORS" <<EOF
      # Generated by wal-color-export. Manual edits will be replaced.
      general:col.active_border = rgba(''${PRIMARY_HEX}ff) rgba(''${SECONDARY_HEX}ff) 45deg
      general:col.inactive_border = rgba(''${MUTED_HEX}66)
      group:col.border_active = rgba(''${PRIMARY_HEX}ff)
      group:col.border_inactive = rgba(''${MUTED_HEX}66)
      group:col.border_locked_active = rgba(''${SECONDARY_HEX}ff)
      group:col.border_locked_inactive = rgba(''${MUTED_HEX}4d)
      group:groupbar:col.active = rgba(''${PRIMARY_HEX}ff)
      group:groupbar:col.inactive = rgba(''${MUTED_HEX}66)
      group:groupbar:col.locked_active = rgba(''${SECONDARY_HEX}ff)
      group:groupbar:col.locked_inactive = rgba(''${MUTED_HEX}4d)
      group:groupbar:text_color = rgba(''${ON_PRIMARY_HEX}ff)
      group:groupbar:text_color_inactive = rgba(''${FG_HEX}cc)
      group:groupbar:text_color_locked_active = rgba(''${ON_SECONDARY_HEX}ff)
      group:groupbar:text_color_locked_inactive = rgba(''${FG_HEX}b3)
EOF
      then
        changed_any=1
        hypr_changed=1
      fi

      if atomic_write "$HYPRLOCK_COLORS" <<EOF
      \$bg = rgba(''${BG_HEX}ff)
      \$fg = rgba(''${FG_HEX}ff)
      \$primary = rgba(''${PRIMARY_HEX}ff)
      \$primary_bright = rgba(''${PRIMARY_BRIGHT_HEX}ff)
      \$secondary = rgba(''${SECONDARY_HEX}ff)
      \$tertiary = rgba(''${TERTIARY_HEX}ff)
      \$surface = rgba(''${BG_HEX}aa)
      \$surface_container = rgba(''${BG_HEX}dd)
      \$on_primary = rgba(''${ON_PRIMARY_HEX}ff)
      \$error = rgba(ffb4abff)
EOF
      then
        changed_any=1
      fi

      # Notify immediately as soon as colors are updated so user feedback is instant
      if (( changed_any )); then
        notify-send -a "System Theme" -i preferences-desktop-theme -t 3000 \
          "Đã cập nhật giao diện" "Màu hệ thống đã đồng bộ theo hình nền mới." || true
      fi

      # Reload consumers whose generated files changed
      if (( css_changed )); then
        pkill -USR2 -x waybar >/dev/null 2>&1 || true
        pkill -x walker >/dev/null 2>&1 || true
      fi
      if (( kitty_changed )); then
        kitty @ set-colors --all "$KITTY_COLORS" >/dev/null 2>&1 || true
      fi
      if (( cava_changed )); then
        pkill -USR2 -x cava >/dev/null 2>&1 || true
      fi
      if (( hypr_changed )); then
        hyprctl reload config-only >/dev/null 2>&1 || true
      fi

      pkill -USR2 -x btop >/dev/null 2>&1 || true
    '';
  };

  setBackground = pkgs.writeShellApplication {
    name = "set-background";
    runtimeInputs = with pkgs; [
      coreutils
      ffmpeg
      imagemagick
      libnotify
      mpvpaper
      procps
      pywal
      swww
    ];
    text = ''
      set -Eeuo pipefail

      BACKGROUNDS_DIR="$HOME/Pictures/wallpapers"
      CURRENT_BACKGROUND_LINK="$HOME/.config/current-wallpaper"
      TEMP_FRAME=""
      TEMP_LINK_DIR=""
      declare -a TEMP_FILES=()

      cleanup() {
        [[ -z "$TEMP_FRAME" ]] || rm -f -- "$TEMP_FRAME"
        [[ -z "$TEMP_LINK_DIR" ]] || rm -rf -- "$TEMP_LINK_DIR"
        if (( ''${#TEMP_FILES[@]} > 0 )); then
          rm -f -- "''${TEMP_FILES[@]}"
        fi
      }
      trap cleanup EXIT

      notify_wallpaper_error() {
        notify-send -a "Wallpaper" -u critical -t 5000 \
          "Wallpaper error" "$1"
      }

      is_video() {
        local file="''${1,,}"
        case "$file" in
          *.mp4|*.mkv|*.webm|*.avi|*.mov) return 0 ;;
          *) return 1 ;;
        esac
      }

      atomic_link() {
        local target="$1"
        local link_path="$2"
        local link_directory
        link_directory=$(dirname -- "$link_path")
        mkdir -p -- "$link_directory"
        TEMP_LINK_DIR=$(mktemp -d "$link_directory/.wallpaper-link.XXXXXX")
        ln -s -- "$target" "$TEMP_LINK_DIR/current-wallpaper"
        mv -Tf -- "$TEMP_LINK_DIR/current-wallpaper" "$link_path"
        rmdir -- "$TEMP_LINK_DIR"
        TEMP_LINK_DIR=""
      }

      BACKGROUND_PATH="''${1:-}"
      if [[ -z "$BACKGROUND_PATH" ]]; then
        notify_wallpaper_error "No wallpaper was selected."
        exit 1
      fi

      WALLPAPER_ROOT=$(realpath -m -- "$BACKGROUNDS_DIR")
      if [[ "$BACKGROUND_PATH" = /* ]]; then
        NEW_BACKGROUND=$(realpath -m -- "$BACKGROUND_PATH")
      else
        NEW_BACKGROUND=$(realpath -m -- "$BACKGROUNDS_DIR/$BACKGROUND_PATH")
      fi

      case "$NEW_BACKGROUND" in
        "$WALLPAPER_ROOT"/*) ;;
        *)
          notify_wallpaper_error "Select a file from ~/Pictures/wallpapers."
          exit 1
          ;;
      esac

      if [[ ! -f "$NEW_BACKGROUND" ]]; then
        notify_wallpaper_error "The selected file no longer exists."
        exit 1
      fi

      case "''${NEW_BACKGROUND,,}" in
        *.jpg|*.jpeg|*.png|*.webp|*.mp4|*.mkv|*.webm|*.avi|*.mov) ;;
        *)
          notify_wallpaper_error "That file type is not supported."
          exit 1
          ;;
      esac

      pkill -x mpvpaper >/dev/null 2>&1 || true
      pkill -x swaybg >/dev/null 2>&1 || true

      if is_video "$NEW_BACKGROUND"; then
        swww kill >/dev/null 2>&1 || true
        pkill -x swww-daemon >/dev/null 2>&1 || true

        mpvpaper "*" --mpv-options "loop no-audio" \
          "$NEW_BACKGROUND" >/dev/null 2>&1 &

        TEMP_FRAME=$(mktemp --suffix=.png /tmp/wallpaper-frame-XXXXXX)
        ffmpeg -nostdin -y -i "$NEW_BACKGROUND" -frames:v 1 -q:v 2 \
          "$TEMP_FRAME" >/dev/null 2>&1
        wal -i "$TEMP_FRAME" -n --saturate 0.7 -q \
          -o ${walColorExport}/bin/wal-color-export
      else
        if ! swww query >/dev/null 2>&1; then
          swww-daemon >/dev/null 2>&1 &
          for _ in {1..20}; do
            swww query >/dev/null 2>&1 && break
            sleep 0.05
          done
        fi

        if ! swww query >/dev/null 2>&1; then
          notify_wallpaper_error "The wallpaper daemon did not become ready."
          exit 1
        fi

        TRANSITIONS=(fade wipe wave grow center outer)
        SELECTED_TRANSITION="''${TRANSITIONS[RANDOM % ''${#TRANSITIONS[@]}]}"
        swww img "$NEW_BACKGROUND" \
          --transition-type "$SELECTED_TRANSITION" \
          --transition-duration 1 \
          --transition-fps 60 \
          >/dev/null 2>&1

        WAL_SAMPLE=$(mktemp --suffix=.png /tmp/wallpaper-sample-XXXXXX)
        TEMP_FILES+=("$WAL_SAMPLE")
        convert "$NEW_BACKGROUND" -resize 360x360^ "$WAL_SAMPLE" 2>/dev/null || cp -- "$NEW_BACKGROUND" "$WAL_SAMPLE"

        wal -i "$WAL_SAMPLE" -n --saturate 0.7 -q \
          -o ${walColorExport}/bin/wal-color-export
      fi

      atomic_link "$NEW_BACKGROUND" "$CURRENT_BACKGROUND_LINK"
    '';
  };

  cycleBackground = pkgs.writeShellApplication {
    name = "cycle-background";
    runtimeInputs = with pkgs; [ coreutils findutils libnotify ];
    text = ''
      set -Eeuo pipefail

      BACKGROUNDS_DIR="$HOME/Pictures/wallpapers"
      CURRENT_BACKGROUND_LINK="$HOME/.config/current-wallpaper"

      if [[ ! -d "$BACKGROUNDS_DIR" ]]; then
        notify-send -a "Wallpaper" -u critical -t 5000 \
          "Wallpaper error" "The wallpaper folder does not exist."
        exit 1
      fi

      mapfile -d "" -t BACKGROUNDS < <(
        LC_ALL=C find "$BACKGROUNDS_DIR" -type f \( \
          -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
          -iname "*.webp" -o -iname "*.mp4" -o -iname "*.mkv" -o \
          -iname "*.webm" -o -iname "*.avi" -o -iname "*.mov" \
        \) -print0 | LC_ALL=C sort -z
      )
      TOTAL=''${#BACKGROUNDS[@]}

      if (( TOTAL == 0 )); then
        notify-send -a "Wallpaper" -u normal -t 3500 \
          "Wallpaper" "The wallpaper folder is empty."
        exit 1
      fi

      CURRENT_BACKGROUND=""
      if [[ -L "$CURRENT_BACKGROUND_LINK" ]]; then
        CURRENT_BACKGROUND=$(realpath -m -- "$CURRENT_BACKGROUND_LINK")
      fi

      INDEX=-1
      for i in "''${!BACKGROUNDS[@]}"; do
        if [[ "''${BACKGROUNDS[$i]}" == "$CURRENT_BACKGROUND" ]]; then
          INDEX=$i
          break
        fi
      done

      NEXT_INDEX=$(((INDEX + 1) % TOTAL))
      exec ${setBackground}/bin/set-background "''${BACKGROUNDS[$NEXT_INDEX]}"
    '';
  };
in
{
  # Keep behavior settings immutable while the generated theme remains a
  # small, mutable file. This lets Cava reload colors without restarting.
  xdg.configFile."cava/config" = {
    force = true;
    text = ''
      [general]
      live-config = 0
      framerate = 60
      autosens = 1
      sensitivity = 100
      bars = 0
      bar_width = 2
      bar_spacing = 1
      center_align = 1
      lower_cutoff_freq = 50
      higher_cutoff_freq = 12000
      sleep_timer = 3

      [input]
      method = pipewire
      source = auto

      [output]
      method = noncurses
      orientation = bottom
      channels = stereo
      mono_option = average
      synchronized_sync = 1
      show_idle_bar_heads = 0

      [color]
      theme = 'wal'

      [smoothing]
      monstercat = 1
      waves = 0
      noise_reduction = 80
    '';
  };

  # Runtime includes must exist even on a fresh install or after the Pywal
  # cache is cleared. The exporter replaces these fallbacks atomically.
  home.activation.ensureRuntimePaletteFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    btop_theme="$HOME/.config/btop/themes/wal.theme"
    if [[ ! -e "$btop_theme" ]]; then
      run mkdir -p "$(dirname "$btop_theme")"
      run install -m 0644 ${fallbackBtopTheme} "$btop_theme"
    fi

    hyprlock_theme="$HOME/.config/hypr/hyprlock-colors.conf"
    if [[ ! -e "$hyprlock_theme" ]]; then
      run mkdir -p "$(dirname "$hyprlock_theme")"
      run install -m 0644 ${fallbackHyprlockTheme} "$hyprlock_theme"
    fi

    cava_theme="$HOME/.config/cava/themes/wal"
    if [[ ! -e "$cava_theme" ]]; then
      run mkdir -p "$(dirname "$cava_theme")"
      run install -m 0644 ${fallbackCavaTheme} "$cava_theme"
    fi


  '';

  # Re-export an existing Pywal cache during activation so newly added
  # consumers receive the current wallpaper palette without waiting for the
  # user to change wallpapers again. A fresh install without a cache remains
  # valid and keeps the declarative fallbacks above.
  home.activation.refreshSystemPalette = lib.hm.dag.entryAfter
    [ "ensureRuntimePaletteFiles" "linkGeneration" ]
    ''
      if [[ -r "$HOME/.cache/wal/colors.json" ]]; then
        if ! run ${walColorExport}/bin/wal-color-export; then
          echo "warning: keeping fallback colors because palette export failed" >&2
        fi
      fi
    '';

  home.packages = [
    pkgs.pywal
    walColorExport
    setBackground
    cycleBackground
  ];
}
