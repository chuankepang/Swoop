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
    var inputConfirmBehavior: InputConfirmBehavior { get }
    var searchEntity: SearchableEntity { get }

    func execute(input: String?)
    func execute(input: String?, completion: @escaping (Error?) -> Void)
    func inputCandidates(query: String, completion: @escaping ([SearchResult]) -> Void)
}

extension LauncherAction {
    var inputConfirmBehavior: InputConfirmBehavior { .execute }

    var searchEntity: SearchableEntity {
        SearchableEntity.build(displayName: title, aliases: aliases, keywords: keywords)
    }

    func execute(input: String?, completion: @escaping (Error?) -> Void) {
        execute(input: input)
        completion(nil)
    }

    func inputCandidates(query: String, completion: @escaping ([SearchResult]) -> Void) {
        completion([])
    }
}
