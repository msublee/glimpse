import SwiftUI

@main
struct GlimpseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            PreferencesView()
                .frame(minWidth: 460, minHeight: 480)
                .environmentObject(SearchPreferences.shared)
                .environmentObject(SearchHistoryStore.shared)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 560)
    }
}
