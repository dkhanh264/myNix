#!/usr/bin/env bash

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/caching.sh"
quickshell ipc -p "$MAIN_QML" call main forceReload
