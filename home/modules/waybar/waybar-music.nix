{ pkgs, ... }:
let
  waybarMusic = pkgs.writeShellApplication {
    name = "waybar-music";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      imagemagick
      playerctl
    ];
    text = ''
      umask 077

      readonly max_length=15
      readonly scroll_delay=0.25
      readonly poll_ticks=8
      readonly max_art_bytes=10485760
      readonly placeholder_png="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="

      user_id="$(id -u)"
      if [[ -n "''${XDG_RUNTIME_DIR:-}" ]]; then
        state_dir="$XDG_RUNTIME_DIR/waybar-music"
      else
        state_dir="/tmp/waybar-music-$user_id"
      fi

      mkdir -p -- "$state_dir"
      if [[ "$(stat -c '%u' -- "$state_dir")" != "$user_id" ]]; then
        printf 'waybar-music: refusing state directory not owned by this user: %s\n' "$state_dir" >&2
        exit 1
      fi
      chmod 0700 -- "$state_dir"

      readonly cover_file="$state_dir/music_cover.png"
      readonly rounded_cover_file="$state_dir/music_cover_rounded.png"
      readonly last_art_file="$state_dir/last_art"
      readonly desired_art_file="$state_dir/desired_art"
      readonly legacy_cover="/tmp/music_cover.png"
      readonly legacy_rounded_cover="/tmp/music_cover_rounded.png"

      state_tmp=""
      legacy_link_tmp=""
      art_job_pid=""
      art_job_download=""
      art_job_rounded=""

      replace_if_changed() {
        local source_file="$1"
        local destination_file="$2"

        if [[ -f "$destination_file" ]] && cmp -s -- "$source_file" "$destination_file"; then
          rm -f -- "$source_file"
        else
          chmod 0600 -- "$source_file"
          mv -f -- "$source_file" "$destination_file"
        fi
      }

      write_value_if_changed() {
        local destination_file="$1"
        local value="$2"

        state_tmp="$(mktemp "$state_dir/.state.XXXXXX")"
        printf '%s\n' "$value" > "$state_tmp"
        replace_if_changed "$state_tmp" "$destination_file"
        state_tmp=""
      }

      publish_legacy_link() {
        local source_file="$1"
        local destination_file="$2"
        local destination_owner=""

        if [[ -L "$destination_file" ]] && [[ "$(readlink -- "$destination_file")" == "$source_file" ]]; then
          return 0
        fi

        # /tmp is shared. Never replace a path owned by another user.
        if [[ -e "$destination_file" || -L "$destination_file" ]]; then
          destination_owner="$(stat -c '%u' -- "$destination_file" 2>/dev/null || true)"
          if [[ "$destination_owner" != "$user_id" ]]; then
            return 0
          fi
        fi

        legacy_link_tmp="$(mktemp "/tmp/.waybar-music-$user_id.XXXXXX")"
        rm -f -- "$legacy_link_tmp"
        if ! ln -s -- "$source_file" "$legacy_link_tmp"; then
          legacy_link_tmp=""
          return 0
        fi
        if ! mv -Tf -- "$legacy_link_tmp" "$destination_file"; then
          rm -f -- "$legacy_link_tmp"
        fi
        legacy_link_tmp=""
      }

      publish_covers() {
        publish_legacy_link "$cover_file" "$legacy_cover"
        publish_legacy_link "$rounded_cover_file" "$legacy_rounded_cover"
      }

      create_placeholder() {
        local placeholder_tmp
        local rounded_placeholder_tmp

        placeholder_tmp="$(mktemp "$state_dir/.placeholder.XXXXXX")"
        printf '%s' "$placeholder_png" | base64 --decode > "$placeholder_tmp"
        replace_if_changed "$placeholder_tmp" "$cover_file"

        rounded_placeholder_tmp="$(mktemp "$state_dir/.placeholder-rounded.XXXXXX")"
        cp -- "$cover_file" "$rounded_placeholder_tmp"
        replace_if_changed "$rounded_placeholder_tmp" "$rounded_cover_file"

        write_value_if_changed "$last_art_file" ""
        publish_covers
      }

      read_first_line() {
        local source_file="$1"
        local value=""

        if [[ -f "$source_file" ]]; then
          IFS= read -r value < "$source_file" || true
        fi
        printf '%s' "$value"
      }

      fetch_art() {
        local art_url="$1"
        local download_file="$2"
        local rounded_file="$3"
        local dimensions=""
        local width=""
        local height=""
        local radius=1
        local current_request=""
        local file_size=0

        # The URL comes from MPRIS. Keep the accepted protocol set explicit and
        # prevent HTTP redirects from escaping to a local file URL.
        if ! curl \
          --fail \
          --silent \
          --show-error \
          --location \
          --connect-timeout 3 \
          --max-time 10 \
          --max-filesize "$max_art_bytes" \
          --proto '=file,http,https' \
          --proto-redir '=http,https' \
          --output "$download_file" \
          -- "$art_url"; then
          return 1
        fi

        file_size="$(stat -c '%s' -- "$download_file" 2>/dev/null || printf '0')"
        if [[ ! "$file_size" =~ ^[0-9]+$ ]] || (( file_size == 0 || file_size > max_art_bytes )); then
          return 1
        fi

        if ! dimensions="$(identify -ping -format '%w %h' "$download_file" 2>/dev/null)"; then
          return 1
        fi
        read -r width height <<< "$dimensions"
        if [[ ! "$width" =~ ^[0-9]+$ || ! "$height" =~ ^[0-9]+$ ]]; then
          return 1
        fi
        if (( width == 0 || height == 0 || width > 8192 || height > 8192 )); then
          return 1
        fi

        radius=$(( (width < height ? width : height) / 5 ))
        (( radius > 0 )) || radius=1

        export MAGICK_MEMORY_LIMIT=64MiB
        export MAGICK_MAP_LIMIT=128MiB
        export MAGICK_DISK_LIMIT=256MiB
        export MAGICK_TIME_LIMIT=10
        if ! convert "$download_file" \
          \( -size "''${width}x''${height}" xc:none \
             -fill white \
             -draw "roundrectangle 0,0,$((width - 1)),$((height - 1)),''${radius},''${radius}" \) \
          -alpha off \
          -compose CopyOpacity \
          -composite \
          "png:$rounded_file"; then
          return 1
        fi

        current_request="$(read_first_line "$desired_art_file")"
        if [[ "$current_request" != "$art_url" ]]; then
          return 0
        fi

        replace_if_changed "$download_file" "$cover_file"
        replace_if_changed "$rounded_file" "$rounded_cover_file"
        write_value_if_changed "$last_art_file" "$art_url"
        publish_covers
      }

      reap_art_job() {
        if [[ -n "$art_job_pid" ]] && ! kill -0 "$art_job_pid" 2>/dev/null; then
          wait "$art_job_pid" 2>/dev/null || true
          rm -f -- "$art_job_download" "$art_job_rounded"
          art_job_pid=""
          art_job_download=""
          art_job_rounded=""
        fi
      }

      cancel_art_job() {
        if [[ -n "$art_job_pid" ]]; then
          if kill -0 "$art_job_pid" 2>/dev/null; then
            kill "$art_job_pid" 2>/dev/null || true
          fi
          wait "$art_job_pid" 2>/dev/null || true
        fi
        rm -f -- "$art_job_download" "$art_job_rounded"
        art_job_pid=""
        art_job_download=""
        art_job_rounded=""
      }

      desired_art=""
      request_art() {
        local art_url="$1"

        if [[ "$art_url" == "$desired_art" && -s "$cover_file" && -s "$rounded_cover_file" ]]; then
          return 0
        fi

        cancel_art_job
        desired_art="$art_url"
        write_value_if_changed "$desired_art_file" "$desired_art"

        if [[ -z "$desired_art" ]]; then
          create_placeholder
          return 0
        fi

        # Do not show the previous track's cover while the new one is fetched.
        create_placeholder
        art_job_download="$(mktemp "$state_dir/.download.XXXXXX")"
        art_job_rounded="$(mktemp --tmpdir="$state_dir" --suffix=.png '.rounded.XXXXXX')"
        (
          trap - EXIT HUP INT TERM
          fetch_art "$desired_art" "$art_job_download" "$art_job_rounded"
        ) >/dev/null 2>&1 &
        art_job_pid="$!"
      }

      cleanup() {
        cancel_art_job
        rm -f -- "$state_tmp" "$legacy_link_tmp"
      }
      trap cleanup EXIT
      trap 'exit 0' HUP INT TERM

      if [[ -s "$cover_file" && -s "$rounded_cover_file" ]]; then
        desired_art="$(read_first_line "$last_art_file")"
        write_value_if_changed "$desired_art_file" "$desired_art"
        publish_covers
      else
        desired_art=""
        write_value_if_changed "$desired_art_file" ""
        create_placeholder
      fi

      current_track=""
      scroll_text=""
      offset=0
      ticks_until_poll=0

      while true; do
        reap_art_job

        if (( ticks_until_poll == 0 )); then
          if new_track="$(playerctl metadata --format '{{ title }} - {{ artist }}' 2>/dev/null)" \
            && [[ -n "$new_track" ]]; then
            if [[ "$new_track" != "$current_track" ]]; then
              current_track="$new_track"
              scroll_text="$new_track   |   "
              offset=0
              art_url="$(playerctl metadata mpris:artUrl 2>/dev/null || true)"
              request_art "$art_url"
            fi
          else
            if [[ -n "$current_track" || -n "$desired_art" ]]; then
              current_track=""
              scroll_text=""
              offset=0
              request_art ""
            fi
          fi
          ticks_until_poll=$poll_ticks
        fi

        if [[ -z "$current_track" ]]; then
          printf 'Không có nhạc\n'
        else
          clean_text="''${scroll_text%   |   }"
          if (( ''${#clean_text} <= max_length )); then
            printf '%s\n' "$clean_text"
          else
            text_length="''${#scroll_text}"
            scrolled_text="''${scroll_text:offset}''${scroll_text:0:offset}"
            printf '%s\n' "''${scrolled_text:0:max_length}"
            offset=$(( (offset + 1) % text_length ))
          fi
        fi

        sleep "$scroll_delay"
        ticks_until_poll=$((ticks_until_poll - 1))
      done
    '';
  };
in
{
  home.packages = [ waybarMusic ];
}
