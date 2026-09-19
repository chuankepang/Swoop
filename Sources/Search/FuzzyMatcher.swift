import Foundation

enum FuzzyMatcher {
    static func score(query rawQuery: String, title: String, aliases: [String], keywords: [String]) -> Double {
        let query = normalize(rawQuery)
        if query.isEmpty { return 0 }

        let titleNorm = normalize(title)
        let words = words(in: titleNorm)
        var best = 0.0

        if titleNorm == query {
            best = max(best, RankingWeights.exactTitle)
        }

        if titleNorm.hasPrefix(query) {
            best = max(best, prefixScore(RankingWeights.titlePrefix, query: query, target: titleNorm))
        }

        if let first = words.first, first.hasPrefix(query) {
            best = max(best, prefixScore(RankingWeights.firstWordPrefix, query: query, target: first))
        }

        for alias in aliases {
            let aliasNorm = normalize(alias)
            guard !aliasNorm.isEmpty else { continue }
            if aliasNorm == query {
                let shortBonus = aliasNorm.count <= 4 ? 20.0 : 0
                best = max(best, RankingWeights.exactAlias + shortBonus)
            } else if aliasNorm.hasPrefix(query) {
                let base = aliasNorm.count <= 6 ? RankingWeights.shortAliasPrefix : RankingWeights.aliasPrefix
                best = max(best, prefixScore(base, query: query, target: aliasNorm))
            }
        }

        if matchesWordInitials(query: query, words: words) {
            best = max(best, RankingWeights.wordInitials + Double(query.count) * 4)
        }

        for word in words {
            if word.hasPrefix(query) {
                best = max(best, prefixScore(RankingWeights.wordPrefix, query: query, target: word))
            }
        }

        for keyword in keywords {
            let keyNorm = normalize(keyword)
            if keyNorm == query {
                best = max(best, RankingWeights.keyword + 40)
            } else if keyNorm.hasPrefix(query) || query.hasPrefix(keyNorm) {
                best = max(best, RankingWeights.keyword)
            }
        }

        if let sub = subsequenceTightness(query: query, text: titleNorm) {
            best = max(best, RankingWeights.subsequence + sub * 120)
        }

        for word in words {
            if let sub = subsequenceTightness(query: query, text: word) {
                best = max(best, RankingWeights.subsequence + sub * 140)
            }
        }

        return best
    }

    static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    static func words(in text: String) -> [String] {
        let scalars = text.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) { return Character(scalar) }
            return " "
        }
        return String(scalars)
            .split(whereSeparator: { $0 == " " })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    static func matchesWordInitials(query: String, words: [String]) -> Bool {
        guard !words.isEmpty else { return false }
        let initials = words.compactMap { $0.first }.map { String($0) }.joined()
        if initials.hasPrefix(query) || initials == query { return true }

        var remaining = Array(query)
        for word in words {
            guard let first = remaining.first, word.first == first else { continue }
            remaining.removeFirst()
            if remaining.isEmpty { return true }
        }
        return remaining.isEmpty && query.count >= 2
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

    private static func prefixScore(_ base: Double, query: String, target: String) -> Double {
        let tightness = Double(query.count) / Double(max(target.count, 1))
        let brevity = max(0, 1 - Double(target.count) / 24)
        return base + tightness * 50 + brevity * 30
    }
}
