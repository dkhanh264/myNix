{ pkgs, lib, ... }:
let
  btopThemeTemplate = ''
    # Matugen generated theme for btop
    # Main background, empty for terminal default, need to be also set to false in btop.conf
    theme[main_bg]="{{colors.surface.default.hex}}"

    # Main text color
    theme[main_fg]="{{colors.on_surface.default.hex}}"

    # Title color for boxes
    theme[title]="{{colors.primary.default.hex}}"

    # Highlight color for keyboard shortcuts
    theme[hi_fg]="{{colors.primary.default.hex}}"

    # Background color of selected item in processes box
    theme[selected_bg]="{{colors.primary.default.hex}}"

    # Foreground color of selected item in processes box
    theme[selected_fg]="{{colors.on_primary.default.hex}}"

    # Color of inactive/disabled text
    theme[inactive_fg]="{{colors.outline.default.hex}}"

    # Color of text in graphs
    theme[graph_text]="{{colors.on_surface_variant.default.hex}}"

    # Background color of the percentage meters
    theme[meter_bg]="{{colors.surface_container_highest.default.hex}}"

    # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
    theme[proc_misc]="{{colors.tertiary.default.hex}}"

    # Cpu box outline color
    theme[cpu_box]="{{colors.primary.default.hex}}"

    # Memory/disks box outline color
    theme[mem_box]="{{colors.secondary.default.hex}}"

    # Net up/down box outline color
    theme[net_box]="{{colors.tertiary.default.hex}}"

    # Processes box outline color
    theme[proc_box]="{{colors.primary.default.hex}}"

    # Box divider line and small boxes line color
    theme[div_line]="{{colors.outline_variant.default.hex}}"

    # Temperature graph colors
    theme[temp_start]="{{colors.primary.default.hex}}"
    theme[temp_mid]="{{colors.tertiary.default.hex}}"
    theme[temp_end]="{{colors.error.default.hex}}"

    # CPU graph colors
    theme[cpu_start]="{{colors.primary.default.hex}}"
    theme[cpu_mid]="{{colors.tertiary.default.hex}}"
    theme[cpu_end]="{{colors.error.default.hex}}"

    # Mem/Disk free meter
    theme[free_start]="{{colors.tertiary.default.hex}}"
    theme[free_mid]="{{colors.secondary.default.hex}}"
    theme[free_end]="{{colors.primary.default.hex}}"

    # Mem/Disk cached meter
    theme[cached_start]="{{colors.secondary.default.hex}}"
    theme[cached_mid]="{{colors.tertiary.default.hex}}"
    theme[cached_end]="{{colors.primary.default.hex}}"

    # Mem/Disk available meter
    theme[available_start]="{{colors.secondary.default.hex}}"
    theme[available_mid]="{{colors.tertiary.default.hex}}"
    theme[available_end]="{{colors.primary.default.hex}}"

    # Mem/Disk used meter
    theme[used_start]="{{colors.primary.default.hex}}"
    theme[used_mid]="{{colors.tertiary.default.hex}}"
    theme[used_end]="{{colors.error.default.hex}}"

    # Download graph colors
    theme[download_start]="{{colors.secondary.default.hex}}"
    theme[download_mid]="{{colors.tertiary.default.hex}}"
    theme[download_end]="{{colors.primary.default.hex}}"

    # Upload graph colors
    theme[upload_start]="{{colors.primary.default.hex}}"
    theme[upload_mid]="{{colors.tertiary.default.hex}}"
    theme[upload_end]="{{colors.secondary.default.hex}}"

    # Process box color gradient for threads, mem and cpu usage
    theme[process_start]="{{colors.primary.default.hex}}"
    theme[process_mid]="{{colors.tertiary.default.hex}}"
    theme[process_end]="{{colors.error.default.hex}}"
  '';

  fallbackBtopTheme = pkgs.writeText "btop-matugen-fallback" ''
    # Fallback Matugen theme for btop
    theme[main_bg]="#141218"
    theme[main_fg]="#e6e0e8"
    theme[title]="#d0bcfe"
    theme[hi_fg]="#d0bcfe"
    theme[selected_bg]="#d0bcfe"
    theme[selected_fg]="#37265d"
    theme[inactive_fg]="#948f99"
    theme[graph_text]="#cac4cf"
    theme[meter_bg]="#36343a"
    theme[proc_misc]="#f0b8c7"
    theme[cpu_box]="#d0bcfe"
    theme[mem_box]="#ccc2db"
    theme[net_box]="#f0b8c7"
    theme[proc_box]="#d0bcfe"
    theme[div_line]="#49454e"
    theme[temp_start]="#d0bcfe"
    theme[temp_mid]="#f0b8c7"
    theme[temp_end]="#ffb4ab"
    theme[cpu_start]="#d0bcfe"
    theme[cpu_mid]="#f0b8c7"
    theme[cpu_end]="#ffb4ab"
    theme[free_start]="#f0b8c7"
    theme[free_mid]="#ccc2db"
    theme[free_end]="#d0bcfe"
    theme[cached_start]="#ccc2db"
    theme[cached_mid]="#f0b8c7"
    theme[cached_end]="#d0bcfe"
    theme[available_start]="#ccc2db"
    theme[available_mid]="#f0b8c7"
    theme[available_end]="#d0bcfe"
    theme[used_start]="#d0bcfe"
    theme[used_mid]="#f0b8c7"
    theme[used_end]="#ffb4ab"
    theme[download_start]="#ccc2db"
    theme[download_mid]="#f0b8c7"
    theme[download_end]="#d0bcfe"
    theme[upload_start]="#d0bcfe"
    theme[upload_mid]="#f0b8c7"
    theme[upload_end]="#ccc2db"
    theme[process_start]="#d0bcfe"
    theme[process_mid]="#f0b8c7"
    theme[process_end]="#ffb4ab"
  '';
in
{
  programs.btop = {
    enable = true;
    package = pkgs.btop.override { cudaSupport = true; };
    settings = {
      color_theme = "matugen";
      theme_background = false;
      truecolor = true;
      graph_symbol = "braille";
      update_ms = 1000;
      shown_boxes = "cpu mem net proc gpu0";
      show_gpu_info = "Auto";
      selected_gpu = "Auto";
      show_battery = true;
      show_battery_watts = true;
      check_temp = true;
      gpu_mirror_graph = true;
    };
  };

  xdg.configFile."matugen/templates/btop.theme".text = btopThemeTemplate;
  xdg.configFile."matugen/config.toml".text = ''
    [config]
    reload_apps = true

    [templates.btop]
    input_path = "templates/btop.theme"
    output_path = "~/.config/btop/themes/matugen.theme"
    post_reload = "pkill -SIGUSR2 -x btop 2>/dev/null || true"
  '';

  home.activation.ensureBtopMatugenTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    btop_theme="$HOME/.config/btop/themes/matugen.theme"
    if [[ ! -e "$btop_theme" ]]; then
      run mkdir -p "$(dirname "$btop_theme")"
      run install -m 0644 ${fallbackBtopTheme} "$btop_theme"
    fi

    wp=""
    for screen_wp in "$HOME/.cache/serpantinum/wallpaper/current_"*; do
      if [[ -f "$screen_wp" && ! "$screen_wp" =~ _name$ && ! "$screen_wp" =~ \.png$ && ! "$screen_wp" =~ \.json$ ]]; then
        candidate=$(cat "$screen_wp" 2>/dev/null || true)
        if [[ -n "$candidate" && -f "$candidate" ]]; then
          wp="$candidate"
          break
        fi
      fi
    done
    if [[ -z "$wp" && -f "$HOME/.config/current-wallpaper" ]]; then
      candidate=$(realpath "$HOME/.config/current-wallpaper" 2>/dev/null || true)
      if [[ -n "$candidate" && -f "$candidate" ]]; then
        wp="$candidate"
      fi
    fi
    if [[ -n "$wp" && -f "$wp" ]] && [[ -x "${pkgs.matugen}/bin/matugen" ]]; then
      ${pkgs.matugen}/bin/matugen image "$wp" --source-color-index 0 \
        -c "$HOME/.config/matugen/config.toml" 2>/dev/null || true
    fi

    if pgrep -x btop >/dev/null 2>&1; then
      pkill -SIGUSR2 -x btop 2>/dev/null || true
    fi
  '';
}
