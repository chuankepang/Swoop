#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

./build.sh --local

if pgrep -x Swoop >/dev/null; then
  pkill -x Swoop || true
  sleep 0.3
fi

open .build.noindex/Swoop.app --args --show

for _ in $(seq 1 20); do
  if pgrep -x Swoop >/dev/null; then
    break
  fi
  sleep 0.1
done

if ! pgrep -x Swoop >/dev/null; then
  printf 'Swoop failed to start. Try running:\n  .build.noindex/Swoop.app/Contents/MacOS/Swoop --show\n' >&2
  exit 1
fi

cat <<'EOF'

Swoop is running.

What you should see:
  1) A floating search box near the center of the screen
  2) A small Swoop mark in the top menu bar

If the search box is not visible:
  - Press Option + Space
  - Or click the menu bar Swoop icon → Open Swoop

To quit:
  - Menu bar Swoop icon → Quit Swoop

EOF
