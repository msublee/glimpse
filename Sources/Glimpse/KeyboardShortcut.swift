import AppKit
import Carbon

struct KeyboardShortcut: Codable, Equatable {
    let keyCode: UInt16
    private let modifiersRawValue: UInt
    private let storedKeyDisplay: String

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiersRawValue).intersection(.deviceIndependentFlagsMask)
    }

    var displayString: String {
        let flags = modifierFlags
        let symbols = [
            flags.contains(.command) ? "⌘" : nil,
            flags.contains(.option) ? "⌥" : nil,
            flags.contains(.control) ? "⌃" : nil,
            flags.contains(.shift) ? "⇧" : nil
        ]
        let modifiers = symbols.compactMap { $0 }.joined()
        guard !modifiers.isEmpty else {
            return storedKeyDisplay
        }
        return "\(modifiers) \(storedKeyDisplay)"
    }

    var carbonKeyCode: UInt32 { UInt32(keyCode) }

    var carbonModifierFlags: UInt32 {
        var carbon: UInt32 = 0
        let flags = modifierFlags
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        return carbon
    }

    static let defaultToggle = KeyboardShortcut(
        keyCode: UInt16(kVK_Space),
        modifierFlags: [.control, .shift],
        keyDisplay: "Space"
    )

    init(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags, keyDisplay: String) {
        self.keyCode = keyCode
        self.modifiersRawValue = modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        self.storedKeyDisplay = keyDisplay
    }

    init?(event: NSEvent) {
        guard event.type == .keyDown else { return nil }
        if event.keyCode == UInt16(kVK_Escape) {
            return nil
        }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !flags.isDisjoint(with: [.command, .option, .control, .shift]) else {
            return nil
        }

        let keyCode = event.keyCode
        guard let keyDisplay = KeyboardShortcut.keyDisplay(for: event, keyCode: keyCode) else {
            return nil
        }

        self.init(keyCode: keyCode, modifierFlags: flags, keyDisplay: keyDisplay)
    }

    private static func keyDisplay(for event: NSEvent, keyCode: UInt16) -> String? {
        if let characters = event.charactersIgnoringModifiers, !characters.isEmpty {
            let scalarString = characters.trimmingCharacters(in: .whitespacesAndNewlines)
            if scalarString.isEmpty {
                return specialKeyName(for: keyCode)
            }
            switch scalarString {
            case " ":
                return "Space"
            case "\t":
                return "Tab"
            case "\r":
                return "Return"
            default:
                return scalarString.uppercased()
            }
        }
        return specialKeyName(for: keyCode)
    }

    private static func specialKeyName(for keyCode: UInt16) -> String? {
        let mapping: [UInt16: String] = [
            UInt16(kVK_Return): "Return",
            UInt16(kVK_Tab): "Tab",
            UInt16(kVK_Space): "Space",
            UInt16(kVK_Delete): "Delete",
            UInt16(kVK_ForwardDelete): "Forward Delete",
            UInt16(kVK_Escape): "Esc",
            UInt16(kVK_LeftArrow): "Left Arrow",
            UInt16(kVK_RightArrow): "Right Arrow",
            UInt16(kVK_UpArrow): "Up Arrow",
            UInt16(kVK_DownArrow): "Down Arrow",
            UInt16(kVK_Home): "Home",
            UInt16(kVK_End): "End",
            UInt16(kVK_PageUp): "Page Up",
            UInt16(kVK_PageDown): "Page Down"
        ]
        return mapping[keyCode]
    }

    var matchesMacInputSourceToggle: Bool {
        keyCode == UInt16(kVK_Space) && modifierFlags == [.control]
    }

    var matchesSpotlight: Bool {
        keyCode == UInt16(kVK_Space) && modifierFlags == [.command]
    }
}
