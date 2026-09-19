import AppKit

final class ConfigurableWebAction: LauncherAction {
    let config: WebActionConfig
    private let launcher: BrowserLauncher

    init(config: WebActionConfig, launcher: BrowserLauncher) {
        self.config = config
        self.launcher = launcher
    }

    var id: String { config.id }
    var title: String { config.name }
    var aliases: [String] { config.aliases }
    var keywords: [String] { config.keywords }
    var requiresInput: Bool { config.requiresInput }
    var inputPlaceholder: String? { config.placeholder }

    var kind: ActionKind {
        if config.id.hasPrefix("translate.") { return .translation }
        if config.requiresInput { return .webSearch }
        return .webShortcut
    }

    lazy var icon: NSImage? = {
        if let markRaw = config.mark, let mark = BrandMark(rawValue: markRaw) {
            return IconProvider.brand(mark)
        }
        if let builtIn = BuiltInWebActionDefaults.brandMark(for: config.id) {
            return IconProvider.brand(builtIn)
        }
        return IconProvider.systemGlyph(
            "globe",
            fill: NSColor(srgbRed: 0.35, green: 0.55, blue: 0.95, alpha: 1)
        )
    }()

    func execute(input: String?) {
        if config.requiresInput {
            guard let input, !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            guard let url = QueryURLEncoder.url(from: config.urlTemplate, key: input) else { return }
            launcher.openURLInPreferredBrowser(url)
        } else {
            guard let url = URL(string: config.urlTemplate) else { return }
            launcher.openURLInPreferredBrowser(url)
        }
    }

    func inputCandidates(query: String, completion: @escaping ([SearchResult]) -> Void) {
        guard config.requiresInput else {
            completion([])
            return
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion([])
            return
        }
        let subtitle = config.subtitle ?? trimmed
        let promptTitle = kind == .translation ? config.name : "Search \(shortName)"
        completion([
            SearchResult(
                actionID: id,
                title: promptTitle,
                subtitle: kind == .translation ? trimmed : subtitle,
                score: RankingWeights.exactTitle,
                payload: .prompt(text: trimmed),
                matchReason: "prompt"
            )
        ])
    }

    private var shortName: String {
        config.name.replacingOccurrences(of: " Search", with: "")
    }
}
