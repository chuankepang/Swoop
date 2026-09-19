import AppKit

final class CandidateRowView: NSView {
    let iconView = NSImageView()
    let titleLabel = NSTextField(labelWithString: "")
    let subtitleLabel = NSTextField(labelWithString: "")
    private let background = NSView()
    private(set) var isActive = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        background.wantsLayer = true
        background.layer?.cornerRadius = 8
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = 5
        iconView.layer?.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingMiddle

        addSubview(background)
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
    }

    required init?(coder: NSCoder) { nil }

    func configure(title: String, subtitle: String?, icon: NSImage?, selected: Bool) {
        titleLabel.stringValue = title
        subtitleLabel.stringValue = subtitle ?? ""
        iconView.image = icon
        isActive = selected
        updateSelectionFill()
        needsLayout = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateSelectionFill()
    }

    private func updateSelectionFill() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            background.layer?.backgroundColor = isActive
                ? NSColor.controlAccentColor.withAlphaComponent(0.22).cgColor
                : NSColor.clear.cgColor
        }
    }

    override func layout() {
        super.layout()
        background.frame = bounds.insetBy(dx: 8, dy: 1)
        let icon = LauncherLayout.rowIconSize
        iconView.frame = NSRect(
            x: 16,
            y: ((bounds.height - icon) / 2).rounded(),
            width: icon,
            height: icon
        )
        let textX: CGFloat = 46
        let textWidth = bounds.width - textX - 14
        if subtitleLabel.stringValue.isEmpty {
            titleLabel.frame = NSRect(x: textX, y: ((bounds.height - 16) / 2).rounded(), width: textWidth, height: 16)
            subtitleLabel.frame = .zero
        } else {
            titleLabel.frame = NSRect(x: textX, y: 16, width: textWidth, height: 15)
            subtitleLabel.frame = NSRect(x: textX, y: 3, width: textWidth, height: 13)
        }
    }
}
