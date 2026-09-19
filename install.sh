#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if pgrep -x Swoop >/dev/null; then
  printf 'Swoop is running. Quitting before install...\n'
  osascript -e 'tell application "Swoop" to quit' >/dev/null 2>&1 || true
  sleep 1
  if pgrep -x Swoop >/dev/null; then
    killall Swoop >/dev/null 2>&1 || true
    sleep 1
  fi
fi

./build.sh --local
rm -rf /Applications/Swoop.app
cp -R .build.noindex/Swoop.app /Applications/Swoop.app
codesign --force --sign - /Applications/Swoop.app >/dev/null
printf 'Installed: /Applications/Swoop.app\n'
