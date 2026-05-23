#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"
qs_ensure_cache "weather"

export LC_ALL=C

script_dir="$(dirname "${BASH_SOURCE[0]}")"
weather_script="${script_dir}/weather.sh"
json_file="${QS_CACHE_WEATHER}/weather.json"
env_file="${script_dir}/.env"

unit="metric"
if [ -f "$env_file" ]; then
    unit_line="$(grep -m1 '^OPENWEATHER_UNIT=' "$env_file" 2>/dev/null || true)"
    if [ -n "$unit_line" ]; then
        unit="${unit_line#OPENWEATHER_UNIT=}"
    fi
fi

case "$unit" in
    imperial) unit_sym="°F" ;;
    standard) unit_sym="K" ;;
    *) unit_sym="°C" ;;
esac

"$weather_script" --current-icon >/dev/null 2>&1 || true

if [ ! -f "$json_file" ]; then
    jq -n -c --arg icon "" --arg temp "--${unit_sym}" --arg hex "#cdd6f4" \
        '{icon: $icon, temp: $temp, hex: $hex}'
    exit 0
fi

jq -c --arg unitSym "$unit_sym" \
    '{icon: (.current_icon // ""), temp: ((.current_temp // "--" | tostring) + $unitSym), hex: (.current_hex // "#cdd6f4")}' \
    "$json_file" 2>/dev/null \
    || jq -n -c --arg icon "" --arg temp "--${unit_sym}" --arg hex "#cdd6f4" '{icon: $icon, temp: $temp, hex: $hex}'
