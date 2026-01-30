# Installation Guide

This guide explains how to build and install Screenize locally on your Mac.

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later

## Build and Install

1. **Clone the repository** (if you haven't already):
   ```bash
   git clone https://github.com/syi0808/screenize.git
   cd screenize
   ```

2. **Build the application**:
   ```bash
   xcodebuild -project Screenize.xcodeproj \
              -scheme Screenize \
              -configuration Release \
              -derivedDataPath ./build \
              clean build
   ```

3. **Install to ~/Applications**:
   ```bash
   cp -R ./build/Build/Products/Release/Screenize.app ~/Applications/
   ```

4. **Launch the application**:
   ```bash
   open ~/Applications/Screenize.app
   ```

## First Launch

On first launch, Screenize will request the following permissions:

1. **Screen Recording** — Required to capture your screen
2. **Microphone** — Required for audio recording
3. **Accessibility** — Required for UI element detection and smart zoom

Grant each permission when prompted, or enable them manually under **System Settings > Privacy & Security**.

## macOS Gatekeeper Warning

Since this is a locally built app without Apple notarization, macOS may display a security warning when you first open it. To open the app:

1. Right-click (or Control-click) the Screenize app in ~/Applications
2. Select **Open** from the context menu
3. Click **Open** in the dialog that appears

Alternatively, go to **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to the Screenize message.

You only need to do this once — macOS will remember your choice for future launches.

## Updating

To update to the latest version, pull the latest changes and rebuild:

```bash
cd screenize
git pull origin main
xcodebuild -project Screenize.xcodeproj \
           -scheme Screenize \
           -configuration Release \
           -derivedDataPath ./build \
           clean build
cp -R ./build/Build/Products/Release/Screenize.app ~/Applications/
```

## Uninstalling

To remove Screenize from your system:

```bash
rm -rf ~/Applications/Screenize.app
```

## Troubleshooting

### Permission Issues

If permissions get stuck during development, reset them with:

```bash
tccutil reset ScreenCapture com.screenize.Screenize
tccutil reset Microphone com.screenize.Screenize
```

### Build Errors

If you encounter build errors:

1. Ensure you have the latest version of Xcode installed
2. Clean the build directory: `rm -rf ./build`
3. Try building again

For more information, see [CONTRIBUTING.md](CONTRIBUTING.md).
