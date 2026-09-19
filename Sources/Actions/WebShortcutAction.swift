import AppKit

final class WebShortcutAction: LauncherAction {
    let provider: WebShortcutProvider
    private let launcher: BrowserLauncher

    init(provider: WebShortcutProvider, launcher: BrowserLauncher) {
        self.provider = provider
        self.launcher = launcher
    }

    var id: String { "shortcut.\(provider.id)" }
    var title: String { provider.title }
    var aliases: [String] { provider.aliases }
    var keywords: [String] { provider.keywords }
    var kind: ActionKind { .webShortcut }
    var requiresInput: Bool { false }
    var inputPlaceholder: String? { nil }
    lazy var icon: NSImage? = IconProvider.brand(provider.mark)

    func execute(input: String?) {
        launcher.openURLInPreferredBrowser(provider.url)
    }
}
