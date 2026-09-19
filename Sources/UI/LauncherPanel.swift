import AppKit

final class LauncherPanel: NSPanel {
    let editor = KeyHandlingTextView(frame: .zero)

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: LauncherLayout.panelWidth, height: LauncherLayout.inputRowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = false
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)))
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces, .transient, .ignoresCycle]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isReleasedWhenClosed = false
        editor.isFieldEditor = true
        editor.font = .systemFont(ofSize: 17, weight: .medium)
        editor.textColor = .labelColor
        appearance = nil
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func fieldEditor(_ createFlag: Bool, for object: Any?) -> NSText? {
        editor
    }

    func placeCentered() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let x = visible.midX - frame.width / 2
        let y = visible.midY + visible.height * 0.12 - frame.height / 2
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
