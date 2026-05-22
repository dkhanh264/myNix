#!/usr/bin/env bash
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

quickshell -p "$SCRIPT_DIR/quickshell/Shell.qml" ipc call main forceReload
