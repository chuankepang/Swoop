import AppKit

enum SystemCommand {
    case lockScreen
    case sleep
    case screenSaver
    case openFinder
}

final class SystemAction: LauncherAction {
    let id: String
    let title: String
    let aliases: [String]
    let keywords: [String]
    let kind: ActionKind = .system
    let requiresInput = false
    let inputPlaceholder: String? = nil
    let icon: NSImage?
    private let command: SystemCommand
    private let service: SystemActionService

    init(
        id: String,
        title: String,
        aliases: [String],
        keywords: [String],
        icon: NSImage?,
        command: SystemCommand,
        service: SystemActionService
    ) {
        self.id = id
        self.title = title
        self.aliases = aliases
        self.keywords = keywords
        self.icon = icon
        self.command = command
        self.service = service
    }

    func execute(input: String?) {
        service.run(command)
    }
}
