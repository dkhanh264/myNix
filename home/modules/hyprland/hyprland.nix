{ pkgs, config, ... }:
let
  wallpaperDir = "${config.home.homeDirectory}/Pictures/wallpapers";
  wallpaperPath = "${wallpaperDir}/wallpaper.jpg";
  wallpaperPicker = pkgs.writeShellScriptBin "wallpaper-picker" ''
    set -euo pipefail

    wallpaper_dir="${wallpaperDir}"
    wallpaper_path="${wallpaperPath}"
    supported_extensions=(jpg jpeg png webp gif)

    if [ ! -d "$wallpaper_dir" ]; then
      echo "wallpaper-picker: missing directory $wallpaper_dir" >&2
      exit 1
    fi

    find_args=()
    for ext in "''${supported_extensions[@]}"; do
      find_args+=( -iname "*.''${ext}" -o )
    done
    unset "find_args[''${#find_args[@]}-1]"

    selection="$(
      find "$wallpaper_dir" -maxdepth 1 -type f \
        \( "''${find_args[@]}" \) \
        | sort \
        | rofi -dmenu -i -p "Wallpaper"
    )"

    [ -z "$selection" ] && exit 0

    if [ "$selection" != "$wallpaper_path" ]; then
      ln -sfn "$selection" "$wallpaper_path"
    fi

    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl hyprpaper unload all
      hyprctl hyprpaper preload "$wallpaper_path"
      hyprctl hyprpaper wallpaper ",$wallpaper_path"
    fi

    if ! systemctl_output=$(systemctl --user start pywal-theme.service 2>&1); then
      echo "wallpaper-picker: wallpaper applied, but failed to start pywal-theme.service: $systemctl_output (check: systemctl --user status pywal-theme.service)" >&2
    fi
  '';
in
{
  home.packages = with pkgs; [
    waybar rofi dunst
    hyprpaper hyprlock hypridle
    wallpaperPicker
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # ── Monitors ──────────────────────────────────────────────────────
      # Chạy `hyprctl monitors` trong Hyprland để xem tên thực tế.
      # eDP-1 là màn hình laptop, HDMI-A-1 là màn hình ngoài.
      # Màn hình ngoài được đặt sang phải (offset 1920x0).
      monitor = [
        "eDP-1, 1920x1080@144, 0x0, 1"
        "HDMI-A-1, 1920x1080@179, 1920x0, 1"
      ];

      # ── NVIDIA + Wayland env vars ──────────────────────────────────────
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "WLR_NO_HARDWARE_CURSORS,1"
        "XCURSOR_SIZE,24"
        "MOZ_ENABLE_WAYLAND,1"
        "QT_QPA_PLATFORM,wayland"
        "GDK_BACKEND,wayland,x11"
      ];

      # ── Autostart ─────────────────────────────────────────────────────
      exec-once = [
        "waybar"
        "dunst"
        "hyprpaper"
        "hypridle"
        "nm-applet --indicator"
        "blueman-applet"
        "wl-paste --type text --watch cliphist store"
        "fcitx5 -d"
      ];

      # ── General ───────────────────────────────────────────────────────
      general = {
        gaps_in               = 5;
        gaps_out              = 10;
        border_size           = 2;
        "col.active_border"   = "rgba(33ccffee) rgba(00ff99ee) 45deg";
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
        };
        # drop_shadow = true;
        # shadow_range = 10;
        # shadow_render_power = 3;
        # col.shadow = "rgba(1a1a1aee)";
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
      ];

      "$mainMod" = "SUPER";

      bind = [
        "$mainMod, Return,    exec, kitty"
        "$mainMod, W,         exec, google-chrome"
        "$mainMod, E,         exec, nautilus"
        "$mainMod, R,         exec, rofi -show drun -show-icons"
        "$mainMod, P,         exec, wallpaper-picker"
        "$mainMod, Q,         killactive"
        "$mainMod, V,         togglefloating"
        "$mainMod, F,         fullscreen, 0"
        "$mainMod, L,         exec, hyprlock"
        "$mainMod, C,         exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
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
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod, S,       togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        ", Print,      exec, grim -g \"$(slurp)\" - | wl-copy"
        "SHIFT, Print, exec, grim - | wl-copy"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86MonBrightnessUp,   exec, brightnessctl set 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
