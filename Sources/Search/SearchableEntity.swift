import Foundation

enum Transliterator {
    static func mandarinLatin(_ text: String) -> String {
        let mutable = NSMutableString(string: text)
        CFStringTransform(mutable, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false)
        return String(mutable)
    }

    static func hasCJK(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            let v = scalar.value
            return (0x4E00...0x9FFF).contains(v)
                || (0x3400...0x4DBF).contains(v)
                || (0xF900...0xFAFF).contains(v)
        }
    }
}

struct SearchableEntity: Equatable {
    let displayName: String
    let aliases: [String]
    let keywords: [String]
    let terms: [String]
    let initials: [String]

    static func build(displayName: String, names: [String] = [], aliases: [String] = [], keywords: [String] = []) -> SearchableEntity {
        var raw = Set<String>()
        ([displayName] + names + aliases).forEach { raw.insert($0) }

        var terms = Set<String>()
        var initials = Set<String>()
        for item in raw where !item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let variants = expand(item)
            variants.terms.forEach { terms.insert($0) }
            variants.initials.forEach { initials.insert($0) }
        }
        return SearchableEntity(
            displayName: displayName,
            aliases: aliases,
            keywords: keywords.map(SearchNormalizer.normalize).filter { !$0.isEmpty },
            terms: Array(terms),
            initials: Array(initials)
        )
    }

    private static func expand(_ value: String) -> (terms: [String], initials: [String]) {
        var terms: [String] = []
        var initials: [String] = []
        let normalized = SearchNormalizer.normalize(value)
        if !normalized.isEmpty {
            terms.append(normalized)
            terms.append(SearchNormalizer.compact(normalized))
            let words = SearchNormalizer.words(normalized)
            if let joined = SearchNormalizer.initials(words) {
                initials.append(joined)
            }
        }
        if Transliterator.hasCJK(value) {
            let latin = SearchNormalizer.normalize(Transliterator.mandarinLatin(value))
            if !latin.isEmpty {
                terms.append(latin)
                terms.append(SearchNormalizer.compact(latin))
                let syllables = SearchNormalizer.words(latin)
                if let joined = SearchNormalizer.initials(syllables) {
                    initials.append(joined)
                }
            }
        }
        return (terms, initials)
    }
}

enum SearchNormalizer {
    static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[\\p{Punct}]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func compact(_ value: String) -> String {
        value.replacingOccurrences(of: " ", with: "")
    }

    static func words(_ value: String) -> [String] {
        value.split(whereSeparator: { $0.isWhitespace }).map(String.init).filter { !$0.isEmpty }
    }

    static func initials(_ words: [String]) -> String? {
        guard words.count >= 2 else { return words.first.map { String($0.prefix(1)) } }
        let joined = words.compactMap { $0.first }.map(String.init).joined()
        return joined.isEmpty ? nil : joined
    }
}
