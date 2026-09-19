import Foundation

struct MatchScore: Equatable {
    let value: Double
    let reason: String

    static let none = MatchScore(value: 0, reason: "none")
}

enum FuzzyMatcher {
    static func score(query rawQuery: String, entity: SearchableEntity) -> MatchScore {
        let query = SearchNormalizer.normalize(rawQuery)
        if query.isEmpty { return .none }
        let compactQuery = SearchNormalizer.compact(query)
        var best = MatchScore.none

        func consider(_ value: Double, _ reason: String) {
            if value > best.value {
                best = MatchScore(value: value, reason: reason)
            }
        }

        let display = SearchNormalizer.normalize(entity.displayName)
        if display == query {
            consider(RankingWeights.exactTitle, "exact display")
        }

        for alias in entity.aliases {
            let aliasNorm = SearchNormalizer.normalize(alias)
            if aliasNorm == query {
                consider(RankingWeights.exactAlias, "exact alias")
            } else if aliasNorm.hasPrefix(query) {
                consider(prefix(RankingWeights.aliasPrefix, query: query, target: aliasNorm), "alias prefix")
            }
        }

        for term in entity.terms {
            if term == query || term == compactQuery {
                consider(RankingWeights.exactNormalized, "exact normalized")
            } else if term.hasPrefix(query) || term.hasPrefix(compactQuery) {
                let weight = Transliterator.hasCJK(entity.displayName) && term.allSatisfy({ $0.isASCII })
                    ? RankingWeights.transliterationPrefix
                    : RankingWeights.prefix
                let reason = weight == RankingWeights.transliterationPrefix ? "transliteration prefix" : "prefix"
                consider(prefix(weight, query: compactQuery.count >= query.count ? compactQuery : query, target: term), reason)
            }
        }

        if entity.terms.contains(where: { SearchNormalizer.compact($0) == compactQuery && Transliterator.hasCJK(entity.displayName) }) {
            consider(RankingWeights.transliterationExact, "transliteration exact")
        }

        for initial in entity.initials {
            if initial == compactQuery || initial.hasPrefix(compactQuery) {
                consider(RankingWeights.wordInitials + Double(query.count) * 4, "word initials")
            }
        }

        for keyword in entity.keywords {
            if keyword == query {
                consider(RankingWeights.keyword + 40, "keyword exact")
            } else if keyword.hasPrefix(query) || query.hasPrefix(keyword) {
                consider(RankingWeights.keyword, "keyword")
            }
        }

        if let sub = subsequenceTightness(query: compactQuery, text: SearchNormalizer.compact(display)) {
            consider(RankingWeights.subsequence + sub * 120, "fuzzy subsequence")
        }

        return best
    }

    static func score(query: String, title: String, aliases: [String], keywords: [String]) -> Double {
        score(
            query: query,
            entity: SearchableEntity.build(displayName: title, aliases: aliases, keywords: keywords)
        ).value
    }

    static func subsequenceTightness(query: String, text: String) -> Double? {
        let needle = Array(query)
        let haystack = Array(text)
        guard !needle.isEmpty, needle.count <= haystack.count else { return nil }
        var i = 0
        var lastIndex = -1
        var consecutive = 0
        for (index, char) in haystack.enumerated() {
            if i < needle.count, char == needle[i] {
                if lastIndex >= 0, index - lastIndex - 1 == 0 { consecutive += 1 }
                lastIndex = index
                i += 1
                if i == needle.count { break }
            }
        }
        guard i == needle.count else { return nil }
        let span = max(lastIndex + 1, 1)
        let density = Double(needle.count) / Double(span)
        let consecutiveBonus = Double(consecutive) / Double(max(needle.count - 1, 1))
        return min(1, density * 0.7 + consecutiveBonus * 0.3)
    }

    private static func prefix(_ base: Double, query: String, target: String) -> Double {
        let tightness = Double(query.count) / Double(max(target.count, 1))
        let brevity = max(0, 1 - Double(target.count) / 24)
        return base + tightness * 50 + brevity * 30
    }
}
