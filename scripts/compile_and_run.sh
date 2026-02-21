#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME=${APP_NAME:-Screenize}
APP_BUNDLE="$ROOT_DIR/${APP_NAME}.app"
APP_PROCESS_PATTERN="${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

for arg in "$@"; do
  case "${arg}" in
    --help|-h)
      echo "Usage: $(basename "$0") [--test]"
      exit 0
      ;;
    --test|-t)
      swift test
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 1
      ;;
  esac
done

pkill -f "${APP_PROCESS_PATTERN}" 2>/dev/null || true
pkill -x "${APP_NAME}" 2>/dev/null || true

SIGNING_MODE=adhoc "$ROOT_DIR/scripts/package_app.sh" release

if ! open "$APP_BUNDLE"; then
  "$APP_BUNDLE/Contents/MacOS/$APP_NAME" >/dev/null 2>&1 &
  disown
fi

echo "Launched ${APP_NAME}"
