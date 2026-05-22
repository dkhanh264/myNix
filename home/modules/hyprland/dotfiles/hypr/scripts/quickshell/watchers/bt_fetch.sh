#!/usr/bin/env bash
read_bt_state() {
    local show_output connected_output status icon connected
    show_output=$(LC_ALL=C timeout 0.5 bluetoothctl show 2>/dev/null || true)
    connected_output=$(LC_ALL=C timeout 0.5 bluetoothctl devices Connected 2>/dev/null || true)

    if grep -q "Powered: yes" <<< "$show_output"; then
        status="on"
        if grep -q "^Device" <<< "$connected_output"; then
            icon="󰂱"
            connected=$(head -n1 <<< "$connected_output" | cut -d' ' -f3-)
            connected="${connected:-Disconnected}"
        else
            icon="󰂯"
            connected="Disconnected"
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
