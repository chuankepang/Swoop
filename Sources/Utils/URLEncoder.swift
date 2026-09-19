import Foundation

enum QueryURLEncoder {
    private static let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))

    static func encode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }

    static func url(from template: String, key: String) -> URL? {
        let encoded = encode(key)
        let filled = template.replacingOccurrences(of: "{key}", with: encoded)
        return URL(string: filled)
    }

    static func validateTemplate(_ template: String) -> Bool {
        let sample = "test-query"
        let candidate: URL?
        if template.contains("{key}") {
            candidate = url(from: template, key: sample)
        } else {
            candidate = URL(string: template)
        }
        guard let url = candidate, let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
}
