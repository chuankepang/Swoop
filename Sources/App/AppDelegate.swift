import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkey = GlobalHotkeyManager()
    private let registry = ActionRegistry()
    private let history = UsageHistory()
    private let apps = ApplicationIndex()
    private let spotlight = SpotlightService()
    private let browser = BrowserLauncher()
    private let system = SystemActionService()
    private var controller: LauncherController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerActions()
        hotkey.onPressed = { [weak self] in
            self?.controller?.toggle()
        }
        hotkey.registerDefault()
        setupStatusItem()
        setupMenu()
        apps.scan { [weak self] installed in
            self?.registry.register(installed.map(ApplicationAction.init))
        }

        let shouldShow = ProcessInfo.processInfo.arguments.contains("--show")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let search = SearchEngine(registry: self.registry, history: self.history)
            self.controller = LauncherController(
                registry: self.registry,
                searchEngine: search,
                history: self.history
            )
            if shouldShow {
                self.controller?.show()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func registerActions() {
        registry.register(WebSearchCatalog.all.map { WebSearchAction(provider: $0, launcher: browser) })
        registry.register(FileSearchAction(spotlight: spotlight))
        registry.register([
            SystemAction(
                id: "system.lock",
                title: "Lock Screen",
                aliases: ["lock", "loc", "lk", "锁屏", "suoping"],
                keywords: ["security"],
                icon: ActionIconFactory.glyph(
                    "lock.fill",
                    tint: .white,
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
                icon: ActionIconFactory.glyph(
                    "moon.fill",
                    tint: .white,
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
                icon: ActionIconFactory.glyph(
                    "sparkles",
                    tint: .white,
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

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = ActionIconFactory.menuBarImage()
        item.button?.imagePosition = .imageOnly
        item.button?.toolTip = "Swoop"
        let menu = NSMenu()
        let openItem = menu.addItem(withTitle: "Open Swoop", action: #selector(openLauncher), keyEquivalent: "")
        openItem.target = self
        menu.addItem(.separator())
        let quitItem = menu.addItem(withTitle: "Quit Swoop", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        item.menu = menu
        statusItem = item
    }

    private func setupMenu() {
        let menu = NSMenu()
        let appMenu = NSMenu()
        let item = NSMenuItem()
        item.submenu = appMenu
        menu.addItem(item)
        let quitItem = NSMenuItem(title: "Quit Swoop", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)
        NSApp.mainMenu = menu
    }

    @objc private func openLauncher() {
        controller?.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func finderIcon() -> NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") {
            return ActionIconFactory.roundedAppIcon(NSWorkspace.shared.icon(forFile: url.path))
        }
        return ActionIconFactory.glyph(
            "folder.fill",
            tint: .white,
            fill: NSColor(srgbRed: 0.20, green: 0.55, blue: 0.95, alpha: 1)
        )
    }
}
