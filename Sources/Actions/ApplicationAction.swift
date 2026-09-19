import AppKit

struct InstalledApp {
    let name: String
    let bundleIdentifier: String
    let url: URL
    let icon: NSImage
}

final class ApplicationAction: LauncherAction {
    let app: InstalledApp
    private let cachedAliases: [String]
    private let cachedIcon: NSImage

    init(app: InstalledApp) {
        self.app = app
        self.cachedIcon = ActionIconFactory.roundedAppIcon(app.icon)
        var names = [app.name, app.url.deletingPathExtension().lastPathComponent]
        if let last = app.bundleIdentifier.split(separator: ".").last, last.count > 3 {
            names.append(String(last))
        }
        var values = Set(AliasLexicon.extraAliases(for: names))
        let words = FuzzyMatcher.words(in: FuzzyMatcher.normalize(app.name))
        if let last = words.last { values.insert(last) }
        if words.count > 1 {
            values.insert(words.map { String($0.prefix(1)) }.joined())
        }
        cachedAliases = Array(values)
    }

    var id: String { "app.\(app.bundleIdentifier)" }
    var title: String { app.name }
    var aliases: [String] { cachedAliases }
    var keywords: [String] { ["app", "application"] }
    var kind: ActionKind { .application }
    var icon: NSImage? { cachedIcon }
    var requiresInput: Bool { false }
    var inputPlaceholder: String? { nil }

    func execute(input: String?) {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
        if let live = running.first {
            live.activate()
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: app.url, configuration: configuration) { _, _ in }
    }
}
