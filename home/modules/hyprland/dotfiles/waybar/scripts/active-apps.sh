#!/bin/bash
# Lấy ID workspace hiện tại
workspace=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')

if [ -z "$workspace" ] || [ "$workspace" = "null" ]; then
    exit 0
fi

# Lấy các class window đang mở trong workspace hiện tại (loại bỏ trùng)
mapfile -t classes < <(hyprctl clients -j 2>/dev/null \
    | jq -r ".[] | select(.workspace.id == $workspace) | .class" \
    | sort -u)

icons=""
for class in "${classes[@]}"; do
    lower=$(echo "$class" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
        firefox*|librewolf*)        icon="󰈹" ;;
        chromium*|chrome*|google*)  icon="󰊯" ;;
        code*|vscodium*|vscodiym*)  icon="󰨞" ;;
        kitty*|alacritty*|foot*|wezterm*) icon="" ;;
        spotify*)                   icon="󰓇" ;;
        discord*)                   icon="󰙯" ;;
        telegram*)                  icon="" ;;
        thunar*|nautilus*|dolphin*|nemo*) icon="󰉋" ;;
        mpv*)                       icon="󰕓" ;;
        vlc*)                       icon="󰕼" ;;
        obs*)                       icon="󰑋" ;;
        gimp*)                      icon="󰐇" ;;
        inkscape*)                  icon="󰠠" ;;
        libreoffice*)               icon="󰈙" ;;
        steam*)                     icon="󰓓" ;;
        *)                          icon="" ;;
    esac
    [ -n "$icons" ] && icons="$icons $icon" || icons="$icon"
done

echo "$icons"
