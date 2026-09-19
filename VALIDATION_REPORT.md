# Validation Report

Round 5 — 2026-09-20. Settings window, login item, configurable web actions, install script.

Round 4 — 2026-09-20. Spotlight-like edges, unified icon tiles, status sizing, translation direction icons, show/hide animation.

## Automated

`./test.sh` — **All tests passed** (includes `ConfigurationTests`).

## Settings / configuration matrix

| Area | Change | Result |
| --- | --- | --- |
| ConfigurationStore | UserDefaults JSON `swoop.preferences.v1` | PASS |
| WebActionResolver | built-ins + overrides + customs | PASS |
| replaceWebActions | keeps `files.find`, apps, system | PASS |
| URL validator | requires http/https; `{key}` substitution | PASS |
| Fallback engine | Bing default, Google optional | PASS (code) |
| Browser preference | Chrome preferred vs system default | PASS (code) |
| Settings UI | General / Web Actions / About tabs | PASS (code) |
| Login item | SMAppService.mainApp | PASS (code) |
| install.sh | copy to /Applications | PASS (code) |
| uninstall.sh | quit, unregister login item, remove app | PASS (code) |

## Visual polish matrix

| Area | Change | Result |
| --- | --- | --- |
| Panel corners | continuous radius 22, clip-layer hairline, window-only shadow | PASS (code) |
| App vs web icons | unified 64px tile, aspect-fill apps, no row double-round | PASS (code) |
| Status item | 18pt swoop template, scaleNone | PASS (code) |
| Translation icons | baiduZhEn vs baiduEnZh | PASS |
| Animation | fade 0.14s in / 0.10s out, scale 0.98↔1 | PASS (code) |

## Regression

| Query | Expected | Result |
| --- | --- | --- |
| chr | Google Chrome | PASS |
| goo | Google Search | PASS |
| 键盘 | Bing fallback | PASS |
| fin | Find Files | PASS |
| zh2en / en2zh | distinct marks + input mode | PASS |

## Manual (human)

- White Chrome page: zoom four corners for smooth continuous rim
- Mixed icon row: Google / ChatGPT / WeChat / Chrome / Find Files / Lock — same visual weight
- Menu bar vs WeChat / Clash / battery
- Option+Space fade in; Esc fade out (no flash)
- `zh2en` vs `en2zh` state icons in input mode
- File search + IME Enter unchanged
