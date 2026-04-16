#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Quietline"
BUNDLE_ID="com.quietline.app"
MIN_SYSTEM_VERSION="14.0"
APP_VERSION="0.1.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ICONSET_DIR="$DIST_DIR/AppIcon.iconset"
ICON_FILE="$APP_RESOURCES/AppIcon.icns"

SWIFT_ENV=(
  env
  "CLANG_MODULE_CACHE_PATH=/tmp/clang-module-cache"
  "SWIFTPM_ENABLE_PLUGINS=0"
  swift
)

usage() {
  echo "usage: $0 [run|--bundle|--install|--debug|--logs|--telemetry|--verify]" >&2
}

stop_app() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

build_binary() {
  mkdir -p /tmp/clang-module-cache
  "${SWIFT_ENV[@]}" build >&2
  local bin_path
  bin_path="$("${SWIFT_ENV[@]}" build --show-bin-path)"
  echo "$bin_path/$APP_NAME"
}

generate_icon() {
  mkdir -p "$APP_RESOURCES"
  rm -rf "$ICONSET_DIR"

  if "${SWIFT_ENV[@]}" "$ROOT_DIR/Scripts/GenerateAppIcon.swift" "$ICONSET_DIR" >/dev/null; then
    if /usr/bin/iconutil -c icns -o "$ICON_FILE" "$ICONSET_DIR"; then
      rm -rf "$ICONSET_DIR"
      return 0
    fi
  fi

  echo "warning: app icon generation failed; bundle will use the default macOS icon" >&2
  rm -rf "$ICONSET_DIR"
}

write_info_plist() {
  cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>Quietline</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.music</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST
}

stage_app() {
  stop_app

  local built_binary
  built_binary="$(build_binary)"

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS" "$APP_RESOURCES"
  cp "$built_binary" "$APP_BINARY"
  chmod +x "$APP_BINARY"

  generate_icon
  write_info_plist

  if command -v codesign >/dev/null 2>&1; then
    codesign --force --sign - --timestamp=none "$APP_BUNDLE" >/dev/null 2>&1 || true
  fi

  echo "$APP_BUNDLE"
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

install_app() {
  local install_dir="${INSTALL_DIR:-$HOME/Applications}"
  local installed_app="$install_dir/$APP_NAME.app"

  mkdir -p "$install_dir"
  rm -rf "$installed_app"
  cp -R "$APP_BUNDLE" "$installed_app"
  echo "$installed_app"
  /usr/bin/open -n "$installed_app"
}

case "$MODE" in
  run)
    stage_app
    open_app
    ;;
  --bundle|bundle)
    stage_app
    ;;
  --install|install)
    stage_app
    install_app
    ;;
  --debug|debug)
    stage_app
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    stage_app
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    stage_app
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    stage_app
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    echo "$APP_NAME is running"
    ;;
  *)
    usage
    exit 2
    ;;
esac
