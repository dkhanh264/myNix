{
  pkgs,
  lib,
  config,
  ...
}:

{
  xdg.configFile."niri/config.kdl".text = ''
    // Input device configuration
    hotkey-overlay {
        skip-at-startup
    }

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
            // natural-scroll
        }

        warp-mouse-to-focus
        focus-follows-mouse
    }

    // Output configuration
    // Laptop display (eDP-1)
    output "eDP-1" {
        mode "1920x1080@144.003"
        scale 1.0
        variable-refresh-rate
    }

    // External display (HDMI-A-1)
    output "HDMI-A-1" {
        mode "1920x1080@179.961"
        scale 1.0
    }

    // Disable Client-Side Decorations globally
    prefer-no-csd

    // Environment variables
    environment {
        NIXOS_OZONE_WL "1"
        XDG_CURRENT_DESKTOP "Niri"
        XDG_SESSION_TYPE "wayland"
        XDG_SESSION_DESKTOP "Niri"
        XCURSOR_SIZE "24"
        XCURSOR_THEME "aosp-cursors"
        QT_WAYLAND_DISABLE_WINDOWDECORATION "1"
    }

    // Autostart services
    spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP=niri"
    spawn-at-startup "rfkill" "unblock" "bluetooth"
    spawn-sh-at-startup "wl-paste --type text --watch cliphist store"
    spawn-sh-at-startup "wl-paste --type image --watch cliphist store"
    spawn-at-startup "fcitx5" "-d"

    // Layout configuration
    layout {
        gaps 6
        center-focused-column "never"
        background-color "transparent"

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        preset-window-heights {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }

        focus-ring {
            width 2
            active-color "#bec2ff"
            inactive-color "#8e9099"
        }

        border {
            off
            width 1
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
            off
            softness 20
            spread 2
            offset x=0 y=4
            color "#00000080"
        }
    }

    // Overview backdrop configuration (Super+O / Super+Backspace)
    overview {
        backdrop-color "#00000040"
    }

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    animations {
        slowdown 1.0
    }

    // Compositor background blur settings (frosted glass)
    blur {
        passes 3
        offset 2.2
        noise 0.015
        saturation 1.05
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
        geometry-corner-radius 8
        clip-to-geometry true
        draw-border-with-background false
    }

    // Keybindings (Serpantinum prioritized)
    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        // Applications & Core Actions
        Mod+Return { spawn "kitty"; }
        Mod+Q { spawn "kitty"; }
        Mod+W { spawn "brave"; }
        Mod+E { spawn "nautilus"; }
        Alt+F4 { close-window; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+V { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }
        Mod+Tab { toggle-column-tabbed-display; }

        // Overview
        Mod+Backspace { toggle-overview; }
        Mod+O repeat=false { toggle-overview; }

        // Serpantinum Toggles & Controls
        Mod+Space { spawn "serpantinum" "msg" "toggle" "launcher"; }
        Mod+D { spawn "serpantinum" "msg" "toggle" "launcher"; }
        Mod+C { spawn "serpantinum" "msg" "toggle" "clipboard"; }
        Mod+B { spawn "serpantinum" "msg" "toggle" "system"; }
        Ctrl+Mod+Space { spawn "serpantinum" "msg" "toggle" "wallpaper"; }
        Mod+S { spawn "serpantinum" "msg" "toggle" "calendar"; }
        Mod+N { spawn "serpantinum" "msg" "toggle" "network"; }
        Mod+G { spawn "serpantinum" "msg" "toggle" "guide"; }
        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { spawn "serpantinum" "reload"; }

        // Lock screen
        Mod+Alt+L { spawn "serpantinum" "lock"; }
        Ctrl+Alt+L { spawn "serpantinum" "lock"; }
        XF86PowerOff { spawn "serpantinum" "lock"; }

        // Brightness controls
        XF86MonBrightnessDown { spawn "serpantinum" "brightness" "lower"; }
        XF86MonBrightnessUp   { spawn "serpantinum" "brightness" "raise"; }

        // Media & Volume controls
        XF86AudioPlay { spawn "playerctl" "play-pause"; }
        XF86AudioPause { spawn "playerctl" "play-pause"; }
        XF86AudioNext { spawn "playerctl" "next"; }
        XF86AudioPrev { spawn "playerctl" "previous"; }
        XF86AudioRaiseVolume allow-when-locked=true { spawn "serpantinum" "volume" "raise"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "serpantinum" "volume" "lower"; }
        XF86AudioMute        allow-when-locked=true { spawn "serpantinum" "volume" "mute-toggle"; }
        XF86AudioMicMute     allow-when-locked=true { spawn "serpantinum" "volume" "mic-toggle"; }

        // Screenshot & Recording shortcuts
        Print { spawn "serpantinum" "screenshot"; }
        Shift+Print { spawn "serpantinum" "screenshot" "--edit"; }
        Super+Print { spawn "serpantinum" "screenshot" "--full"; }
        Super+Shift+Print { spawn "serpantinum" "screenshot" "--full" "--edit"; }
        Ctrl+Print { spawn "serpantinum" "screenshot" "--full" "--record"; }

        // Focus Navigation
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up    { focus-window-or-workspace-up; }
        Mod+Down  { focus-window-or-workspace-down; }
        Mod+H     { focus-column-left; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+L     { focus-column-right; }

        // Moving Windows & Columns
        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+Up    { move-column-to-workspace-up; }
        Mod+Ctrl+Down  { move-column-to-workspace-down; }
        Mod+Ctrl+H     { move-column-left; }
        Mod+Ctrl+J     { move-window-down; }
        Mod+Ctrl+K     { move-window-up; }
        Mod+Ctrl+L     { move-column-right; }

        // Focus Monitor Navigation
        Mod+Shift+Left  { focus-monitor-left; }
        Mod+Shift+Right { focus-monitor-right; }
        Mod+Shift+Up    { focus-monitor-up; }
        Mod+Shift+Down  { focus-monitor-down; }
        Mod+Shift+H     { focus-monitor-left; }
        Mod+Shift+J     { focus-monitor-down; }
        Mod+Shift+K     { focus-monitor-up; }
        Mod+Shift+L     { focus-monitor-right; }

        // Moving Columns across Monitors
        Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
        Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

        // Column Layout Adjustments
        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }
        Mod+Comma  { consume-window-into-column; }
        Mod+Period { expel-window-from-column; }

        // Resizing
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }
        Mod+Ctrl+R { reset-window-height; }

        // Workspaces (Native Niri actions)
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

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
