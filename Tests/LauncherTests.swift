import AppKit

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
        ("Google Search", ["google", "goo", "go", "gg", "g", "谷歌"], ["search"]),
        ("Google Chrome", ["chrome", "chr", "gc"], ["app"]),
        ("Google Scholar", ["scholar", "sch", "paper", "学术"], ["papers"]),
        ("GitHub Search", ["ghs", "gitsearch", "githubsearch"], ["code"]),
        ("GitHub", ["github", "gh", "ghome"], ["code"]),
        ("ChatGPT", ["chatgpt", "chat", "gpt", "cg"], ["ai"]),
        ("Bing Search", ["bing", "bin", "bi", "b"], ["search"]),
        ("Lock Screen", ["lock", "loc", "lk", "锁屏"], ["security"]),
        ("Find Files", ["find", "fin", "files", "file", "查找"], ["search"]),
        ("Visual Studio Code", ["code", "vscode", "vsc"], ["editor"]),
        ("Terminal", ["term", "tty"], ["app"]),
        ("YouTube Search", ["youtube", "you", "yt"], ["video"]),
    ]

    TestSupport.expectEqual(topTitle(query: "goo", items: catalog), "Google Search", "goo → Google Search")
    TestSupport.expectEqual(topTitle(query: "gg", items: catalog), "Google Search", "gg → Google Search")
    TestSupport.expectEqual(topTitle(query: "vsc", items: catalog), "Visual Studio Code", "vsc → Visual Studio Code")
    TestSupport.expectEqual(topTitle(query: "chr", items: catalog), "Google Chrome", "chr → Google Chrome")
    TestSupport.expectEqual(topTitle(query: "loc", items: catalog), "Lock Screen", "loc → Lock Screen")
    TestSupport.expectEqual(topTitle(query: "sch", items: catalog), "Google Scholar", "sch → Google Scholar")
    TestSupport.expectEqual(topTitle(query: "gh", items: catalog), "GitHub", "gh → GitHub shortcut")
    TestSupport.expectEqual(topTitle(query: "ghs", items: catalog), "GitHub Search", "ghs → GitHub Search")
    TestSupport.expectEqual(topTitle(query: "chat", items: catalog), "ChatGPT", "chat → ChatGPT")
    TestSupport.expectEqual(topTitle(query: "fin", items: catalog), "Find Files", "fin → Find Files")

    let wechat = SearchableEntity.build(displayName: "WeChat", names: ["WeChat", "微信"], aliases: [], keywords: ["app"])
    TestSupport.expect(FuzzyMatcher.score(query: "wechat", entity: wechat).value > 800, "wechat → WeChat")
    TestSupport.expect(FuzzyMatcher.score(query: "微信", entity: wechat).value > 800, "微信 → WeChat")
    TestSupport.expect(FuzzyMatcher.score(query: "weixin", entity: wechat).value > 700, "weixin → WeChat")
}

func runSearchNormalizationTests() {
    TestSupport.expectEqual(SearchNormalizer.normalize("  Visual-Studio  Code "), "visual studio code", "punctuation collapsed")
    TestSupport.expectEqual(SearchNormalizer.compact("wei xin"), "weixin", "compact pinyin")
}

func runPinyinMatchingTests() {
    func compactPinyin(_ text: String) -> String {
        SearchNormalizer.compact(SearchNormalizer.normalize(Transliterator.mandarinLatin(text)))
    }
    TestSupport.expectEqual(compactPinyin("微信"), "weixin", "微信 → weixin")
    TestSupport.expectEqual(compactPinyin("文件"), "wenjian", "文件 → wenjian")
    TestSupport.expectEqual(compactPinyin("设置"), "shezhi", "设置 → shezhi")
    TestSupport.expect(compactPinyin("音乐").hasPrefix("yin"), "音乐 pinyin is latinized")

    let files = SearchableEntity.build(displayName: "Find Files", aliases: ["查找", "文件"], keywords: [])
    TestSupport.expect(FuzzyMatcher.score(query: "wenjian", entity: files).value > 500, "wenjian matches 文件 alias")
}

func runRankingEngineTests() {
    let exact = RankingEngine.combine(fuzzyScore: RankingWeights.exactAlias, usage: UsageSnapshot(count: 0, lastUsed: nil))
    let weakUsed = RankingEngine.combine(
        fuzzyScore: RankingWeights.subsequence,
        usage: UsageSnapshot(count: 148, lastUsed: Date())
    )
    TestSupport.expect(exact > weakUsed, "exact match should outrank heavy usage of a weak match")

    let ranked = RankingEngine.rank([
        RankedAction(actionID: "b", score: 10, reason: "x"),
        RankedAction(actionID: "a", score: 30, reason: "x"),
        RankedAction(actionID: "c", score: 30, reason: "x"),
    ])
    TestSupport.expectEqual(ranked.map(\.actionID), ["a", "c", "b"], "sort by score then id")
}

func runActionRegistryTests() {
    let registry = ActionRegistry()
    let browser = BrowserLauncher()
    registry.register(WebSearchCatalog.all.map { WebSearchAction(provider: $0, launcher: browser) })
    TestSupport.expect(registry.action(id: "web.google") != nil, "google provider is registered")
    TestSupport.expectEqual(registry.action(id: "web.google")?.requiresInput, true, "web search requires input")
}

func runStateMachineTests() {
    var machine = LauncherStateMachine()
    machine.show()
    TestSupport.expectEqual(machine.phase, .actionSelection, "show enters action selection")

    let enterLock = machine.confirm(selectedActionID: "system.lock", requiresInput: false, inputConfirm: .execute, input: "")
    TestSupport.expectEqual(enterLock, .execute(actionID: "system.lock", input: nil), "lock executes immediately")

    machine.show()
    let enterGoogle = machine.confirm(selectedActionID: "web.google", requiresInput: true, inputConfirm: .execute, input: "goo")
    TestSupport.expectEqual(enterGoogle, .none, "google waits for query")
    TestSupport.expectEqual(machine.phase, .awaitingInput(actionID: "web.google"), "enters input stage")

    let execute = machine.confirm(selectedActionID: "web.google", requiresInput: true, inputConfirm: .execute, input: "robot manipulation")
    TestSupport.expectEqual(execute, .execute(actionID: "web.google", input: "robot manipulation"), "stage 2 executes")

    machine.show()
    _ = machine.confirm(selectedActionID: "files.find", requiresInput: true, inputConfirm: .searchThenBrowse, input: "")
    let search = machine.confirm(selectedActionID: "files.find", requiresInput: true, inputConfirm: .searchThenBrowse, input: "root.tex")
    TestSupport.expectEqual(search, .searchFiles(actionID: "files.find", query: "root.tex"), "file enter searches")
    TestSupport.expectEqual(machine.phase, .browsingFiles(actionID: "files.find"), "file results phase")
    TestSupport.expectEqual(machine.confirm(selectedActionID: "files.find", requiresInput: true, inputConfirm: .searchThenBrowse, input: "root.tex"), .openFile, "second enter opens")

    _ = machine.cancel()
    TestSupport.expectEqual(machine.phase, .awaitingInput(actionID: "files.find"), "esc from results returns to query")
    _ = machine.cancel()
    TestSupport.expectEqual(machine.phase, .actionSelection, "esc from input returns to selection")
    TestSupport.expectEqual(machine.cancel(), .close, "esc from selection hides")
}

func runURLEncoderTests() {
    let url = QueryURLEncoder.url(from: "https://www.google.com/search?q={key}", key: "robot manipulation")
    TestSupport.expectEqual(url?.absoluteString, "https://www.google.com/search?q=robot%20manipulation", "template replacement")
}

func makeTestRegistry() -> ActionRegistry {
    let registry = ActionRegistry()
    let browser = BrowserLauncher()
    registry.register(WebSearchCatalog.all.map { WebSearchAction(provider: $0, launcher: browser) })
    registry.register(WebShortcutCatalog.all.map { WebShortcutAction(provider: $0, launcher: browser) })
    registry.register(TranslationCatalog.all.map { TranslationAction(provider: $0, launcher: browser) })
    registry.register(FileSearchAction(spotlight: SpotlightService()))
    return registry
}

func runSearchFallbackTests() {
    let registry = makeTestRegistry()
    let defaults = UserDefaults(suiteName: "local.swoop.tests.fallback")!
    defaults.removePersistentDomain(forName: "local.swoop.tests.fallback")
    let history = UsageHistory(defaults: defaults)
    let placeholder = NSImage(size: NSSize(width: 64, height: 64))
    registry.register(ApplicationAction(app: InstalledApp(
        displayName: "Google Chrome",
        names: ["Google Chrome", "Chrome"],
        bundleIdentifier: "com.google.Chrome",
        url: URL(fileURLWithPath: "/Applications/Google Chrome.app"),
        icon: placeholder
    )))
    registry.register(ApplicationAction(app: InstalledApp(
        displayName: "WeChat",
        names: ["WeChat", "微信"],
        bundleIdentifier: "com.tencent.xinWeChat",
        url: URL(fileURLWithPath: "/Applications/WeChat.app"),
        icon: placeholder
    )))
    let engine = SearchEngine(registry: registry, history: history)

    func first(_ query: String) -> SearchResult? {
        engine.searchActions(query: query).first
    }

    func isFallback(_ result: SearchResult?) -> Bool {
        guard let result, case .immediate(let actionID, let input) = result.payload else { return false }
        return actionID == "web.bing" && input == result.subtitle
    }

    TestSupport.expectEqual(first("chr")?.title, "Google Chrome", "chr → Chrome over Bing")
    TestSupport.expect(!isFallback(first("chr")), "chr is not fallback")
    TestSupport.expectEqual(first("goo")?.title, "Google Search", "goo → Google Search over Bing")
    TestSupport.expectEqual(first("wechat")?.title, "WeChat", "wechat → WeChat")
    TestSupport.expectEqual(first("weixin")?.title, "WeChat", "weixin → WeChat")
    TestSupport.expectEqual(first("微信")?.title, "WeChat", "微信 → WeChat")
    TestSupport.expect(isFallback(first("键盘")), "键盘 → Bing fallback first")
    TestSupport.expectEqual(first("键盘")?.title, "Search Bing", "fallback title")
    TestSupport.expectEqual(first("键盘")?.subtitle, "键盘", "fallback subtitle is query")
    TestSupport.expect(isFallback(first("abcdefghijklmnop_unique")), "unknown query → Bing fallback")
    TestSupport.expectEqual(first("fin")?.title, "Find Files", "fin → Find Files")

    let empty = engine.searchActions(query: "   ")
    TestSupport.expect(!empty.contains(where: { isFallback($0) }), "blank query must not Bing-search")
    TestSupport.expect(!empty.isEmpty, "blank query still shows recents/defaults")
}

func runSpotlightQueryTests() {
    let predicate = SpotlightService.filenamePredicate("root.tex")
    TestSupport.expect(predicate.contains("kMDItemFSName"), "filename metadata query")
    TestSupport.expect(predicate.contains("root.tex"), "query embedded")
    let quoted = SpotlightService.filenamePredicate(#"a"b"#)
    TestSupport.expect(quoted.contains(#"\""#), "quotes escaped for mdfind")
    TestSupport.expect(SpotlightService.filenamePredicate("论文").contains("论文"), "UTF-8 filename query")
}

func runWebShortcutTests() {
    let registry = makeTestRegistry()
    let defaults = UserDefaults(suiteName: "local.swoop.tests.shortcuts")!
    defaults.removePersistentDomain(forName: "local.swoop.tests.shortcuts")
    let engine = SearchEngine(registry: registry, history: UsageHistory(defaults: defaults))

    func first(_ query: String) -> SearchResult? {
        engine.searchActions(query: query).first
    }

    TestSupport.expectEqual(first("chat")?.title, "ChatGPT", "chat → ChatGPT")
    TestSupport.expectEqual(first("grok")?.title, "Grok", "grok → Grok")
    TestSupport.expectEqual(first("gem")?.title, "Gemini", "gem → Gemini")
    TestSupport.expectEqual(first("bili")?.title, "Bilibili", "bili → Bilibili")
    TestSupport.expectEqual(first("dou")?.title, "Douyin", "dou → Douyin")
    TestSupport.expectEqual(first("github")?.title, "GitHub", "github → GitHub home")
    TestSupport.expectEqual(registry.action(id: "shortcut.chatgpt")?.requiresInput, false, "ChatGPT is immediate")
}

func runTranslationURLTests() {
    let zhURL = QueryURLEncoder.url(from: "https://fanyi.baidu.com/#zh/en/{key}", key: "键盘")
    TestSupport.expectEqual(zhURL?.absoluteString, "https://fanyi.baidu.com/#zh/en/%E9%94%AE%E7%9B%98", "zh→en URL")
    let enURL = QueryURLEncoder.url(from: "https://fanyi.baidu.com/#en/zh/{key}", key: "robot manipulation policy")
    TestSupport.expectEqual(enURL?.absoluteString, "https://fanyi.baidu.com/#en/zh/robot%20manipulation%20policy", "en→zh URL")

    let registry = makeTestRegistry()
    let defaults = UserDefaults(suiteName: "local.swoop.tests.translate")!
    defaults.removePersistentDomain(forName: "local.swoop.tests.translate")
    let engine = SearchEngine(registry: registry, history: UsageHistory(defaults: defaults))
    TestSupport.expectEqual(engine.searchActions(query: "zh2en").first?.title, "Translate ZH → EN", "zh2en alias")
    TestSupport.expectEqual(engine.searchActions(query: "en2zh").first?.title, "Translate EN → ZH", "en2zh alias")
    TestSupport.expectEqual(engine.searchActions(query: "中译英").first?.title, "Translate ZH → EN", "中译英 alias")
    TestSupport.expectEqual(registry.action(id: "translate.zh2en")?.requiresInput, true, "translation requires input")

    let zhIcon = TranslationCatalog.all.first(where: { $0.id == "zh2en" })?.mark
    let enIcon = TranslationCatalog.all.first(where: { $0.id == "en2zh" })?.mark
    TestSupport.expectEqual(zhIcon, .baiduZhEn, "zh2en uses direction icon")
    TestSupport.expectEqual(enIcon, .baiduEnZh, "en2zh uses direction icon")
    TestSupport.expect(zhIcon != enIcon, "translation marks differ")
}

func runFileSearchTests() {
    let files = [
        SpotlightFile(name: "root.tex", url: URL(fileURLWithPath: "/Users/demo/Project/root.tex")),
        SpotlightFile(name: "notes.root.tex.bak", url: URL(fileURLWithPath: "/tmp/notes.root.tex.bak")),
        SpotlightFile(name: "other.txt", url: URL(fileURLWithPath: "/tmp/other.txt")),
    ]
    let ranked = FileSearchAction.rank(files, query: "root.tex")
    TestSupport.expectEqual(ranked.first?.title, "root.tex", "exact filename ranks first")
}

func runApplicationIndexTests() {
    let index = ApplicationIndex()
    let apps = index.scanNow()
    TestSupport.expect(apps.contains(where: { $0.bundleIdentifier == "com.apple.finder" || $0.displayName == "Finder" }), "Finder is indexed")
    if let chrome = apps.first(where: { $0.displayName.localizedCaseInsensitiveContains("Chrome") }) {
        TestSupport.expect(!chrome.url.path.isEmpty, "Chrome has bundle URL")
    }
}

func runApplicationLaunchMatrix() {
    let targets: [(String, String)] = [
        ("Finder", "com.apple.finder"),
        ("Safari", "com.apple.Safari"),
        ("Terminal", "com.apple.Terminal"),
        ("Google Chrome", "com.google.Chrome"),
        ("Visual Studio Code", "com.microsoft.VSCode"),
        ("WeChat", "com.tencent.xinWeChat"),
        ("Preview", "com.apple.Preview"),
        ("System Settings", "com.apple.systempreferences"),
    ]
    print("Application launch matrix:")
    for (name, bundleID) in targets {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            print("  FOUND \(name) \(bundleID) \(url.path)")
            TestSupport.expect(FileManager.default.fileExists(atPath: url.path), "\(name) bundle exists")
        } else {
            print("  SKIP \(name) \(bundleID)")
        }
    }
}

func runFileSearchIntegrationTests() {
    let service = SpotlightService()
    let unique = "swoop_audit_\(Int(Date().timeIntervalSince1970)).txt"
    let path = NSTemporaryDirectory() + unique
    FileManager.default.createFile(atPath: path, contents: Data("swoop".utf8))
    print("File search: created \(path). New files may not be in Spotlight yet.")

    var files: [SpotlightFile] = []
    service.search(query: "README", limit: 5) { result in
        files = result
        print("  mdfind README hits=\(result.count)")
    }
    let deadline = Date().addingTimeInterval(8)
    while files.isEmpty && Date() < deadline {
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
    if files.isEmpty {
        print("  SKIP Spotlight index returned no README hits in home")
    } else {
        TestSupport.expect(files.contains(where: { $0.name.localizedCaseInsensitiveContains("readme") || $0.url.path.contains("README") }), "README filename results")
    }
}
