import AppKit

final class WebSearchAction: LauncherAction {
    let provider: WebSearchProvider
    private let launcher: BrowserLauncher

    init(provider: WebSearchProvider, launcher: BrowserLauncher) {
        self.provider = provider
        self.launcher = launcher
    }

    var id: String { "web.\(provider.id)" }
    var title: String { provider.title }
    var aliases: [String] { provider.aliases }
    var keywords: [String] { provider.keywords }
    var kind: ActionKind { .webSearch }
    var requiresInput: Bool { true }
    var inputPlaceholder: String? { provider.placeholder }
    lazy var icon: NSImage? = ActionIconFactory.brand(provider.mark)

    func execute(input: String?) {
        guard let input, !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let url = QueryURLEncoder.url(from: provider.urlTemplate, key: input) else { return }
        launcher.open(url)
    }

    func inputCandidates(query: String, completion: @escaping ([SearchResult]) -> Void) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion([])
            return
        }
        completion([
            SearchResult(
                actionID: id,
                title: "Search \(shortName) for “\(trimmed)”",
                subtitle: provider.urlTemplate,
                score: RankingWeights.exactTitle,
                payload: .prompt(text: trimmed)
            )
        ])
    }

    private var shortName: String {
        title.replacingOccurrences(of: " Search", with: "")
    }
}
