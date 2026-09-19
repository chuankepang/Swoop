import Foundation

final class SearchEngine {
    private let registry: ActionRegistry
    private let history: UsageHistory

    init(registry: ActionRegistry, history: UsageHistory) {
        self.registry = registry
        self.history = history
    }

    func searchActions(query: String, limit: Int = LayoutMetrics.maxVisibleRows) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return defaultList(limit: min(limit, 6))
        }

        var ranked: [RankedAction] = []
        for action in registry.all() {
            let match = FuzzyMatcher.score(query: trimmed, entity: action.searchEntity)
            let combined = RankingEngine.combine(fuzzyScore: match.value, usage: history.snapshot(actionID: action.id))
            if combined > 0 {
                ranked.append(RankedAction(actionID: action.id, score: combined, reason: match.reason))
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
                    payload: .action,
                    matchReason: item.reason
                )
            }
    }

    private func defaultList(limit: Int) -> [SearchResult] {
        let recentIDs = history.recentActionIDs(limit: limit)
        var seen = Set<String>()
        var results: [SearchResult] = []

        func append(id: String, score: Double) {
            guard !seen.contains(id), let action = registry.action(id: id) else { return }
            seen.insert(id)
            results.append(
                SearchResult(
                    actionID: action.id,
                    title: action.title,
                    subtitle: subtitle(for: action),
                    score: score,
                    payload: .action,
                    matchReason: "recency"
                )
            )
        }

        for (index, id) in recentIDs.enumerated() {
            append(id: id, score: 500 - Double(index))
        }

        let preferred = [
            "web.google", "files.find", "system.lock", "web.github",
            "web.scholar", "system.finder", "web.youtube"
        ]
        for id in preferred where results.count < limit {
            append(id: id, score: 200)
        }
        for action in registry.all() where results.count < limit {
            append(id: action.id, score: 50)
        }
        return results
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
