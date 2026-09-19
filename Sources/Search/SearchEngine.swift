import Foundation

final class SearchEngine {
    private let registry: ActionRegistry
    private let history: UsageHistory

    init(registry: ActionRegistry, history: UsageHistory) {
        self.registry = registry
        self.history = history
    }

    func searchActions(query: String, limit: Int = LauncherLayout.maxVisibleRows) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let actions = registry.all()
        if trimmed.isEmpty {
            return []
        }

        var ranked: [RankedAction] = []
        for action in actions {
            let fuzzy = FuzzyMatcher.score(
                query: trimmed,
                title: action.title,
                aliases: action.aliases,
                keywords: action.keywords
            )
            let combined = RankingEngine.combine(fuzzyScore: fuzzy, usage: history.snapshot(actionID: action.id))
            if combined > 0 {
                ranked.append(RankedAction(actionID: action.id, score: combined))
            }
        }

        return RankingEngine.rank(ranked)
            .prefix(limit)
            .compactMap { item in
                guard let action = registry.action(id: item.actionID) else { return nil }
                return SearchResult(
                    actionID: action.id,
                    title: action.title,
                    subtitle: subtitle(for: action),
                    score: item.score,
                    payload: .action
                )
            }
    }

    private func subtitle(for action: any LauncherAction) -> String {
        switch action.kind {
        case .webSearch: return "Web Search"
        case .application: return "Application"
        case .system: return "System"
        case .fileSearch: return "Files"
        }
    }
}
