#!/bin/bash
# Lấy thông tin player và title trong một lần gọi
output=$(playerctl metadata --format '{{playerName}}|{{title}}' 2>/dev/null)

if [ -z "$output" ] || [ "$output" = "|" ]; then
    echo "󰝛  Chưa phát nhạc"
    exit 0
fi

player=$(echo "$output" | cut -d'|' -f1)
title=$(echo "$output" | cut -d'|' -f2-)

# Map tên player sang icon Nerd Font
case "$(echo "$player" | tr '[:upper:]' '[:lower:]')" in
    spotify*)                  icon="󰓇" ;;
    firefox*|librewolf*)       icon="󰈹" ;;
    chromium*|chrome*|google*) icon="󰊯" ;;
    mpv*)                      icon="󰕓" ;;
    vlc*)                      icon="󰕼" ;;
    *)                         icon="󰝛" ;;
esac

[ -z "$title" ] && echo "󰝛  Chưa phát nhạc" || echo "$icon  $title"
