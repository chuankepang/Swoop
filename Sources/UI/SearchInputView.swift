import AppKit

enum LauncherKey {
    case up
    case down
    case enter
    case escape
    case clear
}

final class KeyHandlingTextView: NSTextView {
    var onKey: ((LauncherKey) -> Bool)?

    override func keyDown(with event: NSEvent) {
        if handle(event) { return }
        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if handle(event) { return true }
        return super.performKeyEquivalent(with: event)
    }

    private func handle(_ event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "k" {
            return onKey?(.clear) ?? false
        }
        switch event.keyCode {
        case 126: return onKey?(.up) ?? false
        case 125: return onKey?(.down) ?? false
        case 36, 76: return onKey?(.enter) ?? false
        case 53: return onKey?(.escape) ?? false
        default: return false
        }
    }
}

final class SearchInputView: NSView, NSTextFieldDelegate {
    let iconView = NSImageView()
    let field = NSTextField()
    var onQueryChange: ((String) -> Void)?
    var onKey: ((LauncherKey) -> Bool)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = 7
        iconView.layer?.masksToBounds = true

        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 17, weight: .medium)
        field.textColor = .labelColor
        field.placeholderString = "Search actions..."
        field.delegate = self
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.cell?.usesSingleLineMode = true
        field.maximumNumberOfLines = 1
        field.lineBreakMode = .byTruncatingTail

        addSubview(iconView)
        addSubview(field)
    }

    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        let inset = LauncherLayout.padding
        let icon = LauncherLayout.iconSize
        iconView.frame = NSRect(
            x: inset,
            y: ((bounds.height - icon) / 2).rounded(),
            width: icon,
            height: icon
        )

        let font = field.font ?? .systemFont(ofSize: 17, weight: .medium)
        let textHeight = ceil(font.ascender - font.descender + 4)
        let fieldX = iconView.frame.maxX + 12
        field.frame = NSRect(
            x: fieldX,
            y: ((bounds.height - textHeight) / 2).rounded(),
            width: bounds.width - fieldX - inset,
            height: textHeight
        )
    }

    func controlTextDidChange(_ obj: Notification) {
        onQueryChange?(field.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.moveUp(_:)):
            return onKey?(.up) ?? false
        case #selector(NSResponder.moveDown(_:)):
            return onKey?(.down) ?? false
        case #selector(NSResponder.insertNewline(_:)):
            return onKey?(.enter) ?? false
        case #selector(NSResponder.cancelOperation(_:)):
            return onKey?(.escape) ?? false
        default:
            return false
        }
    }

    func setIcon(_ image: NSImage?) {
        iconView.image = image
    }
}
