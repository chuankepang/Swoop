import Foundation

enum TestSupport {
    private(set) static var failures = 0

    static func expect(_ condition: Bool, _ message: String, file: StaticString = #fileID, line: UInt = #line) {
        if !condition {
            failures += 1
            fputs("FAIL \(file):\(line) \(message)\n", stderr)
        }
    }

    static func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String, file: StaticString = #fileID, line: UInt = #line) {
        expect(actual == expected, "\(message) (expected \(expected), got \(actual))", file: file, line: line)
    }
}

func topTitle(query: String, items: [(String, [String], [String])]) -> String? {
    let ranked = items.map { item in
        (item.0, FuzzyMatcher.score(query: query, title: item.0, aliases: item.1, keywords: item.2))
    }
    .filter { $0.1 > 0 }
    .sorted { $0.1 > $1.1 }
    return ranked.first?.0
}

func runFuzzyMatcherTests() {
    let catalog: [(String, [String], [String])] = [
        ("Google Search", ["google", "goo", "go", "gg", "g", "谷歌", "guge"], ["search"]),
        ("Google Chrome", ["chrome", "chr", "gc"], ["app"]),
        ("Google Scholar", ["scholar", "sch", "paper", "学术", "xueshu"], ["papers"]),
        ("GitHub Search", ["github", "git", "gh"], ["code"]),
        ("Bing Search", ["bing", "bin", "bi", "b"], ["search"]),
        ("Lock Screen", ["lock", "loc", "lk", "锁屏", "suoping"], ["security"]),
        ("Find Files", ["find", "fin", "files", "file", "查找"], ["search"]),
        ("Visual Studio Code", ["code", "vscode", "vsc"], ["editor"]),
        ("Terminal", ["term", "tty"], ["app"]),
        ("YouTube Search", ["youtube", "you", "yt"], ["video"]),
        ("微信", ["weixin", "wechat", "wx"], ["app"]),
    ]

    TestSupport.expectEqual(topTitle(query: "go", items: catalog), "Google Search", "go → Google Search")
    TestSupport.expectEqual(topTitle(query: "goo", items: catalog), "Google Search", "goo → Google Search")
    TestSupport.expectEqual(topTitle(query: "gg", items: catalog), "Google Search", "gg → Google Search")
    TestSupport.expectEqual(topTitle(query: "guge", items: catalog), "Google Search", "guge → Google Search")
    TestSupport.expectEqual(topTitle(query: "weixin", items: catalog), "微信", "weixin → 微信")
    TestSupport.expectEqual(topTitle(query: "vsc", items: catalog), "Visual Studio Code", "vsc → Visual Studio Code")
    TestSupport.expectEqual(topTitle(query: "chr", items: catalog), "Google Chrome", "chr → Google Chrome")
    TestSupport.expectEqual(topTitle(query: "loc", items: catalog), "Lock Screen", "loc → Lock Screen")
    TestSupport.expectEqual(topTitle(query: "sch", items: catalog), "Google Scholar", "sch → Google Scholar")
    TestSupport.expectEqual(topTitle(query: "gh", items: catalog), "GitHub Search", "gh → GitHub Search")
    TestSupport.expectEqual(topTitle(query: "fin", items: catalog), "Find Files", "fin → Find Files")
    TestSupport.expectEqual(topTitle(query: "term", items: catalog), "Terminal", "term → Terminal")

    let gooGoogle = FuzzyMatcher.score(query: "goo", title: "Google Search", aliases: ["goo"], keywords: [])
    let gooUnrelated = FuzzyMatcher.score(query: "goo", title: "Preview", aliases: ["preview"], keywords: [])
    TestSupport.expect(gooGoogle > gooUnrelated + 200, "unrelated results should score much lower")
}

func runRankingEngineTests() {
    let exact = RankingEngine.combine(fuzzyScore: RankingWeights.exactAlias, usage: UsageSnapshot(count: 0, lastUsed: nil))
    let weakUsed = RankingEngine.combine(
        fuzzyScore: RankingWeights.subsequence,
        usage: UsageSnapshot(count: 148, lastUsed: Date())
    )
    TestSupport.expect(exact > weakUsed, "exact match should outrank heavy usage of a weak match")

    let unused = RankingEngine.combine(fuzzyScore: RankingWeights.titlePrefix, usage: UsageSnapshot(count: 0, lastUsed: nil))
    let used = RankingEngine.combine(
        fuzzyScore: RankingWeights.titlePrefix,
        usage: UsageSnapshot(count: 20, lastUsed: Date())
    )
    TestSupport.expect(used > unused, "usage should boost otherwise equal matches")

    let ranked = RankingEngine.rank([
        RankedAction(actionID: "b", score: 10),
        RankedAction(actionID: "a", score: 30),
        RankedAction(actionID: "c", score: 30),
    ])
    TestSupport.expectEqual(ranked.map(\.actionID), ["a", "c", "b"], "sort by score then id")
}

func runActionRegistryTests() {
    let registry = ActionRegistry()
    let browser = BrowserLauncher()
    registry.register(WebSearchCatalog.all.map { WebSearchAction(provider: $0, launcher: browser) })
    TestSupport.expect(registry.action(id: "web.google") != nil, "google provider is registered")
    TestSupport.expect(registry.action(id: "web.xiaohongshu") != nil, "xiaohongshu is a configured provider")
    TestSupport.expectEqual(registry.action(id: "web.google")?.requiresInput, true, "web search requires input")

    let lock = SystemAction(
        id: "system.lock",
        title: "Lock Screen",
        aliases: ["lock", "loc"],
        keywords: [],
        icon: nil,
        command: .lockScreen,
        service: SystemActionService()
    )
    registry.register(lock)
    TestSupport.expectEqual(registry.action(id: "system.lock")?.requiresInput, false, "lock does not require input")
}

func runStateMachineTests() {
    var machine = LauncherStateMachine()
    machine.show()
    TestSupport.expectEqual(machine.phase, .actionSelection, "show enters action selection")

    let enterLock = machine.confirm(selectedActionID: "system.lock", requiresInput: false, input: "")
    TestSupport.expectEqual(enterLock, .execute(actionID: "system.lock", input: nil), "lock executes immediately")
    TestSupport.expectEqual(machine.phase, .hidden, "execute hides launcher")

    machine.show()
    let enterGoogle = machine.confirm(selectedActionID: "web.google", requiresInput: true, input: "goo")
    TestSupport.expectEqual(enterGoogle, .none, "google waits for query")
    TestSupport.expectEqual(machine.phase, .awaitingInput(actionID: "web.google"), "enters input stage")
    TestSupport.expectEqual(machine.query, "", "query is cleared for stage 2")

    let execute = machine.confirm(selectedActionID: "web.google", requiresInput: true, input: "robot manipulation")
    TestSupport.expectEqual(execute, .execute(actionID: "web.google", input: "robot manipulation"), "stage 2 executes")

    machine.show()
    _ = machine.confirm(selectedActionID: "web.google", requiresInput: true, input: "")
    let back = machine.cancel()
    TestSupport.expectEqual(back, .none, "esc from input returns to selection")
    TestSupport.expectEqual(machine.phase, .actionSelection, "back to action selection")
    let close = machine.cancel()
    TestSupport.expectEqual(close, .close, "second esc closes")
}

func runURLEncoderTests() {
    let encoded = QueryURLEncoder.encode("机器人 manipulation policy & / ? # +")
    TestSupport.expect(!encoded.contains(" "), "spaces must be encoded")
    TestSupport.expect(!encoded.contains("&"), "ampersand must be encoded")
    TestSupport.expect(!encoded.contains("#"), "hash must be encoded")
    TestSupport.expect(!encoded.contains("+"), "plus must be encoded")
    TestSupport.expect(encoded.contains("%"), "percent-encoding present")
    let url = QueryURLEncoder.url(from: "https://www.google.com/search?q={key}", key: "robot manipulation")
    TestSupport.expectEqual(url?.absoluteString, "https://www.google.com/search?q=robot%20manipulation", "template replacement")
}
