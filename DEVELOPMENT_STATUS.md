# Development Status

## Current phase

UX / search / macOS-integration refactor (post-MVP). See `BUGFIX_AUDIT.md` and `VALIDATION_REPORT.md`.

## Completed features

- Option + Space via `GlobalHotkeyManager`
- Floating `NSPanel` with HUD material, hairline, and drop shadow
- IME-safe field editor (Return does not bypass marked text)
- State machine: action selection → awaiting input → file results browse → execute
- `SearchableEntity` with Mandarin Latin transliteration (no per-app pinyin tables)
- Application index of Applications folders plus system bundles by identifier
- `NSWorkspace.openApplication(at:)` with failure logging / panel error
- Find Files: Enter searches, second Enter opens; 300ms debounce preview
- `LayoutMetrics` (~1.26 scale), stack-view vertical centering
- Menu bar SF Symbol template (`magnifyingglass`)
- Usage / recency empty-query suggestions (up to 6)
- `./build.sh`, `./run.sh`, `./test.sh`

## Current architecture

```text
AppDelegate
  → GlobalHotkeyManager
  → ActionRegistry
  → ApplicationIndex / ApplicationLauncher
  → SpotlightService
  → LauncherController
        → LauncherStateMachine
        → SearchEngine / SearchableEntity / FuzzyMatcher
        → LauncherPanel (field editor + HUD chrome)
```

## Known issues

- Human IME matrix (ABC vs 简体拼音) still required
- `SpotlightService` inside `./test.sh` may return empty while Terminal `mdfind` works
- Mandarin Latin uses Apple’s readings (e.g. 乐 → le)

## Manual tests

Automated: `./test.sh` passed.

Please verify on the desktop:

1. 中文输入法 + `goo` + Enter → Google Search mode, then Chinese query still types
2. `wechat` / `weixin` / `微信` + Enter → WeChat
3. `fin` + Enter + filename + Enter → file list, then Enter opens
4. Panel larger, icon and field aligned, menu bar matches other extras
5. Light / Dark

## Next tasks

- User IME and live launch confirmation
- Optional `NSMetadataQuery` if `mdfind` TCC is flaky for some users
