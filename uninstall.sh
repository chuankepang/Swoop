#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

purge=false
for arg in "$@"; do
  case "$arg" in
    --purge-data)
      purge=true
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./uninstall.sh [--purge-data]

Quit Swoop, unregister the login item, and remove /Applications/Swoop.app.

  --purge-data   Also delete saved preferences and usage history
EOF
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$arg" >&2
      printf 'Run ./uninstall.sh --help for usage.\n' >&2
      exit 2
      ;;
  esac
done

app_path=/Applications/Swoop.app
binary="$app_path/Contents/MacOS/Swoop"
bundle_id=local.swoop.launcher

if pgrep -x Swoop >/dev/null; then
  printf 'Swoop is running. Quitting before uninstall...\n'
  osascript -e 'tell application "Swoop" to quit' >/dev/null 2>&1 || true
  sleep 1
  if pgrep -x Swoop >/dev/null; then
    killall Swoop >/dev/null 2>&1 || true
    sleep 1
  fi
fi

if [[ -x "$binary" ]]; then
  "$binary" --unregister-login-item || true
elif [[ -d "$app_path" ]]; then
  printf 'Warning: could not unregister login item (binary missing).\n' >&2
fi

if [[ -d "$app_path" ]]; then
  rm -rf "$app_path"
  printf 'Removed %s\n' "$app_path"
else
  printf 'Swoop is not installed at %s\n' "$app_path"
fi

if [[ "$purge" == true ]]; then
  defaults delete "$bundle_id" swoop.preferences.v1 2>/dev/null || true
  defaults delete "$bundle_id" swoop.usage.v1 2>/dev/null || true
  defaults delete "$bundle_id" swoop.didCompleteFirstPresentation 2>/dev/null || true
  printf 'Removed saved preferences for %s\n' "$bundle_id"
fi
