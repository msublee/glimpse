import AppKit

final class PreferencesWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        animationBehavior = .utilityWindow
        collectionBehavior = [.moveToActiveSpace]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        contentMinSize = NSSize(width: 420, height: 420)
    }
}
