_:
{
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ls  = "eza --icons";
        ll  = "eza -la --icons --git";
        lt  = "eza --tree --icons -L 2";
        cat = "bat";
        cd  = "z";

        # Monitor refresh rate & Siêu tiết kiệm pin (ECO Mode)
        hz60      = "hz 60";
        hz144     = "hz 144";
        hz-status = "hz status";
        eco       = "hz";
        powersave = "hz";
        tietkiem  = "hz";
        pin       = "hz";

        # Monitor rotation (Màn hình rời HDMI-A-1)
        rot90     = "niri msg output HDMI-A-1 transform 90";
        rot0      = "niri msg output HDMI-A-1 transform normal";
        rotnormal = "niri msg output HDMI-A-1 transform normal";
        rot       = "rotate-ext";
        xoay      = "rotate-ext";

        # Android emulator launcher
        runadr = "emulator -avd test -gpu host";

        rebuild     = "sudo nixos-rebuild switch --flake /etc/nixos#HiMeo";
        update      = "sudo nix flake update /etc/nixos";
        gc          = "sudo nix-collect-garbage -d";
        sync-config = "cd /etc/nixos && sudo git pull && rebuild";

        g   = "git";
        gst = "git status";
        gaa = "git add .";
        gcm = "git commit -m";
        gp  = "git push";
        gl  = "git log --oneline --graph --decorate";
      };

      initContent = ''
        # Chế độ Siêu Tiết Kiệm Pin (ECO) & Tần số quét màn hình (hz)
        hz() {
          local NOTIFY_TITLE="⚡ Quản lý năng lượng"

          _notify() {
            local urgency="$1"
            local summary="$2"
            local body="$3"
            if command -v notify-send >/dev/null 2>&1; then
              notify-send -u "$urgency" -a "$NOTIFY_TITLE" "$summary" "$body" 2>/dev/null || true
            fi
          }

          _get_cur_hz() {
            niri msg outputs 2>/dev/null | grep -oE '[0-9]+\.[0-9]+.*\(current\)' | grep -oE '^[0-9]+' || echo "144"
          }

          _get_cur_profile() {
            powerprofilesctl get 2>/dev/null || echo "balanced"
          }

          _get_battery_status() {
            local bat="/sys/class/power_supply/BAT0"
            if [[ -d "$bat" ]]; then
              local status capacity power_now energy_now
              status="$(cat "$bat/status" 2>/dev/null || echo "Unknown")"
              capacity="$(cat "$bat/capacity" 2>/dev/null || echo "0")"
              power_now="$(cat "$bat/power_now" 2>/dev/null || echo "0")"
              energy_now="$(cat "$bat/energy_now" 2>/dev/null || echo "0")"

              local watts="N/A"
              if (( power_now > 0 )); then
                watts="$(awk -v p="$power_now" 'BEGIN { printf "%.1f", p / 1000000 }') W"
              fi

              local rem=""
              if (( power_now > 0 && energy_now > 0 )) && [[ "$status" == "Discharging" ]]; then
                local mins
                mins="$(awk -v e="$energy_now" -v p="$power_now" 'BEGIN { printf "%.0f", (e / p) * 60 }')"
                local h=$(( mins / 60 ))
                local m=$(( mins % 60 ))
                if (( h > 0 )); then
                  rem=" (còn ~''${h}h ''${m}m)"
                else
                  rem=" (còn ~''${m}m)"
                fi
              fi

              echo "''${capacity}% [''${status}] • Tiêu thụ: ''${watts}''${rem}"
            else
              echo "Không tìm thấy thông tin pin"
            fi
          }

          _get_gpu_status() {
            local gpu_pm="/sys/bus/pci/devices/0000:01:00.0/power/runtime_status"
            if [[ -f "$gpu_pm" ]]; then
              local st
              st="$(cat "$gpu_pm" 2>/dev/null || echo "unknown")"
              case "$st" in
                suspended)
                  echo "RTX 4060: D3cold (đang ngủ, 0W) ✓"
                  ;;
                active)
                  echo "RTX 4060: Active (đang thức)"
                  ;;
                *)
                  echo "RTX 4060: $st"
                  ;;
              esac
            else
              echo "NVIDIA dGPU: Không phát hiện hoặc đã tắt"
            fi
          }

          _apply_wifi_powersave() {
            local enable="$1"
            local active_uuid
            active_uuid="$(nmcli -t -f UUID,TYPE connection show --active 2>/dev/null | grep -E "802-11-wireless|wifi" | cut -d: -f1 | head -n1 || true)"
            if [[ -n "$active_uuid" ]]; then
              if [[ "$enable" == "true" ]]; then
                nmcli connection modify "$active_uuid" 802-11-wireless.powersave 3 2>/dev/null || true
              else
                nmcli connection modify "$active_uuid" 802-11-wireless.powersave 2 2>/dev/null || true
              fi
            fi

            local wifi_iface
            wifi_iface="$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^wl' | head -n1 || true)"
            if [[ -n "$wifi_iface" ]] && command -v iw >/dev/null 2>&1; then
              if [[ "$enable" == "true" ]]; then
                iw dev "$wifi_iface" set power_save on 2>/dev/null || sudo -n iw dev "$wifi_iface" set power_save on 2>/dev/null || true
              else
                iw dev "$wifi_iface" set power_save off 2>/dev/null || sudo -n iw dev "$wifi_iface" set power_save off 2>/dev/null || true
              fi
            fi
          }

          _set_eco() {
            echo "🚀 Đang kích hoạt CHẾ ĐỘ SIÊU TIẾT KIỆM PIN (ECO)..."

            # 1. Màn hình: Giảm tần số quét xuống 60Hz
            if niri msg output eDP-1 mode 1920x1080@60.001 2>/dev/null; then
              echo "  ✓ Màn hình: 60Hz"
            else
              echo "  ! Không thể đổi tần số quét màn hình (Niri không chạy?)"
            fi

            # 2. CPU: Đổi power profile sang power-saver
            if command -v powerprofilesctl >/dev/null 2>&1; then
              powerprofilesctl set power-saver 2>/dev/null || true
              echo "  ✓ CPU: power-saver (Lenovo Quiet Mode & Intel EPP power)"
            fi

            # 3. WiFi: Bật tiết kiệm pin
            _apply_wifi_powersave "true"
            echo "  ✓ WiFi: Kích hoạt 802.11 Power Saving"

            # 4. Đèn bàn phím & Giảm độ sáng
            if command -v brightnessctl >/dev/null 2>&1; then
              brightnessctl --device='platform::kbd_backlight' set 0 >/dev/null 2>&1 || true
              echo "  ✓ Bàn phím: Tắt đèn LED nền"

              local cur_b max_b pct
              cur_b="$(brightnessctl g 2>/dev/null || echo 0)"
              max_b="$(brightnessctl m 2>/dev/null || echo 1)"
              pct=$(( cur_b * 100 / max_b ))
              if (( pct > 45 )); then
                echo "$cur_b" > /tmp/.prev_screen_brightness 2>/dev/null || true
                brightnessctl set 35% >/dev/null 2>&1 || true
                echo "  ✓ Màn hình: Giảm độ sáng về 35%"
              fi
            fi

            # 5. Bluetooth: Tắt nếu không kết nối thiết bị nào
            if command -v bluetoothctl >/dev/null 2>&1; then
              local bt_devs
              bt_devs="$(bluetoothctl devices Connected 2>/dev/null || true)"
              if [[ -z "$bt_devs" ]]; then
                bluetoothctl power off >/dev/null 2>&1 || true
                echo "  ✓ Bluetooth: Đã tắt (không có thiết bị kết nối)"
              fi
            fi

            # 6. GPU Status
            echo "  • GPU: $(_get_gpu_status)"

            local bat_info
            bat_info="$(_get_battery_status)"
            echo "  🔋 $bat_info"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "✨ Đã bật Siêu Tiết Kiệm Pin thành công!"

            _notify "normal" "🔋 Chế độ Siêu Tiết Kiệm Pin: ĐÃ BẬT" "Màn hình 60Hz • CPU Power-Saver • WiFi Eco • $bat_info"
          }

          _set_normal() {
            echo "⚡ Đang chuyển về CHẾ ĐỘ HIỆU NĂNG (144Hz)..."

            # 1. Màn hình: Tăng tần số quét lên 144Hz
            if niri msg output eDP-1 mode 1920x1080@144.003 2>/dev/null; then
              echo "  ✓ Màn hình: 144Hz (Mượt mà)"
            else
              echo "  ! Không thể đổi tần số quét màn hình"
            fi

            # 2. CPU: Đổi power profile sang balanced
            if command -v powerprofilesctl >/dev/null 2>&1; then
              powerprofilesctl set balanced 2>/dev/null || true
              echo "  ✓ CPU: balanced"
            fi

            # 3. WiFi: Tắt tiết kiệm pin
            _apply_wifi_powersave "false"
            echo "  ✓ WiFi: Tối đa băng thông & độ trễ thấp"

            # 4. Phục hồi độ sáng màn hình
            if command -v brightnessctl >/dev/null 2>&1; then
              if [[ -f /tmp/.prev_screen_brightness ]]; then
                local prev_b
                prev_b="$(cat /tmp/.prev_screen_brightness 2>/dev/null || echo "")"
                if [[ -n "$prev_b" ]]; then
                  brightnessctl set "$prev_b" >/dev/null 2>&1 || true
                  echo "  ✓ Màn hình: Đã phục hồi độ sáng trước đó"
                fi
                rm -f /tmp/.prev_screen_brightness 2>/dev/null || true
              fi
            fi

            # 5. Phục hồi Bluetooth
            if command -v bluetoothctl >/dev/null 2>&1; then
              bluetoothctl power on >/dev/null 2>&1 || true
            fi

            local bat_info
            bat_info="$(_get_battery_status)"
            echo "  🔋 $bat_info"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "✨ Đã chuyển về Chế độ Hiệu Năng (144Hz)!"

            _notify "normal" "⚡ Chế độ Hiệu Năng: ĐÃ BẬT" "Màn hình 144Hz • CPU Balanced • $bat_info"
          }

          _show_status() {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📊 TRẠNG THÁI NĂNG LƯỢNG HỆ THỐNG"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  🖥️  Tần số quét eDP-1 : $(_get_cur_hz) Hz"
            echo "  ⚙️  CPU Profile        : $(_get_cur_profile)"
            echo "  🎮 Trạng thái GPU     : $(_get_gpu_status)"
            echo "  🔋 Trạng thái Pin     : $(_get_battery_status)"
            if command -v brightnessctl >/dev/null 2>&1; then
              local cur_b max_b pct
              cur_b="$(brightnessctl g 2>/dev/null || echo 0)"
              max_b="$(brightnessctl m 2>/dev/null || echo 1)"
              pct=$(( cur_b * 100 / max_b ))
              echo "  ☀️  Độ sáng màn hình  : ''${pct}%"
            fi
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          }

          case "''${1:-}" in
            60|eco|on|save)
              _set_eco
              ;;
            144|normal|off|perf)
              _set_normal
              ;;
            status|info)
              _show_status
              ;;
            "")
              local cur_hz cur_prof
              cur_hz="$(_get_cur_hz)"
              cur_prof="$(_get_cur_profile)"
              if [[ "$cur_hz" == "144" ]] || [[ "$cur_prof" != "power-saver" ]]; then
                _set_eco
              else
                _set_normal
              fi
              ;;
            *)
              echo "Cách dùng: hz [60|144|status] hoặc eco [on|off|status]"
              echo "  - Gõ 'hz' hoặc 'eco' (không tham số): Tự động đảo chế độ (Toggle)"
              echo "  - 'hz 60' hoặc 'eco on'            : Bật siêu tiết kiệm pin (60Hz, CPU power-saver, WiFi eco, tắt đèn phím)"
              echo "  - 'hz 144' hoặc 'eco off'          : Chuyển về chế độ mượt mà (144Hz, CPU balanced)"
              echo "  - 'hz status'                      : Xem trạng thái pin, công suất (W) và GPU"
              ;;
          esac
        }

        # Xoay màn hình rời (HDMI-A-1) hoặc tự động toggle giữa ngang và dọc
        rotate-ext() {
          case "$1" in
            90)
              niri msg output HDMI-A-1 transform 90 && echo "Màn hình rời (HDMI-A-1): 90° (xoay dọc ngược chiều kim đồng hồ)"
              ;;
            0|normal)
              niri msg output HDMI-A-1 transform normal && echo "Màn hình rời (HDMI-A-1): Bình thường (ngang)"
              ;;
            270)
              niri msg output HDMI-A-1 transform 270 && echo "Màn hình rời (HDMI-A-1): 270° (xoay dọc theo chiều kim đồng hồ)"
              ;;
            180)
              niri msg output HDMI-A-1 transform 180 && echo "Màn hình rời (HDMI-A-1): 180°"
              ;;
            "")
              if niri msg outputs | grep -A 10 'HDMI-A-1' | grep -q 'Transform: normal'; then
                niri msg output HDMI-A-1 transform 90 && echo "Chuyển màn hình rời sang: Dọc (90° ngược chiều kim đồng hồ)"
              else
                niri msg output HDMI-A-1 transform normal && echo "Chuyển màn hình rời sang: Ngang (bình thường)"
              fi
              ;;
            *)
              echo "Cách dùng: rot [90|0|normal|270] (hoặc gõ 'rot' / 'xoay' không tham số để tự động toggle ngang/dọc)"
              ;;
          esac
        }
      '';
    };
  };
}
