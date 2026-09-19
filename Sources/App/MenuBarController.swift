import AppKit

final class MenuBarController {
    private var statusItem: NSStatusItem?
    private let onOpen: () -> Void
    private let onSettings: () -> Void
    private let onQuit: () -> Void

    init(onOpen: @escaping () -> Void, onSettings: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onOpen = onOpen
        self.onSettings = onSettings
        self.onQuit = onQuit
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = IconProvider.menuBarTemplate()
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleNone
            button.toolTip = "Swoop"
        }

        let menu = NSMenu()
        let openItem = menu.addItem(withTitle: "Open Swoop", action: #selector(openLauncher), keyEquivalent: "")
        openItem.keyEquivalentModifierMask = [.option]
        openItem.keyEquivalent = " "
        openItem.target = self
        menu.addItem(.separator())
        let settingsItem = menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(.separator())
        let quitItem = menu.addItem(withTitle: "Quit Swoop", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        item.menu = menu
        statusItem = item
    }

    @objc private func openLauncher() {
        onOpen()
    }

    @objc private func openSettings() {
        onSettings()
    }

    @objc private func quit() {
        onQuit()
    }
}
