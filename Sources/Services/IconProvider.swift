import AppKit

enum IconRole {
    case application
    case brand
    case system
    case file
    case state
}

enum IconProvider {
    static func application(_ source: NSImage) -> NSImage {
        ActionIconFactory.roundedAppIcon(source)
    }

    static func file(at url: URL) -> NSImage {
        ActionIconFactory.roundedAppIcon(NSWorkspace.shared.icon(forFile: url.path))
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
        let glyph = IconMetrics.statusGlyphSize
        let image = NSImage(size: NSSize(width: glyph, height: glyph), flipped: false) { rect in
            ActionIconFactory.drawSwoop(
                in: rect.insetBy(dx: IconMetrics.statusContentInset, dy: IconMetrics.statusContentInset),
                color: .black,
                weight: 0.18
            )
            return true
        }
        image.size = NSSize(width: glyph, height: glyph)
        image.isTemplate = true
        return image
    }
}
