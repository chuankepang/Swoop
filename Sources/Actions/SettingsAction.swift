import AppKit

final class SettingsAction: LauncherAction {
    let id = "system.settings"
    let title = "Settings"
    let aliases = ["settings", "pref", "prefs", "preferences", "设置", "shezhi", "sz"]
    let keywords = ["config", "configure"]
    let kind: ActionKind = .system
    let requiresInput = false
    let inputPlaceholder: String? = nil
    let icon: NSImage? = IconProvider.systemGlyph(
        "gearshape.fill",
        fill: NSColor(srgbRed: 0.45, green: 0.48, blue: 0.55, alpha: 1)
    )

    private let openSettings: () -> Void

    init(openSettings: @escaping () -> Void) {
        self.openSettings = openSettings
    }

    func execute(input: String?) {
        openSettings()
    }
}
