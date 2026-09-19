import AppKit

final class FileSearchAction: LauncherAction {
    let id = "files.find"
    let title = "Find Files"
    let aliases = ["find", "fin", "files", "file", "mdfind", "spotlight", "查找", "文件", "chazhao", "wenjian"]
    let keywords = ["search", "documents"]
    let kind: ActionKind = .fileSearch
    let requiresInput = true
    let inputPlaceholder: String? = "Search files..."
    let presentsCandidatesDuringInput = true
    lazy var icon: NSImage? = ActionIconFactory.brand(.files)
    private let spotlight: SpotlightService

    init(spotlight: SpotlightService) {
        self.spotlight = spotlight
    }

    func execute(input: String?) {
        guard let input, !input.isEmpty else { return }
        spotlight.search(query: input) { results in
            guard let first = results.first else { return }
            NSWorkspace.shared.open(first.url)
        }
    }

    func inputCandidates(query: String, completion: @escaping ([SearchResult]) -> Void) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 1 else {
            completion([])
            return
        }
        spotlight.search(query: trimmed) { files in
            let results = files.enumerated().map { index, file in
                SearchResult(
                    actionID: self.id,
                    title: file.name,
                    subtitle: file.url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"),
                    score: 900 - Double(index),
                    payload: .file(url: file.url)
                )
            }
            completion(results)
        }
    }
}
