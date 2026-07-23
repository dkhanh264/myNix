{ pkgs, ... }:

let
  nixLogoPng = pkgs.runCommand "nixos-lock-logo.png" { } ''
    ${pkgs.librsvg}/bin/rsvg-convert \
      --width 160 --height 160 \
      --output "$out" \
      ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg
  '';
  white = "rgba(255, 255, 255, 1.0)";
  onSurfaceVariant = "rgba(208, 211, 222, 1.0)";
  primary = "rgba(190, 194, 255, 1.0)";
  primaryContainer = "rgba(48, 56, 94, 0.85)";
  surface = "rgba(10, 13, 20, 0.65)";
  surfaceContainer = "rgba(22, 27, 38, 0.75)";
  surfaceStrong = "rgba(26, 32, 45, 0.85)";
  outline = "rgba(255, 255, 255, 0.16)";
  error = "rgba(255, 180, 171, 1.0)";
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
          blur_passes = 4;
          blur_size = 10;
          noise = 0.012;
          contrast = 1.05;
          brightness = 0.50;
          vibrancy = 0.30;
          vibrancy_darkness = 0.20;
        }
      ];

      animations = {
        enabled = true;
        bezier = [
          "m3Standard, 0.2, 0.0, 0.0, 1.0"
          "m3Emphasized, 0.05, 0.7, 0.1, 1.0"
        ];
        animation = [
          "fadeIn, 1, 4, m3Emphasized"
          "fadeOut, 1, 3, m3Standard"
          "inputFieldDots, 1, 3, m3Emphasized"
        ];
      };

      shape = [
        {
          monitor = "";
          size = "792, 432";
          color = surface;
          rounding = 24;
          border_size = 1;
          border_color = outline;
          position = "0, -4";
          halign = "center";
          valign = "center";
          zindex = 0;
        }
        {
          monitor = "";
          size = "282, 400";
          color = primaryContainer;
          rounding = 20;
          border_size = 0;
          position = "-239, -4";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        {
          monitor = "";
          size = "72, 72";
          color = surfaceContainer;
          rounding = 20;
          border_size = 0;
          position = "-239, 128";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        {
          monitor = "";
          size = "218, 40";
          color = surfaceContainer;
          rounding = 20;
          border_size = 1;
          border_color = outline;
          position = "-239, -157";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          size = "56, 56";
          color = primaryContainer;
          rounding = 16;
          border_size = 0;
          position = "142, 128";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        {
          monitor = "";
          size = "300, 40";
          color = surfaceContainer;
          rounding = 20;
          border_size = 1;
          border_color = outline;
          position = "142, -154";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
      ];

      image = [
        {
          monitor = "";
          path = "${nixLogoPng}";
          size = 46;
          rounding = 12;
          border_size = 0;
          position = "-239, 128";
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
          font_size = 64;
          font_family = "Noto Sans";
          position = "-239, 34";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
          color = onSurfaceVariant;
          font_size = 12;
          font_family = "Noto Sans";
          position = "-239, -31";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "<b>$USER</b> · NixOS";
          color = white;
          font_size = 11;
          font_family = "Noto Sans";
          position = "-239, -157";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "lock";
          color = primary;
          font_size = 27;
          font_family = "Material Symbols Rounded";
          position = "142, 128";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "<b>Mở khóa phiên làm việc</b>";
          color = white;
          font_size = 22;
          font_family = "Noto Sans";
          position = "142, 78";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "Nhập mật khẩu của $USER để tiếp tục";
          color = onSurfaceVariant;
          font_size = 10;
          font_family = "Noto Sans";
          position = "142, 47";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "Nhập mật khẩu rồi nhấn Enter";
          color = onSurfaceVariant;
          font_size = 10;
          font_family = "Noto Sans";
          position = "142, -82";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "Enter  ·  Xác thực an toàn";
          color = onSurfaceVariant;
          font_size = 10;
          font_family = "Noto Sans";
          position = "142, -154";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "382, 64";
          position = "142, -20";
          halign = "center";
          valign = "center";
          zindex = 2;
          outline_thickness = 2;
          inner_color = surfaceStrong;
          outer_color = primary;
          check_color = primary;
          fail_color = error;
          font_family = "Noto Sans";
          font_color = white;
          placeholder_text = "Mật khẩu";
          check_text = "Đang xác thực…";
          fail_text = "<b>Không đúng</b> · thử lại ($ATTEMPTS)";
          rounding = 20;
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
