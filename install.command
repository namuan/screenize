#!/bin/bash

OPEN_APP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -open|--open)
            OPEN_APP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--open]"
            exit 1
            ;;
    esac
done

xcodebuild -project Screenize.xcodeproj \
           -scheme Screenize \
           -configuration Release \
           -derivedDataPath ./build \
           clean build
cp -R ./build/Build/Products/Release/Screenize.app ~/Applications/
rm -rf ./build

# Open the application if -open flag was specified
if [ "$OPEN_APP" = true ]; then
    echo "Opening Screenize.app..."
    open ~/Applications/Screenize.app
fi
