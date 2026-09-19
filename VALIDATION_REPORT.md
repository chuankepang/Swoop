# Validation Report

## Summary

This pass treated IME, search, launch, file search, layout, glass, and the menu extra as architecture problems. The app builds, unit tests pass, and `.build.noindex/Swoop.app` launches with a visible panel.

## Root Causes

### IME
`KeyHandlingTextView` stole Return in `keyDown` / `performKeyEquivalent` before `NSTextInputClient`. Composition never committed.

### App Launch
`activate()` on a running app is a no-op under macOS 14’s deprecated `ignoringOtherApps`. Completions were ignored, so failures looked like “WeChat does nothing.” Finder lives in CoreServices, outside the Applications folders.

### Search / Pinyin
Matching used a handwritten Chinese alias table. Bundle localizations and Mandarin Latin transforms were unused.

### File Search
Enter in the file-query phase called `execute`, which opened the first hit asynchronously (or nothing). There was no “results browsing” phase.

### Layout
Manual `layout()` frames used font metrics instead of `centerY` alignment. Sizes were small magic numbers.

### Visual Effect
`.popover` plus `masksToBounds` on the same view flattened the panel into the desktop.

### Status Item
A scaled app-mark raster was used instead of a template SF Symbol on `NSStatusItem.button`.

## Changes

- IME-safe field editor: Return only via `insertNewline` after `!hasMarkedText()`
- `SearchableEntity` + `CFStringTransform` MandarinLatin
- `ApplicationLauncher` uses `NSWorkspace.openApplication(at:)` and reports errors
- Extra system bundles resolved by identifier (Finder, Safari, Terminal, …)
- `LauncherPhase.browsingFiles` + `InputConfirmBehavior.searchThenBrowse`
- `LayoutMetrics` scale 1.26; input row `NSStackView` `.centerY`
- HUD material, hairline, drop shadow on an unclipped host
- Menu bar: `magnifyingglass` template, 13pt medium

## Automated Tests

`./test.sh` — **All tests passed** (with full filesystem permissions).

Covered: goo/gg/vsc/chr/loc/sch/gh/fin, wechat/微信/weixin entities, 微信/文件/设置 pinyin, ranking vs usage, file-search state (`searchFiles` then `openFile`), URL encoding, ApplicationIndex includes Finder.

## Manual Tests

This agent **cannot switch input sources or inject Option+Space**. IME matrix must be run on the Mac:

| Scene | ABC | Chinese Pinyin |
| --- | --- | --- |
| goo → Google | needs human | needs human |
| wechat → WeChat | needs human | needs human |
| weixin → WeChat | needs human | needs human |
| 微信 → WeChat | N/A | needs human |
| fin → file search | needs human | needs human |
| ↑↓ / Esc / Enter | needs human | needs human |

Visual (agent launched `--show`, process alive, one panel expected): scale/alignment/shadow/menu bar need a look in Light and Dark.

## Application Launch Matrix

Recorded via `NSWorkspace.urlForApplication` on this machine (existence, not GUI click-through):

| App | Result |
| --- | --- |
| Finder | FOUND `/System/Library/CoreServices/Finder.app` |
| Safari | FOUND |
| Terminal | FOUND |
| Google Chrome | FOUND `/Applications/Google Chrome.app` |
| Visual Studio Code | FOUND |
| WeChat | FOUND `/Applications/WeChat.app` `com.tencent.xinWeChat` |
| Preview | FOUND |
| System Settings | FOUND |

Live Enter-to-launch of WeChat/Chrome still needs a human at the keyboard.

## File Search Validation

- Ranking unit test: exact `root.tex` wins
- `mdfind -name README` works in Terminal
- `SpotlightService` from the test binary returned no hits here (SKIP, likely process/TCC). UI path uses the same `Process.arguments` API.

## Remaining Known Issues

- Apple’s Mandarin Latin maps 乐 → `le`, not `yue`
- Spotlight from a non-app test process may return empty; the running `.app` should be used for file-search QA
- IME ABC vs Pinyin matrix not executed in this environment
- `NSApp.activate(ignoringOtherApps:)` still used to steal focus for the panel (needed for a floating palette)

## Architecture Review

- No WeChat/Google/find title switches in UI
- File confirm behavior is on `LauncherAction`
- Launch always uses indexed `bundleURL`
- Debounced Spotlight uses a generation token
- Status, app, and state icons go through `IconProvider`
