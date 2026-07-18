

## Tính năng chính

- **NixOS flake** với cấu hình `nixosConfigurations.HiMeo`.
- **Hyprland (Wayland)**: Quickshell, Mako, swww, hypridle, hyprlock.
- **NVIDIA + Intel PRIME Sync Mode** và biến môi trường Wayland cần thiết.
- **Home Manager** cho user `dk` với module tách theo chủ đề.
- **NixVim** cấu hình hoàn toàn bằng Nix (LSP, Treesitter, Telescope, v.v.).
- **Shell**: Zsh + Starship + alias tiện dụng.
- **Theme**: GTK/Qt + Pywal theo wallpaper.
- **Wallpaper switcher**: Super+Ctrl+Space để đổi wallpaper, mỗi lần đổi dùng hiệu ứng animation khác nhau và cập nhật theme theo màu.
- **Quickshell Material 3 Expressive**: top bar đa màn hình và control center quản lý âm lượng, độ sáng, Wi‑Fi, Bluetooth, nguồn và cài đặt.
- **Scripts quản lý bởi Nix flake**: script tùy biến (menu/wallpaper/OSD) được đóng gói bằng `writeShellScriptBin`.

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

### Quickshell control center

- Nhấn vào cụm trạng thái bên phải top bar hoặc bấm `Super+A` để mở.
- Kéo thanh âm lượng/độ sáng; nhấn biểu tượng loa để mute.
- Nhấn phần chính của tile Wi‑Fi/Bluetooth để bật hoặc tắt, nhấn mũi tên để xem thiết bị/mạng.
- Wi‑Fi đã lưu hoặc mạng mở có thể kết nối trực tiếp. Với mạng mới cần mật khẩu, dùng nút **Mở cài đặt**.
- Logout, reboot và shutdown luôn yêu cầu xác nhận lần hai.
- Màu giao diện tự đọc từ `~/.cache/wal/colors.json` và cập nhật khi Pywal đổi palette.
- Chuyển động dùng motion token Material 3: emphasized easing cho popup, spring cho shape morph, stagger cho nội dung và ripple/state layer trên các điều khiển.

### Build / Switch

```
sudo nixos-rebuild switch --flake /etc/nixos#HiMeo
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
