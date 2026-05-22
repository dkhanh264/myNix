#!/usr/bin/env bash

# Xác định thư mục động chứa chính file script này
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

source "$SCRIPT_DIR/caching.sh"
qs_ensure_cache "lock"

# Khởi chạy giao diện Lock screen bằng đường dẫn động
quickshell -p "$SCRIPT_DIR/quickshell/Lock.qml"
