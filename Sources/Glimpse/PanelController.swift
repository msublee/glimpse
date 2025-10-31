import AppKit
import SwiftUI
import QuartzCore

@MainActor
final class PanelController {
    private var window: NSPanel?
    private let historyStore: SearchHistoryStore
    private let viewModel: SearchViewModel
    private lazy var hostingController: OverlayHostingController<AnyView> = {
        let initialView = SearchOverlayView(viewModel: viewModel) { [weak self] in
            self?.hide()
        }
        .environmentObject(historyStore)
        let controller = OverlayHostingController(rootView: AnyView(initialView))
        controller.onCancel = { [weak self] in
            self?.hide()
        }
        return controller
    }()

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    init(historyStore: SearchHistoryStore = .shared) {
        self.historyStore = historyStore
        self.viewModel = SearchViewModel(historyStore: historyStore)
    }

    func prepareWindow() {
        guard window == nil else { return }

        let panel = OverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 2000, height: 1300))
        panel.alphaValue = 0
        panel.contentMinSize = NSSize(width: 720, height: 480)
        panel.contentViewController = hostingController

        // Force the panel to maintain the specified size
        panel.setContentSize(NSSize(width: 2000, height: 1300))

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orderOutOnResign(_:)),
            name: NSWindow.didResignKeyNotification,
            object: panel
        )

        window = panel
    }

    func show() {
        guard let window else { return }
        if !window.isVisible {
            positionWindow(window)
            window.alphaValue = 0
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
        viewModel.requestFocus()
    }

    func hide() {
        guard let window, window.isVisible else {
            viewModel.reset()
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self, weak panel = window] in
                guard let self, let panel else { return }
                panel.orderOut(nil)
                panel.alphaValue = 0
                self.viewModel.reset()
            }
        }
    }

    @objc
    private func orderOutOnResign(_ notification: Notification) {
        hide()
    }

    private func positionWindow(_ window: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        var frame = window.frame
        frame.origin.x = screenFrame.midX - frame.width / 2
        frame.origin.y = screenFrame.midY - frame.height / 2
        window.setFrame(frame, display: true)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@MainActor
final class OverlayHostingController<Content: View>: NSHostingController<Content> {
    var onCancel: (() -> Void)?

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
