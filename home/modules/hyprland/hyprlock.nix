{ pkgs, ... }:

let
  nixLogoPng = pkgs.runCommand "nixos-lock-logo.png" { } ''
    ${pkgs.librsvg}/bin/rsvg-convert \
      --width 160 --height 160 \
      --output "$out" \
      ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg
  '';
  white = "rgba(255,255,255,1.0)";
  secondary = "rgba(210,213,224,1.0)";
  primary = "rgba(190,194,255,1.0)";
  primaryContainer = "rgba(48,56,94,0.92)";
  surface = "rgba(12,16,23,0.70)";
  surfaceStrong = "rgba(28,34,46,0.94)";
  outline = "rgba(218,221,232,0.18)";
  error = "rgba(255,180,171,1.0)";
in
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = true;
        grace = 2;
        hide_cursor = true;
      };

      background = [
        {
          monitor = "";
          path = "/home/dk/.config/current-wallpaper";
          blur_passes = 5;
          blur_size = 10;
          noise = 0.012;
          contrast = 1.06;
          brightness = 0.48;
          vibrancy = 0.20;
          vibrancy_darkness = 0.18;
        }
      ];

      animations = {
        enabled = true;
        bezier = [
          "m3Standard, 0.2, 0.0, 0.0, 1.0"
          "m3Emphasized, 0.05, 0.7, 0.1, 1.0"
        ];
        animation = [
          "fadeIn, 1, 5, m3Emphasized"
          "fadeOut, 1, 4, m3Standard"
          "inputFieldDots, 1, 3, m3Emphasized"
        ];
      };

      shape = [
        {
          monitor = "";
          size = "700, 360";
          color = surface;
          rounding = 24;
          border_size = 0;
          position = "0, 0";
          halign = "center";
          valign = "center";
          zindex = 0;
          shadow_passes = 4;
          shadow_size = 12;
          shadow_color = "rgba(0,0,0,0.46)";
        }
        {
          monitor = "";
          size = "104, 104";
          color = primaryContainer;
          rounding = 52;
          border_size = 0;
          position = "-205, 92";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        {
          monitor = "";
          size = "1, 274";
          color = outline;
          rounding = 0;
          border_size = 0;
          position = "-46, 0";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
      ];

      image = [
        {
          monitor = "";
          path = "${nixLogoPng}";
          size = 64;
          rounding = 18;
          border_size = 0;
          position = "-205, 92";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          color = white;
          font_size = 54;
          font_family = "Noto Sans";
          position = "-205, 6";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
          color = secondary;
          font_size = 12;
          font_family = "Noto Sans";
          position = "-205, -44";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "<b>$USER</b> · NixOS";
          color = primary;
          font_size = 11;
          font_family = "Noto Sans";
          position = "-205, -112";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "<b>Mở khóa phiên làm việc</b>";
          color = white;
          font_size = 20;
          font_family = "Noto Sans";
          position = "124, 88";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "Nhập mật khẩu của $USER để tiếp tục";
          color = secondary;
          font_size = 10;
          font_family = "Noto Sans";
          position = "124, 56";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "Nhấn Enter để xác thực";
          color = secondary;
          font_size = 10;
          font_family = "Noto Sans";
          position = "124, -62";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "350, 60";
          position = "124, 0";
          halign = "center";
          valign = "center";
          zindex = 2;
          outline_thickness = 2;
          inner_color = surfaceStrong;
          outer_color = primaryContainer;
          check_color = primary;
          fail_color = error;
          font_family = "Noto Sans";
          font_color = white;
          placeholder_text = "Mật khẩu";
          check_text = "Đang xác thực…";
          fail_text = "<b>Không đúng</b> · thử lại ($ATTEMPTS)";
          rounding = 18;
          shadow_passes = 0;
          fade_on_empty = false;
          dots_size = 0.22;
          dots_spacing = 0.28;
          dots_center = true;
        }
      ];

      auth = {
        "fingerprint:enabled" = false;
      };
    };
  };
}
