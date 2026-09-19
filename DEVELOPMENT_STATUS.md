# Development Status

## Current phase

Round 5: Settings window, login item, configurable web actions, install script.

## Completed features

- Native Settings window (General / Web Actions / About)
- `ConfigurationStore` + `BuiltInWebActionDefaults` + `WebActionResolver`
- Live reload of web actions via `ActionRegistry.replaceWebActions`
- Built-in web action overrides (name, aliases, URL, enabled) + custom actions
- `{key}` in URL template drives two-stage vs immediate shortcut
- Preferred browser: Chrome preferred or system default
- Fallback search engine: Bing (default) or Google
- Launch at login via `SMAppService.mainApp`
- Menu bar: Open Swoop (⌥Space) / Settings… (⌘,) / Quit (⌘Q)
- Launcher action: `system.settings` (`settings`, `pref`, `设置`)
- `./install.sh` copies local build to `/Applications/Swoop.app`
- `./uninstall.sh` quits, unregisters login item, removes `/Applications/Swoop.app` (`--purge-data` clears UserDefaults)
- `./build.sh` defaults to `--local`; links `ServiceManagement`
- `./test.sh` passes (includes configuration tests)

## Architecture

```text
BuiltInWebActionDefaults + ConfigurationStore
  → WebActionResolver
  → ActionRegistry.replaceWebActions
  → ConfigurableWebAction

SettingsWindowController → ConfigurationStore → live reload
LoginItemManager → SMAppService.mainApp
SearchEngine / BrowserLauncher read ConfigurationStore
```

## Manual QA still needed

- Settings from menu bar and launcher `settings` query
- Edit Google alias live (`goo` → custom alias) without restart
- Custom immediate shortcut (no `{key}`) and custom search (`{key}`)
- Launch at login toggle vs System Settings → Login Items
- `/Applications/Swoop.app` first open shows launcher once; subsequent login launches stay silent
- Regression: chr/wechat/goo/键盘/fin/loc/ChatGPT/translate/IME/file browse
