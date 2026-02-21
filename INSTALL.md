# Installation Guide

This guide explains how to build and install Screenize locally on macOS.

## Requirements

- macOS 13.0+
- Swift toolchain with Swift Package Manager (`swift --version`)

## Quick Install

```bash
git clone https://github.com/syi0808/screenize.git
cd screenize
./install.command --open
```

`install.command` will:
1. Reset TCC permissions for `com.screenize.Screenize`
2. Build/package the app via `scripts/package_app.sh`
3. Install `Screenize.app` to `~/Applications`
4. Optionally open the app (`--open`)

## Manual Build and Install

```bash
./scripts/package_app.sh release
mkdir -p ~/Applications
rm -rf ~/Applications/Screenize.app
cp -R ./Screenize.app ~/Applications/Screenize.app
open ~/Applications/Screenize.app
```

## First Launch and Permissions

Onboarding blocks continuing until all required permissions are granted:

1. Screen Recording
2. Input Monitoring
3. Microphone
4. Accessibility

If prompts were previously denied, rerun:

```bash
./install.command
```

or reset manually:

```bash
tccutil reset All com.screenize.Screenize
```

## Updating

```bash
cd screenize
git pull origin main
./install.command --open
```

## Uninstall

```bash
rm -rf ~/Applications/Screenize.app
```

## Troubleshooting

### Build Issues

1. Confirm toolchain availability: `swift --version`
2. Clean local artifacts: `rm -rf ./.build ./Screenize.app ./dist`
3. Re-run: `./scripts/package_app.sh release`

### Gatekeeper Warning

If macOS blocks first launch for a locally built app:

1. Right-click `Screenize.app`
2. Select **Open**
3. Confirm **Open** in the dialog
