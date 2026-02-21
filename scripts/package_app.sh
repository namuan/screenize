#!/usr/bin/env bash
set -euo pipefail

CONF=${1:-release}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME=${APP_NAME:-Screenize}
BUNDLE_ID=${BUNDLE_ID:-com.screenize.Screenize}
MACOS_MIN_VERSION=${MACOS_MIN_VERSION:-13.0}
APP_CATEGORY=${APP_CATEGORY:-public.app-category.video}
APP_COPYRIGHT=${APP_COPYRIGHT:-Copyright (c) 2024. All rights reserved.}
APP_BUNDLE="$ROOT_DIR/${APP_NAME}.app"
DIST_DIR="$ROOT_DIR/dist"

if [[ -f "$ROOT_DIR/version.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/version.env"
else
  MARKETING_VERSION=${MARKETING_VERSION:-0.1.0}
  BUILD_NUMBER=${BUILD_NUMBER:-1}
fi

ARCH_LIST=( ${ARCHES:-} )
if [[ ${#ARCH_LIST[@]} -eq 0 ]]; then
  ARCH_LIST=("$(uname -m)")
fi

for arch in "${ARCH_LIST[@]}"; do
  swift build -c "$CONF" --arch "$arch"
done

rm -rf "$APP_BUNDLE" "$DIST_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$APP_BUNDLE/Contents/Frameworks" "$DIST_DIR"

build_product_path() {
  local name="$1"
  local arch="$2"

  if [[ -f ".build/${arch}-apple-macosx/${CONF}/${name}" ]]; then
    echo ".build/${arch}-apple-macosx/${CONF}/${name}"
  elif [[ -f ".build/${CONF}/${name}" ]]; then
    echo ".build/${CONF}/${name}"
  else
    return 1
  fi
}

install_binary() {
  local name="$1"
  local dest="$2"
  local binaries=()

  for arch in "${ARCH_LIST[@]}"; do
    local src
    src="$(build_product_path "$name" "$arch")"
    binaries+=("$src")
  done

  if [[ ${#binaries[@]} -gt 1 ]]; then
    lipo -create "${binaries[@]}" -output "$dest"
  else
    cp "${binaries[0]}" "$dest"
  fi

  chmod +x "$dest"
}

install_binary "$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleExecutable</key><string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${MARKETING_VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>LSApplicationCategoryType</key><string>${APP_CATEGORY}</string>
    <key>LSMinimumSystemVersion</key><string>${MACOS_MIN_VERSION}</string>
    <key>NSAccessibilityUsageDescription</key><string>Accessibility permission is required for the dynamic zoom targeting clicked UI elements.</string>
    <key>NSInputMonitoringUsageDescription</key><string>Input monitoring permission is required to capture keyboard and mouse activity.</string>
    <key>NSMicrophoneUsageDescription</key><string>Microphone access is required to capture audio.</string>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSScreenCaptureUsageDescription</key><string>Screen recording permission is required to capture the display.</string>
    <key>NSHumanReadableCopyright</key><string>${APP_COPYRIGHT}</string>
</dict>
</plist>
PLIST

if [[ -f "$ROOT_DIR/Icon.icns" ]]; then
  cp "$ROOT_DIR/Icon.icns" "$APP_BUNDLE/Contents/Resources/Icon.icns"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string Icon" "$APP_BUNDLE/Contents/Info.plist" || true
fi

copy_resource_bundles() {
  local source_dir="$1"
  shopt -s nullglob
  local bundles=("$source_dir"/*.bundle)
  shopt -u nullglob

  if [[ ${#bundles[@]} -gt 0 ]]; then
    for bundle in "${bundles[@]}"; do
      cp -R "$bundle" "$APP_BUNDLE/Contents/Resources/"
    done
  fi
}

for arch in "${ARCH_LIST[@]}"; do
  if [[ -d ".build/${arch}-apple-macosx/${CONF}" ]]; then
    copy_resource_bundles ".build/${arch}-apple-macosx/${CONF}"
  fi
done
if [[ -d ".build/${CONF}" ]]; then
  copy_resource_bundles ".build/${CONF}"
fi

xattr -cr "$APP_BUNDLE" || true
find "$APP_BUNDLE" -name '._*' -delete

APP_ENTITLEMENTS=${APP_ENTITLEMENTS:-$ROOT_DIR/Screenize/Screenize.entitlements}
if [[ ! -f "$APP_ENTITLEMENTS" ]]; then
  APP_ENTITLEMENTS=""
fi

if [[ -n "${APP_IDENTITY:-}" ]]; then
  CODESIGN_ARGS=(--force --timestamp --options runtime --sign "$APP_IDENTITY")
else
  CODESIGN_ARGS=(--force --sign "-")
fi

if [[ -n "$APP_ENTITLEMENTS" ]]; then
  codesign "${CODESIGN_ARGS[@]}" --entitlements "$APP_ENTITLEMENTS" "$APP_BUNDLE"
else
  codesign "${CODESIGN_ARGS[@]}" "$APP_BUNDLE"
fi

cp -R "$APP_BUNDLE" "$DIST_DIR/"

echo "Created $APP_BUNDLE"
echo "Copied app to $DIST_DIR/${APP_NAME}.app"
