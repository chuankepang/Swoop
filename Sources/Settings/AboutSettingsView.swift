import AppKit

final class AboutSettingsView: NSView {
    init() {
        super.init(frame: .zero)
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
        ])

        let title = NSTextField(labelWithString: "Swoop")
        title.font = .boldSystemFont(ofSize: 22)
        stack.addArrangedSubview(title)

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
        stack.addArrangedSubview(NSTextField(labelWithString: "Version \(version)"))

        let description = NSTextField(wrappingLabelWithString: "A lightweight keyboard-first launcher for macOS.")
        description.alignment = .center
        description.preferredMaxLayoutWidth = 360
        stack.addArrangedSubview(description)

        let github = NSButton(title: "GitHub", target: self, action: #selector(openGitHub))
        github.bezelStyle = .rounded
        stack.addArrangedSubview(github)
    }

    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/RoboHyperX/Swoop") {
            NSWorkspace.shared.open(url)
        }
    }
}
