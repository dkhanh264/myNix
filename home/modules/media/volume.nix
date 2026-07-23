{ pkgs, ... }:
let
  volumeOsd = pkgs.writeShellApplication {
    name = "volume-osd";
    runtimeInputs = with pkgs; [ wireplumber libnotify gawk ];
    text = ''
      case "''${1:-}" in
        up) wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ ;;
        down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
        mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        *)
          printf 'Usage: volume-osd {up|down|mute}\n' >&2
          exit 2
          ;;
      esac

      state="$(LC_ALL=C wpctl get-volume @DEFAULT_AUDIO_SINK@)"
      volume_percent="$(awk '{
        value = int($2 * 100 + 0.5)
        if (value < 0) value = 0
        if (value > 100) value = 100
        print value
      }' <<< "$state")"

      if [[ "$state" == *"[MUTED]"* ]]; then
        icon="audio-volume-muted-symbolic"
        title="Đã tắt tiếng"
      elif (( volume_percent < 34 )); then
        icon="audio-volume-low-symbolic"
        title="Âm lượng · ''${volume_percent}%"
      elif (( volume_percent < 67 )); then
        icon="audio-volume-medium-symbolic"
        title="Âm lượng · ''${volume_percent}%"
      else
        icon="audio-volume-high-symbolic"
        title="Âm lượng · ''${volume_percent}%"
      fi

      notify-send -a "System controls" -u low -t 1600 -i "$icon" \
        -h string:x-canonical-private-synchronous:volume \
        -h int:value:"$volume_percent" "$title" || true
    '';
  };

  brightnessOsd = pkgs.writeShellApplication {
    name = "brightness-osd";
    runtimeInputs = with pkgs; [ brightnessctl libnotify ];
    text = ''
      case "''${1:-}" in
        up) brightnessctl set 10%+ >/dev/null ;;
        down) brightnessctl set 10%- >/dev/null ;;
        *)
          printf 'Usage: brightness-osd {up|down}\n' >&2
          exit 2
          ;;
      esac

      IFS=, read -r _device _class _current percentage _maximum \
        <<< "$(brightnessctl -m info)"
      percentage="''${percentage%%%}"
      [[ "$percentage" =~ ^[0-9]+$ ]] || percentage=0

      notify-send -a "System controls" -u low -t 1600 \
        -i "display-brightness-symbolic" \
        -h string:x-canonical-private-synchronous:brightness \
        -h int:value:"$percentage" \
        "Độ sáng · ''${percentage}%" || true
    '';
  };

in
{
  home.packages = [ volumeOsd brightnessOsd ];
}
