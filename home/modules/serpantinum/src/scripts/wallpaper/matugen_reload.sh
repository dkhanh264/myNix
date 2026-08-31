#!/usr/bin/env bash

source "$SCRIPT_DIR/../caching.sh"

quickshell ipc -p "$MAIN_QML" call theme reloadColors >/dev/null 2>&1 &

killall -USR1 .kitty-wrapped

wait
