import AppKit

final class ActionRegistry {
    private var actions: [String: any LauncherAction] = [:]
    private(set) var ordered: [any LauncherAction] = []

    private static let webPrefixes = ["web.", "shortcut.", "translate.", "custom."]

    func register(_ action: any LauncherAction) {
        actions[action.id] = action
        if !ordered.contains(where: { $0.id == action.id }) {
            ordered.append(action)
        }
    }

    func register(_ items: [any LauncherAction]) {
        items.forEach(register)
    }

    func action(id: String) -> (any LauncherAction)? {
        actions[id]
    }

    func all() -> [any LauncherAction] {
        ordered
    }

    func replaceWebActions(_ newActions: [any LauncherAction]) {
        ordered.removeAll { action in
            Self.webPrefixes.contains { action.id.hasPrefix($0) }
        }
        for key in Array(actions.keys) where Self.webPrefixes.contains(where: { key.hasPrefix($0) }) {
            actions.removeValue(forKey: key)
        }
        register(newActions)
    }
}
