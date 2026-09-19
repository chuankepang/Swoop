import AppKit
import Darwin

final class SystemActionService {
    func run(_ command: SystemCommand) {
        switch command {
        case .lockScreen:
            lockScreen()
        case .sleep:
            run("/usr/bin/pmset", ["sleepnow"])
        case .screenSaver:
            let engine = URL(fileURLWithPath: "/System/Library/CoreServices/ScreenSaverEngine.app")
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: engine, configuration: configuration) { _, _ in }
        case .openFinder:
            if let finder = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") {
                let configuration = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.openApplication(at: finder, configuration: configuration) { _, _ in }
            } else {
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()))
            }
        }
    }

    private func lockScreen() {
        let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
        if handle != nil, let symbol = dlsym(handle, "SACLockScreenImmediate") {
            typealias LockFn = @convention(c) () -> Void
            unsafeBitCast(symbol, to: LockFn.self)()
            return
        }
        run("/usr/bin/osascript", [
            "-e",
            "tell application \"System Events\" to keystroke \"q\" using {control down, command down}"
        ])
    }

    private func run(_ launchPath: String, _ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        try? process.run()
    }
}
