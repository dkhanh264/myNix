{ pkgs, ... }:
let
  walkerMenu = pkgs.writeShellApplication {
    name = "walker-menu";
    runtimeInputs = with pkgs; [
      walker
      hyprland
      systemd
      power-profiles-daemon
      brightnessctl
      findutils
      coreutils
      libnotify
    ];
    text = ''
      app_theme="transparent-apps"
      system_theme="transparent-system"
      if [[ -n "''${XDG_RUNTIME_DIR:-}" ]]; then
        runtime_dir="$XDG_RUNTIME_DIR/m3-shell"
      else
        runtime_dir="/tmp/m3-shell-$UID"
      fi
      brightness_state="$runtime_dir/brightness-before-powersave"
      mkdir -p -- "$runtime_dir"

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

      set_refresh_rate() {
        local refresh_rate="$1"
        hyprctl keyword monitor \
          "eDP-1, 1920x1080@''${refresh_rate}, auto, 1" >/dev/null 2>&1 || true
      }

      restore_brightness() {
        local previous_brightness
        [[ -r "$brightness_state" ]] || return 0
        read -r previous_brightness < "$brightness_state" || true
        if [[ "$previous_brightness" =~ ^[0-9]+$ ]]; then
          brightnessctl set "$previous_brightness" >/dev/null 2>&1 || true
        fi
        rm -f -- "$brightness_state"
      }

      remember_brightness() {
        local temporary_state
        [[ -e "$brightness_state" ]] && return 0
        temporary_state="$(mktemp "$runtime_dir/brightness.XXXXXX")"
        brightnessctl get > "$temporary_state" 2>/dev/null || true
        mv -f -- "$temporary_state" "$brightness_state"
      }

      set_profile() {
        local profile="$1"
        local refresh_rate="$2"
        local label="$3"
        local description="$4"

        if ! powerprofilesctl set "$profile" 2>/dev/null; then
          notify-send -a "System controls" -u critical -t 2400 \
            -i "dialog-error-symbolic" "Power mode" \
            "Could not apply $label" || true
          return 1
        fi

        set_refresh_rate "$refresh_rate"
        if [[ "$profile" == "power-saver" || "$profile" == "powersave" ]]; then
          remember_brightness
          brightnessctl set 40% >/dev/null 2>&1 || true
        else
          restore_brightness
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
            set_profile "performance" 144 "Performance" \
              "144 Hz · Maximum speed"
            ;;
          *"Balanced"*|*"Cân bằng"*)
            set_profile "balanced" 144 "Balanced" \
              "144 Hz · Balanced performance and battery"
            ;;
          *"Power Saver"*|*"Tiết kiệm"*|*"saver"*)
            set_profile "power-saver" 60 "Power Saver" \
              "60 Hz · Brightness limited to 40%"
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
  xdg.configFile."walker" = {
    source = ./walker;
    recursive = true;
    force = true;
  };
}
