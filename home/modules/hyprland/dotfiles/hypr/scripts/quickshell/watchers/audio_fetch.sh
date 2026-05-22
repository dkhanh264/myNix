#!/usr/bin/env bash

get_volume_and_mute() {
    local vol="0"
    local muted="false"

    if command -v wpctl &> /dev/null; then
        local line
        line=$(LC_ALL=C wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
        if [ -n "$line" ]; then
            vol=$(awk '{print int($2*100)}' <<< "$line")
            if grep -q "MUTED" <<< "$line"; then muted="true"; fi
        fi
    elif command -v pamixer &> /dev/null; then
        vol=$(LC_ALL=C pamixer --get-volume 2>/dev/null || echo "0")
        if LC_ALL=C pamixer --get-mute 2>/dev/null | grep -q "true"; then muted="true"; fi
    fi

    echo "${vol:-0}|$muted"
}

get_volume_icon() {
    local vol="$1"
    local muted="$2"
    if [ "$muted" = "true" ]; then echo "󰝟"
    elif [ "$vol" -ge 70 ]; then echo "󰕾"
    elif [ "$vol" -ge 30 ]; then echo "󰖀"
    elif [ "$vol" -gt 0 ]; then echo "󰕿"
    else echo "󰝟"; fi
}

toggle_mute() {
    if command -v wpctl &> /dev/null; then
        LC_ALL=C wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    elif command -v pamixer &> /dev/null; then
        LC_ALL=C pamixer --toggle-mute 2>/dev/null
    fi
    IFS='|' read -r vol muted <<< "$(get_volume_and_mute)"
    if [ "$muted" = "true" ]; then notify-send -u low -i audio-volume-muted "Volume" "Muted"
    else notify-send -u low -i audio-volume-high "Volume" "Unmuted (${vol:-0}%)"; fi
}

case $1 in
    --toggle) toggle_mute ;;
    *)
        IFS='|' read -r vol muted <<< "$(get_volume_and_mute)"
        jq -n -c \
            --arg volume "${vol:-0}" \
            --arg icon "$(get_volume_icon "${vol:-0}" "$muted")" \
            --arg is_muted "$muted" \
            '{volume: $volume, icon: $icon, is_muted: $is_muted}'
        ;;
esac
