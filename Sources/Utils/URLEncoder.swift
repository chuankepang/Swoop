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
}
