# Contributing to Screenize

Thanks for contributing to Screenize.

## How to Contribute

### Report Bugs

1. Search [existing issues](../../issues).
2. If not found, open a new issue with:
- Reproduction steps
- Expected vs actual behavior
- Environment details (macOS + `swift --version`)
- Screenshots/recordings if useful

### Suggest Enhancements

1. Search [existing issues](../../issues).
2. Open a new issue with:
- Problem/use case
- Proposed solution
- Alternatives considered

### Submit Pull Requests

1. Fork the repo.
2. Create a branch from `main`.
3. Implement your change.
4. Run build and lint locally.
5. Push and open a PR with clear context.

## Development Setup

```bash
git clone https://github.com/YOUR_USERNAME/screenize.git
cd screenize
swift build
```

Run the app:

```bash
./scripts/compile_and_run.sh
```

## Permissions for Local Testing

The app requires all of the following for full functionality:

1. Screen Recording
2. Input Monitoring
3. Microphone
4. Accessibility

Reset permissions when needed:

```bash
tccutil reset All com.screenize.Screenize
```

or use:

```bash
./install.command
```

## Linting

Run:

```bash
./scripts/lint.sh
```

Auto-fix where possible:

```bash
./scripts/lint.sh --fix
```

## Style Expectations

- Keep changes focused and minimal.
- Follow existing naming and organization patterns.
- Keep keyframes time-sorted within tracks.
- Use `@MainActor` for UI/state coordination where appropriate.

## Testing

There is no full automated test suite yet. If your change is behavior-critical, include reproducible manual test steps in the PR.
