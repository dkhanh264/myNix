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
  primaryContainer = "rgba(42,48,79,0.94)";
  surface = "rgba(13,17,24,0.72)";
  surfaceStrong = "rgba(24,29,39,0.88)";
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
          blur_passes = 4;
          blur_size = 12;
          noise = 0.018;
          contrast = 1.08;
          brightness = 0.56;
          vibrancy = 0.24;
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
          "fadeIn, 1, 5, m3Emphasized"
          "fadeOut, 1, 4, m3Standard"
          "inputFieldDots, 1, 3, m3Emphasized"
        ];
      };

      shape = [
        {
          monitor = "";
          size = "520, 430";
          color = surface;
          rounding = 32;
          border_size = 1;
          border_color = "rgba(255,255,255,0.14)";
          position = "0, 0";
          halign = "center";
          valign = "center";
          zindex = 0;
          shadow_passes = 6;
          shadow_size = 18;
          shadow_color = "rgba(0,0,0,0.52)";
        }
      ];

      image = [
        {
          monitor = "";
          path = "${nixLogoPng}";
          size = 66;
          rounding = 20;
          border_size = 0;
          position = "0, 135";
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
          font_size = 62;
          font_family = "Noto Sans";
          position = "0, 47";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
          color = secondary;
          font_size = 13;
          font_family = "Noto Sans";
          position = "0, -2";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "<b>$USER</b>  ·  NixOS";
          color = primary;
          font_size = 12;
          font_family = "Noto Sans";
          position = "0, -148";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        {
          monitor = "";
          text = "Enter để mở khóa";
          color = secondary;
          font_size = 10;
          font_family = "Noto Sans";
          position = "0, -184";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "420, 64";
          position = "0, -82";
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
          rounding = 24;
          shadow_passes = 2;
          shadow_size = 8;
          shadow_color = "rgba(0,0,0,0.34)";
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
