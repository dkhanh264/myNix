

## Tính năng chính

- **NixOS flake** với cấu hình `nixosConfigurations.your-laptop`.
- **Hyprland (Wayland)**: waybar, dunst, hyprpaper, hypridle, hyprlock.
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
- Hyprland + Waybar + Dunst + Hyprpaper + Hypridle
- Terminal: Kitty
- Dev: Git + NixVim
- Theme: GTK/Qt + Pywal

## NixVim thân thiện cho người mới

- `Space + e`: mở/đóng cây thư mục.
- `Space + ff`: tìm file nhanh.
- `Space + fg`: tìm text trong project.
- `Space + fr`: mở file gần đây.
- `Space + fk`: tìm/phím tắt đã map.
- `Space + w`: lưu file.
- `Space + q`: đóng cửa sổ hiện tại.
- `Esc`: bỏ highlight sau khi search.
- Khi quên phím tắt, bấm `Space` và chờ popup `which-key` hiện gợi ý.

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
