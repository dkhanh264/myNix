{ pkgs, ... }:
let
  waybarMusic = pkgs.writeShellScriptBin "waybar-music" ''
      
      create_placeholder() {
        echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=" | ${pkgs.coreutils}/bin/base64 -d > /tmp/music_cover.png 2>/dev/null
      }
  
      round_cover() {
        local input="/tmp/music_cover.png"
        local tmp="/tmp/music_cover_rounded.png"
        local radius="$ROUND_RADIUS"
        local dims
  
        [ -s "$input" ] || return 0
  
        dims=$(${pkgs.imagemagick}/bin/identify -format "%w %h" "$input" 2>/dev/null || true)
        [ -n "$dims" ] || return 0
  
        local w h
        read -r w h <<< "$dims"
        [ -n "$w" ] && [ -n "$h" ] || return 0
  
        ${pkgs.imagemagick}/bin/convert "$input" \
          \( -size "''${w}x''${h}" xc:none \
          -fill white \
          -draw "roundrectangle 0,0,$((w-1)),$((h-1)),100,100" \) \
          -alpha off \
          -compose CopyOpacity \
          -composite \
          "$tmp"
      }
  
      LAST_CHECK=0
      TEXT=""
      OLD_TEXT=""
      OFFSET=0
      MAX_LEN=15
      ROUND_RADIUS=100
  
      while true; do
        CURRENT_TIME=$(date +%s)
        
        # Cứ sau 2 giây mới check trạng thái playerctl một lần để tránh tốn CPU
        if [ $((CURRENT_TIME - LAST_CHECK)) -ge 2 ] || [ -z "$TEXT" ]; then
          LAST_CHECK=$CURRENT_TIME
          status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)
          
          if [ -z "$status" ]; then
            TEXT="Không có nhạc"
            OLD_TEXT=""
            create_placeholder
            echo "" > /tmp/music_last_art 2>/dev/null
          else
            new_text=$(${pkgs.playerctl}/bin/playerctl metadata --format '{{ title }} - {{ artist }}' 2>/dev/null)
            if [ -z "$new_text" ]; then
              TEXT="Không có nhạc"
              OLD_TEXT=""
              create_placeholder
              echo "" > /tmp/music_last_art 2>/dev/null
            elif [ "$new_text" != "$OLD_TEXT" ]; then
              OLD_TEXT="$new_text"
              # Thêm khoảng cách ngăn cách khi lặp chữ
              TEXT="$new_text   |   "
              OFFSET=0
              
              # Tải ảnh Album Art (chỉ tải khi đổi bài hát mới)
              art_url=$(${pkgs.playerctl}/bin/playerctl metadata mpris:artUrl 2>/dev/null)
              if [ -n "$art_url" ]; then
                last_art=$(cat /tmp/music_last_art 2>/dev/null)
                if [ "$art_url" != "$last_art" ]; then
                  echo "$art_url" > /tmp/music_last_art
                  if [[ "$art_url" == file://* ]]; then
                    cp "''${art_url##file://}" /tmp/music_cover.png 2>/dev/null
                    round_cover
                  elif [[ "$art_url" == http* ]]; then
                    ${pkgs.curl}/bin/curl -s "$art_url" -o /tmp/music_cover_tmp.png \
                      && mv /tmp/music_cover_tmp.png /tmp/music_cover.png \
                      && round_cover &
                  fi
                fi
              else
                create_placeholder
                echo "" > /tmp/music_last_art 2>/dev/null
              fi
            fi
          fi
        fi
  
        # Xử lý dịch chuyển ký tự từng chút một
        if [ "$TEXT" = "Không có nhạc" ]; then
          echo "Không có nhạc"
        else
          clean_text="''${TEXT%   |   }"
          if [ "''${#clean_text}" -le "$MAX_LEN" ]; then
            echo "$clean_text"
          else
            LEN=''${#TEXT}
            SCROLLED="''${TEXT:OFFSET}''${TEXT:0:OFFSET}"
            echo "''${SCROLLED:0:MAX_LEN}"
            OFFSET=$(( (OFFSET + 1) % LEN ))
          fi
        fi
  
        sleep 0.25 # Khoảng thời gian dịch chữ (0.25 giây giúp chữ trượt cực kỳ mượt mà)
      done
    '';

in
{
  home.packages = [ waybarMusic ];
}
