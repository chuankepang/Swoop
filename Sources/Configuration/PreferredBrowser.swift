import Foundation

enum PreferredBrowser: String, Codable, CaseIterable {
    case chromePreferred
    case systemDefault

    var title: String {
        switch self {
        case .chromePreferred: return "Google Chrome (preferred)"
        case .systemDefault: return "System Default"
        }
    }
}

enum FallbackSearchEngine: String, Codable, CaseIterable {
    case bing
    case google

    var title: String {
        switch self {
        case .bing: return "Bing"
        case .google: return "Google"
        }
    }

    var actionID: String {
        switch self {
        case .bing: return "web.bing"
        case .google: return "web.google"
        }
    }
}
