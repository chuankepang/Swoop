import Foundation

struct WebActionConfig: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var aliases: [String]
    var keywords: [String]
    var urlTemplate: String
    var isEnabled: Bool
    var isBuiltIn: Bool
    var placeholder: String?
    var subtitle: String?
    var mark: String?

    var requiresInput: Bool {
        urlTemplate.contains("{key}")
    }

    static func parseAliases(_ text: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for part in text.split(separator: ",") {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            if seen.insert(key).inserted {
                result.append(trimmed)
            }
        }
        return result
    }

    static func aliasesString(_ aliases: [String]) -> String {
        aliases.joined(separator: ", ")
    }
}

struct WebActionOverride: Codable, Equatable {
    var name: String?
    var aliases: [String]?
    var urlTemplate: String?
    var isEnabled: Bool?
}

struct SwoopPreferences: Codable, Equatable {
    var webOverrides: [String: WebActionOverride]
    var customWebActions: [WebActionConfig]
    var preferredBrowser: PreferredBrowser
    var fallbackEngine: FallbackSearchEngine

    static let `default` = SwoopPreferences(
        webOverrides: [:],
        customWebActions: [],
        preferredBrowser: .chromePreferred,
        fallbackEngine: .bing
    )
}

extension Notification.Name {
    static let swoopConfigurationDidChange = Notification.Name("swoop.configurationDidChange")
}
