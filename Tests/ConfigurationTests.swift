import AppKit

func runConfigurationTests() {
    let suite = "local.swoop.tests.configuration"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = ConfigurationStore(defaults: defaults)
    let browser = BrowserLauncher(store: store)

    TestSupport.expectEqual(
        WebActionConfig.parseAliases(" goo , gg , goo , "),
        ["goo", "gg"],
        "alias parse trims and dedupes"
    )

    let google = store.resolvedBuiltInConfigs().first { $0.id == "web.google" }
    TestSupport.expect(google != nil, "built-in google exists")
    TestSupport.expectEqual(google?.requiresInput, true, "{key} requires input")

    let chatgpt = store.resolvedBuiltInConfigs().first { $0.id == "shortcut.chatgpt" }
    TestSupport.expectEqual(chatgpt?.requiresInput, false, "shortcut has no {key}")

    store.updateBuiltInOverride(
        id: "web.google",
        config: WebActionConfig(
            id: "web.google",
            name: "Google Search",
            aliases: ["google"],
            keywords: [],
            urlTemplate: "https://www.google.com/search?q={key}",
            isEnabled: false,
            isBuiltIn: true,
            placeholder: nil,
            subtitle: nil,
            mark: nil
        )
    )
    TestSupport.expect(
        !store.resolvedBuiltInConfigs().contains(where: { $0.id == "web.google" && $0.isEnabled }),
        "disabled built-in is filtered out"
    )

    store.resetBuiltIn(id: "web.google")
    TestSupport.expect(
        store.resolvedBuiltInConfigs().contains(where: { $0.id == "web.google" && $0.isEnabled }),
        "reset built-in restores enabled"
    )

    let custom = WebActionConfig(
        id: "custom.test",
        name: "Hugging Face",
        aliases: ["hf"],
        keywords: [],
        urlTemplate: "https://huggingface.co/",
        isEnabled: true,
        isBuiltIn: false,
        placeholder: nil,
        subtitle: nil,
        mark: nil
    )
    store.addCustomAction(custom)
    TestSupport.expect(store.resolvedCustomConfigs().contains(where: { $0.id == "custom.test" }), "custom added")
    store.removeCustomAction(id: "custom.test")
    TestSupport.expect(!store.resolvedCustomConfigs().contains(where: { $0.id == "custom.test" }), "custom removed")

    TestSupport.expect(QueryURLEncoder.validateTemplate("https://example.com/search?q={key}"), "valid template")
    TestSupport.expect(!QueryURLEncoder.validateTemplate("hello"), "invalid template rejected")

    store.setFallbackEngine(.google)
    TestSupport.expectEqual(store.fallbackEngine.actionID, "web.google", "google fallback id")

    let registry = ActionRegistry()
    registry.register(FileSearchAction(spotlight: SpotlightService()))
    registry.replaceWebActions(WebActionResolver.resolveActions(from: store, launcher: browser))
    TestSupport.expect(registry.action(id: "files.find") != nil, "replaceWebActions keeps file search")
    TestSupport.expect(registry.action(id: "web.bing") != nil, "web actions registered")
}
