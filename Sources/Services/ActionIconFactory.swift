import AppKit

enum BrandMark: String {
    case google
    case bing
    case github
    case youtube
    case scholar
    case arxiv
    case xiaohongshu
    case files
    case launcher
}

enum ActionIconFactory {
    static let canvas = NSSize(width: 64, height: 64)

    static func brand(_ mark: BrandMark) -> NSImage {
        NSImage(size: canvas, flipped: false) { rect in
            drawRoundedBackground(in: rect, fill: brandFill(mark))
            drawBrandContent(mark, in: rect)
            return true
        }
    }

    static func glyph(_ symbolName: String, tint: NSColor, fill: NSColor) -> NSImage {
        NSImage(size: canvas, flipped: false) { rect in
            drawRoundedBackground(in: rect, fill: fill)
            drawSymbol(symbolName, tint: tint, in: rect)
            return true
        }
    }

    static func roundedAppIcon(_ source: NSImage) -> NSImage {
        NSImage(size: canvas, flipped: false) { rect in
            let path = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: 14, yRadius: 14)
            path.addClip()
            source.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            return true
        }
    }

    static func fileIcon(at url: URL) -> NSImage {
        roundedAppIcon(NSWorkspace.shared.icon(forFile: url.path))
    }

    static func launcher() -> NSImage {
        brand(.launcher)
    }

    static func menuBarImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            drawSwoop(in: rect.insetBy(dx: 1.5, dy: 1.5), color: .black)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func isDark() -> Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private static func drawRoundedBackground(in rect: NSRect, fill: NSColor) {
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 14, yRadius: 14)
        fill.setFill()
        path.fill()
        path.addClip()
    }

    private static func brandFill(_ mark: BrandMark) -> NSColor {
        let dark = isDark()
        switch mark {
        case .google: return NSColor(srgbRed: 0.26, green: 0.52, blue: 0.96, alpha: 1)
        case .bing: return NSColor(srgbRed: 0.00, green: 0.51, blue: 0.45, alpha: 1)
        case .github: return dark ? NSColor(white: 0.18, alpha: 1) : NSColor(white: 0.12, alpha: 1)
        case .youtube: return NSColor(srgbRed: 0.90, green: 0.13, blue: 0.15, alpha: 1)
        case .scholar: return NSColor(srgbRed: 0.23, green: 0.49, blue: 0.78, alpha: 1)
        case .arxiv: return NSColor(srgbRed: 0.70, green: 0.11, blue: 0.11, alpha: 1)
        case .xiaohongshu: return NSColor(srgbRed: 1.0, green: 0.14, blue: 0.26, alpha: 1)
        case .files: return NSColor(srgbRed: 0.20, green: 0.55, blue: 0.95, alpha: 1)
        case .launcher:
            return dark
                ? NSColor(srgbRed: 0.18, green: 0.42, blue: 0.78, alpha: 1)
                : NSColor(srgbRed: 0.16, green: 0.46, blue: 0.92, alpha: 1)
        }
    }

    private static func drawBrandContent(_ mark: BrandMark, in rect: NSRect) {
        switch mark {
        case .google:
            drawLetter("G", in: rect, size: 34)
            drawGoogleDots(in: rect)
        case .bing:
            drawLetter("b", in: rect, size: 36)
        case .github:
            drawGitHubMark(in: rect)
        case .youtube:
            drawPlay(in: rect)
        case .scholar:
            drawLetter("S", in: rect, size: 32)
        case .arxiv:
            drawLetter("χ", in: rect, size: 30)
        case .xiaohongshu:
            drawLetter("红", in: rect, size: 28)
        case .files:
            drawSymbol("doc.text.magnifyingglass", tint: .white, in: rect)
        case .launcher:
            drawSwoop(in: rect.insetBy(dx: 12, dy: 12), color: .white)
        }
    }

    private static func drawLetter(_ text: String, in rect: NSRect, size: CGFloat) {
        let font = NSFont.systemFont(ofSize: size, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()
        attributed.draw(at: NSPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2 - 1
        ))
    }

    private static func drawGoogleDots(in rect: NSRect) {
        let colors = [
            NSColor(srgbRed: 0.92, green: 0.26, blue: 0.21, alpha: 1),
            NSColor(srgbRed: 0.98, green: 0.74, blue: 0.02, alpha: 1),
            NSColor(srgbRed: 0.21, green: 0.66, blue: 0.31, alpha: 1)
        ]
        let y = rect.minY + 8
        let startX = rect.midX - 8
        for (index, color) in colors.enumerated() {
            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: startX + CGFloat(index) * 6, y: y, width: 4, height: 4)).fill()
        }
    }

    private static func drawPlay(in rect: NSRect) {
        let path = NSBezierPath()
        let inset = rect.insetBy(dx: 22, dy: 18)
        path.move(to: NSPoint(x: inset.minX + 2, y: inset.minY))
        path.line(to: NSPoint(x: inset.maxX, y: inset.midY))
        path.line(to: NSPoint(x: inset.minX + 2, y: inset.maxY))
        path.close()
        NSColor.white.setFill()
        path.fill()
    }

    private static func drawGitHubMark(in rect: NSRect) {
        NSColor.white.setFill()
        let head = NSRect(x: rect.midX - 12, y: rect.midY - 8, width: 24, height: 22)
        NSBezierPath(roundedRect: head, xRadius: 10, yRadius: 10).fill()
        let earL = NSBezierPath()
        earL.move(to: NSPoint(x: head.minX + 3, y: head.maxY - 6))
        earL.line(to: NSPoint(x: head.minX - 1, y: head.maxY + 6))
        earL.line(to: NSPoint(x: head.minX + 10, y: head.maxY))
        earL.close()
        earL.fill()
        let earR = NSBezierPath()
        earR.move(to: NSPoint(x: head.maxX - 3, y: head.maxY - 6))
        earR.line(to: NSPoint(x: head.maxX + 1, y: head.maxY + 6))
        earR.line(to: NSPoint(x: head.maxX - 10, y: head.maxY))
        earR.close()
        earR.fill()
    }

    static func drawSwoop(in rect: NSRect, color: NSColor) {
        color.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.38))
        path.curve(
            to: NSPoint(x: rect.maxX - rect.width * 0.06, y: rect.maxY - rect.height * 0.22),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.02),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.62, y: rect.maxY - rect.height * 0.02)
        )
        path.lineWidth = max(2, rect.width * 0.18)
        path.lineCapStyle = .round
        path.stroke()

        let accent = NSBezierPath()
        accent.move(to: NSPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.58))
        accent.curve(
            to: NSPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.28),
            controlPoint1: NSPoint(x: rect.midX, y: rect.midY + rect.height * 0.18),
            controlPoint2: NSPoint(x: rect.midX + rect.width * 0.18, y: rect.minY + rect.height * 0.42)
        )
        accent.lineWidth = max(1.5, rect.width * 0.10)
        accent.lineCapStyle = .round
        accent.stroke()
    }

    private static func drawSymbol(_ name: String, tint: NSColor, in rect: NSRect) {
        guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
            .applying(.init(paletteColors: [tint]))
        let image = base.withSymbolConfiguration(config) ?? base
        let size = NSSize(width: 30, height: 30)
        image.draw(
            in: NSRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }
}
