# Swoop

Lightweight, keyboard-first, fuzzy command launcher for macOS.

Swoop is a tiny native floating launcher. One shortcut, one box, a few results, Enter, done. It is not a Raycast clone: no plugins, no accounts, no cloud.

macOS 14+ · Swift / AppKit · MIT

## Features

- Global hotkey (`Option + Space`)
- Borderless floating `NSPanel` that can appear over fullscreen apps
- Two-stage actions: pick what to do, then type the argument
- Fuzzy ranking with aliases, word initials, subsequence match, usage, and recency
- Unknown or weak queries fall back to **Search Bing** (Enter searches immediately; `bin` still opens Bing’s two-stage mode)
- Application launch from `/Applications`, `/System/Applications`, and `~/Applications`
- Web search via URL templates (Chrome preferred, system browser fallback)
- Web shortcuts: one-shot site openers (ChatGPT, Grok, Gemini, Bilibili, Douyin, GitHub)
- Baidu Translate: Chinese → English and English → Chinese (two-stage)
- Spotlight-backed file search (`mdfind` filename metadata)
- Lock Screen, Sleep, Screen Saver, Finder
- Native **Settings** window (General / Web Actions / About)
- Configurable web actions (built-in overrides + custom URLs; `{key}` = two-stage search)
- Preferred browser (Chrome or system default) and fallback search engine (Bing or Google)
- Launch at login via `SMAppService`
- Menu bar extra: Open / Settings / Quit

## Installation

Install the Command Line Tools if needed:

```sh
xcode-select --install
```

Clone, then build:

```sh
git clone https://github.com/YOUR_USERNAME/Swoop.git
cd Swoop
./build.sh --local
./install.sh        # copy to /Applications/Swoop.app
```

`./build.sh` (default) writes **`.build.noindex/Swoop.app`** for development. Use **`./install.sh`** to copy into `/Applications/Swoop.app` (required for Launch at Login). The installer quits a running copy first.

To install directly:

```sh
./build.sh --install  # build + install to /Applications
./build.sh --check    # compile only
```

The local build uses ad-hoc signing and is not notarized.

## Uninstall

```sh
./uninstall.sh              # quit, unregister login item, remove /Applications/Swoop.app
./uninstall.sh --purge-data # also delete preferences and usage history
```

If the app bundle was already deleted manually, remove any leftover login item in **System Settings → General → Login Items**.

## Build

```sh
./build.sh            # .build.noindex/Swoop.app (default)
./build.sh --install  # /Applications/Swoop.app
./install.sh          # local build + copy to /Applications
./uninstall.sh        # remove /Applications/Swoop.app
./run.sh              # local build + launch
./test.sh             # unit tests
```

Compilation intermediates live in `.build.noindex/`.

## Usage

1. Launch Swoop once from `/Applications/Swoop.app`.
2. Press **Option + Space** from anywhere.
3. Type 2–4 characters until the action you want is first.
4. **Enter** confirms. Actions that need input (search, files) enter a second stage.
5. **Esc** goes back, then closes.
6. Open **Settings** from the menu bar, type `settings` / `设置` in the launcher, or press **⌘,**.

Typical flows:

```text
chr → Enter                    open Google Chrome
chat → Enter                   open ChatGPT in Chrome
goo → Enter → robot policy     Google Search
bin → Enter → query            Bing Search mode
键盘 → Enter                   Bing search for 键盘 (no extra prompt)
zh2en → Enter → 键盘           Baidu Translate ZH→EN
github → Enter                 open GitHub home
ghs → Enter → ManiSkill        GitHub Search
sch → Enter → diffusion        Google Scholar
fin → Enter → root.tex         list files, Enter opens
loc → Enter                    lock screen
```

## Keyboard shortcuts

| Key | Action |
| --- | --- |
| Option + Space | Open or hide the launcher |
| ↑ / ↓ | Move the selected candidate |
| Enter | Confirm action or execute |
| Esc | Back to action list, then close |
| ⌘K | Clear the current query |
| Click outside | Close |

## Available Actions

Web shortcuts (Enter opens site in Chrome):

- ChatGPT (`chatgpt`, `chat`, `gpt`, `cg`)
- Grok (`grok`, `xai`)
- Gemini (`gemini`, `gem`)
- Bilibili (`bilibili`, `bili`, `b站`)
- Douyin (`douyin`, `dy`, `抖音`)
- GitHub (`github`, `gh`, `ghome`)

Web search (two-stage):

- Google Search (`google`, `goo`, `gg`, `g`, `谷歌`)
- Bing Search (`bing`, `bin`, `bi`, `b`)
- GitHub Search (`ghs`, `gitsearch`)
- YouTube Search (`youtube`, `you`, `yt`)
- Google Scholar (`scholar`, `sch`, `paper`, `学术`)
- arXiv Search (`arxiv`, `arx`)
- Xiaohongshu Search (`xiaohongshu`, `xhs`, `red`, `红书`, `小红书`)

Translation (two-stage, Baidu):

- Translate ZH → EN (`zh2en`, `中译英`, `fyen`)
- Translate EN → ZH (`en2zh`, `英译中`, `fyzh`)

System:

- Settings (`settings`, `pref`, `设置`)
- Lock Screen (`lock`, `loc`, `lk`, `锁屏`)
- Sleep
- Screen Saver
- Finder

Files:

- Find Files (`find`, `fin`, `files`)

Applications are discovered at launch and become first-class actions (for example `chr` → Google Chrome, `vsc` → Visual Studio Code).

## Project structure

```text
Sources/
  main.swift
  App/          lifecycle, controller, menu bar, login item
  Configuration/ preferences store, built-in defaults, resolver
  Settings/     native preferences window
  UI/           NSPanel, input row, candidate list
  Actions/      unified action types and registry
  Search/       fuzzy matcher, ranking, search engine
  Services/     apps, Spotlight, browser, usage, system
  Hotkey/       global Option+Space
  Utils/        URL encoding and layout constants
Tests/
Scripts/GenerateIcon.swift
build.sh  install.sh  uninstall.sh  run.sh  test.sh
```

## Development

No third-party packages. The app is compiled with `swiftc` against AppKit, Carbon, and ApplicationServices.

```sh
./test.sh
./run.sh
```

If the default Command Line Tools SDK is newer than the installed Swift compiler, the build scripts automatically prefer a macOS 15 SDK when present.

## Roadmap

- User-configurable hotkey recorder
- Hide menu bar icon (with recovery path)
- Watch Application folders for changes
- Replace `mdfind` with `NSMetadataQuery` if needed
- Import/export web action presets

Out of scope for this project: AI, plugin stores, clipboard history, window management, accounts, telemetry.

## License

MIT. See [LICENSE](LICENSE).
