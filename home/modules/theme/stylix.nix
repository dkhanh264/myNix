# home/modules/theme/stylix.nix
# Stylix quản lý colorscheme cho TOÀN BỘ hệ thống.
# Khi bạn đổi theme ở đây, mọi app đều tự động thay đổi.
{ pkgs, config, ... }:
{
  stylix = {
    enable = true;

    # ── Cách 1: Dùng ảnh wallpaper để generate colorscheme ──────────────
    # Stylix phân tích màu sắc trong ảnh và tạo ra palette 16 màu.
    # Đây là cách thú vị nhất — wallpaper và UI sẽ luôn hài hòa màu sắc.
    image = ./b-030.jpg;
    # Copy wallpaper vào cùng thư mục: /etc/nixos/home/modules/theme/

    # ── Cách 2: Dùng theme có sẵn từ base16 collection ──────────────────
    # Uncomment một trong các dòng sau để dùng theme có sẵn:
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/one-dark.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/solarized-dark.yaml";

    # ── Font configuration ───────────────────────────────────────────────
    fonts = {
      # Font cho terminal, editor, monospace contexts
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name    = "JetBrainsMono Nerd Font";
      };
      # Font cho UI, labels, buttons
      sansSerif = {
        package = pkgs.noto-fonts;
        name    = "Noto Sans";
      };
      # Font serif (ít dùng trong desktop)
      serif = {
        package = pkgs.noto-fonts;
        name    = "Noto Serif";
      };
      # Font emoji
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name    = "Noto Color Emoji";
      };
      # Kích thước font cho từng context
      sizes = {
        terminal    = 13;
        applications = 11;
        desktop     = 11;
        popups      = 11;
      };
    };

    # ── Opacity ─────────────────────────────────────────────────────────
    opacity = {
      terminal     = 0.95;  # Terminal hơi trong suốt
      applications = 1.0;   # App bình thường không trong suốt
      popups       = 0.95;
    };

    # ── Cursor ──────────────────────────────────────────────────────────
    cursor = {
      package = pkgs.adwaita-icon-theme;
      name    = "Adwaita";
      size    = 24;
    };

    # ── Targets — kiểm soát app nào được Stylix quản lý ─────────────────
    # Mặc định Stylix quản lý TẤT CẢ app nó biết.
    # Nếu muốn một app dùng theme riêng, set enable = false.
    targets = {
      # Nếu bạn muốn tự config Waybar (giữ CSS cũ), tắt dòng này:
      # waybar.enable = false;

      # Nếu muốn tự config Neovim colorscheme:
      # nixvim.enable = false;

      # Nếu muốn giữ GTK theme cũ (Adwaita-dark):
      # gtk.enable = false;

      # Hyprland border colors
      hyprland.enable = true;

      # Kitty terminal
      kitty.enable = true;

      # Neovim colorscheme
      nixvim.enable = true;

      # GTK apps
      gtk.enable = true;

      # Waybar colors
      waybar.enable = true;

      # SDDM login screen
      sddm.enable = true;

      # Firefox
      firefox.enable = true;
    };
  };
}
