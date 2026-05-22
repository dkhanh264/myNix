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
        "mako"        # Khởi động trình thông báo
        "hypridle"
        "nm-applet --indicator"
        "blueman-applet"
        "wl-paste --type text --watch cliphist store"
        "fcitx5 -d"

        "quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml"
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
        # Cú pháp: opacity <độ_đục_khi_đang_dùng> <độ_đục_khi_không_dùng>, class:^(tên_app)$
      ];

      "$mainMod" = "SUPER";

      bind = [
        # Khởi chạy ứng dụng cơ bản (Kitty đổi sang phím Mod + Enter tránh xung đột phím Q)
        "$mainMod, RETURN, exec, kitty"
        "$mainMod, F,      exec, firefox"
        "$mainMod, E,      exec, nautilus"
        
        # Quản lý cửa sổ mặc định của bạn
        "ALT, F4,         killactive"
        "$mainMod, V,         togglefloating"
        "$mainMod, F,         fullscreen, 0"
        
        # Điều hướng focus chuột (giữ nguyên của bạn)
        "$mainMod, left,      movefocus, l"
        "$mainMod, right,     movefocus, r"
        "$mainMod, up,        movefocus, u"
        "$mainMod, down,      movefocus, d"
        "$mainMod SHIFT, left,  movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up,    movewindow, u"
        "$mainMod SHIFT, down,  movewindow, d"

        # ── ĐIỀU KHIỂN HỆ THỐNG QUICKSHELL & ROFI (Thay thế hoàn toàn Walker) ──
        # Bật Menu ứng dụng và menu hệ thống thông qua Rofi/Quickshell
        "$mainMod, space,  exec, ~/.config/hypr/scripts/qs_manager.sh toggle applauncher"
        "$mainMod, escape, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle guide"
        
        # Gọi Clipboard quản lý qua Quickshell thay vì walker --dmenu
        "$mainMod, C,      exec, ~/.config/hypr/scripts/qs_manager.sh toggle clipboard"
        
        # Các Widget tiện ích nhanh từ Quickshell
        "$mainMod, M,      exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle monitors"
        "$mainMod, R,      exec, bash ~/.config/hypr/scripts/reload.sh"
        "$mainMod, Q,      exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle music"
        "$mainMod, B,      exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle battery"
        "$mainMod, W,      exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper"
        "$mainMod, S,      exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle calendar"
        "$mainMod, N,      exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle network"
        "$mainMod, V,      exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle volume"
        "$mainMod SHIFT, S, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle settings"
        "$mainMod SHIFT, T, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle focustime"

        # ── ĐỊNH TUYẾN WORKSPACE DỰA TRÊN IPC (Chuyển nhanh & tự đóng widget) ──
        "$mainMod, 1, exec, ~/.config/hypr/scripts/qs_manager.sh 1"
        "$mainMod, 2, exec, ~/.config/hypr/scripts/qs_manager.sh 2"
        "$mainMod, 3, exec, ~/.config/hypr/scripts/qs_manager.sh 3"
        "$mainMod, 4, exec, ~/.config/hypr/scripts/qs_manager.sh 4"
        "$mainMod, 5, exec, ~/.config/hypr/scripts/qs_manager.sh 5"

        "$mainMod SHIFT, 1, exec, ~/.config/hypr/scripts/qs_manager.sh 1 move"
        "$mainMod SHIFT, 2, exec, ~/.config/hypr/scripts/qs_manager.sh 2 move"
        "$mainMod SHIFT, 3, exec, ~/.config/hypr/scripts/qs_manager.sh 3 move"
        "$mainMod SHIFT, 4, exec, ~/.config/hypr/scripts/qs_manager.sh 4 move"
        "$mainMod SHIFT, 5, exec, ~/.config/hypr/scripts/qs_manager.sh 5 move"
        
        # Special workspace mặc định của bạn
        "$mainMod, S,       togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
      ];      
      
      bindl = [
        # Khóa màn hình qua script động Lock Screen mới
        "$mainMod, L, exec, bash ~/.config/hypr/scripts/lock.sh"
        ", XF86PowerOff, exec, bash ~/.config/hypr/scripts/lock.sh"
        
        # Chụp ảnh màn hình nâng cao giao tiếp trực tiếp với Quickshell UI
        ", Print,       exec, ~/.config/hypr/scripts/screenshot.sh"
        "SHIFT_L, Print, exec, ~/.config/hypr/scripts/screenshot.sh --edit"
        "SUPER, Print,   exec, ~/.config/hypr/scripts/screenshot.sh --full"
        
        # Đồng bộ hóa SwayOSD cho cụm phím đa phương tiện & CapsLock
        ", XF86AudioMute,        exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute,     exec, swayosd-client --input-volume mute-toggle"
        ", Caps_Lock,            exec, sleep 0.1 && swayosd-client --caps-lock"
      ];

      bindel = [
        # Tăng giảm âm lượng độ sáng phản hồi hoạt họa qua SwayOSD
        ", XF86AudioRaiseVolume,  exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume,  exec, swayosd-client --output-volume lower"
        ", XF86MonBrightnessUp,   exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      # ── Blur cho các giao diện nổi ───────────────────────────────────
      layerrule = [
        "blur, notifications"
        "ignorezero, notifications"
      ];
    };
  };
}
