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
mkdir -p .build.noindex
sources=()
while IFS= read -r file; do
  sources+=("$file")
done < <(find Sources -name '*.swift' ! -name 'main.swift' | sort)
tests=()
while IFS= read -r file; do
  tests+=("$file")
done < <(find Tests -name '*.swift' | sort)

xcrun swiftc \
  -swift-version 5 \
  -target "$(uname -m)-apple-macos14.0" \
  "${sources[@]}" \
  "${tests[@]}" \
  -o .build.noindex/SwoopTests \
  -framework AppKit \
  -framework Carbon \
  -framework ApplicationServices
.build.noindex/SwoopTests
