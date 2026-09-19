import AppKit
import Foundation
import ServiceManagement

enum LoginItemStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case notFound
}

final class LoginItemManager {
    func currentStatus() -> LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .notRegistered:
            return .disabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        @unknown default:
            return .notFound
        }
    }

    func ensureRegistered() {
        guard currentStatus() == .disabled else { return }
        try? SMAppService.mainApp.register()
    }
}
