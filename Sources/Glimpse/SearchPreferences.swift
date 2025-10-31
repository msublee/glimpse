import Foundation

@MainActor
final class SearchPreferences: ObservableObject {
    static let shared = SearchPreferences()

    let engine: SearchEngine = .google

    @Published var hotKey: KeyboardShortcut {
        didSet {
            guard let data = try? JSONEncoder().encode(hotKey) else { return }
            userDefaults.set(data, forKey: Keys.hotKey)
        }
    }

    private let userDefaults: UserDefaults

    private struct Keys {
        static let hotKey = "search.hotkey"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if
            let data = userDefaults.data(forKey: Keys.hotKey),
            let stored = try? JSONDecoder().decode(KeyboardShortcut.self, from: data)
        {
            hotKey = stored
        } else {
            hotKey = .defaultToggle
        }
    }
}
