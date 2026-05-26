{ ... }:
{
  programs.waybar = {
    enable = true;
  };

  # Quản lý file tĩnh để cho phép script runtime ghi wal-colors.css
  xdg.configFile."waybar/config.jsonc".source = ./dotfiles/waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./dotfiles/waybar/style.css;
  xdg.configFile."walker" = {
    source = ./dotfiles/walker;
    recursive = true;
  };
}
