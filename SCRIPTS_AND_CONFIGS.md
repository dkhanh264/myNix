# Giải thích scripts & configs của repo `myNix`

Tài liệu này mô tả **toàn bộ script và file config chính** trong repo để bạn dễ hiểu và tùy chỉnh.

## 1) Luồng cấu hình tổng thể

1. `flake.nix` tạo `nixosConfigurations.HiMeo`.
2. `hosts/laptop/configuration.nix` cấu hình hệ thống NixOS.
3. Home Manager được mount trong `flake.nix`, user `dk` import `home/home.nix`.
4. `home/home.nix` import các module con: shell, hyprland, terminal, dev, theme, media, browser...
5. `home/modules/hyprland/scripts.nix` build các script runtime (waybar/menu/wallpaper/osd).
6. `xdg.configFile` trong các module map dotfiles vào `~/.config/...`.

---

## 2) Scripts (được tạo bằng Nix)

Tất cả script nằm trong: `home/modules/hyprland/scripts.nix`

### `wal-color-export`
- Mục đích: đồng bộ màu từ `~/.cache/wal/colors.json` sang:
  - `~/.config/current/wal-colors.css` (Waybar/Walker)
  - `~/.config/kitty/wal-theme.conf` (Kitty)
  - `~/.config/btop/themes/wal.theme` (btop)
  - `~/.cache/wal/mako-colors.conf` (Mako)
- Tùy chỉnh:
  - đổi biến màu CSS trong block `@define-color`
  - đổi mapping màu cho Kitty/btop nếu muốn theme khác

### `cycle-background`
- Mục đích: chuyển wallpaper theo vòng lặp từ `~/Pictures/wallpapers`, hỗ trợ ảnh và video.
- Cơ chế:
  - lưu wallpaper hiện tại qua symlink `~/.config/current-wallpaper`
  - nếu là video: dùng `mpvpaper`, trích frame bằng `ffmpeg`, rồi chạy `wal`
  - nếu là ảnh: dùng `swww` với transition khác nhau
- Tùy chỉnh:
  - sửa thư mục wallpaper: `BACKGROUNDS_DIR`
  - sửa danh sách hiệu ứng: `TRANSITIONS=(...)`

### `walker-menu`
- Mục đích: menu cho `apps`, `system`, `profile` qua Walker.
- Dùng trong keybind Hyprland:
  - `SUPER+Space` → apps
  - `SUPER+Esc` → system
  - `SUPER+P` → profile
- Tùy chỉnh:
  - sửa item menu trong `system_menu()` / `profile_menu()`
  - đổi theme qua `APP_THEME`, `SYSTEM_THEME`

### `volume-osd`
- Mục đích: tăng/giảm/tắt tiếng bằng `wpctl` + thông báo Mako.
- Tùy chỉnh:
  - đổi step volume (mặc định 5%)
  - đổi nội dung notify

### `waybar-music`
- Mục đích: lấy player + tiêu đề bài hát cho module Waybar.
- Tùy chỉnh:
  - đổi icon theo player trong `case`
  - đổi format output

### `waybar-active-apps`
- Mục đích: hiển thị icon app đang mở ở workspace hiện tại (Hyprland JSON + `jq`).
- Tùy chỉnh:
  - map thêm icon theo class app trong `case`
  - đổi logic lọc app nếu cần

---

## 3) File cấu hình cấp root repo

### `flake.nix`
- Entry flake chính; pin inputs (`nixpkgs`, `home-manager`, `nixvim`, `lanzaboote`).
- Tạo host `HiMeo` bằng `mkSystem`.
- Tùy chỉnh thường làm:
  - đổi channel nixpkgs
  - thêm host mới vào `nixosConfigurations`
  - thêm module global

### `flake.lock`
- Lock version inputs.
- Tùy chỉnh: thường không sửa tay; update bằng `nix flake update`.

---

## 4) Cấu hình hệ thống NixOS (host)

### `hosts/laptop/configuration.nix`
- File hệ thống chính:
  - boot/lanzaboote
  - network/locale/input method
  - NVIDIA + PRIME sync
  - Hyprland + SDDM + PipeWire + Bluetooth
  - user `dk`, fonts, systemPackages, nix settings
- Tùy chỉnh thường làm:
  - đổi hostname/user/packages
  - đổi GPU mode
  - thêm service hệ thống

### `hosts/laptop/hardware-configuration.nix`
- File auto-generate bởi `nixos-generate-config`.
- Chứa disk UUID, kernel modules, filesystem.
- Nên giữ ổn định, chỉ sửa khi đổi phần cứng/phân vùng.

---

## 5) Home Manager core

### `home/home.nix`
- Root Home Manager cho user; import toàn bộ module con.

### `home/core/default.nix`
- Gom module core: `packages.nix`, `env.nix`.

### `home/core/packages.nix`
- Danh sách package user-level (CLI/GUI/Wayland tools).
- Tùy chỉnh: thêm/bớt app dùng hằng ngày.

### `home/core/env.nix`
- Biến môi trường chung (`EDITOR`, `BROWSER`, biến Wayland/NVIDIA/Fcitx5...).
- Tùy chỉnh: đổi terminal/editor, thêm env app-specific.

---

## 6) Module Home Manager theo chức năng

### Nhóm Hyprland
- `home/modules/hyprland/default.nix`: import các module hyprland con.
- `home/modules/hyprland/hyprland.nix`: keybind, monitor, animation, window rules, autostart.
- `home/modules/hyprland/waybar.nix`: bật Waybar + map config `waybar` và `walker`.
- `home/modules/hyprland/mako.nix`: bật notification daemon Mako.
- `home/modules/hyprland/hypridle.nix`: idle/screen dim/lock bằng Home Manager.
- `home/modules/hyprland/scripts.nix`: tạo toàn bộ script runtime (mục 2).

### Nhóm shell
- `home/modules/shell/default.nix`: import `zsh.nix`, `starship.nix`.
- `home/modules/shell/zsh.nix`: alias, completion, autosuggestion, init.
- `home/modules/shell/starship.nix`: bật Starship prompt.

### Nhóm terminal
- `home/modules/terminal/default.nix`: import `kitty.nix`.
- `home/modules/terminal/kitty.nix`: font, opacity, remote control, include `wal-theme.conf`.

### Nhóm dev
- `home/modules/dev/git.nix`: git identity, alias, delta config.
- `home/modules/dev/neovim.nix`: cấu hình NixVim đầy đủ (plugins/LSP/keymaps/theme sync pywal).

### Nhóm giao diện/app
- `home/modules/theme/gtk.nix`: GTK/Qt theme + pointer cursor + pywal package.
- `home/modules/browser/firefox.nix`: Firefox profile `dk` + `userChrome` tùy biến.
- `home/modules/media/obs.nix`: bật OBS Studio.
- `home/modules/extra-dots.nix`: map thêm dotfiles (btop/mpv/neofetch/hyprlock/starship).

---

## 7) Dotfiles đang được map

### Waybar
- `home/modules/hyprland/dotfiles/waybar/config.jsonc`: bố cục modules + command cho custom modules.
- `home/modules/hyprland/dotfiles/waybar/style.css`: style + import màu động `~/.config/current/wal-colors.css`.

### Walker
- `home/modules/hyprland/dotfiles/walker/config.toml`: hành vi launcher, builtins, phím, module bật/tắt.
- `home/modules/hyprland/dotfiles/walker/themes/*.css`: theme giao diện (apps/system/power/transparent).
- `home/modules/hyprland/dotfiles/walker/themes/*.toml`: kích thước/khung UI cho từng mode.

### Hyprlock / Hypridle
- `home/modules/hyprland/dotfiles/hyprlock.conf`: giao diện lock screen.
- `home/modules/hyprland/dotfiles/hypridle.conf`: idle listener (dim + lock) theo file conf gốc.

### CLI app configs
- `home/modules/hyprland/dotfiles/starship.toml`: prompt format.
- `home/modules/hyprland/dotfiles/btop/btop.conf`: cấu hình btop.
- `home/modules/hyprland/dotfiles/mpv/mpv.conf`: cấu hình mpv.
- `home/modules/hyprland/dotfiles/neofetch/config.conf`: cấu hình neofetch.

---

## 8) Điểm tùy chỉnh nhanh (thực tế nhất)

1. **Đổi phím tắt Hyprland**: sửa `home/modules/hyprland/hyprland.nix`.
2. **Đổi layout Waybar**: sửa `dotfiles/waybar/config.jsonc`.
3. **Đổi style Waybar/Walker**: sửa các file CSS theme.
4. **Đổi wallpaper flow + transition**: sửa script `cycle-background` trong `scripts.nix`.
5. **Đổi app mặc định + env**: sửa `home/core/env.nix`.
6. **Thêm app/packages**: sửa `home/core/packages.nix`.
7. **Đổi shell aliases**: sửa `home/modules/shell/zsh.nix`.
8. **Đổi cấu hình hệ thống (driver/service)**: sửa `hosts/laptop/configuration.nix`.

---

## 9) Lưu ý khi chỉnh

- Với file auto-generate như `hardware-configuration.nix`, hạn chế sửa tay.
- Scripts trong `scripts.nix` là runtime behavior quan trọng (wallpaper/theme/menu/waybar).
- Sau khi chỉnh, rebuild bằng:
  - `sudo nixos-rebuild switch --flake /etc/nixos#HiMeo`
