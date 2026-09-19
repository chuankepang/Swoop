import AppKit

final class ActionRegistry {
    private var actions: [String: any LauncherAction] = [:]
    private(set) var ordered: [any LauncherAction] = []

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
}
