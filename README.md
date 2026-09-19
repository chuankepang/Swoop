# Swoop

Lightweight, keyboard-first, fuzzy command launcher for macOS.

Swoop is a tiny native floating launcher. One shortcut, one box, a few results, Enter, done. It is not a Raycast clone: no plugins, no accounts, no cloud.

macOS 14+ · Swift / AppKit · MIT

## Features

- Global hotkey (`Option + Space`)
- Borderless floating `NSPanel` that can appear over fullscreen apps
- Two-stage actions: pick what to do, then type the argument
- Fuzzy ranking with aliases, word initials, subsequence match, usage, and recency
- Application launch from `/Applications`, `/System/Applications`, and `~/Applications`
- Web search via URL templates (Chrome preferred, system browser fallback)
- Spotlight-backed file search (`mdfind`)
- Lock Screen, Sleep, Screen Saver, Finder
- Menu bar extra for Open / Quit

## Installation

Install the Command Line Tools if needed:

```sh
xcode-select --install
```

Clone, then build:

```sh
git clone https://github.com/YOUR_USERNAME/Swoop.git
cd Swoop
./build.sh
```

`./build.sh` installs **`/Applications/Swoop.app`**. Quit any running copy from the menu bar extra before updating.

To compile without replacing the installed app:

```sh
./build.sh --check
./build.sh --local
```

The local build uses ad-hoc signing and is not notarized.

## Build

```sh
./build.sh          # install to /Applications/Swoop.app
./build.sh --local  # write .build.noindex/Swoop.app
./run.sh            # local build + launch
./test.sh           # unit tests
```

Compilation intermediates live in `.build.noindex/`.

## Usage

1. Launch Swoop once from `/Applications/Swoop.app`.
2. Press **Option + Space** from anywhere.
3. Type 2–4 characters until the action you want is first.
4. **Enter** confirms. Actions that need input (search, files) enter a second stage.
5. **Esc** goes back, then closes.

Typical flows:

```text
chr → Enter                    open Google Chrome
goo → Enter → robot policy     Google Search
gh  → Enter → ManiSkill        GitHub Search
sch → Enter → diffusion        Google Scholar
fin → Enter → root.tex         open a file
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

Web search (all two-stage):

- Google Search (`google`, `goo`, `gg`, `g`, `谷歌`)
- Bing Search (`bing`, `bin`, `bi`, `b`)
- GitHub Search (`github`, `git`, `gh`)
- YouTube Search (`youtube`, `you`, `yt`)
- Google Scholar (`scholar`, `sch`, `paper`, `学术`)
- arXiv Search (`arxiv`, `arx`)
- Xiaohongshu Search (`xiaohongshu`, `xhs`, `red`, `红书`, `小红书`)

System:

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
  App/          lifecycle, controller, state machine
  UI/           NSPanel, input row, candidate list
  Actions/      unified action types and registry
  Search/       fuzzy matcher, ranking, search engine
  Services/     apps, Spotlight, browser, usage, system
  Hotkey/       global Option+Space
  Utils/        URL encoding and layout constants
Tests/
Scripts/GenerateIcon.swift
build.sh  run.sh  test.sh
```

## Development

No third-party packages. The app is compiled with `swiftc` against AppKit, Carbon, and ApplicationServices.

```sh
./test.sh
./run.sh
```

If the default Command Line Tools SDK is newer than the installed Swift compiler, the build scripts automatically prefer a macOS 15 SDK when present.

## Roadmap

- User-configurable hotkey
- Watch Application folders for changes
- Replace `mdfind` with `NSMetadataQuery` if needed
- Optional custom web-search providers file

Out of scope for this project: AI, plugin stores, clipboard history, window management, accounts, telemetry.

## License

MIT. See [LICENSE](LICENSE).
