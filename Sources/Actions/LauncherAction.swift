import AppKit

protocol LauncherAction: AnyObject {
    var id: String { get }
    var title: String { get }
    var aliases: [String] { get }
    var keywords: [String] { get }
    var kind: ActionKind { get }
    var icon: NSImage? { get }
    var requiresInput: Bool { get }
    var inputPlaceholder: String? { get }
    var presentsCandidatesDuringInput: Bool { get }

    func execute(input: String?)
    func inputCandidates(query: String, completion: @escaping ([SearchResult]) -> Void)
}

extension LauncherAction {
    var presentsCandidatesDuringInput: Bool { false }

    func inputCandidates(query: String, completion: @escaping ([SearchResult]) -> Void) {
        completion([])
    }
}
