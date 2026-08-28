{ pkgs, ... }:
let
  rofiLauncher = pkgs.writeShellScriptBin "rofi-launcher" ''
    exec ${pkgs.rofi}/bin/rofi -show drun -config "$HOME/.config/rofi/config.rasi"
  '';

  rofiPowerMenu = pkgs.writeShellApplication {
    name = "rofi-power-menu";
    runtimeInputs = with pkgs; [
      rofi
      systemd
      procps
    ];
    text = ''
      shutdown="󰐥  Power Off"
      reboot="󰜉  Reboot"
      lock="󰌾  Lock Screen"
      suspend="󰤄  Suspend"
      logout="󰍃  Log Out"

      options="''${shutdown}\n''${reboot}\n''${lock}\n''${suspend}\n''${logout}"

      chosen="$(printf '%b' "$options" | rofi -dmenu -p "Power" -i \
        -config "$HOME/.config/rofi/config.rasi" \
        -theme-str 'window { width: 380px; } mainbox { children: [ "listview" ]; } inputbar { enabled: false; } listview { lines: 5; scrollbar: false; }' || true)"

      case "$chosen" in
        "$shutdown")
          systemctl poweroff
          ;;
        "$reboot")
          systemctl reboot
          ;;
        "$lock")
          pidof hyprlock || hyprlock
          ;;
        "$suspend")
          systemctl suspend
          ;;
        "$logout")
          niri msg action quit --skip-confirmation 2>/dev/null || pkill -u "$USER" || true
          ;;
        *)
          exit 0
          ;;
      esac
    '';
  };

in
{
  home.packages = [
    pkgs.rofi
    rofiLauncher
    rofiPowerMenu
  ];

  xdg.configFile."rofi" = {
    source = ./rofi;
    recursive = true;
    force = true;
  };
}
