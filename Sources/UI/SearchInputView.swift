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
        if hasMarkedText() {
            super.keyDown(with: event)
            return
        }
        switch event.keyCode {
        case 126:
            if onKey?(.up) == true { return }
        case 125:
            if onKey?(.down) == true { return }
        case 53:
            if onKey?(.escape) == true { return }
        default:
            break
        }
        super.keyDown(with: event)
    }

    override func insertNewline(_ sender: Any?) {
        if hasMarkedText() {
            super.insertNewline(sender)
            return
        }
        if onKey?(.enter) == true { return }
        super.insertNewline(sender)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if hasMarkedText() {
            return super.performKeyEquivalent(with: event)
        }
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "k" {
            return onKey?(.clear) ?? false
        }
        return super.performKeyEquivalent(with: event)
    }
}

final class SearchInputView: NSView, NSTextFieldDelegate {
    let iconView = NSImageView()
    let field = NSTextField()
    private let stack = NSStackView()
    var onQueryChange: ((String) -> Void)?
    var onKey: ((LauncherKey) -> Bool)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: LayoutMetrics.inputSize, weight: .medium)
        field.textColor = .labelColor
        field.placeholderString = "Search actions..."
        field.delegate = self
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.cell?.usesSingleLineMode = true
        field.maximumNumberOfLines = 1
        field.lineBreakMode = .byTruncatingTail
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)

        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = LayoutMetrics.stackSpacing
        stack.edgeInsets = NSEdgeInsets(
            top: 0,
            left: LayoutMetrics.padding,
            bottom: 0,
            right: LayoutMetrics.padding
        )
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(field)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.heightAnchor.constraint(equalTo: heightAnchor),
            iconView.widthAnchor.constraint(equalToConstant: LayoutMetrics.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: LayoutMetrics.iconSize),
            iconView.centerYAnchor.constraint(equalTo: field.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func controlTextDidChange(_ obj: Notification) {
        onQueryChange?(field.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if textView.hasMarkedText() { return false }
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
