#!/bin/bash

OPEN_APP=false
DEBUG_BUILD=false

# Parse command line arguments
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

# Determine build configuration
if [ "$DEBUG_BUILD" = true ]; then
    BUILD_CONFIG="Debug"
    BUILD_DIR="Debug"
    echo "Building DEBUG configuration..."
else
    BUILD_CONFIG="Release"
    BUILD_DIR="Release"
    echo "Building RELEASE configuration..."
fi

xcodebuild -project Screenize.xcodeproj \
           -scheme Screenize \
           -configuration "$BUILD_CONFIG" \
           -derivedDataPath ./build \
           clean build
cp -R ./build/Build/Products/"$BUILD_DIR"/Screenize.app ~/Applications/
rm -rf ./build

# Open the application if -open flag was specified
if [ "$OPEN_APP" = true ]; then
    echo "Opening Screenize.app..."
    open ~/Applications/Screenize.app
fi
