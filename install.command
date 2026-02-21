#!/usr/bin/env bash
set -euo pipefail

OPEN_APP=false
DEBUG_BUILD=false
APP_BUNDLE_ID="com.screenize.Screenize"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
ASSETS_ICON="$ROOT_DIR/assets/icon.png"
ICONSET_DIR="$ROOT_DIR/tmp_iconset.iconset"
ICON_ICNS="$ROOT_DIR/Icon.icns"

generate_icon() {
    if [[ ! -f "$ASSETS_ICON" ]]; then
        echo "Warning: No icon found at $ASSETS_ICON, using default"
        return 1
    fi

    echo "Generating Icon.icns from $ASSETS_ICON..."

    mkdir -p "$ICONSET_DIR"

    sips -z 16 16 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
    sips -z 32 32 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
    sips -z 32 32 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
    sips -z 64 64 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
    sips -z 128 128 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
    sips -z 256 256 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
    sips -z 256 256 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
    sips -z 512 512 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
    sips -z 512 512 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
    sips -z 1024 1024 "$ASSETS_ICON" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

    iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS"
    rm -rf "$ICONSET_DIR"

    echo "Created $ICON_ICNS"
}

generate_icon

while [[ $# -gt 0 ]]; do
    case $1 in
        -open|--open)
            OPEN_APP=true
            shift
            ;;
        -d|--debug)
            DEBUG_BUILD=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--open] [--debug]"
            exit 1
            ;;
    esac
done

echo "Resetting macOS privacy permissions for ${APP_BUNDLE_ID}..."
tccutil reset All "${APP_BUNDLE_ID}" || true

if [ "$DEBUG_BUILD" = true ]; then
    CONFIG="debug"
else
    CONFIG="release"
fi

"$SCRIPT_DIR/scripts/package_app.sh" "$CONFIG"
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/Screenize.app"
cp -R "$SCRIPT_DIR/Screenize.app" "$HOME/Applications/Screenize.app"

echo "Installed Screenize.app to ~/Applications"

if [ "$OPEN_APP" = true ]; then
    open "$HOME/Applications/Screenize.app"
fi
