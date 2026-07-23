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
        # Main Hero Expressive Card Container
        {
          monitor = "";
          size = "820, 480";
          color = "$surface";
          rounding = 32;
          border_size = 2;
          border_color = "$primary";
          position = "0, 0";
          halign = "center";
          valign = "center";
          zindex = 0;
        }
        # Left Accent Hero Section (Clock & Date Card)
        {
          monitor = "";
          size = "320, 436";
          color = "$surface_container";
          rounding = 24;
          border_size = 1;
          border_color = "$primary";
          position = "-224, 0";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        # User Avatar Capsule Badge
        {
          monitor = "";
          size = "80, 80";
          color = "$surface";
          rounding = 24;
          border_size = 2;
          border_color = "$primary";
          position = "-224, 135";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Expressive Lock Status Indicator Badge
        {
          monitor = "";
          size = "64, 64";
          color = "$primary";
          rounding = 20;
          border_size = 0;
          position = "170, 140";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
        # MD3 System Info Pill (User Badge)
        {
          monitor = "";
          size = "236, 42";
          color = "$surface";
          rounding = 21;
          border_size = 1;
          border_color = "$primary";
          position = "-224, -165";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Security Footer Pill
        {
          monitor = "";
          size = "320, 42";
          color = "$surface_container";
          rounding = 21;
          border_size = 1;
          border_color = "$primary";
          position = "170, -165";
          halign = "center";
          valign = "center";
          zindex = 1;
        }
      ];

      image = [
        {
          monitor = "";
          path = "${nixLogoPng}";
          size = 52;
          rounding = 16;
          border_size = 0;
          position = "-224, 135";
          halign = "center";
          valign = "center";
          zindex = 3;
        }
      ];

      label = [
        # Large Expressive Hero Clock Digit ($TIME)
        {
          monitor = "";
          text = "$TIME";
          color = "$primary";
          font_size = 68;
          font_family = "Noto Sans Bold";
          position = "-224, 32";
          halign = "center";
          valign = "center";
          zindex = 3;
        }
        # Formatted Date Label
        {
          monitor = "";
          text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
          color = "$fg";
          font_size = 13;
          font_family = "Noto Sans";
          position = "-224, -36";
          halign = "center";
          valign = "center";
          zindex = 3;
        }
        # User Pill Label
        {
          monitor = "";
          text = "<b>$USER</b> · NixOS Expressive";
          color = "$fg";
          font_size = 12;
          font_family = "Noto Sans";
          position = "-224, -165";
          halign = "center";
          valign = "center";
          zindex = 3;
        }
        # Lock Icon inside Badge
        {
          monitor = "";
          text = "lock";
          color = "$on_primary";
          font_size = 30;
          font_family = "Material Symbols Rounded";
          position = "170, 140";
          halign = "center";
          valign = "center";
          zindex = 3;
        }
        # Main Title Header
        {
          monitor = "";
          text = "<b>Mở khóa hệ thống</b>";
          color = "$fg";
          font_size = 24;
          font_family = "Noto Sans Bold";
          position = "170, 82";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Subtitle Prompt
        {
          monitor = "";
          text = "Nhập mật khẩu của $USER để tiếp tục";
          color = "$fg";
          font_size = 11;
          font_family = "Noto Sans";
          position = "170, 48";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Instruction Label
        {
          monitor = "";
          text = "Nhập mật khẩu rồi nhấn Enter";
          color = "$fg";
          font_size = 10;
          font_family = "Noto Sans";
          position = "170, -88";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
        # Footer Action Label
        {
          monitor = "";
          text = "Enter  ·  Xác thực an toàn MD3";
          color = "$fg";
          font_size = 11;
          font_family = "Noto Sans";
          position = "170, -165";
          halign = "center";
          valign = "center";
          zindex = 2;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "360, 64";
          position = "170, -20";
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
          placeholder_text = "Mật khẩu";
          check_text = "Đang xác thực…";
          fail_text = "<b>Không đúng</b> · Thử lại ($ATTEMPTS)";
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
