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

      shape = [
        # Android 17 Top Lock Status Badge Container
        {
          monitor = "";
          size = "220, 38";
          color = "$surface_container";
          rounding = 19;
          border_size = 1;
          border_color = "$primary";
          position = "0, 320";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        # Android 17 Date Pill Chip Container
        {
          monitor = "";
          size = "280, 36";
          color = "$surface_container";
          rounding = 18;
          border_size = 1;
          border_color = "$primary";
          position = "0, -85";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        # Bottom Left Action Circle Badge (Sleep)
        {
          monitor = "";
          size = "52, 52";
          color = "$surface_container";
          rounding = 26;
          border_size = 1;
          border_color = "$primary";
          position = "-260, -320";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        # Bottom Right Action Circle Badge (Power)
        {
          monitor = "";
          size = "52, 52";
          color = "$surface_container";
          rounding = 26;
          border_size = 1;
          border_color = "$error";
          position = "260, -320";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        # Bottom Gesture Indicator Handle Bar
        {
          monitor = "";
          size = "80, 5";
          color = "$surface_bright";
          rounding = 3;
          border_size = 0;
          position = "0, -350";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
      ];

      label = [
        # Top Lock Status Text
        {
          monitor = "";
          text = "🔒 Android 17  ·  Đã khóa";
          color = "$primary";
          font_size = 12;
          font_family = "Noto Sans Bold";
          position = "0, 320";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Android 17 Giant Stacked Hero Clock - Hours
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
        # Android 17 Giant Stacked Hero Clock - Minutes
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
        # User Instruction Label
        {
          monitor = "";
          text = "Mở khóa cho <b>$USER</b>";
          color = "$fg";
          font_size = 12;
          font_family = "Noto Sans";
          position = "0, -125";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Bottom Left Sleep Icon
        {
          monitor = "";
          text = "bedtime";
          color = "$primary";
          font_size = 22;
          font_family = "Material Symbols Rounded";
          position = "-260, -320";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Bottom Right Power Icon
        {
          monitor = "";
          text = "power_settings_new";
          color = "$error";
          font_size = 22;
          font_family = "Material Symbols Rounded";
          position = "260, -320";
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

