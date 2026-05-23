#!/usr/bin/env bash
read_bt_state() {
    local status="off"
    local icon="󰂲"
    local connected="Off"

    # Kiểm tra trạng thái nguồn cực nhanh qua D-Bus bằng busctl (gần như 0% CPU)
    local powered=""
    if command -v busctl &>/dev/null; then
        powered=$(busctl get-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 Powered 2>/dev/null | awk '{print $2}')
    fi

    # Fallback dự phòng nếu busctl thất bại
    if [ -z "$powered" ]; then
        if LC_ALL=C rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
            powered="false"
        fi
    fi

    if [ "$powered" = "true" ]; then
        status="on"
        icon="󰂯"
        connected="Disconnected"

        # CHỈ gọi bluetoothctl khi chắc chắn Bluetooth đang BẬT
        local connected_output
        connected_output=$(LC_ALL=C timeout 0.2 bluetoothctl devices Connected 2>/dev/null || true)
        if grep -q "^Device" <<< "$connected_output"; then
            icon="󰂱"
            connected=$(head -n1 <<< "$connected_output" | cut -d' ' -f3-)
            connected="${connected:-Disconnected}"
        fi
    else
        status="off"
        icon="󰂲"
        connected="Off"
    fi

    echo "$status|$icon|$connected"
}

toggle_bt() {
    IFS='|' read -r status _ _ <<< "$(read_bt_state)"
    if [ "$status" = "on" ]; then
        LC_ALL=C timeout 0.5 bluetoothctl power off 2>/dev/null
        notify-send -u low -i bluetooth-disabled "Bluetooth" "Disabled"
    else
        LC_ALL=C timeout 0.5 bluetoothctl power on 2>/dev/null
        notify-send -u low -i bluetooth-active "Bluetooth" "Enabled"
    fi
}

case $1 in
    --toggle) toggle_bt ;;
    *)
        IFS='|' read -r status icon connected <<< "$(read_bt_state)"
        jq -n -c --arg status "$status" --arg icon "$icon" --arg connected "$connected" '{status: $status, icon: $icon, connected: $connected}'
        ;;
esac
