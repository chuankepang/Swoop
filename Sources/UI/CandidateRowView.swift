import AppKit

final class CandidateRowView: NSView {
    let iconView = NSImageView()
    let titleLabel = NSTextField(labelWithString: "")
    let subtitleLabel = NSTextField(labelWithString: "")
    private let background = NSView()
    private let textStack = NSStackView()
    private let rowStack = NSStackView()
    private(set) var isActive = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        background.wantsLayer = true
        background.layer?.cornerRadius = 10
        background.translatesAutoresizingMaskIntoConstraints = false

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = 6
        iconView.layer?.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: LayoutMetrics.titleSize, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel.font = .systemFont(ofSize: LayoutMetrics.subtitleSize)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingMiddle
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 1
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        rowStack.orientation = .horizontal
        rowStack.alignment = .centerY
        rowStack.spacing = LayoutMetrics.stackSpacing
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.addArrangedSubview(iconView)
        rowStack.addArrangedSubview(textStack)

        addSubview(background)
        addSubview(rowStack)

        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            background.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            background.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            background.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            rowStack.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 10),
            rowStack.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -10),
            rowStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: LayoutMetrics.rowIconSize),
            iconView.heightAnchor.constraint(equalToConstant: LayoutMetrics.rowIconSize),
            iconView.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(title: String, subtitle: String?, icon: NSImage?, selected: Bool) {
        titleLabel.stringValue = title
        subtitleLabel.stringValue = subtitle ?? ""
        subtitleLabel.isHidden = (subtitle ?? "").isEmpty
        iconView.image = icon
        isActive = selected
        updateSelectionFill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateSelectionFill()
    }

    private func updateSelectionFill() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            background.layer?.backgroundColor = isActive
                ? NSColor.controlAccentColor.withAlphaComponent(0.28).cgColor
                : NSColor.clear.cgColor
        }
    }
}
