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
    private var confirmLockUntil: TimeInterval = 0
    private var fileSearchGeneration = 0
    private var fileSearchInFlight = false
    private var isHiding = false
    private let launcherIcon = IconProvider.launcherState()
    private let showDuration: TimeInterval = 0.14
    private let hideDuration: TimeInterval = 0.10

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

    func show(error: String? = nil) {
        isHiding = false
        machine.show()
        shownAt = ProcessInfo.processInfo.systemUptime
        root.input.field.stringValue = ""
        refreshCandidates()
        updateChrome(error: error)
        resize()
        panel.placeCentered()
        panel.alphaValue = 0
        root.setPresentedScale(0.98)
        suppressResignClose = true
        stealFocus()
        animatePresentation(visible: true) { [weak self] in
            self?.suppressResignClose = false
        }
    }

    func close() {
        _ = machine.cancel()
        machine.phase = .hidden
        machine.query = ""
        machine.selectedIndex = 0
        hidePanel()
    }

    func reloadConfigurationIfNeeded() {
        guard case .actionSelection = machine.phase else { return }
        refreshCandidates()
        updateChrome()
        resize()
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
            let now = ProcessInfo.processInfo.systemUptime
            if now < confirmLockUntil {
                return true
            }
            confirmLockUntil = now + 0.12
            confirm()
            return true
        case .escape:
            let command = machine.cancel()
            if command == .close || machine.phase == .hidden {
                hidePanel()
            } else {
                if case .actionSelection = machine.phase {
                    root.input.field.stringValue = ""
                }
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
            if let action = registry.action(id: actionID), action.inputConfirmBehavior == .searchThenBrowse {
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
        case .browsingFiles(let actionID):
            guard let selected = selectedCandidate(), case .file(let url) = selected.payload else {
                DebugLog.fileSearch("Enter ignored: no file candidate selected in-flight=\(fileSearchInFlight)")
                return
            }
            DebugLog.fileSearch("Opening \(url.path)")
            finish {
                self.history.record(actionID: actionID)
                let opened = NSWorkspace.shared.open(url)
                if !opened {
                    DebugLog.fileSearch("NSWorkspace.open failed for \(url.path)")
                    self.show(error: "Could not open \(url.lastPathComponent)")
                }
            }
        case .awaitingInput(let actionID):
            guard let action = registry.action(id: actionID) else { return }
            let input = root.input.field.stringValue
            DebugLog.fileSearch("Enter pressed phase=awaitingInput action=\(actionID) query=\(input)")
            let command = machine.confirm(
                selectedActionID: actionID,
                requiresInput: true,
                inputConfirm: action.inputConfirmBehavior,
                input: input
            )
            perform(command)
        case .actionSelection:
            guard let selected = selectedCandidate() else { return }
            if case .immediate(let actionID, let input) = selected.payload {
                perform(.execute(actionID: actionID, input: input))
                return
            }
            guard let action = registry.action(id: selected.actionID) else { return }
            let command = machine.confirm(
                selectedActionID: action.id,
                requiresInput: action.requiresInput,
                inputConfirm: action.inputConfirmBehavior,
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
        case .searchFiles(let actionID, let query):
            guard let action = registry.action(id: actionID) else { return }
            fileSearchGeneration += 1
            let token = fileSearchGeneration
            fileSearchInFlight = true
            DebugLog.fileSearch("Starting Spotlight query token=\(token)")
            action.inputCandidates(query: query) { [weak self] results in
                guard let self else { return }
                guard token == self.fileSearchGeneration else {
                    DebugLog.fileSearch("Dropping stale UI update token=\(token)")
                    return
                }
                self.fileSearchInFlight = false
                guard case .browsingFiles(let id) = self.machine.phase, id == actionID else {
                    DebugLog.fileSearch("Results arrived but phase changed")
                    return
                }
                DebugLog.fileSearch("Updating UI count=\(results.count)")
                self.candidates = results
                self.machine.selectedIndex = 0
                self.renderList()
                self.resize()
                self.panel.makeFirstResponder(self.root.input.field)
            }
        case .openFile:
            DebugLog.fileSearch("openFile command ignored at perform(); browsingFiles handles selection")
            return
        case .execute(let actionID, let input):
            finish {
                self.history.record(actionID: actionID)
                guard let action = self.registry.action(id: actionID) else { return }
                action.execute(input: input) { error in
                    if let error {
                        self.show(error: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func finish(work: @escaping () -> Void) {
        machine.phase = .hidden
        machine.query = ""
        machine.selectedIndex = 0
        hidePanel {
            work()
        }
    }

    private func hidePanel(completion: (() -> Void)? = nil) {
        guard !isHiding else { return }
        searchTimer?.invalidate()
        guard panel.isVisible else {
            completion?()
            return
        }
        isHiding = true
        suppressResignClose = true
        animatePresentation(visible: false) { [weak self] in
            guard let self else { return }
            self.panel.orderOut(nil)
            self.panel.alphaValue = 1
            self.root.resetPresentation()
            self.isHiding = false
            self.suppressResignClose = false
            completion?()
        }
    }

    private func animatePresentation(visible: Bool, completion: (() -> Void)? = nil) {
        let duration = visible ? showDuration : hideDuration
        let targetScale: CGFloat = visible ? 1 : 0.98
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: visible ? .easeOut : .easeIn)
            panel.animator().alphaValue = visible ? 1 : 0
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: visible ? .easeOut : .easeIn)
            context.allowsImplicitAnimation = true
            root.setPresentedScale(targetScale)
        } completionHandler: {
            completion?()
        }
    }

    private func selectedCandidate() -> SearchResult? {
        guard candidates.indices.contains(machine.selectedIndex) else { return nil }
        return candidates[machine.selectedIndex]
    }

    private func scheduleDynamicSearch(action: any LauncherAction, query: String) {
        searchTimer?.invalidate()
        let timer = Timer(timeInterval: 0.3, repeats: false) { [weak self] _ in
            DebugLog.fileSearch("Debounced preview Query: \(query)")
            action.inputCandidates(query: query) { results in
                guard let self else { return }
                guard case .awaitingInput(let id) = self.machine.phase, id == action.id else { return }
                DebugLog.fileSearch("Updating UI preview count=\(results.count)")
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
        case .browsingFiles:
            break
        case .awaitingInput(let actionID):
            guard let action = registry.action(id: actionID) else {
                candidates = []
                break
            }
            if action.inputConfirmBehavior == .searchThenBrowse {
                if machine.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    candidates = []
                }
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
            return IconProvider.file(at: url)
        }
        return registry.action(id: item.actionID)?.icon ?? launcherIcon
    }

    private func updateChrome(error: String? = nil) {
        switch machine.phase {
        case .hidden, .actionSelection:
            root.input.setIcon(launcherIcon)
            root.input.field.placeholderString = error ?? "Search actions..."
        case .awaitingInput(let actionID), .browsingFiles(let actionID):
            let action = registry.action(id: actionID)
            root.input.setIcon(action?.icon ?? launcherIcon)
            root.input.field.placeholderString = error ?? action?.inputPlaceholder ?? "Type..."
        }
    }

    private func resize() {
        let rows = CGFloat(max(candidates.count, 0))
        let listHeight = rows * LayoutMetrics.rowHeight
        let extra: CGFloat = rows == 0 ? 0 : 10
        let height = LayoutMetrics.inputRowHeight + listHeight + extra
        var frame = panel.frame
        let newSize = NSSize(width: LayoutMetrics.panelWidth, height: height)
        frame.origin.y += frame.size.height - newSize.height
        frame.size = newSize
        panel.setFrame(frame, display: true)
        root.frame = NSRect(origin: .zero, size: newSize)
        root.needsLayout = true
        root.layoutSubtreeIfNeeded()
    }
}
