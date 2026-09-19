import AppKit

final class GeneralSettingsView: NSView {
    private let store: ConfigurationStore
    private let loginItemManager: LoginItemManager

    private let loginCheckbox = NSButton(checkboxWithTitle: "Launch Swoop at login", target: nil, action: nil)
    private let loginHint = NSTextField(labelWithString: "")
    private let browserPopup = NSPopUpButton()
    private let fallbackPopup = NSPopUpButton()
    private let shortcutLabel = NSTextField(labelWithString: "Option + Space")

    init(store: ConfigurationStore, loginItemManager: LoginItemManager) {
        self.store = store
        self.loginItemManager = loginItemManager
        super.init(frame: .zero)
        buildUI()
        refreshLoginItemState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
        ])

        loginCheckbox.target = self
        loginCheckbox.action = #selector(loginToggled)
        stack.addArrangedSubview(loginCheckbox)

        loginHint.font = .systemFont(ofSize: 11)
        loginHint.textColor = .secondaryLabelColor
        loginHint.lineBreakMode = .byWordWrapping
        loginHint.maximumNumberOfLines = 0
        loginHint.preferredMaxLayoutWidth = 420
        stack.addArrangedSubview(loginHint)

        stack.addArrangedSubview(formRow(title: "Preferred Browser:", control: browserPopup))
        PreferredBrowser.allCases.forEach { browser in
            browserPopup.addItem(withTitle: browser.title)
        }
        browserPopup.target = self
        browserPopup.action = #selector(browserChanged)
        browserPopup.selectItem(withTitle: store.preferredBrowser.title)

        stack.addArrangedSubview(formRow(title: "Fallback Search:", control: fallbackPopup))
        FallbackSearchEngine.allCases.forEach { engine in
            fallbackPopup.addItem(withTitle: engine.title)
        }
        fallbackPopup.target = self
        fallbackPopup.action = #selector(fallbackChanged)
        fallbackPopup.selectItem(withTitle: store.fallbackEngine.title)

        let shortcutRow = NSStackView()
        shortcutRow.orientation = .horizontal
        shortcutRow.spacing = 8
        shortcutRow.addArrangedSubview(NSTextField(labelWithString: "Global Shortcut:"))
        shortcutRow.addArrangedSubview(shortcutLabel)
        shortcutLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        stack.addArrangedSubview(shortcutRow)
    }

    private func formRow(title: String, control: NSView) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        let label = NSTextField(labelWithString: title)
        label.setContentHuggingPriority(.required, for: .horizontal)
        row.addArrangedSubview(label)
        row.addArrangedSubview(control)
        return row
    }

    func refreshLoginItemState() {
        switch loginItemManager.currentStatus() {
        case .enabled:
            loginCheckbox.state = .on
            loginCheckbox.isEnabled = true
            loginHint.stringValue = ""
        case .disabled:
            loginCheckbox.state = .off
            loginCheckbox.isEnabled = true
            loginHint.stringValue = ""
        case .requiresApproval:
            loginCheckbox.state = .on
            loginCheckbox.isEnabled = true
            loginHint.stringValue = "Approval required in System Settings → Login Items."
        case .notFound:
            loginCheckbox.state = .off
            loginCheckbox.isEnabled = false
            loginHint.stringValue = "Install Swoop to /Applications to enable launch at login."
        }
    }

    @objc private func loginToggled() {
        let enable = loginCheckbox.state == .on
        do {
            try loginItemManager.setEnabled(enable)
        } catch {
            loginCheckbox.state = enable ? .off : .on
            let alert = NSAlert()
            alert.messageText = "Could not update login item"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        refreshLoginItemState()
        if loginItemManager.currentStatus() == .requiresApproval {
            loginItemManager.openLoginItemsSettings()
        }
    }

    @objc private func browserChanged() {
        let title = browserPopup.titleOfSelectedItem ?? PreferredBrowser.chromePreferred.title
        if let browser = PreferredBrowser.allCases.first(where: { $0.title == title }) {
            store.setPreferredBrowser(browser)
        }
    }

    @objc private func fallbackChanged() {
        let title = fallbackPopup.titleOfSelectedItem ?? FallbackSearchEngine.bing.title
        if let engine = FallbackSearchEngine.allCases.first(where: { $0.title == title }) {
            store.setFallbackEngine(engine)
        }
    }
}
