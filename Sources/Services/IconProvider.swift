import AppKit

enum IconProvider {
    static func application(_ source: NSImage) -> NSImage {
        ActionIconFactory.roundedAppIcon(source)
    }

    static func file(at url: URL) -> NSImage {
        ActionIconFactory.fileIcon(at: url)
    }

    static func brand(_ mark: BrandMark) -> NSImage {
        ActionIconFactory.brand(mark)
    }

    static func systemGlyph(_ name: String, fill: NSColor) -> NSImage {
        ActionIconFactory.glyph(name, tint: .white, fill: fill)
    }

    static func launcherState() -> NSImage {
        ActionIconFactory.launcher()
    }

    static func menuBarTemplate() -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let base = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Swoop")
        let image = base?.withSymbolConfiguration(config) ?? base ?? NSImage(size: NSSize(width: 18, height: 18))
        image.isTemplate = true
        return image
    }
}
