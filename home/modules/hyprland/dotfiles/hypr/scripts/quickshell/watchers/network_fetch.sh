#!/usr/bin/env bash

get_wifi_strength() {
    # Đọc trực tiếp từ proc, rất nhẹ
    local signal=$(LC_ALL=C awk 'NR==3 {gsub(/\./,"",$3); print int($3 * 100 / 70)}' /proc/net/wireless 2>/dev/null)
    echo "${signal:-0}"
}

get_network_data() {
    # 1. Tìm interface đang định tuyến internet (Rất nhanh)
    local active_iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
    
    # 2. Gộp tất cả dữ liệu thiết bị vào 1 lần gọi nmcli duy nhất
    local nm_data
    nm_data=$(LC_ALL=C nmcli -t -f DEVICE,TYPE,STATE d 2>/dev/null)

    local iface_type=""
    local eth_status="Disconnected"
    local wifi_exists=false

    # Đọc dữ liệu từ biến bằng vòng lặp, không sinh tiến trình con (subshell)
    while AM_LINE= IFS=: read -r dev type state; do
        if [ "$dev" = "$active_iface" ]; then
            iface_type="$type"
        fi
        if [ "$type" = "ethernet" ] && [ "$state" = "connected" ] && [ "$dev" != "lo" ]; then
            eth_status="Connected"
        fi
        if [ "$type" = "wifi" ]; then
            wifi_exists=true
        fi
    done <<< "$nm_data"

    local status="disabled"
    local ssid=""
    local icon="󰈂"

    # Kịch bản 1: Ethernet đang cấp Internet
    if [ "$iface_type" = "ethernet" ]; then
        status="enabled"
        ssid="Ethernet"
        icon="󰈀"
        eth_status="Connected"
        
    # Kịch bản 2: Wi-Fi đang cấp Internet
    elif [ "$iface_type" = "wifi" ]; then
        status="enabled"
        
        # Thử lấy SSID bằng lệnh iw (nhẹ hơn), nếu không được mới fallback nmcli gọn
        if command -v iw &>/dev/null; then
            ssid=$(LC_ALL=C iw dev 2>/dev/null | awk '/\s+ssid/ { $1=""; sub(/^ /, ""); print; exit }')
        fi
        if [ -z "$ssid" ]; then
            ssid=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '/802-11-wireless/ {print $1; exit}')
        fi
        
        local signal=$(get_wifi_strength)
        if [ "$signal" -ge 75 ]; then icon="󰤨"
        elif [ "$signal" -ge 50 ]; then icon="󰤥"
        elif [ "$signal" -ge 25 ]; then icon="󰤢"
        else icon="󰤟"; fi
        
    # Kịch bản 3: Không có Internet
    else
        if [ "$wifi_exists" = false ]; then
            status="disabled"
            ssid=""
            icon="󰈂"
        else
            # Chỉ kiểm tra trạng thái radio khi không có mạng
            local radio=$(LC_ALL=C nmcli radio wifi 2>/dev/null)
            if [ "$radio" = "disabled" ]; then
                status="disabled"
                icon="󰤮"
            else
                status="enabled"
                icon="󰤯"
            fi
        fi
    fi

    echo "$status|$ssid|$icon|$eth_status"
}

toggle_wifi() {
    if [ "$(LC_ALL=C nmcli radio wifi 2>/dev/null)" = "enabled" ]; then
        LC_ALL=C nmcli radio wifi off
        notify-send -u low -i network-wireless-disabled "WiFi" "Disabled"
    else
        LC_ALL=C nmcli radio wifi on
        notify-send -u low -i network-wireless-enabled "WiFi" "Enabled"
    fi
}

case $1 in
    --toggle) toggle_wifi ;;
    *) 
        IFS='|' read -r status ssid icon eth <<< "$(get_network_data)"
        jq -n -c \
            --arg status "$status" \
            --arg ssid "$ssid" \
            --arg icon "$icon" \
            --arg eth "$eth" \
            '{status: $status, ssid: $ssid, icon: $icon, eth_status: $eth}' ;;
esac
