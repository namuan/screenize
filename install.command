#!/bin/bash

xcodebuild -project Screenize.xcodeproj \
           -scheme Screenize \
           -configuration Release \
           -derivedDataPath ./build \
           clean build
cp -R ./build/Build/Products/Release/Screenize.app ~/Applications/
rm -rf ./build
