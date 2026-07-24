{ pkgs, ... }:

let
  nixLogoPng = pkgs.runCommand "nixos-lock-logo.png" { } ''
    ${pkgs.librsvg}/bin/rsvg-convert \
      --width 160 --height 160 \
      --output "$out" \
      ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg
  '';
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
          brightness = 0.55;
          vibrancy = 0.35;
          vibrancy_darkness = 0.20;
        }
      ];

      animations = {
        enabled = true;
        bezier = [
          "m3Standard, 0.2, 0.0, 0.0, 1.0"
          "m3Emphasized, 0.05, 0.7, 0.1, 1.0"
          "expressive, 0.175, 0.885, 0.32, 1.275"
        ];
        animation = [
          "fadeIn, 1, 4, expressive"
          "fadeOut, 1, 3, m3Standard"
          "inputFieldDots, 1, 3, m3Emphasized"
        ];
      };

      shape = [ ];

      label = [
        # Stacked Hero Clock - Hours
        {
          monitor = "";
          text = "cmd[update:1000] date +\"%H\"";
          color = "$fg";
          font_size = 124;
          font_family = "Noto Sans Bold";
          position = "0, 160";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Stacked Hero Clock - Minutes
        {
          monitor = "";
          text = "cmd[update:1000] date +\"%M\"";
          color = "$primary";
          font_size = 124;
          font_family = "Noto Sans Bold";
          position = "0, 20";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Date Chip Label
        {
          monitor = "";
          text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
          color = "$fg";
          font_size = 13;
          font_family = "Noto Sans";
          position = "0, -85";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "360, 56";
          position = "0, -180";
          halign = "center";
          valign = "center";
          zindex = 3;
          outline_thickness = 2;
          inner_color = "$surface";
          outer_color = "$primary";
          check_color = "$primary";
          fail_color = "$error";
          font_family = "Noto Sans";
          font_color = "$fg";
          placeholder_text = "Nhập mật khẩu...";
          check_text = "Đang xác thực…";
          fail_text = "<b>Mật khẩu không đúng</b> ($ATTEMPTS)";
          rounding = 28;
          shadow_passes = 0;
          fade_on_empty = false;
          dots_size = 0.24;
          dots_spacing = 0.30;
          dots_center = true;
        }
      ];

      auth = {
        "fingerprint:enabled" = false;
      };
    };

    extraConfig = ''
      source = ~/.config/hypr/hyprlock-colors.conf
    '';
  };
}

