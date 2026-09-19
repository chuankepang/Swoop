#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ -z "${SDKROOT:-}" ]]; then
  sdk_version="$(xcrun --show-sdk-version 2>/dev/null || true)"
  case "$sdk_version" in
    26*|27*)
      for candidate in \
        /Library/Developer/CommandLineTools/SDKs/MacOSX15.5.sdk \
        /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
        /Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk \
        /Library/Developer/CommandLineTools/SDKs/MacOSX14.5.sdk
      do
        if [[ -d "$candidate" ]]; then
          export SDKROOT="$candidate"
          break
        fi
      done
      ;;
  esac
fi
mode="${1:---install}"
if [[ "$mode" != "--install" && "$mode" != "--check" && "$mode" != "--local" ]]; then
  printf 'Usage: %s [--install|--check|--local]\n' "$0" >&2
  exit 2
fi

mkdir -p .build.noindex
compiled=.build.noindex/Swoop
sources=()
while IFS= read -r file; do
  sources+=("$file")
done < <(find Sources -name '*.swift' | sort)

xcrun swiftc \
  -swift-version 5 \
  -O \
  -target "$(uname -m)-apple-macos14.0" \
  "${sources[@]}" \
  -o "$compiled" \
  -framework AppKit \
  -framework Carbon \
  -framework ApplicationServices

plutil -lint Info.plist >/dev/null

if true; then
  mkdir -p Resources
  xcrun swiftc -swift-version 5 -O Scripts/GenerateIcon.swift -o .build.noindex/GenerateIcon -framework AppKit
  .build.noindex/GenerateIcon Resources/AppIcon.icns
fi

if [[ "$mode" == "--check" ]]; then
  printf 'Build verified. Installed application was not changed.\n'
  exit 0
fi

if [[ "$mode" == "--local" ]]; then
  app_path=.build.noindex/Swoop.app
else
  app_path=/Applications/Swoop.app
  if pgrep -x Swoop >/dev/null; then
    printf 'Quit Swoop from the menu bar item before installing this update.\n' >&2
    exit 1
  fi
fi

mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$compiled" "$app_path/Contents/MacOS/Swoop"
cp Info.plist "$app_path/Contents/Info.plist"
cp Resources/AppIcon.icns "$app_path/Contents/Resources/AppIcon.icns"
cp LICENSE "$app_path/Contents/Resources/"
codesign --force --sign - "$app_path" >/dev/null
printf 'Built: %s\n' "$app_path"
