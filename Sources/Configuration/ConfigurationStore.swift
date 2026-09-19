import Foundation

final class ConfigurationStore {
    static let preferencesKey = "swoop.preferences.v1"
    static let firstPresentationKey = "swoop.didCompleteFirstPresentation"

    private let defaults: UserDefaults
    private(set) var preferences: SwoopPreferences

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.preferencesKey),
           let decoded = try? JSONDecoder().decode(SwoopPreferences.self, from: data) {
            preferences = decoded
        } else {
            preferences = .default
        }
    }

    var preferredBrowser: PreferredBrowser {
        preferences.preferredBrowser
    }

    var fallbackEngine: FallbackSearchEngine {
        preferences.fallbackEngine
    }

    func resolvedBuiltInConfigs() -> [WebActionConfig] {
        BuiltInWebActionDefaults.all.map { definition in
            merge(definition.asConfig(), override: preferences.webOverrides[definition.id])
        }
    }

    func resolvedCustomConfigs() -> [WebActionConfig] {
        preferences.customWebActions.filter(\.isEnabled)
    }

    func merge(_ base: WebActionConfig, override: WebActionOverride?) -> WebActionConfig {
        guard let override else { return base }
        var config = base
        if let name = override.name { config.name = name }
        if let aliases = override.aliases { config.aliases = aliases }
        if let urlTemplate = override.urlTemplate { config.urlTemplate = urlTemplate }
        if let isEnabled = override.isEnabled { config.isEnabled = isEnabled }
        return config
    }

    func updateBuiltInOverride(id: String, config: WebActionConfig) {
        guard BuiltInWebActionDefaults.definition(for: id) != nil else { return }
        let defaultConfig = BuiltInWebActionDefaults.definition(for: id)!.asConfig()
        var override = preferences.webOverrides[id] ?? WebActionOverride()
        if config.name != defaultConfig.name { override.name = config.name } else { override.name = nil }
        if config.aliases != defaultConfig.aliases { override.aliases = config.aliases } else { override.aliases = nil }
        if config.urlTemplate != defaultConfig.urlTemplate { override.urlTemplate = config.urlTemplate } else { override.urlTemplate = nil }
        if config.isEnabled != defaultConfig.isEnabled { override.isEnabled = config.isEnabled } else { override.isEnabled = nil }
        if override.name == nil && override.aliases == nil && override.urlTemplate == nil && override.isEnabled == nil {
            preferences.webOverrides.removeValue(forKey: id)
        } else {
            preferences.webOverrides[id] = override
        }
        persist()
    }

    func resetBuiltIn(id: String) {
        preferences.webOverrides.removeValue(forKey: id)
        persist()
    }

    func addCustomAction(_ config: WebActionConfig) {
        preferences.customWebActions.append(config)
        persist()
    }

    func updateCustomAction(_ config: WebActionConfig) {
        guard let index = preferences.customWebActions.firstIndex(where: { $0.id == config.id }) else { return }
        preferences.customWebActions[index] = config
        persist()
    }

    func removeCustomAction(id: String) {
        preferences.customWebActions.removeAll { $0.id == id }
        persist()
    }

    func setPreferredBrowser(_ browser: PreferredBrowser) {
        preferences.preferredBrowser = browser
        persist()
    }

    func setFallbackEngine(_ engine: FallbackSearchEngine) {
        preferences.fallbackEngine = engine
        persist()
    }

    func markFirstPresentationComplete() {
        defaults.set(true, forKey: Self.firstPresentationKey)
    }

    var didCompleteFirstPresentation: Bool {
        defaults.bool(forKey: Self.firstPresentationKey)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(preferences) {
            defaults.set(data, forKey: Self.preferencesKey)
        }
        NotificationCenter.default.post(name: .swoopConfigurationDidChange, object: self)
    }
}
