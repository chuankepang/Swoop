# Bugfix Audit

Audit date: 2026-09-20 (round 5 appended).

## Round 5 — Settings, login item, configurable web actions

### No runtime configuration
**Root cause:** Web catalogs hardcoded at launch; `ActionRegistry` append-only.
**Fix:** `ConfigurationStore` + `WebActionResolver` + `replaceWebActions`; `ConfigurableWebAction` unified type.

### Hardcoded fallback / browser
**Root cause:** `SearchEngine` always Bing; `BrowserLauncher` always Chrome-first.
**Fix:** `ConfigurationStore.fallbackEngine` and `preferredBrowser` read on each use.

### No Settings / login item
**Root cause:** LSUIElement app with menu Open/Quit only.
**Fix:** `SettingsWindowController`, `MenuBarController`, `LoginItemManager`, `SettingsAction`.

### Install path
**Root cause:** `build.sh --install` mixed compile + deploy; login item needs `/Applications`.
**Fix:** Default `./build.sh --local`; new `./install.sh`; `ServiceManagement` linked.

---

## Round 4 — Visual polish (edges, icons, status, animation)

### Panel edge
**Root cause:** Double shadow (window + layer), non-continuous corners, rectangular border child clipped at corners.
**Fix:** `chromeClip` only, `cornerCurve = .continuous`, hairline on clip layer, window shadow only.

### Icon optical mismatch
**Root cause:** Brand tiles fill canvas; app icons had transparent padding + row double-rounding.
**Fix:** Unified `tileRect`/`tilePath` + aspect-fill for apps; removed extra `iconView` corner masks.

### Status item
**Root cause:** 18pt canvas with 2pt inset and proportional downscale.
**Fix:** 18pt glyph in 22pt slot, `imageScaling = .scaleNone`.

### Translation direction
**Root cause:** Both actions used `BrandMark.baidu`.
**Fix:** `baiduZhEn` / `baiduEnZh` direction tiles.

### Flash on show/hide
**Root cause:** Instant `orderOut` / `makeKeyAndOrderFront`, double `stealFocus`, `animationBehavior = .utilityWindow`.
**Fix:** Fade + scale animation, single focus steal, `animationBehavior = .none`.

---

## Round 3 — Web shortcuts, translation, panel layers, branding

### 1. Web Shortcut Architecture

**Observed:** Only two-stage web **search** actions exist. No one-shot site openers (ChatGPT, Bilibili, etc.).

**Root cause:** All web providers were modeled as `WebSearchProvider` with `requiresInput = true`.

**Solution:** `WebShortcutProvider` + `WebShortcutAction` (`requiresInput = false`). Shared `BrowserLauncher.openURLInPreferredBrowser`. GitHub Search aliases split from GitHub home (`github` → shortcut, `ghs` → search).

### 2. Translation Action Architecture

**Observed:** No Baidu translate shortcuts.

**Solution:** `TranslationProvider` + `TranslationAction` with verified deep links:
`https://fanyi.baidu.com/#zh/en/{key}` and `#en/zh/{key}` (Chrome-tested: query prefilled, direction correct).

### 3. Floating Panel / Rounded Corners

**Observed:** White square corners on bright backgrounds; blur content not clipped; shadow clipped with content.

**Root cause:** Single `chrome` view combined shadow host and `masksToBounds`; `NSVisualEffectView` was not always framed to bounds.

**Solution:** `shadowHost` (shadow only, no clip) → `chromeClip` (`cornerRadius` + `masksToBounds`) → effect / wash / border / content. Fixed `effect.frame = bounds`.

### 4. Icon Optical Size

**Observed:** App/system icons still smaller than web brand tiles.

**Solution:** `IconMetrics` recalibrated: app/file inset 0, system symbol 28pt with inset 3.

### 5. Swoop Branding

**Usage:** Default launcher state icon uses `BrandMark.launcher` (blue tile + white swoop). Menu bar uses the same swoop geometry as a template image.

---

## Round 2 — Search fallback, glass, icons, file pipeline

### 1. Search Fallback Architecture

**Observed:** Unknown queries (e.g. `键盘`) produce an empty list or irrelevant fuzzy hits. No next action.

**Expected:** If the best match is below a relevance threshold, first candidate is `Search Bing` / query, Enter runs Bing immediately via `BrowserLauncher`. Strong matches (`chr`, `goo`) stay first. Empty query stays recents.

**Root cause:** `SearchEngine` only maps fuzzy hits. Weak subsequence scores still count as “results.” UI would have to special-case emptiness.

**Affected module:** `SearchEngine`, `SearchResult.Payload`, `LauncherController.confirm`.

**Generalized solution:** Engine inserts an `.immediate(actionID:input:)` result from the Bing provider when `bestScore < strongThreshold` or there are no hits. Controller executes immediate payloads without entering action-input.

**Regression risk:** Fallback must not outrank alias/prefix/app matches.

### 2. Floating Panel Visual Hierarchy

**Observed:** HUD blur still reads as a transparent sheet over webpages.

**Root cause:** `NSPanel` is clear; content wash is missing; shadow is weak and `chrome.masksToBounds` clips inner shadows.

**Generalized solution:** Keep a clear panel; clip chrome; add a translucent wash over `.hudWindow`; stronger host shadow; hairline.

### 3. Unified Icon System

**Observed:** WeChat looks smaller than Find Files; Xiaohongshu is a generic “红” tile.

**Root cause:** App icons include transparent padding; SF Symbols fill the canvas; no per-role inset; Xiaohongshu is a letter, not a brand mark.

**Generalized solution:** `IconMetrics` + `IconProvider` roles (app/brand/system/file/state/status). Draw Xiaohongshu as the red-card mark. Same container, different content insets.

### 4. Status Bar Icon

**Observed:** Menu extra is a magnifying glass, not the Swoop swoop.

**Root cause:** Status item used SF Symbol instead of the launcher mark as a **template** asset.

**Generalized solution:** Same `drawSwoop` geometry, 18pt template, padding in the artboard—not button `origin.y`.

### 5. File Search Execution Pipeline

**Observed:** `fin` → query → Enter still yields no list. Terminal `mdfind` **does** return `root.tex`.

**Root cause (primary):** Return is handled in both `NSTextView.insertNewline` and `NSTextFieldDelegate.doCommandBy`, so Enter fires twice: first starts search, second is `openFile` with an empty list and returns. Debounce also wipes candidates (`candidates = []`) on each keystroke. `-name` is OK; UI never shows the later Spotlight callback reliably if state/confirm races.

**Generalized solution:** Single Enter path; ignore `openFile` while search is in flight or list empty; `kMDItemFSName` query; pipeline logs; do not clear preview on every refresh.

**Implemented:** `SearchResult.Payload.immediate`; threshold `RankingWeights.strongMatch` (700); HUD wash + framed `NSVisualEffectView`; Xiaohongshu card/flower mark; menu-bar template swoop; Enter coalescing 120ms; `mdfind` filename predicate confirmed against `~/Project/simreal/root.tex`.

---

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
