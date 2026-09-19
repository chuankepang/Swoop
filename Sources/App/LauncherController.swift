import AppKit

final class LauncherController: NSObject, NSWindowDelegate {
    private let panel = LauncherPanel()
    private let root = LauncherView()
    private var machine = LauncherStateMachine()
    private let registry: ActionRegistry
    private let searchEngine: SearchEngine
    private let history: UsageHistory
    private var candidates: [SearchResult] = []
    private var searchTimer: Timer?
    private var suppressResignClose = false
    private var shownAt: TimeInterval = 0
    private let launcherIcon = ActionIconFactory.launcher()

    init(registry: ActionRegistry, searchEngine: SearchEngine, history: UsageHistory) {
        self.registry = registry
        self.searchEngine = searchEngine
        self.history = history
        super.init()
        panel.delegate = self
        panel.contentView = root
        root.input.onQueryChange = { [weak self] query in
            self?.queryChanged(query)
        }
        root.input.onKey = { [weak self] key in
            self?.handle(key) ?? false
        }
        panel.editor.onKey = { [weak self] key in
            self?.handle(key) ?? false
        }
        refreshCandidates()
        resize()
    }

    func toggle() {
        if panel.isVisible, panel.isKeyWindow {
            close()
        } else {
            show()
        }
    }

    func show() {
        machine.show()
        shownAt = ProcessInfo.processInfo.systemUptime
        root.input.field.stringValue = ""
        refreshCandidates()
        updateChrome()
        resize()
        panel.placeCentered()
        stealFocus()
        DispatchQueue.main.async { [weak self] in
            self?.stealFocus()
        }
    }

    func close() {
        _ = machine.cancel()
        machine.phase = .hidden
        machine.query = ""
        machine.selectedIndex = 0
        hidePanel()
    }

    func windowDidResignKey(_ notification: Notification) {
        guard !suppressResignClose else { return }
        guard panel.isVisible else { return }
        if ProcessInfo.processInfo.systemUptime - shownAt < 1.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self, self.panel.isVisible else { return }
                self.stealFocus()
            }
            return
        }
        close()
    }

    private func stealFocus() {
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        panel.makeFirstResponder(root.input.field)
    }

    @discardableResult
    private func handle(_ key: LauncherKey) -> Bool {
        switch key {
        case .up:
            machine.moveSelection(offset: -1, count: candidates.count)
            renderList()
            return true
        case .down:
            machine.moveSelection(offset: 1, count: candidates.count)
            renderList()
            return true
        case .enter:
            confirm()
            return true
        case .escape:
            let command = machine.cancel()
            if command == .close || machine.phase == .hidden {
                hidePanel()
            } else {
                root.input.field.stringValue = ""
                refreshCandidates()
                updateChrome()
                resize()
            }
            return true
        case .clear:
            root.input.field.stringValue = ""
            queryChanged("")
            return true
        }
    }

    private func queryChanged(_ query: String) {
        machine.updateQuery(query)
        switch machine.phase {
        case .awaitingInput(let actionID):
            if let action = registry.action(id: actionID), action.presentsCandidatesDuringInput {
                scheduleDynamicSearch(action: action, query: query)
            } else {
                refreshCandidates()
            }
        default:
            refreshCandidates()
        }
        updateChrome()
        resize()
    }

    private func confirm() {
        switch machine.phase {
        case .hidden:
            return
        case .awaitingInput(let actionID):
            if let selected = selectedCandidate(), case .file(let url) = selected.payload {
                finish {
                    self.history.record(actionID: actionID)
                    NSWorkspace.shared.open(url)
                }
                return
            }
            let input = root.input.field.stringValue
            let command = machine.confirm(selectedActionID: actionID, requiresInput: true, input: input)
            perform(command)
        case .actionSelection:
            guard let selected = selectedCandidate() else { return }
            guard let action = registry.action(id: selected.actionID) else { return }
            let command = machine.confirm(
                selectedActionID: action.id,
                requiresInput: action.requiresInput,
                input: root.input.field.stringValue
            )
            if case .awaitingInput = machine.phase {
                root.input.field.stringValue = ""
                refreshCandidates()
                updateChrome()
                resize()
                panel.makeFirstResponder(root.input.field)
                return
            }
            perform(command)
        }
    }

    private func perform(_ command: LauncherCommand) {
        switch command {
        case .none:
            return
        case .close:
            hidePanel()
        case .execute(let actionID, let input):
            finish {
                self.history.record(actionID: actionID)
                self.registry.action(id: actionID)?.execute(input: input)
            }
        }
    }

    private func finish(work: @escaping () -> Void) {
        suppressResignClose = true
        hidePanel()
        machine.phase = .hidden
        machine.query = ""
        machine.selectedIndex = 0
        DispatchQueue.main.async {
            work()
            self.suppressResignClose = false
        }
    }

    private func hidePanel() {
        searchTimer?.invalidate()
        panel.orderOut(nil)
    }

    private func selectedCandidate() -> SearchResult? {
        guard candidates.indices.contains(machine.selectedIndex) else { return nil }
        return candidates[machine.selectedIndex]
    }

    private func scheduleDynamicSearch(action: any LauncherAction, query: String) {
        searchTimer?.invalidate()
        let timer = Timer(timeInterval: 0.12, repeats: false) { [weak self] _ in
            action.inputCandidates(query: query) { results in
                guard let self else { return }
                guard case .awaitingInput(let id) = self.machine.phase, id == action.id else { return }
                self.candidates = results
                if self.machine.selectedIndex >= results.count {
                    self.machine.selectedIndex = 0
                }
                self.renderList()
                self.resize()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        searchTimer = timer
    }

    private func refreshCandidates() {
        searchTimer?.invalidate()
        switch machine.phase {
        case .hidden:
            candidates = []
        case .actionSelection:
            candidates = searchEngine.searchActions(query: machine.query)
        case .awaitingInput(let actionID):
            guard let action = registry.action(id: actionID) else {
                candidates = []
                break
            }
            if action.presentsCandidatesDuringInput {
                candidates = []
                if !machine.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    scheduleDynamicSearch(action: action, query: machine.query)
                }
            } else {
                action.inputCandidates(query: machine.query) { [weak self] results in
                    guard let self else { return }
                    self.candidates = results
                    if self.machine.selectedIndex >= results.count {
                        self.machine.selectedIndex = 0
                    }
                    self.renderList()
                    self.resize()
                }
                return
            }
        }
        if machine.selectedIndex >= candidates.count {
            machine.selectedIndex = 0
        }
        renderList()
    }

    private func renderList() {
        root.list.render(candidates, selectedIndex: machine.selectedIndex) { [weak self] item in
            self?.icon(for: item)
        }
        root.needsLayout = true
    }

    private func icon(for item: SearchResult) -> NSImage? {
        if case .file(let url) = item.payload {
            return ActionIconFactory.fileIcon(at: url)
        }
        return registry.action(id: item.actionID)?.icon ?? launcherIcon
    }

    private func updateChrome() {
        switch machine.phase {
        case .hidden, .actionSelection:
            root.input.setIcon(launcherIcon)
            root.input.field.placeholderString = "Search actions..."
        case .awaitingInput(let actionID):
            let action = registry.action(id: actionID)
            root.input.setIcon(action?.icon ?? launcherIcon)
            root.input.field.placeholderString = action?.inputPlaceholder ?? "Type..."
        }
    }

    private func resize() {
        let rows = CGFloat(max(candidates.count, 0))
        let listHeight = rows * LauncherLayout.rowHeight
        let extra: CGFloat = rows == 0 ? 0 : 8
        let height = LauncherLayout.inputRowHeight + listHeight + extra
        var frame = panel.frame
        let newSize = NSSize(width: LauncherLayout.panelWidth, height: height)
        frame.origin.y += frame.size.height - newSize.height
        frame.size = newSize
        panel.setFrame(frame, display: true)
        root.frame = NSRect(origin: .zero, size: newSize)
        root.needsLayout = true
        root.layoutSubtreeIfNeeded()
    }
}
