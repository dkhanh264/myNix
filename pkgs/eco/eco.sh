#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# eco / hz — Quản lý năng lượng & Siêu tiết kiệm pin cho Laptop
# ─────────────────────────────────────────────────────────────

NOTIFY_TITLE="⚡ Quản trị Năng lượng"

_notify() {
  local urgency="$1"
  local summary="$2"
  local body="$3"
  if command -v notify-send >/dev/null 2>&1 && [[ -n "${WAYLAND_DISPLAY:-${DISPLAY:-}}" ]]; then
    notify-send -u "$urgency" -a "$NOTIFY_TITLE" "$summary" "$body" 2>/dev/null || true
  fi
}

_get_cm_file() {
  local f
  for f in /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode \
           /sys/devices/platform/ideapad_acpi/conservation_mode \
           /sys/devices/pci*/*/*/*/conservation_mode; do
    if [[ -f "$f" ]]; then
      echo "$f"
      return 0
    fi
  done
  echo ""
}

_get_cur_hz() {
  local hz
  hz="$(niri msg outputs 2>/dev/null | awk '/\(current/ { match($0, /@([0-9]+)/, m); if (m[1]) print m[1] }' | head -n1)"
  echo "${hz:-60}"
}

_get_cur_profile() {
  powerprofilesctl get 2>/dev/null || echo "balanced"
}

_get_ac_status() {
  local adp="/sys/class/power_supply/ADP0"
  if [[ -f "$adp/online" ]]; then
    if [[ "$(cat "$adp/online" 2>/dev/null)" == "1" ]]; then
      echo "🔌 Cắm sạc AC (Adapter Online)"
    else
      echo "🔋 Đang dùng Pin (AC Disconnected)"
    fi
  else
    echo "Không rõ nguồn cấp"
  fi
}

_get_bypass_status() {
  local cm_file
  cm_file="$(_get_cm_file)"
  if [[ -n "$cm_file" && -f "$cm_file" ]]; then
    local val
    val="$(cat "$cm_file" 2>/dev/null || echo "unknown")"
    if [[ "$val" == "1" ]]; then
      echo "BẬT ✓ (Sạc nhánh: ngắt sạc ở ~80%, dùng nguồn adapter trực tiếp)"
    elif [[ "$val" == "0" ]]; then
      echo "TẮT (Sạc thường: nạp đầy 100%) - Gõ 'eco bypass on' để bật sạc nhánh"
    else
      echo "Không đọc được ($val)"
    fi
  else
    echo "Không hỗ trợ trên phần cứng này"
  fi
}

_get_battery_status() {
  local bat="/sys/class/power_supply/BAT0"
  if [[ -d "$bat" ]]; then
    local status capacity power_now energy_now energy_full
    status="$(cat "$bat/status" 2>/dev/null || echo "Unknown")"
    capacity="$(cat "$bat/capacity" 2>/dev/null || echo "0")"
    power_now="$(cat "$bat/power_now" 2>/dev/null || echo "0")"
    energy_now="$(cat "$bat/energy_now" 2>/dev/null || echo "0")"
    energy_full="$(cat "$bat/energy_full" 2>/dev/null || echo "0")"

    local watts="0.0 W"
    if (( power_now > 0 )); then
      watts="$(awk -v p="$power_now" 'BEGIN { printf "%.1f", p / 1000000 }') W"
    fi

    case "$status" in
      Charging)
        local rem=""
        if (( power_now > 0 && energy_full > energy_now )); then
          local mins
          mins="$(awk -v f="$energy_full" -v n="$energy_now" -v p="$power_now" 'BEGIN { printf "%.0f", ((f - n) / p) * 60 }')"
          local h=$(( mins / 60 ))
          local m=$(( mins % 60 ))
          if (( h > 0 )); then
            rem=" (đầy sau ~${h}h ${m}m)"
          else
            rem=" (đầy sau ~${m}m)"
          fi
        fi
        echo "${capacity}% [Đang sạc] • Sạc vào pin: +${watts}${rem}"
        ;;
      Discharging)
        local rem=""
        if (( power_now > 0 && energy_now > 0 )); then
          local mins
          mins="$(awk -v e="$energy_now" -v p="$power_now" 'BEGIN { printf "%.0f", (e / p) * 60 }')"
          local h=$(( mins / 60 ))
          local m=$(( mins % 60 ))
          if (( h > 0 )); then
            rem=" (còn ~${h}h ${m}m)"
          else
            rem=" (còn ~${m}m)"
          fi
        fi
        echo "${capacity}% [Đang dùng Pin] • Tiêu thụ: -${watts}${rem}"
        ;;
      "Not charging"|Full)
        local adp_on
        adp_on="$(cat /sys/class/power_supply/ADP0/online 2>/dev/null || echo "0")"
        if [[ "$adp_on" == "1" ]]; then
          echo "${capacity}% [Sạc nhánh AC trực tiếp] • Pin nghỉ: 0.0 W (Không sạc / Không xả)"
        else
          echo "${capacity}% [${status}] • 0.0 W"
        fi
        ;;
      *)
        echo "${capacity}% [${status}] • ${watts}"
        ;;
    esac
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

  # 1. Màn hình: 60Hz
  if niri msg output eDP-1 mode 1920x1080@60.001 2>/dev/null; then
    echo "  ✓ Màn hình: 60Hz"
  else
    echo "  ! Không thể đổi tần số quét màn hình (Niri không chạy?)"
  fi

  # 2. CPU: power-saver & tắt Intel Turbo Boost
  if command -v powerprofilesctl >/dev/null 2>&1; then
    powerprofilesctl set power-saver 2>/dev/null || true
  fi
  local no_turbo_file="/sys/devices/system/cpu/intel_pstate/no_turbo"
  if [[ -f "$no_turbo_file" ]]; then
    echo 1 > "$no_turbo_file" 2>/dev/null || sudo -n sh -c "echo 1 > '$no_turbo_file'" 2>/dev/null || true
  fi
  echo "  ✓ CPU: power-saver • Tắt Turbo Boost (giảm 50-70% điện năng CPU)"

  # 3. WiFi: Power save
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

  echo "  • GPU: $(_get_gpu_status)"
  local bat_info
  bat_info="$(_get_battery_status)"
  echo "  🔋 $bat_info"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✨ Đã bật Siêu Tiết Kiệm Pin thành công!"

  _notify "normal" "🔋 Chế độ Siêu Tiết Kiệm Pin: ĐÃ BẬT" "Màn hình 60Hz • CPU Power-Saver (No-Turbo) • WiFi Eco • $bat_info"
}

_set_normal() {
  echo "⚡ Đang chuyển về CHẾ ĐỘ HIỆU NĂNG (144Hz)..."

  # 1. Màn hình: 144Hz
  if niri msg output eDP-1 mode 1920x1080@144.003 2>/dev/null; then
    echo "  ✓ Màn hình: 144Hz (Mượt mà)"
  else
    echo "  ! Không thể đổi tần số quét màn hình"
  fi

  # 2. CPU: balanced & bật lại Intel Turbo Boost
  if command -v powerprofilesctl >/dev/null 2>&1; then
    powerprofilesctl set balanced 2>/dev/null || true
  fi
  local no_turbo_file="/sys/devices/system/cpu/intel_pstate/no_turbo"
  if [[ -f "$no_turbo_file" ]]; then
    echo 0 > "$no_turbo_file" 2>/dev/null || sudo -n sh -c "echo 0 > '$no_turbo_file'" 2>/dev/null || true
  fi
  echo "  ✓ CPU: balanced • Bật Turbo Boost (tối đa 4.9 GHz)"

  # 3. WiFi: High performance
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

_set_bypass() {
  local action="${1:-status}"
  local cm_file
  cm_file="$(_get_cm_file)"
  if [[ -z "$cm_file" || ! -f "$cm_file" ]]; then
    echo "❌ Phần cứng không hỗ trợ Lenovo Conservation Mode (Sạc nhánh)."
    return 1
  fi

  case "$action" in
    on|enable|1)
      if echo 1 > "$cm_file" 2>/dev/null || sudo -n sh -c "echo 1 > '$cm_file'" 2>/dev/null; then
        echo "✓ Đã BẬT Chế độ Sạc Nhánh (Lenovo Conservation Mode)"
        echo "  → Pin sẽ tự động ngắt sạc ở ~75-80% để bảo vệ tuổi thọ."
        echo "  → Toàn bộ máy chạy 100% bằng điện sạc AC (Bypass Charging)."
        _notify "normal" "🛡️ Chế độ Sạc Nhánh: ĐÃ BẬT" "Giới hạn pin ~80% • Cấp điện trực tiếp từ Adapter"
      else
        echo "⚠️  Cần quyền ghi vào file sysfs. Vui lòng chạy lệnh sau:"
        echo "   echo 1 | sudo tee $cm_file"
        return 1
      fi
      ;;
    off|disable|0)
      if echo 0 > "$cm_file" 2>/dev/null || sudo -n sh -c "echo 0 > '$cm_file'" 2>/dev/null; then
        echo "✓ Đã TẮT Chế độ Sạc Nhánh (Chế độ sạc thường)"
        echo "  → Pin sẽ được nạp đầy 100%."
        _notify "normal" "🔋 Chế độ Sạc Thường: ĐÃ BẬT" "Pin sẽ sạc đầy 100%"
      else
        echo "⚠️  Cần quyền ghi vào file sysfs. Vui lòng chạy lệnh sau:"
        echo "   echo 0 | sudo tee $cm_file"
        return 1
      fi
      ;;
    status)
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "🛡️  CHẾ ĐỘ SẠC NHÁNH (LENOVO CONSERVATION MODE)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "  Trạng thái: $(_get_bypass_status)"
      echo "  Đường dẫn : $cm_file"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      ;;
    *)
      echo "Cách dùng: eco bypass [on|off|status]"
      echo "  - 'eco bypass on' : Bật sạc nhánh (dừng sạc ở ~80%, dùng điện adapter trực tiếp)"
      echo "  - 'eco bypass off': Tắt sạc nhánh (sạc pin đầy 100%)"
      ;;
  esac
}

_set_turbo() {
  local action="${1:-status}"
  local tf="/sys/devices/system/cpu/intel_pstate/no_turbo"
  if [[ ! -f "$tf" ]]; then
    echo "❌ Hệ thống không hỗ trợ điều khiển intel_pstate Turbo Boost."
    return 1
  fi

  case "$action" in
    off|disable|1)
      if echo 1 > "$tf" 2>/dev/null || sudo -n sh -c "echo 1 > '$tf'" 2>/dev/null; then
        echo "✓ Đã TẮT Intel Turbo Boost (CPU giới hạn ở xung gốc, tiết kiệm 50-70% điện năng)"
        _notify "normal" "⚡ Intel Turbo Boost: TẮT" "Giới hạn xung nhịp mát mẻ • Tiết kiệm pin"
      else
        echo "⚠️  Cần quyền root: echo 1 | sudo tee $tf"
        return 1
      fi
      ;;
    on|enable|0)
      if echo 0 > "$tf" 2>/dev/null || sudo -n sh -c "echo 0 > '$tf'" 2>/dev/null; then
        echo "✓ Đã BẬT Intel Turbo Boost (Mở khóa xung nhịp tối đa 4.9 GHz)"
        _notify "normal" "🚀 Intel Turbo Boost: BẬT" "Hiệu năng tối đa 4.9 GHz"
      else
        echo "⚠️  Cần quyền root: echo 0 | sudo tee $tf"
        return 1
      fi
      ;;
    status)
      local val
      val="$(cat "$tf" 2>/dev/null || echo "unknown")"
      if [[ "$val" == "1" ]]; then
        echo "Intel Turbo Boost: ĐÃ TẮT ✓ (Tiết kiệm điện năng tối đa)"
      elif [[ "$val" == "0" ]]; then
        echo "Intel Turbo Boost: ĐANG BẬT (Hiệu năng cao lên tới 4.9 GHz)"
      else
        echo "Intel Turbo Boost: $val"
      fi
      ;;
    *)
      echo "Cách dùng: eco turbo [on|off|status]"
      ;;
  esac
}

_run_daemon() {
  echo "🔋 Eco Power Daemon đang chạy trong nền (tự động đảo chế độ khi cắm/rút sạc)..."
  local prev_ac=""
  while true; do
    local cur_ac
    cur_ac="$(cat /sys/class/power_supply/ADP0/online 2>/dev/null || echo "1")"
    if [[ -n "$prev_ac" && "$cur_ac" != "$prev_ac" ]]; then
      if [[ "$cur_ac" == "0" ]]; then
        _notify "normal" "🔋 Đang dùng Pin" "Tự động kích hoạt Chế độ Siêu Tiết Kiệm (60Hz • No-Turbo)"
        _set_eco
      elif [[ "$cur_ac" == "1" ]]; then
        _notify "normal" "⚡ Đã cắm nguồn AC" "Tự động kích hoạt Chế độ Hiệu Năng (144Hz • Turbo • Balanced)"
        _set_normal
      fi
    fi
    prev_ac="$cur_ac"
    sleep 3
  done
}

_show_status() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 TRẠNG THÁI NĂNG LƯỢNG HỆ THỐNG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  🔌 Nguồn cấp         : $(_get_ac_status)"
  echo "  🔋 Trạng thái Pin    : $(_get_battery_status)"
  echo "  🛡️  Sạc nhánh (Bảo vệ): $(_get_bypass_status)"
  echo "  🖥️  Tần số quét eDP-1: $(_get_cur_hz) Hz"
  local turbo_st="Bật"
  if [[ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
    if [[ "$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null)" == "1" ]]; then
      turbo_st="TẮT ✓ (Mát & Tiết kiệm điện)"
    else
      turbo_st="BẬT (Tối đa 4.9 GHz)"
    fi
  fi
  echo "  ⚙️  CPU Profile       : $(_get_cur_profile) • Turbo: $turbo_st"
  echo "  🎮 Trạng thái GPU    : $(_get_gpu_status)"
  if command -v brightnessctl >/dev/null 2>&1; then
    local cur_b max_b pct
    cur_b="$(brightnessctl g 2>/dev/null || echo 0)"
    max_b="$(brightnessctl m 2>/dev/null || echo 1)"
    pct=$(( cur_b * 100 / max_b ))
    echo "  ☀️  Độ sáng màn hình : ${pct}%"
    local kbd_b
    kbd_b="$(brightnessctl --device='platform::kbd_backlight' g 2>/dev/null || echo 0)"
    if (( kbd_b > 0 )); then
      echo "  ⌨️  Đèn bàn phím     : Bật ($kbd_b)"
    else
      echo "  ⌨️  Đèn bàn phím     : Tắt"
    fi
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

case "${1:-}" in
  60|eco|on|save)
    _set_eco
    ;;
  144|normal|off|perf)
    _set_normal
    ;;
  bypass|bp|protect)
    _set_bypass "${2:-status}"
    ;;
  turbo|tb)
    _set_turbo "${2:-status}"
    ;;
  daemon|auto|watch)
    _run_daemon
    ;;
  status|info|st)
    _show_status
    ;;
  "")
    cur_hz="$(_get_cur_hz)"
    cur_prof="$(_get_cur_profile)"
    if [[ "$cur_hz" == "144" ]] || [[ "$cur_prof" != "power-saver" ]]; then
      _set_eco
    else
      _set_normal
    fi
    ;;
  help|-h|--help)
    echo "Cách dùng:"
    echo "  • eco                 : Tự động đảo chế độ (Toggle 60Hz Eco ⇄ 144Hz Hiệu năng)"
    echo "  • eco on  / eco 60    : Bật siêu tiết kiệm pin (60Hz, CPU power-saver, Tắt Turbo Boost, WiFi eco, tắt đèn phím)"
    echo "  • eco off / eco 144   : Chuyển về hiệu năng mượt mà (144Hz, CPU balanced, Bật Turbo Boost)"
    echo "  • eco status          : Xem trạng thái nguồn điện, pin, GPU, CPU, sạc nhánh"
    echo "  • eco bypass on       : Bật chế độ sạc nhánh (ngắt sạc ở ~80%, bảo vệ pin)"
    echo "  • eco bypass off      : Tắt sạc nhánh (cho phép sạc đầy 100%)"
    echo "  • eco bypass status   : Xem trạng thái sạc nhánh"
    echo "  • eco turbo on/off    : Bật/Tắt riêng Intel Turbo Boost"
    echo "  • eco daemon          : Chạy tiến trình nền tự động chuyển chế độ khi cắm/rút sạc"
    ;;
  *)
    echo "Tham số không hợp lệ: $1"
    echo "Gõ 'eco help' để xem hướng dẫn sử dụng."
    exit 1
    ;;
esac

