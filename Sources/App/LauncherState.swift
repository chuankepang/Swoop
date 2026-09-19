import Foundation

enum LauncherPhase: Equatable {
    case hidden
    case actionSelection
    case awaitingInput(actionID: String)
}

enum LauncherCommand: Equatable {
    case none
    case execute(actionID: String, input: String?)
    case close
}

struct LauncherStateMachine {
    var phase: LauncherPhase = .hidden
    var query: String = ""
    var selectedIndex: Int = 0

    mutating func show() {
        phase = .actionSelection
        query = ""
        selectedIndex = 0
    }

    mutating func updateQuery(_ value: String) {
        query = value
        selectedIndex = 0
    }

    mutating func moveSelection(offset: Int, count: Int) {
        guard count > 0 else {
            selectedIndex = 0
            return
        }
        let next = selectedIndex + offset
        selectedIndex = (next % count + count) % count
    }

    mutating func confirm(selectedActionID: String?, requiresInput: Bool, input: String) -> LauncherCommand {
        switch phase {
        case .hidden:
            return .none
        case .actionSelection:
            guard let selectedActionID else { return .none }
            if requiresInput {
                phase = .awaitingInput(actionID: selectedActionID)
                query = ""
                selectedIndex = 0
                return .none
            }
            phase = .hidden
            query = ""
            selectedIndex = 0
            return .execute(actionID: selectedActionID, input: nil)
        case .awaitingInput(let actionID):
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return .none }
            phase = .hidden
            query = ""
            selectedIndex = 0
            return .execute(actionID: actionID, input: trimmed)
        }
    }

    mutating func cancel() -> LauncherCommand {
        switch phase {
        case .hidden:
            return .none
        case .awaitingInput:
            phase = .actionSelection
            query = ""
            selectedIndex = 0
            return .none
        case .actionSelection:
            phase = .hidden
            query = ""
            selectedIndex = 0
            return .close
        }
    }
}
