import AppKit
import SwiftUI
import QuartzCore

@MainActor
final class PanelController {
    private var window: NSPanel?
    private let historyStore: SearchHistoryStore
    private var viewModel: SearchViewModel
    private var hostingController: OverlayHostingController<AnyView>?
    private var previousActiveApp: NSRunningApplication?

    private func createHostingController() -> OverlayHostingController<AnyView> {
        let initialView = SearchOverlayView(viewModel: viewModel) { [weak self] in
            self?.hide()
        }
        .environmentObject(historyStore)
        let controller = OverlayHostingController(rootView: AnyView(initialView))
        controller.onCancel = { [weak self] in
            self?.hide()
        }
        return controller
    }

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

        // Create initial hosting controller
        hostingController = createHostingController()
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

        // Save currently active app before taking focus
        if !window.isVisible {
            previousActiveApp = NSWorkspace.shared.frontmostApplication
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

        // Delay focus request to ensure SwiftUI view is ready after ViewModel recreation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.viewModel.requestFocus()
        }
    }

    func hide() {
        guard let window, window.isVisible else {
            recreateViewModel()
            restorePreviousApp()
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

                // Recreate ViewModel to get clean WebView with empty history
                self.recreateViewModel()

                // Restore focus to previous app
                self.restorePreviousApp()
            }
        }
    }

    private func restorePreviousApp() {
        // Return focus to the app that was active before we showed
        if let previousApp = previousActiveApp,
           previousApp.isTerminated == false {
            previousApp.activate(options: [])
        }
        previousActiveApp = nil
    }

    private func recreateViewModel() {
        // Save current window size
        let currentSize = window?.frame.size ?? NSSize(width: 2000, height: 1300)

        // Create new ViewModel (new WebView with empty history)
        viewModel = SearchViewModel(historyStore: historyStore)

        // Recreate hosting controller with new ViewModel
        hostingController = createHostingController()

        // Update window's content view controller
        if let window = window {
            window.contentViewController = hostingController

            // Restore window size
            var frame = window.frame
            frame.size = currentSize
            window.setFrame(frame, display: false)
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
