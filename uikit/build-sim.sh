#!/usr/bin/env bash
# Builds DuoTabBarRepro.app for the simulator with swiftc alone (no Xcode project).
set -euo pipefail
cd "$(dirname "$0")"
APP=build/DuoTabBarRepro.app
rm -rf build && mkdir -p "$APP"
xcrun -sdk iphonesimulator swiftc -parse-as-library -O \
  -target arm64-apple-ios26.0-simulator \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  main.swift -o "$APP/DuoTabBarRepro"
cp Info.plist "$APP/Info.plist"
codesign --force --sign - "$APP" >/dev/null
echo "$APP"
