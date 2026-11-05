#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
IOS_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
: "${SWIFTC:=swiftc}"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/tlc-ios-monitor.XXXXXXXX")
"$SWIFTC" -module-cache-path "$TMP_DIR/module-cache" "$IOS_ROOT/TikTokLiveCompanion/MonitorCore.swift" "$SCRIPT_DIR/main.swift" -o "$TMP_DIR/monitor-core-tests"
"$TMP_DIR/monitor-core-tests"
printf 'Prüfdateien: %s\n' "$TMP_DIR"
