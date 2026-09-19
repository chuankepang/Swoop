import AppKit
import ServiceManagement

if ProcessInfo.processInfo.arguments.contains("--unregister-login-item") {
    do {
        try SMAppService.mainApp.unregister()
    } catch {
        // Ignore when the login item was never registered.
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
