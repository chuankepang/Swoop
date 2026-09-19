import Foundation

struct UsageSnapshot {
    var count: Int
    var lastUsed: Date?
}

enum RankingEngine {
    static func combine(fuzzyScore: Double, usage: UsageSnapshot, now: Date = Date()) -> Double {
        guard fuzzyScore > 0 else { return 0 }
        let usageBonus = min(RankingWeights.maxUsageBonus, log2(Double(max(usage.count, 0) + 1)) * 12)
        var recencyBonus = 0.0
        if let lastUsed = usage.lastUsed {
            let hours = now.timeIntervalSince(lastUsed) / 3600
            if hours < 24 {
                recencyBonus = RankingWeights.maxRecencyBonus
            } else if hours < 24 * 7 {
                recencyBonus = RankingWeights.maxRecencyBonus * 0.6
            } else if hours < 24 * 30 {
                recencyBonus = RankingWeights.maxRecencyBonus * 0.25
            }
        }
        return fuzzyScore + usageBonus + recencyBonus
    }

    static func rank(_ results: [RankedAction]) -> [RankedAction] {
        results.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.actionID < rhs.actionID
        }
    }
}
