import AppKit

final class FileSearchAction: LauncherAction {
    let id = "files.find"
    let title = "Find Files"
    let aliases = ["find", "fin", "files", "file", "mdfind", "spotlight", "查找", "文件"]
    let keywords = ["search", "documents"]
    let kind: ActionKind = .fileSearch
    let requiresInput = true
    let inputPlaceholder: String? = "Search files..."
    let inputConfirmBehavior: InputConfirmBehavior = .searchThenBrowse
    lazy var icon: NSImage? = IconProvider.brand(.files)
    lazy var searchEntity: SearchableEntity = SearchableEntity.build(
        displayName: title,
        aliases: aliases,
        keywords: keywords
    )
    private let spotlight: SpotlightService

    init(spotlight: SpotlightService) {
        self.spotlight = spotlight
    }

    func execute(input: String?) {
        DebugLog.fileSearch("execute() is not used for Find Files; browse phase opens URLs")
        _ = input
    }

    func searchFiles(query: String, completion: @escaping ([SearchResult]) -> Void) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion([])
            return
        }
        spotlight.search(query: trimmed) { files in
            DebugLog.fileSearch("Query: \(trimmed)")
            let ranked = Self.rank(files, query: trimmed)
            DebugLog.fileSearch("Parsed result count: \(ranked.count)")
            completion(ranked)
        }
    }

    func inputCandidates(query: String, completion: @escaping ([SearchResult]) -> Void) {
        searchFiles(query: query, completion: completion)
    }

    static func rank(_ files: [SpotlightFile], query: String) -> [SearchResult] {
        let normalizedQuery = SearchNormalizer.normalize(query)
        return files.map { file -> SearchResult in
            let name = SearchNormalizer.normalize(file.name)
            var score = 200.0
            if name == normalizedQuery {
                score = 1000
            } else if name.hasPrefix(normalizedQuery) {
                score = 800
            } else if let tightness = FuzzyMatcher.subsequenceTightness(query: SearchNormalizer.compact(normalizedQuery), text: SearchNormalizer.compact(name)) {
                score = 400 + tightness * 200
            }
            let home = NSHomeDirectory()
            let subtitle = file.url.path.replacingOccurrences(of: home, with: "~")
            return SearchResult(
                actionID: "files.find",
                title: file.name,
                subtitle: subtitle,
                score: score,
                payload: .file(url: file.url),
                matchReason: "filename"
            )
        }
        .sorted { $0.score > $1.score }
    }
}
