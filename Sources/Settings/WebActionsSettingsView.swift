import AppKit

final class WebActionsSettingsView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private let store: ConfigurationStore
    private var configs: [WebActionConfig] = []
    private let table = NSTableView()
    private let scrollView = NSScrollView()
    private let addButton = NSButton(title: "Add", target: nil, action: nil)
    private let editButton = NSButton(title: "Edit", target: nil, action: nil)
    private let removeButton = NSButton(title: "Remove", target: nil, action: nil)
    private let resetButton = NSButton(title: "Reset", target: nil, action: nil)

    init(store: ConfigurationStore) {
        self.store = store
        super.init(frame: .zero)
        buildUI()
        reload()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reload() {
        configs = store.allResolvedConfigsForSettings()
        table.reloadData()
        updateButtons()
    }

    private func buildUI() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        column.title = "Web Action"
        column.width = 360
        table.addTableColumn(column)
        table.headerView = nil
        table.delegate = self
        table.dataSource = self
        table.usesAlternatingRowBackgroundColors = true
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        scrollView.documentView = table
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttons)

        [addButton, editButton, removeButton, resetButton].forEach { button in
            button.target = self
            buttons.addArrangedSubview(button)
        }
        addButton.action = #selector(addAction)
        editButton.action = #selector(editAction)
        removeButton.action = #selector(removeAction)
        resetButton.action = #selector(resetAction)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            scrollView.bottomAnchor.constraint(equalTo: buttons.topAnchor, constant: -12),
            buttons.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            buttons.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    private func selectedConfig() -> WebActionConfig? {
        let row = table.selectedRow
        guard row >= 0, row < configs.count else { return nil }
        return configs[row]
    }

    private func updateButtons() {
        guard let config = selectedConfig() else {
            editButton.isEnabled = false
            removeButton.isEnabled = false
            resetButton.isEnabled = false
            return
        }
        editButton.isEnabled = true
        removeButton.isEnabled = !config.isBuiltIn
        resetButton.isEnabled = config.isBuiltIn
    }

    @objc private func addAction() {
        let config = WebActionConfig(
            id: "custom.\(UUID().uuidString.lowercased())",
            name: "Custom Web Action",
            aliases: ["custom"],
            keywords: [],
            urlTemplate: "https://example.com/",
            isEnabled: true,
            isBuiltIn: false,
            placeholder: nil,
            subtitle: nil,
            mark: nil
        )
        presentSheet(for: config, isNew: true)
    }

    @objc private func editAction() {
        guard let config = selectedConfig() else { return }
        presentSheet(for: config, isNew: false)
    }

    @objc private func removeAction() {
        guard let config = selectedConfig(), !config.isBuiltIn else { return }
        store.removeCustomAction(id: config.id)
        reload()
    }

    @objc private func resetAction() {
        guard let config = selectedConfig(), config.isBuiltIn else { return }
        store.resetBuiltIn(id: config.id)
        reload()
    }

    private func presentSheet(for config: WebActionConfig, isNew: Bool) {
        let sheet = WebActionEditSheet(config: config) { [weak self] updated in
            guard let self else { return }
            if updated.isBuiltIn {
                self.store.updateBuiltInOverride(id: updated.id, config: updated)
            } else if isNew {
                self.store.addCustomAction(updated)
            } else {
                self.store.updateCustomAction(updated)
            }
            self.reload()
        }
        window?.beginSheet(sheet) { _ in }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        configs.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let config = configs[row]
        let cell = NSTableCellView()
        let text = NSTextField(labelWithString: "")
        text.stringValue = config.isEnabled ? config.name : "\(config.name) (disabled)"
        text.lineBreakMode = .byTruncatingTail
        cell.textField = text
        cell.addSubview(text)
        text.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }
}
