import Foundation

enum WebActionResolver {
    static func resolveActions(from store: ConfigurationStore, launcher: BrowserLauncher) -> [ConfigurableWebAction] {
        let builtIns = store.resolvedBuiltInConfigs().filter(\.isEnabled)
        let customs = store.resolvedCustomConfigs()
        return (builtIns + customs).map { ConfigurableWebAction(config: $0, launcher: launcher) }
    }
}
