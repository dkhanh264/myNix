{ pkgs, config, ... }:

{
  # Các package chuyên biệt cho Hyprland
  home.packages = with pkgs; [
    hyprlock 
    hypridle
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
        "waybar"
        "mako"        # Khởi động trình thông báo
        "hypridle"
        "nm-applet --indicator"
        "blueman-applet"
        "wl-paste --type text --watch cliphist store"
        "fcitx5 -d"
        "swww-daemon"  # Daemon cho hình nền có hiệu ứng chuyển cảnh
      ];

      # ── General ───────────────────────────────────────────────────────
      general = {
        gaps_in               = 5;
        gaps_out              = 10;
        border_size           = 2;
        "col.active_border"   = "rgba(eeaecaff) rgba(94bbe9ff) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout                = "dwindle";
        resize_on_border      = true;
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled           = true;
          size              = 8;
          passes            = 3;
          new_optimizations = true;
          ignore_opacity = true;
        };
      };

      animations = {
        enabled = true;
        bezier   = [ "myBezier, 0.05, 0.9, 0.1, 1.05" ];
        animation = [
          "windows,    1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "fade,       1, 7, default"
          "workspaces, 1, 6, default"
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
        "$mainMod, W,         exec, firefox"
        "$mainMod, E,         exec, nautilus"
        
        # ── Walker & Hình nền ──────────────────────────────────────────
        "$mainMod, space,     exec, walker-menu apps"
        "$mainMod, escape,    exec, walker-menu system"
        "$mainMod CTRL, space, exec, cycle-background"
        "$mainMod, P, exec, walker-menu profile"
        
        "ALT, F4,         killactive"
        "$mainMod, V,         togglefloating"
        "$mainMod, F,         fullscreen, 0"
        "$mainMod, L,         exec, hyprlock"
        
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
        
        ", Print,      exec, grim -g \"$(slurp)\" - | wl-copy"
        "SHIFT, Print, exec, grim - | wl-copy"
        
        # ── OSD Âm lượng & Truyền thông ────────────────────────────────
        ", XF86AudioRaiseVolume, exec, volume-osd up"
        ", XF86AudioLowerVolume, exec, volume-osd down"
        ", XF86AudioMute,        exec, volume-osd mute"
        ", XF86AudioPlay,        exec, playerctl play-pause"
        ", XF86AudioNext,        exec, playerctl next"
        ", XF86AudioPrev,        exec, playerctl previous"
        
        ", XF86MonBrightnessUp,   exec, brightnessctl set 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      # ── Blur cho các giao diện nổi ───────────────────────────────────
      layerrule = [
        "blur, walker"
        "ignorezero, walker"
        "blur, waybar"
        "ignorezero, waybar"
        "blur, notifications"
        "ignorezero, notifications"
      ];
    };
  };
}
