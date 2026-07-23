{ pkgs, lib, ... }:

let
  # The runtime palette exporter replaces this file atomically after Pywal
  # finishes.  Keeping a small fallback here makes the sourced Hyprland
  # fragment valid on first login and when the Pywal cache has been cleared.
  defaultHyprlandPalette = pkgs.writeText "hyprland-default-palette.conf" ''
    general:col.active_border = rgba(bec2ffff) rgba(c6bfffff) 45deg
    general:col.inactive_border = rgba(8e9099a6)

    group:col.border_active = rgba(bec2ffff) rgba(c6bfffff) 45deg
    group:col.border_inactive = rgba(8e909986)
    group:col.border_locked_active = rgba(c6bfffff) rgba(bec2ffff) 45deg
    group:col.border_locked_inactive = rgba(8e909970)

    group:groupbar:col.active = rgba(bec2ffff)
    group:groupbar:col.inactive = rgba(242731ee)
    group:groupbar:col.locked_active = rgba(c6bfffff)
    group:groupbar:col.locked_inactive = rgba(242731ee)
    group:groupbar:text_color = rgba(191b24ff)
    group:groupbar:text_color_inactive = rgba(c6c5ccff)
    group:groupbar:text_color_locked_active = rgba(191b24ff)
    group:groupbar:text_color_locked_inactive = rgba(c6c5ccff)

    decoration:shadow:color = rgba(05070ca6)
    decoration:shadow:color_inactive = rgba(05070c66)
  '';

  captureScreen = pkgs.writeShellApplication {
    name = "capture-screen";
    runtimeInputs = with pkgs; [ coreutils grim slurp wl-clipboard libnotify ];
    text = ''
      set -Eeuo pipefail

      mode="''${1:-region}"
      case "$mode" in
        region|full) ;;
        *)
          printf 'Usage: capture-screen {region|full}\n' >&2
          exit 2
          ;;
      esac

      screenshot_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
      mkdir -p -- "$screenshot_dir"
      screenshot_path=$(mktemp --tmpdir="$screenshot_dir" \
        "screenshot-$(date +%Y-%m-%d_%H-%M-%S)-XXXXXX.png")
      completed=0
      cleanup() {
        (( completed )) || rm -f -- "$screenshot_path"
      }
      trap cleanup EXIT

      if [[ "$mode" == "region" ]]; then
        selection="$(slurp)" || exit 0
        [[ -n "$selection" ]] || exit 0
        grim -g "$selection" "$screenshot_path"
      else
        grim "$screenshot_path"
      fi

      wl-copy --type image/png < "$screenshot_path"
      completed=1
      notify-send -a "Screenshot" -u normal -t 4500 \
        -h string:x-canonical-private-synchronous:screenshot \
        -i "$screenshot_path" "Screenshot copied" \
        "Saved to $screenshot_path" || true
    '';
  };
in
{
  home.activation.ensureHyprlandPalette = lib.hm.dag.entryBetween
    [ "linkGeneration" ]
    [ "writeBoundary" ]
    ''
      palette_dir="$HOME/.config/hypr"
      palette_path="$palette_dir/wal-colors.conf"

      $DRY_RUN_CMD mkdir -p "$palette_dir"
      if [ ! -e "$palette_path" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 \
          ${defaultHyprlandPalette} "$palette_path"
      fi
    '';

  # Các package chuyên biệt cho Hyprland
  home.packages = with pkgs; [
    hyprlock 
    hypridle
    captureScreen
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # ── Monitors ──────────────────────────────────────────────────────
      # eDP-1 là màn hình laptop, HDMI-A-1 là màn hình ngoài.
      monitor = [
        "eDP-1, 1920x1080@144, 1920x0, 1"
        "HDMI-A-1, highrr, 0x0, 1"
      ];

      # ── NVIDIA + Wayland env vars ──────────────────────────────────────
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "XCURSOR_SIZE,24"
        "MOZ_ENABLE_WAYLAND,1"
        "QT_QPA_PLATFORM,wayland"
        "GDK_BACKEND,wayland,x11"
      ];

      cursor = {
        no_hardware_cursors = true;
      };

      # ── Autostart ─────────────────────────────────────────────────────
      exec-once = [
        "quickshell"
        "wl-paste --type text --watch cliphist store"
        "fcitx5 -d"
        "swww-daemon"  # Daemon cho hình nền có hiệu ứng chuyển cảnh
      ];

      # ── General ───────────────────────────────────────────────────────
      general = {
        gaps_in               = 6;
        gaps_out              = 12;
        border_size           = 2;
        # Static semantic fallback.  The sourced Pywal fragment below is
        # appended last and overrides these colors without rebuilding Home
        # Manager whenever the wallpaper changes.
        "col.active_border"   = "rgba(bec2ffff) rgba(c6bfffff) 45deg";
        "col.inactive_border" = "rgba(8e9099a6)";
        layout                = "dwindle";
        resize_on_border      = true;
      };

      decoration = {
        # A restrained squircle reads consistently with the MD3 surfaces in
        # Quickshell while leaving tiled windows visually compact.
        rounding = 16;
        rounding_power = 3.0;
        shadow = {
          enabled        = true;
          range          = 8;
          render_power   = 3;
          ignore_window  = true;
          color          = "rgba(05070ca6)";
          color_inactive = "rgba(05070c66)";
          offset         = "0 3";
          scale          = 0.985;
        };
        blur = {
          enabled            = true;
          size               = 18;
          passes             = 4;
          new_optimizations  = true;
          ignore_opacity     = true;
          popups             = true;
          popups_ignorealpha = 0.05;
          noise              = 0.015;
          contrast           = 1.08;
          brightness         = 0.92;
          vibrancy           = 0.28;
          vibrancy_darkness  = 0.12;
        };
      };

      # Hyprland only draws text itself for a few compositor-owned surfaces.
      # Match those to the same UI family and semantic palette as Quickshell.
      group = {
        "col.border_active"          = "rgba(bec2ffff) rgba(c6bfffff) 45deg";
        "col.border_inactive"        = "rgba(8e909986)";
        "col.border_locked_active"   = "rgba(c6bfffff) rgba(bec2ffff) 45deg";
        "col.border_locked_inactive" = "rgba(8e909970)";

        groupbar = {
          enabled                     = true;
          font_family                 = "Noto Sans";
          font_size                   = 11;
          font_weight_active          = "semibold";
          font_weight_inactive        = "normal";
          height                      = 28;
          indicator_height            = 3;
          indicator_gap               = 2;
          gradients                   = true;
          gradient_rounding           = 8;
          gradient_rounding_power     = 3.0;
          gradient_round_only_edges   = false;
          gaps_in                     = 3;
          gaps_out                    = 3;
          keep_upper_gap              = true;
          "col.active"               = "rgba(bec2ffff)";
          "col.inactive"             = "rgba(242731ee)";
          "col.locked_active"        = "rgba(c6bfffff)";
          "col.locked_inactive"      = "rgba(242731ee)";
          text_color                  = "rgba(191b24ff)";
          text_color_inactive         = "rgba(c6c5ccff)";
          text_color_locked_active    = "rgba(191b24ff)";
          text_color_locked_inactive  = "rgba(c6c5ccff)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "m3Standard, 0.2, 0.0, 0.0, 1.0"
          "m3Emphasized, 0.05, 0.7, 0.1, 1.0"
          "linear, 0.0, 0.0, 1.0, 1.0"
          "expressiveBounce, 0.34, 1.56, 0.64, 1.0"
        ];
        animation = [
          "border,        1, 5, m3Standard"
          "borderangle,   1, 30, linear, loop"
          "windows,       1, 6, m3Emphasized"
          "windowsIn,     1, 6, expressiveBounce, popin 94%"
          "windowsOut,    1, 5, m3Standard, popin 88%"
          "fadeIn,        1, 5, m3Emphasized"
          "fadeOut,       1, 4, m3Standard"
          "layersIn,      1, 5, m3Emphasized, fade"
          "layersOut,     1, 4, m3Standard, fade"
          "workspaces,    1, 5, m3Emphasized, slide"
        ];
      };

      input = {
        kb_layout    = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll       = true;
          disable_while_typing = true;
          tap-to-click         = true;
        };
        sensitivity = 0;
      };

      dwindle = {
        pseudotile     = true;
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo   = true;
        disable_splash_rendering = true;
        font_family             = "Noto Sans";
        splash_font_family      = "Noto Sans";
        mouse_move_enables_dpms = true;
        key_press_enables_dpms  = true;
      };

      windowrulev2 = [
        "float, class:^(pavucontrol)$"
        "float, class:^(blueman-manager)$"
        "float, title:^(Picture-in-Picture)$"
        "pin,   title:^(Picture-in-Picture)$"
        "opacity 0.95 0.90, class:^(firefox)$"
        "opacity 0.94 0.90, class:^(kitty)$"
        "opacity 0.95 0.92, class:^(org\\.gnome\\.Nautilus)$"
        "opacity 0.95 0.90, class:^(google-chrome)$"
        "opacity 0.95 0.90, class:^(discord)$"
        "opacity 0.95 0.90, class:^(Spotify)$"
        "opacity 0.95 0.90, class:^(Code|code)$"
        # Cú pháp: opacity <độ_đục_khi_đang_dùng> <độ_đục_khi_không_dùng>, class:^(tên_app)$
      ];

      "$mainMod" = "SUPER";

      bind = [
        "$mainMod, Q,    exec, kitty"
        "$mainMod, W,         exec, brave"
        "$mainMod, E,         exec, nautilus"
        
        # ── Walker & Hình nền ──────────────────────────────────────────
        "$mainMod, space,     exec, walker-menu apps"
        "$mainMod SHIFT, space, exec, quickshell ipc call launcher wallpapers"
        "$mainMod, A,         exec, qs ipc call controlCenter toggle"
        "$mainMod, escape,    exec, walker-menu system"
        "$mainMod CTRL, space, exec, cycle-background"
        "$mainMod, P, exec, walker-menu profile"
        
        "ALT, F4,         killactive"
        "$mainMod, V,         togglefloating"
        "$mainMod, F,         fullscreen, 0"
        "$mainMod, L,         exec, quickshellipc lockscreen lock || hyprlock"
        
        # Dùng walker --dmenu thay cho rofi -dmenu để gọi clipboard
        "$mainMod, C,         exec, cliphist list | walker --dmenu | cliphist decode | wl-copy"
        
        "$mainMod, left,      movefocus, l"
        "$mainMod, right,     movefocus, r"
        "$mainMod, up,        movefocus, u"
        "$mainMod, down,      movefocus, d"
        "$mainMod SHIFT, left,  movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up,    movewindow, u"
        "$mainMod SHIFT, down,  movewindow, d"
        
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        
        "$mainMod, S,       togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        
        ", Print,      exec, capture-screen region"
        "SHIFT, Print, exec, capture-screen full"
        
        # ── OSD Âm lượng & Truyền thông ────────────────────────────────
        ", XF86AudioRaiseVolume, exec, volume-osd up"
        ", XF86AudioLowerVolume, exec, volume-osd down"
        ", XF86AudioMute,        exec, volume-osd mute"
        ", XF86AudioPlay,        exec, playerctl play-pause"
        ", XF86AudioNext,        exec, playerctl next"
        ", XF86AudioPrev,        exec, playerctl previous"
        
        ", XF86MonBrightnessUp,   exec, brightness-osd up"
        ", XF86MonBrightnessDown, exec, brightness-osd down"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      # ── Blur cho các giao diện nổi (Android 17 Glassmorphic Backdrop) ────
      layerrule = [
        "blur, walker"
        "ignorezero, walker"
        "blur, waybar"
        "ignorezero, waybar"
        "blur, notifications"
        "ignorezero, notifications"
        "blur, m3-shell"
        "blurpopups, m3-shell"
        "ignorealpha 0.05, m3-shell"
        "blur, quickshell"
        "blurpopups, quickshell"
        "ignorealpha 0.05, quickshell"
      ];
    };

    # Keep the generated palette separate from the declarative config.  The
    # exporter can now update colors and issue a lightweight `hyprctl reload
    # config-only`; window geometry, bindings and monitor state remain intact.
    extraConfig = ''
      source = ~/.config/hypr/wal-colors.conf
    '';
  };
}
