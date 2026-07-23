{ pkgs, ... }:
let
  walkerMenu = pkgs.writeShellApplication {
    name = "walker-menu";
    runtimeInputs = with pkgs; [
      walker
      hyprlock
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

      system_menu() {
        local selection
        selection="$(menu "System" \
          "Lock\nSuspend\nRestart\nShut down\nSign out" \
          "$system_theme")" || return 0

        case "$selection" in
          "Lock") hyprlock ;;
          "Suspend") systemctl suspend ;;
          "Restart") systemctl reboot ;;
          "Shut down") systemctl poweroff ;;
          "Sign out") hyprctl dispatch exit ;;
          "") return 0 ;;
        esac
      }

      set_refresh_rate() {
        local refresh_rate="$1"
        hyprctl keyword monitor \
          "eDP-1, 1920x1080@''${refresh_rate}, 1920x0, 1" >/dev/null
      }

      restore_brightness() {
        local previous_brightness
        [[ -r "$brightness_state" ]] || return 0
        read -r previous_brightness < "$brightness_state" || true
        if [[ "$previous_brightness" =~ ^[0-9]+$ ]]; then
          brightnessctl set "$previous_brightness" >/dev/null
        fi
        rm -f -- "$brightness_state"
      }

      remember_brightness() {
        local temporary_state
        [[ -e "$brightness_state" ]] && return 0
        temporary_state="$(mktemp "$runtime_dir/brightness.XXXXXX")"
        brightnessctl get > "$temporary_state"
        mv -f -- "$temporary_state" "$brightness_state"
      }

      set_profile() {
        local profile="$1"
        local refresh_rate="$2"
        local label="$3"
        local description="$4"

        if ! powerprofilesctl set "$profile"; then
          notify-send -a "System controls" -u critical -t 2400 \
            -i "dialog-error-symbolic" "Power mode" \
            "Could not apply $label" || true
          return 1
        fi

        set_refresh_rate "$refresh_rate"
        if [[ "$profile" == "power-saver" ]]; then
          remember_brightness
          brightnessctl set 40% >/dev/null
        else
          restore_brightness
        fi
        notify_system "battery-good-symbolic" "$label" "$description"
      }

      profile_menu() {
        local selection
        selection="$(menu "Power mode" \
          "Performance\nBalanced\nPower saver" "$system_theme")" \
          || return 0

        case "$selection" in
          "Performance")
            set_profile "performance" 144 "Performance" \
              "144 Hz · Full brightness control"
            ;;
          "Balanced")
            set_profile "balanced" 144 "Balanced" \
              "144 Hz · Balanced power use"
            ;;
          "Power saver")
            set_profile "power-saver" 60 "Power saver" \
              "60 Hz · Brightness limited to 40%"
            ;;
          "") return 0 ;;
        esac
      }

      wallpaper_menu() {
        local wallpaper_dir="$HOME/Pictures/wallpapers"
        local selection
        if [[ ! -d "$wallpaper_dir" ]]; then
          notify-send -a "Wallpaper" -u normal \
            -i "preferences-desktop-wallpaper-symbolic" \
            "Wallpaper" \
            "Create ~/Pictures/wallpapers and add an image first" || true
          return 1
        fi

        selection="$(find "$wallpaper_dir" -type f \( \
          -iname "*.jpg" -o -iname "*.jpeg" -o \
          -iname "*.png" -o -iname "*.webp" -o \
          -iname "*.mp4" -o -iname "*.mkv" -o \
          -iname "*.webm" -o -iname "*.avi" -o \
          -iname "*.mov" \) -printf '%P\n' \
          | sort | walker --dmenu --theme "$app_theme" \
            -p "Choose wallpaper…")" || return 0

        if [[ -n "$selection" ]]; then
          set-background "$selection"
        fi
      }

      launcher_menu() {
        local selection
        selection="$(menu "Launcher" "Applications\nWallpapers" \
          "$system_theme")" || return 0
        case "$selection" in
          "Applications") walker --theme "$app_theme" ;;
          "Wallpapers") wallpaper_menu ;;
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
