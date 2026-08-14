{
  writeShellApplication,
  brightnessctl,
  coreutils,
  hyprland,
  power-profiles-daemon,
  util-linux,
}:

writeShellApplication {
  name = "m3-power-profile";

  runtimeInputs = [
    brightnessctl
    coreutils
    hyprland
    power-profiles-daemon
    util-linux
  ];

  text = ''
    export LC_ALL=C

    if [[ -n "''${XDG_RUNTIME_DIR:-}" ]]; then
      runtime_dir="$XDG_RUNTIME_DIR/m3-shell"
    else
      runtime_dir="/tmp/m3-shell-$UID"
    fi
    brightness_state="$runtime_dir/brightness-before-powersave"
    applied_state="$runtime_dir/applied-power-profile"
    lock_file="$runtime_dir/power-profile.lock"

    install -d -m 0700 "$runtime_dir"
    exec 9>"$lock_file"
    flock 9

    usage() {
      printf 'Usage: m3-power-profile {get|list|set PROFILE|sync}\n' >&2
    }

    normalize_profile() {
      case "$1" in
        performance|perf)
          printf 'performance\n'
          ;;
        balanced|balance)
          printf 'balanced\n'
          ;;
        power-saver|powersave|save|saver)
          printf 'power-saver\n'
          ;;
        *)
          printf 'Unsupported power profile: %s\n' "$1" >&2
          return 2
          ;;
      esac
    }

    current_profile() {
      local active
      active="$(powerprofilesctl get)"
      normalize_profile "$active"
    }

    remember_brightness() {
      local current temporary_state
      [[ -e "$brightness_state" ]] && return 0
      current="$(brightnessctl get 2>/dev/null)" || return 0
      [[ "$current" =~ ^[0-9]+$ ]] || return 0

      temporary_state="$(mktemp "$runtime_dir/brightness.XXXXXX")"
      printf '%s\n' "$current" > "$temporary_state"
      mv -f -- "$temporary_state" "$brightness_state"
    }

    cap_brightness() {
      local current maximum
      current="$(brightnessctl get 2>/dev/null)" || return 0
      maximum="$(brightnessctl max 2>/dev/null)" || return 0
      [[ "$current" =~ ^[0-9]+$ && "$maximum" =~ ^[0-9]+$ ]] || return 0
      (( maximum > 0 )) || return 0

      # Saver is a ceiling, never an instruction to brighten a dim display.
      if (( current * 100 > maximum * 40 )); then
        brightnessctl set 40% >/dev/null
      fi
    }

    restore_brightness() {
      local previous
      [[ -r "$brightness_state" ]] || return 0
      read -r previous < "$brightness_state" || true
      [[ "$previous" =~ ^[0-9]+$ ]] || return 0

      if brightnessctl set "$previous" >/dev/null 2>&1; then
        rm -f -- "$brightness_state"
      fi
    }

    set_refresh_rate() {
      local refresh_rate="$1"

      # A profile can also be changed from a TTY. In that case keep the CPU
      # profile and retry the display policy when the graphical session syncs.
      hyprctl monitors -j >/dev/null 2>&1 || return 1
      hyprctl keyword monitor \
        "eDP-1, 1920x1080@$refresh_rate, 0x0, 1" >/dev/null
    }

    write_applied_profile() {
      local profile="$1" temporary_state
      temporary_state="$(mktemp "$runtime_dir/profile.XXXXXX")"
      printf '%s\n' "$profile" > "$temporary_state"
      mv -f -- "$temporary_state" "$applied_state"
    }

    apply_policy() {
      local profile="$1"
      local force="false"
      local previous=""
      local refresh_rate="144"
      local display_applied="false"

      if (( $# > 1 )); then
        force="$2"
      fi
      if [[ -r "$applied_state" ]]; then
        read -r previous < "$applied_state" || true
      fi
      if [[ "$force" != "true" && "$previous" == "$profile" ]]; then
        return 0
      fi

      if [[ "$profile" == "power-saver" ]]; then
        refresh_rate="60"
        remember_brightness
        cap_brightness
      else
        restore_brightness
      fi

      if set_refresh_rate "$refresh_rate"; then
        display_applied="true"
      else
        printf 'Power profile changed, but display policy will retry in the graphical session.\n' >&2
      fi

      if [[ "$display_applied" == "true" ]]; then
        write_applied_profile "$profile"
      fi
    }

    command="''${1:-}"
    case "$command" in
      get)
        (( $# == 1 )) || { usage; exit 2; }
        current_profile
        ;;
      list)
        (( $# == 1 )) || { usage; exit 2; }
        powerprofilesctl list
        ;;
      set)
        (( $# == 2 )) || { usage; exit 2; }
        profile="$(normalize_profile "$2")"
        powerprofilesctl set "$profile"
        apply_policy "$profile" true
        printf '%s\n' "$profile"
        ;;
      sync)
        (( $# == 1 )) || { usage; exit 2; }
        profile="$(current_profile)"
        apply_policy "$profile" false
        printf '%s\n' "$profile"
        ;;
      *)
        usage
        exit 2
        ;;
    esac
  '';
}
