{ pkgs, ... }:
let
  volumeOsd = pkgs.writeShellScriptBin "volume-osd" ''
      #!/usr/bin/env bash
      case "$1" in
      up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
      down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
      mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
      esac
  
      volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
      muted=$(echo "$volume" | grep -o "MUTED")
      volume_percent=$(echo "$volume" | awk '{print int($2 * 100)}')
  
      if [ -n "$muted" ]; then
         ${pkgs.libnotify}/bin/notify-send -h string:x-canonical-private-synchronous:volume -t 2000 "🔇 Đã tắt tiếng"
      else
         ${pkgs.libnotify}/bin/notify-send -h string:x-canonical-private-synchronous:volume -h int:value:"$volume_percent" -t 2000 "Âm lượng: $volume_percent%"
      fi
    '';

in
{
  home.packages = [ volumeOsd ];
}
