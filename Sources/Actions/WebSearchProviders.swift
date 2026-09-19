import Foundation

struct WebSearchProvider {
    let id: String
    let title: String
    let aliases: [String]
    let keywords: [String]
    let urlTemplate: String
    let mark: BrandMark
    let placeholder: String
}

enum WebSearchCatalog {
    static let all: [WebSearchProvider] = [
        WebSearchProvider(
            id: "google",
            title: "Google Search",
            aliases: ["google", "goo", "go", "gg", "g", "谷歌", "guge"],
            keywords: ["search", "web", "sousuo"],
            urlTemplate: "https://www.google.com/search?q={key}",
            mark: .google,
            placeholder: "Search Google..."
        ),
        WebSearchProvider(
            id: "bing",
            title: "Bing Search",
            aliases: ["bing", "bin", "bi", "b"],
            keywords: ["search", "web"],
            urlTemplate: "https://www.bing.com/search?q={key}",
            mark: .bing,
            placeholder: "Search Bing..."
        ),
        WebSearchProvider(
            id: "github",
            title: "GitHub Search",
            aliases: ["ghs", "gitsearch", "githubsearch", "search github", "git search"],
            keywords: ["code", "repo"],
            urlTemplate: "https://github.com/search?q={key}",
            mark: .github,
            placeholder: "Search GitHub..."
        ),
        WebSearchProvider(
            id: "youtube",
            title: "YouTube Search",
            aliases: ["youtube", "you", "yt"],
            keywords: ["video"],
            urlTemplate: "https://www.youtube.com/results?search_query={key}",
            mark: .youtube,
            placeholder: "Search YouTube..."
        ),
        WebSearchProvider(
            id: "scholar",
            title: "Google Scholar",
            aliases: ["scholar", "sch", "paper", "学术", "xueshu"],
            keywords: ["papers", "research"],
            urlTemplate: "https://scholar.google.com/scholar?q={key}",
            mark: .scholar,
            placeholder: "Search Google Scholar..."
        ),
        WebSearchProvider(
            id: "arxiv",
            title: "arXiv Search",
            aliases: ["arxiv", "arx"],
            keywords: ["papers", "preprint"],
            urlTemplate: "https://arxiv.org/search/?query={key}&searchtype=all",
            mark: .arxiv,
            placeholder: "Search arXiv..."
        ),
        WebSearchProvider(
            id: "xiaohongshu",
            title: "Xiaohongshu Search",
            aliases: ["xiaohongshu", "xhs", "red", "红书", "小红书", "hongshu"],
            keywords: ["notes", "social"],
            urlTemplate: "https://www.xiaohongshu.com/search_result?keyword={key}",
            mark: .xiaohongshu,
            placeholder: "Search Xiaohongshu..."
        ),
    ]
}
