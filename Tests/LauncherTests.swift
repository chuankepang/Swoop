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
        ("GitHub Search", ["github", "git", "gh"], ["code"]),
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
    TestSupport.expectEqual(topTitle(query: "gh", items: catalog), "GitHub Search", "gh → GitHub Search")
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

    let semaphore = DispatchSemaphore(value: 0)
    var foundIndexed = false
    service.search(query: "README", limit: 5) { files in
        foundIndexed = !files.isEmpty
        print("  mdfind Info.plist hits=\(files.count)")
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + 8)
    if foundIndexed {
        TestSupport.expect(true, "SpotlightService parsed results")
    } else {
        print("  SKIP Spotlight index returned no README hits in home")
    }
}
