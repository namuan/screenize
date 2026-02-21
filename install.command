#!/usr/bin/env bash
set -euo pipefail

OPEN_APP=false
DEBUG_BUILD=false
APP_BUNDLE_ID="com.screenize.Screenize"

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

"$(dirname "$0")/scripts/package_app.sh" "$CONFIG"
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/Screenize.app"
cp -R "$(dirname "$0")/Screenize.app" "$HOME/Applications/Screenize.app"

echo "Installed Screenize.app to ~/Applications"

if [ "$OPEN_APP" = true ]; then
    open "$HOME/Applications/Screenize.app"
fi
