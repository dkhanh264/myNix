## Key Features

- **NixOS flake** with `nixosConfigurations.HiMeo` target.
- **Niri (Wayland)**: Quickshell topbar, Rofi, Mako, and Hypridle.
- **NVIDIA + Intel PRIME Sync Mode** with Wayland optimizations.
- **Home Manager** for user `dk` with modular topic configuration.
- **NixVim** configured entirely in Nix (LSP, Treesitter, Telescope, etc.).
- **Shell**: Zsh + Starship + productivity aliases.
- **Theme**: GTK/Qt + dynamic Pywal color palette synced with wallpaper.
- **Wallpaper switcher**: `Super+Ctrl+Space` to cycle wallpaper and dynamically update system colors.
- **Scripts managed by Nix flake**: modular OSD and system control utilities packaged via `writeShellApplication`.

## System Configuration

Main file: `hosts/laptop/configuration.nix`

- Bootloader: systemd-boot (UEFI) / Lanzaboote
- NetworkManager
- Timezone: `Asia/Ho_Chi_Minh`
- Input method: Fcitx5
- Audio: PipeWire + WirePlumber
- Display manager: SDDM (Wayland)

## Home Manager Configuration

Main file: `home/home.nix`

- Core packages & environment
- Niri + Quickshell + Rofi + Mako + Hypridle
- Terminal: Kitty
- Dev: Git + NixVim
- Theme: GTK/Qt + Pywal

## NixVim Shortcuts

- `Space + e`: Toggle file explorer tree.
- `Space + ff`: Quick file search.
- `Space + fg`: Live grep text across project.
- `Space + fr`: Open recent files.
- `Space + fk`: Search keymaps.
- `Space + w`: Save file.
- `Space + q`: Close current window.
- `Esc`: Clear search highlights.
- Press `Space` and wait for the `which-key` popup menu for shortcuts.

## Usage

### Build / Switch

```sh
sudo nixos-rebuild switch --flake .#HiMeo
```

### Update flake

```sh
sudo nix flake update
```

### Garbage collect

```sh
sudo nix-collect-garbage -d
```

## Notes

- Default wallpaper loaded from `~/Pictures/wallpapers`.
- Zsh aliases available for quick rebuild/update/gc.
