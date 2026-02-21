<p align="center">
  <img src="Screenize/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" alt="Screenize" width="128" height="128">
</p>

<h1 align="center">Screenize</h1>

<p align="center">
  <img src="docs/demo.gif" alt="Screenize demo" style="max-width: 100%; width: 520px;" />
</p>

Open-source macOS screen recording app with auto-zoom, cursor effects, and timeline editing.

Screenize uses a two-pass workflow:
1. Record raw video plus mouse/keyboard metadata.
2. Apply zoom, cursor, click, keystroke, and annotation effects in the editor.

## Features

- Screen and window capture via `ScreenCaptureKit`
- Smart auto-zoom from interaction/context analysis
- Timeline-based editing with keyframes and easing
- Click ripple effects and custom cursor rendering
- Keystroke overlays for shortcut visualization
- Background styling (solid, gradient, image)
- Export to MP4/MOV

## Requirements

- macOS 13.0+
- Swift toolchain with Swift Package Manager (`swift --version`)

## Build and Run (SwiftPM)

```bash
git clone https://github.com/syi0808/screenize.git
cd screenize
./scripts/package_app.sh release
open ./Screenize.app
```

## Install to Applications

```bash
./install.command --open
```

Notes:
- `install.command` resets existing TCC permissions for `com.screenize.Screenize` first, so permission prompts appear again.
- App bundle is also copied to `./dist/Screenize.app` by the packaging script.

## Development Commands

Build debug binary:
```bash
swift build
```

Package and launch app:
```bash
./scripts/compile_and_run.sh
```

Run linter:
```bash
./scripts/lint.sh
```

Create release DMG:
```bash
./scripts/release.sh 2.2.1
```

## Permissions and Onboarding

On first launch, Screenize shows onboarding and requires all of the following before continuing:

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

## Download

Prebuilt releases are available on [GitHub Releases](https://github.com/syi0808/screenize/releases).

If macOS Gatekeeper warns on first open, right-click the app and choose **Open**.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0. See [LICENSE](LICENSE).
