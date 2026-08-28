{ pkgs, ... }:
let
  volumeOsd = pkgs.writeShellApplication {
    name = "volume-osd";
    runtimeInputs = with pkgs; [
      wireplumber
      libnotify
      gawk
    ];
    text = ''
      app_title="Điều khiển hệ thống"

      case "''${1:-}" in
        up)
          wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
          wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
          ;;
        down)
          wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
          wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
          ;;
        mute)
          wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
          ;;
        mute-mic|mic-mute)
          wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
          source_output="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true)"
          if [[ "$source_output" == *"[MUTED]"* ]]; then
            icon="microphone-disabled-symbolic"
            label="Microphone · Tắt tiếng"
            val=0
          else
            icon="microphone-sensitivity-high-symbolic"
            label="Microphone · Bật"
            val=100
          fi
          notify-send -a "$app_title" -u low -t 1600 \
            -i "$icon" \
            -h string:x-canonical-private-synchronous:mic \
            -h int:value:"$val" \
            "$label" || true
          exit 0
          ;;
        *)
          printf 'Usage: volume-osd {up|down|mute|mute-mic}\n' >&2
          exit 2
          ;;
      esac

      vol_output="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
      is_muted=0
      if [[ "$vol_output" == *"[MUTED]"* ]]; then
        is_muted=1
      fi

      raw_vol="$(awk '{print $2}' <<< "$vol_output")"
      percentage="$(awk -v v="$raw_vol" 'BEGIN { printf "%.0f", v * 100 }')"
      [[ "$percentage" =~ ^[0-9]+$ ]] || percentage=0

      if (( is_muted )) || (( percentage == 0 )); then
        icon="audio-volume-muted-symbolic"
        label="Âm lượng · Tắt tiếng"
        progress_val=0
      elif (( percentage <= 30 )); then
        icon="audio-volume-low-symbolic"
        label="Âm lượng · ''${percentage}%"
        progress_val="$percentage"
      elif (( percentage <= 70 )); then
        icon="audio-volume-medium-symbolic"
        label="Âm lượng · ''${percentage}%"
        progress_val="$percentage"
      else
        icon="audio-volume-high-symbolic"
        label="Âm lượng · ''${percentage}%"
        progress_val="$percentage"
      fi

      notify-send -a "$app_title" -u low -t 1600 \
        -i "$icon" \
        -h string:x-canonical-private-synchronous:volume \
        -h int:value:"$progress_val" \
        "$label" || true
    '';
  };

  brightnessOsd = pkgs.writeShellApplication {
    name = "brightness-osd";
    runtimeInputs = with pkgs; [ brightnessctl libnotify ];
    text = ''

      case "''${1:-}" in
        up) brightness_output="$(brightnessctl -m set 10%+)" ;;
        down) brightness_output="$(brightnessctl -m set 10%-)" ;;
        *)
          printf 'Usage: brightness-osd {up|down}\n' >&2
          exit 2
          ;;
      esac

      IFS=, read -r _device _class _current percentage _maximum \
        <<< "$brightness_output"
      percentage="''${percentage%%%}"
      [[ "$percentage" =~ ^[0-9]+$ ]] || percentage=0

      app_title="Điều khiển hệ thống"
      label="Độ sáng · ''${percentage}%"

      notify-send -a "$app_title" -u low -t 1600 \
        -i "display-brightness-symbolic" \
        -h string:x-canonical-private-synchronous:brightness \
        -h int:value:"$percentage" \
        "$label" || true
    '';
  };

in
{
  home.packages = [ volumeOsd brightnessOsd ];
}
