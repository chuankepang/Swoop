# Bugfix Audit

Audit date: 2026-09-19. Source of truth: current `Sources/` before this refactor.

## 1. Keyboard / IME Input Architecture

**Observed:** With Simplified Pinyin active, typing Latin commands (`goo`, `wechat`) then Enter often does nothing, needs a second Enter, or leaves marked text uncommitted.

**Expected:** IME gets first claim on Return while composing. After text is committed, Enter confirms the launcher action. Real Chinese input (`微信`, `机器人操作`) still works. Do not force ABC.

**Root cause:** `KeyHandlingTextView.keyDown` and `performKeyEquivalent` intercept `keyCode` 36/76 (Return) *before* `NSTextInputClient` / the input method. Composition never commits. `NSTextFieldDelegate.insertNewline` is the correct post-IME hook and is racing with that steal.

**Affected module:** `Sources/UI/SearchInputView.swift` (`KeyHandlingTextView`), `LauncherPanel` field editor, `LauncherController.handle`.

**Fix strategy:** Field editor only intercepts ↑↓/Esc when `!hasMarkedText()`. Return is never stolen in `keyDown`. Confirm only from `insertNewline` / `doCommandBy:` after IME. Cmd+A/C/V/Delete stay on `NSTextView`.

**Regression risk:** Enter in ABC mode must still confirm. Esc during composition should cancel marked text via `super`, not close the panel.

---

## 2. Search & Matching Architecture

**Observed:** `weixin` / localized names miss apps unless they appear in a hardcoded `AliasLexicon` table. Matching is `title + aliases` only.

**Expected:** Every action is a `SearchableEntity` with display name, bundle names, localizations, normalized forms, pinyin, initials. `wechat` / `微信` / `weixin` resolve to the same app without WeChat-specific branches.

**Root cause:** `AliasLexicon` is a finite Chinese dictionary. `ApplicationIndex.inspect` keeps one display name and drops `CFBundleName` / `InfoPlist.strings`. No `CFStringTransform` MandarinLatin pipeline.

**Affected module:** `AliasLexicon.swift`, `FuzzyMatcher.swift`, `ApplicationIndex.swift`, `ApplicationAction.swift`, `SearchEngine.swift`.

**Fix strategy:** `Transliterator` via `kCFStringTransformMandarinLatin` + strip diacritics. `SearchableEntity` built at index time. Rank exact > prefix > initials > transliteration > subsequence > usage.

**Regression risk:** Over-matching pinyin initials (`wx`, `w`). Keep initials below exact/prefix. Usage bonus still cannot beat exact alias.

---

## 3. Application Discovery & Launch Reliability

**Observed:** WeChat (and potentially other apps) can appear in search but fail to come to front. Launch errors are swallowed.

**Expected:** Index `/Applications`, `/System/Applications`, `~/Applications`, Utilities. Launch the indexed `bundleURL` with `NSWorkspace.openApplication`. Surface failures.

**Root cause:** `execute` calls `NSRunningApplication.activate()` (macOS 14: `ignoringOtherApps` has no effect) and ignores the `openApplication` completion `Error`. Failed launches still close the panel (`finish { execute }`).

**Affected module:** `ApplicationAction.swift`, `ApplicationIndex.swift`, `LauncherController.finish`.

**Fix strategy:** `ApplicationLauncher` always opens `bundleURL`. Completion reports success/failure. On failure, reopen panel with a short error string. Collect localized names at scan time.

**Regression risk:** Double-opening if both activate and openApplication run. Use one API.

---

## 4. File Search State Machine

**Observed:** `fin` → Find Files → type filename → Enter shows no results / does not search.

**Expected:** Stage 1 select Find Files. Stage 2 type query. Enter *runs search* and lists files. ↑↓ select. Enter opens. Esc returns to query.

**Root cause:** `awaitingInput` treats Enter as `execute(input)`, which opens the first Spotlight hit asynchronously (or none). Debounced `inputCandidates` is not a distinct “results” phase, so Enter never means “search”. If the list is empty, execute silently no-ops.

**Affected module:** `LauncherState.swift`, `LauncherController.confirm`, `FileSearchAction.execute`, `SpotlightService`.

**Fix strategy:** Phases `awaitingInput` vs `browsingFiles`. File actions declare `inputConfirmBehavior = .searchThenBrowse`. Spotlight stays `Process.arguments` + generation token. Rank by filename exact/prefix/fuzzy.

**Regression risk:** Web search Enter must still execute the URL, not browse.

---

## 5. Layout / Scaling / Alignment

**Observed:** Panel feels small. Icon and text are not truly centerY-aligned (manual `font.ascender` frames). Brand icons vary optically.

**Expected:** One `LayoutMetrics` scale (~1.25). Auto Layout / stack views: `icon.centerY == field.centerY`. Uniform icon bounding boxes.

**Root cause:** Magic numbers in `LauncherLayout` plus `layout()` frame math for text height. No constraints.

**Affected module:** `Constants.swift`, `SearchInputView`, `CandidateRowView`, `LauncherView`.

**Fix strategy:** `LayoutMetrics` scaled constants. `NSStackView` alignment `.centerY`. Icons drawn into a fixed canvas and displayed `scaleProportionallyUpOrDown`.

**Regression risk:** Auto Layout vs panel `setFrame` resize — pin stack to input row edges.

---

## 6. Floating Panel Visual Hierarchy

**Observed:** `popover` material blends into the desktop; `masksToBounds` on the root clips any shadow.

**Expected:** HUD-like float: blur + shadow + hairline border. Native, not neon.

**Root cause:** `NSVisualEffectView.material = .popover` and clipping the layer that would hold a shadow.

**Affected module:** `LauncherView.swift`, `LauncherPanel.swift`.

**Fix strategy:** Inner clipped chrome + outer shadow host. Material `.hudWindow`. Hairline using label color at low alpha.

---

## 7. macOS Menu Bar / Status Item Compliance

**Observed:** Custom 18×18 raster swoop does not match Wi‑Fi / Control Center weight or padding.

**Expected:** `NSStatusItem.button`, template image, SF Symbol at menu-bar point size. Light/Dark automatic.

**Root cause:** App-icon artwork scaled into the status item. Not an SF Symbol template.

**Affected module:** `AppDelegate.setupStatusItem`, `ActionIconFactory.menuBarImage`.

**Fix strategy:** `magnifyingglass` (or fallback) with `NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)`, `isTemplate = true`. App icon remains the color swoop. State icons remain brand tiles.

---

## 8. Regression Testing & Code Review

**Observed:** Tests cover fuzzy aliases but not pinyin transform, file-search phases, launch API, or IME (GUI).

**Expected:** Unit tests for normalization/pinyin/ranking/state/file search. Launch matrix records PASS/FAIL/SKIP. Manual IME matrix documented as environment-limited if this agent cannot switch input sources.

**Root cause:** Scope of `Tests/LauncherTests.swift`.

**Fix strategy:** Expand tests. Integration: `mdfind` + temp files; `NSWorkspace` launch of apps that exist.

**Regression risk:** Spotlight delay for brand-new files — also query a known indexed path.
