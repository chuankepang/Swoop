import AppKit

final class BrowserLauncher {
    private let chromeBundleID = "com.google.Chrome"
    private weak var store: ConfigurationStore?

    init(store: ConfigurationStore? = nil) {
        self.store = store
    }

    func attachStore(_ store: ConfigurationStore) {
        self.store = store
    }

    func openURLInPreferredBrowser(_ url: URL) {
        open(url)
    }

    func open(_ url: URL) {
        let preference = store?.preferredBrowser ?? .chromePreferred
        switch preference {
        case .chromePreferred:
            openInChromeOrDefault(url)
        case .systemDefault:
            NSWorkspace.shared.open(url)
        }
    }

    private func openInChromeOrDefault(_ url: URL) {
        if let chrome = NSWorkspace.shared.urlForApplication(withBundleIdentifier: chromeBundleID) {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: chrome, configuration: configuration) { _, error in
                if error != nil {
                    NSWorkspace.shared.open(url)
                }
            }
            return
        }
        NSWorkspace.shared.open(url)
    }
}
