# Screenize Development Guide

## Quick Start (SwiftPM)

```bash
swift build
./scripts/compile_and_run.sh
```

## Build Commands

Debug build:
```bash
swift build
```

Release build and app bundle packaging:
```bash
./scripts/package_app.sh release
```

Install to `~/Applications`:
```bash
./install.command --open
```
