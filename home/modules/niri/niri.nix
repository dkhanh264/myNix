{ pkgs, lib, ... }:

let
  captureScreen = pkgs.writeShellApplication {
    name = "capture-screen";
    runtimeInputs = with pkgs; [
      coreutils
      grim
      slurp
      wl-clipboard
      libnotify
    ];
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

      app_title="Chụp màn hình"
      msg="Đã sao chép ảnh chụp màn hình"
      body="Đã lưu tại $screenshot_path"

      notify-send -a "$app_title" -u normal -t 4500 \
        -h string:x-canonical-private-synchronous:screenshot \
        -i "$screenshot_path" "$msg" \
        "$body" || true
    '';
  };

in
{
  home.packages = [
    captureScreen
    pkgs.xwayland-satellite
  ];

  xdg.configFile."niri/config.kdl".text = ''
    // Input device configuration
    input {
        keyboard {
            xkb {
                layout "us"
            }
            numlock
        }

        touchpad {
            tap
            natural-scroll
            dwt
        }

        mouse {
            // natural-scroll // Bỏ natural-scroll để cuộn chuột theo hướng chuẩn truyền thống
        }

        warp-mouse-to-focus
        focus-follows-mouse
    }

    // Output configuration
    // Laptop display (eDP-1)
    output "eDP-1" {
        mode "1920x1080@144.003"
        scale 1.0
        position x=0 y=0
        variable-refresh-rate
    }

    // External display (HDMI-A-1)
    output "HDMI-A-1" {
        mode "1920x1080@179.961"
        scale 1.0
        position x=1920 y=0
    }

    // Disable Client-Side Decorations globally (remove titlebars / close-minimize-maximize buttons)
    prefer-no-csd

    // Environment variables
    environment {
        LIBVA_DRIVER_NAME "nvidia"
        __GLX_VENDOR_LIBRARY_NAME "nvidia"
        GBM_BACKEND "nvidia-drm"
        NVD_BACKEND "direct"
        ELECTRON_OZONE_PLATFORM_HINT "auto"
        NIXOS_OZONE_WL "1"
        XCURSOR_SIZE "24"
        XCURSOR_THEME "FrierenBLZ"
        MOZ_ENABLE_WAYLAND "1"
        QT_QPA_PLATFORM "wayland"
        QT_WAYLAND_DISABLE_WINDOWDECORATION "1"
    }

    // Fix screencast tearing/flickering on NVIDIA
    debug {
        wait-for-frame-completion-in-pipewire
    }

    // Autostart services
    spawn-at-startup "rfkill" "unblock" "bluetooth"
    spawn-sh-at-startup "wl-paste --type text --watch cliphist store"
    spawn-at-startup "fcitx5" "-d"
    spawn-at-startup "restore-background"
    spawn-at-startup "xwayland-satellite"

    // Layout configuration
    layout {
        gaps 12
        center-focused-column "never"

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }

        focus-ring {
            width 3
            active-color "#bec2ff"
            inactive-color "#8e9099"
        }

        border {
            off
            width 2
            active-color "#bec2ff"
            inactive-color "#8e9099"
        }

        tab-indicator {
            hide-when-single-tab
            corner-radius 10
            gap 4
            width 3
            position "top"
        }

        shadow {
            on
            softness 20
            spread 2
            offset x=0 y=4
            color "#00000080"
        }
    }

    // Include dynamic Pywal palette
    include "wal-colors.kdl"

    hotkey-overlay {
        skip-at-startup
    }

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    animations {
        slowdown 1.0
    }

    // Compositor background blur settings
    blur {
        passes 3
        offset 2.0
        noise 0.0
        saturation 1.2
    }

    // Window rules
    window-rule {
        match app-id=r#"kitty"#
        background-effect {
            blur true
        }
    }

    window-rule {
        match app-id=r#"pavucontrol$"#
        match app-id=r#"blueman-manager$"#
        open-floating true
    }

    window-rule {
        match app-id=r#"firefox$"# title="^Picture-in-Picture$"
        open-floating true
    }

    window-rule {
        match app-id=r#"brave"# title="^Picture-in-Picture$"
        open-floating true
    }

    window-rule {
        geometry-corner-radius 24
        clip-to-geometry true
        draw-border-with-background false
    }

    // Keybindings
    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        // Core required binds
        Mod+Q { spawn "kitty"; }
        Mod+W { spawn "brave"; }
        Alt+F4 { close-window; }

        // Applications & System Utilities
        Mod+E { spawn "nautilus"; }
        Mod+Space { spawn "rofi-launcher"; }
        Mod+Ctrl+Space { spawn "cycle-background"; }
        Mod+C { spawn-sh "cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy"; }
        Mod+Alt+L { spawn-sh "pidof hyprlock || hyprlock"; }

        // Audio, Media & Brightness Controls
        XF86AudioRaiseVolume allow-when-locked=true { spawn "volume-osd" "up"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "volume-osd" "down"; }
        XF86AudioMute        allow-when-locked=true { spawn "volume-osd" "mute"; }
        XF86MonBrightnessUp   allow-when-locked=true { spawn "brightness-osd" "up"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightness-osd" "down"; }
        XF86AudioPlay        allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioNext        allow-when-locked=true { spawn "playerctl" "next"; }
        XF86AudioPrev        allow-when-locked=true { spawn "playerctl" "previous"; }

        // Screenshot shortcuts
        Print { spawn "capture-screen" "region"; }
        Shift+Print { spawn "capture-screen" "full"; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }

        // Focus navigation
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up    { focus-window-up; }
        Mod+Down  { focus-window-down; }
        Mod+H     { focus-column-left; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+L     { focus-column-right; }

        // Moving windows & columns
        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+Up    { move-window-up; }
        Mod+Ctrl+Down  { move-window-down; }
        Mod+Ctrl+H     { move-column-left; }
        Mod+Ctrl+J     { move-window-down; }
        Mod+Ctrl+K     { move-window-up; }
        Mod+Ctrl+L     { move-column-right; }

        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Down  { move-window-down; }
        Mod+Shift+H     { move-column-left; }
        Mod+Shift+J     { move-window-down; }
        Mod+Shift+K     { move-window-up; }
        Mod+Shift+L     { move-column-right; }

        // Column layout adjustments
        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }
        Mod+Comma  { consume-window-into-column; }
        Mod+Period { expel-window-from-column; }

        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { switch-preset-column-width-back; }
        Mod+Ctrl+R { reset-window-height; }

        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+V { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }
        Mod+Tab { toggle-column-tabbed-display; }
        Mod+O repeat=false { toggle-overview; }

        // Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        Mod+Ctrl+1 { move-column-to-workspace 1; }
        Mod+Ctrl+2 { move-column-to-workspace 2; }
        Mod+Ctrl+3 { move-column-to-workspace 3; }
        Mod+Ctrl+4 { move-column-to-workspace 4; }
        Mod+Ctrl+5 { move-column-to-workspace 5; }
        Mod+Ctrl+6 { move-column-to-workspace 6; }
        Mod+Ctrl+7 { move-column-to-workspace 7; }
        Mod+Ctrl+8 { move-column-to-workspace 8; }
        Mod+Ctrl+9 { move-column-to-workspace 9; }

        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }

        // Mouse wheel workspace / column scrolling
        Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
        Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
        Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }
        Mod+WheelScrollRight      { focus-column-right; }
        Mod+WheelScrollLeft       { focus-column-left; }
        Mod+Ctrl+WheelScrollRight { move-column-right; }
        Mod+Ctrl+WheelScrollLeft  { move-column-left; }

        // Session control
        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
        Mod+Shift+E { quit; }
        Ctrl+Alt+Delete { quit; }
        Mod+Shift+P { power-off-monitors; }
    }
  '';
}
