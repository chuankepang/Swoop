import Foundation

struct WebShortcutProvider {
    let id: String
    let title: String
    let aliases: [String]
    let keywords: [String]
    let url: URL
    let mark: BrandMark
}

enum WebShortcutCatalog {
    static let all: [WebShortcutProvider] = [
        WebShortcutProvider(
            id: "chatgpt",
            title: "ChatGPT",
            aliases: ["chatgpt", "chat", "gpt", "openai", "cg"],
            keywords: ["ai", "assistant"],
            url: URL(string: "https://chatgpt.com/")!,
            mark: .chatgpt
        ),
        WebShortcutProvider(
            id: "grok",
            title: "Grok",
            aliases: ["grok", "xai", "x ai"],
            keywords: ["ai", "assistant"],
            url: URL(string: "https://grok.com/")!,
            mark: .grok
        ),
        WebShortcutProvider(
            id: "gemini",
            title: "Gemini",
            aliases: ["gemini", "gem", "google ai"],
            keywords: ["ai", "assistant"],
            url: URL(string: "https://gemini.google.com/")!,
            mark: .gemini
        ),
        WebShortcutProvider(
            id: "bilibili",
            title: "Bilibili",
            aliases: ["bilibili", "bili", "b站", "哔哩哔哩"],
            keywords: ["video", "web"],
            url: URL(string: "https://www.bilibili.com/")!,
            mark: .bilibili
        ),
        WebShortcutProvider(
            id: "douyin",
            title: "Douyin",
            aliases: ["douyin", "dy", "抖音"],
            keywords: ["video", "web"],
            url: URL(string: "https://www.douyin.com/")!,
            mark: .douyin
        ),
        WebShortcutProvider(
            id: "github",
            title: "GitHub",
            aliases: ["github", "ghome", "github home", "gh"],
            keywords: ["code", "repo", "web"],
            url: URL(string: "https://github.com/")!,
            mark: .github
        ),
    ]
}
