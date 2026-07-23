{ pkgs, ... }:
let
  volumeOsd = pkgs.writeShellApplication {
    name = "volume-osd";
    runtimeInputs = with pkgs; [ wireplumber ];
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

      quickshell ipc call volumeOsd trigger >/dev/null 2>&1 || true
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
