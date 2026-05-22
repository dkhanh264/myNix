

## Tính năng chính

- **NixOS flake** với cấu hình `nixosConfigurations.your-laptop`.
- **Hyprland (Wayland)**: quickshell, dunst, hyprpaper, hypridle, hyprlock.
- **NVIDIA + Intel PRIME Sync Mode** và biến môi trường Wayland cần thiết.
- **Home Manager** cho user `dk` với module tách theo chủ đề.
- **NixVim** cấu hình hoàn toàn bằng Nix (LSP, Treesitter, Telescope, v.v.).
- **Shell**: Zsh + Starship + alias tiện dụng.
- **Theme**: GTK/Qt + Pywal theo wallpaper.
- **Wallpaper picker**: Super+P để chọn wallpaper và cập nhật theme theo màu.

## Cấu hình hệ thống

File chính: `hosts/laptop/configuration.nix`

- Bootloader: systemd-boot (UEFI)
- NetworkManager
- Timezone: `Asia/Ho_Chi_Minh`
- Input method: Fcitx5 + Unikey
- Audio: PipeWire
- Display manager: SDDM (Wayland)

## Cấu hình Home Manager

File chính: `home/home.nix`

- Core packages + môi trường
- Hyprland + Quickshell + Dunst + Hyprpaper + Hypridle
- Quickshell (autostart qua Hyprland `exec-once`)
- Terminal: Kitty
- Dev: Git + NixVim
- Theme: GTK/Qt + Pywal

## Sử dụng

> **Lưu ý:** Thay `your-laptop` bằng hostname thực tế của bạn.

### Build / Switch

```
sudo nixos-rebuild switch --flake /etc/nixos#your-laptop
```

### Update flake

```
sudo nix flake update /etc/nixos
```

### Garbage collect

```
sudo nix-collect-garbage -d
```

## Ghi chú

- Wallpaper mặc định lấy từ `~/Pictures/wallpapers/wallpaper.jpg`.
- Có alias sẵn trong Zsh để rebuild/update/gc.

## Tích hợp vào cấu trúc `ilyamiro/nixos-configuration`

Repo này đã thêm module Quickshell ở:
- `home/modules/hyprland/quickshell.nix`
- `home/modules/hyprland/dotfiles/quickshell/shell.qml`

Nếu bạn giữ cấu trúc `/etc/nixos/config/...` như `ilyamiro/nixos-configuration`, có thể map tương đương:
- `home/modules/hyprland/quickshell.nix` → `config/programs/quickshell/default.nix`
- `home/modules/hyprland/dotfiles/quickshell/*` → `config/programs/quickshell/*`

Và import module mới trong `home.nix` (hoặc cơ chế auto-import thư mục `config/programs`) để Home Manager symlink vào `~/.config/quickshell`.
