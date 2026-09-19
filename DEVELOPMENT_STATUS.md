# Development Status

## Current phase

Phase 8 complete: app, tests, scripts, and docs are in place.

## Completed features

- Option + Space via `GlobalHotkeyManager` (Carbon)
- Borderless floating `NSPanel` with status icon + input + candidates
- `LauncherStateMachine`: action selection → optional input → execute / Esc back / close
- Unified `LauncherAction` + `ActionRegistry`
- Fuzzy matcher (exact, prefix, word prefix, initials, alias, keyword, subsequence)
- Ranking with usage count and recency (`UserDefaults`)
- Application index of `/Applications`, `/System/Applications`, `~/Applications`
- Web search providers (Google, Bing, GitHub, YouTube, Scholar, arXiv, Xiaohongshu)
- Chrome-preferred `BrowserLauncher` with default-browser fallback
- RFC-style query encoding for `{key}` templates
- Find Files through `SpotlightService` (`/usr/bin/mdfind`)
- Lock Screen, Sleep, Screen Saver, Finder
- Unified rounded icons: brand marks for web search, real app icons, SF Symbols for system actions
- Appearance follows macOS light/dark
- Empty query shows only the input row; candidates appear after typing
- File search uses `mdfind -name` with a Common-mode debounce timer
- App launch activates a running app like the Dock
- Pinyin aliases for common Chinese names (`guge`, `weixin`, …)

## Current architecture

```text
AppDelegate
  → GlobalHotkeyManager
  → ActionRegistry (web, system, files, apps)
  → LauncherController
        → LauncherStateMachine
        → SearchEngine / FuzzyMatcher / RankingEngine
        → LauncherPanel (AppKit)
```

Web search is data-driven (`WebSearchCatalog`). Applications become `ApplicationAction` instances after a one-time scan. File search reuses the candidate list in stage 2.

## Known issues

- Unit tests cover ranking, registry, URL encoding, and the state machine.
- Fixed (2026-09-19): app appeared not to start because `NSPanel` was created synchronously in `applicationDidFinishLaunching` (hang) and then crashed on conflicting `collectionBehavior` flags. Both are fixed; `./run.sh` now leaves a visible window (`windows=1` in Accessibility checks).
- Fullscreen stacking and live Chrome / VS Code / Finder hotkey checks still need a human at the Mac.
- Option + Space may already be bound by another launcher or an input method.
- Lock Screen uses `SACLockScreenImmediate` from the private `login` framework, with an AppleScript fallback that may require Accessibility permission.
- Application folder changes are not watched after the initial scan.
- Xiaohongshu search URL is a single template in `WebSearchCatalog`; site changes require a config edit, not an architecture change.
- On this machine the default Command Line Tools SDK is macOS 26 while `swiftc` is 6.1.2. Build scripts pin `SDKROOT` to a macOS 15 SDK when that mismatch is detected.

## Manual tests

Automated:

```text
./test.sh
goo/gg/vsc/chr/loc/sch/gh/fin ranking
Esc back vs close
URL encoding of spaces and reserved characters
exact match outranks usage-boosted weak matches
```

Still require a real session on the Mac:

```text
1. Option Space → chr → Enter → Chrome
2. goo → Enter → robot manipulation → Enter → Google in Chrome
3. bin → Enter → robot learning → Enter → Bing
4. gh → Enter → ManiSkill → Enter → GitHub
5. loc → Enter → lock screen (no second stage)
6. fin → Enter → filename → files listed → Enter opens
7. Search mode Esc → action list; Esc again → close
8. Fullscreen app + Option Space + type immediately
9. Click outside closes
```

## Next tasks

- Run the app on the desktop and confirm hotkey, panel level, and first-responder behavior
- Adjust panel style if `.nonactivatingPanel` prevents typing
- Optional: persist a custom hotkey without a settings window
