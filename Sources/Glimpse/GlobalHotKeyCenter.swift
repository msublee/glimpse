import AppKit
import Carbon

@MainActor
final class GlobalHotKeyCenter {
    enum HotKeyError: Error {
        case registrationFailed(OSStatus)
        case handlerMissing
    }

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handler: (() -> Void)?

    init() {
        registerEventHandler()
    }

    @MainActor
    deinit {
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }

    func register(shortcut: KeyboardShortcut, handler: @escaping () -> Void) throws {
        unregister(retainHandler: false)
        self.handler = handler
        try installHotKey(for: shortcut)
    }

    func update(shortcut: KeyboardShortcut) throws {
        guard handler != nil else {
            throw HotKeyError.handlerMissing
        }
        try installHotKey(for: shortcut)
    }

    func unregister(retainHandler: Bool = false) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if !retainHandler {
            handler = nil
        }
    }

    private func installHotKey(for shortcut: KeyboardShortcut) throws {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: 1)
        let status = RegisterEventHotKey(
            shortcut.carbonKeyCode,
            shortcut.carbonModifierFlags,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            throw HotKeyError.registrationFailed(status)
        }

        self.hotKeyRef = hotKeyRef
    }

    private func registerEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, eventRef, userData in
                guard let eventRef, let userData else { return noErr }

                let center = Unmanaged<GlobalHotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard err == noErr, hotKeyID.signature == hotKeySignature else {
                    return noErr
                }

                Task { @MainActor in
                    center.handler?()
                }
                return noErr
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )

        if status != noErr {
            assertionFailure("Failed to install hot key handler: \(status)")
        }
    }
}

private let hotKeySignature: OSType = 0x474C4D50 // 'GLMP'
