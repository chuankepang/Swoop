import AppKit

final class WebActionEditSheet: NSWindow {
    private let onSave: (WebActionConfig) -> Void
    private var config: WebActionConfig

    private let nameField = NSTextField()
    private let aliasesField = NSTextField()
    private let urlField = NSTextField()
    private let enabledCheckbox = NSButton(checkboxWithTitle: "Enabled", target: nil, action: nil)
    private let hintLabel = NSTextField(labelWithString: "Use {key} in the URL for search/translate actions.")

    init(config: WebActionConfig, onSave: @escaping (WebActionConfig) -> Void) {
        self.config = config
        self.onSave = onSave
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        title = config.isBuiltIn ? "Edit Built-in Web Action" : "Edit Web Action"
        buildUI()
        populate()
    }

    private func buildUI() {
        let content = contentView!
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
        ])

        stack.addArrangedSubview(fieldRow(title: "Name", field: nameField))
        stack.addArrangedSubview(fieldRow(title: "Keywords", field: aliasesField))
        stack.addArrangedSubview(fieldRow(title: "URL", field: urlField))
        aliasesField.placeholderString = "comma-separated aliases"
        urlField.placeholderString = "https://example.com/search?q={key}"
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor
        stack.addArrangedSubview(hintLabel)
        enabledCheckbox.state = .on
        stack.addArrangedSubview(enabledCheckbox)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        let save = NSButton(title: "Save", target: self, action: #selector(save))
        save.keyEquivalent = "\r"
        buttons.addArrangedSubview(cancel)
        buttons.addArrangedSubview(save)
        stack.addArrangedSubview(buttons)
    }

    private func fieldRow(title: String, field: NSTextField) -> NSView {
        let row = NSStackView()
        row.orientation = .vertical
        row.spacing = 4
        row.addArrangedSubview(NSTextField(labelWithString: title))
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: 380).isActive = true
        row.addArrangedSubview(field)
        return row
    }

    private func populate() {
        nameField.stringValue = config.name
        aliasesField.stringValue = WebActionConfig.aliasesString(config.aliases)
        urlField.stringValue = config.urlTemplate
        enabledCheckbox.state = config.isEnabled ? .on : .off
    }

    @objc private func cancel() {
        close()
    }

    @objc private func save() {
        let name = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = urlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            showError("Name is required.")
            return
        }
        guard QueryURLEncoder.validateTemplate(url) else {
            showError("Invalid URL template.")
            return
        }
        config.name = name
        config.aliases = WebActionConfig.parseAliases(aliasesField.stringValue)
        config.urlTemplate = url
        config.isEnabled = enabledCheckbox.state == .on
        onSave(config)
        close()
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}
