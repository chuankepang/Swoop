import AppKit
import Carbon

final class GlobalHotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    var onPressed: (() -> Void)?

    deinit {
        unregister()
    }

    func registerDefault() {
        register(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey))
    }

    func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(noErr) }
                Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue().handlePress()
                return OSStatus(noErr)
            },
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        guard status == noErr else { return }

        let hotKeyID = EventHotKeyID(signature: OSType(0x53574F50), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    private func handlePress() {
        DispatchQueue.main.async { [weak self] in
            self?.onPressed?()
        }
    }
}
