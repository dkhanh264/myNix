{ lib, pkgs, ... }:
let
  m3PowerProfile = pkgs.callPackage ../m3-power-profile { };

  walkerMenu = pkgs.writeShellApplication {
    name = "walker-menu";
    runtimeInputs = with pkgs; [
      walker
      hyprland
      systemd
      m3PowerProfile
      findutils
      coreutils
      libnotify
    ];
    text = ''
      app_theme="transparent-apps"
      system_theme="transparent-system"

      menu() {
        local prompt="$1"
        local choices="$2"
        local theme="$3"
        printf '%b\n' "$choices" \
          | walker --dmenu --theme "$theme" -p "$prompt…"
      }

      notify_system() {
        local icon="$1"
        local title="$2"
        local body="$3"
        notify-send -a "System controls" -u low -t 1800 \
          -i "$icon" "$title" "$body" || true
      }

      lang_file="$HOME/.config/m3-shell-language"
      current_lang="vi"
      if [[ -r "$lang_file" ]]; then
        read -r current_lang < "$lang_file" || current_lang="vi"
      fi

      system_menu() {
        local selection prompt choices
        if [[ "$current_lang" == "en" ]]; then
          prompt="Power Options"
          choices="Lock screen\nSuspend\nRestart\nShut down\nSign out"
        else
          prompt="Tùy chọn Nguồn"
          choices="Khóa màn hình (Lock)\nTạm dừng (Suspend)\nKhởi động lại (Restart)\nTắt máy (Shut down)\nĐăng xuất (Sign out)"
        fi
        selection="$(menu "$prompt" "$choices" "$system_theme")" || return 0

        case "$selection" in
          *"Lock"*|*"Khóa"*) qs ipc call lockscreen lock ;;
          *"Suspend"*|*"Tạm dừng"*) systemctl suspend ;;
          *"Restart"*|*"Khởi động"*) systemctl reboot ;;
          *"Shut down"*|*"Tắt máy"*) systemctl poweroff ;;
          *"Sign out"*|*"Đăng xuất"*) hyprctl dispatch exit ;;
          "") return 0 ;;
        esac
      }

      set_profile() {
        local profile="$1"
        local label description error_title error_body

        if [[ "$current_lang" == "en" ]]; then
          error_title="Power mode"
          case "$profile" in
            performance)
              label="Performance"
              description="144 Hz · Maximum speed"
              ;;
            balanced)
              label="Balanced"
              description="144 Hz · Balanced performance and battery"
              ;;
            power-saver)
              label="Power Saver"
              description="60 Hz · Brightness capped at 40%"
              ;;
          esac
          error_body="Could not apply $label"
        else
          error_title="Chế độ nguồn"
          case "$profile" in
            performance)
              label="Hiệu năng"
              description="144 Hz · Ưu tiên tốc độ tối đa"
              ;;
            balanced)
              label="Cân bằng"
              description="144 Hz · Cân bằng hiệu năng và pin"
              ;;
            power-saver)
              label="Tiết kiệm pin"
              description="60 Hz · Giới hạn độ sáng tối đa 40%"
              ;;
          esac
          error_body="Không thể áp dụng chế độ $label"
        fi

        if ! m3-power-profile set "$profile" >/dev/null 2>&1; then
          notify-send -a "System controls" -u critical -t 2400 \
            -i "dialog-error-symbolic" "$error_title" \
            "$error_body" || true
          return 1
        fi

        notify_system "battery-good-symbolic" "$label" "$description"
      }

      profile_menu() {
        local selection prompt choices
        if [[ "$current_lang" == "en" ]]; then
          prompt="Power Mode"
          choices="Performance\nBalanced\nPower Saver"
        else
          prompt="Chế độ Nguồn"
          choices="Hiệu năng cao (Performance)\nCân bằng (Balanced)\nTiết kiệm pin (Power Saver)"
        fi
        selection="$(menu "$prompt" "$choices" "$system_theme")" || return 0

        case "$selection" in
          *"Performance"*|*"Hiệu năng"*)
            set_profile "performance"
            ;;
          *"Balanced"*|*"Cân bằng"*)
            set_profile "balanced"
            ;;
          *"Power Saver"*|*"Tiết kiệm"*|*"saver"*)
            set_profile "power-saver"
            ;;
          "") return 0 ;;
        esac
      }

      wallpaper_menu() {
        local wallpaper_dir="$HOME/Pictures/wallpapers"
        local selection prompt
        prompt="Choose wallpaper…"
        [[ "$current_lang" == "vi" ]] && prompt="Chọn hình nền…"

        if [[ ! -d "$wallpaper_dir" ]]; then
          notify-send -a "Wallpaper" -u normal \
            -i "preferences-desktop-wallpaper-symbolic" \
            "Wallpaper" \
            "Create ~/Pictures/wallpapers and add images" || true
          return 1
        fi

        selection="$(find "$wallpaper_dir" -type f \( \
          -iname "*.jpg" -o -iname "*.jpeg" -o \
          -iname "*.png" -o -iname "*.webp" -o \
          -iname "*.mp4" -o -iname "*.mkv" -o \
          -iname "*.webm" -o -iname "*.avi" -o \
          -iname "*.mov" \) -printf '%P\n' \
          | sort | walker --dmenu --theme "$app_theme" \
            -p "$prompt")" || return 0

        if [[ -n "$selection" ]]; then
          set-background "$selection"
        fi
      }

      launcher_menu() {
        local selection prompt choices
        if [[ "$current_lang" == "en" ]]; then
          prompt="Launcher"
          choices="Applications\nWallpapers\nSystem Controls"
        else
          prompt="Trình khởi chạy"
          choices="Ứng dụng (Applications)\nHình nền (Wallpapers)\nTùy chọn nguồn (System Controls)"
        fi
        selection="$(menu "$prompt" "$choices" "$system_theme")" || return 0
        case "$selection" in
          *"Applications"*|*"Ứng dụng"*) walker --theme "$app_theme" ;;
          *"Wallpapers"*|*"Hình nền"*) wallpaper_menu ;;
          *"System Controls"*|*"Tùy chọn"*) system_menu ;;
          "") return 0 ;;
        esac
      }

      case "''${1:-apps}" in
        system) system_menu ;;
        profile) profile_menu ;;
        wallpapers) wallpaper_menu ;;
        launcher) launcher_menu ;;
        apps) walker --theme "$app_theme" ;;
        *)
          printf 'Usage: walker-menu {apps|launcher|system|profile|wallpapers}\n' >&2
          exit 2
          ;;
      esac
    '';
  };

in
{
  home.packages = [ walkerMenu ];

  # Pin the power-profile shortcut to this generation so it never falls back
  # to an older walker-menu from the system profile during a Home Manager-only
  # activation.
  wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
    "$mainMod, P, exec, ${walkerMenu}/bin/walker-menu profile"
  ];

  xdg.configFile."walker" = {
    source = ./walker;
    recursive = true;
    force = true;
  };
}
