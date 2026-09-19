import AppKit

struct InstalledApp {
    let displayName: String
    let names: [String]
    let bundleIdentifier: String
    let url: URL
    let icon: NSImage
}

final class ApplicationAction: LauncherAction {
    let app: InstalledApp
    let searchEntity: SearchableEntity
    private let cachedIcon: NSImage
    private let launcher: ApplicationLauncher

    init(app: InstalledApp, launcher: ApplicationLauncher = .shared) {
        self.app = app
        self.launcher = launcher
        self.cachedIcon = IconProvider.application(app.icon)
        self.searchEntity = SearchableEntity.build(
            displayName: app.displayName,
            names: app.names,
            aliases: [],
            keywords: ["app", "application"]
        )
    }

    var id: String { "app.\(app.bundleIdentifier)" }
    var title: String { app.displayName }
    var aliases: [String] { searchEntity.aliases }
    var keywords: [String] { searchEntity.keywords }
    var kind: ActionKind { .application }
    var icon: NSImage? { cachedIcon }
    var requiresInput: Bool { false }
    var inputPlaceholder: String? { nil }

    func execute(input: String?) {
        execute(input: input, completion: { _ in })
    }

    func execute(input: String?, completion: @escaping (Error?) -> Void) {
        launcher.open(url: app.url, name: app.displayName, bundleIdentifier: app.bundleIdentifier) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
}

final class ApplicationLauncher {
    static let shared = ApplicationLauncher()

    func open(
        url: URL,
        name: String,
        bundleIdentifier: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { running, error in
            DispatchQueue.main.async {
                if let error {
                    NSLog("Swoop launch failed name=%@ id=%@ url=%@ error=%@", name, bundleIdentifier, url.path, error.localizedDescription)
                    completion(.failure(error))
                    return
                }
                if running == nil {
                    let failed = NSError(
                        domain: "local.swoop.launch",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to open \(name)"]
                    )
                    NSLog("Swoop launch returned nil app name=%@ id=%@ url=%@", name, bundleIdentifier, url.path)
                    completion(.failure(failed))
                    return
                }
                completion(.success(()))
            }
        }
    }
}
