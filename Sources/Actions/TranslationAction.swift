import AppKit

final class TranslationAction: LauncherAction {
    let provider: TranslationProvider
    private let launcher: BrowserLauncher

    init(provider: TranslationProvider, launcher: BrowserLauncher) {
        self.provider = provider
        self.launcher = launcher
    }

    var id: String { "translate.\(provider.id)" }
    var title: String { provider.title }
    var aliases: [String] { provider.aliases }
    var keywords: [String] { provider.keywords }
    var kind: ActionKind { .translation }
    var requiresInput: Bool { true }
    var inputPlaceholder: String? { provider.placeholder }
    lazy var icon: NSImage? = IconProvider.brand(provider.mark)

    func execute(input: String?) {
        guard let input, !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let url = QueryURLEncoder.url(from: provider.urlTemplate, key: input) else { return }
        launcher.openURLInPreferredBrowser(url)
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
                title: provider.title,
                subtitle: trimmed,
                score: RankingWeights.exactTitle,
                payload: .prompt(text: trimmed),
                matchReason: "prompt"
            )
        ])
    }
}
