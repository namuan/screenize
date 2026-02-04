#!/bin/bash
set -e

# ============================================
# Screenize release script
# Usage: ./scripts/release.sh 2.1
# ============================================

VERSION=$1
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/release"
APP_NAME="Screenize"
DMG_NAME="${APP_NAME}.dmg"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${GREEN}==>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Version check
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 2.1"
    exit 1
fi

echo ""
echo "============================================"
echo "  Screenize v${VERSION} release build"
echo "============================================"
echo ""

# Clean build directories
print_step "Cleaning build directories..."
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Update version in Info.plist
print_step "Updating Info.plist version to ${VERSION}..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "$PROJECT_DIR/Screenize/Info.plist"

# Increment build number (CFBundleVersion)
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PROJECT_DIR/Screenize/Info.plist")
NEW_BUILD=$((CURRENT_BUILD + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" "$PROJECT_DIR/Screenize/Info.plist"
print_step "Build number: ${CURRENT_BUILD} -> ${NEW_BUILD}"

# Release build
print_step "Performing Release build..."
xcodebuild -project "$PROJECT_DIR/Screenize.xcodeproj" \
           -scheme Screenize \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           clean build

APP_PATH="$BUILD_DIR/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    print_error "Build failed: $APP_PATH not found"
    exit 1
fi

print_step "Build completed: $APP_PATH"

# Notarization (optional)
# Requires Apple Developer Program membership
# Uncomment below to use
# print_step "Notarizing..."
# xcrun notarytool submit "$APP_PATH" \
#     --apple-id "$APPLE_ID" \
#     --password "$APPLE_APP_PASSWORD" \
#     --team-id "PDRAQZHYD3" \
#     --wait
# xcrun stapler staple "$APP_PATH"

# Create DMG
print_step "Creating DMG..."
DMG_PATH="$RELEASE_DIR/$DMG_NAME"
TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"

mkdir -p "$TEMP_DMG_DIR"
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"

# Add Applications symlink
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Create DMG image
hdiutil create -volname "$APP_NAME" \
               -srcfolder "$TEMP_DMG_DIR" \
               -ov \
               -format UDZO \
               "$DMG_PATH"

rm -rf "$TEMP_DMG_DIR"

print_step "DMG created: $DMG_PATH"

# Summary
echo ""
echo "============================================"
echo "  Release build complete!"
echo "============================================"
echo ""
echo "Generated files:"
echo "  - DMG: $DMG_PATH"
echo ""
echo "Next steps:"
echo "  1. Create a GitHub Release (tag: v${VERSION})"
echo "  2. Upload ${DMG_NAME}"
echo "  3. Commit version changes:"
echo "     git add Screenize/Info.plist"
echo "     git commit -m 'Bump version to v${VERSION}'"
echo "     git push origin main"
echo ""
