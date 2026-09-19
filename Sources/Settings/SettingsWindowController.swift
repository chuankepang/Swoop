import AppKit

final class SettingsWindowController: NSWindowController {
    private static var shared: SettingsWindowController?

    private let store: ConfigurationStore
    private let loginItemManager: LoginItemManager
    private let generalView: GeneralSettingsView
    private let webActionsView: WebActionsSettingsView

    static func shared(store: ConfigurationStore, loginItemManager: LoginItemManager) -> SettingsWindowController {
        if let shared {
            return shared
        }
        let controller = SettingsWindowController(store: store, loginItemManager: loginItemManager)
        SettingsWindowController.shared = controller
        return controller
    }

    private init(store: ConfigurationStore, loginItemManager: LoginItemManager) {
        self.store = store
        self.loginItemManager = loginItemManager
        self.generalView = GeneralSettingsView(store: store, loginItemManager: loginItemManager)
        self.webActionsView = WebActionsSettingsView(store: store)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Swoop Settings"
        window.center()
        super.init(window: window)

        let tabs = NSTabView()
        tabs.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = NSView()
        window.contentView?.addSubview(tabs)
        tabs.topAnchor.constraint(equalTo: window.contentView!.topAnchor).isActive = true
        tabs.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor).isActive = true
        tabs.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor).isActive = true
        tabs.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor).isActive = true

        tabs.addTabViewItem(makeTab(title: "General", view: generalView))
        tabs.addTabViewItem(makeTab(title: "Web Actions", view: webActionsView))
        tabs.addTabViewItem(makeTab(title: "About", view: AboutSettingsView()))

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configurationDidChange),
            name: .swoopConfigurationDidChange,
            object: store
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bringToFront() {
        generalView.refreshLoginItemState()
        webActionsView.reload()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }

    @objc private func configurationDidChange() {
        webActionsView.reload()
    }

    private func makeTab(title: String, view: NSView) -> NSTabViewItem {
        let item = NSTabViewItem(identifier: title)
        item.label = title
        view.translatesAutoresizingMaskIntoConstraints = false
        item.view = view
        return item
    }
}
