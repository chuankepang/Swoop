import Foundation

struct SearchResult {
    let actionID: String
    let title: String
    let subtitle: String?
    let score: Double
    let payload: Payload

    enum Payload {
        case action
        case file(url: URL)
        case prompt(text: String)
    }
}

struct RankedAction {
    let actionID: String
    let score: Double
}
