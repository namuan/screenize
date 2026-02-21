#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:-}
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 2.2.1"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME=${APP_NAME:-Screenize}
RELEASE_DIR="$ROOT_DIR/release"
DMG_PATH="$RELEASE_DIR/${APP_NAME}.dmg"

if [[ -f "$ROOT_DIR/version.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/version.env"
fi

CURRENT_BUILD=${BUILD_NUMBER:-1}
NEXT_BUILD=$((CURRENT_BUILD + 1))

cat > "$ROOT_DIR/version.env" <<ENV
MARKETING_VERSION=${VERSION}
BUILD_NUMBER=${NEXT_BUILD}
ENV

echo "Building ${APP_NAME} ${VERSION} (${NEXT_BUILD})"

ARCHES="arm64 x86_64" "$ROOT_DIR/scripts/package_app.sh" release

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"
cp -R "$ROOT_DIR/${APP_NAME}.app" "$RELEASE_DIR/"

hdiutil create -volname "$APP_NAME" \
               -srcfolder "$RELEASE_DIR/${APP_NAME}.app" \
               -ov \
               -format UDZO \
               "$DMG_PATH"

echo "Created release artifact: $DMG_PATH"
