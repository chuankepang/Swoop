import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkey = GlobalHotkeyManager()
    private let registry = ActionRegistry()
    private let configurationStore = ConfigurationStore()
    private let history = UsageHistory()
    private let apps = ApplicationIndex()
    private let spotlight = SpotlightService()
    private let browser = BrowserLauncher()
    private let system = SystemActionService()
    private let loginItemManager = LoginItemManager()
    private var controller: LauncherController?
    private var menuBar: MenuBarController?
    private var settingsWindow: SettingsWindowController?
    private var configObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        browser.attachStore(configurationStore)
        registerActions()
        reloadWebActions()
        observeConfigurationChanges()

        hotkey.onPressed = { [weak self] in
            self?.controller?.toggle()
        }
        hotkey.registerDefault()

        menuBar = MenuBarController(
            onOpen: { [weak self] in self?.controller?.show() },
            onSettings: { [weak self] in self?.openSettings() },
            onQuit: { [weak self] in self?.quit() }
        )
        menuBar?.install()
        setupMenu()

        apps.scan { [weak self] installed in
            self?.registry.register(installed.map { ApplicationAction(app: $0) })
        }

        let shouldShow = ProcessInfo.processInfo.arguments.contains("--show")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let search = SearchEngine(
                registry: self.registry,
                history: self.history,
                configurationStore: self.configurationStore
            )
            self.controller = LauncherController(
                registry: self.registry,
                searchEngine: search,
                history: self.history
            )
            if shouldShow {
                self.controller?.show()
            } else if !self.configurationStore.didCompleteFirstPresentation {
                self.controller?.show()
                self.configurationStore.markFirstPresentationComplete()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func openSettings() {
        let window = SettingsWindowController.shared(
            store: configurationStore,
            loginItemManager: loginItemManager
        )
        settingsWindow = window
        window.bringToFront()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func registerActions() {
        registry.register(FileSearchAction(spotlight: spotlight))
        registry.register([
            SettingsAction(openSettings: { [weak self] in self?.openSettings() }),
            SystemAction(
                id: "system.lock",
                title: "Lock Screen",
                aliases: ["lock", "loc", "lk", "锁屏", "suoping"],
                keywords: ["security"],
                icon: IconProvider.systemGlyph(
                    "lock.fill",
                    fill: NSColor(srgbRed: 0.35, green: 0.42, blue: 0.52, alpha: 1)
                ),
                command: .lockScreen,
                service: system
            ),
            SystemAction(
                id: "system.sleep",
                title: "Sleep",
                aliases: ["sleep", "slp"],
                keywords: ["power"],
                icon: IconProvider.systemGlyph(
                    "moon.fill",
                    fill: NSColor(srgbRed: 0.35, green: 0.28, blue: 0.62, alpha: 1)
                ),
                command: .sleep,
                service: system
            ),
            SystemAction(
                id: "system.screensaver",
                title: "Screen Saver",
                aliases: ["screensaver", "saver"],
                keywords: ["display"],
                icon: IconProvider.systemGlyph(
                    "sparkles",
                    fill: NSColor(srgbRed: 0.55, green: 0.32, blue: 0.72, alpha: 1)
                ),
                command: .screenSaver,
                service: system
            ),
            SystemAction(
                id: "system.finder",
                title: "Finder",
                aliases: ["finder", "fnd", "访达", "fangda"],
                keywords: ["files"],
                icon: finderIcon(),
                command: .openFinder,
                service: system
            ),
        ])
    }

    private func reloadWebActions() {
        let actions = WebActionResolver.resolveActions(from: configurationStore, launcher: browser)
        registry.replaceWebActions(actions)
        controller?.reloadConfigurationIfNeeded()
    }

    private func observeConfigurationChanges() {
        configObserver = NotificationCenter.default.addObserver(
            forName: .swoopConfigurationDidChange,
            object: configurationStore,
            queue: .main
        ) { [weak self] _ in
            self?.reloadWebActions()
        }
    }

    private func setupMenu() {
        let menu = NSMenu()
        let appMenu = NSMenu()
        let item = NSMenuItem()
        item.submenu = appMenu
        menu.addItem(item)
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Swoop", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)
        NSApp.mainMenu = menu
    }

    private func finderIcon() -> NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") {
            return IconProvider.application(NSWorkspace.shared.icon(forFile: url.path))
        }
        return IconProvider.systemGlyph(
            "folder.fill",
            fill: NSColor(srgbRed: 0.20, green: 0.55, blue: 0.95, alpha: 1)
        )
    }
}
