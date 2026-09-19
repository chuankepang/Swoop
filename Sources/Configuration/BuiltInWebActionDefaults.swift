import Foundation

struct BuiltInWebActionDefinition: Equatable {
    let id: String
    let name: String
    let aliases: [String]
    let keywords: [String]
    let urlTemplate: String
    let mark: BrandMark?
    let placeholder: String?
    let subtitle: String?

    func asConfig() -> WebActionConfig {
        WebActionConfig(
            id: id,
            name: name,
            aliases: aliases,
            keywords: keywords,
            urlTemplate: urlTemplate,
            isEnabled: true,
            isBuiltIn: true,
            placeholder: placeholder,
            subtitle: subtitle,
            mark: mark?.rawValue
        )
    }
}

enum BuiltInWebActionDefaults {
    static let all: [BuiltInWebActionDefinition] = searchActions + shortcutActions + translationActions

    private static let searchActions: [BuiltInWebActionDefinition] = [
        BuiltInWebActionDefinition(
            id: "web.google",
            name: "Google Search",
            aliases: ["google", "goo", "go", "gg", "g", "谷歌", "guge"],
            keywords: ["search", "web", "sousuo"],
            urlTemplate: "https://www.google.com/search?q={key}",
            mark: .google,
            placeholder: "Search Google...",
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "web.bing",
            name: "Bing Search",
            aliases: ["bing", "bin", "bi", "b"],
            keywords: ["search", "web"],
            urlTemplate: "https://www.bing.com/search?q={key}",
            mark: .bing,
            placeholder: "Search Bing...",
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "web.github",
            name: "GitHub Search",
            aliases: ["ghs", "gitsearch", "githubsearch", "search github", "git search"],
            keywords: ["code", "repo"],
            urlTemplate: "https://github.com/search?q={key}",
            mark: .github,
            placeholder: "Search GitHub...",
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "web.youtube",
            name: "YouTube Search",
            aliases: ["youtube", "you", "yt"],
            keywords: ["video"],
            urlTemplate: "https://www.youtube.com/results?search_query={key}",
            mark: .youtube,
            placeholder: "Search YouTube...",
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "web.scholar",
            name: "Google Scholar",
            aliases: ["scholar", "sch", "paper", "学术", "xueshu"],
            keywords: ["papers", "research"],
            urlTemplate: "https://scholar.google.com/scholar?q={key}",
            mark: .scholar,
            placeholder: "Search Google Scholar...",
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "web.arxiv",
            name: "arXiv Search",
            aliases: ["arxiv", "arx"],
            keywords: ["papers", "preprint"],
            urlTemplate: "https://arxiv.org/search/?query={key}&searchtype=all",
            mark: .arxiv,
            placeholder: "Search arXiv...",
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "web.xiaohongshu",
            name: "Xiaohongshu Search",
            aliases: ["xiaohongshu", "xhs", "red", "红书", "小红书", "hongshu"],
            keywords: ["notes", "social"],
            urlTemplate: "https://www.xiaohongshu.com/search_result?keyword={key}",
            mark: .xiaohongshu,
            placeholder: "Search Xiaohongshu...",
            subtitle: nil
        ),
    ]

    private static let shortcutActions: [BuiltInWebActionDefinition] = [
        BuiltInWebActionDefinition(
            id: "shortcut.chatgpt",
            name: "ChatGPT",
            aliases: ["chatgpt", "chat", "gpt", "openai", "cg"],
            keywords: ["ai", "assistant"],
            urlTemplate: "https://chatgpt.com/",
            mark: .chatgpt,
            placeholder: nil,
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "shortcut.grok",
            name: "Grok",
            aliases: ["grok", "xai", "x ai"],
            keywords: ["ai", "assistant"],
            urlTemplate: "https://grok.com/",
            mark: .grok,
            placeholder: nil,
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "shortcut.gemini",
            name: "Gemini",
            aliases: ["gemini", "gem", "google ai"],
            keywords: ["ai", "assistant"],
            urlTemplate: "https://gemini.google.com/",
            mark: .gemini,
            placeholder: nil,
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "shortcut.bilibili",
            name: "Bilibili",
            aliases: ["bilibili", "bili", "b站", "哔哩哔哩"],
            keywords: ["video", "web"],
            urlTemplate: "https://www.bilibili.com/",
            mark: .bilibili,
            placeholder: nil,
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "shortcut.douyin",
            name: "Douyin",
            aliases: ["douyin", "dy", "抖音"],
            keywords: ["video", "web"],
            urlTemplate: "https://www.douyin.com/",
            mark: .douyin,
            placeholder: nil,
            subtitle: nil
        ),
        BuiltInWebActionDefinition(
            id: "shortcut.github",
            name: "GitHub",
            aliases: ["github", "ghome", "github home", "gh"],
            keywords: ["code", "repo", "web"],
            urlTemplate: "https://github.com/",
            mark: .github,
            placeholder: nil,
            subtitle: nil
        ),
    ]

    private static let translationActions: [BuiltInWebActionDefinition] = [
        BuiltInWebActionDefinition(
            id: "translate.zh2en",
            name: "Translate ZH → EN",
            aliases: ["zh2en", "zhen", "中英", "中译英", "翻译英文", "translate english", "fyen"],
            keywords: ["translate", "fanyi", "baidu"],
            urlTemplate: "https://fanyi.baidu.com/#zh/en/{key}",
            mark: .baiduZhEn,
            placeholder: "Translate Chinese to English...",
            subtitle: "Baidu Translate"
        ),
        BuiltInWebActionDefinition(
            id: "translate.en2zh",
            name: "Translate EN → ZH",
            aliases: ["en2zh", "enzh", "英中", "英译中", "翻译中文", "translate chinese", "fyzh"],
            keywords: ["translate", "fanyi", "baidu"],
            urlTemplate: "https://fanyi.baidu.com/#en/zh/{key}",
            mark: .baiduEnZh,
            placeholder: "Translate English to Chinese...",
            subtitle: "Baidu Translate"
        ),
    ]

    static func definition(for id: String) -> BuiltInWebActionDefinition? {
        all.first { $0.id == id }
    }

    static func brandMark(for actionID: String) -> BrandMark? {
        definition(for: actionID)?.mark
            ?? (actionID.hasPrefix("custom.") ? nil : nil)
    }
}
