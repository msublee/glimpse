import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = SearchPreferences.shared
    private let historyStore = SearchHistoryStore.shared
    private lazy var panelController = PanelController(historyStore: historyStore)
    private let hotKeyCenter = GlobalHotKeyCenter()
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        panelController.prepareWindow()

        registerHotKey(preferences.hotKey)

        preferences.$hotKey
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] newShortcut in
                guard let self else { return }
                do {
                    try self.hotKeyCenter.update(shortcut: newShortcut)
                } catch {
                    assertionFailure("Failed to update global hot key: \(error)")
                    self.registerHotKey(newShortcut)
                }
            }
            .store(in: &cancellables)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController.show()
        return false
    }

    private func registerHotKey(_ shortcut: KeyboardShortcut) {
        do {
            try hotKeyCenter.register(shortcut: shortcut) { [weak self] in
                self?.togglePanel()
            }
        } catch {
            assertionFailure("Failed to register global hot key: \(error)")
        }
    }

    private func togglePanel() {
        if panelController.isVisible {
            panelController.hide()
        } else {
            panelController.show()
        }
    }
}
