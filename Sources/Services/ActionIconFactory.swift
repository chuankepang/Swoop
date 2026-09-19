import AppKit

enum BrandMark: String {
    case google
    case bing
    case github
    case youtube
    case scholar
    case arxiv
    case xiaohongshu
    case chatgpt
    case grok
    case gemini
    case bilibili
    case douyin
    case baidu
    case baiduZhEn
    case baiduEnZh
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

    static func normalized(_ source: NSImage, inset: CGFloat) -> NSImage {
        NSImage(size: canvas, flipped: false) { rect in
            source.draw(in: rect.insetBy(dx: inset, dy: inset), from: .zero, operation: .sourceOver, fraction: 1)
            return true
        }
    }

    static func roundedAppIcon(_ source: NSImage) -> NSImage {
        NSImage(size: canvas, flipped: false) { rect in
            let tile = tileRect(in: rect)
            tilePath(in: tile).addClip()
            drawAspectFill(source, in: tile)
            return true
        }
    }

    static func normalizedRaster(_ source: NSImage, inset: CGFloat) -> NSImage {
        let trimmed = trimmedToAlphaBounds(source) ?? source
        return NSImage(size: canvas, flipped: false) { rect in
            trimmed.draw(in: rect.insetBy(dx: inset, dy: inset), from: .zero, operation: .sourceOver, fraction: 1)
            return true
        }
    }

    static func trimmedToAlphaBounds(_ image: NSImage) -> NSImage? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let cg = bitmap.cgImage else { return nil }
        let width = cg.width
        let height = cg.height
        guard width > 0, height > 0 else { return nil }
        guard let data = cg.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }
        let bpp = cg.bitsPerPixel / 8
        guard bpp >= 4 else { return nil }

        var minX = width, minY = height, maxX = 0, maxY = 0
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * cg.bytesPerRow) + (x * bpp)
                let alpha = bytes[offset + 3]
                if alpha > 8 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        let crop = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        guard let cropped = cg.cropping(to: crop) else { return nil }
        return NSImage(cgImage: cropped, size: NSSize(width: crop.width, height: crop.height))
    }

    static func fileIcon(at url: URL) -> NSImage {
        roundedAppIcon(NSWorkspace.shared.icon(forFile: url.path))
    }

    static func launcher() -> NSImage {
        brand(.launcher)
    }

    private static func isDark() -> Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private static func tileRect(in rect: NSRect) -> NSRect {
        rect.insetBy(dx: IconMetrics.tileInset, dy: IconMetrics.tileInset)
    }

    private static func tilePath(in tile: NSRect) -> NSBezierPath {
        NSBezierPath(roundedRect: tile, xRadius: IconMetrics.tileCornerRadius, yRadius: IconMetrics.tileCornerRadius)
    }

    private static func drawAspectFill(_ image: NSImage, in rect: NSRect) {
        let source = image.size
        guard source.width > 0, source.height > 0 else { return }
        let scale = max(rect.width / source.width, rect.height / source.height)
        let drawSize = NSSize(width: source.width * scale, height: source.height * scale)
        let origin = NSPoint(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2
        )
        image.draw(
            in: NSRect(origin: origin, size: drawSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }

    private static func drawRoundedBackground(in rect: NSRect, fill: NSColor) {
        let tile = tileRect(in: rect)
        let path = tilePath(in: tile)
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
        case .chatgpt: return NSColor(srgbRed: 0.07, green: 0.64, blue: 0.50, alpha: 1)
        case .grok: return dark ? NSColor(white: 0.14, alpha: 1) : NSColor(white: 0.10, alpha: 1)
        case .gemini: return NSColor(srgbRed: 0.26, green: 0.45, blue: 0.98, alpha: 1)
        case .bilibili: return NSColor(srgbRed: 0.98, green: 0.45, blue: 0.58, alpha: 1)
        case .douyin: return NSColor(srgbRed: 0.08, green: 0.08, blue: 0.10, alpha: 1)
        case .baidu, .baiduZhEn, .baiduEnZh: return NSColor(srgbRed: 0.16, green: 0.45, blue: 0.98, alpha: 1)
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
            drawXiaohongshuMark(in: rect)
        case .chatgpt:
            drawChatGPTMark(in: rect)
        case .grok:
            drawLetter("G", in: rect, size: 30)
        case .gemini:
            drawGeminiMark(in: rect)
        case .bilibili:
            drawBilibiliMark(in: rect)
        case .douyin:
            drawDouyinMark(in: rect)
        case .baidu:
            drawBaiduMark(in: rect)
        case .baiduZhEn:
            drawTranslationDirectionMark(in: rect, top: "中", bottom: "EN")
        case .baiduEnZh:
            drawTranslationDirectionMark(in: rect, top: "EN", bottom: "中")
        case .files:
            drawSymbol("doc.text.magnifyingglass", tint: .white, in: rect)
        case .launcher:
            drawSwoop(in: rect.insetBy(dx: 12, dy: 12), color: .white, weight: 0.18)
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

    static func drawSwoop(in rect: NSRect, color: NSColor, weight: CGFloat = 0.18) {
        color.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.38))
        path.curve(
            to: NSPoint(x: rect.maxX - rect.width * 0.06, y: rect.maxY - rect.height * 0.22),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.02),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.62, y: rect.maxY - rect.height * 0.02)
        )
        path.lineWidth = max(1.4, rect.width * weight)
        path.lineCapStyle = .round
        path.stroke()

        let accent = NSBezierPath()
        accent.move(to: NSPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.58))
        accent.curve(
            to: NSPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.28),
            controlPoint1: NSPoint(x: rect.midX, y: rect.midY + rect.height * 0.18),
            controlPoint2: NSPoint(x: rect.midX + rect.width * 0.18, y: rect.minY + rect.height * 0.42)
        )
        accent.lineWidth = max(1.1, rect.width * weight * 0.55)
        accent.lineCapStyle = .round
        accent.stroke()
    }

    private static func drawXiaohongshuMark(in rect: NSRect) {
        let card = rect.insetBy(dx: 16, dy: 14)
        let book = NSBezierPath(roundedRect: card, xRadius: 8, yRadius: 8)
        NSColor.white.setFill()
        book.fill()

        let inner = card.insetBy(dx: 7, dy: 8)
        let flower = NSBezierPath()
        let center = NSPoint(x: inner.midX, y: inner.midY + 1)
        let petals = 5
        for i in 0..<petals {
            let angle = (CGFloat(i) / CGFloat(petals)) * (.pi * 2) - .pi / 2
            let petal = NSBezierPath(ovalIn: NSRect(
                x: center.x + cos(angle) * inner.width * 0.18 - inner.width * 0.16,
                y: center.y + sin(angle) * inner.height * 0.18 - inner.height * 0.16,
                width: inner.width * 0.32,
                height: inner.height * 0.32
            ))
            flower.append(petal)
        }
        brandFill(.xiaohongshu).setFill()
        flower.fill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 3.5, y: center.y - 3.5, width: 7, height: 7)).fill()
    }

    private static func drawChatGPTMark(in rect: NSRect) {
        NSColor.white.setFill()
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let path = NSBezierPath()
        path.appendOval(in: NSRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22))
        path.fill()
        brandFill(.chatgpt).setStroke()
        let ring = NSBezierPath()
        ring.appendOval(in: NSRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18))
        ring.lineWidth = 2.5
        ring.stroke()
    }

    private static func drawGeminiMark(in rect: NSRect) {
        NSColor.white.setFill()
        let star = NSBezierPath()
        let center = NSPoint(x: rect.midX, y: rect.midY + 1)
        for i in 0..<4 {
            let angle = CGFloat(i) * (.pi / 2)
            let tip = NSPoint(x: center.x + cos(angle) * 12, y: center.y + sin(angle) * 12)
            let side = NSPoint(x: center.x + cos(angle + .pi / 4) * 5, y: center.y + sin(angle + .pi / 4) * 5)
            if i == 0 { star.move(to: tip) } else { star.line(to: tip) }
            star.line(to: side)
        }
        star.close()
        star.fill()
    }

    private static func drawBilibiliMark(in rect: NSRect) {
        NSColor.white.setFill()
        let tv = NSRect(x: rect.midX - 14, y: rect.midY - 10, width: 28, height: 20)
        NSBezierPath(roundedRect: tv, xRadius: 4, yRadius: 4).fill()
        brandFill(.bilibili).setFill()
        NSBezierPath(roundedRect: tv.insetBy(dx: 3, dy: 3), xRadius: 2, yRadius: 2).fill()
        NSColor.white.setFill()
        let play = NSBezierPath()
        let inset = tv.insetBy(dx: 9, dy: 6)
        play.move(to: NSPoint(x: inset.minX + 2, y: inset.minY))
        play.line(to: NSPoint(x: inset.maxX, y: inset.midY))
        play.line(to: NSPoint(x: inset.minX + 2, y: inset.maxY))
        play.close()
        play.fill()
    }

    private static func drawDouyinMark(in rect: NSRect) {
        NSColor.white.setFill()
        let note = NSBezierPath()
        note.appendOval(in: NSRect(x: rect.midX - 4, y: rect.midY - 10, width: 10, height: 10))
        note.fill()
        NSColor(srgbRed: 0.98, green: 0.20, blue: 0.36, alpha: 1).setFill()
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: rect.midX + 2, y: rect.midY - 2))
        tail.line(to: NSPoint(x: rect.midX + 12, y: rect.midY + 12))
        tail.line(to: NSPoint(x: rect.midX - 2, y: rect.midY + 8))
        tail.close()
        tail.fill()
    }

    private static func drawBaiduMark(in rect: NSRect) {
        drawLetter("译", in: rect, size: 28)
        NSColor.white.withAlphaComponent(0.9).setStroke()
        let paw = NSBezierPath(ovalIn: NSRect(x: rect.midX - 10, y: rect.minY + 8, width: 20, height: 8))
        paw.lineWidth = 1.2
        paw.stroke()
    }

    private static func drawTranslationDirectionMark(in rect: NSRect, top: String, bottom: String) {
        let topFont = NSFont.systemFont(ofSize: top.count > 2 ? 14 : 16, weight: .bold)
        let bottomFont = NSFont.systemFont(ofSize: bottom.count > 2 ? 14 : 16, weight: .bold)
        let topAttr = NSAttributedString(string: top, attributes: [.font: topFont, .foregroundColor: NSColor.white])
        let bottomAttr = NSAttributedString(string: bottom, attributes: [.font: bottomFont, .foregroundColor: NSColor.white])
        let topSize = topAttr.size()
        let bottomSize = bottomAttr.size()
        topAttr.draw(at: NSPoint(x: rect.midX - topSize.width / 2, y: rect.midY + 2))
        bottomAttr.draw(at: NSPoint(x: rect.midX - bottomSize.width / 2, y: rect.midY - bottomSize.height - 2))
        NSColor.white.setStroke()
        let arrow = NSBezierPath()
        arrow.move(to: NSPoint(x: rect.maxX - 14, y: rect.midY + 6))
        arrow.line(to: NSPoint(x: rect.maxX - 14, y: rect.midY - 6))
        arrow.line(to: NSPoint(x: rect.maxX - 8, y: rect.midY))
        arrow.close()
        arrow.fill()
    }

    private static func drawSymbol(_ name: String, tint: NSColor, in rect: NSRect) {
        guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return }
        let config = NSImage.SymbolConfiguration(pointSize: IconMetrics.systemSymbolPointSize, weight: .semibold)
            .applying(.init(paletteColors: [tint]))
        let image = base.withSymbolConfiguration(config) ?? base
        let inset = IconMetrics.systemContentInset
        let size = NSSize(
            width: rect.width - inset * 2,
            height: rect.height - inset * 2
        )
        image.draw(
            in: NSRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }
}
