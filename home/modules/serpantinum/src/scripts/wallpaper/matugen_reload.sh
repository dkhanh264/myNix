#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../caching.sh"

quickshell ipc -p "$MAIN_QML" call theme reloadColors >/dev/null 2>&1 &

killall -USR1 .kitty-wrapped 2>/dev/null || pkill -SIGUSR1 kitty 2>/dev/null || true

wait

