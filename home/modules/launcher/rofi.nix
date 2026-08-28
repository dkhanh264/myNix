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
      shutdown="󰐥  Tắt máy"
      reboot="󰜉  Khởi động lại"
      lock="󰌾  Khóa màn hình"
      suspend="󰤄  Tạm dừng (Suspend)"
      logout="󰍃  Đăng xuất"

      options="''${shutdown}\n''${reboot}\n''${lock}\n''${suspend}\n''${logout}"

      chosen="$(printf '%b' "$options" | rofi -dmenu -p "Nguồn" -i -config "$HOME/.config/rofi/config.rasi" || true)"

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
