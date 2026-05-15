# File: home/modules/shell/starship.nix
{ ... }:
{
  programs.starship = {
    enable = true;
    # Bỏ trống phần settings để hệ thống tự đọc file starship.toml từ ~/.config
  };
}
